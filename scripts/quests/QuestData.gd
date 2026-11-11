class_name QuestData
extends Resource
## Definition of one chore. Pure data, so quests can later move to .tres files.

@export var id: StringName
@export var title: String
## Seconds before the wife loses patience.
@export var patience: float = 30.0
@export var reward_happiness: float = 12.0
@export var fail_penalty: float = 18.0
@export var reward_money: int = 10
@export var min_players: int = 1
@export var max_players: int = 4
## Item dropped at a random "hiding_spots" marker when the quest starts (e.g. lost keys).
@export var spawn_item: StringName = &""
## Ordered steps. Each: { station, needs (item id or &""), gives (item id or &""), work (seconds), text }.
@export var steps: Array[Dictionary] = []
