extends Node2D
class_name PlayerController
enum ControlState { IDLE, AIMING, BUILDING }

@export var grid_manager: GridManager
@export var camera_bounds: Area2D
@onready var draw_node = $ControllerDraw
@onready var command_controller: CommandController = %CommandController
@onready var aim_preview:Sprite2D = %AimingVisual

const MAX_GROUP_SIZE = 18

var current_state: ControlState = ControlState.IDLE
var selected_objects: Array[GridObject] = []
var hovered_coord: Vector2i = Vector2i.ZERO

# Drag selection
var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_end_pos: Vector2 = Vector2.ZERO

# Command & Build Data
var aiming_command: CommandData = null


func _ready() -> void:
	GameplayEvents.UI_controller_ready.emit(self)
	GameplayEvents.UI_command_requested.connect(on_command_aim_request)

func on_command_aim_request(new_command: CommandData):
	print("Command was requested! %s" %[new_command.display_name])
	aiming_command = new_command
	
	# Clear existing ghosts if any
	_clear_ghost()
	
	if aiming_command.target_mode == CommandData.Targetting.BUILD_SETUP:
		current_state = ControlState.BUILDING
		_update_aiming_visual()
	else:
		_update_aiming_visual()
		current_state = ControlState.AIMING

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover()
		if is_dragging:
			drag_end_pos = get_global_mouse_position()
		if aim_preview:
			aim_preview.global_position = grid_manager.tile_to_world(hovered_coord)
			_update_aiming_visual()
		draw_node.queue_redraw()
	
	if event is InputEventMouseButton:
		_handle_mouse_click(event)

func _handle_mouse_click(event: InputEventMouseButton):
	# LEFT CLICK
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if current_state == ControlState.IDLE:
				_start_dragging()
			else:
				_confirm_aimed_command()
		else:
			if is_dragging: _stop_dragging()
			
	# RIGHT CLICK (Cancel or Contextual)
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if current_state != ControlState.IDLE:
			_cancel_aiming()
		else:
			# Normal contextual order (Move/Harvest)
			command_controller.issue_wildcard_order(selected_objects)

# --- Command Execution ---

func _confirm_aimed_command():
	print("Valid Target!")
	if _is_command_target_valid():
		command_controller.issue_aimed_command(selected_objects, aiming_command, hovered_coord)
		
		_cancel_aiming()
	else:
		print("Invalid Target!")

func _cancel_aiming():
	aiming_command = null
	current_state = ControlState.IDLE
	_clear_ghost()
	draw_node.queue_redraw()

# --- Build Mode Terrain ---

func _update_aiming_visual():
	if (aiming_command):
		aim_preview.texture = aiming_command.icon # Placeholder for the building sprite
		if (_is_command_target_valid()):
			aim_preview.modulate = Color(1, 1, 1, 0.7) # Semi-transparent
		else:
			aim_preview.modulate = Color.RED # big bad red
	else:
		aim_preview.texture = null

func _clear_ghost():
	if aim_preview:
		aim_preview.texture = null

func _is_command_target_valid() -> bool:
	if (aiming_command && selected_objects.size() >0):
		return command_controller.validate_command_on_coord(selected_objects[0].get_component(CCommandExecutor),hovered_coord,aiming_command)

	return false

	

# --- Selection Logic ---

func _select_at_mouse() -> void:
	selected_objects.clear()
	var tile = grid_manager.map_tiles[hovered_coord]
	if tile and tile.occupant:
		selected_objects.append(tile.occupant)

	_emit_selection()

func _select_in_box() -> void:
	selected_objects.clear()
	
	# Create a Rect2 from the drag positions
	var selection_rect = Rect2(drag_start_pos, Vector2.ZERO).expand(drag_end_pos)
	
	var tilesInRect = grid_manager.get_tiles_in_rect(selection_rect)
	for tile in tilesInRect:
		if (tile.occupant):
			selected_objects.append(tile.occupant)

	selected_objects = _filter_multiple_selection(selected_objects)
	_emit_selection()

func _filter_multiple_selection(objects:Array[GridObject]) -> Array[GridObject]:
	var player_objects:Array[GridObject] = []
	for object in objects:
		if object.side == ActorData.Sides.PLAYER:
			player_objects.append(object)

	if player_objects.size() == 0:
		return []

	var movers:Array[GridObject] = []
	for object in player_objects:
		if object.get_component(CMover):
			movers.append(object)

	if movers.size() > 0:
		player_objects = movers

	if player_objects.size() > MAX_GROUP_SIZE:
		return player_objects.slice(0,MAX_GROUP_SIZE)
	return player_objects

func _emit_selection():
	if (selected_objects.size() == 0):
		GameplayEvents.selection_cleared.emit()
	elif (selected_objects.size() == 1):
		GameplayEvents.object_selected.emit(selected_objects[0])
	else:
		GameplayEvents.multiple_objects_selected.emit(selected_objects)

func _start_dragging() -> void:
	is_dragging = true
	drag_start_pos = get_global_mouse_position()
	drag_end_pos = drag_start_pos

func _stop_dragging() -> void:
	is_dragging = false
	# If the mouse barely moved, treat it as a single click
	if drag_start_pos.distance_to(drag_end_pos) < 16.0:
		_select_at_mouse()
	else:
		_select_in_box()
	draw_node.queue_redraw()

func _update_hover() -> void:
	hovered_coord = grid_manager.world_to_tile(get_global_mouse_position())
	GameplayEvents.UI_tile_hovered.emit(self,hovered_coord)
	
