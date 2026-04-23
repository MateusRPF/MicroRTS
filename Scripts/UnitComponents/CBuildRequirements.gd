extends GridObjectComponent
class_name CBuildRequirements

var required: Dictionary[GameResource, int] = {}
var delivered: Dictionary[GameResource, int] = {}


func init_requirements(costs: Dictionary[GameResource, int]) -> void:
	required = costs.duplicate()
	delivered.clear()
	for res in required:
		delivered[res] = 0


func remaining_need(res: GameResource) -> int:
	if not required.has(res):
		return 0
	return max(0, required[res] - delivered.get(res, 0))


func total_remaining_need() -> int:
	var sum: int = 0
	for res in required:
		sum += remaining_need(res)
	return sum


func has_all_deposited() -> bool:
	return total_remaining_need() == 0


func needed_resources() -> Array[GameResource]:
	var list: Array[GameResource] = []
	for res in required:
		if remaining_need(res) > 0:
			list.append(res)
	return list


func deposit_from_unit(unit: GridObject, res: GameResource) -> int:
	var inventory: CInventory = unit.get_component(CInventory)
	if not inventory:
		return 0
	var need: int = remaining_need(res)
	if need <= 0:
		return 0
	var available: int = inventory.get_stored_qty(res)
	var amount: int = min(need, available)
	if amount <= 0:
		return 0
	var withdrawn: int = inventory.withdrawal(res, amount)
	if withdrawn <= 0:
		return 0
	delivered[res] = delivered.get(res, 0) + withdrawn
	return withdrawn
