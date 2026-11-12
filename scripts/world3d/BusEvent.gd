class_name BusEvent
extends Node3D
## Plays the school-bus event in the 3D world: the yellow bus drives in, the two kids hop out, walk through
## the yard and the door to their chairs. The timing and the consequences live in EventManager (logic).

var _bus: Node3D
var _kids: Array[Kid3D] = []
var _seated := 0
var _tween: Tween


func _ready() -> void:
	EventManager.bus_arrival_requested.connect(_on_bus_arrival)
	EventManager.bus_departure_requested.connect(_on_bus_departure)
	EventManager.event_reset.connect(_clear)


func _on_bus_arrival() -> void:
	_clear()
	_bus = ModelLoader.spawn("Prop_Bus")
	_bus.position = Vector3(HouseLayout.BUS_ROAD_X, 0.0, HouseLayout.BUS_START_Z)
	add_child(_bus)
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_bus, "position:z", HouseLayout.BUS_STOP_Z, 3.5)
	_tween.tween_interval(0.4)
	_tween.tween_callback(_spawn_kids)


func _spawn_kids() -> void:
	var delay := 0.0
	for def in HouseLayout.KIDS:
		var seat: Vector2 = def["seat"]
		var kid := Kid3D.new()
		kid.name = String(def["id"])
		get_parent().get_node("House/Furniture").add_child(kid)
		kid.setup({
			"id": def["id"], "name": def["name"], "model": def["model"],
			"cell": seat - Vector2(0.5, 0.5), "size": Vector2.ONE, "height": 1.2,
			"solid": false, "shadow": true, "bubble": 1.8, "zone_margin": 0.9,
		})
		kid.seated.connect(_on_kid_seated)
		_kids.append(kid)
		var z: float = def["door_z"]
		var waypoints: Array[Vector3] = [
			Vector3(15.0, 0.0, z),
			Vector3(12.5, 0.0, z),
			Vector3(seat.x, 0.0, z),
			Vector3(seat.x, 0.0, seat.y),
		]
		kid.walk_to_seat(Vector3(HouseLayout.BUS_ROAD_X - 1.4, 0.0, z), waypoints, delay)
		delay += 0.9


func _on_kid_seated() -> void:
	_seated += 1
	if _seated >= HouseLayout.KIDS.size():
		EventManager.kids_seated()


func _on_bus_departure() -> void:
	if _bus == null:
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_interval(1.0)
	_tween.tween_property(_bus, "position:z", HouseLayout.BUS_EXIT_Z, 3.5)
	_tween.tween_callback(_bus.queue_free)


func _clear() -> void:
	if _tween != null:
		_tween.kill()
	if is_instance_valid(_bus):
		_bus.queue_free()
	_bus = null
	for kid in _kids:
		if is_instance_valid(kid):
			kid.remove_from_group("stations")
			kid.queue_free()
	_kids.clear()
	_seated = 0
