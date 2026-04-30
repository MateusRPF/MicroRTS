extends GridObjectComponent
class_name CBuildRequirements

const REQUIREMENT_ICON_SCENE: PackedScene = preload("res://Prefabs/Widgets/Widget_RequirementIcon.tscn")

var required: Dictionary[GameResource, int] = {}
var delivered: Dictionary[GameResource, int] = {}
var _icons: Dictionary[GameResource, Widget_RequirementIcon] = {}


func init_requirements(costs: Dictionary[GameResource, int]) -> void:
	required = costs.duplicate()
	delivered.clear()
	for res in required:
		delivered[res] = 0
	_build_icons()


func _build_icons() -> void:
	var view: HBoxContainer = owner_object.get_node("%RequirementsView") as HBoxContainer
	for child in view.get_children():
		child.queue_free()
	_icons.clear()
	for res in required:
		var icon: Widget_RequirementIcon = REQUIREMENT_ICON_SCENE.instantiate()
		view.add_child(icon)
		icon.set_resource(res, remaining_need(res))
		_icons[res] = icon
	view.visible = not has_all_deposited()
	_center_view(view)


func _center_view(view: HBoxContainer) -> void:
	view.reset_size()
	var building_center_x: float = GridManager.TILE_SIZE * (owner_object.size.x - 1) * 0.5
	var building_center_y: float = -GridManager.TILE_SIZE * (owner_object.size.y - 1) * 0.5
	view.position = Vector2(building_center_x - view.size.x * 0.5, building_center_y - view.size.y * 0.5)


func _refresh_icons() -> void:
	for res in _icons:
		_icons[res].set_amount(remaining_need(res))
	var view: HBoxContainer = owner_object.get_node("%RequirementsView") as HBoxContainer
	view.visible = not has_all_deposited()
	_center_view(view)


func _exit_tree() -> void:
	var view: HBoxContainer = owner_object.get_node("%RequirementsView") as HBoxContainer
	for child in view.get_children():
		child.queue_free()
	view.visible = false


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
	_refresh_icons()
	return withdrawn
