extends ComponentData
class_name ComponentData_Mover

@export var default_speed: int = 1 # Default speed for this mover, can be overridden by actor's attributes

func assemble_component(actor:GridObject) -> GridObjectComponent:
	var newMover = CMover.new()
	actor.add_child(newMover)
	newMover.initialize_component(actor)
	newMover.default_speed = default_speed
	return newMover
