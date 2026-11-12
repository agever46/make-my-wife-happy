extends Node
## Quest board (Autoload: QuestManager). PURE LOGIC: it only knows station ids and item ids,
## never nodes. Spawns random chores, counts down patience and advances steps.
## The world (2D or 3D) talks to it through try_work() and reacts to the item_* / world_reset signals.

signal quest_added(quest: ActiveQuest)
signal quest_step_changed(quest: ActiveQuest)
signal quest_completed(quest: ActiveQuest)
signal quest_failed(quest: ActiveQuest)
signal quests_cleared
## Logic -> world: please create this item somewhere reachable (e.g. lost keys at a hiding spot).
signal item_spawn_requested(quest_uid: int, item_id: StringName)
## Logic -> world: the quest ended, remove every item tagged with this quest_uid.
signal quest_items_released(quest_uid: int)
## Logic -> world: a new day started, remove all items.
signal world_reset

const MAX_ACTIVE := 3
const FIRST_SPAWN_DELAY := 2.0
const SPAWN_INTERVAL_MIN := 7.0
const SPAWN_INTERVAL_MAX := 11.0

var active: Array[ActiveQuest] = []
var _spawn_cooldown := FIRST_SPAWN_DELAY
var _next_uid := 1


func _ready() -> void:
	GameManager.game_started.connect(_reset)


func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	for quest in active.duplicate():
		quest.time_left -= delta
		if quest.time_left <= 0.0:
			_finish(quest, false)
	if not GameManager.is_playing(): # a failed quest may have ended the game
		return
	_spawn_cooldown -= delta
	if _spawn_cooldown <= 0.0:
		_spawn_cooldown = randf_range(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_MAX)
		spawn_random()


# --- Public API --------------------------------------------------------------

## Adds a random quest that fits the current player count. Returns null if none fits.
func spawn_random() -> ActiveQuest:
	if active.size() >= MAX_ACTIVE:
		return null
	var players := maxi(1, GameManager.player_count)
	var candidates: Array[QuestData] = []
	for data in QuestDB.all():
		if players < data.min_players or players > data.max_players:
			continue
		if _is_active(data.id):
			continue
		candidates.append(data)
	if candidates.is_empty():
		return null
	return start_quest(candidates.pick_random())


func start_quest(data: QuestData) -> ActiveQuest:
	var quest := ActiveQuest.new()
	quest.uid = _next_uid
	_next_uid += 1
	quest.data = data
	quest.time_left = data.patience
	active.append(quest)
	quest_added.emit(quest)
	if data.spawn_item != &"":
		item_spawn_requested.emit(quest.uid, data.spawn_item)
	return quest


## Called every frame while a player holds `interact` at a station.
## Returns {} when there is nothing to do here. Otherwise:
##   progress  0..1 of the current step
##   done      true on the frame the step finished (logic already advanced)
##   consume   true if the held item must be removed (only when done)
##   give      item id the player must receive (only when done), &"" for none
##   quest_uid uid of the quest, so the world can tag a given item for cleanup
func try_work(station_id: StringName, held_item: StringName, delta: float) -> Dictionary:
	for quest in active:
		var step := quest.step()
		if step["station"] != station_id:
			continue
		var needs: StringName = step.get("needs", &"")
		var gives: StringName = step.get("gives", &"")
		if needs != &"" and held_item != needs:
			continue
		if needs == &"" and gives != &"" and held_item != &"":
			continue # hands are full
		quest.work_done += delta
		var work: float = step.get("work", 0.5)
		if quest.work_done >= work:
			_advance(quest)
			return {"progress": 1.0, "done": true, "consume": needs != &"", "give": gives, "quest_uid": quest.uid}
		return {"progress": quest.work_done / work, "done": false, "consume": false, "give": &"", "quest_uid": quest.uid}
	return {}


func is_station_needed(station_id: StringName) -> bool:
	for quest in active:
		if quest.step()["station"] == station_id:
			return true
	return false


## Item id to show on a station's floating icon: what you will get there, else what you must bring.
func icon_item_for(station_id: StringName) -> StringName:
	for quest in active:
		var step := quest.step()
		if step["station"] == station_id:
			var gives: StringName = step.get("gives", &"")
			return gives if gives != &"" else step.get("needs", &"")
	return &""


# --- Internals ---------------------------------------------------------------

func _advance(quest: ActiveQuest) -> void:
	quest.work_done = 0.0
	if quest.step_index + 1 >= quest.data.steps.size():
		_finish(quest, true)
	else:
		quest.step_index += 1
		quest_step_changed.emit(quest)


func _finish(quest: ActiveQuest, success: bool) -> void:
	active.erase(quest)
	quest_items_released.emit(quest.uid)
	if success:
		quest_completed.emit(quest)
		GameManager.add_money(quest.data.reward_money)
		GameManager.add_happiness(quest.data.reward_happiness)
	else:
		quest_failed.emit(quest)
		GameManager.remove_happiness(quest.data.fail_penalty)


func _is_active(id: StringName) -> bool:
	for quest in active:
		if quest.data.id == id:
			return true
	return false


func _reset() -> void:
	active.clear()
	world_reset.emit()
	_spawn_cooldown = FIRST_SPAWN_DELAY
	quests_cleared.emit()
