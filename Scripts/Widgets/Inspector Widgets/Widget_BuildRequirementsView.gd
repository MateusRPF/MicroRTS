extends Widget_ComponentViewBase
class_name BuildRequirementsView

@onready var entry_container = %BuildRequirementsContainer
var entry_prefab = preload("res://Prefabs/Widgets/Widget_InventoryEntry.tscn")

var requirements_component: CBuildRequirements


func _load_view():
	requirements_component = viewing_component as CBuildRequirements
	_recreate_entries()


func _recreate_entries():
	if not entry_container:
		entry_container = %BuildRequirementsContainer
	for child in entry_container.get_children():
		child.queue_free()
	if not requirements_component:
		return
	for res in requirements_component.required:
		var entry: InventoryEntry = entry_prefab.instantiate() as InventoryEntry
		entry_container.add_child(entry)
		_update_entry(entry, res)


func _update_entry(entry: InventoryEntry, res: GameResource) -> void:
	var delivered: int = requirements_component.delivered.get(res, 0)
	var required: int = requirements_component.required.get(res, 0)
	entry.get_node("%Image_ResourceSprite").texture = res.icon
	entry.get_node("%Label_Value").text = "%d/%d" % [delivered, required]


func update_view():
	if not requirements_component:
		return
	var children := entry_container.get_children()
	if children.size() != requirements_component.required.size():
		_recreate_entries()
		return
	var i: int = 0
	for res in requirements_component.required:
		_update_entry(children[i] as InventoryEntry, res)
		i += 1
