extends Widget_ComponentViewBase
class_name Widget_WorkOrdersView

var entry_prefab = preload("res://Prefabs/Widgets/Widget_InventoryEntry.tscn")
@onready var container_requirements = %Requirement_Container 

var issuer:CWorkOrderIssuer
var buttons:Array[BasicButton]

func _ready() -> void:
	buttons.append(%Button_ActiveOrder)
	buttons.append(%Button_Order1)
	buttons.append(%Button_Order2)
	buttons.append(%Button_Order3)
	buttons.append(%Button_Order4)

	for button in buttons:
		button.on_pressed.connect(on_button_pressed.bind(buttons.find(button)))

	
func on_button_pressed(index:int):
	issuer.cancel_work_order_at_index(index)
	update_view()



func _load_view():
	issuer = viewing_component as CWorkOrderIssuer
	clean_buttons()

func update_view():
	clean_buttons()
	
	if issuer.current_work_order:
		self.visible = true
		view_order(buttons[0], issuer.current_work_order)
		for i:int in range(0,issuer.queued_work_orders.size()):
			view_order(buttons[i+1], issuer.queued_work_orders[i])
		
		%Label_CurrentWork.text = issuer.current_work_order.name
		%ProgressBar1.max_value = issuer.current_work_order.work_required
		%ProgressBar1.value = issuer.current_work_received
		_display_requirements()
	else:
		self.visible = false
	pass


func _display_requirements():
	if not container_requirements:
		container_requirements = %Requirement_Container
	for child in container_requirements.get_children():
		child.queue_free()
	if not issuer:
		return
	for res in issuer.current_work_order.get_resource_costs():
		var entry: InventoryEntry = entry_prefab.instantiate() as InventoryEntry
		container_requirements.add_child(entry)
		_update_entry(entry, res)


func _update_entry(entry: InventoryEntry, res: GameResource) -> void:
	var delivered: int = issuer.delivered_resources.get(res, 0)
	var required: int = issuer.current_work_order.get_resource_costs()[res]
	entry.get_node("%Image_ResourceSprite").texture = res.icon
	entry.get_node("%Label_Value").text = "%d/%d" % [delivered, required]


func clean_buttons():
	for button in buttons:
		button.disable_button()
		button.icon = null

	
func view_order(button:BasicButton,order:WorkOrderData):
	button.icon = order.get_icon()
	button.enable_button()
