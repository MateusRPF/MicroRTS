extends Node2D
class_name FX_Control

func _ready() -> void:
	$AnimatedSprite.play("default")
	$AnimatedSprite.connect("animation_finished",clear)

func clear() -> void:
	queue_free()
