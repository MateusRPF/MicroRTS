extends IntelligenceBase
class_name Intelligence_Predator

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
		var cmd_data = CommandData.new()
		cmd_data.display_name = "Attacking %s" % target.name
		var cmd = Command_Attack.new(cmd_data, holder.executor, target.current_coord,target)
		var attributeSet = owner.get_component(CAttributeSet)
		if attributeSet:
			attributeSet.get_attr_instance(CAttributeSet.ATTR_ID.ATTR_MOVE_SPEED).mult_bonus = 0
		holder.executor.queue_command(cmd, true)
		return



	#Wander logic
	var current_counter = holder.get_from_blackboard("repath_delay_counter", 0)
	var current_delay = holder.get_from_blackboard("repath_delay", REPATH_DELAY_MIN)
	if current_counter >= current_delay:
		var cmd = generate_command(owner, holder)
		holder.executor.queue_command(cmd,false)
		holder.add_to_blackboard("repath_delay_counter", 0)
	else:
		holder.add_to_blackboard("repath_delay_counter", current_counter + 1)

func on_start(_owner: GridObject, holder: CIntelligenceHolder) -> void:
	holder.add_to_blackboard("repath_delay", randi_range(REPATH_DELAY_MIN, REPATH_DELAY_MAX))
	holder.add_to_blackboard("repath_delay_counter",99)
	var attributeSet = _owner.get_component(CAttributeSet)
	if attributeSet:
		attributeSet.get_attr_instance(CAttributeSet.ATTR_ID.ATTR_MOVE_SPEED).mult_bonus = -0.5

func filter_targets(candidate, PoV:GridObject) -> bool:
	if candidate == PoV:
		return false
	if candidate.side == PoV.side:
		return false
	if not candidate.get_component(CWoundable):
		return false
	
	return true


func generate_command(owner: GridObject, holder: CIntelligenceHolder) -> Command:
	var cmd_data = CommandData.new()
	cmd_data.display_name = "Wandering"
	var cmd = Command_Wander.new(cmd_data,holder.executor,owner.current_coord,null)
	return cmd
