
extends Node

## Global debug settings for conditional debug printing
## Use: if DebugSettings.is_enabled("UI"): print("UI Debug: ...")
## Or: DebugSettings.debug_print("UI", "Your message here")

# Debug categories - set to true to enable debug output for that category
var debug_categories: Dictionary = {
	"UI": false,
	"AI": false,
	"Controller": true,
	"Physics": false,
	"Tileset": false,
	"Map": false,
	"GridObject": true,
	"Mover": false,
	"CommandExecutor": true,
	"PlayerController": true,
	"Unit": true,
	"Combat": false
}

var selected_unit:GridObject

func _ready():
	GameplayEvents.object_selected.connect(set_selection)

func set_selection(object:GridObject):
	selected_unit = object

## Check if a specific debug category is enabled
func is_enabled(category: String) -> bool:
	return debug_categories.get(category, false)

## Print a debug message if the category is enabled
func debug_print(category: String, message: String) -> void:
	if is_enabled(category):
		print("[%s] %s" % [category, message])

## Print a debug message with additional context if the category is enabled
func debug_print_verbose(category: String, message: String, context: String = "") -> void:
	if is_enabled(category):
		var line = "[%s] %s" % [category, message]
		if context:
			line += " (%s)" % context
		print(line)

## Enable a debug category
func enable(category: String) -> void:
	if debug_categories.has(category):
		debug_categories[category] = true
		print("Debug category '%s' enabled" % category)
	else:
		push_warning("Unknown debug category: %s" % category)

## Disable a debug category
func disable(category: String) -> void:
	if debug_categories.has(category):
		debug_categories[category] = false
		print("Debug category '%s' disabled" % category)
	else:
		push_warning("Unknown debug category: %s" % category)

## Toggle a debug category on/off
func toggle(category: String) -> void:
	if debug_categories.has(category):
		debug_categories[category] = !debug_categories[category]
		var state = "enabled" if debug_categories[category] else "disabled"
		print("Debug category '%s' %s" % [category, state])
	else:
		push_warning("Unknown debug category: %s" % category)

## Get all available categories
func get_categories() -> Array:
	return debug_categories.keys()

## Get the current state of all categories
func get_all_states() -> Dictionary:
	return debug_categories.duplicate()

## Enable all debug categories
func enable_all() -> void:
	for category in debug_categories.keys():
		debug_categories[category] = true
	print("All debug categories enabled")

## Disable all debug categories
func disable_all() -> void:
	for category in debug_categories.keys():
		debug_categories[category] = false
	print("All debug categories disabled")
