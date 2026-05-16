extends Resource
class_name ActorData



@export var actor_name : String
@export var description: String
@export var sprite: Texture2D
@export var view_offset:Vector2i = Vector2i(0,0)
@export var grid_size:Vector2i = Vector2i(1,1)
@export var clearance: int = 0
@export var layer: Layer = Layer.UNIT
@export var modules: Array[ComponentData]
@export var tags:Array[ActorTag]
@export var costs: Dictionary[GameResource, int]
@export var blocks_view:bool = false

@export var spawn_on_death: String

@export var VFX_Spawn:String = "Spawn"
@export var VFX_Death:String = "Death"

enum Layer { UNIT, PROP }
enum Sides { PLAYER, NEUTRAL, ALLY, ENEMY }



