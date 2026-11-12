extends CanvasLayer
## Game-master console for testing (Autoload: DebugConsole). Debug builds only.
## Open / close: F1, the ` key, or type the word "debug". Esc closes it. Type `help` for the commands.
## The game is paused while the console is open.

const MAX_LOG_LINES := 200
const HELP := {
	"help": "help [command]  - list commands",
	"status": "status  - show happiness, money, time, state, quests",
	"happy": "happy <0-100>  - set the Wife-O-Meter",
	"money": "money <n>  - set the money",
	"time": "time <seconds>  - set the seconds left in the day",
	"quest": "quest <coffee|trash|keys|random>  - start a quest now",
	"quests": "quests  - list active quests and quest ids",
	"clear": "clear  - remove all quests (no reward, no penalty)",
	"win": "win  - finish the day now (victory)",
	"lose": "lose  - game over now",
	"restart": "restart  - start a new day",
	"god": "god [on|off]  - the Wife-O-Meter can not drop",
	"tp": "tp <station id>  or  tp <x> <z>  - teleport player 1 (ids: coffee_machine fridge trash_can dumpster wife)",
	"give": "give <coffee|coffee_milk|trash_bag|keys>  - put an item in player 1's hands",
	"speed": "speed <m/s>  - player 1 walking speed (default 5.4)",
	"timescale": "timescale <x>  - game speed (1 = normal)",
	"close": "close  - close the console",
}

var _panel: PanelContainer
var _log: RichTextLabel
var _line: LineEdit
var _open := false
var _was_paused := false
var _history: Array[String] = []
var _history_pos := 0
var _typed := ""
var _typed_time := 0.0


func _ready() -> void:
	if not OS.is_debug_build():
		set_process_input(false)
		return
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -250.0
	_panel.offset_left = 12.0
	_panel.offset_right = -12.0
	_panel.offset_bottom = -12.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.09, 0.92)
	style.border_color = Color(1.0, 0.6, 0.18)
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_panel.add_child(col)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 15)
	col.add_child(_log)
	_line = LineEdit.new()
	_line.placeholder_text = "type a command, e.g. help"
	_line.add_theme_font_size_override("font_size", 16)
	_line.text_submitted.connect(_on_submitted)
	col.add_child(_line)
	_print("[color=#ffb347][b]Debug console[/b][/color] - type [b]help[/b]. F1 / ` / Esc closes.")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := event as InputEventKey
	if key.physical_keycode == KEY_F1 or key.physical_keycode == KEY_QUOTELEFT:
		toggle()
		get_viewport().set_input_as_handled()
		return
	if _open:
		if key.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_UP:
			_step_history(-1)
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_DOWN:
			_step_history(1)
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_TAB:
			_autocomplete()
			get_viewport().set_input_as_handled()
		return
	# Closed: typing the word "debug" opens the console.
	var now := Time.get_ticks_msec() / 1000.0
	if now - _typed_time > 1.5:
		_typed = ""
	_typed_time = now
	if key.keycode >= KEY_A and key.keycode <= KEY_Z:
		_typed += char(key.keycode).to_lower()
		_typed = _typed.right(5)
		if _typed == "debug":
			_typed = ""
			open()


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func open() -> void:
	if _open or not OS.is_debug_build():
		return
	_open = true
	_was_paused = get_tree().paused
	get_tree().paused = true
	_panel.visible = true
	_line.clear()
	_line.grab_focus.call_deferred()


func close() -> void:
	if not _open:
		return
	_open = false
	_panel.visible = false
	_line.release_focus()
	get_tree().paused = _was_paused


func is_open() -> bool:
	return _open


# --- commands ----------------------------------------------------------------

func _on_submitted(line: String) -> void:
	_line.clear()
	line = line.strip_edges()
	if line == "":
		return
	_history.append(line)
	_history_pos = _history.size()
	_print("[color=#8fd3ff]> %s[/color]" % line)
	execute(line)
	if _open:
		get_tree().paused = true # a command (restart, lose...) may have un-paused the tree
		_line.grab_focus.call_deferred()


## Runs one command line and logs the result. Public so tests and scripts can call it.
func execute(line: String) -> void:
	var parts := line.strip_edges().split(" ", false)
	if parts.is_empty():
		return
	var cmd := parts[0].to_lower()
	var args := parts.slice(1)
	match cmd:
		"help": _cmd_help(args)
		"status": _cmd_status()
		"happy": _cmd_happy(args)
		"money": _cmd_money(args)
		"time": _cmd_time(args)
		"quest": _cmd_quest(args)
		"quests": _cmd_quests()
		"clear":
			QuestManager.clear_quests()
			_print("All quests removed.")
		"win":
			GameManager.win_day()
			_print("Day won." if GameManager.state == GameManager.GameState.VICTORY else "Not possible right now (the game must be running).")
		"lose":
			GameManager.end_game()
			_print("Game over.")
		"restart":
			GameManager.start_game()
			_print("New day started.")
		"god": _cmd_god(args)
		"tp": _cmd_tp(args)
		"give": _cmd_give(args)
		"speed": _cmd_speed(args)
		"timescale": _cmd_timescale(args)
		"close": close()
		_: _error("Unknown command '%s'. Type help." % cmd)


func _cmd_help(args: PackedStringArray) -> void:
	if args.size() > 0 and HELP.has(args[0]):
		_print(HELP[args[0]])
		return
	for name in HELP:
		_print("  " + HELP[name])


