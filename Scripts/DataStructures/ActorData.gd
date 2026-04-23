extends Resource
class_name ActorData

@export var actor_name : String
@export var description: String
@export var sprite: Texture2D
@export var view_offset:Vector2i = Vector2i(0,0)
@export var grid_size:Vector2i = Vector2i(1,1)
@export var clearance: int = 0
@export var modules: Array[ComponentData]
@export var tags:Array[ActorTag]


enum Sides { PLAYER, NEUTRAL, ALLY, ENEMY }


