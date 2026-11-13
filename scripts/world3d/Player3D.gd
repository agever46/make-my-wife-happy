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

# --- mouse control (player 1 only) ---
## Click the floor to walk there (hold to follow the cursor); click a station to walk there and work until the step
## is done; click an item to fetch it; right click drops / picks up. Any movement key cancels.
var _nav_active := false
var _nav_target := Vector3.ZERO
var _nav_station: Station3D = null
var _nav_item: Item3D = null
var _auto_work := false
var _mouse_down := false
var _stuck := 0.0
var _detour_left := 0.0
var _detour_sign := 1.0
var _detours := 0
var _last_nav_pos := Vector3.ZERO
var _hover_station: Station3D = null
var _marker: MeshInstance3D


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

	if player_id == 1:
		_marker = _make_marker()
		get_parent().add_child.call_deferred(_marker)
	carry_point = Marker3D.new()
	carry_point.name = "CarryPoint"
	carry_point.position = Vector3(0.0, 2.0, 0.0)
	add_child(carry_point)


func _exit_tree() -> void:
	GameManager.unregister_player()
	if is_instance_valid(_marker):
		_marker.queue_free()


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if GameManager.is_playing():
		input = Input.get_vector(_prefix + "move_left", _prefix + "move_right", _prefix + "move_up", _prefix + "move_down")
	if input != Vector2.ZERO:
		_cancel_nav() # keyboard wins over the mouse
	elif _nav_active:
		input = _nav_input(delta)
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
	var step_before := floori(_phase / PI)
	_phase += TAU * speed / stride_length * delta
	if speed > 0.5 and floori(_phase / PI) != step_before:
		Sfx.footstep()
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
	Sfx.pickup()


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
	Sfx.drop()


func consume_item() -> void:
	if is_instance_valid(held_item):
		held_item.destroy()
	held_item = null


func _update_interaction(delta: float) -> void:
	if not GameManager.is_playing():
		Sfx.set_working(self, false)
		return
	var action := _prefix + "interact"
	if Input.is_action_pressed(action) or _auto_work:
		var station := _current_station()
		if station != null:
			var result := QuestManager.try_work(station.station_id, held_item_id(), delta)
			if not result.is_empty():
				Sfx.set_working(self, not result["done"])
				station.show_progress(result["progress"])
				if result["done"]:
					_apply_result(result)
					_cancel_nav() # a mouse-ordered job is finished
				return
		if _auto_work:
			_cancel_nav() # nothing to do here (any more)
	Sfx.set_working(self, false)
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


# --- Mouse -----------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if player_id != 1 or not GameManager.is_playing():
		return
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT:
			_mouse_down = click.pressed
			if click.pressed:
				_click_at(click.position)
		elif click.button_index == MOUSE_BUTTON_RIGHT and click.pressed:
			_cancel_nav()
			if is_instance_valid(held_item):
				drop_item()
			else:
				var item := _nearest_item()
				if item != null:
					give_item(item)
	elif event is InputEventMouseMotion and _mouse_down and _nav_station == null and _nav_item == null:
		# Dragging: keep walking towards the cursor.
		var floor_point = _floor_point(event.position)
		if floor_point != null:
			_set_nav_floor(floor_point)


func _process(_delta: float) -> void:
	if player_id != 1:
		return
	_update_hover()
	_update_marker()


func _click_at(screen_pos: Vector2) -> void:
	var station := _pick_station(screen_pos)
	if station != null:
		_cancel_nav()
		_nav_active = true
		_nav_station = station
		_nav_target = station.global_position
		return
	var item := _pick_item(screen_pos)
	if item != null:
		_cancel_nav()
		_nav_active = true
		_nav_item = item
		_nav_target = item.global_position
		return
	var floor_point = _floor_point(screen_pos)
	if floor_point != null:
		_cancel_nav()
		_set_nav_floor(floor_point)


func _set_nav_floor(point: Vector3) -> void:
	_nav_active = true
	_nav_station = null
	_nav_item = null
	_auto_work = false
	_nav_target = Vector3(point.x, 0.0, point.z)


func _cancel_nav() -> void:
	_nav_active = false
	_nav_station = null
	_nav_item = null
	_auto_work = false
	_stuck = 0.0
	_detour_left = 0.0
	_detours = 0


