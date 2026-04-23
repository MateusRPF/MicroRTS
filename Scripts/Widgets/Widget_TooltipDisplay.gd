extends PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameplayEvents.UI_tooltip_requested.connect(_show_tooltip)
	GameplayEvents.UI_tooltip_closed.connect(_hide_tooltip)
	GameplayEvents.selection_cleared.connect(_hide_tooltip)
	self.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _show_tooltip(config:TooltipConfiguration) -> void:
	print("Showing tooltip: %s" % [config.title])
	self.visible = true
	%Label_Title.text = config.title
	%Label_Desc.text = config.description
	#$Icon.texture = config.icon

func _hide_tooltip() -> void:
	print("Hiding tooltip")
	self.visible = false
