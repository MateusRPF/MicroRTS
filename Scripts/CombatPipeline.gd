extends RefCounted
class_name CombatPipeline

const MIN_HIT_CHANCE: int = 1
const BASE_HIT_CHANCE: int = 50
const DAMAGE_MATRIX_BONUS: float = 1.0
const CRIT_WOUNDS: int = 2

var attacker: GridObject = null
var defender: GridObject = null

func execute() -> bool:
	if not is_instance_valid(attacker) or not attacker.is_inside_tree():
		return false
	var attacker_woundable: CWoundable = attacker.get_component(CWoundable)
	if attacker_woundable and attacker_woundable.get_current_health() <= 0:
		return false
	if not is_instance_valid(defender) or not defender.is_inside_tree():
		return false

	var attacker_attrs: CAttributeSet = attacker.get_component(CAttributeSet)
	var defender_attrs: CAttributeSet = defender.get_component(CAttributeSet)
	var attack_value: int = attacker_attrs.get_attr(CAttributeSet.ATTR_ID.ATTR_ATTACK_POWER) if attacker_attrs else 0
	var defense_value: int = defender_attrs.get_attr(CAttributeSet.ATTR_ID.ATTR_ARMOR) if defender_attrs else 0

	var offense: int = attack_value + BASE_HIT_CHANCE
	var defense: int = roundi(defense_value * DAMAGE_MATRIX_BONUS)
	var hit_chance: int = clampi(offense - defense, MIN_HIT_CHANCE, 100)
	var roll: int = randi_range(1, 100)
	var hit: bool = roll <= hit_chance

	if hit:
		var defender_woundable: CWoundable = defender.get_component(CWoundable)
		if defender_woundable:
			var crit_chance: int = clampi(offense - defense, 0, 100)
			var crit_roll: int = randi_range(1, 100)
			var is_crit: bool = crit_roll <= crit_chance
			defender_woundable.receive_wound(CRIT_WOUNDS if is_crit else 1)
	return hit
