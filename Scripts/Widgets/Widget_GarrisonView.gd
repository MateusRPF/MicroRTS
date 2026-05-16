extends Widget_ComponentViewBase
class_name Widget_GarrisonView

@onready var entry_container = %Container_CurrentWorkers
var entry_prefab = preload("res://Prefabs/Widgets/Widget_GarrisonEntry.tscn")

var entries:Array[Widget_GarrisonEntry]

var garrison_component:CGarrison

func _load_view():

	garrison_component = viewing_component as CGarrison
	_create_station_entries()

func update_view():
	for entry in entries:
		entry.update_view()


func _create_station_entries():

	for child in entry_container.get_children():
		child.queue_free()

	entries.clear()

	for i in range(0,garrison_component.slot_configurations.size()):
		var new_entry = entry_prefab.instantiate() as Widget_GarrisonEntry
		entry_container.add_child(new_entry)
		new_entry.load_slot_config(garrison_component.slot_configurations[i], garrison_component)
		new_entry.button_clicked.connect(on_entry_clicked)
		entries.append(new_entry)


func on_entry_clicked(entry:Widget_GarrisonEntry):
	var slot = entry.associated_slot
	garrison_component.expulse_from_garrison(slot)
