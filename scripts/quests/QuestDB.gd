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

	list.append(_quest(&"laundry", "The laundry! It's going to RAIN!", 36.0, [
		_step(&"washing_machine", "Grab the wet laundry", 1.8, &"", &"laundry"),
		_step(&"clothesline", "Hang it outside!", 1.5, &"laundry"),
	], &"laundry"))
	list.append(_quest(&"mail", "Did the mail come?!", 32.0, [
		_step(&"mailbox", "Check the mailbox outside", 1.0, &"", &"mail"),
		_step(&"wife", "Bring her the mail", 0.3, &"mail"),
	], &"mail"))
	list.append(_quest(&"dog", "The dog needs a walk. NOW.", 30.0, [
		_step(&"leash_hook", "Grab the leash by the door", 0.5, &"", &"leash"),
		_step(&"dog", "Walk the dog (hold!)", 3.5, &"leash"),
	], &"leash"))
	list.append(_quest(&"groceries", "The groceries are in the car!", 36.0, [
		_step(&"car", "Unload the groceries", 1.2, &"", &"grocery_bag"),
		_step(&"fridge", "Put them in the fridge", 1.0, &"grocery_bag"),
	], &"grocery_bag"))
	list.append(_quest(&"stain", "There is a STAIN on the carpet!", 32.0, [
		_step(&"sink", "Grab a sponge at the sink", 0.8, &"", &"sponge"),
		_step(&"stain", "Scrub it (hold!)", 3.0, &"sponge"),
	], &"sponge"))
	var remote := _quest(&"remote", "Where is the TV remote?!", 26.0, [
		_step(&"wife", "Find the remote and bring it", 0.3, &"remote"),
	], &"remote")
	remote.spawn_item = &"remote"
	list.append(remote)
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
