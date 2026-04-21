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

const HOP_HEIGHT: float = 10.0
const HOP_LEAN: float = 0.22

var _pos_tween: Tween = null
var _rot_tween: Tween = null


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

func start_move_with_path(path: Array[Vector2i], target_coord: Vector2i) -> bool:
	if path.is_empty():
		return false
	current_goal = target_coord
	current_path = path
	current_step = 0
	tick_counter = 99
	return true

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
	blocker_object = null
	if not is_moving():
		return false

	var next_coord: Vector2i = current_path[current_step]
	if not perform_move(owner_object.current_coord, next_coord):
		if blocker_object == null:
			tick_counter = ticks_per_step - 1
			return false

		var blocker_mover: CMover = blocker_object.get_component(CMover)
		if blocker_mover == null or not blocker_mover.is_moving():
			start_move(current_goal)
			return false

		blocked_repath_counter += 1
		if blocked_repath_counter >= blocked_repath_delay:
			blocked_repath_counter = 0
			start_move(current_goal)
		return false

	blocked_repath_counter = 0
	current_step += 1
	if current_step >= current_path.size():
		current_path = []
		return false
	return true

func perform_move(from_coord: Vector2i, to_coord: Vector2i) -> bool:
	if not owner_object or not owner_object.grid_manager:
		push_error("CMover: Cannot perform move without grid_manager")
		return false
	if not owner_object.grid_manager.map_tiles.has(to_coord):
		DebugSettings.debug_print("Mover", "Target tile %s is invalid" % to_coord)
		return false

	if not can_move_to(to_coord):
		return false

	var grid = owner_object.grid_manager
	grid.UpdatePosition(owner_object, to_coord)
	owner_object.settle_position()
	_play_hop(to_coord - from_coord)
	return true


func _play_hop(direction: Vector2i) -> void:
	var sprite: Node2D = owner_object.get_node_or_null("%Sprite")
	if not sprite:
		return
	if _pos_tween and _pos_tween.is_running():
		_pos_tween.kill()
	if _rot_tween and _rot_tween.is_running():
		_rot_tween.kill()

	var duration: float = GlobalTicker.tick_rate * ticks_per_step
	var half: float = duration * 0.5
	var start_local: Vector2 = -Vector2(direction) * GridManager.TILE_SIZE
	var start_y: float = start_local.y

	sprite.position = start_local

	_pos_tween = sprite.create_tween().set_parallel(true)
	_pos_tween.tween_property(sprite, "position:x", 0.0, duration).set_trans(Tween.TRANS_LINEAR)
	_pos_tween.tween_method(
		func(t: float) -> void:
			sprite.position.y = lerp(start_y, 0.0, t) - HOP_HEIGHT * sin(t * PI),
		0.0, 1.0, duration
	)

	if direction.x != 0:
		var lean: float = -sign(direction.x) * HOP_LEAN
		_rot_tween = sprite.create_tween()
		_rot_tween.tween_property(sprite, "rotation", lean, half).set_trans(Tween.TRANS_SINE)
		_rot_tween.tween_property(sprite, "rotation", 0.0, half).set_trans(Tween.TRANS_SINE)
	else:
		sprite.rotation = 0.0

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
	
