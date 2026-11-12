class_name QuestDB
extends RefCounted
## The quest pool. Add new chores here.

static func all() -> Array[QuestData]:
	var list: Array[QuestData] = []
	list.append(_quest(&"coffee", "Coffee, exactly how I like it!", 32.0, [
		_step(&"coffee_machine", "Make coffee at the machine", 2.0, &"", &"coffee"),
		_step(&"fridge", "Add milk at the fridge", 1.0, &"coffee", &"coffee_milk"),
		_step(&"wife", "Bring it to her", 0.3, &"coffee_milk"),
	], &"coffee_milk"))
	list.append(_quest(&"trash", "Take out the trash!", 26.0, [
		_step(&"trash_can", "Tie the bag at the trash can", 1.2, &"", &"trash_bag"),
		_step(&"dumpster", "Throw it in the dumpster outside", 0.5, &"trash_bag"),
	], &"trash_bag"))
	var keys := _quest(&"keys", "Where are my keys?!", 24.0, [
		_step(&"wife", "Find the keys and bring them to her", 0.3, &"keys"),
	], &"keys")
	keys.spawn_item = &"keys"
	list.append(keys)
	return list


static func _quest(id: StringName, title: String, patience: float, steps: Array, icon_item: StringName = &"") -> QuestData:
	var q := QuestData.new()
	q.id = id
	q.title = title
	q.icon_item = icon_item
	q.patience = patience
	for s in steps:
		q.steps.append(s)
	return q


static func _step(station: StringName, text: String, work: float, needs: StringName = &"", gives: StringName = &"") -> Dictionary:
	return {"station": station, "text": text, "work": work, "needs": needs, "gives": gives}
