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
