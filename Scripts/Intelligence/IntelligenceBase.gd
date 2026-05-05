extends RefCounted
class_name IntelligenceBase


func on_tick(_owner: GridObject, _holder: CIntelligenceHolder) -> void:
	# To be overridden by subclasses
	pass

func on_start(_owner: GridObject, _holder: CIntelligenceHolder) -> void:
	pass

func on_end(_owner: GridObject, _holder: CIntelligenceHolder) -> void:
	_holder.blackboard.clear() #clear the blackboard on intelligence end by default, can be overridden by children if they want to preserve it.