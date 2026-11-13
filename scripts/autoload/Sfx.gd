extends Node
## Sound effects (autoload). Files live in audio/<id>.ogg; a missing file is simply silent.
## It listens to the GameManager / QuestManager signals by itself; the player calls pickup / drop / footstep / set_working.
##   Sfx.play("pickup")

const DIR := "res://audio/"
const WARN_RATIO := 0.25        # below this share of the Wife-O-Meter the warning pulse starts
const WARN_EVERY := 3.0         # seconds between warning pulses
const MAX_VOICES := 12

var _cache := {}
var _voices: Array[AudioStreamPlayer] = []
var _loop: AudioStreamPlayer
var _workers := {}              # player instance id -> true while that player works at a station
var _warn_clock := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in MAX_VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_voices.append(p)
	_loop = AudioStreamPlayer.new()
	_loop.volume_db = -8.0
	add_child(_loop)
	GameManager.happiness_changed.connect(_on_happiness_changed)
	GameManager.day_won.connect(func(_stars: int, _score: int): _stop_work(); play("day_win"))
	GameManager.game_over.connect(func(_score: int): _stop_work(); play("game_over"))
	GameManager.game_paused.connect(func(): play("ui_click"))
	GameManager.game_resumed.connect(func(): play("ui_click"))
	GameManager.money_changed.connect(func(new_value: int, old_value: int):
		if new_value > old_value:
			get_tree().create_timer(0.3).timeout.connect(func(): play("coin")))
	GameManager.tick.connect(_on_tick)
	QuestManager.quest_added.connect(func(_q): play("quest_new"))
	QuestManager.quest_step_changed.connect(func(_q): play("step_done"))
	QuestManager.quest_completed.connect(func(_q): play("quest_complete", -2.0); play("wife_happy", -4.0))
	QuestManager.quest_failed.connect(func(_q): play("quest_failed"))
	QuestManager.world_reset.connect(_stop_work)


## A one-shot. `pitch_jitter` varies the pitch a little so repeats (footsteps) do not sound mechanical.
func play(id: String, volume_db: float = 0.0, pitch_jitter: float = 0.0) -> void:
	var stream := _stream(id)
	if stream == null:
		return
	var voice: AudioStreamPlayer = null
	for p in _voices:
		if not p.playing:
			voice = p
			break
	if voice == null:
		voice = _voices[0]
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	voice.play()


func pickup() -> void:
	play("pickup", -2.0, 0.05)


func drop() -> void:
	play("drop", -2.0, 0.05)


func footstep() -> void:
	play("step_wood", -12.0, 0.12)


## Called by a player every frame it works (or stops working) at a station; the loop plays while anyone works.
func set_working(player: Object, working: bool) -> void:
	var key := player.get_instance_id()
	if working:
		_workers[key] = true
	else:
		_workers.erase(key)
	if _workers.is_empty():
		_loop.stop()
	elif not _loop.playing:
		var stream := _stream("work_loop")
		if stream != null:
			_loop.stream = stream
			_loop.play()


func _stop_work() -> void:
	_workers.clear()
	_loop.stop()


func _on_happiness_changed(new_value: float, old_value: float) -> void:
	if new_value < old_value - 5.0:
		play("wife_angry", -2.0)
	var warn := GameManager.MAX_HAPPINESS * WARN_RATIO
	if new_value < warn and old_value >= warn:
		play("meter_warning")
		_warn_clock = 0.0


func _on_tick(delta: float) -> void:
	if GameManager.happiness_ratio() < WARN_RATIO:
		_warn_clock += delta
		if _warn_clock >= WARN_EVERY:
			_warn_clock = 0.0
			play("meter_warning", -4.0)


func _stream(id: String) -> AudioStream:
	if not _cache.has(id):
		var path := DIR + id + ".ogg"
		var stream: AudioStream = load(path) if ResourceLoader.exists(path) else null
		if stream != null and id == "work_loop" and "loop" in stream:
			stream = stream.duplicate()
			stream.loop = true
		_cache[id] = stream
	return _cache[id]
