class_name SpeechBubble
extends Node3D
## A comic speech bubble above a character: the wife or a kid says what they want (the quest title),
## with the icon of the item involved. Pops in, stays a few seconds, pops out. One bubble per speaker.

const SHADER := preload("res://shaders/speech_bubble.gdshader")
const LIFETIME := 4.2
const PIXEL_SIZE := 0.0042
const PADDING := Vector2(0.34, 0.2)
const TAIL := 0.22

var _tween: Tween


## Makes `speaker` say `text` (replacing any bubble it already has). Returns the new bubble.
## `anchor` is where the tail tip points (relative to the speaker). side = -1 / 0 / +1: the bubble body extends
## to the left / centred / to the right of that point, so bubbles of neighbours do not cover each other.
static func say(speaker: Node3D, text: String, icon: Texture2D, border: Color, anchor: Vector3, side: float = 0.0) -> SpeechBubble:
	var old := speaker.get_node_or_null("SpeechBubble") as SpeechBubble
	if old != null:
		old.name = "SpeechBubbleOld"
		old.dismiss()
	var bubble := SpeechBubble.new()
	bubble.name = "SpeechBubble"
	bubble.position = anchor
	speaker.add_child(bubble)
	bubble._build(text, icon, border, side)
	return bubble


func _build(text: String, icon: Texture2D, border: Color, side: float) -> void:
	scale = Vector3.ZERO
	var label := Label3D.new()
	label.text = text
	label.font_size = 54
	label.pixel_size = PIXEL_SIZE
	label.width = 520.0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = Color(0.33, 0.2, 0.14)
	label.outline_size = 0
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 6
	label.shaded = false
	add_child(label)

	var icon_sprite: Sprite3D = null
	var icon_width := 0.0
	if icon != null:
		icon_sprite = Sprite3D.new()
		icon_sprite.texture = icon
		icon_sprite.pixel_size = 0.0050
		icon_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		icon_sprite.no_depth_test = true
		icon_sprite.render_priority = 5
		icon_sprite.shaded = false
		icon_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(icon_sprite)
		icon_width = icon.get_width() * icon_sprite.pixel_size + 0.12

	# The label measures itself on the next frame.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var text_size := label.get_aabb().size
	var body := Vector2(text_size.x + icon_width + PADDING.x * 2.0, maxf(text_size.y, 0.4) + PADDING.y * 2.0)
	body.y = maxf(body.y, icon.get_height() * 0.0050 + 0.2 if icon != null else 0.0)

	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.render_priority = 4
	mat.set_shader_parameter("body_size", body)
	mat.set_shader_parameter("tail", TAIL)
	# Tail near the end of the body that is closest to the speaker; the body extends to the chosen side.
	var tail_x := -side * (body.x * 0.5 - 0.4)
	mat.set_shader_parameter("tail_x", tail_x)
	mat.set_shader_parameter("border_color", border)
	var quad := QuadMesh.new()
	quad.size = Vector2(body.x, body.y + TAIL)
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The quad's origin is its centre; the bubble's origin (the tail tip) sits at its bottom edge.
	mesh.position = Vector3(-tail_x, (body.y + TAIL) * 0.5, 0.0)
	add_child(mesh)
	var body_center_y := TAIL + body.y * 0.5
	label.position = Vector3(icon_width * 0.5 - tail_x, body_center_y, 0.0)
	if icon_sprite != null:
		icon_sprite.position = Vector3(-body.x * 0.5 + PADDING.x + (icon_width - 0.12) * 0.5 - tail_x, body_center_y, 0.0)

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector3.ONE, 0.35)
	_tween.tween_interval(LIFETIME)
	_tween.tween_callback(dismiss)


func dismiss() -> void:
	if _tween != null:
		_tween.kill()
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.25)
	tw.tween_callback(queue_free)
