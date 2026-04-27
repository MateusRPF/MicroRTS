extends Command
class_name Command_Wander

var mover: CMover = null

const MIN_WANDER_RADIUS: int = 3
const MAX_WANDER_RADIUS: int = 7



func finish_cache() -> void:
	mover = owner_executor.owner_object.get_component(CMover)


func start_command() -> bool:
	print("Starting wander command for %s" % owner_executor.owner_object.name)
	emit_signal("command_started", self)
	var random_radius = randi_range(MIN_WANDER_RADIUS, MAX_WANDER_RADIUS)
	var tiles:Array[GameTile] = owner_executor.owner_object.grid_manager.get_walkable_tiles_in_radius(owner_executor.owner_object.current_coord, random_radius)
	var randomTile: GameTile = tiles.pick_random()
	target_coord = randomTile.coord
	print("Wander command: selected random target coordinate %s within radius %d" % [target_coord, random_radius])
	owner_executor.owner_object.get_component(CStateMachine).request_state(CStateMachine.StateID.MOVE, {"target_tile": target_coord})
	return true

func get_descriptor() -> String:
	return "Move to %s" %[target_coord]


func tick() -> void:
	super.tick()
	if not mover.is_moving():
		finish_command()

func get_status() -> int:
	if mover.is_moving():
		return command_states.EXECUTING
	else:
		return command_states.COMPLETED
