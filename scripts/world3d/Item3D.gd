class_name Item3D
extends Node3D
## A carryable thing in the 3D world: shown as a camera-facing icon that bobs gently. Group "items".

## Icons are preloaded: a texture first loaded inside a draw call can render white.
const ICONS := {
	&"coffee": preload("res://assets/items/coffee.png"),
	&"coffee_milk": preload("res://assets/items/coffee_milk.png"),
	&"trash_bag": preload("res://assets/items/trash_bag.png"),
	&"keys": preload("res://assets/items/keys.png"),
}
const PIXEL_SIZE := 0.0045

var item_id: StringName = &""
## The quest this item belongs to (0 = none). Used to remove it when the quest ends.
var quest_uid: int = 0
## The Player3D carrying it, or null when it lies on the floor.
var holder: Node3D = null

var _sprite: Sprite3D
var _t := 0.0


static func create(id: StringName, uid: int = 0) -> Item3D:
	var item := Item3D.new()
	item.item_id = id
	item.quest_uid = uid
	item.name = "Item_%s" % id
	item.add_to_group("items")
	return item


func _ready() -> void:
	_t = randf() * TAU
	_sprite = Sprite3D.new()
	var tex: Texture2D = ICONS.get(item_id)
	_sprite.texture = tex
	_sprite.pixel_size = PIXEL_SIZE
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.shaded = false
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if tex != null:
		_sprite.offset = Vector2(0.0, tex.get_height() * 0.5) # pivot at the bottom of the icon
	add_child(_sprite)
	add_child(ContactShadow.make(Vector2(0.3, 0.2), 0.12, 0.4))


func _process(delta: float) -> void:
	_t += delta * 3.0
	var lift := 0.0 if holder != null else 0.18 + sin(_t) * 0.05
	_sprite.position.y = lift


## Remove the item from the game, freeing the holder's hands if someone carries it.
func destroy() -> void:
	if is_instance_valid(holder) and holder.get("held_item") == self:
		holder.set("held_item", null)
	holder = null
	queue_free()
