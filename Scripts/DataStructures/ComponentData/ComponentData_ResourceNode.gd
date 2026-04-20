extends ComponentData
class_name ComponentData_ResourceNode

@export var resource: GameResource
@export var amount: int = 10
@export var destroy_on_deplete: bool = true

func assemble_component(actor:GridObject) -> GridObjectComponent:
	var newComponent = CResourceNode.new()
	actor.add_child(newComponent)
	
	newComponent.initial_amount = amount
	newComponent.resource = resource
	newComponent.destroy_on_deplete = destroy_on_deplete
	newComponent.initialize_component(actor)

	return newComponent
