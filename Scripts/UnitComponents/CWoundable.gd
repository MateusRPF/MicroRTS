extends GridObjectComponent
class_name CWoundable

var damage_taken:int = 0
var indicator:ProgressBar = null

func initialize_component(actor: GridObject) -> void:
	super.initialize_component(actor)
	indicator = owner_object.get_node("%ProgressBar1") as ProgressBar
	refresh_indicator()
	


func get_max_wounds()-> int:
	var attrSet:CAttributeSet = owner_object.get_component(CAttributeSet)
	if (attrSet):
		return attrSet.get_attr(CAttributeSet.ATTR_ID.ATTR_MAX_WOUNDS)
	return 1

func get_current_health()->int:
	return max(get_max_wounds()- damage_taken,0)

func receive_wound(damage:int,opponent:GridObject) -> void:
	owner_object.OnDamageReceived.emit(owner_object)
	damage_taken += damage
	if damage_taken >= get_max_wounds():
		owner_object.destroy_object()
	refresh_indicator()

func refresh_indicator():
	if indicator:
		indicator.value = get_current_health()
		indicator.max_value = get_max_wounds()
		indicator.visible = damage_taken > 0