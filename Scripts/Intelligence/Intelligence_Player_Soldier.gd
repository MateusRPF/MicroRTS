extends IntelligenceBase
class_name Intelligence_PlayerSoldier

const REPATH_DELAY_MIN: int = 10
const REPATH_DELAY_MAX: int = 20

const PREDATE_RANGE:int = 5


func on_tick(owner: GridObject, holder: CIntelligenceHolder) -> void:

	if not (holder.executor.idling):
		return

	#predate logic
	var _units_in_range = owner.grid_manager.get_objects_in_radius(owner.current_coord, 5, CWoundable)
	var filtered = _units_in_range.filter(func(candidate):
		return filter_targets(candidate, owner)
	)
	if (filtered):
		var target = filtered[0]
		print("Soldier intelligence: Selected target %s at coordinate %s" % [target.name, target.current_coord])
		var cmd_data = CommandData.new()
		cmd_data.display_name = "Attacking %s" % target.name
		var cmd = Command_Attack.new(cmd_data, holder.executor, target.current_coord,target)
		holder.executor.queue_command(cmd, true)
		return




func on_start(_owner: GridObject, _holder: CIntelligenceHolder) -> void:
	pass

func filter_targets(candidate, PoV:GridObject) -> bool:
	if candidate == PoV:
		return false
	if candidate.side == PoV.side:
		return false
	if not candidate.get_component(CWoundable):
		return false
	if not candidate.get_component(CAttacker):
		return false
	
	return true

