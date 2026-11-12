class_name HouseBuilder
extends Node3D
## Turns HouseLayout (grid data) into 3D: floor tiles per zone, cut-away walls with a doorframe,
## half walls, furniture and stations. Everything snaps to the 1 m grid, so nothing overlaps.

const T := HouseLayout.WALL_THICKNESS

const KITCHEN_A := Color(0.5, 0.72, 0.7)
const KITCHEN_B := Color(0.64, 0.82, 0.8)
const WOOD_A := Color(0.74, 0.47, 0.27)
const WOOD_B := Color(0.69, 0.43, 0.24)
const GRASS_A := Color(0.45, 0.74, 0.32)
const GRASS_B := Color(0.5, 0.79, 0.36)
const PATH_A := Color(0.64, 0.6, 0.55)
const PATH_B := Color(0.58, 0.54, 0.5)
const WALL := Color(0.9, 0.79, 0.64)
const WALL_LOW := Color(0.86, 0.68, 0.5)
const FRAME := Color(0.62, 0.42, 0.26)
const EARTH := Color(0.36, 0.26, 0.24)

var _map: Array = HouseLayout.MAP


func build() -> void:
	_build_base()
	_build_floor()
	_build_walls()
	_build_partitions()
	_build_door_frame()
	_build_furniture()
	_build_boundary()


# --- floor -------------------------------------------------------------------

func _build_base() -> void:
	var w := float(_map[0].length())
	var d := float(_map.size())
	var base := PlaceholderFactory.box(self, "Base", Vector3(w + 2.0, 0.6, d + 2.0), Vector3(w * 0.5, -0.8, d * 0.5), EARTH, 0.1)
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_floor() -> void:
	var floor_root := Node3D.new()
	floor_root.name = "Floor"
	add_child(floor_root)
	for z in _map.size():
		var row: String = _map[z]
		for x in row.length():
			var color := _floor_color(row[x], x, z)
			if color.a == 0.0:
				continue
			var tile := PlaceholderFactory.box(floor_root, "Tile_%d_%d" % [x, z], Vector3(1.0, 0.2, 1.0), Vector3(x + 0.5, -0.2, z + 0.5), color, 0.02)
			tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _floor_color(ch: String, x: int, z: int) -> Color:
	var checker := (x + z) % 2 == 0
	match ch:
		"k": return KITCHEN_A if checker else KITCHEN_B
		"w", "D": return WOOD_A if x % 2 == 0 else WOOD_B
		"g": return GRASS_A if checker else GRASS_B
		"p": return PATH_A if checker else PATH_B
	return Color(0, 0, 0, 0)


# --- walls -------------------------------------------------------------------

func _is_inside(x: int, z: int) -> bool:
	if z < 0 or z >= _map.size() or x < 0 or x >= String(_map[z]).length():
		return false
	return "kwD".contains(String(_map[z])[x])


## True when cell (x, z) is inside and its neighbour in direction (dx, dz) is not.
func _needs_wall(x: int, z: int, dx: int, dz: int) -> bool:
	if not _is_inside(x, z) or _is_inside(x + dx, z + dz):
		return false
	# The doorway keeps its east edge open.
	return not (dx == 1 and String(_map[z])[x] == "D")


func _build_walls() -> void:
	var walls := Node3D.new()
	walls.name = "Walls"
	add_child(walls)
	var w := String(_map[0]).length()
	var d := _map.size()
	# North and south walls run along x; they extend by T to close the corners.
	for z in d:
		_run_walls(walls, w, true, z, 0, -1, HouseLayout.WALL_HEIGHT, WALL, "North")
		_run_walls(walls, w, true, z, 0, 1, HouseLayout.FRONT_WALL_HEIGHT, WALL_LOW, "SouthLow")
	# West and east walls run along z.
	for x in w:
		_run_walls(walls, d, false, x, -1, 0, HouseLayout.WALL_HEIGHT, WALL, "West")
		_run_walls(walls, d, false, x, 1, 0, HouseLayout.WALL_HEIGHT, WALL, "East")


## Finds runs of consecutive cells along a line that need a wall and builds one box per run.
## along_x: the line is a row z = line, cells are x; else the line is a column x = line, cells are z.
func _run_walls(parent: Node3D, length: int, along_x: bool, line: int, dx: int, dz: int, height: float, color: Color, label: String) -> void:
	var start := -1
	for i in length + 1:
		var need := false
		if i < length:
			need = _needs_wall(i, line, dx, dz) if along_x else _needs_wall(line, i, dx, dz)
		if need and start < 0:
			start = i
		elif not need and start >= 0:
			_add_wall(parent, along_x, line, start, i, dx, dz, height, color, label)
			start = -1


