extends ComponentData
class_name ComponentData_AttributeSet

@export var attrs: Dictionary[CAttributeSet.ATTR_ID, int]

func assemble_component(actor:GridObject) -> GridObjectComponent:
	var newSet:CAttributeSet = CAttributeSet.new()
	actor.add_child(newSet)
	newSet.initialize_component(actor)
	newSet.configure_base_attrs(attrs)

	return newSet