extends GridObjectComponent
class_name CUnderConstruction

const MAX_PROGRESS: int = 30
const GHOST_ALPHA: float = 0.1
const SHAKE_MAGNITUDE: float = 3.0
const SHAKE_DURATION: float = 0.26

var current_progress: int = 0
var _shake_tween: Tween = null

signal progress_changed(component: CUnderConstruction)


func initialize_component(actor: GridObject) -> void:
	super.initialize_component(actor)
	_refresh_visual()


func get_progress_ratio() -> float:
	return float(current_progress) / float(MAX_PROGRESS)


func is_complete() -> bool:
	return current_progress >= MAX_PROGRESS


func add_progress(amount: int) -> bool:
	if is_complete():
		return false
	current_progress = min(current_progress + amount, MAX_PROGRESS)
	_refresh_visual()
	progress_changed.emit(self)
	if is_complete():
		owner_object.complete_construction()
		return true
	return false


func _refresh_visual() -> void:
	if owner_object:
		owner_object.modulate.a = GHOST_ALPHA + (1.0 - GHOST_ALPHA) * get_progress_ratio()


func shake() -> void:
	if not owner_object:
		return
	var sprite: Node2D = owner_object.get_node_or_null("%Sprite")
	if not sprite:
		return
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
	sprite.position.x = 0
	_shake_tween = sprite.create_tween()
	var step: float = SHAKE_DURATION * 0.25
	_shake_tween.tween_property(sprite, "position:x", SHAKE_MAGNITUDE, step)
	_shake_tween.tween_property(sprite, "position:x", -SHAKE_MAGNITUDE, step)
	_shake_tween.tween_property(sprite, "position:x", SHAKE_MAGNITUDE * 0.5, step)
	_shake_tween.tween_property(sprite, "position:x", 0.0, step)
