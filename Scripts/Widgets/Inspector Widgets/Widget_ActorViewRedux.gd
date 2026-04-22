extends Widget_ComponentViewBase
class_name Widget_ActorViewRedux

var woundable:CWoundable

func initialize(object:GridObject, component:GridObjectComponent):
	viewing_object = object
	if (component is CWoundable):
		%Widget_WoundView.initialize(object, component)
		%Widget_WoundView.visible = true
	else:		%Widget_WoundView.visible = false
	_load_view()

func _load_view():
	%Image_ActorSprite.texture = viewing_object.data.sprite


func update_view():
	%Widget_WoundView.update_view()