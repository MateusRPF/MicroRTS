extends GridObjectComponent
class_name CUnderConstruction

const HITS_PER_RESOURCE: int = 4
const GHOST_ALPHA: float = 0.1
const SHAKE_MAGNITUDE: float = 3.0
const SHAKE_DURATION: float = 0.26

var max_progress: int = 0
var current_progress: int = 0

signal progress_changed(component: CUnderConstruction)


func initialize_component(actor: GridObject) -> void:
	super.initialize_component(actor)
	_refresh_visual()


func init_from_cost(_cost_sum: int) -> void:
	max_progress = 100
	current_progress = 0
	_refresh_visual()


func get_progress_ratio() -> float:
	if max_progress <= 0:
		return 0.0
	return float(current_progress) / float(max_progress)


func is_complete() -> bool:
	return max_progress > 0 and current_progress >= max_progress


func add_progress(amount: int) -> bool:
	if is_complete() or max_progress <= 0:
		return false
	current_progress = min(current_progress + amount, max_progress)
	_refresh_visual()
	progress_changed.emit(self)
	if is_complete():
		owner_object.complete_construction()
		return true
	return false


func _refresh_visual() -> void:
	var sprite: Sprite2D = owner_object.get_node("%Sprite") as Sprite2D
	sprite.modulate.a = GHOST_ALPHA + (1.0 - GHOST_ALPHA) * get_progress_ratio()
	var bar: ProgressBar = owner_object.get_node("%ProgressBar1") as ProgressBar
	bar.max_value = max_progress
	bar.value = current_progress
	bar.visible = not is_complete()

