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
	var mover: CMover = attacker.get_component(CMover)
	if mover:
		mover.stop_move()
	attack_interval = 10
	if attrSet:
		var rate: int = max(1, attrSet.get_attr(CAttributeSet.ATTR_ID.ATTR_ATTACK_SPEED))
		attack_interval = max(1, ceili(30.0 / rate))
	frame_counter = attack_interval
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

	var mover_check: CMover = attacker.get_component(CMover)
	if mover_check and mover_check.is_hop_animating():
		return
	frame_counter += 1
	var will_fire: bool = frame_counter >= attack_interval
	if will_fire:
		frame_counter = 0
		var lean_duration: float = min(GridObject.INTERACT_DURATION, attack_interval * GlobalTicker.tick_rate)
		attacker.play_interaction_with(target_actor, false, lean_duration)
		var pipeline: CombatPipeline = CombatPipeline.new()
		pipeline.attacker = attacker
		pipeline.defender = target_actor
		var is_ranged: bool = attacker.get_component(CAttributeSet).get_attr(CAttributeSet.ATTR_ID.ATTR_ATTACK_RANGE) > 1
		
		var hit: bool = pipeline.execute()
		if (is_ranged):
			GameplayEvents.VFX_requested.emit("Projectile", attacker.current_coord, target_actor.current_coord)
		if is_instance_valid(target_actor) and target_actor.is_inside_tree():
			if hit:
				if (not is_ranged):
					GameplayEvents.VFX_requested.emit("Slash", attacker.current_coord,target_actor.current_coord) #todo - what for ranged?
				target_actor.play_hit_flash()
			else:
				GameplayEvents.VFX_requested.emit("Miss", attacker.current_coord,target_actor.current_coord)
				# target_actor.play_white_flash()
		var defender_woundable:CWoundable = target_actor.get_component(CWoundable) if is_instance_valid(target_actor) else null
		if not defender_woundable or defender_woundable.get_current_health() <= 0:
			owner_machine.request_state(CStateMachine.StateID.IDLE)

func exit_state() -> void:
	attacker_comp.in_combat= false
