extends RefCounted
class_name State

var owner_machine: CStateMachine = null
var state_id: CStateMachine.StateID = CStateMachine.StateID.NONE

func enter_state(_params: Dictionary) -> bool:
	return true

func exit_state() -> void:
	pass

func tick_state() -> void:
	pass