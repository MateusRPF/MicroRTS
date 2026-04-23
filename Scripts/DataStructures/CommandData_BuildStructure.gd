extends CommandData
class_name CommandData_BuildStructure

@export var structure_scene: PackedScene

var _cached_size: Vector2i = Vector2i.ZERO


func get_footprint_size() -> Vector2i:
	if _cached_size != Vector2i.ZERO:
		return _cached_size
	if not structure_scene:
		_cached_size = Vector2i.ONE
		return _cached_size
	var temp := structure_scene.instantiate() as GridObject
	_cached_size = temp.data.grid_size
	temp.free()
	return _cached_size
