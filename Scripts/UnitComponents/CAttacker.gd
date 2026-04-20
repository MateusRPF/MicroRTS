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

	var distance = owner_object.grid_manager.calculate_distance(owner_object.current_coord, target.current_coord)
	return distance <= get_attack_range()
