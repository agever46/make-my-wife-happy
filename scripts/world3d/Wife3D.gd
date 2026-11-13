class_name Wife3D
extends Station3D
## The wife. Normally she sits on the couch. When the kids are home she gets up, walks to the stove and asks for
## ingredients (the husband brings them), cooks, carries the plates to the table, and goes back to the couch.
## Her face follows the Wife-O-Meter: skin flushes red and the brows turn angry.
## Works with the placeholder or a Blender model; optional nodes: Skull, BrowL, BrowR, LegL/LegR, KneeL/KneeR, ArmL/ArmR.

enum Pose { SEATED, STANDING }

const WALK_SPEED := 2.4
const STRIDE := 1.1
const COOK_TIME := 5.0

var pose := Pose.SEATED

var _head: MeshInstance3D
var _brow_l: Node3D
var _brow_r: Node3D
var _skin: StandardMaterial3D
var _shake := 0.0
var _legs: Array[Node3D] = []
var _knees: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _home_position := Vector3.ZERO
var _walking := false
var _stirring := false
var _stir_time := 0.0
var _phase := 0.0
var _last_pos := Vector3.ZERO
var _tween: Tween
var _plates: Node3D
var _steam: Array[MeshInstance3D] = []
var _generation := 0


func setup(def: Dictionary) -> void:
	super.setup(def)
	_head = model.find_child("Skull", true, false) as MeshInstance3D
	_brow_l = model.find_child("BrowL", true, false) as Node3D
	_brow_r = model.find_child("BrowR", true, false) as Node3D
	if _head != null and _head.material_override is StandardMaterial3D:
		_skin = (_head.material_override as StandardMaterial3D).duplicate()
		_head.material_override = _skin
	for leg_name in ["LegL", "LegR"]:
		var leg := model.find_child(leg_name, true, false) as Node3D
		if leg != null:
			_legs.append(leg)
	for knee_name in ["KneeL", "KneeR"]:
		var knee := model.find_child(knee_name, true, false) as Node3D
		if knee != null:
			_knees.append(knee)
	for arm_name in ["ArmL", "ArmR"]:
		var arm := model.find_child(arm_name, true, false) as Node3D
		if arm != null:
			_arms.append(arm)
	_home_position = position
	_pose_seated()
	GameManager.happiness_changed.connect(_on_happiness_changed)
	EventManager.cooking_started.connect(_on_cooking_started)
	EventManager.cooking_finished.connect(_on_cooking_finished)
	EventManager.dinner_serving_requested.connect(_on_serve)
	EventManager.event_reset.connect(_on_reset)


# --- poses --------------------------------------------------------------------

func _pose_seated() -> void:
	pose = Pose.SEATED
	for leg in _legs:
		leg.rotation.x = -1.5 # thighs forward on the couch
	for knee in _knees:
		knee.rotation.x = 1.5 # shins hang down
	for arm in _arms:
		arm.rotation.x = -0.35
	model.rotation.y = 0.0
	model.position.y = -0.2


func _pose_standing() -> void:
	pose = Pose.STANDING
	for leg in _legs:
		leg.rotation.x = 0.0
	for knee in _knees:
		knee.rotation.x = 0.0
	for arm in _arms:
		arm.rotation.x = 0.0
	model.position.y = 0.0


# --- the cooking story -----------------------------------------------------------

func _on_cooking_started() -> void:
	_pose_standing()
	_walk(WALK_SPEED, _path(HouseLayout.WIFE_PATH_TO_STOVE), func() -> void:
		model.rotation.y = PI # face the stove (north)
		EventManager.wife_at_stove())


func _on_cooking_finished() -> void:
	var gen := _generation
	_stirring = true
	_stir_time = 0.0
	_start_steam()
	await get_tree().create_timer(COOK_TIME).timeout
	if gen != _generation:
		return
	_stirring = false
	_stop_steam()
	_pose_standing()
	EventManager.dinner_ready()


func _on_serve() -> void:
	# Plates in her hands, walk to the table, put them down, come back.
	_plates = Node3D.new()
	_plates.name = "PlatesInHands"
	_plates.position = Vector3(0.0, 1.0, 0.35)
	PlaceholderFactory.box(_plates, "PlateA", Vector3(0.3, 0.04, 0.3), Vector3(-0.12, 0.0, 0.0), Color(0.97, 0.97, 0.97), 0.015)
	PlaceholderFactory.box(_plates, "FoodA", Vector3(0.18, 0.08, 0.18), Vector3(-0.12, 0.04, 0.0), Color(0.98, 0.82, 0.4), 0.03)
	PlaceholderFactory.box(_plates, "PlateB", Vector3(0.3, 0.04, 0.3), Vector3(0.14, 0.0, 0.0), Color(0.97, 0.97, 0.97), 0.015)
	PlaceholderFactory.box(_plates, "FoodB", Vector3(0.18, 0.08, 0.18), Vector3(0.14, 0.04, 0.0), Color(0.98, 0.82, 0.4), 0.03)
	model.add_child(_plates)
	for arm in _arms:
		arm.rotation.x = -1.2 # arms forward, carrying
	var gen := _generation
	_walk(WALK_SPEED, _path(HouseLayout.WIFE_PATH_TO_TABLE), func() -> void:
		if gen != _generation:
			return
		model.rotation.y = PI * 0.5 # face the table (east)
		_put_plates_down()
		_walk(WALK_SPEED, _path(HouseLayout.WIFE_PATH_TO_COUCH), func() -> void:
			if gen == _generation:
				_pose_seated()))


