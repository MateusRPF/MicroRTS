extends State
class_name State_Harvest

var target_resource: CResourceNode = null
var harvester: CHarvester = null

func enter_state(params: Dictionary) -> bool:
	harvester = owner_machine.owner_object.get_component(CHarvester)
	if not params.has("target_resource"):
		print("State_Harvest Missing target_resource param for harvest state")
		return false
	
	target_resource = params["target_resource"] as CResourceNode
	harvester.currently_harvesting_resource = target_resource.resource
	harvester.harvest_target_node = target_resource

	if not (target_resource):
		push_error("No target resource on state assignment")
	return true

func tick_state() -> void:
	if not (target_resource && harvester.can_harvest(target_resource)):
		owner_machine.request_state(CStateMachine.StateID.IDLE)

func exit_state() -> void:
	pass
	#harvester.currently_harvesting_resource = null
