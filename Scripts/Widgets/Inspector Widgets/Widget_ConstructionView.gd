extends Widget_ComponentViewBase
class_name ConstructionView

@onready var entry_container = %ConstructionProgressContainer
var entry_prefab = preload("res://Prefabs/Widgets/Widget_WoundPanel.tscn")

var construction_component: CUnderConstruction


func _load_view():
	construction_component = viewing_component as CUnderConstruction
	_recreate_progress_views()
	update_view()


func _recreate_progress_views():
	if not entry_container:
		entry_container = %ConstructionProgressContainer
	for child in entry_container.get_children():
		child.queue_free()
	for i in range(0, CUnderConstruction.MAX_PROGRESS):
		var newPanel: Panel = entry_prefab.instantiate()
		entry_container.add_child(newPanel)


func update_view():
	if not construction_component:
		return
	var current_panels: int = entry_container.get_child_count()
	if current_panels != CUnderConstruction.MAX_PROGRESS:
		_recreate_progress_views()
	var progress: int = construction_component.current_progress
	for i in range(entry_container.get_child_count()):
		if i + 1 > progress:
			entry_container.get_child(i).modulate.a = 0
		else:
			entry_container.get_child(i).modulate.a = 1
