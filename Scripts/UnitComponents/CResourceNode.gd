extends GridObjectComponent
class_name CResourceNode


var resource: GameResource
var initial_amount: int = 10
var destroy_on_deplete: bool = true

var inventory:CInventory

func initialize_component(actor: GridObject) -> void:
	super.initialize_component(actor)
	inventory = actor.get_component(CInventory)

	inventory.deposit(resource,initial_amount)

func grant_resource(amount_requested: int)->int:
	var available = inventory.get_stored_qty(resource)
	var granted = min(available, amount_requested)

	inventory.withdrawal(resource,granted)
	if available - granted <=0 and destroy_on_deplete:
		deplete()

	return granted


func deplete():
	owner_object.destroy_object()
