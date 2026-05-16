extends CommandData
class_name CommandData_BuildStructure

@export var buildable_id: String
var fetchedData:ActorData


func get_footprint_size() -> Vector2i:

	return Database.get_actor_data(buildable_id).grid_size


func get_clearance() -> int:
	return Database.get_actor_data(buildable_id).clearance
