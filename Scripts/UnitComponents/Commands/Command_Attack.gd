extends Command
class_name Command_Attack

var attacker: CAttacker = null
var state_machine: CStateMachine = null
var mover: CMover = null
var current_step: AttackSteps = AttackSteps.FINDING_ENEMY
var cached_path: Array[Vector2i] = []

enum AttackSteps
{
	APPROACHING,
	ATTACKING,
	FINDING_ENEMY,
	COMPLETED
}

func get_status() -> int:
	if current_step == AttackSteps.COMPLETED:
		return command_states.COMPLETED
	return command_states.EXECUTING

func finish_command() -> void:
	current_step = AttackSteps.COMPLETED
	super.finish_command()

func finish_cache() -> void:
	attacker = owner_executor.owner_object.get_component(CAttacker)
	state_machine = owner_executor.owner_object.get_component(CStateMachine)
	mover = owner_executor.owner_object.get_component(CMover)

func start_command() -> bool:
	emit_signal("command_started", self)
	if not attacker:
		finish_command()
		return true

	if _is_target_valid_enemy(target_actor):
		if attacker.can_attack(target_actor):
			var combat_state := state_machine.current_state as State_Combat
			var already_on_target: bool = state_machine.current_state_id == CStateMachine.StateID.COMBAT and combat_state and combat_state.target_actor == target_actor
			if not already_on_target:
				state_machine.request_state(CStateMachine.StateID.COMBAT, {"target_actor": target_actor})
			current_step = AttackSteps.ATTACKING
			return true
		if _start_approach():
			return true

	current_step = AttackSteps.FINDING_ENEMY
	return true

func tick() -> void:
	super.tick()
	match current_step:
		AttackSteps.FINDING_ENEMY:
			var chosen_target: GridObject = _choose_attack_target()
			if not chosen_target:
				finish_command()
				return
			target_actor = chosen_target
			if attacker.can_attack(target_actor):
				state_machine.request_state(CStateMachine.StateID.COMBAT, {"target_actor": target_actor})
				current_step = AttackSteps.ATTACKING
			elif not _start_approach():
				finish_command()
		AttackSteps.APPROACHING:
			if not _is_target_valid_enemy(target_actor):
				current_step = AttackSteps.FINDING_ENEMY
				return
			if attacker.can_attack(target_actor):
				state_machine.request_state(CStateMachine.StateID.COMBAT, {"target_actor": target_actor})
				current_step = AttackSteps.ATTACKING
				return
			if mover and not mover.is_moving():
				if not _start_approach():
					finish_command()
		AttackSteps.ATTACKING:
			if attacker.in_combat:
				return
			if not _is_target_valid_enemy(target_actor):
				current_step = AttackSteps.FINDING_ENEMY
				return
			if attacker.can_attack(target_actor):
				state_machine.request_state(CStateMachine.StateID.COMBAT, {"target_actor": target_actor})
				return
			if not _start_approach():
				current_step = AttackSteps.FINDING_ENEMY


func get_descriptor() -> String:
	if target_actor:
		return "Attack %s" % target_actor.data.actor_name
	return "Attack"

func _is_target_valid_enemy(target) -> bool:
	if not is_instance_valid(target):
		return false
	var target_obj := target as GridObject
	if not target_obj or not target_obj.is_inside_tree():
		return false
	if target_obj.side == owner_executor.owner_object.side:
		return false
	if not target_obj.get_component(CWoundable):
		return false
	return true

func _start_approach() -> bool:
	var target_coord: Vector2i = _get_best_coord_to_enact(target_actor)
	if target_coord == Vector2i(-1, -1):
		return false
	_request_move_state(target_coord)
	current_step = AttackSteps.APPROACHING
	return true

func _request_move_state(target_tile: Vector2i) -> void:
	var params: Dictionary = {"target_tile": target_tile}
	if cached_path.size() > 0:
		params["cached_path"] = cached_path
	state_machine.request_state(CStateMachine.StateID.MOVE, params)

func _get_best_coord_to_enact(target: GridObject) -> Vector2i:
	var candidates: Array[Vector2i] = get_valid_coords_to_enact(target, attacker.get_attack_range())
	if candidates.is_empty():
		cached_path = []
		return Vector2i(-1, -1)
	var actor: GridObject = owner_executor.owner_object
	var result: Dictionary = actor.grid_manager.dijkstra_to_any(actor.current_coord, candidates, actor)
	if result.is_empty():
		cached_path = []
		return Vector2i(-1, -1)
	cached_path = result["path"]
	return result["best_goal"]

func _choose_attack_target() -> GridObject:
	if attacker and _is_target_valid_enemy(target_actor) and attacker.can_attack(target_actor):
		return target_actor

	if not attacker:
		return null

	var attack_range: int = attacker.get_attack_range()
	var nearby_enemies: Array[GridObject] = owner_executor.owner_object.grid_manager.get_objects_in_radius(owner_executor.owner_object.current_coord, attack_range, CWoundable)
	var best_target: GridObject = null
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
