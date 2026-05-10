extends GridObjectComponent
class_name CStateMachine



var current_state: State = null
var cached_states: Dictionary = {}
var current_state_id: StateID = StateID.NONE


enum StateID
{
	NONE,
	IDLE,
	MOVE,
	HARVEST,
	COMBAT,
}

const STATE_MAP = {
	StateID.IDLE: preload("res://Scripts/UnitComponents/States/State_Idle.gd"),
	StateID.MOVE: preload("res://Scripts/UnitComponents/States/State_Move.gd"),
	StateID.HARVEST: preload("res://Scripts/UnitComponents/States/State_Harvest.gd"),
	StateID.COMBAT: preload("res://Scripts/UnitComponents/States/State_Combat.gd")
}

func _on_tick_received() -> void:
	if current_state:
		current_state.tick_state()

func request_state(state_id: StateID, params: Dictionary = {}) -> bool:
	if current_state:
		current_state.exit_state()
	
	if not cached_states.has(state_id):
		var state_class = STATE_MAP[state_id]
		var new_state = state_class.new()
		new_state.owner_machine = self
		cached_states[state_id] = new_state
	
	current_state = cached_states[state_id]
	current_state_id = state_id
	var success = current_state.enter_state(params)
	return success
