class_name StationIndicator
extends Node3D
## Floating, camera-facing feedback above a station: a bubble with the icon of the item involved
## (or "!") while a quest needs this station, and a rounded progress bar while a player works here.

const BUBBLE_SHADER := preload("res://shaders/billboard_bubble.gdshader")
const BAR_SHADER := preload("res://shaders/billboard_bar.gdshader")

var _bubble_root: Node3D
var _bubble: MeshInstance3D
var _icon: Sprite3D
var _mark: Label3D
var _bar: MeshInstance3D
var _bar_mat: ShaderMaterial
var _bubble_mat: ShaderMaterial
var _shown := false
var _focused := false
var _t := 0.0
var _pop: Tween


func _ready() -> void:
	_bubble_root = Node3D.new()
	_bubble_root.name = "Bubble"
	_bubble_root.scale = Vector3.ZERO
	add_child(_bubble_root)

	_bubble_mat = ShaderMaterial.new()
	_bubble_mat.shader = BUBBLE_SHADER
	_bubble_mat.render_priority = 1
	var quad := QuadMesh.new()
	quad.size = Vector2(0.62, 0.62)
	_bubble = MeshInstance3D.new()
	_bubble.mesh = quad
	_bubble.material_override = _bubble_mat
	_bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bubble_root.add_child(_bubble)

	_icon = Sprite3D.new()
	_icon.pixel_size = 0.0034
	_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_icon.shaded = false
	_icon.no_depth_test = true
	_icon.render_priority = 2
	_icon.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_icon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bubble_root.add_child(_icon)

	_mark = Label3D.new()
	_mark.text = "!"
	_mark.font_size = 110
	_mark.pixel_size = 0.005
	_mark.modulate = Color(1.0, 0.55, 0.1)
	_mark.outline_size = 0
	_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mark.no_depth_test = true
	_mark.render_priority = 2
	_bubble_root.add_child(_mark)

	_bar_mat = ShaderMaterial.new()
	_bar_mat.shader = BAR_SHADER
	_bar_mat.render_priority = 3
	var bar_quad := QuadMesh.new()
	bar_quad.size = Vector2(0.9, 0.16)
	_bar = MeshInstance3D.new()
	_bar.mesh = bar_quad
	_bar.material_override = _bar_mat
	_bar.position = Vector3(0.0, -0.55, 0.0)
	_bar.visible = false
	_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bar)


func _process(delta: float) -> void:
	_t += delta
	_bubble_root.position.y = 0.32 + sin(_t * 3.0) * 0.05


## needed = a quest wants this station now. icon = texture of the item involved (may be null -> "!").
func set_task(needed: bool, icon: Texture2D, focused: bool) -> void:
	if icon != _icon.texture:
		_icon.texture = icon
	_icon.visible = icon != null
	_mark.visible = icon == null
	_focused = focused
	if needed != _shown:
		_shown = needed
		_animate_pop()
	elif _shown:
		var target := Vector3.ONE * (1.25 if focused else 1.0)
		_bubble_root.scale = _bubble_root.scale.lerp(target, 0.25)


func set_progress(ratio: float, show: bool) -> void:
	_bar.visible = show
	if show:
		_bar_mat.set_shader_parameter("progress", clampf(ratio, 0.0, 1.0))


func _animate_pop() -> void:
	if _pop != null:
		_pop.kill()
	_pop = create_tween()
	_pop.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop.tween_property(_bubble_root, "scale", Vector3.ONE if _shown else Vector3.ZERO, 0.35)
