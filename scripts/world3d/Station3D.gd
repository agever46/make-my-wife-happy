class_name Station3D
extends Node3D
## A piece of furniture or a character in the 3D house.
## With an id it is an interactive station: an Area3D "InteractZone" detects players, the station lights up
## (rim glow + elastic scale bounce) while a player is inside, and a StationIndicator floats above it.
## Without an id it is plain scenery (still solid unless told otherwise).

const RIM_SHADER := preload("res://shaders/rim_glow.gdshader")
## Physics layers: 1 = players, 2 = world (walls, furniture), 3 = interact zones.
const LAYER_WORLD := 2
const LAYER_ZONE := 4

var station_id: StringName = &""
var players_in_zone: Array[Node3D] = []
var visual_root: Node3D
var model: Node3D

var _rim: ShaderMaterial
var _indicator: StationIndicator
var _glow_tween: Tween
var _bounce_tween: Tween
var needed_only := false
var _progress := 0.0
var _progress_stamp := -100000


func setup(def: Dictionary) -> void:
	station_id = def.get("id", &"")
	needed_only = def.get("needed_only", false)
	var size: Vector2 = def["size"]
	var height: float = def.get("height", 1.0)
	name = String(station_id) if station_id != &"" else String(def["model"])
	position = Grid.center(def["cell"], size)

	visual_root = Node3D.new()
	visual_root.name = "Visual"
	add_child(visual_root)
	model = ModelLoader.spawn(def["model"])
	model.rotation.y = deg_to_rad(def.get("rot", 0.0))
	visual_root.add_child(model)

	if def.get("shadow", true):
		add_child(ContactShadow.make(size, 0.4, 0.5))
	if def.get("solid", true):
		_add_collider(size, height)
	if station_id != &"":
		add_to_group("stations")
		_add_zone(size, def.get("zone_margin", 0.85))
		_indicator = StationIndicator.new()
		_indicator.position = Vector3(0.0, def.get("bubble", height + 0.6), 0.0)
		add_child(_indicator)
		_rim = ShaderMaterial.new()
		_rim.shader = RIM_SHADER
		_rim.set_shader_parameter("strength", 0.0)
		_apply_overlay(visual_root, _rim)


func has_player(player: Node3D) -> bool:
	return players_in_zone.has(player)


func show_progress(ratio: float) -> void:
	_progress = ratio
	_progress_stamp = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	if _indicator == null:
		return
	var needed := QuestManager.is_station_needed(station_id)
	if needed_only:
		visual_root.visible = QuestManager.is_station_involved(station_id) # e.g. the stain exists while its quest is active
	var icon: Texture2D = null
	if needed:
		icon = Item3D.ICONS.get(QuestManager.icon_item_for(station_id))
	_indicator.set_task(needed, icon, not players_in_zone.is_empty())
	_indicator.set_progress(_progress, Time.get_ticks_msec() - _progress_stamp < 150)


# --- construction ------------------------------------------------------------

func _add_collider(size: Vector2, height: float) -> void:
	var body := StaticBody3D.new()
	body.name = "Collider"
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, height, size.y)
	shape.shape = box
	shape.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(shape)
	add_child(body)


func _add_zone(size: Vector2, margin: float) -> void:
	var zone := Area3D.new()
	zone.name = "InteractZone"
	zone.collision_layer = LAYER_ZONE
	zone.collision_mask = 1 # players
	zone.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x + margin * 2.0, 2.0, size.y + margin * 2.0)
	shape.shape = box
	shape.position = Vector3(0.0, 1.0, 0.0)
	zone.add_child(shape)
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	add_child(zone)


func _apply_overlay(node: Node, material: Material) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_overlay = material
		_apply_overlay(child, material)


# --- highlight ---------------------------------------------------------------

func _on_body_entered(body: Node3D) -> void:
	if not players_in_zone.has(body):
		players_in_zone.append(body)
	if players_in_zone.size() == 1:
		_set_highlight(true)


func _on_body_exited(body: Node3D) -> void:
	players_in_zone.erase(body)
	if players_in_zone.is_empty():
		_set_highlight(false)


func _set_highlight(on: bool) -> void:
	if _glow_tween != null:
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.tween_property(_rim, "shader_parameter/strength", 1.3 if on else 0.0, 0.2)
	if on:
		if _bounce_tween != null:
			_bounce_tween.kill()
		visual_root.scale = Vector3(1.1, 0.9, 1.1)
		_bounce_tween = create_tween()
		_bounce_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		_bounce_tween.tween_property(visual_root, "scale", Vector3.ONE, 0.55)
