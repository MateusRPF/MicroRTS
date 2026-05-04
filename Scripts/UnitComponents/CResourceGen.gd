extends GridObjectComponent
class_name CResourceGen

@export var resource: GameResource
@export var amount_per_generation: int = 1
@export var generation_interval_seconds: float = 1.0

var time_accumulator: float = 0.0

func _ready() -> void:
	if not resource:
		push_error("CResourceGen: No resource assigned")
		return

func _process(delta: float) -> void:
	if owner_object.side == ActorData.Sides.NEUTRAL:
		return  # Only player units generate resources?
	
	time_accumulator += delta
	if time_accumulator >= generation_interval_seconds:
		time_accumulator -= generation_interval_seconds
		if owner_object.player_state:
			owner_object.player_state.add_resource(resource, amount_per_generation)