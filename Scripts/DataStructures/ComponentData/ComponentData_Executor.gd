extends ComponentData
class_name ComponentData_Executor


func assemble_component(actor:GridObject) -> GridObjectComponent:
	var newComponent = CCommandExecutor.new()
	actor.add_child(newComponent)
	newComponent.initialize_component(actor)

	return newComponent