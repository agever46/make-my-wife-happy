class_name Kid3D
extends Station3D
## One of the two kids. Life cycle: walks from the bus to a chair and sits (dinner), then after dinner stands up
## and runs around the living room playing. All the time it is a station: give it what it asked for, or
## hold interact next to it to play (the quest logic knows the ids kid_a / kid_b).
## While a player stands next to a playing kid, the kid stops running so you can actually reach it.

signal seated

enum Mode { ARRIVING, SEATED, PLAYING }

const ARRIVE_SPEED := 2.6
const PLAY_SPEED := 2.0
## Metres per full stride, for the leg swing while walking.
const STRIDE := 1.0

var kid_name := ""
var mode := Mode.ARRIVING
var is_seated := false

var _walking := false
var _held_still := false
var _phase := 0.0
var _hop := 0.0
var _last_pos := Vector3.ZERO
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _knees: Array[Node3D] = []
var _plate: Node3D
var _tween: Tween
var _play_time_left := 0.0
var _at_play_spot := false


func setup(def: Dictionary) -> void:
	super.setup(def)
	kid_name = def.get("name", "")
	for leg_name in ["LegL", "LegR"]:
		var leg := model.find_child(leg_name, true, false) as Node3D
		if leg != null:
			_legs.append(leg)
	for arm_name in ["ArmL", "ArmR"]:
		var arm := model.find_child(arm_name, true, false) as Node3D
		if arm != null:
			_arms.append(arm)
	for knee_name in ["KneeL", "KneeR"]:
		var knee := model.find_child(knee_name, true, false) as Node3D
		if knee != null:
			_knees.append(knee)
	visible = false
	QuestManager.quest_completed.connect(_on_quest_completed)


# --- arriving and sitting ----------------------------------------------------

## Starts walking along `waypoints` (the last one is the seat), then sits down.
func walk_to_seat(start: Vector3, waypoints: Array[Vector3], delay: float = 0.0) -> void:
	mode = Mode.ARRIVING
	position = start
	visible = true
	_last_pos = start
	_walking = true
	_kill_tween()
	_tween = create_tween()
	if delay > 0.0:
		_tween.tween_interval(delay)
	var from := start
	for wp in waypoints:
		_add_leg(from, wp, ARRIVE_SPEED)
		from = wp
	_tween.tween_callback(_sit)


func _sit() -> void:
	_walking = false
	is_seated = true
	mode = Mode.SEATED
	model.rotation.y = 0.0 # facing the table (south)
	for leg in _legs:
		leg.rotation.x = -1.5 # thighs forward on the chair
	for knee in _knees:
		knee.rotation.x = 1.5 # shins hang down
	for arm in _arms:
		arm.rotation.x = -0.5
	model.position.y = -0.04
	seated.emit()


# --- playing -------------------------------------------------------------------

## Dinner is over: stand up, walk out from behind the chair and start running around.
func leave_table(delay: float = 0.0) -> void:
	if mode != Mode.SEATED:
		return
	mode = Mode.PLAYING
	is_seated = false
	_stand_pose()
	_kill_tween()
	_tween = create_tween()
	if delay > 0.0:
		_tween.tween_interval(delay)
	# Step back from the chair first, then off to a play spot.
	var step_out := Vector3(position.x, 0.0, position.z - 0.9)
	_tween.tween_callback(_start_walking)
	_add_leg(position, step_out, PLAY_SPEED)
	_tween.tween_callback(_pick_next_spot.bind(step_out))


func _stand_pose() -> void:
	for leg in _legs:
		leg.rotation.x = 0.0
	for knee in _knees:
		knee.rotation.x = 0.0
	for arm in _arms:
		arm.rotation.x = 0.0
	model.position.y = 0.0


func _start_walking() -> void:
	_walking = true
	_at_play_spot = false
	_last_pos = position


func _pick_next_spot(from: Vector3) -> void:
	if mode != Mode.PLAYING:
		return
	var best := from
	var points: Array = HouseLayout.PLAY_POINTS
	for i in 8:
		var p: Vector2 = points.pick_random()
		var candidate := Vector3(p.x, 0.0, p.y)
		if candidate.distance_to(from) > 2.5:
			best = candidate
			break
	_walking = true
	_at_play_spot = false
	_last_pos = position
	_kill_tween()
	_tween = create_tween()
	_add_leg(position, best, PLAY_SPEED)
	_tween.tween_callback(_arrive_at_spot)


