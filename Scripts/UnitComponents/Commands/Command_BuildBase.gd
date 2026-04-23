extends Command
class_name Command_BuildBase

var mover: CMover = null
var state_machine: CStateMachine = null
var inventory: CInventory = null
var target_construction: CUnderConstruction = null
var target_requirements: CBuildRequirements = null
var site: GridObject = null
var current_step: BuildSteps = BuildSteps.FETCHING
var footprint_coords: Array[Vector2i] = []
var perimeter_coords: Array[Vector2i] = []
var _target_stockpile: GridObject = null

const SEARCH_RADIUS: int = 20
const PUNCH_DISTANCE: float = 14.0
const PUNCH_DURATION: float = 0.16
var _punch_tween: Tween = null

enum BuildSteps {
	FETCHING,
	BUILDING,
	COMPLETED
}


func finish_cache() -> void:
	var actor: GridObject = owner_executor.owner_object
	mover = actor.get_component(CMover)
	state_machine = actor.get_component(CStateMachine)
	inventory = actor.get_component(CInventory)


func _bind_to_site(new_site: GridObject) -> void:
	site = new_site
	target_construction = new_site.get_component(CUnderConstruction)
	target_requirements = new_site.get_component(CBuildRequirements)
	footprint_coords = new_site.get_covered_coords()
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


func tick() -> void:
	super.tick()
	if not is_instance_valid(site) or not is_instance_valid(target_construction):
		current_step = BuildSteps.COMPLETED
		finish_command()
		return

	match current_step:
		BuildSteps.FETCHING:
			if target_construction.is_complete():
				current_step = BuildSteps.COMPLETED
				finish_command()
				return
			if target_requirements and target_requirements.has_all_deposited():
				current_step = BuildSteps.BUILDING
				return
			_tick_fetching()
		BuildSteps.BUILDING:
			_tick_building()


func _tick_fetching() -> void:
	if _has_needed_resource_in_inventory():
		if _at_site_perimeter():
			_deposit_at_site()
			return
		if not mover.is_moving():
			var adjacent: Vector2i = _find_walkable_in_perimeter()
			if adjacent == Vector2i(-1, -1):
				current_step = BuildSteps.COMPLETED
				finish_command()
				return
			state_machine.request_state(CStateMachine.StateID.MOVE, {"target_tile": adjacent})
		return
	if not is_instance_valid(_target_stockpile):
		_pick_next_stockpile()
		if not is_instance_valid(_target_stockpile):
			current_step = BuildSteps.COMPLETED
			finish_command()
			return
	if _at_stockpile_deliverable(_target_stockpile):
		_withdraw_from_stockpile(_target_stockpile)
		return
	if not mover.is_moving():
		var coord: Vector2i = _find_walkable_at_stockpile(_target_stockpile)
		if coord == Vector2i(-1, -1):
			_target_stockpile = null
			return
		state_machine.request_state(CStateMachine.StateID.MOVE, {"target_tile": coord})


func _tick_building() -> void:
	if target_construction.is_complete():
		current_step = BuildSteps.COMPLETED
		finish_command()
		return
	if target_requirements and not target_requirements.has_all_deposited():
		current_step = BuildSteps.FETCHING
		return
	var actor: GridObject = owner_executor.owner_object
	if not perimeter_coords.has(actor.current_coord):
		if not mover.is_moving():
			var adjacent: Vector2i = _find_walkable_in_perimeter()
			if adjacent == Vector2i(-1, -1):
				current_step = BuildSteps.COMPLETED
				finish_command()
				return
			state_machine.request_state(CStateMachine.StateID.MOVE, {"target_tile": adjacent})
		return
	_play_punch()
	target_construction.shake()
	if target_construction.add_progress(1):
		current_step = BuildSteps.COMPLETED
		finish_command()


func _has_needed_resource_in_inventory() -> bool:
	if not inventory or not target_requirements:
		return false
	for res in target_requirements.needed_resources():
		if inventory.get_stored_qty(res) > 0:
			return true
	return false


func _at_site_perimeter() -> bool:
	return perimeter_coords.has(owner_executor.owner_object.current_coord)


