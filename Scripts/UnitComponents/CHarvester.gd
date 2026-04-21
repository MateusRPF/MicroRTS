extends GridObjectComponent
class_name CHarvester

var currently_harvesting_resource: GameResource = null
var harvest_target_node: CResourceNode = null
var max_storage: int = 10
var tick_counter: int = 0
var inventory:CInventory


const TICKS_PER_HARVEST:int = 3
const PUNCH_DISTANCE: float = 14.0
const PUNCH_DURATION: float = 0.16

var _punch_tween: Tween = null


func initialize_component(actor: GridObject) -> void:
	super.initialize_component(actor)
	
	inventory = actor.get_component(CInventory)

func can_harvest(node:CResourceNode) -> bool:
	if not node:
		return false
	if not inventory.has_room_for(node.resource):
		return false
	var distance = owner_object.grid_manager.calculate_distance(owner_object.current_coord, node.owner_object.current_coord)
	return distance <2

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

		_play_punch(node)
		node.shake()
		inventory.deposit(currently_harvesting_resource, node.grant_resource(harvestQuantity))


func _play_punch(node: CResourceNode) -> void:
	var sprite: Node2D = owner_object.get_node_or_null("%Sprite")
	if not sprite or not is_instance_valid(node) or not is_instance_valid(node.owner_object):
		return
	var delta: Vector2 = Vector2(node.owner_object.current_coord - owner_object.current_coord)
	if delta.length_squared() == 0:
		return
	if _punch_tween and _punch_tween.is_running():
		_punch_tween.kill()
	var punch_offset: Vector2 = delta.normalized() * PUNCH_DISTANCE
	sprite.position = Vector2.ZERO
	_punch_tween = sprite.create_tween()
	_punch_tween.tween_property(sprite, "position", punch_offset, PUNCH_DURATION * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_punch_tween.tween_property(sprite, "position", Vector2.ZERO, PUNCH_DURATION * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func deliver_to(stockpile: CStockpile) -> void:
	
	stockpile.deposit_resource(self,currently_harvesting_resource,inventory.withdrawal(currently_harvesting_resource,inventory.get_stored_qty(currently_harvesting_resource)))
	


func _draw_debug() -> void:

	var path_color = Color.GREEN
	
	if(harvest_target_node):
		var start_pos = owner_object.grid_manager.tile_to_world(owner_object.current_coord) - owner_object.global_position
		var end_pos = owner_object.grid_manager.tile_to_world(harvest_target_node.owner_object.current_coord)  - owner_object.global_position

		_debug_proxy.draw_line(start_pos,end_pos,path_color,1)
