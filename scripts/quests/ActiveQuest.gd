class_name ActiveQuest
extends RefCounted
## A quest currently on the board.

var uid: int = 0
var data: QuestData
var step_index: int = 0
var time_left: float = 0.0
## Seconds of work already done on the current step.
var work_done: float = 0.0
## Items created for this quest; removed when it ends.
var items: Array[Item] = []


func step() -> Dictionary:
	return data.steps[step_index]


func hint() -> String:
	return str(step().get("text", ""))


func patience_ratio() -> float:
	return clampf(time_left / data.patience, 0.0, 1.0)
