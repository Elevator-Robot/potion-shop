@tool
extends StaticBody2D
## Furniture is empty artwork. Inventory is a separate set of animated item
## instances anchored to its shelf boards; nothing is baked into the cabinet.
const Game = preload("res://network/game.gd")
const ItemIcon = preload("res://client/item_icon.gd")
const SHELVES = preload("res://assets/furniture/library/shelves.png")
const CHEST = preload("res://assets/environment/pixel_shop/chest.png")
const POT = preload("res://assets/props/cauldron/cauldron.png")
const LIQUID = preload("res://assets/props/cauldron/liquid.png")
const ITEM_SCALE := 0.7

@export var prop_id := "":
	set(value):
		prop_id = value
		if is_node_ready():
			_configure()

var _kind := ""
var _variant := 0
var _pulse_until := 0
var _open := 0.0
var _cauldron := {}
var _stock := {}
var _slots: Array[Vector2] = []
var _slot_items: Array[String] = []
var _icons: Array = []
var selected_item := ""
var _highlighted := false
var _placement := ""
var _result_icon: Sprite2D
var _input_icons: Array[Sprite2D] = []
var _last_mouse := Vector2.INF

func _ready() -> void:
	_configure()

func _configure() -> void:
	if not Game.FURNITURE.has(prop_id):
		return
	var data: Dictionary = Game.FURNITURE[prop_id]
	position = data["at"]
	_kind = data["kind"]
	_variant = int(data.get("variant", 0))
	var points := Game.furniture_polygon(prop_id).duplicate()
	for i in points.size():
		points[i] -= position
	var shape := ConvexPolygonShape2D.new()
	shape.points = points
	$Collision.shape = shape
	$Collision.position = Vector2.ZERO
	var sprite: Sprite2D = $Sprite
	sprite.hframes = 4
	sprite.vframes = 9 if _kind == "shelf" else (3 if _kind == "cauldron" else 1)
	sprite.texture = SHELVES if _kind == "shelf" else (CHEST if _kind == "storage" else POT)
	sprite.scale = Vector2.ONE * 1.5
	var size := sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes) * sprite.scale
	sprite.position = Vector2(-size.x * 0.5, -size.y)
	sprite.frame = _variant * 4 if _kind == "shelf" else 0
	$Cue.position = Vector2(-8, -size.y - 18)
	if _kind == "shelf":
		$Cue.position.y += [4, 8, 8, 6, 8, 24, 6, 24, 24][_variant] * 1.5
	$Liquid.texture = LIQUID
	$Liquid.hframes = 4
	$Liquid.vframes = 3
	$Liquid.scale = sprite.scale
	$Liquid.position = sprite.position
	$Liquid.visible = false
	if Engine.is_editor_hint():
		return
	if _kind == "shelf" and _icons.is_empty():
		_build_stock_slots()
	if _kind == "cauldron" and _result_icon == null:
		_result_icon = ItemIcon.new()
		add_child(_result_icon)
		_result_icon.position = Vector2(0, -110)
		_result_icon.visible = false
		for i in 2:
			var icon := ItemIcon.new()
			add_child(icon)
			icon.position = Vector2(-18 + i * 36, -110)
			icon.scale = Vector2.ONE * 0.7
			icon.visible = false
			_input_icons.append(icon)

func _build_stock_slots() -> void:
	_slots = Game.shelf_slots(prop_id)
	var items := Game.shelf_items(prop_id)
	selected_item = str(items[0])
	for i in _slots.size():
		var item := str(items[i % items.size()])
		_slot_items.append(item)
		var stack: Array = []
		for copy in 3:
			var icon := ItemIcon.new()
			add_child(icon)
			icon.set_item(item)
			icon.scale = Vector2.ONE * ITEM_SCALE
			# Align the actual item bottom (source y≈38), not empty canvas padding.
			icon.position = _slots[i] - Vector2(0, 18 * ITEM_SCALE) + Vector2(copy * 2, -copy * 2)
			icon.visible = false
			stack.append(icon)
		_icons.append(stack)

