@tool
extends Resource
class_name Registry

@export_tool_button("Fetch") var fetch_datas = _populate_actors_from_folder.call_deferred

@export_group("Actors")
@export var actor_data_map: Dictionary

@export_group("VFX")
@export var vfxRegistry:Dictionary[String, PackedScene]

## Intelligences
var helpless_wander: Intelligence_HelplessWander = Intelligence_HelplessWander.new()
var predator: Intelligence_Predator = Intelligence_Predator.new()
var player_soldier: Intelligence_PlayerSoldier = Intelligence_PlayerSoldier.new()
var intels:Dictionary[IntelligenceID,IntelligenceBase] = {
	IntelligenceID.HELPLESS_WANDER: helpless_wander,
	IntelligenceID.PREDATOR: predator,
	# IntelligenceID.SEEK_AND_DESTROY: SEEK_AND_DESTROY,
	# IntelligenceID.WARDEN: WARDEN,
	# IntelligenceID.PLAYER_WORKER: PLAYER_WORKER,
	IntelligenceID.PLAYER_SOLDIER: player_soldier
	# IntelligenceID.HARVEST_CORPSE: HARVEST_CORPSE
}

enum IntelligenceID{
	HELPLESS_WANDER,
	PREDATOR,
	# SEEK_AND_DESTROY
	# WARDEN
	# PLAYER_WORKER
	PLAYER_SOLDIER
}

func _populate_actors_from_folder() -> void:
	if not Engine.is_editor_hint():
		return
		
	print("--- Starting ActorData Registry Scan ---")
	actor_data_map.clear()
	
	var files: Array[String] = _find_resources_recursive("res://Data/Actors/", ".tres")
	var added_count: int = 0
	
	for file_path in files:
		# Use SAFE cache mode to grab the raw disk file
		var resource = load(file_path)
		# Validation check still works perfectly fine here
		if resource and resource.get_class() == "Resource" and resource.script != null:
			if resource.is_class("ActorData") or resource.get_script().get_instance_base_type() == "Resource":
				# A safer fallback check to verify class names without relying strictly on the 'is' keyword during reload
				var script_path: String = resource.get_script().resource_path
				if script_path.ends_with("ActorData.gd"):
					var file_name: String = file_path.get_file()
					var key: String = _extract_last_word(file_name)
					
					if not key.is_empty():
						actor_data_map[key] = resource
						print("Registered: ['", key, "'] -> ", file_path)
						added_count += 1
			
	notify_property_list_changed()
	emit_changed() 
	print("--- Scan Complete. Successfully registered ", added_count, " Actors. ---")

func _find_resources_recursive(path: String, extension: String) -> Array[String]:
	var results: Array[String] = []
	var dir = DirAccess.open(path)
	if not dir: return results
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				results.append_array(_find_resources_recursive(path.path_join(file_name), extension))
		else:
			if file_name.ends_with(extension):
				results.append(path.path_join(file_name))
		file_name = dir.get_next()
	return results

func _extract_last_word(filename: String) -> String:
	var base_name: String = filename.get_basename()
	base_name = base_name.replace(".", "_")
	var words: PackedStringArray = base_name.split("_", false)
	if words.size() > 0:
		return words[words.size() - 1] 
	return ""