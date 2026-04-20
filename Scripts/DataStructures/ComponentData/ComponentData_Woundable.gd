extends ComponentData
class_name ComponentData_Woundable


func assemble_component(actor:GridObject) -> GridObjectComponent:
	var newComponent = CWoundable.new()
	actor.add_child(newComponent)
	newComponent.initialize_component(actor)
	return newComponent