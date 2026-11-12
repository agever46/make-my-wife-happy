extends CanvasLayer
## Playful Overcooked-style HUD, built in code: rounded colourful panels, a mood portrait of the wife next to
## the Wife-O-Meter, coin counter, round clock, quest tickets with item icons, and big result screens.

const WIFE_FACES := {
	&"happy": preload("res://assets/characters/wife_happy.png"),
	&"neutral": preload("res://assets/characters/wife_neutral.png"),
	&"angry": preload("res://assets/characters/wife_angry.png"),
}
const FACE_REGION := Rect2(62, 0, 100, 100)

const CREAM := Color(1.0, 0.96, 0.87)
const ORANGE := Color(1.0, 0.6, 0.18)
const BROWN := Color(0.33, 0.2, 0.14)
const GOOD := Color(0.36, 0.84, 0.4)
const BAD := Color(0.96, 0.32, 0.3)

var _root: Control
var _meter: ProgressBar
var _meter_fill: StyleBoxFlat
var _face: TextureRect
var _face_mood: StringName = &""
var _money: Label
var _clock: Label
var _clock_panel: PanelContainer
var _tickets: VBoxContainer
var _dim: ColorRect
var _result: PanelContainer
var _result_title: Label
var _result_sub: Label
var _stars: StarRow
## quest uid -> { panel, hint, bar, fill, quest }
var _ticket_nodes := {}


# A row of three painted stars.
class StarRow extends Control:
	var count := 0

	func _init() -> void:
		custom_minimum_size = Vector2(240, 70)

	func _draw() -> void:
		for i in 3:
			var c := Vector2(40.0 + i * 80.0, 36.0)
			var pts := PackedVector2Array()
			for k in 10:
				var r := 32.0 if k % 2 == 0 else 14.0
				var a := -PI / 2.0 + k * PI / 5.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			var on := i < count
			draw_colored_polygon(pts, Color(1.0, 0.82, 0.2) if on else Color(0.55, 0.5, 0.55, 0.6))
			var outline := pts.duplicate()
			outline.append(pts[0])
			draw_polyline(outline, Color(0.7, 0.4, 0.1) if on else Color(0.3, 0.27, 0.3), 3.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_top_left()
	_build_clock()
	_build_tickets()
	_build_result()

	GameManager.happiness_changed.connect(_on_happiness_changed)
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.day_won.connect(_on_day_won)
	GameManager.game_over.connect(_on_game_over)
	QuestManager.quest_added.connect(_on_quest_added)
	QuestManager.quest_step_changed.connect(_on_quest_step_changed)
	QuestManager.quest_completed.connect(_on_quest_done.bind(true))
	QuestManager.quest_failed.connect(_on_quest_done.bind(false))
	QuestManager.quests_cleared.connect(_clear_tickets)
	_on_happiness_changed(GameManager.wife_happiness, GameManager.wife_happiness)
	_on_money_changed(GameManager.money, GameManager.money)
	_on_time_changed(int(GameManager.DAY_LENGTH))


func _process(_delta: float) -> void:
	for uid in _ticket_nodes:
		var entry: Dictionary = _ticket_nodes[uid]
		var quest: ActiveQuest = entry["quest"]
		var ratio := quest.patience_ratio()
		var bar: ProgressBar = entry["bar"]
		bar.value = ratio
		(entry["fill"] as StyleBoxFlat).bg_color = BAD.lerp(GOOD, ratio)
		# The ticket wobbles when patience is nearly gone.
		var panel: Control = entry["panel"]
		panel.rotation = sin(Time.get_ticks_msec() / 60.0) * 0.025 if ratio < 0.25 else 0.0


# --- building ----------------------------------------------------------------

func _style(bg: Color, border: Color, radius: int, border_width: int = 4, shadow: bool = true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(10)
	if shadow:
		s.shadow_color = Color(0, 0, 0, 0.3)
		s.shadow_size = 6
		s.shadow_offset = Vector2(0, 4)
	return s


func _label(text: String, size: int, color: Color = BROWN, outline: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.05))
	return l


func _build_top_left() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(18, 14)
	row.add_theme_constant_override("separation", 12)
	_root.add_child(row)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(CREAM, ORANGE, 30))
	row.add_child(panel)
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	panel.add_child(inner)

	var portrait := PanelContainer.new()
	portrait.add_theme_stylebox_override("panel", _style(Color(0.95, 0.85, 0.7), BROWN, 26, 3, false))
	portrait.clip_contents = true
	inner.add_child(portrait)
	_face = TextureRect.new()
	_face.custom_minimum_size = Vector2(56, 56)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_face.pivot_offset = Vector2(28, 28)
	portrait.add_child(_face)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	inner.add_child(col)
	col.add_child(_label("WIFE-O-METER", 15, ORANGE.darkened(0.25)))
	_meter = ProgressBar.new()
	_meter.custom_minimum_size = Vector2(230, 22)
	_meter.max_value = GameManager.MAX_HAPPINESS
	_meter.show_percentage = false
	_meter_fill = _style(GOOD, Color(1, 1, 1, 0.5), 13, 2, false)
	_meter_fill.set_content_margin_all(0)
	var meter_bg := _style(Color(0.3, 0.2, 0.18), BROWN, 13, 3, false)
	meter_bg.set_content_margin_all(0)
	_meter.add_theme_stylebox_override("background", meter_bg)
	_meter.add_theme_stylebox_override("fill", _meter_fill)
	col.add_child(_meter)

	var coin_panel := PanelContainer.new()
	coin_panel.add_theme_stylebox_override("panel", _style(Color(1.0, 0.85, 0.3), Color(0.85, 0.55, 0.1), 26))
	row.add_child(coin_panel)
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 8)
	coin_panel.add_child(coin_row)
	var coin := PanelContainer.new()
	coin.custom_minimum_size = Vector2(38, 38)
	var coin_style := _style(Color(1.0, 0.7, 0.15), Color(0.7, 0.4, 0.05), 19, 3, false)
	coin_style.set_content_margin_all(0)
	coin.add_theme_stylebox_override("panel", coin_style)
	var coin_label := _label("$", 22, Color(0.6, 0.35, 0.05))
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin.add_child(coin_label)
	coin_row.add_child(coin)
	_money = _label("0", 28, BROWN)
	_money.custom_minimum_size = Vector2(54, 0)
	coin_row.add_child(_money)


