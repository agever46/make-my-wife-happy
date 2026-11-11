class_name Item
extends Node2D
## A carryable thing (coffee cup, trash bag, keys...). Placeholder look is drawn in code.

const LOOKS := {
	&"coffee": [Color(0.45, 0.28, 0.15), "COFFEE"],
	&"coffee_milk": [Color(0.8, 0.65, 0.45), "COFFEE+MILK"],
	&"trash_bag": [Color(0.15, 0.15, 0.18), "TRASH"],
	&"keys": [Color(0.95, 0.8, 0.2), "KEYS"],
}

var item_id: StringName = &""
## The Player carrying this item, or null when it lies on the floor.
var holder: Node = null


static func create(id: StringName) -> Item:
	var item := Item.new()
	item.item_id = id
	item.add_to_group("items")
	return item


## Remove the item from the game, freeing the holder's hands if someone carries it.
func destroy() -> void:
	if is_instance_valid(holder) and holder.get("held_item") == self:
		holder.set("held_item", null)
	holder = null
	queue_free()


func _draw() -> void:
	var look: Array = LOOKS.get(item_id, [Color.MAGENTA, String(item_id)])
	draw_circle(Vector2(0, -12), 12.0, look[0])
	draw_arc(Vector2(0, -12), 12.0, 0.0, TAU, 24, Color.BLACK, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-60, -30), look[1], HORIZONTAL_ALIGNMENT_CENTER, 120.0, 12)
