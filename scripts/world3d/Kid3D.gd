class_name Kid3D
extends Station3D
## One of the two kids. Walks from the bus to a chair, sits down, and then acts as a station:
## give the kid what it asked for (the quest logic knows the ids kid_a / kid_b).
## Cheers when one of its quests is completed; a served dinner appears on the table.

signal seated

const STEP_SPEED := 2.6
## Metres per full stride, for the leg swing while walking.
const STRIDE := 1.0

var kid_name := ""
var is_seated := false

var _walking := false
var _phase := 0.0
var _last_pos := Vector3.ZERO
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _knees: Array[Node3D] = []
var _plate: Node3D
var _walk_tween: Tween


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


## Starts walking along `waypoints` (the last one is the seat), then sits down.
func walk_to_seat(start: Vector3, waypoints: Array[Vector3], delay: float = 0.0) -> void:
	position = start
	visible = true
	_last_pos = start
	_walking = true
	if _walk_tween != null:
		_walk_tween.kill()
	_walk_tween = create_tween()
	if delay > 0.0:
		_walk_tween.tween_interval(delay)
	var from := start
	for wp in waypoints:
		var dir := wp - from
		dir.y = 0.0
		var duration := maxf(dir.length() / STEP_SPEED, 0.05)
		_walk_tween.tween_callback(_face.bind(dir))
		_walk_tween.tween_property(self, "position", wp, duration)
		from = wp
	_walk_tween.tween_callback(_sit)


func _face(dir: Vector3) -> void:
	model.rotation.y = atan2(dir.x, dir.z)


func _sit() -> void:
	_walking = false
	is_seated = true
	model.rotation.y = 0.0 # facing the table (south)
	for leg in _legs:
		leg.rotation.x = -1.5 # thighs forward on the chair
	for knee in _knees:
		knee.rotation.x = 1.5 # shins hang down
	for arm in _arms:
		arm.rotation.x = -0.5
	model.position.y = -0.04
	seated.emit()


func _process(delta: float) -> void:
	super._process(delta)
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


func _on_quest_completed(quest: ActiveQuest) -> void:
	if quest.data.kid != station_id or not is_seated:
		return
	if String(quest.data.id).begins_with("dinner"):
		_show_plate()
	# Cheer: a happy hop.
	var tw := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	visual_root.position.y = 0.0
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
	add_child(_plate)
