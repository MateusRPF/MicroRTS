extends HBoxContainer
class_name  AttributeViewEntry



func show_attribute(instance:CAttributeSet.AttributeInstance):
	%Label_AttrName.text = CAttributeSet.ATTR_NAMES[instance.attr_ID]
	%Label_AttrValue.text = str(instance.get_final_value())
