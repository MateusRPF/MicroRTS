extends Node2D
class_name GridObject

@export var size: Vector2i = Vector2i(1, 1)
var current_coord: Vector2i = Vector2i.ZERO

var grid_manager: GridManager = null

var side: ActorData.Sides = ActorData.Sides.NEUTRAL

@export var material_map:Dictionary[ActorData.Sides, ShaderMaterial]


@export var data:ActorData = null

@onready var randomizedPriority = randi()

var _component_cache: Dictionary = {}


signal OnTickReceived

func Initialize(manager: GridManager, coord: Vector2i, newSide:ActorData.Sides) -> void:
	grid_manager = manager
	current_coord = coord
	side = newSide

	GlobalTicker.TickSignal.connect(_on_global_tick)
	assemble_from_data(data)
	_update_outline_color()

	grid_manager.UpdatePosition(self, current_coord)

	settle_position()

func assemble_from_data(newData:ActorData):
	data = newData
	%Sprite.texture = data.sprite
	%Sprite.offset = data.view_offset
	size = newData.grid_size

	for module in data.modules:
		var newComp = module.assemble_component(self)
		_component_cache[newComp.get_script()] = newComp

func _update_outline_color() -> void:
	if material_map.has(side):
		%Sprite.material = material_map[side]
	else:
		%Sprite.material = material_map[ActorData.Sides.NEUTRAL]



func _on_global_tick() -> void:
	OnTickReceived.emit()

func settle_position():
	if not grid_manager:
		push_error("GridObject.settle() called without grid_manager initialized")
		return
	global_position = grid_manager.tile_to_world(current_coord)


func get_covered_coords() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	var origin = current_coord
	for size_x in range(size.x):
		for size_y in range(size.y):
			var newCoord = Vector2i(origin.x + size_x, origin.y - size_y)
			if grid_manager.map_tiles.has(newCoord):
				coords.append(newCoord)
	return coords



func contains_grid_cell(cell: Vector2i) -> bool:
	var origin = settle_position()
	var bottom = origin.y - size.y + 1
	return cell.x >= origin.x and cell.x < origin.x + size.x and cell.y >= bottom and cell.y <= origin.y


func get_component(type: Script) -> GridObjectComponent:
	return _component_cache.get(type, null)

func get_component_by_name(script_name:String) -> GridObjectComponent:
	for component:GridObjectComponent in _component_cache:
		if component.get_class() == script_name:
			return component
	return null

func destroy_object():
	grid_manager.ClearPosition(self)
	queue_free()
