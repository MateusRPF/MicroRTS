extends PanelContainer
class_name  InventoryEntry



func view_entry(resource:GameResource, value:int):
	%Image_ResourceSprite.texture = resource.icon
	%Label_Value.text = str(value)
