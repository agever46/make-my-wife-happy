class_name Wife3D
extends Station3D
## The wife on the couch. Her face follows the Wife-O-Meter: skin flushes red and the brows turn angry.
## Works with the placeholder or a Blender model, as long as the nodes are called Head, BrowL, BrowR (all optional).

var _head: MeshInstance3D
var _brow_l: Node3D
var _brow_r: Node3D
var _skin: StandardMaterial3D
var _shake := 0.0


func setup(def: Dictionary) -> void:
	super.setup(def)
	_head = model.find_child("Skull", true, false) as MeshInstance3D
	_brow_l = model.find_child("BrowL", true, false) as Node3D
	_brow_r = model.find_child("BrowR", true, false) as Node3D
	if _head != null and _head.material_override is StandardMaterial3D:
		_skin = (_head.material_override as StandardMaterial3D).duplicate()
		_head.material_override = _skin
	GameManager.happiness_changed.connect(_on_happiness_changed)


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


## Beside her head, to the right, so it stays below the top HUD and clear of her task icon.
func speech_anchor() -> Vector3:
	return Vector3(0.7, 1.45, 0.0)


func speech_side() -> float:
	return 1.0
