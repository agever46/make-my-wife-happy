extends Node
## Timed events of the day (Autoload: EventManager). PURE LOGIC: decides WHEN things happen and what they
## change in the quest board; the 3D world plays the animation and reports back.
##
## Day timeline: at BUS_TIME the school bus is called. The world drives the bus in, the kids walk to the table
## and call kids_seated(). That switches on the kids' requests and starts the two dinner orders.

signal bus_arrival_requested
signal bus_departure_requested
## The world should remove the bus and the kids (new day / restart).
signal event_reset
## A short message for the HUD banner.
signal announcement(text: String)

## Seconds into the day when the bus arrives.
const BUS_TIME := 22.0

var kids_home := false
var _bus_called := false


func _ready() -> void:
	GameManager.game_started.connect(_reset)
	GameManager.tick.connect(_on_tick)


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
	announcement.emit("The kids are hungry - DINNER TIME!")
	QuestManager.start_by_id(&"dinner_a")
	QuestManager.start_by_id(&"dinner_b")
	bus_departure_requested.emit()


func _reset() -> void:
	kids_home = false
	_bus_called = false
	event_reset.emit()
