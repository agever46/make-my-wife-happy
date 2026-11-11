extends Node2D
## Day 1 map: the house (living room + kitchen) and a strip of yard outside.
## Draws the floor and builds the wall colliders in code. Placeholder look.

const WORLD := Rect2(40, 110, 1200, 580)
const HOUSE := Rect2(120, 150, 740, 510)
const WALL := 14.0
## The door is a gap in the right wall between these Y values.
const DOOR_TOP := 380.0
const DOOR_BOTTOM := 480.0

var _walls: Array[Rect2] = []


func _ready() -> void:
	var h := HOUSE
	_walls = [
		Rect2(h.position.x - WALL, h.position.y - WALL, h.size.x + WALL * 2.0, WALL), # top
		Rect2(h.position.x - WALL, h.end.y, h.size.x + WALL * 2.0, WALL), # bottom
		Rect2(h.position.x - WALL, h.position.y, WALL, h.size.y), # left
		Rect2(h.end.x, h.position.y, WALL, DOOR_TOP - h.position.y), # right, above the door
		Rect2(h.end.x, DOOR_BOTTOM, WALL, h.end.y - DOOR_BOTTOM), # right, below the door
	]
	for wall in _walls:
		_add_collider(wall)
	# Invisible borders so nobody walks off the screen.
	var w := WORLD
	_add_collider(Rect2(w.position.x - 40.0, w.position.y - 40.0, w.size.x + 80.0, 40.0))
	_add_collider(Rect2(w.position.x - 40.0, w.end.y, w.size.x + 80.0, 40.0))
	_add_collider(Rect2(w.position.x - 40.0, w.position.y, 40.0, w.size.y))
	_add_collider(Rect2(w.end.x, w.position.y, 40.0, w.size.y))


func _add_collider(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)


func _draw() -> void:
	draw_rect(WORLD, Color(0.33, 0.55, 0.3)) # grass
	draw_rect(Rect2(HOUSE.end.x, DOOR_TOP, WORLD.end.x - HOUSE.end.x, DOOR_BOTTOM - DOOR_TOP), Color(0.6, 0.58, 0.52)) # path
	draw_rect(HOUSE, Color(0.78, 0.62, 0.45)) # wooden floor
	for wall in _walls:
		draw_rect(wall, Color(0.25, 0.2, 0.25))
