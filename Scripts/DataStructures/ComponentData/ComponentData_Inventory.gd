extends ComponentData
class_name ComponentData_Inventory

@export var max_storage:int = 10

func assemble_component(actor:GridObject) -> GridObjectComponent:
	var newComponent = CInventory.new()
	actor.add_child(newComponent)
	newComponent.max_storage_per_entry = max_storage
	newComponent.initialize_component(actor)
	return newComponent