func _build_clock() -> void:
	_clock_panel = PanelContainer.new()
	_clock_panel.add_theme_stylebox_override("panel", _style(CREAM, Color(0.35, 0.65, 0.95), 26))
	_clock_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_clock_panel.position = Vector2(-70, 14)
	_clock_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.add_child(_clock_panel)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_clock_panel.add_child(box)
	box.add_child(_label("TIME", 14, Color(0.35, 0.65, 0.95).darkened(0.2)))
	_clock = _label("2:00", 32, BROWN)
	box.add_child(_clock)
	_clock_panel.pivot_offset = Vector2(70, 22)


func _build_tickets() -> void:
	_tickets = VBoxContainer.new()
	_tickets.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_tickets.position = Vector2(-264, 14)
	_tickets.custom_minimum_size = Vector2(250, 0)
	_tickets.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_tickets.add_theme_constant_override("separation", 8)
	_root.add_child(_tickets)


func _build_result() -> void:
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.05, 0.03, 0.1, 0.6)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	_root.add_child(_dim)

	_result = PanelContainer.new()
	_result.add_theme_stylebox_override("panel", _style(CREAM, ORANGE, 44, 8))
	_result.set_anchors_preset(Control.PRESET_CENTER)
	_result.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_result.grow_vertical = Control.GROW_DIRECTION_BOTH
	_result.visible = false
	_root.add_child(_result)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	col.custom_minimum_size = Vector2(520, 0)
	_result.add_child(col)
	_result_title = _label("", 56, Color.WHITE, 12)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_result_title)
	_stars = StarRow.new()
	var star_center := CenterContainer.new()
	star_center.add_child(_stars)
	col.add_child(star_center)
	_result_sub = _label("", 26, BROWN)
	_result_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_result_sub)
	_result.pivot_offset = Vector2(300, 150)


# --- reacting to the game ----------------------------------------------------

func _mood_for(ratio: float) -> StringName:
	if ratio >= 0.66:
		return &"happy"
	if ratio < 0.33:
		return &"angry"
	return &"neutral"


func _on_happiness_changed(new_value: float, old_value: float) -> void:
	_meter.value = new_value
	var ratio := GameManager.happiness_ratio()
	_meter_fill.bg_color = BAD.lerp(Color(1.0, 0.8, 0.25), clampf(ratio * 2.0, 0.0, 1.0)).lerp(GOOD, clampf(ratio * 2.0 - 1.0, 0.0, 1.0))
	var mood := _mood_for(ratio)
	if mood != _face_mood:
		_face_mood = mood
		var atlas := AtlasTexture.new()
		atlas.atlas = WIFE_FACES[mood]
		atlas.region = FACE_REGION
		_face.texture = atlas
		_bounce(_face)
	elif absf(new_value - old_value) > 5.0:
		_bounce(_face)


