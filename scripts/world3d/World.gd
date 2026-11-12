class_name World
extends Node3D
## Builds the 3D house and the players, and carries out what the quest logic asks for
## (spawn the lost keys, clean up items). The logic itself lives in the autoloads.

const PLAYER_SCENE := preload("res://scenes/Player3D.tscn")

var items_root: Node3D
var players: Array[Player3D] = []


func _ready() -> void:
	var house := HouseBuilder.new()
	house.name = "House"
	add_child(house)
	house.build()

	items_root = Node3D.new()
	items_root.name = "Items"
	items_root.add_to_group("item_root")
	add_child(items_root)

	var player := PLAYER_SCENE.instantiate() as Player3D
	player.name = "Player1"
	player.position = Grid.center(HouseLayout.PLAYER_START)
	add_child(player)
	players.append(player)

	QuestManager.item_spawn_requested.connect(_on_item_spawn_requested)
	QuestManager.quest_items_released.connect(_on_quest_items_released)
	QuestManager.world_reset.connect(_on_world_reset)


func _on_item_spawn_requested(quest_uid: int, item_id: StringName) -> void:
	var spot: Vector2 = HouseLayout.HIDING_SPOTS.pick_random()
	var item := Item3D.create(item_id, quest_uid)
	items_root.add_child(item)
	item.position = Grid.center(spot)


func _on_quest_items_released(quest_uid: int) -> void:
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item3D
		if item != null and item.quest_uid == quest_uid:
			item.destroy()


func _on_world_reset() -> void:
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item3D
		if item != null:
			item.destroy()
