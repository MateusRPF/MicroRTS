extends Widget_ComponentViewBase
class_name ExecutorView


var executor:CCommandExecutor

func _load_view():

	executor = viewing_component as CCommandExecutor
	update_view()

func update_view():
	var currentCommand:Command = executor.current_command

	if (currentCommand):
		%Label_Command.text = currentCommand.get_descriptor()
	else:
		%Label_Command.text = "Idle"
