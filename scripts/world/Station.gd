class_name Station
extends StaticBody2D
## A piece of furniture. With a station_id it becomes an interactable station used by quest steps.
## Origin = bottom-centre of the box, so Y-sort works. The look is a placeholder drawn in code
## (so it is only visible when the game runs, not in the editor).

@export var station_id: StringName = &""
@export var title: String = ""
@export var size := Vector2(80, 60)
@export var color := Color(0.6, 0.5, 0.4)

## Vertical gap between the box top and the title text.
var title_gap := 8.0
var _focus_stamp := -100000
var _progress := 0.0
var _progress_stamp := -100000


func _ready() -> void:
	if station_id != &"":
		add_to_group("stations")
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x, size.y * 0.5)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0, -size.y * 0.25)
	add_child(shape)


## Distance from a global point to the edge of the station box (0 when inside).
func distance_to(global_point: Vector2) -> float:
	var local := to_local(global_point)
	var closest := Vector2(clampf(local.x, -size.x * 0.5, size.x * 0.5), clampf(local.y, -size.y, 0.0))
	return local.distance_to(closest)


## Called every frame by the player standing next to this station.
func mark_focused() -> void:
	_focus_stamp = Time.get_ticks_msec()


func show_progress(ratio: float) -> void:
	_progress = clampf(ratio, 0.0, 1.0)
	_progress_stamp = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var box := Rect2(-size.x * 0.5, -size.y, size.x, size.y)
	var now := Time.get_ticks_msec()
	_draw_body(box)
	if now - _focus_stamp < 120:
		draw_rect(box.grow(3.0), Color.WHITE, false, 3.0)
	var font := ThemeDB.fallback_font
	var text_y := -size.y - title_gap
	draw_string(font, Vector2(-80, text_y), title, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 14)
	if station_id != &"" and QuestManager.is_station_needed(station_id):
		var bounce := sin(now / 150.0) * 4.0
		draw_string(font, Vector2(-80, text_y - 18.0 + bounce), "!", HORIZONTAL_ALIGNMENT_CENTER, 160.0, 30, Color.YELLOW)
	if now - _progress_stamp < 150:
		var bar := Rect2(-size.x * 0.5, 6.0, size.x, 8.0)
		draw_rect(bar, Color(0, 0, 0, 0.6))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * _progress, bar.size.y)), Color(0.3, 0.9, 0.4))


## Override in subclasses for a custom look.
func _draw_body(box: Rect2) -> void:
	draw_rect(box, color)
	draw_rect(box, color.darkened(0.4), false, 2.0)
