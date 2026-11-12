class_name QuestData
extends Resource
## Definition of one chore. Pure data, so quests can later move to .tres files.

@export var id: StringName
@export var title: String
## Item whose icon represents this quest on the ticket.
@export var icon_item: StringName = &""
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
## Only offered while this flag is set (e.g. &"kids_home"). Empty = always available.
@export var requires: StringName = &""
## Never picked at random; started by an event (e.g. the dinner orders when the kids sit down).
@export var event_only: bool = false
## Which kid station this quest is about (kid_a / kid_b), for the reaction animation. Empty = none.
@export var kid: StringName = &""
