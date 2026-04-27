extends Node2D
class_name GridObject


@export var size: Vector2i = Vector2i(1, 1)
var current_coord: Vector2i = Vector2i.ZERO

var grid_manager: GridManager = null

var player_state: PlayerState = null

var side: ActorData.Sides = ActorData.Sides.NEUTRAL

@export var tint_map:Dictionary[ActorData.Sides, Color]


var data:ActorData = null

@onready var randomizedPriority = randi()

var _component_cache: Dictionary = {}

const INTERACT_LEAN_DISTANCE: float = 6.0
const INTERACT_DURATION: float = 0.3
const INTERACT_SHAKE_MAGNITUDE: float = 2.0
const INTERACT_SHAKE_DURATION: float = 0.2
const HIT_FLASH_DURATION: float = 0.5

var _interact_tween: Tween = null
var _shake_tween: Tween = null
var _hit_flash_tween: Tween = null


signal OnTickReceived

func Initialize(manager: GridManager, coord: Vector2i, newSide:ActorData.Sides, state:PlayerState, actorData: ActorData) -> void:
	grid_manager = manager
	current_coord = coord
	side = newSide
	player_state = state
	GlobalTicker.TickSignal.connect(_on_global_tick)
	assemble_from_data(actorData)
	_update_color_tint()

	grid_manager.UpdatePosition(self, current_coord)

	settle_position()


func initialize_as_construction_site(manager: GridManager, coord: Vector2i, newSide: ActorData.Sides, target_data: ActorData, cost: Dictionary[GameResource, int], state: PlayerState) -> void:
	grid_manager = manager
	current_coord = coord
	side = newSide
	player_state = state
	data = target_data
	%Sprite.texture = data.sprite
	%Sprite.offset = data.view_offset
	%Sprite.material = null
	size = data.grid_size

	GlobalTicker.TickSignal.connect(_on_global_tick)

	var requirements := CBuildRequirements.new()
	add_child(requirements)
	requirements.initialize_component(self)
	_component_cache[requirements.get_script()] = requirements
	requirements.init_requirements(cost)

	var construction := CUnderConstruction.new()
	add_child(construction)
	construction.initialize_component(self)
	_component_cache[construction.get_script()] = construction
	var cost_sum: int = 0
	for res in cost:
		cost_sum += cost[res]
	construction.init_from_cost(cost_sum)

	grid_manager.UpdatePosition(self, current_coord)
	settle_position()


func complete_construction() -> void:
	var construction: CUnderConstruction = get_component(CUnderConstruction)
	if construction:
		_component_cache.erase(construction.get_script())
		construction.queue_free()
	var requirements: CBuildRequirements = get_component(CBuildRequirements)
	if requirements:
		_component_cache.erase(requirements.get_script())
		requirements.queue_free()
	modulate.a = 1.0
	_update_color_tint()
	for module in data.modules:
		var newComp = module.assemble_component(self)
		_component_cache[newComp.get_script()] = newComp

func assemble_from_data(newData:ActorData):
	data = newData
	%Sprite.texture = data.sprite
	%Sprite.offset = data.view_offset
	size = newData.grid_size

	for module in data.modules:
		var newComp = module.assemble_component(self)
		_component_cache[newComp.get_script()] = newComp

func _update_color_tint() -> void:
	var color_rect = get_node_or_null("%ColorRect")
	var progress_bar = get_node_or_null("%ProgressBar1")
	if not color_rect:
		return
	color_rect.size.x *= size.x
	color_rect.size.y *= size.y
	color_rect.position.y += -32 * (size.y-1)

	if tint_map.has(side):
		color_rect.color = tint_map[side]
		if progress_bar:
			progress_bar.modulate = tint_map[side]
	else:
		color_rect.color = Color(0, 0, 0, 0)



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


func play_interaction_with(target: GridObject, shake_target: bool = true, duration: float = INTERACT_DURATION) -> void:
	if not is_instance_valid(target):
		return
	var pivot: Node2D = get_node_or_null("%ViewPivot")
	if not pivot:
		return
	var delta: Vector2 = Vector2(target.current_coord - current_coord)
	if delta.length_squared() == 0:
		return
	var offset: Vector2 = delta.normalized() * INTERACT_LEAN_DISTANCE
	if _interact_tween and _interact_tween.is_running():
		_interact_tween.kill()
	pivot.position = Vector2.ZERO
	_interact_tween = pivot.create_tween()
	var third: float = duration / 3.0
	_interact_tween.tween_property(pivot, "position", offset, third).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if shake_target:
		var target_id: int = target.get_instance_id()
		_interact_tween.tween_callback(func():
			var t: GridObject = instance_from_id(target_id) as GridObject
			if t and is_instance_valid(t):
				t.play_shake()
		)
	_interact_tween.tween_interval(third)
	_interact_tween.tween_property(pivot, "position", Vector2.ZERO, third).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func play_shake() -> void:
	var sprite: Node2D = get_node_or_null("%Sprite")
	if not sprite:
		return
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
	sprite.position.x = 0
	_shake_tween = sprite.create_tween()
	var step: float = INTERACT_SHAKE_DURATION * 0.25
	_shake_tween.tween_property(sprite, "position:x", INTERACT_SHAKE_MAGNITUDE, step)
	_shake_tween.tween_property(sprite, "position:x", -INTERACT_SHAKE_MAGNITUDE, step)
	_shake_tween.tween_property(sprite, "position:x", INTERACT_SHAKE_MAGNITUDE * 0.5, step)
	_shake_tween.tween_property(sprite, "position:x", 0.0, step)


func play_hit_flash() -> void:
	_play_flash(Color(2.0, 0.5, 0.5))


func play_white_flash() -> void:
	_play_flash(Color(2.0, 2.0, 2.0))


func _play_flash(color: Color) -> void:
	var sprite: Node2D = get_node_or_null("%Sprite")
	if not sprite:
		return
	if _hit_flash_tween and _hit_flash_tween.is_running():
		_hit_flash_tween.kill()
	sprite.modulate = color
	_hit_flash_tween = sprite.create_tween()
	_hit_flash_tween.tween_property(sprite, "modulate", Color(1, 1, 1), HIT_FLASH_DURATION)
