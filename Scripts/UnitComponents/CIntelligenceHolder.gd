extends GridObjectComponent
class_name CIntelligenceHolder

var executor: CCommandExecutor = null
var held_intelligence: IntelligenceBase
var blackboard: Dictionary = {}


func initialize_component(actor: GridObject) -> void:
	super.initialize_component(actor)
	executor = actor.get_component(CCommandExecutor)
	if (held_intelligence):
		held_intelligence.on_start(actor, self)


func _on_tick_received() -> void:
	if held_intelligence:
		held_intelligence.on_tick(owner_object, self)


func swap_intelligence(new_intel: IntelligenceBase) -> void:
	held_intelligence.on_end(owner_object, self)
	held_intelligence = new_intel
	held_intelligence.on_start(owner_object, self)
	
func add_to_blackboard(key: String, value) -> void:
	blackboard[key] = value

func get_from_blackboard(key: String, default_value = null):
	return blackboard.get(key, default_value)
