extends RefCounted
class_name Command

signal command_completed(command: Command)
signal command_started(command: Command)


#args
var data:CommandData
var owner_executor:CCommandExecutor
var target_coord:Vector2i
var target_actor:GridObject

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


func tick() -> void:
	if not owner_executor:
		push_error("Command_Move: No owner_executor assigned")
		return
	pass

func get_status() -> command_states:
	return command_states.COMPLETED


func get_valid_coords_to_enact(object:GridObject,interactRange:int = 1) -> Array[Vector2i]:
	return owner_executor.owner_object.grid_manager.get_interaction_positions( object, interactRange)
