class_name Player
extends CharacterBody2D
## Top-down / isometric player with bouncy, elastic movement.
## WASD / arrow keys, 8 directions. Diagonals are normalized by Input.get_vector.

@export var max_speed: float = 280.0
## Higher = snappier start. Lower = more "floaty".
@export var acceleration: float = 9.0
## Higher = stops faster.
@export var friction: float = 12.0
## Overshoot "bounce" when changing direction (0 = none, ~0.15 = cartoony).
@export_range(0.0, 0.5) var elastic_overshoot: float = 0.12
## Vertical screen movement is scaled to fake an isometric angle (2:1 ratio ~ 0.5).
@export_range(0.25, 1.0) var iso_y_scale: float = 0.5
## Optional node used for squash & stretch (e.g. the Sprite2D / Visual node).
@export var visual: Node2D

var _overshoot_velocity := Vector2.ZERO


func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if GameManager.is_playing():
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var target := input_dir * Vector2(1.0, iso_y_scale) * max_speed
	var rate := acceleration if input_dir != Vector2.ZERO else friction
	# Frame-rate independent exponential smoothing.
	var smoothed := velocity.lerp(target, 1.0 - exp(-rate * delta))

	# Elastic kick: when the input direction flips, add a little spring-back.
	if elastic_overshoot > 0.0 and input_dir != Vector2.ZERO:
		var change := target - velocity
		_overshoot_velocity = _overshoot_velocity.lerp(change * elastic_overshoot, 1.0 - exp(-rate * delta))
	else:
		_overshoot_velocity = _overshoot_velocity.lerp(Vector2.ZERO, 1.0 - exp(-friction * delta))

	velocity = smoothed + _overshoot_velocity * delta * rate
	move_and_slide()
	_update_squash(delta)


func _update_squash(delta: float) -> void:
	if visual == null:
		return
	var t := clampf(velocity.length() / max_speed, 0.0, 1.0)
	var target_scale := Vector2(1.0 + 0.12 * t, 1.0 - 0.12 * t)
	if absf(velocity.y) > absf(velocity.x):
		target_scale = Vector2(1.0 - 0.08 * t, 1.0 + 0.08 * t)
	visual.scale = visual.scale.lerp(target_scale, 1.0 - exp(-14.0 * delta))
