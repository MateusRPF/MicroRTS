extends  PanelContainer
class_name Widget_ComponentViewBase

var viewing_object:GridObject
var viewing_component: GridObjectComponent


func initialize(object:GridObject, component:GridObjectComponent):
	viewing_object = object
	viewing_component = component
	_load_view()

func _load_view():
	pass

func update_view():
	pass