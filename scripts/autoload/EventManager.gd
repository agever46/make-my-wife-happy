extends Node
## Timed events of the day (Autoload: EventManager). PURE LOGIC: decides WHEN things happen and what they
## change in the quest board; the 3D world plays the animations and reports back.
##
## Day timeline:
##   BUS_TIME            the school bus is called -> the kids walk to the table -> kids_seated()
##   kids_seated         the wife stands up and walks to the stove (cooking_started)
##   wife_at_stove()     she asks for ingredients, two at a time (quests cook_*); the husband fetches them
##   all delivered       cooking_finished -> she cooks -> dinner_ready() -> she serves -> dinner_served()
##   a few seconds later playtime: the kids leave the table and play in the living room

signal bus_arrival_requested
signal bus_departure_requested
## The kids are at the table: the wife should get up and go to the stove.
signal cooking_started
## All ingredients are in: the wife should cook now (and call dinner_ready() when it is done).
signal cooking_finished
## The wife should bring the plates to the table (and call dinner_served() when she put them down).
signal dinner_serving_requested
## Dinner is over: the kids leave the table and go to play in the living room.
signal kids_play_requested
## The world should remove the bus and the kids and reset the wife (new day / restart).
signal event_reset
## A short message for the HUD banner.
signal announcement(text: String)

## Seconds into the day when the bus arrives.
const BUS_TIME := 22.0
const RECIPE: Array[StringName] = [&"cook_pasta", &"cook_tomato", &"cook_cheese", &"cook_basil", &"cook_carrot"]
## How many ingredient requests are open at the same time.
const MAX_OPEN_REQUESTS := 2
const EAT_TIME := 6.0

var kids_home := false
var kids_playing := false
var cooking := false

var _bus_called := false
var _queue: Array[StringName] = []
var _open := 0
var _delivered := 0
## Bumped on every reset so delayed callbacks of an old day do nothing.
var _generation := 0


func _ready() -> void:
	GameManager.game_started.connect(_reset)
	GameManager.tick.connect(_on_tick)
	QuestManager.quest_completed.connect(_on_quest_ended.bind(true))
	QuestManager.quest_failed.connect(_on_quest_ended.bind(false))


func _on_tick(_delta: float) -> void:
	if not _bus_called and GameManager.elapsed_time >= BUS_TIME:
		call_bus()


## Calls the bus now (also used by the debug console).
func call_bus() -> void:
	if _bus_called or not GameManager.is_playing():
		return
	_bus_called = true
	announcement.emit("THE SCHOOL BUS IS HERE!")
	bus_arrival_requested.emit()


## The world calls this when both kids are sitting at the table.
func kids_seated() -> void:
	if kids_home:
		return
	kids_home = true
	QuestManager.set_flag(&"kids_home", true)
	QuestManager.set_flag(&"kids_at_table", true)
	announcement.emit("The kids are hungry - MOM goes to cook!")
	cooking_started.emit()
	bus_departure_requested.emit()


## The wife reached the stove: she starts asking for ingredients.
func wife_at_stove() -> void:
	if cooking or kids_playing:
		return
	cooking = true
	QuestManager.set_flag(&"cooking", true)
	_delivered = 0
	_open = 0
	_queue = RECIPE.duplicate()
	_queue.shuffle()
	announcement.emit("Mom needs ingredients - fetch them!")
	_fill_requests()


## The wife is done cooking.
func dinner_ready() -> void:
	announcement.emit("DINNER IS READY!")
	dinner_serving_requested.emit()


## The plates are on the table. The kids eat, then go and play.
func dinner_served() -> void:
	var gen := _generation
	await get_tree().create_timer(EAT_TIME).timeout
	if gen == _generation:
		start_playtime()


func start_playtime() -> void:
	if kids_playing or not kids_home:
		return
	kids_playing = true
	QuestManager.set_flag(&"kids_at_table", false)
	QuestManager.set_flag(&"kids_playing", true)
	announcement.emit("Dinner is over - the kids are PLAYING!")
	kids_play_requested.emit()


# --- ingredient requests -----------------------------------------------------

func _fill_requests() -> void:
	while cooking and _open < MAX_OPEN_REQUESTS and not _queue.is_empty():
		var id: StringName = _queue.pop_front()
		if QuestManager.start_by_id(id) != null:
			_open += 1


func _on_quest_ended(quest: ActiveQuest, success: bool) -> void:
	if not cooking or not String(quest.data.id).begins_with("cook_"):
		return
	_open = maxi(_open - 1, 0)
	if success:
		_delivered += 1
	else:
		_queue.push_back(quest.data.id) # she still needs it: ask again
	if _delivered >= RECIPE.size():
		cooking = false
		QuestManager.set_flag(&"cooking", false)
		cooking_finished.emit()
		return
	var gen := _generation
	await get_tree().create_timer(1.0 if success else 2.0).timeout
	if gen == _generation:
		_fill_requests()


func _reset() -> void:
	_generation += 1
	kids_playing = false
	kids_home = false
	cooking = false
	_bus_called = false
	_queue.clear()
	_open = 0
	_delivered = 0
	event_reset.emit()
