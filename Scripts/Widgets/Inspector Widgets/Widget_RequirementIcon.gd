extends HBoxContainer
class_name Widget_RequirementIcon

var resource: GameResource = null


func set_resource(res: GameResource, amount: int) -> void:
	resource = res
	%Image_ResourceSprite.texture = res.icon
	set_amount(amount)


func set_amount(amount: int) -> void:
	%Label_Amount.text = "x%d" % amount
	visible = amount > 0
