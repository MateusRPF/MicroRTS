extends Node2D
class_name GridManager

const TILE_SIZE: int = 32
const HALF_TILE: float = TILE_SIZE / 2.0

var map_tiles: Dictionary[Vector2i, GameTile] = {}
var grid_size: Vector2i = Vector2i(10, 10)  # Default grid size
@export var grid_object_scene: PackedScene = null

var pathfinding: CAStarPathfinding = null



func _ready() -> void:
	pathfinding = CAStarPathfinding.new()
	add_child(pathfinding)
	LoadFromTileSet()
	initialize_spawnables(%Spawnables_Player, ActorData.Sides.PLAYER)
	initialize_spawnables(%Spawnables_Enemy, ActorData.Sides.ENEMY)
	initialize_spawnables(%Spawnables_SideNeutral, ActorData.Sides.NEUTRAL)


func LoadFromTileSet() -> void:
	var terrain:TileMapLayer = %Terrain
	if not terrain:
		DebugSettings.debug_print("GridManager", "Terrain node not found for tileset load")
		return

	var bounds = Rect2()  # Default empty rect
	bounds = terrain.get_used_rect()		


	var min_cell = Vector2i(int(bounds.position.x), int(bounds.position.y))
	var size = Vector2i(int(bounds.size.x), int(bounds.size.y))
	if size.x <= 0 or size.y <= 0:
		DebugSettings.debug_print("GridManager", "Terrain bounds are invalid: %s" % bounds)
		return

	grid_size = size
	map_tiles.clear()
	for x in range(min_cell.x, min_cell.x + grid_size.x):
		for y in range(min_cell.y, min_cell.y + grid_size.y):
			var coord = Vector2i(x, y)
			var tile = GameTile.new()
			tile.coord = coord
			var tile_data = terrain.get_cell_tile_data(coord)
			if (tile_data):
				var tile_type:GameTile.TileType = tile_data.get_custom_data("floor_wall_hole")
				tile.tile_type = tile_type
			map_tiles[coord] = tile

	DebugSettings.debug_print("GridManager", "Loaded tileset with grid size %s from Terrain bounds %s" % [grid_size, bounds])

func initialize_spawnables(tileset:TileMapLayer, side:ActorData.Sides) -> void:

	for tile in tileset.get_used_cells():
		var data = tileset.get_cell_tile_data(tile)
		var resourceName:String = data.get_custom_data("DataEntry")
		var actorData = Database.get_actor_data(resourceName)

		if (actorData):
			var newActor = grid_object_scene.instantiate() as GridObject
			add_child(newActor)
			newActor.Initialize(self,tile,actorData,side)


	tileset.clear()



func world_to_tile(world_position: Vector2) -> Vector2i:
	return Vector2i(
		int(floor((world_position.x ) / TILE_SIZE)),
		int(floor((world_position.y ) / TILE_SIZE))
	)

func tile_to_world(tile_position: Vector2i) -> Vector2:
	return Vector2(
		tile_position.x * TILE_SIZE + HALF_TILE,
		tile_position.y * TILE_SIZE + HALF_TILE
	)

func get_tiles_in_rect(rect: Rect2) -> Array[GameTile]:
	var tiles: Array[GameTile] = []
	for coord in get_tile_coords_in_rect(rect):
		if map_tiles.has(coord):
			tiles.append(map_tiles[coord])
	return tiles

func get_tile_coords_in_rect(rect: Rect2) -> Array[Vector2i]:
	var min_point: Vector2 = rect.position
	var max_point: Vector2 = rect.position + rect.size
	var left: float = min(min_point.x, max_point.x)
	var top: float = min(min_point.y, max_point.y)
	var right: float = max(min_point.x, max_point.x)
	var bottom: float = max(min_point.y, max_point.y)

	var min_tile: Vector2i = world_to_tile(Vector2(left, top))
	var max_tile: Vector2i = world_to_tile(Vector2(right, bottom))

	var coords: Array[Vector2i] = []
	for x in range(min_tile.x, max_tile.x + 1):
		for y in range(min_tile.y, max_tile.y + 1):
			coords.append(Vector2i(x, y))

	return coords

