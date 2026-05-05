extends Node
class_name GridVisibility

var fog_of_war: TextureRect = null
var fog_of_war_texture: ImageTexture = ImageTexture.new()
var grid_size: Vector2i = Vector2i.ZERO
var grid_origin: Vector2i = Vector2i.ZERO
var tile_size: int = 32

const VIEW_RANGE: int = 8
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
]

var ever_seen_tiles: Dictionary = {}
var current_visible_tiles: Dictionary = {}

func initialize(fog_node: TextureRect, grid_size_in: Vector2i, grid_origin_in: Vector2i, tile_size_in: int) -> void:
	fog_of_war = fog_node
	grid_size = grid_size_in
	grid_origin = grid_origin_in
	tile_size = tile_size_in
	if fog_of_war:
		fog_of_war.texture = fog_of_war_texture
		var shader_material = fog_of_war.material
		shader_material.set_shader_parameter("grid_size", Vector2(grid_size.x, grid_size.y))
		update_fog_mask_texture(null)

func refresh(objects:Array, map_tiles:Dictionary, player_state: PlayerState) -> void:
	if not fog_of_war or grid_size.x <= 0 or grid_size.y <= 0 or not player_state:
		return
	var visible_coords: Dictionary = {}
	for obj in objects:
		if obj is GridObject and obj.player_state == player_state:
			_mark_viewed_tiles_for_object(obj, map_tiles, visible_coords)
	if not ever_seen_tiles.has(player_state):
		ever_seen_tiles[player_state] = {}
	var seen: Dictionary = ever_seen_tiles[player_state]
	for coord in visible_coords:
		seen[coord] = true
	current_visible_tiles[player_state] = visible_coords
	update_fog_mask_texture(player_state)
	for obj in objects:
		if obj is GridObject:
			obj.set_fog_visible(_is_object_visible_to_current_player(obj, player_state))

func get_visible_tiles(player_state: PlayerState) -> Dictionary:
	return current_visible_tiles.get(player_state, {})

func get_previously_visible_tiles(player_state: PlayerState) -> Dictionary:
	var current: Dictionary = current_visible_tiles.get(player_state, {})
	var seen: Dictionary = ever_seen_tiles.get(player_state, {})
	var previous: Dictionary = {}
	for coord in seen:
		if not current.has(coord):
			previous[coord] = true
	return previous

func get_invisible_tiles(player_state: PlayerState) -> Dictionary:
	var seen: Dictionary = ever_seen_tiles.get(player_state, {})
	var invisible: Dictionary = {}
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var coord := grid_origin + Vector2i(x, y)
			if not seen.has(coord):
				invisible[coord] = true
	return invisible

func _mark_viewed_tiles_for_object(object: GridObject, map_tiles:Dictionary, out_visible: Dictionary) -> void:
	if not object or not object.player_state:
		return
	var visited: Dictionary = {}
	var queue: Array = []
	for origin in object.get_covered_coords():
		if not map_tiles.has(origin):
			continue
		queue.append([origin, 0])
		visited[origin] = true

	while queue.size() > 0:
		var entry = queue.pop_front()
		var coord: Vector2i = entry[0]
		var distance: int = entry[1]
		if distance > VIEW_RANGE:
			continue
		if map_tiles.has(coord):
			out_visible[coord] = true
		var tile: GameTile = map_tiles[coord]
		if tile.tile_type == GameTile.TileType.WALL:
			continue
		if  tile.unit_occupant and tile.unit_occupant != object:
			if (tile.unit_occupant.data.blocks_view):
				continue
			if (distance > VIEW_RANGE -5):
				continue
		for dir in DIRECTIONS:
			var neighbor: Vector2i = coord + dir
			if visited.has(neighbor):
				continue
			if distance + 1 > VIEW_RANGE:
				continue
			if not map_tiles.has(neighbor):
				continue
			visited[neighbor] = true
			queue.append([neighbor, distance + 1])

func _is_object_visible_to_current_player(object: GridObject, player_state: PlayerState) -> bool:
	if not object or not player_state:
		return true
	if not current_visible_tiles.has(player_state):
		return false
	for coord in object.get_covered_coords():
		if current_visible_tiles[player_state].has(coord):
			return true
	return false

func update_fog_mask_texture(player_state: PlayerState) -> void:
	if not fog_of_war or grid_size.x <= 0 or grid_size.y <= 0 or not player_state:
		return
	var image:Image = Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_RGBA8)
	var current: Dictionary = current_visible_tiles.get(player_state, {})
	var seen: Dictionary = ever_seen_tiles.get(player_state, {})
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var coord := grid_origin + Vector2i(x, y)
			var value:Color = Color(0, 0, 0, 1)
			if current.has(coord):
				value = Color(1, 0, 0, 1)
			elif seen.has(coord):
				value = Color(0.3, 0, 0, 1)
			image.set_pixel(x, y, value)

	fog_of_war_texture = ImageTexture.create_from_image(image)

	fog_of_war.texture = fog_of_war_texture
	var mat := fog_of_war.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("grid_size", Vector2(grid_size.x, grid_size.y))
