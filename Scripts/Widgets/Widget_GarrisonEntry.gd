extends PanelContainer
class_name Widget_GarrisonEntry


var component_garrison:CGarrison
var associated_slot:GarrisonSlot
var button:BasicButton

signal button_clicked(entry:Widget_GarrisonEntry)

func _ready():
	button = %Button_Worker as BasicButton
	button.on_pressed.connect(on_button_clicked)


func load_slot_config(slot:GarrisonSlot, garrison:CGarrison):
	associated_slot = slot
	component_garrison = garrison

	self.self_modulate = Color.YELLOW if associated_slot.is_required else Color.WHITE

	if (button):
		if (slot.accepts_any):
			%Label_SlotName.text = "Any"
			button.icon = null
		else:
			%Label_SlotName.text = slot.accepted_tag.tag_name
			if button:
				button.icon = slot.accepted_tag.icon


func update_view():
	print("Update view")
	if (component_garrison and associated_slot):
		if component_garrison.garrison_slots[associated_slot] != null:
			button.icon = component_garrison.garrison_slots[associated_slot].data.sprite
			%Label_Required.visible = false
			%Label_SlotName.visible = false
		else:
			%Label_Required.visible = associated_slot.is_required
			%Label_SlotName.visible = true

			if button:
				if (associated_slot.accepts_any):
					button.icon = null
				else:
					button.icon = associated_slot.accepted_tag.icon
	

func on_button_clicked():
	button_clicked.emit(self)
