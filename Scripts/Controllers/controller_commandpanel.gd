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
		if object.side != ActorData.Sides.PLAYER:
			continue
		var command_pool:Array[CommandData] = get_enabled_commands_for_actor(object)
		var executor:CCommandExecutor = object.get_component(CCommandExecutor)
		if not executor:
			continue
		if (command_pool.has(commandData)):
			if (validate_command_on_coord(executor,target_coord,commandData)):
				var new_command:Command = create_command_from_data(commandData,executor,target_coord)
				if (new_command):
					executor.queue_command(new_command)


func create_command_from_data(data:CommandData,executor:CCommandExecutor, target_pos:Vector2i)->Command:
	var tile = controller.grid_manager.map_tiles[target_pos]
	var target_object:GridObject = tile.occupant

	var new_command = data.command_script.new(data,executor,target_pos,target_object)


	return new_command

func validate_command_on_coord(_executor:CCommandExecutor, target_coord:Vector2i, command:CommandData) -> bool:
	var tile = controller.grid_manager.map_tiles[target_coord]
	if not tile:
		# print("No valid tile.")
		return false
	
	var hovered_object:GridObject
	if (tile.occupant):
		hovered_object = tile.occupant

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
				if (hovered_object and hovered_object.side != ActorData.Sides.PLAYER):
					return true
			CommandData.Targetting.RESOURCE_NODE:
				if (hovered_object && hovered_object.get_component(CResourceNode)):
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
		if (validate_command_on_coord(executor,controller.hovered_coord,command)):
			valid_commands_for_target.append(command)

	valid_commands_for_target.sort_custom(sort_commands)
	print("found %s commands. %s were valid. " % [applicable_commands.size(),valid_commands_for_target.size()])

	if (valid_commands_for_target.size() >0):
		return valid_commands_for_target[0]

	return null

func sort_commands(a:CommandData, b:CommandData):
	return a.priority > b.priority
