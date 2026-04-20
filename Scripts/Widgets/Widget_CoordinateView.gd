extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameplayEvents.UI_tile_hovered.connect(update_coord)

func update_coord(_controller:PlayerController,coord:Vector2i):
	text = "(%s)" %[coord]
