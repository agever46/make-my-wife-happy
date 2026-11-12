class_name Player3D
extends CharacterBody3D
## A player on the X/Z plane. Smooth, slightly elastic movement, turns towards where it walks,
## and interacts with stations via their Area3D zones.
## Hold `interact` at a station to work, tap it to pick up / drop an item.
## Multiplayer-ready: player_id selects the input actions "p<id>_*".

@export var player_id: int = 1
@export var model_name: String = "Char_Husband"
@export var max_speed: float = 5.4
## Higher = snappier start. Lower = more floaty.
@export var acceleration: float = 11.0
@export var friction: float = 15.0
@export_range(0.0, 0.4) var elastic_overshoot: float = 0.1
@export var turn_speed: float = 16.0
@export var pickup_radius: float = 1.15
## Metres walked per full stride; keeps the leg swing in step with the ground speed.
@export var stride_length: float = 1.9

var held_item: Item3D = null
var carry_point: Marker3D

var _prefix := "p1_"
var _overshoot := Vector3.ZERO
var _visual: Node3D
var _model: Node3D
var _phase := 0.0
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []


func _ready() -> void:
	_prefix = "p%d_" % player_id
	add_to_group("players")
	GameManager.register_player()
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = 1
	collision_mask = Station3D.LAYER_WORLD

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.6
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.8, 0.0)
	add_child(shape)

	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_model = ModelLoader.spawn(model_name)
	_visual.add_child(_model)
	for leg_name in ["LegL", "LegR"]:
		var leg := _model.find_child(leg_name, true, false) as Node3D
		if leg != null:
			_legs.append(leg)
	for arm_name in ["ArmL", "ArmR"]:
		var arm := _model.find_child(arm_name, true, false) as Node3D
		if arm != null:
			_arms.append(arm)
	add_child(ContactShadow.make(Vector2(0.55, 0.4), 0.2, 0.55))

	carry_point = Marker3D.new()
	carry_point.name = "CarryPoint"
	carry_point.position = Vector3(0.0, 2.0, 0.0)
	add_child(carry_point)


func _exit_tree() -> void:
	GameManager.unregister_player()


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if GameManager.is_playing():
		input = Input.get_vector(_prefix + "move_left", _prefix + "move_right", _prefix + "move_up", _prefix + "move_down")
	var dir := Vector3(input.x, 0.0, input.y)
	var target := dir * max_speed
	var rate := acceleration if dir != Vector3.ZERO else friction
	var blend := 1.0 - exp(-rate * delta)
	var smoothed := velocity.lerp(target, blend)
	# Elastic kick: a little spring-back when the direction changes.
	if elastic_overshoot > 0.0 and dir != Vector3.ZERO:
		_overshoot = _overshoot.lerp((target - velocity) * elastic_overshoot, blend)
	else:
		_overshoot = _overshoot.lerp(Vector3.ZERO, 1.0 - exp(-friction * delta))
	velocity = smoothed + _overshoot * delta * rate
	velocity.y = 0.0
	move_and_slide()
	position.y = 0.0

	if dir != Vector3.ZERO:
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-turn_speed * delta))
	_animate(delta)
	_update_interaction(delta)


# --- Animation ---------------------------------------------------------------

func _animate(delta: float) -> void:
	var speed := velocity.length()
	var t := clampf(speed / max_speed, 0.0, 1.0)
	_phase += TAU * speed / stride_length * delta
	var swing := sin(_phase) * 0.75 * t
	if _legs.size() == 2:
		_legs[0].rotation.x = swing
		_legs[1].rotation.x = -swing
	if _arms.size() == 2:
		_arms[0].rotation.x = -swing * 0.8
		_arms[1].rotation.x = swing * 0.8
	_visual.position.y = absf(sin(_phase)) * 0.05 * t
	# Lean into the run and squash a little, relaxed like a tired husband.
	_visual.rotation.x = lerpf(_visual.rotation.x, 0.14 * t, 1.0 - exp(-10.0 * delta))
	_visual.scale = Vector3(1.0 + 0.03 * t, 1.0 - 0.04 * t, 1.0 + 0.03 * t)


# --- Interaction -------------------------------------------------------------

func held_item_id() -> StringName:
	return held_item.item_id if is_instance_valid(held_item) else &""


func give_item(item: Item3D) -> void:
	if is_instance_valid(held_item):
		drop_item()
	if item.get_parent() != null:
		item.reparent(carry_point, false)
	else:
		carry_point.add_child(item)
	item.position = Vector3.ZERO
	item.holder = self
	held_item = item


func drop_item() -> void:
	if not is_instance_valid(held_item):
		held_item = null
		return
	var item := held_item
	held_item = null
	item.holder = null
	var root := get_tree().get_first_node_in_group("item_root") as Node3D
	item.reparent(root if root != null else get_parent(), false)
	var forward := Vector3(sin(_visual.rotation.y), 0.0, cos(_visual.rotation.y))
	item.global_position = Vector3(global_position.x, 0.0, global_position.z) + forward * 0.7


func consume_item() -> void:
	if is_instance_valid(held_item):
		held_item.destroy()
	held_item = null


func _update_interaction(delta: float) -> void:
	if not GameManager.is_playing():
		return
	var action := _prefix + "interact"
	if Input.is_action_pressed(action):
		var station := _current_station()
		if station != null:
			var result := QuestManager.try_work(station.station_id, held_item_id(), delta)
			if not result.is_empty():
				station.show_progress(result["progress"])
				if result["done"]:
					_apply_result(result)
				return
	if Input.is_action_just_pressed(action):
		if is_instance_valid(held_item):
			drop_item()
		else:
			var item := _nearest_item()
			if item != null:
				give_item(item)


func _apply_result(result: Dictionary) -> void:
	if result["consume"]:
		consume_item()
	var give: StringName = result["give"]
	if give != &"":
		var item := Item3D.create(give, result["quest_uid"])
		var root := get_tree().get_first_node_in_group("item_root") as Node3D
		(root if root != null else get_parent()).add_child(item)
		give_item(item)


## The station to work at: among the InteractZones that contain this player, the nearest one where a quest
## can make progress right now; if none can, simply the nearest. (Zones overlap, e.g. dog and car.)
func _current_station() -> Station3D:
	var best: Station3D = null
	var best_dist := INF
	var best_can := false
	for node in get_tree().get_nodes_in_group("stations"):
		var station := node as Station3D
		if station == null or not station.has_player(self):
			continue
		var can := QuestManager.can_work(station.station_id, held_item_id())
		var d := Vector2(station.global_position.x - global_position.x, station.global_position.z - global_position.z).length()
		if (can and not best_can) or (can == best_can and d < best_dist):
			best_dist = d
			best = station
			best_can = can
	return best


func _nearest_item() -> Item3D:
	var best: Item3D = null
	var best_dist := pickup_radius
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item3D
		if item == null or item.holder != null:
			continue
		var d := Vector2(item.global_position.x - global_position.x, item.global_position.z - global_position.z).length()
		if d < best_dist:
			best_dist = d
			best = item
	return best
