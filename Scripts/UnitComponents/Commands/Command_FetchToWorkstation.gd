extends Command
class_name Command_FetchToWorkStation


var issuer:CWorkStation
var current_step:FulfillSteps = FulfillSteps.FETCHING
var work_order:WorkOrderData
var mover:CMover
var inventory:CInventory
var state_machine: CStateMachine = null
var tiles_to_work_from:Array[Vector2i]
var _target_stockpile:CStockpile

enum FulfillSteps{FETCHING,RETURNING}


func finish_cache() -> void:
	issuer = target_actor.get_component(CWorkStation)
	mover = owner_executor.owner_object.get_component(CMover)
	state_machine = owner_executor.owner_object.get_component(CStateMachine)
	inventory = owner_executor.owner_object.get_component(CInventory)
	work_order = issuer.current_work_order
	tiles_to_work_from = target_actor.get_perimeter()


func get_descriptor() -> String:
	var base_string:String
	if target_actor and target_actor.data:
		match current_step:
			FulfillSteps.FETCHING:
				base_string ="Getting resources"
			FulfillSteps.RETURNING:
				base_string = "Delivering resources "
		return base_string + target_actor.data.actor_name
	return base_string

func get_status() -> int:
	return command_states.EXECUTING

func tick() -> void:
	super.tick()
	print("Ticking Work")
	if not is_instance_valid(issuer):
		print("No issuer. Finishing")
		finish_command()
		return
	if issuer.check_delivery_complete() or _has_needed_resource_in_inventory():
		if (current_step == FulfillSteps.FETCHING):
			mover.stop_move()
		current_step = FulfillSteps.RETURNING

	match current_step:
		FulfillSteps.FETCHING:
			_tick_fetching()
		FulfillSteps.RETURNING:
			_tick_delivery()


func _has_needed_resource_in_inventory() -> bool:
	if not inventory:
		return false
	for res in issuer.get_missing_resources():
		if inventory.get_stored_qty(res) > 0:
			return true
	return false

func _can_work_at_current_coord():
	return tiles_to_work_from.has( owner_executor.owner_object.current_coord)



func _deposit_at_site() -> void:
	if not issuer or not inventory:
		return
	var any_deposited: bool = false
	for res in issuer.get_missing_resources():
		if inventory.get_stored_qty(res) > 0:
			if issuer.deposit_from_unit(owner_executor.owner_object, res) > 0:
				any_deposited = true
	if any_deposited and is_instance_valid(issuer):
		pass
		# owner_executor.owner_object.play_interaction_with(issuer.owner_object)

func _tick_fetching():
	if not is_instance_valid(_target_stockpile): #
		_pick_next_stockpile()
		if not is_instance_valid(_target_stockpile):
			finish_command()
			return
	if _at_stockpile_deliverable(_target_stockpile.owner_object):
		_withdraw_from_stockpile(_target_stockpile)
		return
	if not mover.is_moving():
		var coord: Vector2i = _get_best_coord_to_enact(_target_stockpile.owner_object)
		if coord == Vector2i(-1, -1):
			_target_stockpile = null
			return
		state_machine.request_state(CStateMachine.StateID.MOVE, {"target_tile": coord})


func _tick_delivery() -> void:
		if _can_work_at_current_coord():
			_deposit_at_site()
			if not issuer.check_delivery_complete():
				current_step = FulfillSteps.FETCHING
			else:
				_enter_site()
		if not mover.is_moving(): #Move to deliver to Work site.
			var best_coord: Vector2i = _get_best_coord_to_enact(issuer.owner_object)
			if best_coord == Vector2i(-1, -1):
				finish_command()
				return
			state_machine.request_state(CStateMachine.StateID.MOVE, {"target_tile": best_coord})
		return
	
	
func _enter_site():
	var garrison:CGarrison = issuer.owner_object.get_component(CGarrison)
	garrison.enter_garrison(owner_executor.owner_object)


func _pick_next_stockpile() -> void:
	var actor: GridObject = owner_executor.owner_object
	var grid: GridManager = actor.grid_manager
	var state: PlayerState = actor.player_state
	if not issuer or not state:
		_target_stockpile = null
		return

	var candidates: Array[GridObject] = grid.get_objects_in_radius(actor.current_coord, 20, CStockpile)
	var best: GridObject = null
	var best_dist: float = INF
	for obj in candidates:
		if obj == issuer.owner_object:
			continue
		if not obj.get_component(CStockpile):
			continue
		var dist: float = grid.calculate_distance(actor.current_coord, obj.current_coord)
		if dist < best_dist:
			best_dist = dist
			best = obj
	_target_stockpile = best.get_component(CStockpile)


func _at_stockpile_deliverable(stockpile_obj: GridObject) -> bool:
	var stockpile: CStockpile = stockpile_obj.get_component(CStockpile)
	if not stockpile:
		return false
	return stockpile.calculate_deliverable_tiles().has(owner_executor.owner_object.current_coord)

func _withdraw_from_stockpile(stockpile: CStockpile) -> void:
	var player_state = owner_executor.owner_object.player_state
	if not stockpile or not inventory or not issuer or not state_machine:
		_target_stockpile = null
		return
	var any_withdrawn: bool = false
	var missing_res:Dictionary[GameResource,int] = issuer.get_missing_resources()
	for res in missing_res:
		var need: int = missing_res[res]
		var unit_room: int = inventory.max_storage_per_entry - inventory.get_stored_qty(res)
		var pool: int = player_state.resource_inventory.get(res, 0)
		var amount: int = min(need, min(unit_room, pool))
		if amount > 0:
			player_state.remove_resource(res, amount)
			inventory.deposit(res, amount)
			any_withdrawn = true
	if any_withdrawn:
		owner_executor.owner_object.play_interaction_with(stockpile.owner_object)
	_target_stockpile = null
