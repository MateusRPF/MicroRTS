extends GridObjectComponent
class_name CCarryVisual

const ICON_SIZE: float = 14.0
const ICON_SPACING: float = 14.0

var inventory: CInventory = null
var _pivot: Node2D = null


func initialize_component(actor: GridObject) -> void:
	super.initialize_component(actor)
	inventory = actor.get_component(CInventory)
	_pivot = actor.get_node_or_null("ViewPivot/CarryPivot")
	if inventory:
		inventory.inventory_changed.connect(_refresh)
	_refresh()


func _refresh(_inv: CInventory = null) -> void:
	if not _pivot:
		return
	for child in _pivot.get_children():
		child.queue_free()
	if not inventory:
		return
	var carried: Array[GameResource] = []
	for res in inventory._storage:
		if inventory._storage[res] > 0:
			carried.append(res)
	var count: int = carried.size()
	for i in range(count):
		var sprite := Sprite2D.new()
		sprite.texture = carried[i].icon
		var tex_size: Vector2 = sprite.texture.get_size()
		var longest: float = max(tex_size.x, tex_size.y)
		if longest > 0.0:
			var s: float = ICON_SIZE / longest
			sprite.scale = Vector2(s, s)
		sprite.position = Vector2((float(i) - (float(count) - 1.0) / 2.0) * ICON_SPACING, 0)
		_pivot.add_child(sprite)
