extends ComponentData
class_name ComponentData_Garrison
@export var slot_configs:Array[GarrisonSlot]


func assemble_component(actor:GridObject) -> GridObjectComponent:
	var newComponent = CGarrison.new()
	newComponent.slot_configurations = slot_configs
	actor.add_child(newComponent)
	newComponent.initialize_component(actor)

	return newComponent