extends Command
class_name Command_Attack

var attacker: CAttacker = null
var state_machine: CStateMachine = null
var current_step: AttackSteps = AttackSteps.APPROACHING
enum AttackSteps
{
	APPROACHING,
	ATTACKING,
	FINDING_ENEMY
}

func finish_cache() -> void:
	attacker = owner_executor.owner_object.get_component(CAttacker)
	state_machine = owner_executor.owner_object.get_component(CStateMachine)

func start_command() -> bool:
	emit_signal("command_started", self)
	current_step = AttackSteps.FINDING_ENEMY
	var chosen_target: GridObject = _choose_attack_target()
	if not chosen_target:
		finish_command()
		return true

	target_actor = chosen_target
	state_machine.request_state(CStateMachine.StateID.COMBAT, {"target_actor": target_actor})
	return true

func tick() -> void:
	super.tick()
	match current_step:
		AttackSteps.FINDING_ENEMY:
			var chosen_target: GridObject = _choose_attack_target()
			if chosen_target:
				target_actor = chosen_target
				if (attacker.can_attack(target_actor)):
					state_machine.request_state(CStateMachine.StateID.COMBAT, {"target_actor": target_actor})
				current_step = AttackSteps.ATTACKING
			else:
				finish_command()
		AttackSteps.ATTACKING:
			if not target_actor:
				current_step = AttackSteps.FINDING_ENEMY
			if attacker.in_combat == false:
				current_step = AttackSteps.FINDING_ENEMY
		AttackSteps.APPROACHING:
			# This state is entered if the target was out of range, but we had a valid target. We wait here until the combat state finishes and then we check if we can attack or need to move closer
			if attacker.in_combat == false:
				if target_actor:
					state_machine.request_state(CStateMachine.StateID.MOVE, {"target_actor": target_actor})
				else:
					current_step = AttackSteps.FINDING_ENEMY



func get_descriptor() -> String:
	if target_actor:
		return "Attack %s" % target_actor.data.actor_name
	return "Attack"

func _choose_attack_target() -> GridObject:
	if attacker and target_actor and attacker.can_attack(target_actor):
		return target_actor

	if not attacker:
		return null

	var attack_range:int = attacker.get_attack_range()
	var nearby_enemies:Array[GridObject] = owner_executor.owner_object.grid_manager.get_objects_in_radius(owner_executor.owner_object.current_coord, attack_range, CWoundable)
	var best_target:GridObject = null
	var best_distance: float = INF

	for enemy in nearby_enemies:
		if enemy == owner_executor.owner_object:
			continue
		if enemy.side == owner_executor.owner_object.side:
			continue
		if not attacker.can_attack(enemy):
			continue
		var distance = owner_executor.owner_object.grid_manager.calculate_distance(owner_executor.owner_object.current_coord, enemy.current_coord)
		if distance < best_distance:
			best_distance = distance
			best_target = enemy

	return best_target
