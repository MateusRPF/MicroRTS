extends Camera2D
class_name CameraController

@export var edge_pan_margin: int = 6
@export var edge_pan_speed: float = 900.0
@export var zoom_step_multiplier: float = 1.1
@export var zoom_smoothing: float = 15.0
@export var min_zoom_factor: float = 0.25
@export var max_zoom_factor: float = 4.0

var player_controller: PlayerController = null
var target_zoom: float = 1.0
var is_middle_dragging: bool = false

func _ready() -> void:
	player_controller = get_parent() as PlayerController
	var viewport := get_viewport()
	if viewport:
		viewport.size_changed.connect(_on_viewport_resized)
	target_zoom = zoom.x
	_enforce_zoom_floor()
	_clamp_camera()
	_confine_mouse()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_confine_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					_zoom_by_scroll(1)
				MOUSE_BUTTON_WHEEL_DOWN:
					_zoom_by_scroll(-1)
				MOUSE_BUTTON_MIDDLE:
					is_middle_dragging = true
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			is_middle_dragging = false
	elif event is InputEventMouseMotion and is_middle_dragging:
		global_position -= event.relative / zoom.x
		_clamp_camera()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CONFINED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	_update_zoom(delta)
	_update_edge_pan(delta)

func _update_edge_pan(delta: float) -> void:
	if is_middle_dragging or not player_controller or not get_viewport():
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO or edge_pan_margin <= 0:
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var speed_factor: Vector2 = Vector2.ZERO

	if mouse_pos.x < edge_pan_margin:
		speed_factor.x = -clamp(1.0 - mouse_pos.x / edge_pan_margin, 0.0, 1.0)
	elif mouse_pos.x > viewport_size.x - edge_pan_margin:
		speed_factor.x = clamp(1.0 - (viewport_size.x - mouse_pos.x) / edge_pan_margin, 0.0, 1.0)

	if mouse_pos.y < edge_pan_margin:
		speed_factor.y = -clamp(1.0 - mouse_pos.y / edge_pan_margin, 0.0, 1.0)
	elif mouse_pos.y > viewport_size.y - edge_pan_margin:
		speed_factor.y = clamp(1.0 - (viewport_size.y - mouse_pos.y) / edge_pan_margin, 0.0, 1.0)

	if speed_factor == Vector2.ZERO:
		return

	if speed_factor.length() > 1.0:
		speed_factor = speed_factor.normalized()

	global_position += speed_factor * edge_pan_speed * delta / zoom.x
	_clamp_camera()

func _update_zoom(delta: float) -> void:
	var current_zoom: float = zoom.x
	if is_equal_approx(current_zoom, target_zoom):
		return

	var t: float = 1.0 - exp(-zoom_smoothing * delta)
	var next_zoom: float = lerp(current_zoom, target_zoom, t)
	if abs(next_zoom - target_zoom) < 0.0005:
		next_zoom = target_zoom

	var pivot_world: Vector2 = _get_zoom_pivot_world()
	var pivot_offset: Vector2 = pivot_world - global_position
	zoom = Vector2(next_zoom, next_zoom)
	global_position = pivot_world - pivot_offset * (current_zoom / next_zoom)
	_clamp_camera()

func _zoom_by_scroll(direction: int) -> void:
	# direction should be +1 for zoom in, -1 for zoom out
	var floor_zoom: float = max(min_zoom_factor, _min_zoom_for_bounds())
	var factor: float = zoom_step_multiplier if direction > 0 else 1.0 / zoom_step_multiplier
	target_zoom = clamp(target_zoom * factor, floor_zoom, max_zoom_factor)

func _on_viewport_resized() -> void:
	_enforce_zoom_floor()
	_clamp_camera()

func _enforce_zoom_floor() -> void:
	var floor_zoom: float = max(min_zoom_factor, _min_zoom_for_bounds())
	if target_zoom < floor_zoom:
		target_zoom = floor_zoom
	if zoom.x < floor_zoom:
		zoom = Vector2(floor_zoom, floor_zoom)

func _confine_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED

func _get_zoom_pivot_world() -> Vector2:
	if player_controller and player_controller.grid_manager:
		return player_controller.grid_manager.tile_to_world(player_controller.hovered_coord)
	return get_global_mouse_position()

func _min_zoom_for_bounds() -> float:
	var bounds_rect: Rect2 = _get_bounds_world_rect()
	if not bounds_rect.has_area():
		return min_zoom_factor
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO:
		return min_zoom_factor
	return max(viewport_size.x / bounds_rect.size.x, viewport_size.y / bounds_rect.size.y)

func _clamp_camera() -> void:
	if not player_controller:
		return

	var bounds_rect: Rect2 = _get_bounds_world_rect()
	if not bounds_rect.has_area():
		return

	var viewport_pixel_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_pixel_size == Vector2.ZERO:
		return

	var view_world_size: Vector2 = viewport_pixel_size / zoom
	var view_extents: Vector2 = view_world_size * 0.5
	var min_center: Vector2 = bounds_rect.position + view_extents
	var max_center: Vector2 = bounds_rect.position + bounds_rect.size - view_extents

	if view_world_size.x >= bounds_rect.size.x:
		global_position.x = bounds_rect.position.x + bounds_rect.size.x * 0.5
	else:
		global_position.x = clamp(global_position.x, min_center.x, max_center.x)

	if view_world_size.y >= bounds_rect.size.y:
		global_position.y = bounds_rect.position.y + bounds_rect.size.y * 0.5
	else:
		global_position.y = clamp(global_position.y, min_center.y, max_center.y)

func _get_bounds_world_rect() -> Rect2:
	if not player_controller or not player_controller.camera_bounds:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var area: Area2D = player_controller.camera_bounds
	for child in area.get_children():
		var shape_node := child as CollisionShape2D
		if shape_node == null:
			continue
		var rect_shape := shape_node.shape as RectangleShape2D
		if rect_shape == null:
			continue
		var world_center: Vector2 = area.global_position + shape_node.position
		return Rect2(world_center - rect_shape.size * 0.5, rect_shape.size)
	return Rect2(Vector2.ZERO, Vector2.ZERO)
