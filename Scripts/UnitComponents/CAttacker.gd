extends GridObjectComponent
class_name CAttacker

var in_combat: bool = false

func get_attack_range() -> int:
	var attrSet:CAttributeSet = owner_object.get_component(CAttributeSet)
	if attrSet:
		return max(1, attrSet.get_attr(CAttributeSet.ATTR_ID.ATTR_ATTACK_RANGE))
	return 1

func get_attack_power() -> int:
	var attrSet:CAttributeSet = owner_object.get_component(CAttributeSet)
	if attrSet:
		return max(0, attrSet.get_attr(CAttributeSet.ATTR_ID.ATTR_ATTACK_POWER))
	return 0

func can_attack(target: GridObject) -> bool:
	if not target:
		return false
	if target == owner_object:
		return false
	if target.side == owner_object.side:
		return false
	if not target.get_component(CWoundable):
		return false
	if not owner_object.grid_manager:
		return false

	var delta: Vector2i = target.current_coord - owner_object.current_coord
	var distance: int = max(abs(delta.x), abs(delta.y))
	return distance <= get_attack_range()


func _on_tick_received() -> void:
	var state_machine: CStateMachine = owner_object.get_component(CStateMachine)
	if not state_machine or state_machine.current_state_id != CStateMachine.StateID.IDLE:
		return
	var attack_range: int = get_attack_range()
	var nearby: Array[GridObject] = owner_object.grid_manager.get_objects_in_radius(owner_object.current_coord, attack_range, CWoundable)
	var best: GridObject = null
	var best_distance: int = 999999
	for candidate in nearby:
		if not can_attack(candidate):
			continue
		var delta: Vector2i = candidate.current_coord - owner_object.current_coord
		var distance: int = max(abs(delta.x), abs(delta.y))
		if distance < best_distance:
			best_distance = distance
			best = candidate
	if best:
		state_machine.request_state(CStateMachine.StateID.COMBAT, {"target_actor": best})
