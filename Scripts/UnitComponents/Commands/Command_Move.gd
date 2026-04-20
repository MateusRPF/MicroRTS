extends Command
class_name Command_Move

var mover: CMover = null


func finish_cache() -> void:
	mover = owner_executor.owner_object.get_component(CMover)


func start_command() -> bool:
	emit_signal("command_started", self)
	var success:bool = owner_executor.owner_object.get_component(CStateMachine).request_state(CStateMachine.StateID.MOVE, {"target_tile": target_coord})
	return success

func get_descriptor() -> String:
	return "Move to %s" %[target_coord]


func tick() -> void:
	super.tick()
	if not mover.is_moving():
		finish_command()

func get_status() -> int:
	if mover.is_moving():
		return command_states.EXECUTING
	else:
		return command_states.COMPLETED

