extends ComponentData
class_name ComponentData_CIntelligenceHolder

@export var default_intelligence: IntelligenceDatabase.IntelligenceID = IntelligenceDatabase.IntelligenceID.HELPLESS_WANDER


func assemble_component(actor: GridObject) -> GridObjectComponent:
	var newComponent := CIntelligenceHolder.new()
	actor.add_child(newComponent)
	newComponent.held_intelligence = IntelligenceDB.intels[default_intelligence]
	newComponent.initialize_component(actor)
	return newComponent
