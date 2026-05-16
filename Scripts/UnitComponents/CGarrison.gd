extends GridObjectComponent
class_name CGarrison

var perimeter: Array[Vector2i]
var garrison_slots: Dictionary[GarrisonSlot, GridObject]
var slot_configurations: Array[GarrisonSlot]

# Track slots whose units are currently out on a task
var deployed_slots: Array[GarrisonSlot] = []

func initialize_component(actor: GridObject) -> void:
	garrison_slots.clear()
	deployed_slots.clear()
	super.initialize_component(actor)
	perimeter = owner_object.get_perimeter()
	for slot in slot_configurations:
		garrison_slots[slot] = null

func can_enter(actor: GridObject) -> bool:
	# Check if this actor is already bound to a deployed slot returning home
	var existing_slot = get_slot_for_actor(actor)
	if existing_slot and existing_slot in deployed_slots:
		return true

	for slot in garrison_slots:
		if slot_accepts_actor(slot, actor):
			return true
	return false

func slot_accepts_actor(slot: GarrisonSlot, actor: GridObject) -> bool:
	if garrison_slots[slot] != null:
		return false
	if slot.accepts_any:
		return true 
	if actor.data.tags.has(slot.accepted_tag):
		return true
	return false

func get_slot_for_actor(actor: GridObject) -> GarrisonSlot:
	for slot in garrison_slots:
		if garrison_slots[slot] == actor:
			return slot
	return null

func enter_garrison(actor: GridObject):
	if can_enter(actor):
		var existing_slot = get_slot_for_actor(actor)
		
		# Case A: Returning from a deployment mission
		if existing_slot and existing_slot in deployed_slots:
			deployed_slots.erase(existing_slot)
			actor.exit_grid()
			print("Actor returned to assigned slot from mission")
			return

		# Case B: Brand new assignment
		for slot in garrison_slots:
			if slot_accepts_actor(slot, actor):
				garrison_slots[slot] = actor
				actor.exit_grid()
				print("Actor entered garrison")
				break

func expulse_all():
	deployed_slots.clear()
	for slot in garrison_slots:
		expulse_from_garrison(slot)

func expulse_from_garrison(slot: GarrisonSlot) -> void:

	var actor: GridObject = garrison_slots[slot]

	if not actor:
		return

	var placement: Vector2i = _find_valid_perimeter_tile()
	if placement != Vector2i(-1, -1):
		actor.reenter_grid(placement)
		garrison_slots[slot] = null
		deployed_slots.erase(slot)
		print("Actor exited garrison completely")
	else:
		push_error("No placement!")

func deploy_worker() -> GridObject:
	for slot in garrison_slots:
		var actor = garrison_slots[slot]
		# Find a worker who is present and not already deployed
		if actor and not slot in deployed_slots:
			var placement = _find_valid_perimeter_tile()
			if placement != Vector2i(-1, -1):
				deployed_slots.append(slot)
				actor.reenter_grid(placement)
				print("Worker deployed on mission, slot reserved")
				return actor
	return null

func _find_valid_perimeter_tile() -> Vector2i:
	for coord in perimeter:
		var tile: GameTile = owner_object.grid_manager.map_tiles[coord]
		if tile.tile_type != GameTile.TileType.FLOOR:
			continue
		if tile.has_unit_occupant:
			continue
		return coord
	return Vector2i(-1, -1)