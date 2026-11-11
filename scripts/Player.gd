class_name Player
extends CharacterBody2D
## Top-down / isometric player with bouncy, elastic movement.
## WASD / arrow keys, 8 directions. Diagonals are normalized by Input.get_vector.
## Also handles interaction: hold `interact` at a station to work, tap it to pick up / drop an item.
## Multiplayer-ready: every player has a player_id and reads its own "p<id>_*" input actions.

@export var player_id: int = 1
@export var interact_radius: float = 48.0
@export var pickup_radius: float = 44.0
## Where a carried item floats, relative to the feet.
@export var carry_offset := Vector2(0, -162)

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
## Optional Skeleton2D cut-out rig (scenes/PlayerRig.tscn). Used instead of `visual`.
@export var rig: PlayerRig
## Forward lean (radians) at full speed, and side-to-side body sway per step. Fake a relaxed gait.
@export var lean_amount: float = 0.09
@export var sway_amount: float = 0.05
## Ground distance (screen px) covered by one full 4-frame walk cycle (two steps).
## Smaller = feet move faster for the same speed. Tune until feet stop "skating".
@export var walk_cycle_length: float = 104.0

var _overshoot_velocity := Vector2.ZERO
var _facing := 1.0 # the source art looks left; 1.0 = as drawn, -1.0 = mirrored
var _bob_time := 0.0
var _gait_phase := 0.0
var _base_scale: Vector2
var _prefix := "p1_"

var held_item: Item = null


func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if GameManager.is_playing():
		input_dir = Input.get_vector(_prefix + "move_left", _prefix + "move_right", _prefix + "move_up", _prefix + "move_down")

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
	if rig != null:
		rig.cycle_length = walk_cycle_length
		rig.update_motion(velocity)
	_update_interaction(delta)
	_update_squash(delta)


# --- Interaction -------------------------------------------------------------

func held_item_id() -> StringName:
	return held_item.item_id if is_instance_valid(held_item) else &""


func give_item(item: Item) -> void:
	if is_instance_valid(held_item):
		drop_item()
	if item.get_parent() != null:
		item.reparent(self, false)
	else:
		add_child(item)
	item.position = carry_offset
	item.holder = self
	held_item = item


func drop_item() -> void:
	if not is_instance_valid(held_item):
		held_item = null
		return
	var item := held_item
	held_item = null
	item.holder = null
	item.reparent(get_parent(), false)
	item.position = position + Vector2(0, 8)


func consume_item() -> void:
	if is_instance_valid(held_item):
		held_item.destroy()
	held_item = null


func _update_interaction(delta: float) -> void:
	if not GameManager.is_playing():
		return
	var station := _nearest_station()
	if station != null:
		station.mark_focused()
	var action := _prefix + "interact"
	if station != null and Input.is_action_pressed(action):
		var ratio := QuestManager.try_work(station, self, delta)
		if ratio >= 0.0:
			station.show_progress(ratio)
			return
	if Input.is_action_just_pressed(action):
		if is_instance_valid(held_item):
			drop_item()
		else:
			var item := _nearest_item()
			if item != null:
				give_item(item)


func _nearest_station() -> Station:
	var best: Station = null
	var best_dist := interact_radius
	for node in get_tree().get_nodes_in_group("stations"):
		var station := node as Station
		if station == null:
			continue
		var d := station.distance_to(global_position)
		if d < best_dist:
			best_dist = d
			best = station
	return best


func _nearest_item() -> Item:
	var best: Item = null
	var best_dist := pickup_radius
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item == null or item.holder != null:
			continue
		var d := item.global_position.distance_to(global_position)
		if d < best_dist:
			best_dist = d
			best = item
	return best


func _ready() -> void:
	_prefix = "p%d_" % player_id
	add_to_group("players")
	if visual != null:
		_base_scale = visual.scale
		if visual is AnimatedSprite2D:
			visual.play(&"idle")


func _update_squash(delta: float) -> void:
	if visual == null:
		return
	if velocity.x > 8.0:
		_facing = -1.0
	elif velocity.x < -8.0:
		_facing = 1.0
	var t := clampf(velocity.length() / max_speed, 0.0, 1.0)
	var target_scale := Vector2(1.0 + 0.12 * t, 1.0 - 0.12 * t)
	if absf(velocity.y) > absf(velocity.x):
		target_scale = Vector2(1.0 - 0.08 * t, 1.0 + 0.08 * t)
	if visual is AnimatedSprite2D:
		target_scale = Vector2.ONE # frame animation already carries the motion
	target_scale *= _base_scale
	var s := Vector2(absf(visual.scale.x), visual.scale.y).lerp(target_scale, 1.0 - exp(-14.0 * delta))
	visual.scale = Vector2(s.x * _facing, s.y)
	if visual is AnimatedSprite2D:
		var sprite := visual as AnimatedSprite2D
		var moving := velocity.length() > 20.0
		var wanted := &"walk" if moving else &"idle"
		if sprite.animation != wanted:
			sprite.play(wanted)
		if moving:
			# Sync the feet to ground speed: frames/sec = 4 * speed / cycle length.
			var fps := 4.0 * velocity.length() / walk_cycle_length
			var base_fps := sprite.sprite_frames.get_animation_speed(&"walk")
			sprite.speed_scale = fps / base_fps
		else:
			sprite.speed_scale = 1.0
	# Walk bob: small hop synced to speed.
	_bob_time += delta * (6.0 + 10.0 * t)
	# Gait: lean into the move direction and rock side to side with each step.
	var horizontal := clampf(velocity.x / max_speed, -1.0, 1.0)
	_gait_phase += TAU * velocity.length() / walk_cycle_length * delta
	visual.rotation = -_facing * absf(horizontal) * lean_amount \
		+ sin(_gait_phase) * sway_amount * t
	visual.position.y = 0.0 if visual is AnimatedSprite2D else -absf(sin(_bob_time)) * 3.0 * t
