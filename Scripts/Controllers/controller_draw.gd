extends Node2D

@onready var controller = get_parent()

func _draw() -> void:
	# 1. Draw the marquee box while dragging
	if controller.is_dragging:
		var rect = Rect2(controller.drag_start_pos, controller.drag_end_pos - controller.drag_start_pos)
		draw_rect(rect, Color(0, 1, 0, 0.2), true) # Fill
		draw_rect(rect, Color(0, 1, 0, 0.5), false, 2.0) # Border

	# 2. Draw highlights for all selected units
	for unit in controller.selected_objects:
		if not (unit):
			return
		var view_child = unit.get_child(0)
		var tile_size = controller.grid_manager.TILE_SIZE
		var rect = Rect2(view_child.global_position - Vector2(tile_size / 2, tile_size / 2), Vector2(tile_size, tile_size))
		draw_rect(rect, Color(1, 1, 0, 0.5), false, 3.0)
	_draw_hover_rect()

func _draw_hover_rect() -> void:
	draw_rect(get_rect_for_tile(controller.hovered_coord), Color(1, 1, 1, 0.5), false)

func _process(_delta: float) -> void:
	
	queue_redraw()  # Request redraw every frame to update hover and selection visuals

func _draw_selection_ui() -> void:
	var object: GridObject = controller.selectedObject
	var rect = Rect2(object.position - Vector2(16, 16), Vector2(32, 32))
	draw_rect(rect, Color.YELLOW, false, 3.0)


func get_rect_for_tile(tile: Vector2i) -> Rect2:
	var tile_size = controller.grid_manager.TILE_SIZE
	var rect_pos = controller.grid_manager.tile_to_world(tile)
	return Rect2(rect_pos.x - tile_size / 2, rect_pos.y - tile_size / 2, tile_size, tile_size)
