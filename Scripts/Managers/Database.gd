extends Node

# The root folder where all your actor resources live
const ACTOR_DATA_PATH = "res://data/actors/"

# Cache to store loaded resources: { "Harbingers_Adept": ActorData_Object }
var _actor_cache: Dictionary = {}

func get_actor_data(actor_id: String) -> ActorData:
	# 1. Check if we've already found and loaded this
	if _actor_cache.has(actor_id):
		return _actor_cache[actor_id]
	
	# 2. Not in cache? We need to find it on disk.
	var found_resource = _find_actor_recursive(ACTOR_DATA_PATH, actor_id)
	
	if found_resource:
		_actor_cache[actor_id] = found_resource
		return found_resource
	
	push_error("Database: Could not find ActorData for '" + actor_id + "' in " + ACTOR_DATA_PATH)
	return null

# Recursive search through the filesystem
func _find_actor_recursive(path: String, target_name: String) -> ActorData:
	var dir = DirAccess.open(path)
	if not dir:
		push_error("Database: Failed to open path: " + path)
		return null

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if dir.current_is_dir():
			# It's a folder, dive deeper
			var result = _find_actor_recursive(path.path_join(file_name), target_name)
			if result:
				return result
		else:
			# It's a file. Check if it matches the 'sentence' and is a .tres
			if file_name.contains(target_name) and file_name.ends_with(".tres"):
				var res = load(path.path_join(file_name))
				if res is ActorData:
					return res
		
		file_name = dir.get_next()
	
	return null