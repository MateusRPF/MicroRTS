extends PanelContainer
class_name MainInspector

@export var widget_registry:Dictionary[Script,Widget_ComponentViewBase]
@export var multiple_selection_view:PackedScene
var _viewing_actor:GridObject
var _viewing_actors:Array[GridObject]

func _ready() -> void:
	GameplayEvents.object_selected.connect(_single_object_view)
	GameplayEvents.multiple_objects_selected.connect(_multiple_object_view)
	GameplayEvents.selection_cleared.connect(_clear_view)
	_clear_view()

func _clear_view():
	print("UI clearing inspector")
	self.visible = false
	_viewing_actor = null
	_viewing_actors = []


func _single_object_view(object: GridObject):
	print("UI Viewing object: %s" % [object.data.actor_name] )
	self.visible = true
	%SingleObject.visible = true
	%MultiObject.visible = false
	_inspect_actor(object)
	_viewing_actors = []

func _multiple_object_view(objects:Array[GridObject]):
	print("UI Viewing %s objects" % [objects.size()] )
	self.visible = true
	%SingleObject.visible = false
	%MultiObject.visible = true
	_viewing_actors = objects
	_viewing_actor = null

	for child in %MultiObject.get_children():
		child.queue_free()

	for object in objects:
		var new_view = multiple_selection_view.instantiate() as Widget_ActorViewRedux
		if object.get_component(CWoundable):
			new_view.initialize(object, object.get_component(CWoundable))
		else:
			new_view.initialize(object, null)
		%MultiObject.add_child(new_view)
		print("Added %s to multi view" % [object.data.actor_name])



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
	if (_viewing_actor):
		self.visible = true
		for script in widget_registry:
			var component = _viewing_actor.get_component(script)
			if component:
				if widget_registry[script].viewing_component != component:
					widget_registry[script].initialize(_viewing_actor, component)
				widget_registry[script].visible = true
				widget_registry[script].update_view()
			else:
				widget_registry[script].visible = false

	elif (_viewing_actors):
		self.visible = true
		for child in %MultiObject.get_children():
			child.update_view()
	else:	
		self.visible = false
