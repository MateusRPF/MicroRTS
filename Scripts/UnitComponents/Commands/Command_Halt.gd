extends Command
class_name Command_Halt

var state_machine: CStateMachine = null
var mover: CMover = null

func get_descriptor() -> String:
	return "Halted."

func get_valid_coords_to_enact(object:GridObject,_interactRange:int = 1) -> Array[Vector2i]:
	return [object.grid_position]

func start_command() -> bool:
	emit_signal("command_started", self)
	state_machine.request_state(CStateMachine.StateID.IDLE)
	mover.stop_move()
	return true

func finish_cache() -> void:
	state_machine = owner_executor.owner_object.get_component(CStateMachine)
	mover = owner_executor.owner_object.get_component(CMover)


func get_status() -> command_states:
	return command_states.EXECUTING