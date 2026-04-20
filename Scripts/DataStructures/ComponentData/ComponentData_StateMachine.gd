extends ComponentData
class_name ComponentData_StateMachine


func assemble_component(actor:GridObject) -> GridObjectComponent:
	var newComponent = CStateMachine.new()
	actor.add_child(newComponent)
	newComponent.initialize_component(actor)

	# var newDraw = CStateDraw.new()
	# actor.add_child(newDraw)
	# newDraw.hook_to_actor(newComponent)

	return newComponent