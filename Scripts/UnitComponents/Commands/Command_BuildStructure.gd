extends Command
class_name Command_BuildStructure

var mover: CMover = null
var state_machine: CStateMachine = null
var build_data: CommandData_BuildStructure = null
var current_step: BuildSteps = BuildSteps.APPROACHING
var footprint_coords: Array[Vector2i] = []
var perimeter_coords: Array[Vector2i] = []
var spawned_site: GridObject = null
var target_construction: CUnderConstruction = null

const PUNCH_DISTANCE: float = 14.0
const PUNCH_DURATION: float = 0.16
var _punch_tween: Tween = null

enum BuildSteps {
	APPROACHING,
	BUILDING,
	COMPLETED
}


func finish_cache() -> void:
	mover = owner_executor.owner_object.get_component(CMover)
	state_machine = owner_executor.owner_object.get_component(CStateMachine)
	build_data = data as CommandData_BuildStructure
	var grid: GridManager = owner_executor.owner_object.grid_manager
	footprint_coords = grid.get_footprint_coords(target_coord, build_data.get_footprint_size())
	perimeter_coords = _compute_perimeter()


func _compute_perimeter() -> Array[Vector2i]:
	var footprint_set: Dictionary = {}
	for coord in footprint_coords:
		footprint_set[coord] = true
	var perimeter: Array[Vector2i] = []
	var seen: Dictionary = {}
	for coord in footprint_coords:
		for direction in GridManager.DIRECTIONS:
			var neighbor: Vector2i = coord + direction
			if footprint_set.has(neighbor):
				continue
			if seen.has(neighbor):
				continue
			seen[neighbor] = true
			perimeter.append(neighbor)
	return perimeter


func start_command() -> bool:
	emit_signal("command_started", self)
	return true


func tick() -> void:
	super.tick()
	var actor: GridObject = owner_executor.owner_object
	match current_step:
		BuildSteps.APPROACHING:
			if perimeter_coords.has(actor.current_coord):
				_spawn_structure()
				if not is_instance_valid(target_construction):
					current_step = BuildSteps.COMPLETED
					finish_command()
					return
				current_step = BuildSteps.BUILDING
				return
			if not mover.is_moving():
				var adjacent: Vector2i = _find_adjacent_walkable()
				if adjacent == Vector2i(-1, -1):
					current_step = BuildSteps.COMPLETED
					finish_command()
					return
				state_machine.request_state(CStateMachine.StateID.MOVE, {"target_tile": adjacent})
		BuildSteps.BUILDING:
			if not is_instance_valid(spawned_site) or not is_instance_valid(target_construction) or target_construction.is_complete():
				current_step = BuildSteps.COMPLETED
				finish_command()
				return
			if not perimeter_coords.has(actor.current_coord):
				current_step = BuildSteps.APPROACHING
				return
			_play_punch()
			target_construction.shake()
			if target_construction.add_progress(1):
				current_step = BuildSteps.COMPLETED
				finish_command()


func _find_adjacent_walkable() -> Vector2i:
	var actor: GridObject = owner_executor.owner_object
	var grid: GridManager = actor.grid_manager
	var candidates: Array[Vector2i] = []
	for coord in perimeter_coords:
		var tile: GameTile = grid.map_tiles.get(coord)
		if tile and tile.tile_type == GameTile.TileType.FLOOR:
			if not tile.is_occupied or tile.occupant == actor:
				candidates.append(coord)
	if candidates.is_empty():
		return Vector2i(-1, -1)
	if candidates.has(actor.current_coord):
		return actor.current_coord
	var result: Dictionary = grid.dijkstra_to_any(actor.current_coord, candidates, actor)
	if result.is_empty():
		return Vector2i(-1, -1)
	return result["best_goal"]


func _spawn_structure() -> void:
	if not build_data or not build_data.structure_scene:
		return
	var grid: GridManager = owner_executor.owner_object.grid_manager
	if not grid.can_place_footprint(target_coord, build_data.get_footprint_size()):
		return
	var new_structure: GridObject = build_data.structure_scene.instantiate() as GridObject
	grid.add_child(new_structure)
	new_structure.initialize_as_construction_site(grid, target_coord, ActorData.Sides.PLAYER, new_structure.data)
	spawned_site = new_structure
	target_construction = new_structure.get_component(CUnderConstruction)


func _play_punch() -> void:
	var actor: GridObject = owner_executor.owner_object
	var sprite: Node2D = actor.get_node_or_null("%Sprite")
	if not sprite or not is_instance_valid(spawned_site):
		return
	var delta: Vector2 = Vector2(spawned_site.current_coord - actor.current_coord)
	if delta.length_squared() == 0:
		return
	if _punch_tween and _punch_tween.is_running():
		_punch_tween.kill()
	var punch_offset: Vector2 = delta.normalized() * PUNCH_DISTANCE
	sprite.position = Vector2.ZERO
	_punch_tween = sprite.create_tween()
	_punch_tween.tween_property(sprite, "position", punch_offset, PUNCH_DURATION * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_punch_tween.tween_property(sprite, "position", Vector2.ZERO, PUNCH_DURATION * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func get_status() -> int:
	if current_step == BuildSteps.COMPLETED:
		return command_states.COMPLETED
	return command_states.EXECUTING


func get_descriptor() -> String:
	if build_data:
		return "Build %s at %s" % [build_data.display_name, target_coord]
	return "Build at %s" % [target_coord]
