extends ComponentData
class_name ComponentData_Harvester

@export var harvestables:Array[GameResource]

func assemble_component(actor:GridObject) -> GridObjectComponent:
	var newComponent = CHarvester.new()
	actor.add_child(newComponent)
	newComponent.initialize_component(actor)

	return newComponent
