extends ComponentData
class_name ComponentData_Builder

@export var buildable: Array[CommandData]

func assemble_component(actor: GridObject) -> GridObjectComponent:
	var newComponent := CBuilder.new()
	newComponent.buildable = buildable
	actor.add_child(newComponent)
	newComponent.initialize_component(actor)
	return newComponent
