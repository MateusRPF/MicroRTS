extends Node2D
class_name GridManager

const TILE_SIZE: int = 32
const HALF_TILE: float = TILE_SIZE / 2.0

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
]

const MOVER_WEIGHT: float = 10.0

var map_tiles: Dictionary[Vector2i, GameTile] = {}
var grid_size: Vector2i = Vector2i(10, 10)  # Default grid size
@export var spawn_scenes: Dictionary[String, PackedScene]

var astar_grid: AStarGrid2D = null



func _ready() -> void:
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

	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(min_cell, grid_size)
	astar_grid.cell_size = Vector2(TILE_SIZE, TILE_SIZE)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.update()
	for coord in map_tiles:
		_refresh_astar_for(coord, map_tiles[coord])

	DebugSettings.debug_print("GridManager", "Loaded tileset with grid size %s from Terrain bounds %s" % [grid_size, bounds])

func _refresh_astar_for(coord: Vector2i, tile: GameTile) -> void:
	if not astar_grid:
		return
	if not astar_grid.region.has_point(coord):
		return
	if tile.tile_type != GameTile.TileType.FLOOR:
		astar_grid.set_point_solid(coord, true)
		return
	if tile.is_occupied and tile.occupant:
		if tile.occupant.get_component(CMover):
			astar_grid.set_point_solid(coord, false)
			astar_grid.set_point_weight_scale(coord, MOVER_WEIGHT)
		else:
			astar_grid.set_point_solid(coord, true)
	else:
		astar_grid.set_point_solid(coord, false)
		astar_grid.set_point_weight_scale(coord, 1.0)

func initialize_spawnables(tileset:TileMapLayer, side:ActorData.Sides) -> void:

	for tile in tileset.get_used_cells():
		var data = tileset.get_cell_tile_data(tile)
		var resourceName:String = data.get_custom_data("DataEntry")
		if not spawn_scenes.has(resourceName):
			push_warning("GridManager: no scene mapped for '%s'" % resourceName)
			continue
		var newActor = spawn_scenes[resourceName].instantiate() as GridObject
		add_child(newActor)
		newActor.Initialize(self, tile, side)

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
	var old_coords: Array[Vector2i] = object.get_covered_coords()

	object.current_coord = newCoord
	var new_coords: Array[Vector2i] = object.get_covered_coords()

	for coord in new_coords:
		if not map_tiles.has(coord):
			push_error("Attempting to move to invalid tile coordinate: %s" % coord)
			return
		if map_tiles[coord].is_occupied && map_tiles[coord].occupant != object:
			push_error("Attempting to move to occupied tile coordinate: %s" % coord)
			return

	for coord in old_coords:
		map_tiles[coord].is_occupied = false
		map_tiles[coord].occupant = null

	for coord in new_coords:
		map_tiles[coord].is_occupied = true
		map_tiles[coord].occupant = object

	for coord in old_coords:
		_refresh_astar_for(coord, map_tiles[coord])
	for coord in new_coords:
		_refresh_astar_for(coord, map_tiles[coord])

func ClearPosition(object: GridObject) -> void:
	var coords: Array[Vector2i] = object.get_covered_coords()
	for coord in coords:
		map_tiles[coord].is_occupied = false
		map_tiles[coord].occupant = null
	for coord in coords:
		_refresh_astar_for(coord, map_tiles[coord])