func _on_money_changed(new_value: int, old_value: int) -> void:
	_money.text = str(new_value)
	if new_value > old_value:
		_money.pivot_offset = _money.size * 0.5
		_bounce(_money)


func _on_time_changed(seconds_left: int) -> void:
	_clock.text = "%d:%02d" % [seconds_left / 60, seconds_left % 60]
	var urgent := seconds_left <= 15
	_clock.add_theme_color_override("font_color", BAD if urgent else BROWN)
	if urgent and seconds_left > 0:
		_bounce(_clock_panel, 1.12)


func _on_state_changed(new_state: int, _old_state: int) -> void:
	match new_state:
		GameManager.GameState.PAUSED:
			_show_result("PAUSED", Color(0.4, 0.7, 1.0), -1, "Press Esc to continue")
		GameManager.GameState.PLAYING, GameManager.GameState.MENU:
			_hide_result()


func _on_day_won(stars: int, final_score: int) -> void:
	_show_result("DAY COMPLETE!", GOOD, stars, "Score: %d\nPress Enter for the next day" % final_score)


func _on_game_over(_final_score: int) -> void:
	_show_result("GAME OVER", BAD, 0, "She is NOT happy.\nPress Enter to try again")


func _show_result(title: String, color: Color, stars: int, sub: String) -> void:
	_result.add_theme_stylebox_override("panel", _style(CREAM, color, 44, 8))
	_result_title.text = title
	_result_title.add_theme_color_override("font_color", color.lightened(0.3))
	_stars.count = maxi(stars, 0)
	_stars.queue_redraw()
	_stars.get_parent().visible = stars >= 0
	_result_sub.text = sub
	_dim.visible = true
	_result.visible = true
	_result.scale = Vector2(0.6, 0.6)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_result, "scale", Vector2.ONE, 0.4)


func _hide_result() -> void:
	_dim.visible = false
	_result.visible = false


func _bounce(node: Control, amount: float = 1.25) -> void:
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2(amount, amount)
	var tw := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, 0.5)


# --- quest tickets -----------------------------------------------------------

func _on_quest_added(quest: ActiveQuest) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(CREAM, ORANGE, 24))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var icon_bg := PanelContainer.new()
	icon_bg.add_theme_stylebox_override("panel", _style(Color(1.0, 0.9, 0.7), ORANGE, 20, 3, false))
	row.add_child(icon_bg)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = Item3D.ICONS.get(quest.data.icon_item)
	icon_bg.add_child(icon)

	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(150, 0)
	col.add_theme_constant_override("separation", 3)
	row.add_child(col)
	var title := _label(quest.data.title, 15)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	var hint := _label(quest.hint(), 12, BROWN.lightened(0.25))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(hint)
	var bar := ProgressBar.new()
	bar.max_value = 1.0
	bar.value = 1.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)
	var fill := _style(GOOD, Color(1, 1, 1, 0.6), 7, 2, false)
	fill.set_content_margin_all(0)
	var bg := _style(Color(0.3, 0.2, 0.18), BROWN, 7, 2, false)
	bg.set_content_margin_all(0)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	col.add_child(bar)

	panel.modulate.a = 0.0
	_tickets.add_child(panel)
	_ticket_nodes[quest.uid] = {"panel": panel, "hint": hint, "bar": bar, "fill": fill, "quest": quest}
	# Pop in once the container has laid the panel out.
	await get_tree().process_frame
	if is_instance_valid(panel):
		panel.pivot_offset = panel.size * 0.5
		panel.scale = Vector2(0.6, 0.6)
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel, "scale", Vector2.ONE, 0.4)
		tw.tween_property(panel, "modulate:a", 1.0, 0.2)


func _on_quest_step_changed(quest: ActiveQuest) -> void:
	if _ticket_nodes.has(quest.uid):
		var hint: Label = _ticket_nodes[quest.uid]["hint"]
		hint.text = quest.hint()
		_bounce(_ticket_nodes[quest.uid]["panel"], 1.06)


func _on_quest_done(quest: ActiveQuest, success: bool) -> void:
	if not _ticket_nodes.has(quest.uid):
		return
	var panel: Control = _ticket_nodes[quest.uid]["panel"]
	_ticket_nodes.erase(quest.uid)
	panel.pivot_offset = panel.size * 0.5
	panel.modulate = Color(0.6, 1.0, 0.6) if success else Color(1.0, 0.5, 0.5)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "scale", Vector2(1.15, 1.15) if success else Vector2(0.6, 0.6), 0.3)
	tw.tween_property(panel, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(panel.queue_free)


func _clear_tickets() -> void:
	for uid in _ticket_nodes:
		(_ticket_nodes[uid]["panel"] as Control).queue_free()
	_ticket_nodes.clear()
