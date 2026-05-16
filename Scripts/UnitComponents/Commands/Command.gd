extends RefCounted
class_name Command

signal command_completed(command: Command)
signal command_started(command: Command)


#args
var data:CommandData
var owner_executor:CCommandExecutor
var target_coord:Vector2i
var target_actor:GridObject
var cached_path: Array[Vector2i] = []

func _init(newData:CommandData,executor:CCommandExecutor,coord:Vector2i,target:GridObject) -> void:
	data = newData
	owner_executor = executor
	target_coord = coord
	target_actor = target
	finish_cache()


enum command_states {
	QUEUED,
	EXECUTING,
	COMPLETED
}

func finish_cache() -> void:
	#for children to cache stuff.
	pass

func get_descriptor() -> String:
	return "none"

func start_command() -> bool:
	emit_signal("command_started", self)
	return true

func finish_command() -> void:
	emit_signal("command_completed", self)

func on_damaged(_opponent:GridObject) -> void:
	#for commands that want to react to being damaged while executing.
	pass


func tick() -> void:
	if not owner_executor:
		push_error("Command_Move: No owner_executor assigned")
		return
	pass

func get_status() -> command_states:
	return command_states.COMPLETED


func get_valid_coords_to_enact(object:GridObject,interact_range:int = 1) -> Array[Vector2i]:
	return owner_executor.owner_object.grid_manager.get_interaction_positions(object, interact_range, true)

func _get_best_coord_to_enact(target: GridObject,interact_range:int =1) -> Vector2i:
	if not target or not is_instance_valid(target):
		cached_path = []
		return Vector2i(-1, -1)

	var candidates: Array[Vector2i] = get_valid_coords_to_enact(target, interact_range)
	if candidates.is_empty():
		cached_path = []
		return Vector2i(-1, -1)

	var actor: GridObject = owner_executor.owner_object
	var result: Dictionary = actor.grid_manager.dijkstra_to_any(actor.current_coord, candidates, actor)
	if result.is_empty() or not result.has("best_goal"):
		cached_path = []
		print("Command_Attack: No path found to any candidate attack position.")
		return Vector2i(-1, -1)

	cached_path = result["path"] if result.has("path") else []
	return result["best_goal"]


func can_path_to_target(target: GridObject) -> bool:
	var candidates: Array[Vector2i] = get_valid_coords_to_enact(target)
	if candidates.is_empty():
		return false
	var actor: GridObject = owner_executor.owner_object
	var result: Dictionary = actor.grid_manager.dijkstra_to_any(actor.current_coord, candidates, actor)
	return not result.is_empty()
