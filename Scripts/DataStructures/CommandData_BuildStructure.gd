extends CommandData
class_name CommandData_BuildStructure

@export var target_actor: ActorData
@export var cost: Dictionary[GameResource, int] = {}


func total_cost() -> int:
	var sum: int = 0
	for res in cost:
		sum += cost[res]
	return sum


func get_footprint_size() -> Vector2i:
	return target_actor.grid_size if target_actor else Vector2i.ONE


func get_clearance() -> int:
	return target_actor.clearance if target_actor else 0
