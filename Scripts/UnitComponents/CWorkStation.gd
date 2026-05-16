extends GridObjectComponent
class_name CWorkStation


@export var available_work_orders:Array[WorkOrderData] = []

var queued_work_orders:Array[WorkOrderData]
const MAX_WORK_ORDERS:int = 5

var delivered_resources: Dictionary[GameResource, int] = {}
var current_work_order:WorkOrderData
var current_work_received:int = 0
var work_order_status:WorkOrderStatus = WorkOrderStatus.NONE

var garrison: CGarrison

var particles:CPUParticles2D



enum WorkOrderStatus {
	NONE,
	DELIVERY,
	WORKING,
	COMPLETED
}

func initialize_component(actor: GridObject) -> void:
	super.initialize_component(actor)
	garrison = actor.get_component(CGarrison)
	particles = actor.get_node("%WorkParticles") as CPUParticles2D

func get_missing_resources()-> Dictionary[GameResource, int]:
	var result:Dictionary[GameResource,int]
	if (current_work_order):
		for res in current_work_order.get_resource_costs():
			var have:int = 0
			if (delivered_resources.has(res)):
				have = delivered_resources[res]
			var need:int = current_work_order.get_resource_costs()[res]
			if (have < need):
				result[res] = need - have
			
	return result


func validate_work_order(work_order:WorkOrderData)->bool:
	print("validating work order " + work_order.name)
	if queued_work_orders.size() >=4:
		return false
	if not available_work_orders.has(work_order):
		push_error("Work order %s is not available for this issuer" % work_order)
		return false 
	return true

func issue_work_order(work_order:WorkOrderData) -> bool:
	
	print("Issue work order: " + work_order.name)
	if not validate_work_order(work_order):
		print("Issue work order FAILED")
		return false

	if (current_work_order):
		queued_work_orders.append(work_order)
	else:
		start_work_order(work_order)

	owner_object.player_state.remove_resource(work_order.immediate_cost,work_order.immediate_cost_value)
	return true

func start_work_order(new_work:WorkOrderData):
	print("Start work order: " + new_work.name)
	current_work_order = new_work
	current_work_received = 0
	delivered_resources.clear()
	work_order_status = WorkOrderStatus.DELIVERY

func cancel_work_order_at_index(index:int):
	print("attempting cancel at index %s" %[index])
	if index == 0:
		if (current_work_order):
			owner_object.player_state.add_resource(current_work_order.immediate_cost,current_work_order.immediate_cost_value)
		
		current_work_order = null
		delivered_resources.clear()
		current_work_received = 0
		trigger_next_order()
	else:
		if (queued_work_orders.size() >= index):
			var removed_order = queued_work_orders[index-1]
			owner_object.player_state.add_resource(removed_order.immediate_cost,removed_order.immediate_cost_value)
			queued_work_orders.remove_at(index-1)
	pass

func trigger_next_order():
	if queued_work_orders.size()>0:
		start_work_order(queued_work_orders.pop_front())

func _on_tick_received() -> void:
	if not current_work_order:
		return
	if work_order_status == WorkOrderStatus.NONE:
		return
	
	if work_order_status == WorkOrderStatus.DELIVERY:
		if check_delivery_complete():
			print("PASSING TO WORKING")
			work_order_status = WorkOrderStatus.WORKING
		else:
			_manage_delivery_logistics()

	elif work_order_status == WorkOrderStatus.WORKING:
		_process_internal_work()
		if current_work_received >= current_work_order.work_required:
			work_order_status = WorkOrderStatus.COMPLETED
			_on_work_order_completed()


func _manage_delivery_logistics() -> void:
	if not garrison:
		return
		
	# Check if we have missing resources that need fetching
	var missing = get_missing_resources()
	if missing.is_empty():
		return

	# See if we have an available internal worker to send out
	var worker = garrison.deploy_worker()
	if worker:
		_assign_fetch_command_to_unit(worker)


func _assign_fetch_command_to_unit(unit: GridObject) -> void:
	var data = CommandData.new()
	var executor:CCommandExecutor = unit.get_component(CCommandExecutor)
	var newCommand = Command_FetchToWorkStation.new(data, unit.get_component(CCommandExecutor),Vector2i.ZERO,owner_object)
	executor.queue_command(newCommand)


func _process_internal_work() -> void:
	particles.emitting = true
	if not garrison:
		return

	var total_work_power: int = 0

	for slot in garrison.garrison_slots:
		var worker = garrison.garrison_slots[slot]
		if worker and not slot in garrison.deployed_slots:
			var attributes = worker.get_component(CAttributeSet) # Use your exact attribute component class
			if attributes:
				total_work_power += attributes.get_attr(CAttributeSet.ATTR_ID.ATTR_WORK_POWER)

	if total_work_power > 0:
		current_work_received += total_work_power



func check_delivery_complete() -> bool:
	if (current_work_order):
		return get_missing_resources().size()<=0
	return true

func _on_work_order_completed():
	particles.emitting = false
	current_work_order.perform_payload(self.owner_object)
	current_work_order = null
	trigger_next_order()



func deposit_from_unit(unit: GridObject, res: GameResource) -> int:
	var inventory: CInventory = unit.get_component(CInventory)
	if not inventory:
		return 0
	var need: int = get_missing_resources()[res]
	if need <= 0:
		return 0
	var available: int = inventory.get_stored_qty(res)
	var amount: int = min(need, available)
	if amount <= 0:
		return 0
	var withdrawn: int = inventory.withdrawal(res, amount)
	if withdrawn <= 0:
		return 0
	delivered_resources[res] = delivered_resources.get(res, 0) + withdrawn

	# _refresh_icons()
	return withdrawn
