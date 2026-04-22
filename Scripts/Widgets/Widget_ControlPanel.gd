extends PanelContainer
class_name CommandPanel

var command_entries:Array[CommandPanelEntry]
@export var button_command_map:Dictionary[BasicButton,CommandData]
var command_controller:CommandController
@export var key_command_map:Dictionary[CommandData,Key]

func _ready() -> void:
	GameplayEvents.UI_controller_ready.connect(on_controller_ready)
	GameplayEvents.object_selected.connect(_single_object_view)
	GameplayEvents.multiple_objects_selected.connect(_multiple_object_view)
	GameplayEvents.selection_cleared.connect(_clear_view)
	_clear_view()
	_configure_panels()

func on_controller_ready(newController:PlayerController):
	command_controller = newController.command_controller


func _configure_panels():

	for button in button_command_map:
		var newEntry = CommandPanelEntry.new()
		newEntry.button = button
		#newEntry.hotkey = key_command_map[button_command_map[button]]
		newEntry.data = button_command_map[button]
		command_entries.append(newEntry)

	for command_entry in command_entries:
		command_entry.button.on_pressed.connect(trigger_command_request.bind(command_entry.data))
		if (command_entry.data):
			command_entry.button.tooltip_config = TooltipConfiguration.new()
			command_entry.button.tooltip_config.title = command_entry.data.display_name
			command_entry.button.tooltip_config.description = command_entry.data.description


func _clear_view() -> void:
	self.visible = false

func _disable_all_buttons():
	for button in button_command_map:
		button.disable_button()
	print("Disabling all buttons")


func _single_object_view(object: GridObject) -> void:
	_disable_all_buttons()
	self.visible = true
	for available_command in command_controller.get_enabled_commands_for_actor(object):
		for button in button_command_map:
			if button_command_map[button] == available_command:
				button.enable_button()
				continue




func _multiple_object_view(objects:Array[GridObject]) -> void:
	_disable_all_buttons()
	self.visible = true
	if objects.is_empty():
		return
	var common_commands = command_controller.get_enabled_commands_for_actor(objects[0])
	for i in range(1, objects.size()):
		var actor_commands = command_controller.get_enabled_commands_for_actor(objects[i])
		common_commands = common_commands.filter(func(cmd): return cmd in actor_commands)
	for cmd in common_commands:
		for button in button_command_map:
			if button_command_map[button] == cmd:
				button.enable_button()



func trigger_command_request(command:CommandData):

	GameplayEvents.UI_command_requested.emit(command)



class CommandPanelEntry:
	extends RefCounted
	var button:BasicButton
	var hotkey:Key
	var data:CommandData
