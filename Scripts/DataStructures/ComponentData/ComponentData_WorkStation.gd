extends ComponentData
class_name ComponentData_WorkStation

@export var work_orders:Array[WorkOrderData]


func assemble_component(actor:GridObject) -> GridObjectComponent:
	var newComponent = CWorkStation.new()
	newComponent.available_work_orders = work_orders
	actor.add_child(newComponent)
	newComponent.initialize_component(actor)

	return newComponent