func get_footprint_coords(origin: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for x in range(size.x):
		for y in range(size.y):
			coords.append(Vector2i(origin.x + x, origin.y - y))
	return coords


func can_place_footprint(origin: Vector2i, size: Vector2i) -> bool:
	for coord in get_footprint_coords(origin, size):
		if not map_tiles.has(coord):
			return false
		var tile: GameTile = map_tiles[coord]
		if tile.is_occupied:
			return false
		if tile.tile_type != GameTile.TileType.FLOOR:
			return false
	return true


func find_path(start: Vector2i, end: Vector2i, moving_unit: GridObject = null) -> Array[Vector2i]:
	if not astar_grid:
		push_error("GridManager: AStarGrid2D not initialized")
		return []
	if start == end:
		return []
	if not astar_grid.region.has_point(start) or not astar_grid.region.has_point(end):
		return []

	var end_was_solid: bool = astar_grid.is_point_solid(end)
	if end_was_solid:
		astar_grid.set_point_solid(end, false)

	var raw_path: Array[Vector2i] = astar_grid.get_id_path(start, end, true)

	if end_was_solid:
		astar_grid.set_point_solid(end, true)

	if raw_path.size() > 0 and raw_path[0] == start:
		raw_path.remove_at(0)

	if raw_path.size() > 0:
		var last_pos: Vector2i = raw_path[raw_path.size() - 1]
		var dist: int = abs(start.x - last_pos.x) + abs(start.y - last_pos.y)
		if dist > 1 and map_tiles.has(last_pos):
			var tile: GameTile = map_tiles[last_pos]
			if tile.is_occupied and tile.occupant != moving_unit:
				raw_path.pop_back()

	return raw_path


func dijkstra_to_any(start: Vector2i, goals: Array[Vector2i], mover: GridObject) -> Dictionary:
	if goals.is_empty() or not map_tiles.has(start):
		return {}

	var goal_set: Dictionary = {}
	for g in goals:
		goal_set[g] = true

	if goal_set.has(start):
		return {"best_goal": start, "path": [] as Array[Vector2i]}

	var dist: Dictionary = {start: 0.0}
	var came_from: Dictionary = {}
	var open: Array = [[0.0, start]]

	while open.size() > 0:
		var best_idx: int = 0
		var best_cost: float = open[0][0]
		for i in range(1, open.size()):
			if open[i][0] < best_cost:
				best_cost = open[i][0]
				best_idx = i
		var entry = open[best_idx]
		open.remove_at(best_idx)

		var current: Vector2i = entry[1]
		var current_cost: float = entry[0]

		if current_cost > float(dist.get(current, INF)):
			continue

		if goal_set.has(current):
			var path: Array[Vector2i] = []
			var c: Vector2i = current
			while came_from.has(c):
				path.append(c)
				c = came_from[c]
			path.reverse()
			return {"best_goal": current, "path": path}

		for direction in DIRECTIONS:
			var n: Vector2i = current + direction
			if not map_tiles.has(n):
				continue

			var tile: GameTile = map_tiles[n]
			if tile.tile_type != GameTile.TileType.FLOOR:
				continue

			var is_goal: bool = goal_set.has(n)
			var weight: float = 1.0

			if tile.is_occupied and tile.occupant and tile.occupant != mover:
				if tile.occupant.get_component(CMover):
					weight = MOVER_WEIGHT
				elif not is_goal:
					continue

			var step_cost: float = 1.414 if (direction.x != 0 and direction.y != 0) else 1.0
			var new_cost: float = current_cost + step_cost * weight
			if new_cost < float(dist.get(n, INF)):
				dist[n] = new_cost
				came_from[n] = current
				open.append([new_cost, n])

	return {}


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
	var visited: Dictionary = {start: true}
	var distance_map: Dictionary = {start: 0}

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()
		var current_dist: int = distance_map[current]

		if current_dist >= search_radius:
			continue

		for direction in DIRECTIONS:
			var neighbor: Vector2i = current + direction
			var tile: GameTile = map_tiles.get(neighbor)
			if tile and tile.is_occupied and tile.occupant:
				var res_component = tile.occupant.get_component(component_script)
				if res_component:
					return res_component

		for direction in DIRECTIONS:
			var neighbor: Vector2i = current + direction
			if visited.has(neighbor):
				continue
			var tile: GameTile = map_tiles.get(neighbor)
			if not tile or tile.tile_type != GameTile.TileType.FLOOR:
				continue
			if tile.is_occupied and tile.occupant and tile.occupant != origin:
				if not tile.occupant.get_component(CMover):
					continue
			visited[neighbor] = true
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




func get_interaction_positions(target: GridObject, tolerableDistance: float = 1.5, include_transient_occupants: bool = true) -> Array[Vector2i]:
	var possible_positions: Array[Vector2i] = []
	for occupied_tile in target.get_covered_coords():
		var tiles_in_range = get_tiles_in_radius(occupied_tile, tolerableDistance)
		for tile in tiles_in_range:
			if tile.tile_type != GameTile.TileType.FLOOR:
				continue
			var qualifies: bool = false
			if not tile.is_occupied:
				qualifies = true
			elif include_transient_occupants and tile.occupant and tile.occupant != target:
				if tile.occupant.get_component(CMover):
					qualifies = true
			if qualifies and not possible_positions.has(tile.coord):
				possible_positions.append(tile.coord)
	return possible_positions
