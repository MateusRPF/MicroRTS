extends Node
class_name GridObjectComponent


var owner_object: GridObject = null 



func initialize_component(actor: GridObject) -> void:
	if not (actor is GridObject):
		push_error("GridObjectComponent: owner is not a GridObject")
		return
	owner_object = actor
	actor.OnTickReceived.connect(_on_tick_received)
	

func _on_tick_received() -> void:
	# Override in subclasses that care about tick updates.
	pass

## Debug only

var _debug_proxy: Node2D = null



func _ready() -> void:
	# DebugSettings.debug_toggled.connect(_on_debug_toggled)
	# # Check initial state
	# if DebugSettings.debug_enabled:
	# _create_debug_proxy()
	pass

func _get_debug_color() -> Color:
	return Color.RED

func _on_debug_toggled(enabled: bool) -> void:
	if enabled:
		_create_debug_proxy()
	else:
		_remove_debug_proxy()

func _create_debug_proxy() -> void:
	if _debug_proxy: return
	
	_debug_proxy = Node2D.new()
	_debug_proxy.name = "DebugProxy_" + name
	
	# Connect the proxy's draw call back to this component
	_debug_proxy.draw.connect(_draw_debug)
	
	# Add it to the GridObject (the parent) so it moves with the unit
	get_parent().add_child(_debug_proxy)

func _remove_debug_proxy() -> void:
	if _debug_proxy:
		_debug_proxy.queue_free()
		_debug_proxy = null

# Virtual function to be overridden by CMover, CHarvester, etc.
func _draw_debug() -> void:
	pass

func _process(_delta: float) -> void:
	if _debug_proxy:
		_debug_proxy.queue_redraw()

func on_damaged(_opponent:GridObject) -> void:
	# For components that want to react to the owner being damaged.
	pass