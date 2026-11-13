class_name CameraRig
extends Node3D
## Angled camera for the diorama look (like Overcooked). It follows player 1 smoothly and stays inside the map,
## so the husband and the stations around him are big enough to see.
## Zoom: mouse wheel, or + / - keys. The zoom level is remembered between runs.

const SETTINGS_PATH := "user://settings.cfg"

@export var target := Vector3(11.0, 0.0, 5.0)
@export_range(30.0, 75.0) var pitch_degrees: float = 55.0
@export_range(20.0, 70.0) var fov: float = 38.0
@export var min_distance: float = 8.0
@export var max_distance: float = 25.0
@export var default_distance: float = 15.0
## How quickly the camera catches up with the player (higher = tighter).
@export var follow_speed: float = 5.0
@export var zoom_step: float = 1.5
## Metres of the map edge allowed to show beyond the map (so the walls are not cut off exactly at the border).
@export var edge_margin: float = 1.5
## The camera looks this many metres north of the player, so the back row (counters, fridge, couch) stays below the HUD.
@export var look_ahead_north: float = 1.6

var camera: Camera3D
var distance: float = 15.0
var _distance_goal: float = 15.0
var _focus := Vector3(11.0, 0.0, 5.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keep following / zooming while the console or pause is open
	distance = _load_distance()
	_distance_goal = distance
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = fov
	camera.current = true
	add_child(camera)
	_focus = _clamped_focus(_player_position() - Vector3(0.0, 0.0, look_ahead_north), distance)
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(-zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(zoom_step)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD]:
			_zoom(-zoom_step)
		elif event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			_zoom(zoom_step)


func set_distance(value: float) -> void:
	_distance_goal = clampf(value, min_distance, max_distance)
	_save_distance()


func _zoom(amount: float) -> void:
	set_distance(_distance_goal + amount)


func _process(delta: float) -> void:
	distance = lerpf(distance, _distance_goal, 1.0 - exp(-10.0 * delta))
	var wanted := _clamped_focus(_player_position() - Vector3(0.0, 0.0, look_ahead_north), distance)
	_focus = _focus.lerp(wanted, 1.0 - exp(-follow_speed * delta))
	_apply()


func _apply() -> void:
	var pitch := deg_to_rad(pitch_degrees)
	camera.position = _focus + Vector3(0.0, sin(pitch), cos(pitch)) * distance
	camera.rotation = Vector3(-pitch, 0.0, 0.0)


func _player_position() -> Vector3:
	var player := get_tree().get_first_node_in_group("players") as Node3D
	return player.global_position if player != null else target


## Keeps the view inside the map: half the visible width / depth is subtracted from the map edges.
func _clamped_focus(wanted: Vector3, dist: float) -> Vector3:
	var view := get_viewport().get_visible_rect().size
	var aspect := view.x / maxf(view.y, 1.0)
	var half_h := tan(deg_to_rad(fov * 0.5)) * dist
	var half_w := half_h * aspect
	var half_depth := half_h / sin(deg_to_rad(pitch_degrees))
	var map_w := float(String(HouseLayout.MAP[0]).length())
	var map_d := float(HouseLayout.MAP.size())
	return Vector3(
		_clamp_axis(wanted.x, half_w, map_w),
		0.0,
		_clamp_axis(wanted.z, half_depth, map_d))


func _clamp_axis(value: float, half_view: float, map_size: float) -> float:
	var lo := half_view - edge_margin
	var hi := map_size - half_view + edge_margin
	if lo > hi:
		return map_size * 0.5 # the whole map fits: keep it centred
	return clampf(value, lo, hi)


func _load_distance() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		return clampf(float(cfg.get_value("camera", "distance", default_distance)), min_distance, max_distance)
	return default_distance


func _save_distance() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH) # keep other settings (e.g. audio) if the file exists
	cfg.set_value("camera", "distance", _distance_goal)
	cfg.save(SETTINGS_PATH)
