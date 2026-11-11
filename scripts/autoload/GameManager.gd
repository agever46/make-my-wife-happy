extends Node
## Global game state (Autoload: GameManager).
## Owns the Wife-O-Meter, the central 1-second tick, money, and the game state machine.
## Other systems (HUD, quests, player) talk to it only via methods and signals.

signal game_started
signal game_paused
signal game_resumed
signal game_over(final_score: int)
## The day timer ran out with the wife still above zero.
signal day_won(stars: int, final_score: int)
## Whole seconds left in the day; fires every tick.
signal time_changed(seconds_left: int)
signal state_changed(new_state: GameState, old_state: GameState)
signal happiness_changed(new_value: float, old_value: float)
signal money_changed(new_value: int, old_value: int)
## Fires every central tick while PLAYING (once per TICK_SECONDS). QuestManager can hook into this.
signal tick(delta_seconds: float)

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, VICTORY }

const MAX_HAPPINESS := 100.0
const START_HAPPINESS := 60.0
## Length of one day in seconds. Survive it to win.
const DAY_LENGTH := 120.0
## Wife-O-Meter needed at the end of the day for 2 / 3 stars (1 star for just surviving).
const STARS_2_AT := 40.0
const STARS_3_AT := 70.0
const TICK_SECONDS := 1.0
## Happiness lost per second (can be raised over time for difficulty).
const BASE_DECAY_PER_SECOND := 0.8

var state: GameState = GameState.MENU
var wife_happiness: float = START_HAPPINESS
var money: int = 0
var elapsed_time: float = 0.0
var decay_per_second: float = BASE_DECAY_PER_SECOND

var _timer: Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keep handling input (pause toggle) while paused
	_timer = Timer.new()
	_timer.wait_time = TICK_SECONDS
	_timer.one_shot = false
	_timer.process_mode = Node.PROCESS_MODE_PAUSABLE # stops automatically with get_tree().paused
	_timer.timeout.connect(_on_tick)
	add_child(_timer)


# --- State machine -----------------------------------------------------------

func start_game() -> void:
	wife_happiness = START_HAPPINESS
	money = 0
	elapsed_time = 0.0
	decay_per_second = BASE_DECAY_PER_SECOND
	happiness_changed.emit(wife_happiness, wife_happiness)
	money_changed.emit(money, money)
	time_changed.emit(int(DAY_LENGTH))
	_timer.start()
	_set_state(GameState.PLAYING)
	game_started.emit()


func pause_game() -> void:
	if state != GameState.PLAYING:
		return
	get_tree().paused = true
	_set_state(GameState.PAUSED)
	game_paused.emit()


func resume_game() -> void:
	if state != GameState.PAUSED:
		return
	get_tree().paused = false
	_set_state(GameState.PLAYING)
	game_resumed.emit()


func end_game() -> void:
	if state == GameState.GAME_OVER:
		return
	_timer.stop()
	get_tree().paused = false
	_set_state(GameState.GAME_OVER)
	game_over.emit(final_score())


func win_day() -> void:
	if state != GameState.PLAYING:
		return
	_timer.stop()
	var stars := stars_for(wife_happiness)
	_set_state(GameState.VICTORY)
	day_won.emit(stars, final_score())


func stars_for(happiness: float) -> int:
	if happiness >= STARS_3_AT:
		return 3
	if happiness >= STARS_2_AT:
		return 2
	return 1


func final_score() -> int:
	return money * 10 + int(wife_happiness)


func time_left() -> int:
	return maxi(0, int(ceil(DAY_LENGTH - elapsed_time)))


func is_playing() -> bool:
	return state == GameState.PLAYING


# --- Happiness & money -------------------------------------------------------

func add_happiness(amount: float) -> void:
	_change_happiness(absf(amount))


func remove_happiness(amount: float) -> void:
	_change_happiness(-absf(amount))


func add_money(amount: int) -> void:
	var old := money
	money = maxi(0, money + amount)
	if money != old:
		money_changed.emit(money, old)


func happiness_ratio() -> float:
	return wife_happiness / MAX_HAPPINESS


# --- Internals ---------------------------------------------------------------

func _change_happiness(delta: float) -> void:
	if state != GameState.PLAYING:
		return
	var old := wife_happiness
	wife_happiness = clampf(wife_happiness + delta, 0.0, MAX_HAPPINESS)
	if not is_equal_approx(old, wife_happiness):
		happiness_changed.emit(wife_happiness, old)
	if wife_happiness <= 0.0:
		end_game()


func _on_tick() -> void:
	if state != GameState.PLAYING:
		return
	elapsed_time += TICK_SECONDS
	remove_happiness(decay_per_second * TICK_SECONDS)
	if state != GameState.PLAYING: # decay may have ended the game
		return
	time_changed.emit(time_left())
	tick.emit(TICK_SECONDS)
	if elapsed_time >= DAY_LENGTH:
		win_day()


func _set_state(new_state: GameState) -> void:
	var old := state
	state = new_state
	state_changed.emit(new_state, old)
