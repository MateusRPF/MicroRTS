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
	if not entry_container:
		entry_container = %WoundContainer
	for child in entry_container.get_children():
		child.queue_free()

	for i in range(0,wound_component.get_max_wounds()):
		var newPanel:Panel = entry_prefab.instantiate()
		entry_container.add_child(newPanel)

func update_view():
	if not wound_component:
		return
	var progressBar:ProgressBar = %ProgressBar1 as ProgressBar
	# var current_wound_panels:int = entry_container.get_child_count()
	# if (current_wound_panels != wound_component.get_max_wounds()):
	# 	_recreate_wound_views()
	var max_health:int = wound_component.get_max_wounds()
	progressBar.max_value = max_health
	var health:int = wound_component.get_current_health()
	progressBar.value = health
	# for childIndex in range(entry_container.get_child_count()):
	# 	if childIndex+1 > health:
	# 		entry_container.get_child(childIndex).modulate.a = 0
	# 	else:
	# 		entry_container.get_child(childIndex).modulate.a = 1

	
