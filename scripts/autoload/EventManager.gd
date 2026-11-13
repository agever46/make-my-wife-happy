extends Node
## Timed events of the day (Autoload: EventManager). PURE LOGIC: decides WHEN things happen and what they
## change in the quest board; the 3D world plays the animation and reports back.
##
## Day timeline: at BUS_TIME the school bus is called. The world drives the bus in, the kids walk to the table
## and call kids_seated(). That switches on the kids' requests and starts the two dinner orders.

signal bus_arrival_requested
signal bus_departure_requested
## Dinner is over: the kids leave the table and go to play in the living room.
signal kids_play_requested
## The world should remove the bus and the kids (new day / restart).
signal event_reset
## A short message for the HUD banner.
signal announcement(text: String)

## Seconds into the day when the bus arrives.
const BUS_TIME := 22.0

var kids_home := false
var kids_playing := false
var _dinner_ended := 0
var _bus_called := false


func _ready() -> void:
	GameManager.game_started.connect(_reset)
	GameManager.tick.connect(_on_tick)
	QuestManager.quest_completed.connect(_on_quest_ended)
	QuestManager.quest_failed.connect(_on_quest_ended)


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
	announcement.emit("The kids are hungry - DINNER TIME!")
	QuestManager.start_by_id(&"dinner_a")
	QuestManager.start_by_id(&"dinner_b")
	bus_departure_requested.emit()


## Both dinners finished (served or ruined): the kids stand up and go play.
func _on_quest_ended(quest: ActiveQuest) -> void:
	if not kids_home or kids_playing:
		return
	if quest.data.id == &"dinner_a" or quest.data.id == &"dinner_b":
		_dinner_ended += 1
		if _dinner_ended >= 2:
			start_playtime()


func start_playtime() -> void:
	if kids_playing or not kids_home:
		return
	kids_playing = true
	QuestManager.set_flag(&"kids_at_table", false)
	QuestManager.set_flag(&"kids_playing", true)
	announcement.emit("Dinner is over - the kids are PLAYING!")
	kids_play_requested.emit()


func _reset() -> void:
	kids_playing = false
	_dinner_ended = 0
	kids_home = false
	_bus_called = false
	event_reset.emit()
