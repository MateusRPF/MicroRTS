extends Command
class_name Command_DepositAtStockpile

var mover: CMover = null
var state_machine: CStateMachine = null
var inventory: CInventory = null
var _done: bool = false
var _target_stockpile: GridObject = null

const SEARCH_RADIUS: int = 20


func finish_cache() -> void:
	var actor: GridObject = owner_executor.owner_object
	mover = actor.get_component(CMover)
	state_machine = actor.get_component(CStateMachine)
	inventory = actor.get_component(CInventory)


func start_command() -> bool:
	emit_signal("command_started", self)
	return true


func tick() -> void:
	super.tick()
	if not inventory or _inventory_empty():
		_done = true
		finish_command()
		return

	if not is_instance_valid(_target_stockpile):
		_target_stockpile = _find_stockpile_for_carried()
		if not is_instance_valid(_target_stockpile):
			_done = true
			finish_command()
			return

	if _at_stockpile_deliverable(_target_stockpile):
		_deposit_all(_target_stockpile)
		_target_stockpile = null
		return

	if not mover.is_moving():
		var coord: Vector2i = _find_walkable_at_stockpile(_target_stockpile)
		if coord == Vector2i(-1, -1):
			_target_stockpile = null
			return
		state_machine.request_state(CStateMachine.StateID.MOVE, {"target_tile": coord})


func _inventory_empty() -> bool:
	for res in inventory._storage:
		if inventory._storage[res] > 0:
			return false
	return true


func _find_stockpile_for_carried() -> GridObject:
	var actor: GridObject = owner_executor.owner_object
	var grid: GridManager = actor.grid_manager
	var carried: Array[GameResource] = []
	for res in inventory._storage:
		if inventory._storage[res] > 0:
			carried.append(res)
	if carried.is_empty():
		return null
	var candidates: Array[GridObject] = grid.get_objects_in_radius(actor.current_coord, SEARCH_RADIUS, CStockpile)
	var best: GridObject = null
	var best_dist: float = INF
	for obj in candidates:
		if not obj.get_component(CStockpile):
			continue
		var dist: float = grid.calculate_distance(actor.current_coord, obj.current_coord)
		if dist < best_dist:
			best_dist = dist
			best = obj
	return best


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


func _deposit_all(stockpile_obj: GridObject) -> void:
	var stockpile: CStockpile = stockpile_obj.get_component(CStockpile)
	var state: PlayerState = owner_executor.owner_object.player_state
	if not stockpile or not state:
		return
	var carried: Array[GameResource] = []
	for res in inventory._storage:
		if inventory._storage[res] > 0:
			carried.append(res)
	var any_deposited: bool = false
	for res in carried:
		var amount: int = inventory.get_stored_qty(res)
		if amount <= 0:
			continue
		var withdrawn: int = inventory.withdrawal(res, amount)
		if withdrawn > 0:
			state.add_resource(res, withdrawn)
			any_deposited = true
	if any_deposited:
		owner_executor.owner_object.play_interaction_with(stockpile_obj)


func get_status() -> int:
	return command_states.COMPLETED if _done else command_states.EXECUTING


func get_descriptor() -> String:
	return "Storing resources"
