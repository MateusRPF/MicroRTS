extends Node
class_name CAStarPathfinding

class PathNode:
	var coord: Vector2i
	var parent: PathNode = null
	var g_score: float = 0.0
	var h_score: float = 0.0
	var f_score: float = 0.0

	func _init(pos: Vector2i, p: PathNode = null, g: float = 0.0, h: float = 0.0) -> void:
		coord = pos
		parent = p
		g_score = g
		h_score = h
		f_score = g + h

# OPTIMIZATION 1: Pre-allocated constant array
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
]

var grid_manager: GridManager = null

func _ready() -> void:
	grid_manager = get_parent()
	if not (grid_manager is GridManager):
		push_error("CAStarPathfinding must be a child of GridManager")

func find_path(start: Vector2i, end: Vector2i, moving_unit: GridObject = null) -> Array[Vector2i]:
	if not grid_manager: return []
	if start == end: return []

	var open_set: Array[PathNode] = []
	var open_set_map: Dictionary = {} # OPTIMIZATION 2: Fast lookups
	var closed_set: Dictionary = {}

	var start_node = PathNode.new(start, null, 0.0, float(start.distance_to(end)))
	open_set.append(start_node)
	open_set_map[start] = start_node

	while open_set.size() > 0:
		# OPTIMIZATION 3: Leaner lowest f-score search
		var current_index = 0
		var lowest_f = open_set[0].f_score
		for i in range(1, open_set.size()):
			if open_set[i].f_score < lowest_f:
				lowest_f = open_set[i].f_score
				current_index = i

		var current = open_set[current_index]

		if current.coord == end:
			var path: Array[Vector2i] = _reconstruct_path(current)
			if path.size() > 0:
				var last_pos = path.back()
				var dist = abs(start.x - last_pos.x) + abs(start.y - last_pos.y)
				if dist > 1:
					if grid_manager.map_tiles.has(last_pos):
						var tile = grid_manager.map_tiles[last_pos]
						if tile.is_occupied and tile.occupant != moving_unit:
							path.pop_back() # Fast removal from end
			return path

		# OPTIMIZATION 4: O(1) Array Removal (Swap and Pop)
		var last_idx = open_set.size() - 1
		if current_index != last_idx:
			open_set[current_index] = open_set[last_idx]
		open_set.pop_back()
		open_set_map.erase(current.coord)

		closed_set[current.coord] = true

		for neighbor_coord in _get_walkable_neighbors(current.coord, moving_unit):
			if neighbor_coord in closed_set:
				continue

			var is_diagonal = abs(current.coord.x - neighbor_coord.x) == 1 and abs(current.coord.y - neighbor_coord.y) == 1
			var move_cost = 1.414 if is_diagonal else 1.0
			
			var extra_weight = 0.0
			var tile = grid_manager.map_tiles[neighbor_coord]
			
			if tile.is_occupied and tile.occupant and tile.occupant != moving_unit and tile.occupant.get_component(CMover).is_moving():
				extra_weight = 5.0 

			var tentative_g_score = current.g_score + move_cost + extra_weight

			# OPTIMIZATION 5: Dictionary lookup instead of loop
			if open_set_map.has(neighbor_coord):
				var open_node = open_set_map[neighbor_coord]
				if tentative_g_score < open_node.g_score:
					open_node.parent = current
					open_node.g_score = tentative_g_score
					open_node.f_score = tentative_g_score + float(neighbor_coord.distance_to(end))
			else:
				var neighbor_node = PathNode.new(neighbor_coord, current, tentative_g_score, float(neighbor_coord.distance_to(end)))
				open_set.append(neighbor_node)
				open_set_map[neighbor_coord] = neighbor_node

	return []

func _get_walkable_neighbors(coord: Vector2i, mover: GridObject = null) -> Array:
	var neighbors: Array = []
	
	for direction in DIRECTIONS:
		var neighbor = coord + direction
		if not grid_manager.map_tiles.has(neighbor):
			continue

		var tile: GameTile = grid_manager.map_tiles[neighbor]
		if tile.tile_type == GameTile.TileType.FLOOR:
			if tile.is_occupied && tile.occupant:
				var occupant = tile.occupant
				var mover_comp = occupant.get_component(CMover)
				if not mover_comp:
					continue
				else: 
					if mover_comp.is_moving(): 
						if occupant.randomizedPriority >= mover.randomizedPriority:
							continue
					else:
						continue
			neighbors.append(neighbor)

	return neighbors

func _reconstruct_path(end_node: PathNode) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current = end_node
	while current.parent != null:
		path.append(current.coord) # OPTIMIZATION 6: Append then reverse
		current = current.parent
	path.reverse()
	return path

func _reconstruct_path_from_map(came_from: Dictionary, end: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current = end
	
	# We loop until we reach the start node
	# (The start node's value in came_from should be null or an invalid coordinate)
	while current != null and came_from.has(current):
		path.append(current)
		current = came_from[current]
	
	# Since we worked backward from the tree to the unit, we flip it
	path.reverse()
	
	# OPTIONAL: Remove the first element if it's the tile the unit is already standing on
	# if not path.is_empty():
	#     path.remove_at(0)
	
	return path