func _arrive_at_spot() -> void:
	_walking = false
	_at_play_spot = true
	_play_time_left = randf_range(2.5, 4.5)


func _add_leg(from: Vector3, to: Vector3, speed: float) -> void:
	var dir := to - from
	dir.y = 0.0
	_tween.tween_callback(_face.bind(dir))
	_tween.tween_property(self, "position", to, maxf(dir.length() / speed, 0.05))


func _face(dir: Vector3) -> void:
	if dir.length() > 0.01:
		model.rotation.y = atan2(dir.x, dir.z)


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


# --- per-frame ---------------------------------------------------------------

func _process(delta: float) -> void:
	super._process(delta)
	if mode == Mode.PLAYING:
		_update_playing(delta)
	if _walking:
		var moved := Vector2(position.x - _last_pos.x, position.z - _last_pos.z).length()
		_last_pos = position
		if moved > 0.0001:
			_phase += TAU * moved / STRIDE
		var swing := sin(_phase) * 0.55 if moved > 0.0001 else 0.0
		if _legs.size() == 2:
			_legs[0].rotation.x = swing
			_legs[1].rotation.x = -swing
		if _arms.size() == 2:
			_arms[0].rotation.x = -swing
			_arms[1].rotation.x = swing
		model.position.y = absf(sin(_phase)) * 0.04


func _update_playing(delta: float) -> void:
	# Stop running while a player is next to the kid, so it can be reached.
	var hold := not players_in_zone.is_empty()
	if hold != _held_still:
		_held_still = hold
		if _tween != null and _tween.is_valid():
			if hold:
				_tween.pause()
			else:
				_tween.play()
	if hold and _walking:
		# Standing still mid-run: stop the leg swing.
		for leg in _legs:
			leg.rotation.x = 0.0
		for arm in _arms:
			arm.rotation.x = 0.0
		_walking = false
		_walk_paused_resume = true
	elif not hold and _walk_paused_resume:
		_walk_paused_resume = false
		_walking = true
		_last_pos = position
	if _at_play_spot and not hold:
		# Playing in place: hop around happily, then run to the next spot.
		_hop += delta * 9.0
		model.position.y = absf(sin(_hop)) * 0.16
		for arm in _arms:
			arm.rotation.x = -2.4 + sin(_hop * 2.0) * 0.5
		_play_time_left -= delta
		if _play_time_left <= 0.0:
			_at_play_spot = false
			_stand_pose()
			_pick_next_spot(position)


var _walk_paused_resume := false


# --- reactions ---------------------------------------------------------------

func _on_quest_completed(quest: ActiveQuest) -> void:
	if quest.data.kid != station_id or mode == Mode.ARRIVING:
		return
	if String(quest.data.id).begins_with("dinner"):
		_show_plate()
	# Cheer: a happy squash and stretch.
	var tw := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual_root, "scale", Vector3(0.9, 1.2, 0.9), 0.08)
	tw.tween_property(visual_root, "scale", Vector3.ONE, 0.6)


func _show_plate() -> void:
	if _plate != null:
		return
	_plate = Node3D.new()
	_plate.name = "Plate"
	_plate.position = Vector3(0.0, 0.0, 0.55)
	PlaceholderFactory.box(_plate, "Dish", Vector3(0.36, 0.03, 0.36), Vector3(0, 0.82, 0), Color(0.97, 0.97, 0.97), 0.012)
	PlaceholderFactory.box(_plate, "Pasta", Vector3(0.22, 0.07, 0.22), Vector3(0, 0.85, 0), Color(0.98, 0.82, 0.4), 0.03)
	PlaceholderFactory.box(_plate, "Sauce", Vector3(0.1, 0.04, 0.1), Vector3(0, 0.92, 0), Color(0.85, 0.28, 0.2), 0.02)
	get_parent().add_child(_plate)
	_plate.global_position = global_position + Vector3(0.0, 0.0, 0.55)