func _find_walkable_in_perimeter() -> Vector2i:
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


func _deposit_at_site() -> void:
	if not target_requirements or not inventory:
		return
	var any_deposited: bool = false
	for res in target_requirements.needed_resources():
		if inventory.get_stored_qty(res) > 0:
			if target_requirements.deposit_from_unit(owner_executor.owner_object, res) > 0:
				any_deposited = true
	if any_deposited and is_instance_valid(site):
		owner_executor.owner_object.play_interaction_with(site)


func _pick_next_stockpile() -> void:
	var actor: GridObject = owner_executor.owner_object
	var grid: GridManager = actor.grid_manager
	var state: PlayerState = actor.player_state
	if not target_requirements or not state:
		_target_stockpile = null
		return
	var needed: Array[GameResource] = target_requirements.needed_resources()
	if needed.is_empty():
		_target_stockpile = null
		return
	var pool_has_any: bool = false
	for res in needed:
		if state.resourceInventory.get(res, 0) > 0:
			pool_has_any = true
			break
	if not pool_has_any:
		_target_stockpile = null
		return
	var candidates: Array[GridObject] = grid.get_objects_in_radius(actor.current_coord, SEARCH_RADIUS, CStockpile)
	var best: GridObject = null
	var best_dist: float = INF
	for obj in candidates:
		if obj == site:
			continue
		if not obj.get_component(CStockpile):
			continue
		var dist: float = grid.calculate_distance(actor.current_coord, obj.current_coord)
		if dist < best_dist:
			best_dist = dist
			best = obj
	_target_stockpile = best


func _at_stockpile_deliverable(stockpile_obj: GridObject) -> bool:
	var stockpile: CStockpile = stockpile_obj.get_component(CStockpile)
	if not stockpile:
		return false
	return stockpile.calculate_deliverable_tiles().has(owner_executor.owner_object.current_coord)


func _find_walkable_at_stockpile(stockpile_obj: GridObject) -> Vector2i:
	var stockpile: CStockpile = stockpile_obj.get_component(CStockpile)
	if not stockpile:
		return Vector2i(-1, -1)
	var actor: GridObject = owner_executor.owner_object
	var grid: GridManager = actor.grid_manager
	var candidates: Array[Vector2i] = []
	for coord in stockpile.calculate_deliverable_tiles():
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


func _withdraw_from_stockpile(stockpile_obj: GridObject) -> void:
	var stockpile: CStockpile = stockpile_obj.get_component(CStockpile)
	var state: PlayerState = owner_executor.owner_object.player_state
	if not stockpile or not inventory or not target_requirements or not state:
		_target_stockpile = null
		return
	var any_withdrawn: bool = false
	for res in target_requirements.needed_resources():
		var need: int = target_requirements.remaining_need(res)
		var unit_room: int = inventory.max_storage_per_entry - inventory.get_stored_qty(res)
		var pool: int = state.resourceInventory.get(res, 0)
		var amount: int = min(need, min(unit_room, pool))
		if amount > 0:
			state.remove_resource(res, amount)
			inventory.deposit(res, amount)
			any_withdrawn = true
	if any_withdrawn:
		owner_executor.owner_object.play_interaction_with(stockpile_obj)
	_target_stockpile = null


func _play_punch() -> void:
	var actor: GridObject = owner_executor.owner_object
	var pivot: Node2D = actor.get_node_or_null("%ViewPivot")
	if not pivot or not is_instance_valid(site):
		return
	var delta: Vector2 = Vector2(site.current_coord - actor.current_coord)
	if delta.length_squared() == 0:
		return
	if _punch_tween and _punch_tween.is_running():
		_punch_tween.kill()
	var punch_offset: Vector2 = delta.normalized() * PUNCH_DISTANCE
	pivot.position = Vector2.ZERO
	_punch_tween = pivot.create_tween()
	_punch_tween.tween_property(pivot, "position", punch_offset, PUNCH_DURATION * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_punch_tween.tween_property(pivot, "position", Vector2.ZERO, PUNCH_DURATION * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func get_status() -> int:
	if current_step == BuildSteps.COMPLETED:
		return command_states.COMPLETED
	return command_states.EXECUTING
