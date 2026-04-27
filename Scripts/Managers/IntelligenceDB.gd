extends Node
class_name IntelligenceDatabase


var helpless_wander: Intelligence_HelplessWander = Intelligence_HelplessWander.new()
var predator: Intelligence_Predator = Intelligence_Predator.new()
var intels:Dictionary[IntelligenceID,IntelligenceBase] = {
	IntelligenceID.HELPLESS_WANDER: helpless_wander,
	IntelligenceID.PREDATOR: predator
	# IntelligenceID.SEEK_AND_DESTROY: SEEK_AND_DESTROY,
	# IntelligenceID.WARDEN: WARDEN,
	# IntelligenceID.PLAYER_WORKER: PLAYER_WORKER,
	# IntelligenceID.PLAYER_SOLDIER: PLAYER_SOLDIER,
	# IntelligenceID.HARVEST_CORPSE: HARVEST_CORPSE
}


enum IntelligenceID{
	HELPLESS_WANDER,
	PREDATOR
	# SEEK_AND_DESTROY
	# WARDEN
	# PLAYER_WORKER
	# HARVEST_CORPSE
}
