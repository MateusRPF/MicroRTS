extends Camera2D
class_name CameraController

@export var edge_pan_margin: int = 64
@export var edge_pan_speed: float = 600.0
@export var zoom_step_pixels: float = 32.0
@export var min_zoom_factor: float = 0.25
@export var max_zoom_factor: float = 4.0

var player_controller: PlayerController = null

func _ready() -> void:
	player_controller = get_parent() as PlayerController
	_clamp_camera()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom_by_scroll(-1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_by_scroll(1)

func _process(delta: float) -> void:
	if not player_controller or not get_viewport():
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO:
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var direction: Vector2 = Vector2.ZERO

	if mouse_pos.x <= edge_pan_margin:
		direction.x = -1
	elif mouse_pos.x >= viewport_size.x - edge_pan_margin:
		direction.x = 1

	if mouse_pos.y <= edge_pan_margin:
		direction.y = -1
	elif mouse_pos.y >= viewport_size.y - edge_pan_margin:
		direction.y = 1

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		global_position += direction * edge_pan_speed * delta
		_clamp_camera()

func _zoom_by_scroll(direction: int) -> void:
	# direction should be +1 for zoom out, -1 for zoom in
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO:
		return

	var current_zoom: float = zoom.x
	var zoom_step: float = zoom_step_pixels / viewport_size.x
	var next_zoom: float = clamp(current_zoom + zoom_step * direction, min_zoom_factor, max_zoom_factor)
	zoom = Vector2(next_zoom, next_zoom)
	_clamp_camera()

func _clamp_camera() -> void:
	if not player_controller or not player_controller.grid_manager:
		return

	var map_rect: Rect2 = _get_map_world_rect()
	if not map_rect.has_area():
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size * zoom
	if viewport_size == Vector2.ZERO:
		return

	var view_extents: Vector2 = viewport_size * 0.5
	var min_center: Vector2 = map_rect.position + view_extents
	var max_center: Vector2 = map_rect.position + map_rect.size - view_extents

	if viewport_size.x >= map_rect.size.x:
		global_position.x = map_rect.position.x + map_rect.size.x * 0.5
	else:
		global_position.x = clamp(global_position.x, min_center.x, max_center.x)

	if viewport_size.y >= map_rect.size.y:
		global_position.y = map_rect.position.y + map_rect.size.y * 0.5
	else:
		global_position.y = clamp(global_position.y, min_center.y, max_center.y)

func _get_map_world_rect() -> Rect2:
	var grid = player_controller.grid_manager
	if not grid or grid.map_tiles.size() == 0:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF

	for coord in grid.map_tiles.keys():
		min_x = min(min_x, coord.x)
		min_y = min(min_y, coord.y)
		max_x = max(max_x, coord.x)
		max_y = max(max_y, coord.y)

	var min_tile = Vector2(min_x, min_y)
	var max_tile = Vector2(max_x, max_y)
	var top_left = grid.tile_to_world(min_tile) - Vector2(grid.HALF_TILE, grid.HALF_TILE)
	var bottom_right = grid.tile_to_world(max_tile) + Vector2(grid.HALF_TILE, grid.HALF_TILE)
	return Rect2(top_left, bottom_right - top_left)
