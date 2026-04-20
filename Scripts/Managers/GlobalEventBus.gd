extends Node

# -- Selection Events --

signal object_selected(object: GridObject)

signal multiple_objects_selected(objects: Array[GridObject])

signal selection_cleared()

signal UI_controller_ready(controller:PlayerController)
signal UI_command_requested(controller:PlayerController)
signal UI_tile_hovered(controller:PlayerController, coord:Vector2i)

# -- Movement & Logic --
# Useful for the UI to know when to update position-based widgets

signal movement_step(object: GridObject, from_coord: Vector2i, to_coord: Vector2i)

# -- Life Cycle & Health --
# Using 'object' instead of 'actor' to keep it generic for structures/units

signal object_spawned(object: GridObject)

signal object_destroyed(object: GridObject)

signal object_finished_building(object: GridObject)

signal wound_changed(object: GridObject, current_wounds: int, max_wounds: int)