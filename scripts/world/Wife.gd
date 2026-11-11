extends Station
## The wife on the sofa. Her face follows the Wife-O-Meter.

## Real art per mood (wife + sofa in one picture). Any missing one falls back to `texture`.
@export var texture_happy: Texture2D
@export var texture_angry: Texture2D


func _ready() -> void:
	super._ready()
	title_gap = 46.0 if texture == null else 8.0


func _draw_body(box: Rect2) -> void:
	var mood := GameManager.happiness_ratio()
	var art := texture
	if mood >= 0.66 and texture_happy != null:
		art = texture_happy
	elif mood < 0.33 and texture_angry != null:
		art = texture_angry
	if art != null:
		_draw_art(art)
		return
	draw_rect(box, color) # placeholder sofa
	draw_rect(box, color.darkened(0.4), false, 2.0)
	var head := Vector2(0, -size.y - 14.0)
	draw_circle(Vector2(0, -size.y + 14.0), 20.0, Color(0.85, 0.3, 0.55)) # body
	draw_circle(head, 18.0, Color(0.96, 0.78, 0.65).lerp(Color(0.95, 0.4, 0.35), 1.0 - mood))
	draw_circle(head + Vector2(-6, -4), 2.5, Color.BLACK)
	draw_circle(head + Vector2(6, -4), 2.5, Color.BLACK)
	if mood >= 0.5:
		draw_arc(head + Vector2(0, 2), 8.0, 0.2 * PI, 0.8 * PI, 12, Color.BLACK, 2.0) # smile
	else:
		draw_arc(head + Vector2(0, 14), 8.0, 1.2 * PI, 1.8 * PI, 12, Color.BLACK, 2.0) # frown
