extends Node
## Quest board (Autoload: QuestManager). Spawns random chores, counts down their patience,
## and advances them when a player works at the right station with the right item.

signal quest_added(quest: ActiveQuest)
signal quest_step_changed(quest: ActiveQuest)
signal quest_completed(quest: ActiveQuest)
signal quest_failed(quest: ActiveQuest)
signal quests_cleared

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
	var player_count := maxi(1, get_tree().get_nodes_in_group("players").size())
	var candidates: Array[QuestData] = []
	for data in QuestDB.all():
		if player_count < data.min_players or player_count > data.max_players:
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
	if data.spawn_item != &"":
		var spots := get_tree().get_nodes_in_group("hiding_spots")
		if spots.is_empty():
			return null
		var spot := spots.pick_random() as Node2D
		var item := Item.create(data.spawn_item)
		spot.get_parent().add_child(item)
		item.position = spot.position
		quest.items.append(item)
	active.append(quest)
	quest_added.emit(quest)
	return quest


## Called every frame while a player holds `interact` at a station.
## Returns the step progress (0..1), or -1.0 if there is nothing to do here.
func try_work(station: Station, player: Player, delta: float) -> float:
	var held := player.held_item_id()
	for quest in active:
		var step := quest.step()
		if step["station"] != station.station_id:
			continue
		var needs: StringName = step.get("needs", &"")
		var gives: StringName = step.get("gives", &"")
		if needs != &"" and held != needs:
			continue
		if needs == &"" and gives != &"" and held != &"":
			continue # hands are full
		quest.work_done += delta
		var work: float = step.get("work", 0.5)
		if quest.work_done >= work:
			_complete_step(quest, player)
			return 1.0
		return quest.work_done / work
	return -1.0


func is_station_needed(station_id: StringName) -> bool:
	for quest in active:
		if quest.step()["station"] == station_id:
			return true
	return false


# --- Internals ---------------------------------------------------------------

func _complete_step(quest: ActiveQuest, player: Player) -> void:
	var step := quest.step()
	var needs: StringName = step.get("needs", &"")
	var gives: StringName = step.get("gives", &"")
	if needs != &"":
		player.consume_item()
	if gives != &"":
		var item := Item.create(gives)
		quest.items.append(item)
		player.give_item(item)
	quest.work_done = 0.0
	if quest.step_index + 1 >= quest.data.steps.size():
		_finish(quest, true)
	else:
		quest.step_index += 1
		quest_step_changed.emit(quest)


func _finish(quest: ActiveQuest, success: bool) -> void:
	active.erase(quest)
	_free_items(quest)
	if success:
		quest_completed.emit(quest)
		GameManager.add_money(quest.data.reward_money)
		GameManager.add_happiness(quest.data.reward_happiness)
	else:
		quest_failed.emit(quest)
		GameManager.remove_happiness(quest.data.fail_penalty)


func _free_items(quest: ActiveQuest) -> void:
	for item in quest.items:
		if is_instance_valid(item):
			item.destroy()
	quest.items.clear()


func _is_active(id: StringName) -> bool:
	for quest in active:
		if quest.data.id == id:
			return true
	return false


func _reset() -> void:
	for quest in active:
		_free_items(quest)
	active.clear()
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item != null:
			item.destroy()
	_spawn_cooldown = FIRST_SPAWN_DELAY
	quests_cleared.emit()
