extends Control
## Container-friendly visual recipe/order tile using the exact world item sprite.
const ItemIcon = preload("res://client/item_icon.gd")
var icon: Sprite2D

func setup(item: String, tile_size: Vector2 = Vector2(56, 64)) -> void:
	custom_minimum_size = tile_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon == null:
		icon = ItemIcon.new()
		add_child(icon)
	icon.set_item(item)
	icon.position = tile_size * 0.5
	icon.scale = Vector2.ONE * minf((tile_size.x - 8) / 32.0, (tile_size.y - 8) / 40.0)
