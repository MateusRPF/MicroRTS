@tool
extends PanelContainer
class_name BasicButton

signal on_pressed()
signal on_hovered()
signal on_released()
var tooltip_config:TooltipConfiguration

# -- Visual States --
@export var normal_tint: Color = Color(1, 1, 1, 0):
	set(value):
		normal_tint = value
		var bg = get_node_or_null("%ColorRect")
		if bg: bg.color = normal_tint

@export var pressed_tint: Color = Color(0, 0, 0, 0.3)

@export var hover_tint: Color = Color(1, 1, 1, 0.1)

@export var disabled_tint: Color = Color(1, 1, 1, 0.1)

# -- Content --
@export var icon: Texture2D:
	set(value):
		icon = value
		var tex = get_node_or_null("%TextureRect")
		if tex: tex.texture = icon

@export var text: String = "":
	set(value):
		text = value
		var lbl = get_node_or_null("%Label")
		if lbl: lbl.text = text


func _ready() -> void:
	# Enforce initial state when the scene actually runs
	var tex = get_node_or_null("%TextureRect")
	if tex: tex.texture = icon
	
	var lbl = get_node_or_null("%Label")
	if lbl: lbl.text = text
	
	var bg = get_node_or_null("%ColorRect")
	if bg: bg.color = normal_tint
	
	# Gameplay connections
	if not Engine.is_editor_hint():
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)

func disable_button():
	var bg = get_node_or_null("%ColorRect")
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bg: bg.color = disabled_tint

func enable_button():
	var bg = get_node_or_null("%ColorRect")
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	if bg: bg.color = normal_tint

# -- Mouse Interaction Logic --

func _on_mouse_entered() -> void:
	var bg = get_node_or_null("%ColorRect")
	bg.color = hover_tint
	print("Hovered button")
	if (tooltip_config):
		GameplayEvents.UI_tooltip_requested.emit(tooltip_config)
	on_hovered.emit()

func _on_mouse_exited() -> void:
	var bg = get_node_or_null("%ColorRect")
	print("Exited button")
	if (tooltip_config):
		GameplayEvents.UI_tooltip_closed.emit()
	if bg: bg.color = normal_tint

func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		print("Pressed button")
		var bg = get_node_or_null("%ColorRect")
		if event.pressed:
			if bg: bg.color = pressed_tint
			on_pressed.emit()
		else:
			if bg: bg.color = hover_tint 
			on_released.emit()