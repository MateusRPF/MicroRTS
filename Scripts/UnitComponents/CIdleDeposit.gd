extends GridObjectComponent
class_name CIdleDeposit

var inventory: CInventory = null
var executor: CCommandExecutor = null


func initialize_component(actor: GridObject) -> void:
	super.initialize_component(actor)
	inventory = actor.get_component(CInventory)
	executor = actor.get_component(CCommandExecutor)
	if executor:
		executor.became_idle.connect(_on_became_idle)


func _on_became_idle(_exec: CCommandExecutor) -> void:
	if not inventory or not executor:
		return
	if owner_object.side != ActorData.Sides.PLAYER:
		return
	if not _has_any_item():
		return
	var cmd := Command_DepositAtStockpile.new(null, executor, owner_object.current_coord, null)
	executor.queue_command(cmd, false)


func _has_any_item() -> bool:
	for res in inventory._storage:
		if inventory._storage[res] > 0:
			return true
	return false
