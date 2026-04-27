extends GridObjectComponent
class_name CWoundable

var damage_taken:int = 0


func get_max_wounds()-> int:
	var attrSet:CAttributeSet = owner_object.get_component(CAttributeSet)
	if (attrSet):
		return attrSet.get_attr(CAttributeSet.ATTR_ID.ATTR_MAX_WOUNDS)
	return 1

func get_current_health()->int:
	return max(get_max_wounds()- damage_taken,0)

func receive_wound(damage:int):
	damage_taken += damage
	if damage_taken >= get_max_wounds():
		owner_object.destroy_object()
