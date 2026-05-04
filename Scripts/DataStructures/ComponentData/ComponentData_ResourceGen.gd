extends ComponentData
class_name ComponentData_ResourceGen

@export var resource: GameResource
@export var amount_per_generation: int = 1
@export var generation_interval_seconds: float = 1.0

func assemble_component(actor:GridObject) -> GridObjectComponent:
	var newComponent = CResourceGen.new()
	actor.add_child(newComponent)
	newComponent.resource = resource
	newComponent.amount_per_generation = amount_per_generation
	newComponent.generation_interval_seconds = generation_interval_seconds
	newComponent.initialize_component(actor)
	return newComponent