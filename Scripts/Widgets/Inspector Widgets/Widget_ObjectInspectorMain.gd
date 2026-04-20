extends PanelContainer
class_name MainInspector

@export var widget_registry:Dictionary[Script,Widget_ComponentViewBase]
var _viewing_actor:GridObject

func _ready() -> void:
	GameplayEvents.object_selected.connect(_single_object_view)
	GameplayEvents.multiple_objects_selected.connect(_multiple_object_view)
	GameplayEvents.selection_cleared.connect(_clear_view)
	_clear_view()

func _clear_view():
	print("UI clearing inspector")
	self.visible = false


func _single_object_view(object: GridObject):
	print("UI Viewing object: %s" % [object.data.actor_name] )
	self.visible = true
	_inspect_actor(object)

func _multiple_object_view(objects:Array[GridObject]):
	print("UI Viewing %s objects" % [objects.size()] )
	self.visible = true
	pass

func _inspect_actor(object:GridObject):
	_viewing_actor = object
	if not _viewing_actor:
		return
	%Widget_ActorView.configure(object.data)
	for script in widget_registry:
		var possible_component = object.get_component(script)
		if possible_component:
			widget_registry[script].initialize(object,possible_component)
			widget_registry[script].visible = true
		else:
			widget_registry[script].visible = false


func _process(_delta: float) -> void:
	if (self.visible && _viewing_actor):
		for script in widget_registry:
			if _viewing_actor.get_component(script):
				widget_registry[script].update_view()
	else:
		self.visible = false
