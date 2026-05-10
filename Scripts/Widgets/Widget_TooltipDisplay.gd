extends PanelContainer

var entry_prefab = preload("res://Prefabs/Widgets/Widget_InventoryEntry.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameplayEvents.UI_tooltip_requested.connect(_show_tooltip)
	GameplayEvents.UI_tooltip_closed.connect(_hide_tooltip)
	GameplayEvents.selection_cleared.connect(_hide_tooltip)
	self.visible = false

func _show_tooltip(config:TooltipConfiguration) -> void:
	self.visible = true
	%Label_Title.text = config.title
	%Label_Desc.text = config.description

	#hotkey
	if (config.hotkey):
		%Label_Hotkey.visible = true
		%Label_Hotkey.text = "[%s] " % [OS.get_keycode_string(config.hotkey)]
	else:
		%Label_Hotkey.visible = false

	# material costs
	if (config.costs):
		%Container_Costs.visible = true
		for child in %Costs_Entries.get_children():
			child.queue_free()
		for cost in config.costs:
			var new_entry = entry_prefab.instantiate() as InventoryEntry
			%Costs_Entries.add_child(new_entry)
			new_entry.view_entry(cost.cost_resource,cost.cost_amount)
	else:
		%Container_Costs.visible = false

	#immediate cost
	if (config.immediate_cost):
		var available:bool = true
		if (config.immediate_cost.validate_on_wallet):
			var playerState:PlayerState = GameplayEvents.embodied_player_state
			available = playerState.get_resource_value(config.immediate_cost.cost_resource) >= config.immediate_cost.cost_amount

		%Widget_EssenceCost.visible = true
		%Widget_EssenceCost.view_entry(config.immediate_cost.cost_resource,config.immediate_cost.cost_amount,available)
		
	else:
		%Widget_EssenceCost.visible = false

	#TODO ADD REQUIRED WORKERS AND OTHER REQUIREMENTS








func _hide_tooltip() -> void:
	self.visible = false