func choose_item(mouse: Vector2, held: String = "") -> String:
	if _kind != "shelf":
		return ""
	_placement = held if Game.shelf_items(prop_id).has(held) else ""
	if _placement != "":
		selected_item = _placement
	elif mouse.distance_to(_last_mouse) > 1.0:
		var nearest := 19.0
		for i in _slots.size():
			var center := global_position + _slots[i] - Vector2(0, 14)
			var distance := center.distance_to(mouse)
			if distance < nearest:
				selected_item = _slot_items[i]
				nearest = distance
	_last_mouse = mouse
	_refresh_stock()
	return selected_item

func mouse_over_stock(mouse: Vector2) -> bool:
	for slot in _slots:
		if (global_position + slot - Vector2(0, 14)).distance_to(mouse) < 19.0:
			return true
	return false

func cycle_selection() -> void:
	var items := Game.shelf_items(prop_id)
	if items.is_empty():
		return
	selected_item = str(items[(items.find(selected_item) + 1) % items.size()])
	_refresh_stock()

func select_item(item: String) -> void:
	if Game.shelf_items(prop_id).has(item):
		selected_item = item
		_refresh_stock()

func _refresh_stock() -> void:
	var seen := {}
	for i in _icons.size():
		var item := _slot_items[i]
		var repeats := _slot_items.count(item)
		var ordinal := int(seen.get(item, 0))
		seen[item] = ordinal + 1
		var total := int(_stock.get(item, 0))
		var share := total / repeats + (1 if ordinal < total % repeats else 0)
		for copy in 3:
			var icon: Sprite2D = _icons[i][copy]
			var ghost := copy == 0 and total == 0 and _highlighted and _placement == item
			icon.visible = copy < mini(share, 3) or ghost
			icon.modulate = Color(1, 1, 1, 0.3) if ghost else Color.WHITE
			icon.scale = Vector2.ONE * ITEM_SCALE * (1.12 if _highlighted and selected_item == item else 1.0)

func item_position(item: String) -> Vector2:
	if _kind == "shelf":
		var index := _slot_items.find(item)
		if index >= 0:
			return global_position + _slots[index] - Vector2(0, 14)
	return global_position - Vector2(0, 64 if _kind == "cauldron" else 30)

func set_highlighted(on: bool) -> void:
	_highlighted = on
	$Cue.visible = on
	_refresh_stock()

func interact() -> void:
	_pulse_until = Time.get_ticks_msec() + (1000 if _kind == "storage" else 450)

func apply_shop(document: Dictionary) -> void:
	_cauldron = document.get("cauldron", {})
	_stock = document.get("shelf_stock", {}).get(prop_id, {})
	_refresh_stock()

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _kind == "":
		return
	var now := Time.get_ticks_msec()
	match _kind:
		"shelf":
			$Sprite.frame = _variant * 4 + (1 + int(now / 100) % 3 if now < _pulse_until else 0)
		"storage":
			_open = move_toward(_open, 1.0 if now < _pulse_until else 0.0, delta * 5.0)
			$Sprite.frame = roundi(_open * 3.0)
		"cauldron":
			var potion := str(_cauldron.get("potion", ""))
			var ready := bool(_cauldron.get("ready", false))
			var row := 2 if ready else (1 if potion != "" else 0)
			$Sprite.frame = row * 4 + int(now / 250) % 4
			$Liquid.visible = not (_cauldron.get("contents", []) as Array).is_empty() or potion != ""
			$Liquid.frame = row * 4 + int(now / (150 if now < _pulse_until else 300)) % 4
			$Liquid.modulate = Game.item_color(potion) if potion != "" else Color(0.55, 0.9, 0.7)
			if potion != "":
				_result_icon.set_item(potion)
			_result_icon.visible = potion != ""
			_result_icon.modulate.a = 1.0 if ready else 0.45
			_result_icon.position.y = -110 + sin(now * 0.003) * 2
			var contents: Array = _cauldron.get("contents", [])
			for i in _input_icons.size():
				if i < contents.size():
					_input_icons[i].set_item(str(contents[i]))
				_input_icons[i].visible = i < contents.size() and potion == ""
