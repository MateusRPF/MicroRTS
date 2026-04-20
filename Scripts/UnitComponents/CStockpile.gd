extends GridObjectComponent
class_name CStockpile


@export var accepted_resources:Array[GameResource]

var inventory:CInventory

func initialize_component(actor: GridObject) -> void:
	super.initialize_component(actor)
	inventory =  actor.get_component(CInventory)



func can_deposit_resource(harvester: CHarvester) -> bool:
	var is_in_range = is_harvester_in_range(harvester) 
	return is_in_range


func deposit_resource(_harvester:CHarvester, gameResource:GameResource, value:int) -> bool:
	if (accepted_resources.has(gameResource)):
		inventory.deposit(gameResource,value)
		return true
	return false
	

func is_harvester_in_range(harvester: CHarvester) -> bool:
	if not owner_object or not owner_object.grid_manager:
		push_error("CStockpile: Cannot check harvester range without grid_manager")
		return false
	for coord in calculate_deliverable_tiles():
		if harvester.owner_object.current_coord == coord:
			return true
	return false

func calculate_deliverable_tiles() -> Array[Vector2i]:
	var deliverable_tiles: Array[Vector2i] = []
	for covered_tile in owner_object.get_covered_coords():
		for coord in owner_object.grid_manager.get_coords_in_radius(covered_tile, 1):
			if deliverable_tiles.has(coord) == false:
				deliverable_tiles.append(coord)
	return deliverable_tiles
