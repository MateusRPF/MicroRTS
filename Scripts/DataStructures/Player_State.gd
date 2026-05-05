extends Resource
class_name PlayerState


var current_controlValue:int = 0
var max_controlValue:int = 100

var resource_inventory:Dictionary[GameResource, int] = {}


func _init():
	resource_inventory.clear()

func get_resource_value_by_name(rsc_name:String)->int:
	for rsc:GameResource in resource_inventory:
		if rsc.proper_name.to_lower() == rsc_name.to_lower():
			return resource_inventory[rsc]
	return 0


func get_resource_value(rsc:GameResource)->int:
	if resource_inventory.has(rsc):
		return resource_inventory[rsc]
	return 0

func add_resource(resource:GameResource, amount:int):

	if resource in resource_inventory:
		resource_inventory[resource] += amount
	else:
		resource_inventory[resource] = amount
		
	GameplayEvents.resource_inventory_changed.emit(resource, resource_inventory[resource])

func remove_resource(resource:GameResource, amount:int):
	if resource in resource_inventory:
		resource_inventory[resource] = max(0, resource_inventory[resource] - amount)
		GameplayEvents.resource_inventory_changed.emit(resource, resource_inventory[resource])	
	GameplayEvents.resource_inventory_changed.emit(resource, resource_inventory[resource])