extends GridObjectComponent
class_name CMover


var current_goal: Vector2i = Vector2i.ZERO
var current_path: Array[Vector2i] = []

var current_step: int = 0
var tick_counter: int = 0
var ticks_per_step: int = 1
var blocked_repath_delay: int = 2
var blocked_repath_counter: int = 0
var blocker_object:GridObject = null

var default_speed: int = 1


func is_moving() -> bool:
	return current_path.size() > 0 and current_step < current_path.size()


func find_path_to(target_coord: Vector2i) -> Array[Vector2i]:
	if not owner_object or not owner_object.grid_manager:
		push_error("CMover: Cannot find path without grid_manager")
		return []
	var path:Array[Vector2i] = owner_object.grid_manager.find_path(owner_object.current_coord, target_coord, owner_object)
	return path

func stop_move() -> void:
	current_path = []
	current_step = 0
	tick_counter = 0
	

func start_move(target_coord: Vector2i) -> bool:
	current_goal = target_coord
	current_path = find_path_to(target_coord)
	if current_path.is_empty():

		return false
	current_step = 0
	tick_counter = 99  # Force immediate first step on next tick


	return true

func can_path_to(target_coord:Vector2i)->bool:
	if not (target_coord):
		return false
	var testPath = owner_object.grid_manager.find_path(owner_object.current_coord,target_coord,owner_object).size() >0
	return testPath

func _on_tick_received() -> void:
	if not is_moving():
		return
	
	var attribute_set:CAttributeSet = owner_object.get_component(CAttributeSet)
	if (attribute_set):
		var speed_attr = attribute_set.get_attr(CAttributeSet.ATTR_ID.ATTR_MOVE_SPEED)
		if (speed_attr > 0):
			ticks_per_step = ceili(60 / speed_attr)
		else:
			stop_move()
			return
	else:
		ticks_per_step = ceil(TickManager.DEFAULT_TICK_RATE / default_speed as float)
	tick_counter += 1
	
	if tick_counter < ticks_per_step:
		return
	tick_counter = 0

	_advance_move_step()
		


func _advance_move_step() -> bool:
	#DebugSettings.debug_print("Mover", "Advancing Move")
	blocker_object = null
	if not is_moving():
		return false

	var next_coord: Vector2i = current_path[current_step]
	if not perform_move(owner_object.current_coord, next_coord):
		if (blocker_object):
			if (blocker_object.randomizedPriority > owner_object.randomizedPriority or blocker_object.get_component(CMover).is_moving()):
				blocked_repath_counter += 1 
			if blocked_repath_counter >= blocked_repath_delay:
				blocked_repath_counter = 0
			else:
				start_move(current_goal)  # Recalculate path after waiting a tick
		else:
			tick_counter = ticks_per_step - 1  # retry on next tick
		return false

	blocked_repath_counter = 0
	current_step += 1
	if current_step >= current_path.size():
		current_path = []
		return false
	return true

# var _move_tween: Tween
func perform_move(_from_coord: Vector2i, to_coord: Vector2i) -> bool:
	if not owner_object or not owner_object.grid_manager:
		push_error("CMover: Cannot perform move without grid_manager")
		return false
	if not owner_object.grid_manager.map_tiles.has(to_coord):
		DebugSettings.debug_print("Mover", "Target tile %s is invalid" % to_coord)
		return false
	
	if not can_move_to(to_coord):
		return false

	# # 1. Kill any ongoing movement to prevent "fighting" tweens
	# if _move_tween and _move_tween.is_running():
	# 	_move_tween.kill()

	var grid = owner_object.grid_manager



	# 2. Update Logic: Move the parent immediately


	# var view_child = owner_object.get_child(0)
	# var old_visual_pos: Vector2
	
	# if view_child:
	# 	old_visual_pos = view_child.global_position
	# 	if _move_tween: _move_tween.kill()

	grid.UpdatePosition(owner_object, to_coord)
	owner_object.settle_position() # This snaps the parent to to_world_pos

	
	# if view_child:
	# 	# Instantly teleport the child BACK to where it was globally.
	# 	# This negates the parent's snap, so the player sees no change yet.
	# 	view_child.global_position = old_visual_pos

	# 	# 4. Animate local position back to (0,0) 
	# 	# (Zero is now the new parent position)
	# 	var duration = GlobalTicker.tick_rate * ticks_per_step

	# 	_move_tween = owner_object.create_tween()
	# 	_move_tween.set_trans(Tween.TRANS_LINEAR) 
	# 	_move_tween.tween_property(view_child, "position", Vector2.ZERO, duration)
	return true

func _on_move_tween_completed() -> void:
	owner_object.get_child(0).position = Vector2.ZERO

# func find_valid_interaction_tile(target_obj: GridObject) -> Vector2i:
# 	# TODO: Find an adjacent tile to interact with the target object
# 	# Returns a coordinate adjacent to the target that the owner_object can stand on
# 	if not owner_object or not target_obj:
# 		push_error("CMover: Invalid parameters for find_valid_interaction_tile")
# 		return Vector2i.ZERO
	
# 	DebugSettings.debug_print("Mover", "Finding interaction tile for target at %s" % target_obj.currentCoord)
# 	return Vector2i.ZERO

func can_move_to(target_coord: Vector2i) -> bool:
	if not owner_object or not owner_object.grid_manager:
		return false
	if not owner_object.grid_manager.map_tiles.has(target_coord):
		return false

	if owner_object.grid_manager.map_tiles[target_coord].is_occupied:
		var occupant = owner_object.grid_manager.map_tiles[target_coord].occupant
		if occupant != null and occupant != owner_object:
			if (occupant):
				blocker_object = occupant
			return false  # Tile is occupied by another object
	return true

func _draw_debug() -> void:
	if current_path.is_empty():
		return

	var path_color = Color.CYAN
	var goal_color = Color.GOLD
	
	# 1. Draw the path segments
	for i in range(current_path.size() - 1):
		var start_pos = owner_object.grid_manager.tile_to_world((current_path[i])) - owner_object.global_position
		var end_pos = owner_object.grid_manager.tile_to_world((current_path[i+1]))  - owner_object.global_position

		_debug_proxy.draw_line(start_pos,end_pos,path_color,1)

	# 2. Highlight the final goal
	var final_pos =  owner_object.grid_manager.tile_to_world(current_path[-1])- owner_object.global_position
	
	# draw_arc is the best way to do a "hollow" circle
	_debug_proxy.draw_arc(
		final_pos, 
		3.0,           # Radius (adjust for your sprite size)
		0, 
		TAU,            # Full circle
		16,             # Points for smoothness
		goal_color, 
		2.0,            # Line width
		true            # Antialiasing
	)
	
