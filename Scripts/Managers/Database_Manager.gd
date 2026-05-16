extends Node


var registry:Registry

func get_actor_data(id: String) -> ActorData:
	return registry.actor_data_map.get(id, null)


func _ready() -> void:
	GameplayEvents.VFX_requested.connect(_on_vfx_requested)
	registry = load("res://Data/MasterRegistry.tres")

func _on_vfx_requested(vfx_name:String, coord_origin:Vector2i,coord_target:Vector2i) -> void:
	var grid:GridManager = GameplayEvents.current_grid
	if not registry.vfxRegistry.has(vfx_name):
		return
	var vfx_scene: PackedScene = registry.vfxRegistry[vfx_name]
	var vfx_instance: FX_Control = vfx_scene.instantiate() as FX_Control

	if grid.visibility_manager.current_visible_tiles[grid.player_state].has(coord_target):
		grid.add_child(vfx_instance)
		vfx_instance.start_fx(grid.tile_to_world(coord_origin), grid.tile_to_world(coord_target))