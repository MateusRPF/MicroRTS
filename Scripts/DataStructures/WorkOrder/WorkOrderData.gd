extends Resource
class_name WorkOrderData


enum WorkOrderType { RECRUIT, UPGRADE, CONVERT_RESOURCE } #RESEARCH }

@export var type: WorkOrderType
@export var name: String
@export var immediate_cost:GameResource = preload("res://Data/GameResources/Resource_Essence.tres")
@export var immediate_cost_value: int
@export var description: String
@export var icon: Texture2D
@export var work_required:int
@export var accepted_tags: Array[ActorTag]

@export var associated_actorData: ActorData
@export var requirements: Array[WorkOrderData.Requirement]
#@export var associated_tech: TechnologyData


func get_resource_costs() -> Dictionary[GameResource, int]:
	match type:
		WorkOrderType.RECRUIT:
			return associated_actorData.costs
		WorkOrderType.UPGRADE:
			return associated_actorData.costs
	
	return {} 

func can_initiate(player_state: PlayerState) -> bool:
	# Check essence cost
	if player_state.get_resource_value(immediate_cost) < immediate_cost_value:
		return false

	#add checks for tech requirements here if we add tech

	return true

func get_tooltip_config() -> TooltipConfiguration:
	var tooltip = TooltipConfiguration.new()
	tooltip.title = name
	tooltip.description = get_description()
	tooltip.costs.clear()

	if (self.immediate_cost_value):
		var essenceTip = TooltipConfiguration.TooltipCost.new()
		essenceTip.cost_resource = immediate_cost
		essenceTip.cost_amount = self.immediate_cost_value
		essenceTip.validate_on_wallet = true
		tooltip.immediate_cost = essenceTip

	for res in get_resource_costs():
		var cost = TooltipConfiguration.TooltipCost.new()
		cost.cost_resource = res
		cost.cost_amount = get_resource_costs()[res]
		tooltip.costs.append(cost)

	return tooltip

func get_icon()->Texture2D:
	match type:
		WorkOrderType.RECRUIT:
			return associated_actorData.sprite
		WorkOrderType.UPGRADE:
			return associated_actorData.sprite
	return icon


func get_description() ->String:
	match type:
		WorkOrderType.RECRUIT:
			return associated_actorData.description
		WorkOrderType.UPGRADE:
			return associated_actorData.description
	return description

func perform_payload(workIssuer: GridObject) -> void:
	match type:
		WorkOrderType.RECRUIT:
			perform_recruit(workIssuer)
		WorkOrderType.UPGRADE:
			perform_upgrade(workIssuer)
		# WorkOrderType.RESEARCH:
		# 	perform_research(workIssuer)
	pass

func perform_recruit(_workIssuer: GridObject) -> void:
	pass

func perform_upgrade(_workIssuer: GridObject) -> void:
	pass

func perform_research(_workIssuer: GridObject) -> void:
	pass	


class Requirement:
	extends Resource
	enum RequirementType {TECHNOLOGY, NEARBY}

	var type:RequirementType = RequirementType.TECHNOLOGY
	var required_actor:ActorData
	#var required_tech:Technology
