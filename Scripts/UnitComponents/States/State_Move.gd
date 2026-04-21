extends State
class_name State_Move
var mover: CMover = null

func enter_state(params: Dictionary) -> bool:
	if not params.has("target_tile"):
		DebugSettings.debug_print("State_Move", "Missing target_tile param for move state")
		return false

	var target_tile = params["target_tile"] as Vector2i
	mover = owner_machine.owner_object.get_component(CMover)

	if params.has("cached_path"):
		var cached: Array[Vector2i] = params["cached_path"]
		if cached.size() > 0:
			return mover.start_move_with_path(cached, target_tile)

	return mover.start_move(target_tile)

func tick_state() -> void:
	if not mover.is_moving():
		owner_machine.request_state(CStateMachine.StateID.IDLE)
