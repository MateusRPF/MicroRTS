extends PanelContainer
class_name CommandPanel

var command_entries: Array[CommandPanelEntry]
@export var button_command_map: Dictionary[BasicButton, CommandData]
var command_controller: CommandController
@export var key_command_map: Dictionary[CommandData, Key]

var _current_objects: Array[GridObject]
var _in_submenu: bool = false


func _ready() -> void:
	GameplayEvents.UI_controller_ready.connect(on_controller_ready)
	GameplayEvents.object_selected.connect(_single_object_view)
	GameplayEvents.multiple_objects_selected.connect(_multiple_object_view)
	GameplayEvents.selection_cleared.connect(_clear_view)
	_clear_view()
	_configure_panels()


func on_controller_ready(newController: PlayerController):
	command_controller = newController.command_controller


func _configure_panels():
	for button in button_command_map:
		var newEntry = CommandPanelEntry.new()
		newEntry.button = button
		newEntry.data = button_command_map[button]
		command_entries.append(newEntry)

	for command_entry in command_entries:
		command_entry.button.on_pressed.connect(_on_button_pressed.bind(command_entry))
		_refresh_button_chrome(command_entry)

func _on_hotkey_pressed(key: Key):
	for commandEntry:CommandPanelEntry in command_entries:
		if commandEntry.data and key_command_map.get(commandEntry.data, null) == key:
			_on_button_pressed(commandEntry)
			break


func _input(event):
	if event is InputEventKey and event.pressed:
		_on_hotkey_pressed(event.keycode)

func _refresh_button_chrome(entry: CommandPanelEntry):
	if entry.data:
		entry.button.icon = entry.data.icon
		
		if (entry.data is CommandData_IssueWorkOrder):	
			entry.button.tooltip_config = entry.data.order.get_tooltip_config()
			return
		entry.button.tooltip_config = TooltipConfiguration.new()
		entry.button.tooltip_config.title = entry.data.display_name
		entry.button.tooltip_config.description = entry.data.description

	else:
		entry.button.icon = null
		entry.button.tooltip_config = null


func _on_button_pressed(entry: CommandPanelEntry):
	if not entry.data:
		return
	if entry.data.target_mode == CommandData.Targetting.SUBMENU:
		_enter_submenu(entry.data)
		return
	var was_submenu := _in_submenu

	if validate_request(entry.data):
		GameplayEvents.UI_command_requested.emit(entry.data)
		if was_submenu:
			_reset_to_root_menu()
	else:
		do_fail(entry)
	



func validate_request(command_data:CommandData)->bool:
	for object in _current_objects:
		if command_controller.actor_can_issue(object,command_data):
			return true
	return false




func do_fail(entry: CommandPanelEntry):

	entry.button.self_modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	entry.button.self_modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	entry.button.self_modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	entry.button.self_modulate = Color.WHITE
	pass


func _enter_submenu(root: CommandData):
	if _current_objects.size() == 0:
		return
	var builder: CBuilder = _current_objects[0].get_component(CBuilder)
	var sublist: Array[CommandData]
	if builder:
		sublist = builder.buildable
	else:
		sublist = root.sub_commands
	_in_submenu = true
	for entry in command_entries:
		entry.data = null
	for i in range(min(sublist.size(), command_entries.size())):
		command_entries[i].data = sublist[i]
	for entry in command_entries:
		_refresh_button_chrome(entry)
		if entry.data:
			entry.button.enable_button()
		else:
			entry.button.disable_button()


func _reset_to_root_menu():
	_in_submenu = false
	reset_view()


func _enable_buttons_for_actor(object: GridObject):
	_disable_all_buttons()
	self.visible = true
	for available_command in command_controller.get_enabled_commands_for_actor(object):
		for entry in command_entries:
			if entry.data == available_command:
				entry.button.enable_button()

	var work_issuer:CWorkOrderIssuer = object.get_component(CWorkOrderIssuer)
	if (work_issuer):
		print("Enabling commands for an issuer.")
		var available_work_orders:Array[WorkOrderData] = work_issuer.available_work_orders

		for i in range(min(command_entries.size(), available_work_orders.size())):
			var entry =  command_entries[i]
			if entry.button.enabled == false:
				var work_order = available_work_orders[i]
				entry.data = CommandData_IssueWorkOrder.new()
				entry.data.display_name = work_order.name
				entry.data.icon = work_order.icon
				entry.data.command_script = Command_IssueWorkOrder
				entry.data.order = work_order
				if (work_order.type == WorkOrderData.WorkOrderType.RECRUIT or work_order.type == WorkOrderData.WorkOrderType.UPGRADE):
					entry.data.icon = work_order.associated_actorData.sprite
					entry.data.description = work_order.associated_actorData.description
				
				entry.button.enable_button()
				_refresh_button_chrome(entry)

func _clear_view() -> void:
	self.visible = false
	_current_objects.clear()
	_in_submenu = false


func _disable_all_buttons():
	for button in button_command_map:
		button.disable_button()

func reset_view():
	if _current_objects.size() == 1:
		_single_object_view(_current_objects[0])
	if _current_objects.size() > 1:
		_multiple_object_view(_current_objects)


func _single_object_view(object: GridObject) -> void:
	_current_objects.clear()
	_current_objects.append(object)
	_in_submenu = false
	_enable_buttons_for_actor(object)


func _multiple_object_view(objects: Array[GridObject]) -> void:
	_current_objects.clear()
	_reset_to_root_menu()
	_disable_all_buttons()
	self.visible = true
	if objects.is_empty():
		return
	var common_commands = command_controller.get_enabled_commands_for_actor(objects[0])
	for i in range(1, objects.size()):
		var actor_commands = command_controller.get_enabled_commands_for_actor(objects[i])
		common_commands = common_commands.filter(func(cmd): return cmd in actor_commands)
	for cmd in common_commands:
		for entry in command_entries:
			if entry.data == cmd:
				entry.button.enable_button()


func trigger_command_request(command: CommandData):
	GameplayEvents.UI_command_requested.emit(command)


class CommandPanelEntry:
	extends RefCounted
	var button: BasicButton
	var hotkey: Key
	var data: CommandData
