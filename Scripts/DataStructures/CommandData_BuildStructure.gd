extends CommandData
class_name CommandData_BuildStructure

@export var structure_scene: PackedScene
@export var cost: Dictionary[GameResource, int] = {}

var _cache_ready: bool = false
var _cached_size: Vector2i = Vector2i.ONE
var _cached_clearance: int = 0


func total_cost() -> int:
	var sum: int = 0
	for res in cost:
		sum += cost[res]
	return sum


func _ensure_cache() -> void:
	if _cache_ready:
		return
	if not structure_scene:
		_cache_ready = true
		return
	var temp := structure_scene.instantiate() as GridObject
	if temp and temp.data:
		_cached_size = temp.data.grid_size
		_cached_clearance = temp.data.clearance
	if temp:
		temp.free()
	_cache_ready = true


func get_footprint_size() -> Vector2i:
	_ensure_cache()
	return _cached_size


func get_clearance() -> int:
	_ensure_cache()
	return _cached_clearance
