extends Widget_ComponentViewBase
class_name WoundView

@onready var entry_container = %WoundContainer
var entry_prefab = preload("res://Prefabs/Widgets/Widget_WoundPanel.tscn")

var wound_component:CWoundable

func _load_view():

	wound_component = viewing_component as CWoundable
	_recreate_wound_views()
	update_view()


func _recreate_wound_views():
	for child in entry_container.get_children():
		child.queue_free()

	for i in range(0,wound_component.get_max_wounds()):
		var newPanel:Panel = entry_prefab.instantiate()
		entry_container.add_child(newPanel)

func update_view():
	if not wound_component:
		return

	var current_wound_panels:int = entry_container.get_child_count()
	if (current_wound_panels != wound_component.get_max_wounds()):
		_recreate_wound_views()
	
	var health:int = wound_component.get_current_health()

	for childIndex in range(entry_container.get_child_count()):
		if childIndex+1 > health:
			entry_container.get_child(childIndex).modulate.a = 0
		else:
			entry_container.get_child(childIndex).modulate.a = 1

	