func _add_wall(parent: Node3D, along_x: bool, line: int, from: int, to: int, dx: int, dz: int, height: float, color: Color, label: String) -> void:
	var run := float(to - from)
	var size: Vector3
	var center: Vector3
	if along_x:
		var edge_z := float(line) + (1.0 if dz > 0 else 0.0)
		var z_center := edge_z + (T * 0.5 if dz > 0 else -T * 0.5)
		size = Vector3(run + T * 2.0, height, T)
		center = Vector3(from + run * 0.5, 0.0, z_center)
	else:
		var edge_x := float(line) + (1.0 if dx > 0 else 0.0)
		var x_center := edge_x + (T * 0.5 if dx > 0 else -T * 0.5)
		size = Vector3(T, height, run)
		center = Vector3(x_center, 0.0, from + run * 0.5)
	_solid_box(parent, "%s_%d_%d" % [label, line, from], size, center, color, 0.06)


## A visible, collidable box standing on the floor (center.y is ignored: the bottom sits at y = 0).
func _solid_box(parent: Node3D, box_name: String, size: Vector3, center: Vector3, color: Color, bevel: float) -> void:
	var holder := StaticBody3D.new()
	holder.name = box_name
	holder.collision_layer = Station3D.LAYER_WORLD
	holder.collision_mask = 0
	holder.position = Vector3(center.x, 0.0, center.z)
	parent.add_child(holder)
	PlaceholderFactory.box(holder, "Mesh", size, Vector3.ZERO, color, bevel)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = Vector3(0.0, size.y * 0.5, 0.0)
	holder.add_child(shape)
	holder.add_child(ContactShadow.make(Vector2(size.x, size.z), 0.5, 0.35))


func _build_partitions() -> void:
	var parts := Node3D.new()
	parts.name = "Partitions"
	add_child(parts)
	for p in HouseLayout.PARTITIONS:
		var length: float = p["z1"] - p["z0"]
		_solid_box(parts, "Half", Vector3(0.28, 0.9, length), Vector3(p["x"], 0.0, p["z0"] + length * 0.5), WALL_LOW, 0.06)
		var cap := PlaceholderFactory.box(parts, "Cap", Vector3(0.36, 0.06, length + 0.02), Vector3(p["x"], 0.9, p["z0"] + length * 0.5), FRAME, 0.02)
		cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_door_frame() -> void:
	# Find the vertical range of 'D' cells in the east wall.
	var rows: Array[int] = []
	var door_x := -1
	for z in _map.size():
		var x := String(_map[z]).find("D")
		if x >= 0:
			rows.append(z)
			door_x = x
	if rows.is_empty():
		return
	var z0 := float(rows[0])
	var z1 := float(rows[-1] + 1)
	var frame := Node3D.new()
	frame.name = "DoorFrame"
	add_child(frame)
	var x_center := door_x + 1.0 + T * 0.5
	var depth := T + 0.14
	var post := 0.2
	var h := HouseLayout.WALL_HEIGHT
	PlaceholderFactory.box(frame, "PostA", Vector3(depth, h + 0.04, post), Vector3(x_center, 0.0, z0 - post * 0.25), FRAME, 0.04)
	PlaceholderFactory.box(frame, "PostB", Vector3(depth, h + 0.04, post), Vector3(x_center, 0.0, z1 + post * 0.25), FRAME, 0.04)
	PlaceholderFactory.box(frame, "Lintel", Vector3(depth, 0.4, z1 - z0 + post * 1.5), Vector3(x_center, h - 0.4, (z0 + z1) * 0.5), FRAME, 0.04)
	PlaceholderFactory.box(frame, "Threshold", Vector3(T + 0.1, 0.05, z1 - z0), Vector3(x_center, 0.0, (z0 + z1) * 0.5), Color(0.55, 0.52, 0.5), 0.02)


# --- furniture ---------------------------------------------------------------

func _build_furniture() -> void:
	var furniture := Node3D.new()
	furniture.name = "Furniture"
	add_child(furniture)
	for def in HouseLayout.STATIONS:
		var station: Station3D = Wife3D.new() if def.get("script", "") == "wife" else Station3D.new()
		furniture.add_child(station)
		station.setup(def)
	for def in HouseLayout.PROPS:
		var prop := Station3D.new()
		furniture.add_child(prop)
		prop.setup(def)


## Invisible walls around the whole map so nobody can walk off the diorama.
func _build_boundary() -> void:
	var w := float(String(_map[0]).length())
	var d := float(_map.size())
	var body := StaticBody3D.new()
	body.name = "Boundary"
	body.collision_layer = Station3D.LAYER_WORLD
	body.collision_mask = 0
	add_child(body)
	for rect in [
		Rect2(-1.0, -1.0, w + 2.0, 1.0),
		Rect2(-1.0, d, w + 2.0, 1.0),
		Rect2(-1.0, 0.0, 1.0, d),
		Rect2(w, 0.0, 1.0, d),
	]:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(rect.size.x, 3.0, rect.size.y)
		shape.shape = box
		shape.position = Vector3(rect.get_center().x, 1.5, rect.get_center().y)
		body.add_child(shape)
