extends GridObjectComponent
class_name CCommandExecutor

signal became_idle(executor: CCommandExecutor)

var command_queue: Array = []
var current_command = null
var _was_idle: bool = true

@onready var behavioral_frequency:int = randi_range(3,5)
var tick_count:int = 0


func queue_command(newCommand: Command, force:bool = true) -> void:
	newCommand.owner_executor = self
	if force:
		command_queue.clear()
		current_command = null
	command_queue.append(newCommand)
	_was_idle = false

	if (current_command == null):
		_trigger_next_command()

func _on_tick_received() -> void:
	tick_count +=1
	if (tick_count >= behavioral_frequency):
		tick_count = 0
		if current_command == null and command_queue.size() > 0:
			_trigger_next_command()

		if current_command != null:
			if current_command.get_status() == Command.command_states.COMPLETED:
				current_command = null
			else:
				current_command.tick()

		var idle_now: bool = current_command == null and command_queue.is_empty()
		if idle_now and not _was_idle:
			became_idle.emit(self)
		_was_idle = idle_now

func _trigger_next_command() -> void:
	current_command = command_queue.pop_front()
	current_command.start_command()