extends Command_BuildBase
class_name Command_BuildStructure

var build_data: CommandData_BuildStructure = null


func finish_cache() -> void:
	super.finish_cache()
	build_data = data as CommandData_BuildStructure



func start_command() -> bool:
	emit_signal("command_started", self)
	_spawn_structure()
	if not is_instance_valid(site):
		current_step = BuildSteps.COMPLETED
		finish_command()
		return false
	current_step = BuildSteps.FETCHING
	return true


func _spawn_structure() -> void:
	if not build_data or not build_data.buildable_id:
		return
	var grid: GridManager = owner_executor.owner_object.grid_manager
	if not grid.can_place_with_clearance(target_coord, build_data.get_footprint_size(), build_data.get_clearance()):
		return
	var new_structure: GridObject = grid.grid_object_scene.instantiate() as GridObject
	grid.add_child(new_structure)
	new_structure.initialize_as_construction_site(grid, target_coord, ActorData.Sides.PLAYER, build_data.buildable_id, owner_executor.owner_object.player_state)
	target_actor = new_structure
	footprint_coords = grid.get_footprint_coords(target_coord, build_data.get_footprint_size())
	perimeter_coords = target_actor.get_perimeter()
	_bind_to_site(new_structure)


func get_descriptor() -> String:
	if build_data:
		return "Build %s at %s" % [build_data.display_name, target_coord]
	return "Build at %s" % [target_coord]
