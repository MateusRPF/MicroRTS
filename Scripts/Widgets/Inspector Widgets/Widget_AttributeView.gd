extends Widget_ComponentViewBase
class_name AttributeView

@onready var entry_container = %Entry_Container
var entry_prefab = preload("res://Prefabs/Widgets/Widget_AttributeEntry.tscn")

@export var ids_to_Show:Array[CAttributeSet.ATTR_ID]

var attrComponent:CAttributeSet

func _load_view():

	attrComponent = viewing_component as CAttributeSet
	_recreate_attrs()
	update_view()


func _recreate_attrs():
	for child in entry_container.get_children():
		child.queue_free()

	for attrID:CAttributeSet.ATTR_ID in attrComponent.attr_map:
		if (ids_to_Show.has(attrID)):
			var instance:CAttributeSet.AttributeInstance = attrComponent.get_attr_instance(attrID)
			if (instance):
				var entry:AttributeViewEntry = entry_prefab.instantiate() as AttributeViewEntry
				entry_container.add_child(entry)
				entry.show_attribute(instance)

	

func update_view():
	if not attrComponent:
		return


	
