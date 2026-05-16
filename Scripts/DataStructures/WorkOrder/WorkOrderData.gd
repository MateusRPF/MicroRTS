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
@export var associated_actorID: String
@export var requirements: Array[WorkOrderData.Requirement]
#@export var associated_tech: TechnologyData


func get_resource_costs() -> Dictionary[GameResource, int]:
	var data:ActorData = Database.get_actor_data(associated_actorID)
	match type:
		WorkOrderType.RECRUIT:
			return data.costs
		WorkOrderType.UPGRADE:
			return data.costs
	
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
	var data:ActorData = Database.get_actor_data(associated_actorID)
	match type:
		WorkOrderType.RECRUIT:
			return data.sprite
		WorkOrderType.UPGRADE:
			return data.sprite
	return icon


func get_description() ->String:
	var data:ActorData = Database.get_actor_data(associated_actorID)
	match type:
		WorkOrderType.RECRUIT:
			return data.description
		WorkOrderType.UPGRADE:
			return data.description
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

func perform_recruit(work_issuer: GridObject) -> void:
	print("Performing Recruit unit!")
	var available_placements:Array[Vector2i] = work_issuer.get_perimeter()
	var found_placement:bool = false
	var placement:Vector2i
	for coord in available_placements:
		var tile: GameTile =  work_issuer.grid_manager.map_tiles[coord]
		if (tile.tile_type != GameTile.TileType.FLOOR):
			continue
		if tile.has_unit_occupant:
			continue
		
		placement = coord
		found_placement = true
		break

	if (found_placement):
		work_issuer.grid_manager.spawn_grid_object(associated_actorID,placement,work_issuer.side,work_issuer.player_state)
	else:
		push_error("Wah! no placement!")





func perform_upgrade(_workIssuer: GridObject) -> void:
	push_error("UPGRADED!!")

func perform_research(_workIssuer: GridObject) -> void:
	push_error("RESEARCHED!!")	


class Requirement:
	extends Resource
	enum RequirementType {TECHNOLOGY, NEARBY}

	var type:RequirementType = RequirementType.TECHNOLOGY
	var required_actor:ActorData
	#var required_tech:Technology
