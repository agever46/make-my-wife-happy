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
	list.append_array(_kid_quests())
	return list


## Orders from the two kids at the dinner table. Dinner is started by the bus event; the small requests are random.
static func _kid_quests() -> Array[QuestData]:
	var out: Array[QuestData] = []
	for kid in [[&"kid_a", "a", "Mia"], [&"kid_b", "b", "Noah"]]:
		var k: StringName = kid[0]
		var suffix: String = kid[1]
		var who: String = kid[2]
		var dinner := _quest(StringName("dinner_" + suffix), "Dinner for %s!" % who, 70.0, [
			_step(&"fridge", "Get ingredients from the fridge", 1.0, &"", &"ingredients"),
			_step(&"stove", "Cook it on the stove (hold!)", 3.5, &"ingredients", &"dinner_plate"),
			_step(k, "Serve %s" % who, 0.5, &"dinner_plate"),
		], &"dinner_plate")
		dinner.event_only = true
		dinner.requires = &"kids_home"
		dinner.reward_happiness = 16.0
		dinner.reward_money = 25
		dinner.fail_penalty = 22.0
		dinner.kid = k
		out.append(dinner)
		var water := _quest(StringName("water_" + suffix), "%s: I need WATER!" % who, 26.0, [
			_step(&"sink", "Fill a glass at the sink", 1.0, &"", &"water"),
			_step(k, "Give it to %s" % who, 0.4, &"water"),
		], &"water")
		var ketchup := _quest(StringName("ketchup_" + suffix), "%s: MORE KETCHUP!" % who, 26.0, [
			_step(&"fridge", "Get the ketchup", 0.6, &"", &"ketchup"),
			_step(k, "Give it to %s" % who, 0.4, &"ketchup"),
		], &"ketchup")
		var cookie := _quest(StringName("cookie_" + suffix), "%s: can I have a cookie?" % who, 28.0, [
			_step(&"fridge", "Find a cookie in the fridge", 0.6, &"", &"cookie"),
			_step(k, "Give it to %s" % who, 0.4, &"cookie"),
		], &"cookie")
		var toy := _quest(StringName("toy_" + suffix), "%s: where is my DUCK?!" % who, 28.0, [
			_step(k, "Find the duck and bring it to %s" % who, 0.4, &"toy"),
		], &"toy")
		toy.spawn_item = &"toy"
		for q in [water, ketchup, cookie, toy]:
			q.requires = &"kids_home"
			q.kid = k
			q.reward_money = 8
			q.reward_happiness = 8.0
			q.fail_penalty = 10.0
			out.append(q)
	return out


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
