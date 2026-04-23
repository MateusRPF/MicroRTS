extends ComponentData
class_name ComponentData_IdleDeposit


func assemble_component(actor: GridObject) -> GridObjectComponent:
	var newComponent := CIdleDeposit.new()
	actor.add_child(newComponent)
	newComponent.initialize_component(actor)
	return newComponent
