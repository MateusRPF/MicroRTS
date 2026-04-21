extends Node2D

@onready var controller = get_parent()

func get_color_for_side(side: ActorData.Sides) -> Color:
	match side:
		ActorData.Sides.PLAYER:
			return Color(1, 1, 1, 0.5)  # White
		ActorData.Sides.ENEMY:
			return Color(1, 0, 0, 0.5)  # Red
		ActorData.Sides.NEUTRAL:
			return Color(1, 1, 0, 0.5)  # Yellow
		ActorData.Sides.ALLY:
			return Color(0, 1, 1, 0.5)  # Cyan (assuming ally like player)
		_:
			return Color(1, 1, 0, 0.5)  # Default to yellow

func draw_rect_corners(rect: Rect2, color: Color, width: float = 1.0, corner_length: float = 10.0) -> void:
	# Normalize rect to ensure positive width and height
	rect = rect.abs()
	var tl = rect.position
	var tr = rect.position + Vector2(rect.size.x, 0)
	var bl = rect.position + Vector2(0, rect.size.y)
	var br = rect.position + rect.size
	
	# Top-left corner
	draw_line(tl, tl + Vector2(corner_length, 0), color, width)
	draw_line(tl, tl + Vector2(0, corner_length), color, width)
	
	# Top-right corner
	draw_line(tr, tr - Vector2(corner_length, 0), color, width)
	draw_line(tr, tr + Vector2(0, corner_length), color, width)
	
	# Bottom-left corner
	draw_line(bl, bl + Vector2(corner_length, 0), color, width)
	draw_line(bl, bl - Vector2(0, corner_length), color, width)
	
	# Bottom-right corner
	draw_line(br, br - Vector2(corner_length, 0), color, width)
	draw_line(br, br - Vector2(0, corner_length), color, width)

func _draw() -> void:
	# 1. Draw the marquee box while dragging
	if controller.is_dragging:
		var rect = Rect2(controller.drag_start_pos, controller.drag_end_pos - controller.drag_start_pos)
		draw_rect(rect, Color(0, 1, 0, 0.2), true) # Fill
		draw_rect_corners(rect, Color(0, 1, 0, 0.5), 2.0) # Border corners on top

	# 2. Draw highlights for all selected units
	for unit in controller.selected_objects:
		if not (unit):
			return
		var view_child = unit.get_child(0).get_child(0) as Node2D
		var tile_size = controller.grid_manager.TILE_SIZE
		var rect = Rect2(view_child.global_position - Vector2(tile_size / 2, tile_size / 2), Vector2(tile_size, tile_size))
		var color = get_color_for_side(unit.side)
		draw_rect_corners(rect, color, 1.0)
	_draw_hover_rect()

func _draw_hover_rect() -> void:
	draw_rect_corners(get_rect_for_tile(controller.hovered_coord), Color(1, 1, 1, 0.5), 1.0)

func _process(_delta: float) -> void:
	
	queue_redraw()  # Request redraw every frame to update hover and selection visuals

func _draw_selection_ui() -> void:
	var object: GridObject = controller.selectedObject
	var rect = Rect2(object.get_child(0).get_child(0).global_position - Vector2(16, 16), Vector2(32, 32))
	var color = get_color_for_side(object.side)
	draw_rect_corners(rect, color, 3.0)


func get_rect_for_tile(tile: Vector2i) -> Rect2:
	var tile_size = controller.grid_manager.TILE_SIZE
	var rect_pos = controller.grid_manager.tile_to_world(tile)
	return Rect2(rect_pos.x - tile_size / 2, rect_pos.y - tile_size / 2, tile_size, tile_size)
