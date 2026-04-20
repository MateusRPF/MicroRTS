extends RefCounted
class_name CombatPipeline

var attacker: GridObject = null
var defender: GridObject = null

func execute() -> bool:
	if not attacker or not defender:
		return false

	var attacker_attrs:CAttributeSet = attacker.get_component(CAttributeSet)
	var defender_attrs:CAttributeSet = defender.get_component(CAttributeSet)
	var attack_value:int = attacker_attrs.get_attr(CAttributeSet.ATTR_ID.ATTR_ATTACK_POWER) if attacker_attrs else 0
	var defense_value:int = defender_attrs.get_attr(CAttributeSet.ATTR_ID.ATTR_ARMOR)  if defender_attrs else 0
	var hit_chance:int = clamp(attack_value + 50 - defense_value, 0, 100)
	var roll:int = randi_range(1, 100)
	var hit: bool = roll <= hit_chance

	if hit:
		var defender_woundable:CWoundable = defender.get_component(CWoundable)
		if defender_woundable:
			defender_woundable.receive_wound(1)
	return hit
