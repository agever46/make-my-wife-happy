class_name PlaceholderFactory
extends RefCounted
## Clean stand-in models made of beveled boxes with flat colours. Same names and sizes as the planned Blender models.
## Every model: origin bottom-centre on the floor, front = +Z.

static var _mats := {}


static func make(model_name: String) -> Node3D:
	var root := Node3D.new()
	root.name = model_name
	match model_name:
		"Char_Husband": _husband(root)
		"Char_Wife": _wife(root)
		"Interact_Fridge": _fridge(root)
		"Interact_CoffeeMachine": _coffee_machine(root)
		"Interact_TrashCan": _trash_can(root)
		"Interact_Dumpster": _dumpster(root)
		"Prop_Counter": _counter(root)
		"Prop_Couch": _couch(root)
		"Prop_CoffeeTable": _coffee_table(root)
		"Prop_Rug": _rug(root)
		"Prop_TV": _tv(root)
		"Interact_WashingMachine": _washing_machine(root)
		"Interact_Sink": _sink(root)
		"Interact_Stain": _stain(root)
		"Interact_Clothesline": _clothesline(root)
		"Interact_Mailbox": _mailbox(root)
		"Interact_LeashHook": _leash_hook(root)
		"Interact_Dog": _dog(root)
		"Interact_Car": _car(root)
		"Interact_Stove": _stove(root)
		"Interact_ToyBox": _toy_box(root)
		"Prop_DiningTable": _dining_table(root)
		"Prop_Chair": _chair(root)
		"Prop_Bus": _bus(root)
		"Char_Kid_A": _kid(root, Color(0.98, 0.6, 0.25), Color(0.25, 0.15, 0.1), true)
		"Char_Kid_B": _kid(root, Color(0.35, 0.75, 0.45), Color(0.8, 0.55, 0.25), false)
		_:
			box(root, "Unknown", Vector3(0.8, 0.8, 0.8), Vector3.ZERO, Color(1.0, 0.0, 1.0))
	return root


# --- helpers -----------------------------------------------------------------

static func mat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var key := "%s|%s" % [color, emission]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.78
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	_mats[key] = m
	return m


