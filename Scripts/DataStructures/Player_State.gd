extends Resource
class_name PlayerState


var current_controlValue:int = 0
var max_controlValue:int = 100
var current_essenceValue:int = 0

var resourceInventory:Dictionary[GameResource, int] = {}


func _init():
	resourceInventory.clear()


func modify_essence(amount:int):
	current_essenceValue += amount
	GameplayEvents.essence_value_changed.emit(current_essenceValue)

func add_resource(resource:GameResource, amount:int):
	if resource in resourceInventory:
		resourceInventory[resource] += amount
	else:
		resourceInventory[resource] = amount
		
	GameplayEvents.resource_inventory_changed.emit(resource, resourceInventory[resource])

func remove_resource(resource:GameResource, amount:int):
	if resource in resourceInventory:
		resourceInventory[resource] = max(0, resourceInventory[resource] - amount)
		GameplayEvents.resource_inventory_changed.emit(resource, resourceInventory[resource])	
	GameplayEvents.resource_inventory_changed.emit(resource, resourceInventory[resource])