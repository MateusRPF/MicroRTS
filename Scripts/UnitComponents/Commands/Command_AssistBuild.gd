extends Command_BuildBase
class_name Command_AssistBuild


func finish_cache() -> void:
	super.finish_cache()
	if is_instance_valid(target_actor):
		_bind_to_site(target_actor)


func start_command() -> bool:
	emit_signal("command_started", self)
	return true


func get_descriptor() -> String:
	if target_actor and target_actor.data:
		return "Build %s" % [target_actor.data.actor_name]
	return "Build"
