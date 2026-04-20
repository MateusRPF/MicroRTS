
class_name GameTile	
var coord:Vector2i
var is_occupied:bool = false
var occupant:GridObject = null
var buildable:bool = true
var tile_type:TileType = TileType.FLOOR
var walkable:bool:
	get:
		return is_occupied == false && tile_type == TileType.FLOOR


enum TileType {
	FLOOR,
	WALL,
	HOLE,
}