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

## Difficulty ramp over the day (0 = start, 1 = end): more quests at once, shorter gaps between them.
const MAX_ACTIVE_START := 2
const MAX_ACTIVE_END := 4
const FIRST_SPAWN_DELAY := 2.0
const SPAWN_GAP_START := Vector2(9.0, 13.0)
const SPAWN_GAP_END := Vector2(4.5, 7.0)

## Story flags set by events (e.g. kids_home). Quests may require one.
var flags := {}
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
		var gap := SPAWN_GAP_START.lerp(SPAWN_GAP_END, day_progress())
		_spawn_cooldown = randf_range(gap.x, gap.y)
		spawn_random()


# --- Public API --------------------------------------------------------------

func set_flag(flag: StringName, value: bool = true) -> void:
	flags[flag] = value


## Starts a quest by id regardless of the board limit (events, debug). Returns null if the id is unknown.
func start_by_id(id: StringName) -> ActiveQuest:
	for data in QuestDB.all():
		if data.id == id:
			return start_quest(data)
	return null


## 0.0 at the start of the day, 1.0 at the end.
func day_progress() -> float:
	return clampf(GameManager.elapsed_time / GameManager.DAY_LENGTH, 0.0, 1.0)


func max_active() -> int:
	return roundi(lerpf(MAX_ACTIVE_START, MAX_ACTIVE_END, day_progress()))


## Adds a random quest that fits the current player count. Returns null if none fits.
func spawn_random() -> ActiveQuest:
	if active.size() >= max_active():
		return null
	var players := maxi(1, GameManager.player_count)
	var candidates: Array[QuestData] = []
	for data in QuestDB.all():
		if players < data.min_players or players > data.max_players:
			continue
		if data.event_only or (data.requires != &"" and not flags.get(data.requires, false)):
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
	# Prefer a step that uses the item in the hands over one that needs nothing (e.g. "play with the kid").
	var chosen: ActiveQuest = null
	for quest in active:
		var step := quest.step()
		if not _step_can_run(step, station_id, held_item):
			continue
		if step.get("needs", &"") != &"":
			chosen = quest
			break
		if chosen == null:
			chosen = quest
	if chosen == null:
		return {}
	var quest := chosen
	var step := quest.step()
	var needs: StringName = step.get("needs", &"")
	var gives: StringName = step.get("gives", &"")
	quest.work_done += delta
	var work: float = step.get("work", 0.5)
	if quest.work_done >= work:
		_advance(quest)
		return {"progress": 1.0, "done": true, "consume": needs != &"", "give": gives, "quest_uid": quest.uid}
	return {"progress": quest.work_done / work, "done": false, "consume": false, "give": &"", "quest_uid": quest.uid}


## True if some active quest could make progress at this station with this held item.
## Lets the world pick the right station when several interact zones overlap.
func can_work(station_id: StringName, held_item: StringName) -> bool:
	for quest in active:
		if _step_can_run(quest.step(), station_id, held_item):
			return true
	return false


func is_station_needed(station_id: StringName) -> bool:
	for quest in active:
		if quest.step()["station"] == station_id:
			return true
	return false


## True if any step of any active quest (now or later) uses this station.
func is_station_involved(station_id: StringName) -> bool:
	for quest in active:
		for step in quest.data.steps:
			if step["station"] == station_id:
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


## Removes every active quest without reward or penalty (debug).
func clear_quests() -> void:
	for quest in active:
		quest_items_released.emit(quest.uid)
	active.clear()
	quests_cleared.emit()


# --- Internals ---------------------------------------------------------------

func _step_can_run(step: Dictionary, station_id: StringName, held_item: StringName) -> bool:
	if step["station"] != station_id:
		return false
	var needs: StringName = step.get("needs", &"")
	var gives: StringName = step.get("gives", &"")
	if needs != &"" and held_item != needs:
		return false
	if needs == &"" and gives != &"" and held_item != &"":
		return false # hands are full
	return true


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
	flags.clear()
	world_reset.emit()
	_spawn_cooldown = FIRST_SPAWN_DELAY
	quests_cleared.emit()
