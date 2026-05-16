extends ComponentData
class_name ComponentData_CIntelligenceHolder

@export var default_intelligence: Registry.IntelligenceID = Registry.IntelligenceID.HELPLESS_WANDER


func assemble_component(actor: GridObject) -> GridObjectComponent:
	var newComponent := CIntelligenceHolder.new()
	actor.add_child(newComponent)
	newComponent.held_intelligence = Database.registry.intels[default_intelligence]
	newComponent.initialize_component(actor)
	return newComponent
