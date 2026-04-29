extends Node

@export var grid: GridManager

@export var vfxRegistry:Dictionary[String, PackedScene]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameplayEvents.VFX_requested.connect(_on_vfx_requested)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_vfx_requested(vfx_name:String, coord_origin:Vector2i,coord_target) -> void:
	if not vfxRegistry.has(vfx_name):
		print("VFXManager: No VFX found for name: " + vfx_name)
		return
	var vfx_scene: PackedScene = vfxRegistry[vfx_name]
	var vfx_instance: FX_Control = vfx_scene.instantiate() as FX_Control
	grid.add_child(vfx_instance)
	vfx_instance.start_fx(grid.tile_to_world(coord_origin), grid.tile_to_world(coord_target))