## A beveled box whose BOTTOM-CENTRE is at `base`.
static func box(parent: Node3D, part_name: String, size: Vector3, base: Vector3, color: Color, bevel: float = 0.04, emission: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = Bevel.box(size, bevel)
	mi.material_override = mat(color, emission)
	mi.position = base + Vector3(0.0, size.y * 0.5, 0.0)
	parent.add_child(mi)
	return mi


static func pivot(parent: Node3D, node_name: String, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = node_name
	n.position = pos
	parent.add_child(n)
	return n


# --- characters --------------------------------------------------------------

const SKIN := Color(0.96, 0.78, 0.64)
const HAIR := Color(0.36, 0.22, 0.14)


static func _husband(r: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var leg := pivot(r, "LegL" if side < 0.0 else "LegR", Vector3(side * 0.12, 0.8, 0.0))
		box(leg, "Leg", Vector3(0.18, 0.68, 0.2), Vector3(0, -0.8 + 0.12, 0), Color(0.5, 0.5, 0.56))
		box(leg, "Slipper", Vector3(0.2, 0.12, 0.34), Vector3(0, -0.8, 0.06), Color(0.6, 0.45, 0.36), 0.05)
		var arm := pivot(r, "ArmL" if side < 0.0 else "ArmR", Vector3(side * 0.34, 1.38, 0.0))
		box(arm, "Sleeve", Vector3(0.16, 0.2, 0.18), Vector3(0, -0.2, 0), Color(0.25, 0.5, 0.9))
		box(arm, "Forearm", Vector3(0.13, 0.34, 0.15), Vector3(0, -0.54, 0), SKIN)
	box(r, "Torso", Vector3(0.52, 0.6, 0.3), Vector3(0, 0.8, 0), Color(0.25, 0.5, 0.9), 0.06)
	var head := pivot(r, "Head", Vector3(0, 1.42, 0))
	box(head, "Skull", Vector3(0.36, 0.34, 0.33), Vector3.ZERO, SKIN, 0.06)
	box(head, "Hair", Vector3(0.38, 0.12, 0.35), Vector3(0, 0.3, 0), HAIR, 0.04)
	box(head, "Fringe", Vector3(0.38, 0.07, 0.1), Vector3(0, 0.24, 0.13), HAIR, 0.03)
	box(head, "EyeL", Vector3(0.05, 0.05, 0.02), Vector3(-0.08, 0.17, 0.165), Color(0.12, 0.1, 0.1), 0.01)
	box(head, "EyeR", Vector3(0.05, 0.05, 0.02), Vector3(0.08, 0.17, 0.165), Color(0.12, 0.1, 0.1), 0.01)
	box(head, "Stubble", Vector3(0.3, 0.09, 0.02), Vector3(0, 0.02, 0.165), Color(0.62, 0.5, 0.42), 0.01)


static func _wife(r: Node3D) -> void:
	var jeans := Color(0.2, 0.26, 0.4)
	for side in [-1.0, 1.0]:
		box(r, "Thigh", Vector3(0.16, 0.14, 0.42), Vector3(side * 0.11, 0.42, 0.2), jeans, 0.04)
		box(r, "Shin", Vector3(0.14, 0.44, 0.14), Vector3(side * 0.11, 0.0, 0.44), jeans, 0.04)
		box(r, "Foot", Vector3(0.14, 0.06, 0.2), Vector3(side * 0.11, 0.0, 0.5), SKIN, 0.02)
		var arm := pivot(r, "ArmL" if side < 0.0 else "ArmR", Vector3(side * 0.28, 1.0, -0.02))
		box(arm, "Sleeve", Vector3(0.14, 0.34, 0.16), Vector3(0, -0.34, 0.04), Color(0.2, 0.62, 0.6))
		box(arm, "Hand", Vector3(0.11, 0.1, 0.14), Vector3(0, -0.44, 0.14), SKIN, 0.03)
	box(r, "Torso", Vector3(0.46, 0.5, 0.26), Vector3(0, 0.56, -0.05), Color(0.2, 0.62, 0.6), 0.06)
	var head := pivot(r, "Head", Vector3(0, 1.08, -0.02))
	box(head, "Skull", Vector3(0.32, 0.3, 0.29), Vector3.ZERO, SKIN, 0.06)
	box(head, "Hair", Vector3(0.34, 0.12, 0.31), Vector3(0, 0.26, -0.01), HAIR, 0.04)
	box(head, "Bun", Vector3(0.15, 0.15, 0.15), Vector3(0, 0.34, -0.1), HAIR, 0.05)
	box(head, "EyeL", Vector3(0.045, 0.045, 0.02), Vector3(-0.075, 0.15, 0.147), Color(0.12, 0.1, 0.1), 0.01)
	box(head, "EyeR", Vector3(0.045, 0.045, 0.02), Vector3(0.075, 0.15, 0.147), Color(0.12, 0.1, 0.1), 0.01)
	box(head, "BrowL", Vector3(0.09, 0.025, 0.02), Vector3(-0.075, 0.21, 0.15), HAIR, 0.008)
	box(head, "BrowR", Vector3(0.09, 0.025, 0.02), Vector3(0.075, 0.21, 0.15), HAIR, 0.008)
	box(head, "Mouth", Vector3(0.09, 0.025, 0.02), Vector3(0, 0.05, 0.15), Color(0.7, 0.2, 0.25), 0.008)
	box(r, "Remote", Vector3(0.06, 0.03, 0.18), Vector3(-0.28, 0.58, 0.28), Color(0.1, 0.1, 0.12), 0.01)


# --- stations ----------------------------------------------------------------

static func _fridge(r: Node3D) -> void:
	box(r, "Body", Vector3(0.86, 1.85, 0.78), Vector3.ZERO, Color(0.92, 0.94, 0.97), 0.07)
	box(r, "DoorGap", Vector3(0.86, 0.03, 0.02), Vector3(0, 1.22, 0.39), Color(0.55, 0.58, 0.64), 0.005)
	box(r, "HandleTop", Vector3(0.05, 0.4, 0.05), Vector3(0.3, 1.3, 0.4), Color(0.6, 0.63, 0.7), 0.015)
	box(r, "HandleBottom", Vector3(0.05, 0.5, 0.05), Vector3(0.3, 0.55, 0.4), Color(0.6, 0.63, 0.7), 0.015)
	box(r, "Magnet", Vector3(0.1, 0.1, 0.02), Vector3(-0.2, 1.5, 0.4), Color(0.95, 0.4, 0.45), 0.02)


static func _counter(r: Node3D) -> void:
	box(r, "Cabinet", Vector3(0.96, 0.84, 0.82), Vector3.ZERO, Color(0.95, 0.9, 0.82), 0.05)
	box(r, "Top", Vector3(1.0, 0.07, 0.86), Vector3(0, 0.84, 0), Color(0.68, 0.48, 0.3), 0.025)
	box(r, "Handle", Vector3(0.3, 0.04, 0.03), Vector3(0, 0.6, 0.42), Color(0.55, 0.55, 0.6), 0.01)


static func _coffee_machine(r: Node3D) -> void:
	_counter(r)
	box(r, "Machine", Vector3(0.52, 0.44, 0.42), Vector3(0, 0.91, -0.05), Color(0.74, 0.76, 0.82), 0.06)
	box(r, "Top", Vector3(0.44, 0.1, 0.36), Vector3(0, 1.35, -0.05), Color(0.35, 0.37, 0.44), 0.03)
	box(r, "Spout", Vector3(0.1, 0.1, 0.1), Vector3(0, 1.02, 0.17), Color(0.2, 0.2, 0.25), 0.02)
	box(r, "Cup", Vector3(0.1, 0.1, 0.1), Vector3(0, 0.91, 0.17), Color(0.95, 0.95, 0.9), 0.025)
	box(r, "Light", Vector3(0.06, 0.06, 0.02), Vector3(0.17, 1.2, 0.17), Color(0.95, 0.25, 0.25), 0.01, 1.5)


static func _trash_can(r: Node3D) -> void:
	box(r, "Body", Vector3(0.56, 0.72, 0.56), Vector3.ZERO, Color(0.5, 0.6, 0.56), 0.08)
	box(r, "Lid", Vector3(0.62, 0.1, 0.62), Vector3(0, 0.72, 0), Color(0.3, 0.36, 0.34), 0.04)
	box(r, "Knob", Vector3(0.12, 0.06, 0.12), Vector3(0, 0.82, 0), Color(0.22, 0.26, 0.25), 0.02)
	box(r, "Pedal", Vector3(0.2, 0.05, 0.12), Vector3(0, 0.0, 0.32), Color(0.22, 0.26, 0.25), 0.02)


static func _dumpster(r: Node3D) -> void:
	box(r, "Body", Vector3(1.8, 1.0, 0.9), Vector3(0, 0.12, 0), Color(0.2, 0.58, 0.32), 0.08)
	box(r, "Lid", Vector3(1.86, 0.12, 0.96), Vector3(0, 1.12, 0), Color(0.12, 0.16, 0.15), 0.04)
	box(r, "Stripe", Vector3(1.82, 0.12, 0.92), Vector3(0, 0.6, 0), Color(0.16, 0.45, 0.26), 0.04)
	for x in [-0.75, 0.75]:
		box(r, "Wheel", Vector3(0.14, 0.14, 0.14), Vector3(x, 0.0, 0.3), Color(0.1, 0.1, 0.12), 0.04)
		box(r, "Wheel", Vector3(0.14, 0.14, 0.14), Vector3(x, 0.0, -0.3), Color(0.1, 0.1, 0.12), 0.04)


# --- living room -------------------------------------------------------------

static func _couch(r: Node3D) -> void:
	var purple := Color(0.5, 0.36, 0.72)
	var light := Color(0.62, 0.48, 0.84)
	box(r, "Base", Vector3(3.0, 0.4, 1.0), Vector3.ZERO, purple, 0.08)
	box(r, "Back", Vector3(3.0, 0.95, 0.3), Vector3(0, 0.0, -0.35), purple, 0.1)
	for x in [-1.0, 0.0, 1.0]:
		box(r, "Cushion", Vector3(0.94, 0.16, 0.72), Vector3(x * 0.96, 0.4, 0.1), light, 0.06)
	for x in [-1.4, 1.4]:
		box(r, "Arm", Vector3(0.28, 0.68, 1.0), Vector3(x, 0.0, 0.0), purple, 0.09)


static func _coffee_table(r: Node3D) -> void:
	var wood := Color(0.72, 0.5, 0.32)
	box(r, "Top", Vector3(1.2, 0.08, 0.7), Vector3(0, 0.36, 0), wood, 0.03)
	for x in [-0.5, 0.5]:
		for z in [-0.26, 0.26]:
			box(r, "Leg", Vector3(0.08, 0.36, 0.08), Vector3(x, 0.0, z), Color(0.55, 0.38, 0.24), 0.02)
	box(r, "Mug", Vector3(0.1, 0.1, 0.1), Vector3(0.3, 0.44, 0.05), Color(0.95, 0.5, 0.4), 0.03)


static func _rug(r: Node3D) -> void:
	box(r, "Border", Vector3(3.0, 0.04, 2.0), Vector3.ZERO, Color(0.86, 0.38, 0.38), 0.015)
	box(r, "Inner", Vector3(2.6, 0.05, 1.6), Vector3.ZERO, Color(0.98, 0.9, 0.76), 0.015)


static func _tv(r: Node3D) -> void:
	box(r, "Stand", Vector3(1.8, 0.5, 0.6), Vector3.ZERO, Color(0.66, 0.46, 0.3), 0.05)
	box(r, "Frame", Vector3(1.4, 0.82, 0.1), Vector3(0, 0.55, 0), Color(0.1, 0.11, 0.15), 0.04)
	box(r, "Screen", Vector3(1.28, 0.7, 0.02), Vector3(0, 0.61, 0.05), Color(0.3, 0.5, 0.75), 0.005, 0.7)


# --- chores: kitchen, yard ------------------------------------------------------

static func _washing_machine(r: Node3D) -> void:
	box(r, "Body", Vector3(0.88, 0.95, 0.8), Vector3.ZERO, Color(0.9, 0.92, 0.96), 0.07)
	box(r, "Panel", Vector3(0.88, 0.16, 0.04), Vector3(0, 0.78, 0.4), Color(0.55, 0.6, 0.75), 0.02)
	box(r, "Door", Vector3(0.5, 0.5, 0.06), Vector3(0, 0.2, 0.4), Color(0.35, 0.5, 0.7), 0.06)
	box(r, "Glass", Vector3(0.38, 0.38, 0.03), Vector3(0, 0.26, 0.44), Color(0.6, 0.8, 0.95), 0.04, 0.3)
	box(r, "Knob", Vector3(0.1, 0.1, 0.05), Vector3(0.25, 0.8, 0.43), Color(0.95, 0.5, 0.3), 0.03)


static func _sink(r: Node3D) -> void:
	_counter(r)
	box(r, "Basin", Vector3(0.6, 0.06, 0.5), Vector3(0, 0.86, 0.02), Color(0.78, 0.8, 0.86), 0.03)
	box(r, "Water", Vector3(0.5, 0.02, 0.4), Vector3(0, 0.92, 0.02), Color(0.5, 0.75, 0.95), 0.01, 0.3)
	box(r, "TapBase", Vector3(0.08, 0.3, 0.08), Vector3(0, 0.9, -0.28), Color(0.7, 0.72, 0.78), 0.02)
	box(r, "TapSpout", Vector3(0.07, 0.07, 0.24), Vector3(0, 1.14, -0.17), Color(0.7, 0.72, 0.78), 0.02)


static func _stain(r: Node3D) -> void:
	var c := Color(0.32, 0.2, 0.14)
	box(r, "Blob1", Vector3(0.7, 0.03, 0.55), Vector3.ZERO, c, 0.012)
	box(r, "Blob2", Vector3(0.45, 0.03, 0.7), Vector3(0.1, 0, 0.05), c, 0.012)
	box(r, "Blob3", Vector3(0.25, 0.03, 0.25), Vector3(-0.35, 0, -0.2), c, 0.012)
	box(r, "Blob4", Vector3(0.18, 0.03, 0.18), Vector3(0.38, 0, 0.3), c, 0.012)


static func _clothesline(r: Node3D) -> void:
	for x in [-0.9, 0.9]:
		box(r, "Pole", Vector3(0.1, 1.9, 0.1), Vector3(x, 0, 0), Color(0.6, 0.45, 0.3), 0.03)
	box(r, "Line", Vector3(1.8, 0.03, 0.03), Vector3(0, 1.75, 0), Color(0.9, 0.9, 0.85), 0.01)
	var colors := [Color(0.95, 0.4, 0.5), Color(0.4, 0.7, 0.95), Color(0.98, 0.85, 0.35)]
	for i in 3:
		box(r, "Cloth", Vector3(0.36, 0.5, 0.04), Vector3(-0.55 + i * 0.55, 1.25, 0), colors[i], 0.02)


static func _mailbox(r: Node3D) -> void:
	box(r, "Post", Vector3(0.12, 0.9, 0.12), Vector3.ZERO, Color(0.6, 0.45, 0.3), 0.03)
	box(r, "Box", Vector3(0.45, 0.3, 0.7), Vector3(0, 0.9, 0), Color(0.85, 0.3, 0.3), 0.07)
	box(r, "Flag", Vector3(0.04, 0.3, 0.12), Vector3(0.24, 0.98, -0.1), Color(0.98, 0.85, 0.3), 0.01)


static func _leash_hook(r: Node3D) -> void:
	box(r, "Board", Vector3(0.7, 0.9, 0.08), Vector3(0, 0.7, -0.14), Color(0.62, 0.42, 0.26), 0.03)
	box(r, "Hook", Vector3(0.06, 0.06, 0.12), Vector3(0, 1.3, -0.06), Color(0.8, 0.8, 0.85), 0.015)
	box(r, "Leash", Vector3(0.05, 0.5, 0.03), Vector3(0, 0.8, -0.08), Color(0.9, 0.25, 0.3), 0.01)


static func _dog(r: Node3D) -> void:
	var fur := Color(0.85, 0.62, 0.35)
	box(r, "Body", Vector3(0.4, 0.38, 0.7), Vector3(0, 0.22, 0), fur, 0.07)
	box(r, "Head", Vector3(0.32, 0.3, 0.32), Vector3(0, 0.45, 0.4), fur, 0.07)
	box(r, "Snout", Vector3(0.16, 0.12, 0.14), Vector3(0, 0.46, 0.6), Color(0.95, 0.85, 0.7), 0.03)
	box(r, "Nose", Vector3(0.06, 0.05, 0.04), Vector3(0, 0.52, 0.68), Color(0.1, 0.1, 0.12), 0.01)
	box(r, "EarL", Vector3(0.08, 0.2, 0.1), Vector3(-0.18, 0.5, 0.38), Color(0.6, 0.4, 0.22), 0.03)
	box(r, "EarR", Vector3(0.08, 0.2, 0.1), Vector3(0.18, 0.5, 0.38), Color(0.6, 0.4, 0.22), 0.03)
	box(r, "Tail", Vector3(0.07, 0.07, 0.3), Vector3(0, 0.45, -0.45), fur, 0.02)
	for x in [-0.14, 0.14]:
		box(r, "FrontLeg", Vector3(0.1, 0.22, 0.1), Vector3(x, 0.0, 0.25), fur, 0.03)
		box(r, "BackLeg", Vector3(0.1, 0.22, 0.1), Vector3(x, 0.0, -0.25), fur, 0.03)


static func _car(r: Node3D) -> void:
	box(r, "Body", Vector3(1.9, 0.5, 0.92), Vector3(0, 0.22, 0), Color(0.9, 0.4, 0.3), 0.08)
	box(r, "Cabin", Vector3(1.0, 0.4, 0.8), Vector3(-0.1, 0.72, 0), Color(0.95, 0.55, 0.45), 0.08)
	box(r, "Window", Vector3(0.92, 0.26, 0.82), Vector3(-0.1, 0.79, 0), Color(0.6, 0.8, 0.92), 0.05, 0.2)
	box(r, "Trunk", Vector3(0.04, 0.3, 0.7), Vector3(-0.95, 0.4, 0), Color(0.7, 0.28, 0.2), 0.01)
	for x in [-0.6, 0.6]:
		for z in [-0.42, 0.42]:
			box(r, "Wheel", Vector3(0.34, 0.34, 0.12), Vector3(x, 0.0, z), Color(0.12, 0.12, 0.15), 0.05)


# --- dinner ---------------------------------------------------------------------

static func _stove(r: Node3D) -> void:
	_counter(r)
	box(r, "Cooktop", Vector3(0.84, 0.04, 0.7), Vector3(0, 0.91, 0), Color(0.15, 0.15, 0.18), 0.015)
	for x in [-0.2, 0.2]:
		for z in [-0.15, 0.15]:
			box(r, "Burner", Vector3(0.22, 0.02, 0.22), Vector3(x, 0.95, z), Color(0.35, 0.35, 0.4), 0.01)
	box(r, "Pot", Vector3(0.34, 0.26, 0.34), Vector3(-0.2, 0.95, 0.15), Color(0.75, 0.78, 0.85), 0.05)
	box(r, "PotHandle", Vector3(0.14, 0.04, 0.05), Vector3(-0.42, 1.12, 0.15), Color(0.2, 0.2, 0.24), 0.01)
	box(r, "Knob", Vector3(0.07, 0.07, 0.04), Vector3(0.22, 0.75, 0.42), Color(0.95, 0.5, 0.3), 0.02)
	box(r, "Knob", Vector3(0.07, 0.07, 0.04), Vector3(-0.22, 0.75, 0.42), Color(0.95, 0.5, 0.3), 0.02)


static func _dining_table(r: Node3D) -> void:
	var wood := Color(0.7, 0.48, 0.3)
	box(r, "Top", Vector3(1.95, 0.08, 0.92), Vector3(0, 0.72, 0), wood, 0.03)
	box(r, "Cloth", Vector3(1.9, 0.02, 0.5), Vector3(0, 0.8, 0), Color(0.98, 0.9, 0.75), 0.008)
	for x in [-0.85, 0.85]:
		for z in [-0.38, 0.38]:
			box(r, "Leg", Vector3(0.09, 0.72, 0.09), Vector3(x, 0.0, z), Color(0.55, 0.38, 0.24), 0.02)


static func _chair(r: Node3D) -> void:
	var wood := Color(0.62, 0.42, 0.26)
	box(r, "Seat", Vector3(0.5, 0.06, 0.5), Vector3(0, 0.42, 0), wood, 0.02)
	box(r, "Back", Vector3(0.5, 0.5, 0.06), Vector3(0, 0.48, -0.22), wood, 0.02)
	for x in [-0.2, 0.2]:
		for z in [-0.2, 0.2]:
			box(r, "Leg", Vector3(0.05, 0.42, 0.05), Vector3(x, 0.0, z), Color(0.5, 0.34, 0.2), 0.01)


static func _bus(r: Node3D) -> void:
	var yellow := Color(0.98, 0.78, 0.15)
	box(r, "Body", Vector3(2.1, 1.1, 5.0), Vector3(0, 0.3, 0), yellow, 0.12)
	box(r, "Roof", Vector3(1.96, 0.18, 4.7), Vector3(0, 1.4, 0), Color(0.99, 0.84, 0.3), 0.06)
	box(r, "Stripe", Vector3(2.14, 0.1, 5.04), Vector3(0, 0.78, 0), Color(0.15, 0.15, 0.18), 0.02)
	box(r, "Hood", Vector3(1.9, 0.5, 0.9), Vector3(0, 0.3, 2.7), yellow, 0.1)
	for z in [-1.7, -0.9, -0.1, 0.7]:
		box(r, "WindowL", Vector3(0.04, 0.4, 0.55), Vector3(-1.06, 0.95, z), Color(0.55, 0.78, 0.92), 0.01, 0.2)
		box(r, "WindowR", Vector3(0.04, 0.4, 0.55), Vector3(1.06, 0.95, z), Color(0.55, 0.78, 0.92), 0.01, 0.2)
	box(r, "Door", Vector3(0.05, 0.9, 0.7), Vector3(-1.07, 0.35, 1.5), Color(0.3, 0.55, 0.7), 0.01)
	box(r, "StopSign", Vector3(0.05, 0.3, 0.3), Vector3(-1.12, 0.85, 0.35), Color(0.9, 0.2, 0.2), 0.02)
	box(r, "Windshield", Vector3(1.8, 0.45, 0.04), Vector3(0, 0.9, 2.28), Color(0.55, 0.78, 0.92), 0.01, 0.2)
	for x in [-1.0, 1.0]:
		for z in [-1.6, 1.6]:
			box(r, "Wheel", Vector3(0.18, 0.5, 0.5), Vector3(x, 0.0, z), Color(0.1, 0.1, 0.12), 0.06)


static func _kid(r: Node3D, shirt: Color, hair: Color, pigtails: bool) -> void:
	var inner := Node3D.new()
	inner.name = "KidBody"
	inner.scale = Vector3.ONE * 0.7
	r.add_child(inner)
	for side in [-1.0, 1.0]:
		var leg := pivot(inner, "LegL" if side < 0.0 else "LegR", Vector3(side * 0.11, 0.8, 0.0))
		box(leg, "Thigh", Vector3(0.18, 0.4, 0.2), Vector3(0, -0.4, 0), Color(0.3, 0.4, 0.7))
		var knee := pivot(leg, "KneeL" if side < 0.0 else "KneeR", Vector3(0, -0.4, 0))
		box(knee, "Shin", Vector3(0.17, 0.28, 0.18), Vector3(0, -0.28, 0), Color(0.3, 0.4, 0.7))
		box(knee, "Shoe", Vector3(0.2, 0.12, 0.32), Vector3(0, -0.4, 0.06), Color(0.95, 0.95, 0.95), 0.05)
		var arm := pivot(inner, "ArmL" if side < 0.0 else "ArmR", Vector3(side * 0.3, 1.34, 0.0))
		box(arm, "Sleeve", Vector3(0.15, 0.2, 0.17), Vector3(0, -0.2, 0), shirt)
		box(arm, "Forearm", Vector3(0.12, 0.32, 0.14), Vector3(0, -0.52, 0), SKIN)
	box(inner, "Torso", Vector3(0.46, 0.58, 0.28), Vector3(0, 0.8, 0), shirt, 0.06)
	var head := pivot(inner, "Head", Vector3(0, 1.4, 0))
	box(head, "Skull", Vector3(0.42, 0.4, 0.38), Vector3.ZERO, SKIN, 0.07)
	box(head, "Hair", Vector3(0.44, 0.14, 0.4), Vector3(0, 0.34, 0), hair, 0.04)
	box(head, "EyeL", Vector3(0.06, 0.07, 0.02), Vector3(-0.1, 0.2, 0.195), Color(0.12, 0.1, 0.1), 0.01)
	box(head, "EyeR", Vector3(0.06, 0.07, 0.02), Vector3(0.1, 0.2, 0.195), Color(0.12, 0.1, 0.1), 0.01)
	box(head, "Mouth", Vector3(0.1, 0.03, 0.02), Vector3(0, 0.07, 0.195), Color(0.75, 0.25, 0.3), 0.01)
	if pigtails:
		box(head, "PigtailL", Vector3(0.12, 0.3, 0.12), Vector3(-0.27, 0.0, 0.0), hair, 0.04)
		box(head, "PigtailR", Vector3(0.12, 0.3, 0.12), Vector3(0.27, 0.0, 0.0), hair, 0.04)


static func _toy_box(r: Node3D) -> void:
	box(r, "Box", Vector3(0.9, 0.5, 0.7), Vector3.ZERO, Color(0.35, 0.6, 0.9), 0.07)
	box(r, "Rim", Vector3(0.96, 0.08, 0.76), Vector3(0, 0.5, 0), Color(0.25, 0.45, 0.8), 0.03)
	box(r, "BlockA", Vector3(0.22, 0.22, 0.22), Vector3(-0.2, 0.58, 0.0), Color(0.95, 0.4, 0.4), 0.04)
	box(r, "BlockB", Vector3(0.2, 0.2, 0.2), Vector3(0.12, 0.58, 0.1), Color(0.98, 0.85, 0.3), 0.04)
	box(r, "BlockC", Vector3(0.18, 0.18, 0.18), Vector3(0.0, 0.78, -0.05), Color(0.5, 0.85, 0.5), 0.04)
