extends Widget_ComponentViewBase
class_name InventoryView

@onready var entry_container = %Entry_Container
var entry_prefab = preload("res://Prefabs/Widgets/Widget_InventoryEntry.tscn")


var inventory_component:CInventory ##Todo - this should be split in Harvester view and Stockpile view.

var prefabMap:Dictionary[GameResource,InventoryEntry]

func _load_view():

	inventory_component = viewing_component as CInventory
	_recreate_entries()
	update_view()


func _recreate_entries():
	prefabMap.clear()
	for child in entry_container.get_children():
		child.queue_free()

	for resource:GameResource in inventory_component._storage:
		if inventory_component.get_stored_qty(resource) >0:
			_create_entry(resource, inventory_component.get_stored_qty(resource))

func _create_entry(resource:GameResource,value:int):
	var newPrefab:InventoryEntry = entry_prefab.instantiate() as InventoryEntry
	entry_container.add_child(newPrefab)
	prefabMap[resource] = newPrefab
	newPrefab.view_entry(resource, value)


	

func update_view():
	
	if not inventory_component:
		print("Did not find inventory.")
		return
	for resource in inventory_component._storage:
		if not prefabMap.has(resource):
			_recreate_entries()
			return
		prefabMap[resource].view_entry(resource, inventory_component.get_stored_qty(resource))


	
