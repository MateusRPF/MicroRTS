extends PanelContainer
class_name CommandPanel

var panel_entries: Array[CommandPanelEntry]
@export var button_keys:Dictionary[BasicButton,Key]
var command_controller: CommandController

var _current_objects: Array[GridObject]

var _in_submenu


func _ready() -> void:
	GameplayEvents.UI_controller_ready.connect(on_controller_ready)
	GameplayEvents.object_selected.connect(_single_object_view)
	GameplayEvents.multiple_objects_selected.connect(_multiple_object_view)
	GameplayEvents.selection_cleared.connect(_clear_view)
	_clear_view()


func on_controller_ready(newController: PlayerController):
	command_controller = newController.command_controller


func find_button_for_data(data:CommandData)->BasicButton:
# 1. Gather buttons already assigned to an entry in this current view
	var occupied_buttons: Array[BasicButton] = []
	for entry in panel_entries:
		if entry.button:
			occupied_buttons.append(entry.button)

	# 2. Strategy A: Check the Preferred Hotkey
	if data.preferred_hotkey != KEY_NONE:
		for button in button_keys:
			# Check if this button is mapped to the preferred key
			if button_keys[button] == data.preferred_hotkey:
				# If it's not taken, we found our match
				if not button in occupied_buttons:
					return button
	
	# 3. Strategy B: Fallback to the next available button
	for button in button_keys:
		if not button in occupied_buttons:
			return button
			
	# 4. Fail State
	push_error("CommandPanel: No free buttons for command: %s" % data.display_name)
	return null


func _on_hotkey_pressed(key: Key):
	for entry:CommandPanelEntry in panel_entries:
		if entry.data and entry.hotkey == key:
			_on_button_pressed(entry)
			break

func _input(event):
	if event is InputEventKey and event.pressed:
		_on_hotkey_pressed(event.keycode)

func configure_entry(entry: CommandPanelEntry, data:CommandData):
	print("Configuring Entry for " + data.display_name)
	if data:
		panel_entries.append(entry)
		entry.button = find_button_for_data(data)
		entry.hotkey = button_keys[entry.button]


		entry.button.on_pressed.connect(_on_button_pressed.bind(entry))	

		entry.data = data

		if (entry.data is CommandData_BuildStructure):
			var actorData = Database.get_actor_data(entry.data.buildable_id)
			if (actorData):
				entry.data.icon = actorData.sprite	

		if (entry.data is CommandData_IssueWorkOrder):	
			entry.button.tooltip_config = entry.data.order.get_tooltip_config()
			
			var work_order = data.order
			entry.data.display_name = work_order.name
			entry.data.icon = work_order.icon
			entry.data.command_script = Command_IssueWorkOrder

			if (work_order.type == WorkOrderData.WorkOrderType.RECRUIT or work_order.type == WorkOrderData.WorkOrderType.UPGRADE):
				var actorData:ActorData = Database.get_actor_data(work_order.associated_actorID)
				entry.data.icon = actorData.sprite
				entry.data.description = actorData.description
				match work_order.type:
					WorkOrderData.WorkOrderType.RECRUIT:
						entry.button.set_sub_icon(BasicButton.SubIcons.RECRUIT)
					WorkOrderData.WorkOrderType.UPGRADE:
						entry.button.set_sub_icon(BasicButton.SubIcons.UPGRADE)
		else:
			entry.button.tooltip_config = TooltipConfiguration.new()
			entry.button.tooltip_config.title = entry.data.display_name
			entry.button.tooltip_config.description = entry.data.description

		entry.button.icon = entry.data.icon
		entry.button.tooltip_config.hotkey = entry.hotkey
		entry.button.enable_button()	
	else:
		entry.button.icon = null
		entry.button.set_sub_icon(BasicButton.SubIcons.NONE)