## Steering for click-to-move. Returns the same Vector2 the keyboard would.
func _nav_input(delta: float) -> Vector2:
	# Arrived at what was clicked?
	if _nav_station != null:
		if is_instance_valid(_nav_station) and _nav_station.has_player(self):
			_auto_work = true
			return Vector2.ZERO
		if not is_instance_valid(_nav_station):
			_cancel_nav()
			return Vector2.ZERO
		_nav_target = _nav_station.global_position
	elif _nav_item != null:
		if not is_instance_valid(_nav_item) or _nav_item.holder != null:
			_cancel_nav()
			return Vector2.ZERO
		_nav_target = _nav_item.global_position
		if Vector2(_nav_target.x - global_position.x, _nav_target.z - global_position.z).length() < pickup_radius * 0.8:
			give_item(_nav_item)
			_cancel_nav()
			return Vector2.ZERO
	var to := Vector2(_nav_target.x - global_position.x, _nav_target.z - global_position.z)
	if _nav_station == null and _nav_item == null and to.length() < 0.15:
		_cancel_nav()
		return Vector2.ZERO
	# Blocked (furniture corner, wall)? Veer off to one side for a moment, alternating; give up after a few tries.
	# There is no path finding; steer around bigger obstacles with the keys.
	var moved := global_position.distance_to(_last_nav_pos) / maxf(delta, 0.0001)
	_last_nav_pos = global_position
	if moved < 0.6 and _detour_left <= 0.0:
		_stuck += delta
		if _stuck > 0.3:
			_stuck = 0.0
			_detours += 1
			if _detours > 4:
				_cancel_nav()
				return Vector2.ZERO
			_detour_sign = -_detour_sign
			_detour_left = 0.7
	elif moved >= 0.6:
		_stuck = 0.0
	if _detour_left > 0.0:
		_detour_left -= delta
		to = to.rotated(_detour_sign * 1.2)
		if _detour_left <= 0.0 and moved > 2.0:
			_detours = maxi(_detours - 1, 0)
	var slow := clampf(to.length() / 0.7, 0.35, 1.0)
	return to.normalized() * slow


func _mouse_ray(screen_pos: Vector2) -> Dictionary:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return {}
	var origin := cam.project_ray_origin(screen_pos)
	return {"from": origin, "dir": cam.project_ray_normal(screen_pos)}


func _floor_point(screen_pos: Vector2) -> Variant:
	var ray := _mouse_ray(screen_pos)
	if ray.is_empty():
		return null
	return Plane(Vector3.UP, 0.0).intersects_ray(ray["from"], ray["dir"])


func _pick_station(screen_pos: Vector2) -> Station3D:
	var ray := _mouse_ray(screen_pos)
	if ray.is_empty():
		return null
	var best: Station3D = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("stations"):
		var station := node as Station3D
		if station == null or not station.visible or not station.is_visible_in_tree():
			continue
		var hit = station.pick_aabb().intersects_ray(ray["from"], ray["dir"])
		if hit != null:
			var d: float = (hit as Vector3).distance_to(ray["from"])
			if d < best_dist:
				best_dist = d
				best = station
	return best


func _pick_item(screen_pos: Vector2) -> Item3D:
	var ray := _mouse_ray(screen_pos)
	if ray.is_empty():
		return null
	var from: Vector3 = ray["from"]
	var to: Vector3 = from + (ray["dir"] as Vector3) * 200.0
	var best: Item3D = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item3D
		if item == null or item.holder != null:
			continue
		var hit := Geometry3D.segment_intersects_sphere(from, to, item.global_position + Vector3(0.0, 0.3, 0.0), 0.45)
		if not hit.is_empty():
			var d := (hit[0] as Vector3).distance_to(from)
			if d < best_dist:
				best_dist = d
				best = item
	return best


func _update_hover() -> void:
	var hovered: Station3D = null
	var over_item := false
	if GameManager.is_playing() and not get_tree().paused:
		var mouse := get_viewport().get_mouse_position()
		hovered = _pick_station(mouse)
		if hovered == null:
			over_item = _pick_item(mouse) != null
	if hovered != _hover_station:
		if is_instance_valid(_hover_station):
			_hover_station.set_hover(false)
		_hover_station = hovered
		if hovered != null:
			hovered.set_hover(true)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if (hovered != null or over_item) else Input.CURSOR_ARROW)


func _make_marker() -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.28
	mesh.bottom_radius = 0.28
	mesh.height = 0.02
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.85, 0.2, 0.7)
	mesh.material = mat
	var marker := MeshInstance3D.new()
	marker.name = "ClickMarker"
	marker.mesh = mesh
	marker.visible = false
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return marker


## A pulsing yellow disc on the floor where you clicked, while walking there.
func _update_marker() -> void:
	if _marker == null or not is_instance_valid(_marker) or _marker.get_parent() == null:
		return
	var show := _nav_active and _nav_station == null and _nav_item == null
	_marker.visible = show
	if show:
		_marker.global_position = Vector3(_nav_target.x, 0.03, _nav_target.z)
		var pulse := 1.0 + sin(Time.get_ticks_msec() / 120.0) * 0.12
		_marker.scale = Vector3(pulse, 1.0, pulse)
