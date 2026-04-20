extends ComponentData
class_name ComponentData_Stockpile

@export var acceptables:Array[GameResource]

func assemble_component(actor:GridObject) -> GridObjectComponent:
	var newComponent = CStockpile.new()
	actor.add_child(newComponent)
	newComponent.initialize_component(actor)
	newComponent.accepted_resources = acceptables
	return newComponent