extends GridObjectComponent
class_name CHarvester

var currently_harvesting_resource: GameResource = null
var harvest_target_node: CResourceNode = null
var max_storage: int = 10
var tick_counter: int = 0
var inventory:CInventory


const TICKS_PER_HARVEST:int = 6
const PUNCH_DISTANCE: float = 14.0
const PUNCH_DURATION: float = 0.16


func initialize_component(actor: GridObject) -> void:
	super.initialize_component(actor)
	
	inventory = actor.get_component(CInventory)

func can_harvest(node:CResourceNode) -> bool:
	return node.owner_object.get_perimeter().has(owner_object.current_coord)



func _on_tick_received() -> void:
	if currently_harvesting_resource && harvest_target_node:
		tick_counter += 1
		if tick_counter >= TICKS_PER_HARVEST:
			tick_counter = 0
			perform_harvest(harvest_target_node)


func perform_harvest(node:CResourceNode) -> void:
	if can_harvest(node):
		currently_harvesting_resource = node.resource
		var harvestQuantity = 0
		var attribute_set:CAttributeSet = owner_object.get_component(CAttributeSet)
		if attribute_set:
			harvestQuantity = attribute_set.get_attr(CAttributeSet.ATTR_ID.ATTR_HARVEST_POWER)

		var storageLeft = max(0,inventory.max_storage_per_entry- inventory.get_stored_qty(currently_harvesting_resource))
		harvestQuantity = min(harvestQuantity,storageLeft)

		owner_object.play_interaction_with(node.owner_object)
		node.owner_object.play_shake()
		inventory.deposit(currently_harvesting_resource, node.grant_resource(harvestQuantity))




func deliver_to(stockpile: CStockpile) -> void:

	stockpile.deposit_resource(self,currently_harvesting_resource,inventory.withdrawal(currently_harvesting_resource,inventory.get_stored_qty(currently_harvesting_resource)))
	if stockpile.owner_object:
		owner_object.play_interaction_with(stockpile.owner_object)
	


func _draw_debug() -> void:

	var path_color = Color.GREEN
	
	if(harvest_target_node):
		var start_pos = owner_object.grid_manager.tile_to_world(owner_object.current_coord) - owner_object.global_position
		var end_pos = owner_object.grid_manager.tile_to_world(harvest_target_node.owner_object.current_coord)  - owner_object.global_position

		_debug_proxy.draw_line(start_pos,end_pos,path_color,1)
