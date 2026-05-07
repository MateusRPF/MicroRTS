extends Command
class_name Command_FulfillWorkOrder


var issuer:CWorkOrderIssuer
var current_step:FulfillSteps = FulfillSteps.DELIVERING
var work_order:WorkOrderData
var mover:CMover
var inventory:CInventory
var state_machine: CStateMachine = null
var tiles_to_work_from:Array[Vector2i]
var _target_stockpile:CStockpile

enum FulfillSteps{DELIVERING, WORKING, COMPLETED}


func finish_cache() -> void:
	issuer = target_actor.get_component(CWorkOrderIssuer)
	mover = owner_executor.owner_object.get_component(CMover)
	state_machine = owner_executor.owner_object.get_component(CStateMachine)
	inventory = owner_executor.owner_object.get_component(CInventory)
	work_order = issuer.current_work_order
	tiles_to_work_from = target_actor.get_perimeter()


func get_descriptor() -> String:
	var base_string:String
	if target_actor and target_actor.data:
		match current_step:
			FulfillSteps.DELIVERING:
				base_string ="Deliver to"
			FulfillSteps.WORKING:
				base_string = "Working in "
		return base_string + target_actor.data.actor_name
	return base_string

func get_status() -> int:
	if current_step == FulfillSteps.COMPLETED:
		return command_states.COMPLETED
	else:
		return command_states.EXECUTING

func tick() -> void:
	super.tick()
	print("Ticking Work")
	if not is_instance_valid(issuer):
		print("No issuer. Finishing")
		finish_command()
		return

	match current_step:
		FulfillSteps.DELIVERING:
			print("Delivering")
			if issuer.work_order_status == CWorkOrderIssuer.WorkOrderStatus.DELIVERY:
				_tick_delivery()
				return
			else:
				current_step = FulfillSteps.WORKING
				return

		FulfillSteps.WORKING:
			print("Working")
			if issuer.work_order_status == CWorkOrderIssuer.WorkOrderStatus.WORKING:
				_tick_work()
				return
			else:
				current_step = FulfillSteps.COMPLETED
				return
	print("Fulfill step is Completed.")
	finish_command()



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
		owner_executor.owner_object.play_interaction_with(issuer.owner_object)


func _tick_delivery() -> void:
	#Deliver to work site
	if _has_needed_resource_in_inventory():
		if _can_work_at_current_coord():
			_deposit_at_site()
			_pick_next_stockpile()
			return
		if not mover.is_moving(): #Move to deliver to Work site.
			var best_coord: Vector2i = _get_best_coord_to_enact(issuer.owner_object)
			if best_coord == Vector2i(-1, -1):
				current_step = FulfillSteps.COMPLETED
				finish_command()
				return
			state_machine.request_state(CStateMachine.StateID.MOVE, {"target_tile": best_coord})
		return
	
	#Get to the nearest Stockpile
	if not is_instance_valid(_target_stockpile): #
		_pick_next_stockpile()
		if not is_instance_valid(_target_stockpile):
			current_step = FulfillSteps.COMPLETED
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



func _tick_work():
	if not (work_order) or not (issuer):
		finish_command()
		return
	if	issuer.work_order_status != CWorkOrderIssuer.WorkOrderStatus.WORKING:
		current_step = FulfillSteps.DELIVERING
		return

	if not _can_work_at_current_coord():
		if not mover.is_moving(): #Move to deliver to Work site.
			var best_coord: Vector2i = _get_best_coord_to_enact(issuer.owner_object)
			if best_coord == Vector2i(-1, -1):
				current_step = FulfillSteps.COMPLETED
				finish_command()
				return
			state_machine.request_state(CStateMachine.StateID.MOVE, {"target_tile": best_coord})
		return
	else:
		owner_executor.owner_object.play_interaction_with(issuer.owner_object)
		issuer.receive_work_from_unit(owner_executor.owner_object)
		if (issuer.current_work_received >= work_order.work_required):
			current_step = FulfillSteps.COMPLETED
			finish_command()
