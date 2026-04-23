extends ComponentData
class_name ComponentData_CarryVisual


func assemble_component(actor: GridObject) -> GridObjectComponent:
	var newComponent := CCarryVisual.new()
	actor.add_child(newComponent)
	newComponent.initialize_component(actor)
	return newComponent