func _on_button_pressed(entry: CommandPanelEntry):
	if not entry.data:
		return
	if entry.data.target_mode == CommandData.Targetting.SUBMENU:
		_enter_submenu(entry.data)

	else: 
		if validate_request(entry.data):
			GameplayEvents.UI_command_requested.emit(entry.data)
			reset_view()
			entry.button.do_sucess()
		else:
			entry.button.do_fail()

func validate_request(command_data:CommandData)->bool:
	for object in _current_objects:
		if command_controller.actor_can_issue(object,command_data):
			return true
	return false



func _enter_submenu(_root: CommandData):
	panel_entries.clear()
	_disable_all_buttons()
	_in_submenu = true
	print("Entering sub menu. Panels are clear.")
	if _current_objects.size() == 0:
		return
	var builder: CBuilder = _current_objects[0].get_component(CBuilder)
	var sublist: Array[CommandData]
	if builder:
		sublist = builder.buildable
		print("Its a builder!.")
		_create_entries_for_builds(sublist)
	
	
func _reset_to_root_menu():
	print("Resetting to root")
	_in_submenu = false


func _enable_buttons_for_actor(object: GridObject):
	panel_entries.clear()
	_disable_all_buttons()
	self.visible = true
	if not _in_submenu:
		_create_entries_for_commands(command_controller.get_enabled_commands_for_actor(object))

	var work_issuer:CWorkStation = object.get_component(CWorkStation)
	if (work_issuer):
		var available_work_orders:Array[WorkOrderData] = work_issuer.available_work_orders
		_create_entries_for_work_orders(available_work_orders)


func _create_entries_for_work_orders(orders:Array[WorkOrderData]):
	for work_order in orders:
		var newEntry = CommandPanelEntry.new()	
		var data = CommandData_IssueWorkOrder.new()
		data.preferred_hotkey = Key.KEY_0
		data.order = work_order
		configure_entry(newEntry,data)


func _create_entries_for_commands(commandDatas:Array[CommandData]):
	for data in commandDatas:
		var newEntry = CommandPanelEntry.new()	
		if data.preferred_hotkey != Key.KEY_NONE:
			configure_entry(newEntry,data)

func _create_entries_for_builds(commandDatas:Array[CommandData]):
	for data in commandDatas:
		var newEntry = CommandPanelEntry.new()	
		data.preferred_hotkey = Key.KEY_0
		configure_entry(newEntry,data)


func _clear_view() -> void:
	self.visible = false
	_current_objects.clear()


func _disable_all_buttons():
	for button in button_keys:
		button.disable_button()
		for connection in button.on_pressed.get_connections():
			button.on_pressed.disconnect(connection.callable)

func reset_view():
	if _current_objects.size() == 1:
		_single_object_view(_current_objects[0])
	if _current_objects.size() > 1:
		_multiple_object_view(_current_objects)


func _single_object_view(object: GridObject) -> void:
	print("starting single object view")
	_reset_to_root_menu()
	_current_objects.clear()
	_current_objects.append(object)
	_enable_buttons_for_actor(object)
	visibility_if_enabled()




func _multiple_object_view(objects: Array[GridObject]) -> void:
	_reset_to_root_menu()
	_current_objects.clear()
	_disable_all_buttons()
	self.visible = true
	if objects.is_empty():
		return
	var common_commands = command_controller.get_enabled_commands_for_actor(objects[0])
	for i in range(1, objects.size()):
		var actor_commands = command_controller.get_enabled_commands_for_actor(objects[i])
		common_commands = common_commands.filter(func(cmd): return cmd in actor_commands)
	for cmd in common_commands:
		for entry in panel_entries:
			if entry.data == cmd:
				entry.button.enable_button()
	visibility_if_enabled()

func visibility_if_enabled():
	var should_show = false
	for button:BasicButton in button_keys:
		if button.enabled:
			should_show = true
			break
	self.visible = should_show



func trigger_command_request(command: CommandData):
	GameplayEvents.UI_command_requested.emit(command)


class CommandPanelEntry:
	extends RefCounted
	var button: BasicButton
	var hotkey: Key
	var data: CommandData
