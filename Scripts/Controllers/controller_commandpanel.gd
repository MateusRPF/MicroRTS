extends Node
class_name CommandController

@export var _command_registry:Array[CommandData]
@onready var controller:PlayerController = self.get_parent() as PlayerController



func get_enabled_commands_for_actor(actor:GridObject) -> Array[CommandData]:
	if actor.side != ActorData.Sides.PLAYER:
		return []

	var valid_commands:Array[CommandData] = []
	for command_data in _command_registry:
		var valid:bool = true
		for script in command_data.required_components:
			if not actor.get_component(script):
				valid = false
		if valid:
			valid_commands.append(command_data)

	return valid_commands


func issue_wildcard_order(selected_objects:Array[GridObject]) -> void:
	for unit in selected_objects:
		if not is_instance_valid(unit):
			continue
		if unit.side != ActorData.Sides.PLAYER:
			continue
		var executor = unit.get_component(CCommandExecutor)
		if not executor:
			continue
		var commandData = find_appropriate_command(executor)
		if not (commandData):
			continue
		var command = create_command_from_data(commandData,executor,controller.hovered_coord)
		if command:
			executor.queue_command(command)

func issue_aimed_command(selected_objects:Array[GridObject],commandData:CommandData,target_coord:Vector2i):
	for object in selected_objects:
		if not is_instance_valid(object):
			continue
		if object.side != ActorData.Sides.PLAYER:
			continue
		var executor:CCommandExecutor = object.get_component(CCommandExecutor)
		if not executor:
			continue
		if not actor_can_issue(object, commandData):
			print("Actor %s cannot issue command %s " %[object.data.actor_name,commandData.display_name])
			continue
		if (validate_command_on_coord(executor,target_coord,commandData)):
			var new_command:Command = create_command_from_data(commandData,executor,target_coord)
			if (new_command):
				executor.queue_command(new_command)


func actor_can_issue(actor: GridObject, commandData: CommandData) -> bool:

	if commandData is CommandData_BuildStructure:
		var builder: CBuilder = actor.get_component(CBuilder)
		if builder and builder.buildable.has(commandData):
			return true

	if commandData is CommandData_IssueWorkOrder:
		print("Validating CommandData_IssueWorkOrder")
		var immediate_cost_resource = commandData.order.immediate_cost
		var immediate_cost_value = commandData.order.immediate_cost_value
		if controller.grid_manager.player_state.get_resource_value(immediate_cost_resource) < immediate_cost_value:
			print("Validating CommandData_IssueWorkOrder - Immediate Cost failed.")
			return false

		var issuer:CWorkStation = actor.get_component(CWorkStation)
		if (issuer and issuer.validate_work_order(commandData.order)):
			print("Validating CommandData_IssueWorkOrder - accepted Issuer")
			return true

	if get_enabled_commands_for_actor(actor).has(commandData):
		return true
	
	return false


func create_command_from_data(data:CommandData,executor:CCommandExecutor, target_pos:Vector2i)->Command:
	var tile:GameTile = null
	var target_object:GridObject = null
	if (target_pos != Vector2i(-1,-1)):
		tile = controller.grid_manager.map_tiles[target_pos]
		if (tile):
			target_object = tile.unit_occupant
			if target_object == null:
				target_object = tile.prop_occupant

	var new_command = data.command_script.new(data,executor,target_pos,target_object)

	return new_command

func validate_command_on_coord(_executor:CCommandExecutor, target_coord:Vector2i, command:CommandData) -> bool:
	if command.target_mode == CommandData.Targetting.NONE:
		return true
	
	var tile = controller.grid_manager.map_tiles[target_coord]
	if not tile:
		return false
	
	var hovered_object:GridObject
	if (tile.unit_occupant):
		hovered_object = tile.unit_occupant
	elif (tile.prop_occupant):
		hovered_object = tile.prop_occupant

	match command.target_mode: #TODO ADD ALL OTHERS
			CommandData.Targetting.NONE:
				return true
			CommandData.Targetting.EMPTY_TILE:
				if (hovered_object == null): #no one occupies the tile
					return true
			CommandData.Targetting.ACTOR_ANY:
				if (hovered_object):
					return true
			CommandData.Targetting.UNIT_ENEMY:
				if (hovered_object and hovered_object.side != ActorData.Sides.PLAYER and hovered_object.get_component(CWoundable)):
					return true
			CommandData.Targetting.RESOURCE_NODE:
				if (hovered_object && hovered_object.get_component(CResourceNode)):
					return true
			CommandData.Targetting.BUILD_SETUP:
				if command is CommandData_BuildStructure:
					var build_data := command as CommandData_BuildStructure
					var size: Vector2i = build_data.get_footprint_size()
					var clearance: int = build_data.get_clearance()
					return controller.grid_manager.can_place_with_clearance(target_coord, size, clearance)
				if (hovered_object == null and tile.tile_type == GameTile.TileType.FLOOR):
					return true
			CommandData.Targetting.CONSTRUCTION_SITE:
				if hovered_object and hovered_object.get_component(CUnderConstruction):
					return true
			CommandData.Targetting.GARRISON:
				if hovered_object and hovered_object.get_component(CGarrison):
					if hovered_object.get_component(CGarrison).can_enter(_executor.owner_object):
						return true
	return false



func find_appropriate_command(executor:CCommandExecutor)-> CommandData:

	print("finding appropriate command for %s at %s" %[executor.owner_object.data.actor_name, controller.hovered_coord] )
	if controller.hovered_coord == null:
		# print("No valid coord.")
		return null

	var applicable_commands:Array[CommandData] = get_enabled_commands_for_actor(executor.owner_object)
	var valid_commands_for_target:Array[CommandData]
	for command:CommandData in applicable_commands:
		if command.target_mode == CommandData.Targetting.NONE:
			valid_commands_for_target.append(command)
			continue
		if (validate_command_on_coord(executor,controller.hovered_coord,command)):
			valid_commands_for_target.append(command)

	valid_commands_for_target.sort_custom(sort_commands)

	if (valid_commands_for_target.size() >0):
		return valid_commands_for_target[0]

	return null

func sort_commands(a:CommandData, b:CommandData):
	return a.priority > b.priority
