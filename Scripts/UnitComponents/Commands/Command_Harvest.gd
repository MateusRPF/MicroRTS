extends Command
class_name Command_Harvest
var target_resource: CResourceNode = null
var target_delivery_stockpile: CStockpile = null
var current_step: HarvestSteps = HarvestSteps.FINDING_RESOURCE
var harvester: CHarvester = null
var state_machine: CStateMachine = null

var ideal_resource:GameResource

const SEARCH_RADIUS = 20

enum HarvestSteps
{
	APPROACHING,
	HARVESTING,
	DELIVERING,
	FINDING_RESOURCE,
	COMPLETED
}

func finish_cache():
	target_resource = target_actor.get_component(CResourceNode)
	harvester = owner_executor.owner_object.get_component(CHarvester)
	state_machine = owner_executor.owner_object.get_component(CStateMachine)


func start_command() -> bool:
	emit_signal("command_started", self)
	return true


func tick() -> void:
	super.tick()
	match current_step:
		HarvestSteps.FINDING_RESOURCE:
			if (target_resource):
				current_step = HarvestSteps.APPROACHING
				return
			if get_next_node():
				current_step = HarvestSteps.APPROACHING
			else:
				finish_command()
		HarvestSteps.APPROACHING:
			if (target_resource):
				if harvester.can_harvest(target_resource):
					state_machine.request_state(CStateMachine.StateID.HARVEST, {"target_resource": target_resource})
					current_step = HarvestSteps.HARVESTING
					return
	
				if not owner_executor.owner_object.get_component(CMover).is_moving():
					var target_interact_coord = get_best_coord_to_enact(target_resource.owner_object)
					if target_interact_coord == Vector2i(-1, -1): # No path found
							target_resource = null
							current_step = HarvestSteps.FINDING_RESOURCE
							return
					state_machine.request_state(CStateMachine.StateID.MOVE, {"target_tile":target_interact_coord })
					return
			else:
				current_step = HarvestSteps.FINDING_RESOURCE
		HarvestSteps.HARVESTING:
			if not harvester.inventory.has_room_for(harvester.currently_harvesting_resource):
				current_step = HarvestSteps.DELIVERING
				return
			if not target_resource:
				current_step = HarvestSteps.FINDING_RESOURCE
		HarvestSteps.DELIVERING:
			if target_delivery_stockpile:

				if target_delivery_stockpile.can_deposit_resource(harvester):
					harvester.deliver_to(target_delivery_stockpile)
					current_step = HarvestSteps.FINDING_RESOURCE
				else:
					if not owner_executor.owner_object.get_component(CMover).is_moving():
						state_machine.request_state(CStateMachine.StateID.MOVE, {"target_tile": get_best_coord_to_enact(target_delivery_stockpile.owner_object)})
			else:
				get_next_stockpile()
				if not target_delivery_stockpile:
						finish_command()


func get_best_coord_to_enact(target:GridObject)->Vector2i:

	var target_interact_coords:Array[Vector2i] = get_valid_coords_to_enact(target)
	var best_coord:Vector2i = Vector2i(-1,-1)
	var best_distance = INF
	var mover:CMover = owner_executor.owner_object.get_component(CMover)
	for coord in target_interact_coords:
		if (mover.can_path_to(coord)):
			var distance = owner_executor.owner_object.grid_manager.calculate_distance_sqr(coord,owner_executor.owner_object.current_coord)
			if distance < best_distance:
				best_coord = coord
				best_distance = distance
	return best_coord
	

func can_path_to_target(target:GridObject):
	var target_interact_coords:Array[Vector2i] = get_valid_coords_to_enact(target)
	var mover:CMover = owner_executor.owner_object.get_component(CMover)
	for coord in target_interact_coords:
		if mover.can_path_to(coord):
			return true


	return false


func get_status() -> int:
	if current_step == HarvestSteps.COMPLETED:
		return command_states.COMPLETED
	else:
		return command_states.EXECUTING

func get_descriptor() -> String:

	match current_step:
		HarvestSteps.DELIVERING:
			if (target_delivery_stockpile):
				return "Delivering to " + target_delivery_stockpile.owner_object.data.actor_name
			else:
				return "Finding stockpile..."
		HarvestSteps.FINDING_RESOURCE:
			return "Finding harvestable..."
		HarvestSteps.APPROACHING:
			if (target_resource):
				var approachingString = target_resource.owner_object.data.actor_name
				return "Approaching %s at %s" %[ approachingString,target_resource.owner_object.current_coord]

	var harvestingString:String = "???"
	if (target_resource):
		harvestingString = target_resource.owner_object.data.actor_name
		return "Harvest %s at %s" %[ harvestingString,target_resource.owner_object.current_coord]
	return "Done harvesting"
	



func get_next_node() -> bool:
	var nearby_resource = owner_executor.owner_object.grid_manager.find_closest_reachable_component(owner_executor.owner_object, SEARCH_RADIUS, CResourceNode)
	
	if not nearby_resource:
		return false
	else:
		target_resource = nearby_resource
		return true


func get_next_stockpile()->bool:
	if target_delivery_stockpile:
		return true
	else:
		var nearby_objects = owner_executor.owner_object.grid_manager.get_objects_in_radius(owner_executor.owner_object.current_coord, SEARCH_RADIUS,CStockpile)
		var best_stockpile: CStockpile = null
		var best_score = -INF
		for obj in nearby_objects:
			var stockpile = obj.get_component(CStockpile)
			if stockpile:
				var score = evaluate_stockpile(stockpile)
				if score > best_score:
					best_score = score
					best_stockpile = stockpile

		if best_stockpile:
			target_delivery_stockpile = best_stockpile
			return true

	return false

func evaluate_stockpile(stockpile: CStockpile) -> float:
	var distance = owner_executor.owner_object.grid_manager.calculate_distance(stockpile.owner_object.current_coord, owner_executor.owner_object.current_coord)
	var score = 1.0 / distance
	return score
