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
	list.append_array(_cooking_quests())
	var tidy := _quest(&"tidy", "The toys are EVERYWHERE!", 34.0, [
		_step(&"toy_box", "Put the toy in the toy box", 0.5, &"toy"),
	], &"toy")
	tidy.spawn_item = &"toy"
	tidy.requires = &"kids_playing"
	list.append(tidy)
	return list


## Requests of the two kids (random while they are home).
static func _kid_quests() -> Array[QuestData]:
	var out: Array[QuestData] = []
	for kid in [[&"kid_a", "a", "Mia"], [&"kid_b", "b", "Noah"]]:
		var k: StringName = kid[0]
		var suffix: String = kid[1]
		var who: String = kid[2]
		var water := _quest(StringName("water_" + suffix), "%s: I need WATER!" % who, 26.0, [
			_step(&"sink", "Fill a glass at the sink", 1.0, &"", &"water"),
			_step(k, "Give it to %s" % who, 0.4, &"water"),
		], &"water")
		var ketchup := _quest(StringName("ketchup_" + suffix), "%s: MORE KETCHUP!" % who, 26.0, [
			_step(&"fridge", "Get the ketchup", 0.6, &"", &"ketchup"),
			_step(k, "Give it to %s" % who, 0.4, &"ketchup"),
		], &"ketchup")
		ketchup.requires = &"kids_at_table" # only makes sense at the table; the loop below would reset it
		var play := _quest(StringName("play_" + suffix), "%s: PLAY WITH ME!" % who, 32.0, [
			_step(k, "Play with %s (hold!)" % who, 4.0),
		], &"toy")
		play.requires = &"kids_playing"
		play.kid = k
		play.reward_money = 12
		play.reward_happiness = 10.0
		play.fail_penalty = 10.0
		out.append(play)
		var cookie := _quest(StringName("cookie_" + suffix), "%s: can I have a cookie?" % who, 28.0, [
			_step(&"fridge", "Find a cookie in the fridge", 0.6, &"", &"cookie"),
			_step(k, "Give it to %s" % who, 0.4, &"cookie"),
		], &"cookie")
		var toy := _quest(StringName("toy_" + suffix), "%s: where is my DUCK?!" % who, 28.0, [
			_step(k, "Find the duck and bring it to %s" % who, 0.4, &"toy"),
		], &"toy")
		toy.spawn_item = &"toy"
		for q in [water, ketchup, cookie, toy]:
			if q.requires == &"":
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


## The wife cooks dinner and asks the husband for ingredients. Started one after another by EventManager.
static func _cooking_quests() -> Array[QuestData]:
	var out: Array[QuestData] = []
	var items := [
		[&"cook_pasta", "Mom: I need PASTA!", &"pantry", "Get the pasta from the pantry", 0.8, &"pasta"],
		[&"cook_tomato", "Mom: fresh TOMATOES from the garden!", &"tomato_bed", "Pick tomatoes in the garden (hold!)", 1.6, &"tomato"],
		[&"cook_carrot", "Mom: one CARROT. Just one.", &"carrot_bed", "Pull a carrot in the garden (hold!)", 1.4, &"carrot"],
		[&"cook_basil", "Mom: BASIL! Quick!", &"herb_bed", "Cut basil in the garden", 1.0, &"basil"],
		[&"cook_cheese", "Mom: cheese, from the fridge!", &"fridge", "Get the cheese from the fridge", 0.6, &"cheese"],
	]
	for it in items:
		var q := _quest(it[0], it[1], 40.0, [
			_step(it[2], it[3], it[4], &"", it[5]),
			_step(&"wife", "Bring it to her", 0.3, it[5]),
		], it[5])
		q.event_only = true
		q.requires = &"cooking"
		q.reward_money = 10
		q.reward_happiness = 6.0
		q.fail_penalty = 10.0
		out.append(q)
	return out
