extends GridObjectComponent
class_name CResourceGen

@export var resource: GameResource
@export var amount_per_generation: int = 1
@export var generation_interval_seconds: float = 5.0

var generation_progress: float = 0.0

func _ready() -> void:
	GlobalTicker.tick_rate_changed.connect(_on_tick_rate_changed)

func _on_tick_rate_changed(_new_rate: float) -> void:
	pass  # No action needed, progress continues

func _on_tick_received() -> void:
	if not resource:
		return
	if owner_object.side == ActorData.Sides.NEUTRAL:
		return
	
	if GlobalTicker.is_paused:
		return
	
	generation_progress += GlobalTicker.tick_rate / generation_interval_seconds
	if generation_progress >= 1.0:
		generation_progress -= 1.0
		if owner_object.player_state:
			owner_object.player_state.add_resource(resource, amount_per_generation)