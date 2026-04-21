extends GridObjectComponent
class_name CResourceNode


var resource: GameResource
var initial_amount: int = 10
var destroy_on_deplete: bool = true

var inventory:CInventory

const SHAKE_MAGNITUDE: float = 3.0
const SHAKE_DURATION: float = 0.26

var _shake_tween: Tween = null

func initialize_component(actor: GridObject) -> void:
	super.initialize_component(actor)
	inventory = actor.get_component(CInventory)

	inventory.deposit(resource,initial_amount)

func grant_resource(amount_requested: int)->int:
	var available = inventory.get_stored_qty(resource)
	var granted = min(available, amount_requested)

	inventory.withdrawal(resource,granted)
	if available - granted <=0 and destroy_on_deplete:
		deplete()

	return granted


func deplete():
	owner_object.destroy_object()


func shake() -> void:
	var sprite: Node2D = owner_object.get_node_or_null("%Sprite")
	if not sprite:
		return
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
	sprite.position.x = 0
	_shake_tween = sprite.create_tween()
	var step: float = SHAKE_DURATION * 0.25
	_shake_tween.tween_property(sprite, "position:x", SHAKE_MAGNITUDE, step)
	_shake_tween.tween_property(sprite, "position:x", -SHAKE_MAGNITUDE, step)
	_shake_tween.tween_property(sprite, "position:x", SHAKE_MAGNITUDE * 0.5, step)
	_shake_tween.tween_property(sprite, "position:x", 0.0, step)
