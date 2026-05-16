@tool
extends PanelContainer
class_name BasicButton

signal on_pressed()
signal on_hovered()
signal on_released()
var tooltip_config:TooltipConfiguration
var enabled:bool = false

@export var sub_icon_map:Dictionary[SubIcons,Texture2D]

enum SubIcons {RECRUIT, BUILD, RESEARCH, EJECT, UPGRADE,NONE}

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

func set_sub_icon(key:SubIcons):
	if (key == SubIcons.NONE):
		%Container_SubIcon.visible = false
	
	%Container_SubIcon.visible = true
	%SubIcon.texture = sub_icon_map[key]


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
	enabled = false
	var bg = get_node_or_null("%ColorRect")
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bg: bg.color = disabled_tint

func enable_button():
	enabled = true
	var bg = get_node_or_null("%ColorRect")
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	if bg: bg.color = normal_tint

# -- Mouse Interaction Logic --

func _on_mouse_entered() -> void:
	var bg = get_node_or_null("%ColorRect")
	bg.color = hover_tint
	if (tooltip_config):
		GameplayEvents.UI_tooltip_requested.emit(tooltip_config)
	on_hovered.emit()

func _on_mouse_exited() -> void:
	var bg = get_node_or_null("%ColorRect")
	if (tooltip_config):
		GameplayEvents.UI_tooltip_closed.emit()
	if bg: bg.color = normal_tint

func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var bg = get_node_or_null("%ColorRect")
		if event.pressed:
			do_sucess()
			on_pressed.emit()
		else:
			if bg: bg.color = hover_tint 
			on_released.emit()


func do_fail():
	shake_button()
	self_modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	self_modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	self_modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	self_modulate = Color.WHITE
	pass

func do_sucess():
	# shake_button()
	modulate = Color.GRAY
	await get_tree().create_timer(0.2).timeout
	self.scale = Vector2.ONE
	modulate = Color.WHITE
	pass

func shake_button(duration:float = 0.2, intensity: float = 5.0):
	var tween = create_tween()
	var original_pos = position
	
	# We chain a series of quick offsets
	# Fast duration (0.04s) makes it feel "vibrational" rather than "sliding"
	tween.tween_property(self, "position", original_pos + Vector2(-intensity, 0), duration/5)
	tween.tween_property(self, "position", original_pos + Vector2(intensity, 0), duration/5)
	tween.tween_property(self, "position", original_pos + Vector2(-intensity * 0.5, 0), duration/5)
	tween.tween_property(self, "position", original_pos + Vector2(intensity * 0.5, 0), duration/5)
	
	# Always end by snapping back to the exact original position
	tween.tween_property(self, "position", original_pos, duration/5)