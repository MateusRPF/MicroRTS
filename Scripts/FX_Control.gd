extends Node2D
class_name FX_Control

@export var play_mode: FX_PlayMode = FX_PlayMode.AT_TARGET
@export var override_duration: float = 0.0

enum FX_PlayMode {
	AT_ORIGIN,
	AT_TARGET,
	PROJECTILE_STRAIGHT,
	PROJECTILE_ARC
}

@onready var sprite = $AnimatedSprite
var _arc_progress: float = 0.0
var _trajectory_origin: Vector2 = Vector2.ZERO
var _trajectory_target: Vector2 = Vector2.ZERO
var _arc_height: float = 0.0
var _animation_done: bool = false
var _tween_done: bool = false

func start_fx(origin: Vector2, target: Vector2) -> void:
	_animation_done = false
	_tween_done = false
	_trajectory_origin = origin
	_trajectory_target = target

	var duration = 0.1

	match play_mode:
		FX_PlayMode.AT_ORIGIN:
			position = origin
			_sprite_play()
			return

		FX_PlayMode.AT_TARGET:
			position = target
			_sprite_play()
			return

		FX_PlayMode.PROJECTILE_STRAIGHT:
			position = origin
			rotation = (target - origin).angle() + PI * 0.5
			_sprite_play()
			var tween = create_tween()
			tween.tween_property(self, "position", target, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
			tween.finished.connect(_on_tween_finished)
			return

		FX_PlayMode.PROJECTILE_ARC:
			position = origin
			_arc_height = max(24.0, origin.distance_to(target) * 0.25)
			_arc_progress = 0.0
			_sprite_play()
			var tween_arc = create_tween()
			tween_arc.tween_property(self, "_arc_progress", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween_arc.finished.connect(_on_tween_finished)

func _sprite_play() -> void:
	if sprite.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		sprite.disconnect("animation_finished", Callable(self, "_on_animation_finished"))
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("default")

func _on_animation_finished() -> void:
	_animation_done = true
	if _tween_done or play_mode in [FX_PlayMode.AT_ORIGIN, FX_PlayMode.AT_TARGET]:
		clear()

func _on_tween_finished() -> void:
	_tween_done = true
	if _animation_done or play_mode in [FX_PlayMode.AT_ORIGIN, FX_PlayMode.AT_TARGET]:
		clear()

# func _process(delta: float) -> void:
	# if play_mode == FX_PlayMode.PROJECTILE_ARC:
	# 	position = _trajectory_origin.linear_interpolate(_trajectory_target, _arc_progress)
	# 	position.y -= sin(_arc_progress * PI) * _arc_height

func _get_animation_duration() -> float:
	if not sprite or sprite.animation == "":
		return 0.0

	var frames = sprite.sprite_frames
	var total_duration: float = 0.0
	if frames:
		var animation_name = sprite.animation
		if frames.has_animation(animation_name):
			if frames.has_method("get_frame_count") and frames.has_method("get_frame_duration"):
				var count = frames.get_frame_count(animation_name)
				for i in range(count):
					total_duration += frames.get_frame_duration(animation_name, i)
			elif frames.has_method("get_animation_speed"):
				var count = frames.get_frame_count(animation_name)
				var speed = frames.get_animation_speed(animation_name)
				if speed > 0.0:
					total_duration = count / speed
		if total_duration > 0.0:
			var speed_scale = sprite.speed_scale
			return total_duration / max(speed_scale, 0.001)

	return 0.0

func clear() -> void:
	queue_free()
