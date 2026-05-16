extends Command
class_name Command_EnterGarrison

var mover: CMover = null
var state_machine: CStateMachine = null
var inventory: CInventory = null
var _target_garrison: CGarrison = null

var target_position:Vector2i


func finish_cache() -> void:
	var actor: GridObject = owner_executor.owner_object
	mover = actor.get_component(CMover)
	state_machine = actor.get_component(CStateMachine)
	_target_garrison = target_actor.get_component(CGarrison)

func get_status() -> command_states:
	return command_states.EXECUTING

func get_descriptor() -> String:
	return "Entering " + _target_garrison.owner_object.data.actor_name


func tick() -> void:
	print("tick - entering gar")
	if _target_garrison:
		if not _target_garrison.can_enter(owner_executor.owner_object):
			print("")
			finish_command()
		if _target_garrison.perimeter.has(owner_executor.owner_object.current_coord):
			_target_garrison.enter_garrison(owner_executor.owner_object)
			finish_command()
		else:
			if not owner_executor.owner_object.get_component(CMover).is_moving():
				var delivery_coord = _get_best_coord_to_enact(_target_garrison.owner_object)
				if delivery_coord == Vector2i(-1, -1):
					cached_path = []
					return
				_request_move_state(delivery_coord)



func _request_move_state(target_tile: Vector2i) -> void:
	var params: Dictionary = {"target_tile": target_tile}
	if cached_path.size() > 0:
		params["cached_path"] = cached_path
	state_machine.request_state(CStateMachine.StateID.MOVE, params)