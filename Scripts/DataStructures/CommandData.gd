extends Resource
class_name CommandData


@export var display_name: String = "Move"
@export var description: String = "Move"
@export var icon: Texture2D
@export var target_mode: Targetting = Targetting.NONE
@export var priority = 1 #when two commands apply, choose the one with highest priority.
@export var required_components: Array[Script]
@export var command_script:Script
@export var preferred_hotkey:Key = Key.KEY_NONE

## If this is a SUBMENU mode, these are the commands inside it
@export var sub_commands: Array[CommandData] = []

enum Targetting {
	NONE,
	EMPTY_TILE,
	ACTOR_ANY,
	# UNIT_ALLY,
	UNIT_ENEMY,
	# STRUCTURE_ANY,
	# STRUCTURE_ALLY,
	# STRUCTURE_ENEMY,
	RESOURCE_NODE,
	BUILD_SETUP,
	SUBMENU,
	CONSTRUCTION_SITE,
	GARRISON
}