func _cmd_status() -> void:
	_print("state=%s  happiness=%.1f  money=%d  time left=%ds  god=%s  quests=%d  players=%d" % [
		GameManager.GameState.keys()[GameManager.state], GameManager.wife_happiness, GameManager.money,
		GameManager.time_left(), GameManager.god_mode, QuestManager.active.size(), GameManager.player_count])


func _cmd_happy(args: PackedStringArray) -> void:
	if args.size() < 1 or not args[0].is_valid_float():
		_error("usage: happy <0-100>")
		return
	GameManager.set_happiness(args[0].to_float())
	_print("Wife-O-Meter = %.1f" % GameManager.wife_happiness)


func _cmd_money(args: PackedStringArray) -> void:
	if args.size() < 1 or not args[0].is_valid_int():
		_error("usage: money <n>")
		return
	GameManager.add_money(args[0].to_int() - GameManager.money)
	_print("money = %d" % GameManager.money)


func _cmd_time(args: PackedStringArray) -> void:
	if args.size() < 1 or not args[0].is_valid_float():
		_error("usage: time <seconds left>")
		return
	GameManager.set_time_left(args[0].to_float())
	_print("time left = %ds" % GameManager.time_left())


func _cmd_quest(args: PackedStringArray) -> void:
	if args.size() < 1:
		_error("usage: quest <id|random>  (see quests)")
		return
	if not GameManager.is_playing():
		_error("The game is not running.")
		return
	if args[0] == "random":
		var quest := QuestManager.spawn_random()
		_print("Started %s." % quest.data.id if quest != null else "No quest could be started (board full?).")
		return
	for data in QuestDB.all():
		if String(data.id) == args[0]:
			QuestManager.start_quest(data)
			_print("Started %s." % data.id)
			return
	_error("No quest '%s'. Type quests." % args[0])


func _cmd_quests() -> void:
	var ids: Array[String] = []
	for data in QuestDB.all():
		ids.append(String(data.id))
	_print("available: " + ", ".join(ids))
	if QuestManager.active.is_empty():
		_print("active: none")
	for quest in QuestManager.active:
		_print("active: %s  step %d/%d  patience %.0fs" % [quest.data.id, quest.step_index + 1, quest.data.steps.size(), quest.time_left])


func _cmd_god(args: PackedStringArray) -> void:
	if args.size() > 0:
		GameManager.god_mode = args[0] == "on"
	else:
		GameManager.god_mode = not GameManager.god_mode
	_print("god mode %s" % ("ON" if GameManager.god_mode else "off"))


func _player() -> Player3D:
	return get_tree().get_first_node_in_group("players") as Player3D


func _cmd_tp(args: PackedStringArray) -> void:
	var player := _player()
	if player == null:
		_error("No player in the scene.")
		return
	if args.size() == 1:
		for node in get_tree().get_nodes_in_group("stations"):
			var station := node as Station3D
			if station != null and String(station.station_id) == args[0]:
				player.global_position = station.global_position + Vector3(0.0, 0.0, 1.3)
				player.velocity = Vector3.ZERO
				_print("Teleported next to %s." % args[0])
				return
		_error("No station '%s'." % args[0])
	elif args.size() == 2 and args[0].is_valid_float() and args[1].is_valid_float():
		player.global_position = Vector3(args[0].to_float(), 0.0, args[1].to_float())
		player.velocity = Vector3.ZERO
		_print("Teleported to %s, %s." % [args[0], args[1]])
	else:
		_error("usage: tp <station id>  or  tp <x> <z>")


func _cmd_give(args: PackedStringArray) -> void:
	var player := _player()
	if player == null or args.size() < 1:
		_error("usage: give <item id>")
		return
	var id := StringName(args[0])
	if not Item3D.ICONS.has(id):
		_error("Unknown item. Items: %s" % ", ".join(Item3D.ICONS.keys().map(func(k): return String(k))))
		return
	var item := Item3D.create(id)
	var root := get_tree().get_first_node_in_group("item_root") as Node3D
	(root if root != null else player.get_parent()).add_child(item)
	player.give_item(item)
	_print("Gave %s." % id)


func _cmd_speed(args: PackedStringArray) -> void:
	var player := _player()
	if player == null or args.size() < 1 or not args[0].is_valid_float():
		_error("usage: speed <m/s>")
		return
	player.max_speed = clampf(args[0].to_float(), 0.5, 30.0)
	_print("speed = %.1f m/s" % player.max_speed)


func _cmd_timescale(args: PackedStringArray) -> void:
	if args.size() < 1 or not args[0].is_valid_float():
		_error("usage: timescale <x>")
		return
	Engine.time_scale = clampf(args[0].to_float(), 0.1, 10.0)
	_print("timescale = %.2f" % Engine.time_scale)


# --- helpers -----------------------------------------------------------------

func _print(text: String) -> void:
	if _log == null:
		return
	_log.append_text(text + "\n")


func _error(text: String) -> void:
	_print("[color=#ff7a7a]%s[/color]" % text)


func _step_history(direction: int) -> void:
	if _history.is_empty():
		return
	_history_pos = clampi(_history_pos + direction, 0, _history.size())
	_line.text = _history[_history_pos] if _history_pos < _history.size() else ""
	_line.caret_column = _line.text.length()


func _autocomplete() -> void:
	var text := _line.text.strip_edges().to_lower()
	if text == "" or text.contains(" "):
		return
	var matches: Array[String] = []
	for name in HELP:
		if name.begins_with(text):
			matches.append(name)
	if matches.size() == 1:
		_line.text = matches[0] + " "
		_line.caret_column = _line.text.length()
	elif matches.size() > 1:
		_print("  " + "  ".join(matches))
