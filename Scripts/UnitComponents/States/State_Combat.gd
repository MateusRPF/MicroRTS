extends State
class_name State_Combat

var target_actor: GridObject = null
var frame_counter: int = 0
var attack_interval: int = 1

var attacker_comp: CAttacker = null


func enter_state(params: Dictionary) -> bool:
	if not params.has("target_actor"):
		print("State_Combat missing target_actor")
		return false

	target_actor = params["target_actor"] as GridObject
	var attacker: GridObject = owner_machine.owner_object
	var attrSet:CAttributeSet = attacker.get_component(CAttributeSet)
	attacker_comp = attacker.get_component(CAttacker)
	attacker_comp.in_combat= true
	attack_interval = 1
	if attrSet:
		attack_interval = max(1, attrSet.get_attr(CAttributeSet.ATTR_ID.ATTR_ATTACK_SPEED))
	frame_counter = 0

	return true

func tick_state() -> void:
	var attacker: GridObject = owner_machine.owner_object
	if not target_actor or not target_actor.is_inside_tree():
		owner_machine.request_state(CStateMachine.StateID.IDLE)
		return
	if target_actor.side == attacker.side:
		owner_machine.request_state(CStateMachine.StateID.IDLE)
		return
	if not attacker_comp or not attacker_comp.can_attack(target_actor):
		owner_machine.request_state(CStateMachine.StateID.IDLE)
		return

	frame_counter += 1
	if frame_counter >= attack_interval:
		frame_counter = 0
		var pipeline: CombatPipeline = CombatPipeline.new()
		pipeline.attacker = attacker
		pipeline.defender = target_actor
		pipeline.execute()
		var defender_woundable:CWoundable = target_actor.get_component(CWoundable)
		if not defender_woundable or defender_woundable.get_current_health() <= 0:
			owner_machine.request_state(CStateMachine.StateID.IDLE)

func exit_state() -> void:
	attacker_comp.in_combat= false
