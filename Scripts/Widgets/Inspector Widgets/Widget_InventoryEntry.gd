extends PanelContainer
class_name InventoryEntry



func view_entry(resource:GameResource, value:int, availability = true):
	%Image_ResourceSprite.texture = resource.icon
	%Label_Value.text = str(value)
	if not availability:
		%Label_Value.modulate = Color.RED
	else:
		%Label_Value.modulate = Color.WHITE
