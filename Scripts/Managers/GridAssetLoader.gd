extends Node
class_name GridAssetLoader

var actor_data_search_cache: Dictionary = {}

func find_actor_data_by_name(entry:String) -> ActorData:
	if entry == null or entry == "":
		return null
	if actor_data_search_cache.has(entry):
		return actor_data_search_cache[entry] as ActorData
	var result: ActorData = _search_actor_data_folder("res://Data/Actors", entry)
	actor_data_search_cache[entry] = result
	return result

func clear_cache() -> void:
	actor_data_search_cache.clear()

func _search_actor_data_folder(path:String, entry:String) -> ActorData:
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		print("GridAssetLoader: Failed to open directory: %s" % path)
		return null
	if dir.list_dir_begin() != OK:
		dir.list_dir_end()
		print("GridAssetLoader: Failed to list directory: %s" % path)
		return null
	var file_name:String = dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var child_path:String = "%s/%s" % [path, file_name]
		if dir.current_is_dir():
			var sub_result: ActorData = _search_actor_data_folder(child_path, entry)
			if sub_result:
				dir.list_dir_end()
				return sub_result
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var normalized_name:String = child_path.to_lower()
			var normalized_entry:String = entry.to_lower()
			if normalized_name.find(normalized_entry) != -1:
				var resource = ResourceLoader.load(child_path)
				if resource and resource is ActorData:
					dir.list_dir_end()
					return resource
		file_name = dir.get_next()
	dir.list_dir_end()
	return null
