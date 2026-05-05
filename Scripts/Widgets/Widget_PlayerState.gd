extends PanelContainer

@export var player_state: PlayerState

var inventory_entries: Dictionary[GameResource, Node] = {}

@onready var container: VBoxContainer = %Container_ItemEntries
@onready var label_mana: Label = %Label_ManaValue
@onready var label_pop: Label = %Label_PopValue

func _ready() -> void:
	if player_state:
		update_essence(player_state.get_resource_value_by_name("Essence"))
		update_control()
		populate_inventory()
		GameplayEvents.essence_value_changed.connect(update_essence)
		GameplayEvents.resource_inventory_changed.connect(update_resource)

func update_essence(value: int) -> void:
	label_mana.text = str(value)

func update_control() -> void:
	if player_state:
		label_pop.text = str(player_state.current_controlValue) + "/" + str(player_state.max_controlValue)

func populate_inventory() -> void:
	# Clear existing entries
	for child in container.get_children():
		child.queue_free()
	inventory_entries.clear()
	
	for res in player_state.resource_inventory:
		if player_state.resource_inventory[res] > 0:
			add_or_update_entry(res, player_state.resource_inventory[res])

func update_resource(resource: GameResource, amount: int) -> void:
	if resource.proper_name == "Essence":
		update_essence(amount)
		return

	if amount > 0:
		add_or_update_entry(resource, amount)
	else:
		remove_entry(resource)

func add_or_update_entry(resource: GameResource, amount: int) -> void:
	if resource in inventory_entries:
		inventory_entries[resource].view_entry(resource, amount)
	else:
		var entry_scene = preload("res://Prefabs/Widgets/Widget_InventoryEntry.tscn")
		var entry = entry_scene.instantiate()
		container.add_child(entry)
		inventory_entries[resource] = entry
		entry.view_entry(resource, amount)

func remove_entry(resource: GameResource) -> void:
	if resource in inventory_entries:
		inventory_entries[resource].queue_free()
		inventory_entries.erase(resource)
