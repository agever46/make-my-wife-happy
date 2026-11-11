extends CanvasLayer
## Heads-up display, built in code: Wife-O-Meter, money, quest tickets, pause / game-over text.

var _meter: ProgressBar
var _money: Label
var _tickets: VBoxContainer
var _overlay: Label
## quest uid -> { "panel": PanelContainer, "hint": Label, "bar": ProgressBar, "quest": ActiveQuest }
var _ticket_nodes := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var top := HBoxContainer.new()
	top.position = Vector2(20, 16)
	top.add_theme_constant_override("separation", 14)
	add_child(top)
	var caption := Label.new()
	caption.text = "WIFE-O-METER"
	top.add_child(caption)
	_meter = ProgressBar.new()
	_meter.custom_minimum_size = Vector2(360, 28)
	_meter.max_value = GameManager.MAX_HAPPINESS
	_meter.show_percentage = false
	top.add_child(_meter)
	_money = Label.new()
	top.add_child(_money)

	_tickets = VBoxContainer.new()
	_tickets.position = Vector2(1000, 16)
	_tickets.custom_minimum_size = Vector2(260, 0)
	_tickets.add_theme_constant_override("separation", 8)
	add_child(_tickets)

	_overlay = Label.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_overlay.add_theme_font_size_override("font_size", 48)
	_overlay.visible = false
	add_child(_overlay)

	GameManager.happiness_changed.connect(_on_happiness_changed)
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.state_changed.connect(_on_state_changed)
	QuestManager.quest_added.connect(_on_quest_added)
	QuestManager.quest_step_changed.connect(_on_quest_step_changed)
	QuestManager.quest_completed.connect(_remove_ticket)
	QuestManager.quest_failed.connect(_remove_ticket)
	QuestManager.quests_cleared.connect(_clear_tickets)
	_on_happiness_changed(GameManager.wife_happiness, GameManager.wife_happiness)
	_on_money_changed(GameManager.money, GameManager.money)


func _process(_delta: float) -> void:
	for uid in _ticket_nodes:
		var entry: Dictionary = _ticket_nodes[uid]
		var quest: ActiveQuest = entry["quest"]
		var bar: ProgressBar = entry["bar"]
		bar.value = quest.patience_ratio()
		bar.modulate = Color(1.0, 0.3, 0.3).lerp(Color(0.4, 1.0, 0.5), quest.patience_ratio())


func _on_happiness_changed(new_value: float, _old_value: float) -> void:
	_meter.value = new_value
	_meter.modulate = Color(1.0, 0.3, 0.3).lerp(Color(0.4, 1.0, 0.5), GameManager.happiness_ratio())


func _on_money_changed(new_value: int, _old_value: int) -> void:
	_money.text = "$ %d" % new_value


func _on_state_changed(new_state: int, _old_state: int) -> void:
	match new_state:
		GameManager.GameState.GAME_OVER:
			_overlay.text = "GAME OVER\nShe is NOT happy.\nPress Enter to try again"
			_overlay.visible = true
		GameManager.GameState.PAUSED:
			_overlay.text = "PAUSED"
			_overlay.visible = true
		_:
			_overlay.visible = false


func _on_quest_added(quest: ActiveQuest) -> void:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = quest.data.title
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(240, 0)
	box.add_child(title)
	var hint := Label.new()
	hint.text = "> " + quest.hint()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(240, 0)
	hint.add_theme_font_size_override("font_size", 12)
	box.add_child(hint)
	var bar := ProgressBar.new()
	bar.max_value = 1.0
	bar.value = 1.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(240, 10)
	box.add_child(bar)
	_tickets.add_child(panel)
	_ticket_nodes[quest.uid] = {"panel": panel, "hint": hint, "bar": bar, "quest": quest}


func _on_quest_step_changed(quest: ActiveQuest) -> void:
	if _ticket_nodes.has(quest.uid):
		var hint: Label = _ticket_nodes[quest.uid]["hint"]
		hint.text = "> " + quest.hint()


func _remove_ticket(quest: ActiveQuest) -> void:
	if _ticket_nodes.has(quest.uid):
		var panel: PanelContainer = _ticket_nodes[quest.uid]["panel"]
		panel.queue_free()
		_ticket_nodes.erase(quest.uid)


func _clear_tickets() -> void:
	for uid in _ticket_nodes:
		var panel: PanelContainer = _ticket_nodes[uid]["panel"]
		panel.queue_free()
	_ticket_nodes.clear()
