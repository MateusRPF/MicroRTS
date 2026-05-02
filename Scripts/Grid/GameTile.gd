
class_name GameTile	
var coord:Vector2i
var has_unit_occupant:bool = false
var unit_occupant:GridObject = null
var prop_occupant:GridObject = null
var buildable:bool = true
var tile_type:TileType = TileType.FLOOR

var walkable:bool:
	get:
		return has_unit_occupant == false && tile_type == TileType.FLOOR


enum TileType {
	FLOOR,
	WALL,
	HOLE,
}