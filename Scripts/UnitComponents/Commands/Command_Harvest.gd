extends Command
class_name Command_Harvest
var target_resource: CResourceNode = null
var target_delivery_stockpile: CStockpile = null
var current_step: HarvestSteps = HarvestSteps.FINDING_RESOURCE
var harvester: CHarvester = null
var state_machine: CStateMachine = null

var ideal_resource:GameResource
var cached_path: Array[Vector2i] = []

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
			if is_instance_valid(target_resource) and is_instance_valid(target_resource.owner_object):
				if harvester.can_harvest(target_resource):
					state_machine.request_state(CStateMachine.StateID.HARVEST, {"target_resource": target_resource})
					current_step = HarvestSteps.HARVESTING
					return

				if not owner_executor.owner_object.get_component(CMover).is_moving():
					var target_interact_coord: Vector2i = get_best_coord_to_enact(target_resource.owner_object)
					if target_interact_coord == Vector2i(-1, -1):
						target_resource = null
						cached_path = []
						current_step = HarvestSteps.FINDING_RESOURCE
						return
					_request_move_state(target_interact_coord)
					return
			else:
				target_resource = null
				cached_path = []
				current_step = HarvestSteps.FINDING_RESOURCE
		HarvestSteps.HARVESTING:
			if not harvester.inventory.has_room_for(harvester.currently_harvesting_resource):
				current_step = HarvestSteps.DELIVERING
				return
			if not is_instance_valid(target_resource):
				target_resource = null
				current_step = HarvestSteps.FINDING_RESOURCE
		HarvestSteps.DELIVERING:
			if target_delivery_stockpile:

				if target_delivery_stockpile.can_deposit_resource(harvester):
					harvester.deliver_to(target_delivery_stockpile)
					current_step = HarvestSteps.FINDING_RESOURCE
				else:
					if not owner_executor.owner_object.get_component(CMover).is_moving():
						var delivery_coord = get_best_coord_to_enact(target_delivery_stockpile.owner_object)
						if delivery_coord == Vector2i(-1, -1):
							cached_path = []
							return
						_request_move_state(delivery_coord)
			else:
				get_next_stockpile()
				if not target_delivery_stockpile:
						finish_command()


func _request_move_state(target_tile: Vector2i) -> void:
	var params: Dictionary = {"target_tile": target_tile}
	if cached_path.size() > 0:
		params["cached_path"] = cached_path
	state_machine.request_state(CStateMachine.StateID.MOVE, params)


func get_best_coord_to_enact(target: GridObject) -> Vector2i:
	var candidates: Array[Vector2i] = get_valid_coords_to_enact(target)
	if candidates.is_empty():
		cached_path = []
		return Vector2i(-1, -1)

	var actor: GridObject = owner_executor.owner_object
	var result: Dictionary = actor.grid_manager.dijkstra_to_any(actor.current_coord, candidates, actor)
	if result.is_empty():
		cached_path = []
		return Vector2i(-1, -1)

	cached_path = result["path"]
	return result["best_goal"]


func can_path_to_target(target: GridObject) -> bool:
	var candidates: Array[Vector2i] = get_valid_coords_to_enact(target)
	if candidates.is_empty():
		return false
	var actor: GridObject = owner_executor.owner_object
	var result: Dictionary = actor.grid_manager.dijkstra_to_any(actor.current_coord, candidates, actor)
	return not result.is_empty()


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
			if obj.side != owner_executor.owner_object.side:
				continue
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