func UpdatePosition(object: GridObject, newCoord: Vector2i) -> void:
	# Check if destination is valid
	var covered_coords = object.get_covered_coords()
	for coord in covered_coords:
		if not map_tiles.has(coord):
			push_error("Attempting to move to invalid tile coordinate: %s" % coord)
			return  # Out of bounds
		if map_tiles[coord].is_occupied && map_tiles[coord].occupant != object:
			push_error("Attempting to move to occupied tile coordinate: %s" % coord)
			return  # Collision

	# Unregister from old position
	for coord in object.get_covered_coords():
		map_tiles[coord].is_occupied = false
		map_tiles[coord].occupant = null

	# Register at new position
	object.current_coord = newCoord
	for coord in object.get_covered_coords():
		map_tiles[coord].is_occupied = true
		map_tiles[coord].occupant = object

func ClearPosition(object: GridObject) -> void:
	for coord in object.get_covered_coords():
		map_tiles[coord].is_occupied = false
		map_tiles[coord].occupant = null


func find_path(start: Vector2i, end: Vector2i, moving_unit: GridObject = null) -> Array[Vector2i]:
	if not pathfinding:
		push_error("GridManager: Pathfinding not initialized")
		return []
	return pathfinding.find_path(start, end, moving_unit)


func get_objects_in_radius(center: Vector2i, radius: int, filter_script:Script = null) -> Array[GridObject]:
	var objects: Array[GridObject] = []
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var coord = Vector2i(x, y)
			if map_tiles.has(coord) and map_tiles[coord].is_occupied:
				if (map_tiles[coord].occupant):
					if (filter_script):
						if not (map_tiles[coord].occupant.get_component(filter_script)):
							continue
					objects.append(map_tiles[coord].occupant)
	return objects


func find_closest_reachable_component(origin: GridObject, search_radius: int, component_script: Script) -> GridObjectComponent:
	var start: Vector2i = origin.current_coord
	var queue: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: null}
	var distance_map: Dictionary = {start: 0}

	while queue.size() > 0:
		var current = queue.pop_front()
		var current_dist = distance_map[current]
		
		if current_dist >= search_radius:
			continue

		# 1. THE LOOK-AHEAD: Check ALL neighbors for the component (even blocked ones)
		# We use a simple directions array here to avoid the 'walkable' filter
		for direction in pathfinding.DIRECTIONS:
			var neighbor = current + direction
			var tile = map_tiles.get(neighbor)
			
			if tile and tile.is_occupied and tile.occupant:
				var res_component = tile.occupant.get_component(component_script)
				if res_component:
					# FOUND IT! Return the component as requested.
					return res_component

		# 2. THE EXPANSION: Only add WALKABLE neighbors to the queue to keep the ripple going
		for neighbor in pathfinding._get_walkable_neighbors(current, origin):
			if not came_from.has(neighbor):
				came_from[neighbor] = current
				distance_map[neighbor] = current_dist + 1
				queue.append(neighbor)
                
	return null

func get_coords_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var coord = Vector2i(x, y)
			if map_tiles.has(coord):
				coords.append(coord)
	return coords

func get_tiles_in_radius(center: Vector2i, radius: float) -> Array[GameTile]:
	var tiles: Array[GameTile] = []
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var coord = Vector2i(x, y)
			if map_tiles.has(coord):
				tiles.append(map_tiles[coord])
	return tiles

func calculate_distance(coord1: Vector2i, coord2: Vector2i) -> float:
	var distance = Vector2(coord1).distance_to(coord2)
	return distance

func calculate_distance_sqr(coord1: Vector2i, coord2: Vector2i) -> float:
	var distance = Vector2(coord1).distance_squared_to(coord2)
	return distance




func get_interaction_positions(target: GridObject,tolerableDistance:float = 1.5) -> Array[Vector2i]:
	var possible_positions:Array[Vector2i] = []
	for occupied_tile in target.get_covered_coords():
		var tiles_in_range = get_tiles_in_radius(occupied_tile, tolerableDistance)
		for tile in tiles_in_range:
			if tile.walkable:
				if possible_positions.has(tile.coord) == false:
					possible_positions.append(tile.coord)
	return possible_positions