func _put_plates_down() -> void:
	if is_instance_valid(_plates):
		_plates.queue_free()
	_plates = null
	for arm in _arms:
		arm.rotation.x = 0.0
	for node in get_tree().get_nodes_in_group("stations"):
		if node is Kid3D:
			(node as Kid3D).show_plate()
	EventManager.dinner_served()


func _on_reset() -> void:
	_generation += 1
	if _tween != null:
		_tween.kill()
	_walking = false
	_stirring = false
	_stop_steam()
	if is_instance_valid(_plates):
		_plates.queue_free()
	_plates = null
	position = _home_position
	_pose_seated()


# --- walking -------------------------------------------------------------------------

func _path(points: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for p in points:
		out.append(p)
	return out


func _walk(speed: float, points: Array[Vector3], done: Callable) -> void:
	if _tween != null:
		_tween.kill()
	_walking = true
	_last_pos = position
	_tween = create_tween()
	var from := position
	for wp in points:
		var dir := wp - from
		dir.y = 0.0
		_tween.tween_callback(_face.bind(dir))
		_tween.tween_property(self, "position", Vector3(wp.x, 0.0, wp.z), maxf(dir.length() / speed, 0.05))
		from = wp
	_tween.tween_callback(func() -> void:
		_walking = false
		for leg in _legs:
			leg.rotation.x = 0.0
		for arm in _arms:
			if _plates == null:
				arm.rotation.x = 0.0
		done.call())


func _face(dir: Vector3) -> void:
	if dir.length() > 0.01:
		model.rotation.y = atan2(dir.x, dir.z)


# --- steam over the pot ------------------------------------------------------------

func _start_steam() -> void:
	_stop_steam()
	var pot := global_position + Vector3(-0.2, 1.2, -0.85)
	for i in 3:
		var puff := PlaceholderFactory.box(get_parent(), "Steam", Vector3(0.14, 0.14, 0.14), Vector3.ZERO, Color(1, 1, 1, 0.7), 0.04)
		puff.material_override = _steam_material()
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		puff.global_position = pot
		_steam.append(puff)
		var tw := puff.create_tween().set_loops()
		tw.tween_interval(i * 0.45)
		tw.tween_callback(func() -> void:
			puff.global_position = pot
			puff.scale = Vector3.ONE * 0.6)
		tw.tween_property(puff, "global_position:y", pot.y + 0.9, 1.4)
		tw.parallel().tween_property(puff, "scale", Vector3.ONE * 1.6, 1.4)


func _stop_steam() -> void:
	for puff in _steam:
		if is_instance_valid(puff):
			puff.queue_free()
	_steam.clear()


func _steam_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.55)
	return m


# --- mood ---------------------------------------------------------------------------

func _on_happiness_changed(new_value: float, old_value: float) -> void:
	var mood := new_value / GameManager.MAX_HAPPINESS
	if _skin != null:
		_skin.albedo_color = Color(0.96, 0.78, 0.64).lerp(Color(0.95, 0.35, 0.3), clampf(1.0 - mood * 1.4, 0.0, 1.0))
	var angry := clampf(1.0 - mood * 1.6, 0.0, 1.0)
	if _brow_l != null:
		_brow_l.rotation.z = -angry * 0.5 + (1.0 - angry) * 0.12
	if _brow_r != null:
		_brow_r.rotation.z = angry * 0.5 - (1.0 - angry) * 0.12
	if new_value < old_value - 5.0: # a sharp drop: she flinches
		_shake = 0.4


func _process(delta: float) -> void:
	super._process(delta)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		visual_root.rotation.z = sin(_shake * 60.0) * _shake * 0.12
	elif visual_root.rotation.z != 0.0:
		visual_root.rotation.z = 0.0
	if _walking:
		var moved := Vector2(position.x - _last_pos.x, position.z - _last_pos.z).length()
		_last_pos = position
		if moved > 0.0001:
			_phase += TAU * moved / STRIDE
			var swing := sin(_phase) * 0.55
			if _legs.size() == 2:
				_legs[0].rotation.x = swing
				_legs[1].rotation.x = -swing
			if _arms.size() == 2 and _plates == null:
				_arms[0].rotation.x = -swing
				_arms[1].rotation.x = swing
			model.position.y = absf(sin(_phase)) * 0.03
	elif _stirring:
		_stir_time += delta
		if _arms.size() == 2:
			_arms[1].rotation.x = -1.2 + sin(_stir_time * 9.0) * 0.35
			_arms[1].rotation.z = cos(_stir_time * 9.0) * 0.25
			_arms[0].rotation.x = -0.5
		model.rotation.y = PI + sin(_stir_time * 2.0) * 0.06


## Beside her head, to the right, so it stays below the top HUD and clear of her task icon.
func speech_anchor() -> Vector3:
	return Vector3(0.7, 1.45 if pose == Pose.SEATED else 2.0, 0.0)


func speech_side() -> float:
	return 1.0
