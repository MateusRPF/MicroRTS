extends Widget_ComponentViewBase
class_name ExecutorView


var executor:CCommandExecutor

func _load_view():

	executor = viewing_component as CCommandExecutor
	update_view()

func update_view():

	match executor.owner_object.side:
		ActorData.Sides.PLAYER:
			var currentCommand:Command = executor.current_command
			modulate = Color.WHITE # Light red tint for enemies
			if (currentCommand):
				%Label_Command.text = currentCommand.get_descriptor()
			else:
				%Label_Command.text = "Idle"
		ActorData.Sides.ENEMY:
			%Label_Command.text = "Enemy"
			modulate = Color.RED # Light red tint for enemies
		_:
			%Label_Command.text = "Neutral"
			modulate = Color.YELLOW
