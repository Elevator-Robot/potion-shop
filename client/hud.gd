extends CanvasLayer
## The shop HUD: visitor orders and patience bars, the day and the
## clock, the coins, the reputation, and what pressing interact would do where
## we are standing. It draws what it is told and counts down locally from the
## authority's timestamps; it never changes any game state.

const Game = preload("res://network/game.gd")
const ItemTile = preload("res://client/item_tile.gd")
signal take_requested(station: String, item: String)
signal return_requested(station: String, item: String)
signal selection_requested(item: String)

const ROW_BAR_WIDTH := 104.0
const CALM_TEXT := Color(0.93, 0.9, 0.82, 1.0)
const ANGRY_TEXT := Color(0.98, 0.5, 0.42, 1.0)

@onready var orders: VBoxContainer = %Orders
@onready var day_label: Label = %DayLabel
@onready var clock_label: Label = %ClockLabel
@onready var coins_label: Label = %CoinsLabel
@onready var reputation_bar: ProgressBar = %ReputationBar
@onready var reputation_label: Label = %ReputationLabel
@onready var prompt_label: Label = %PromptLabel
@onready var hold_bar: ProgressBar = %HoldBar
@onready var serve_flash: Label = %ServeFlash
@onready var message_label: Label = %MessageLabel
@onready var timeout_flash: ColorRect = %TimeoutFlash

## The latest Shop document, and our own clock reading when it landed.
var _doc := {}
var _local_at := 0.0
var _rows: Array = []
var _recipe_panel: PanelContainer
var _shelf_panel: PanelContainer
var _shelf_id := ""
var _shelf_buttons := {}
var _return_button: Button
var _bag_buttons: Array = []
var _inventory_ids: Array[String] = []
var local_seat := 0
var _dialogue: PanelContainer

func show_dialogue(value: Dictionary) -> void:
	if is_instance_valid(_dialogue):
		_dialogue.queue_free()
	_dialogue = PanelContainer.new()
	_dialogue.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_dialogue.position = Vector2(-350, -190)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f1dfbd")
	style.border_color = Color("745867")
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.content_margin_left = 16
	style.content_margin_right = 16
	_dialogue.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	for part in [str(value["dialogue_before"]), "", str(value["dialogue_after"])]:
		if part == "":
			var tile := ItemTile.new()
			tile.setup(str(value["potion"]), Vector2(44, 58))
			row.add_child(tile)
		else:
			var label := Label.new()
			label.text = part
			label.add_theme_color_override("font_color", Color("392f46"))
			label.add_theme_font_size_override("font_size", 16)
			row.add_child(label)
	_dialogue.add_child(row)
	$Root.add_child(_dialogue)
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(40,57), Vector2(58,57), Vector2(48,72)])
	tail.color = Color("f1dfbd")
	_dialogue.add_child(tail)
	var bubble: WeakRef = weakref(_dialogue)
	get_tree().create_timer(5.0).timeout.connect(func() -> void:
		var panel: PanelContainer = bubble.get_ref()
		if panel != null: panel.queue_free())
var _slot_normal: StyleBoxFlat
var _slot_selected: StyleBoxFlat


func _ready() -> void:
	reputation_bar.max_value = Game.REPUTATION_MAX
	hold_bar.max_value = 1.0
	hold_bar.visible = false
	serve_flash.visible = false
	_build_recipes()
	_build_inventory()
	_refresh()


func _build_recipes() -> void:
	_recipe_panel = PanelContainer.new()
	_recipe_panel.position = Vector2(16, 170)
	_recipe_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color("191d2c")
	style.border_color = Color("897087")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 8
	_recipe_panel.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	var pages := VBoxContainer.new()
	var title := Label.new()
	title.text = "MATCH THE SHAPES   ·   R to close"
	title.add_theme_font_size_override("font_size", 16)
	pages.add_child(title)
	for potion in Game.POTIONS:
		var row := HBoxContainer.new()
		row.name = "Recipe_" + str(potion)
		row.add_theme_constant_override("separation", 10)
		var needs := Game.recipe_needs(potion)
		var index := 0
		for ingredient in needs:
			if index > 0:
				var plus := Label.new()
				plus.text = "+"
				row.add_child(plus)
			var tile := ItemTile.new()
			tile.setup(ingredient)
			row.add_child(tile)
			index += 1
		var arrow := Label.new()
		arrow.text = "→"
		row.add_child(arrow)
		var result := ItemTile.new()
		result.setup(potion, Vector2(64, 64))
		row.add_child(result)
		pages.add_child(row)
	var hint := Label.new()
	hint.text = "Add the two ingredients. Collect the bottle.\nMatch the bottle beside your customer."
	pages.add_child(hint)
	margin.add_child(pages)
	_recipe_panel.add_child(margin)
	$Root.add_child(_recipe_panel)

func toggle_recipes() -> void:
	if _shelf_panel != null:
		_shelf_panel.visible = false
	_recipe_panel.visible = not _recipe_panel.visible

func _build_inventory() -> void:
	_slot_normal = StyleBoxFlat.new()
	_slot_normal.bg_color = Color("222736")
	_slot_normal.border_color = Color("555165")
	_slot_normal.set_border_width_all(1)
	_slot_selected = _slot_normal.duplicate()
	_slot_selected.border_color = Color("d1bd86")
	_slot_selected.set_border_width_all(2)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -224
	panel.offset_right = 224
	panel.offset_top = -76
	panel.offset_bottom = -8
	panel.add_theme_stylebox_override("panel", _recipe_panel.get_theme_stylebox("panel").duplicate())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for i in Game.INVENTORY_CAPACITY:
		var button := Button.new()
		button.custom_minimum_size = Vector2(50, 60)
		var tile := ItemTile.new()
		tile.setup("", Vector2(44, 48))
		tile.position = Vector2(3, 0)
		button.add_child(tile)
		var count := Label.new()
		count.position = Vector2(4, 43)
		count.add_theme_font_size_override("font_size", 11)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(count)
		button.pressed.connect(_inventory_press.bind(i))
		row.add_child(button)
		_bag_buttons.append({"button": button, "tile": tile, "count": count})
	panel.add_child(row)
	$Root.add_child(panel)

func _inventory_press(index: int) -> void:
	if index >= _inventory_ids.size():
		return
	var item := _inventory_ids[index]
	selection_requested.emit("" if _doc.get("held", {}).get(str(local_seat), "") == item else item)

func select_inventory_slot(index: int) -> void:
	_inventory_press(index)

func open_shelf(station: String) -> void:
	if _shelf_panel != null:
		$Root.remove_child(_shelf_panel)
		_shelf_panel.queue_free()
	_shelf_id = station
	_shelf_buttons.clear()
	_recipe_panel.visible = false
	_shelf_panel = PanelContainer.new()
	_shelf_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_shelf_panel.offset_left = -300
	_shelf_panel.offset_right = -16
	_shelf_panel.offset_top = 120
	_shelf_panel.add_theme_stylebox_override("panel", _recipe_panel.get_theme_stylebox("panel").duplicate())
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	var column := VBoxContainer.new()
	var title := Label.new()
	title.text = "DISCOVERIES   ·   click to collect"
	column.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 3
	for item in Game.shelf_items(station):
		var button := Button.new()
		button.custom_minimum_size = Vector2(80, 86)
		var tile := ItemTile.new()
		tile.setup(str(item), Vector2(72, 68))
		tile.position = Vector2(4, 0)
		button.add_child(tile)
		var count := Label.new()
		count.position = Vector2(8, 65)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(count)
		button.pressed.connect(_shelf_take.bind(station, str(item)))
		grid.add_child(button)
		_shelf_buttons[item] = {"button": button, "count": count}
	column.add_child(grid)
	_return_button = Button.new()
	_return_button.text = "Return selected item"
	_return_button.pressed.connect(func() -> void: return_requested.emit(station, str(_doc.get("held", {}).get(str(local_seat), ""))))
	column.add_child(_return_button)
	var close := Button.new()
	close.text = "Close · Esc"
	close.pressed.connect(func() -> void: _shelf_panel.visible = false)
	column.add_child(close)
	margin.add_child(column)
	_shelf_panel.add_child(margin)
	$Root.add_child(_shelf_panel)
	_shelf_panel.modulate.a = 0.0
	_shelf_panel.create_tween().tween_property(_shelf_panel, "modulate:a", 1.0, 0.18)
	_refresh_inventory()

func _shelf_take(station: String, item: String) -> void:
	take_requested.emit(station, item)

func close_panels() -> bool:
	var was_open := _recipe_panel.visible or (_shelf_panel != null and _shelf_panel.visible)
	_recipe_panel.visible = false
	if _shelf_panel != null:
		_shelf_panel.visible = false
	return was_open

func shelf_open() -> bool:
	return _shelf_panel != null and _shelf_panel.visible

func _refresh_inventory() -> void:
	var bag: Array = _doc.get("inventory", {}).get(str(local_seat), [])
	var counts := {}
	_inventory_ids.clear()
	for item in bag:
		if not counts.has(item):
			_inventory_ids.append(str(item))
		counts[item] = int(counts.get(item, 0)) + 1
	var selected := str(_doc.get("held", {}).get(str(local_seat), ""))
	for i in _bag_buttons.size():
		var entry: Dictionary = _bag_buttons[i]
		var item := _inventory_ids[i] if i < _inventory_ids.size() else ""
		entry["tile"].setup(item, Vector2(44, 48))
		var count := int(counts.get(item, 0))
		if item != "" and (entry.get("item_seen", "") != item or int(entry.get("count_seen", 0)) != count):
			if entry.get("pulse") != null:
				entry["pulse"].kill()
			entry["tile"].pivot_offset = Vector2(22, 24)
			entry["tile"].scale = Vector2.ONE * 0.8
			var pulse := create_tween()
			pulse.tween_property(entry["tile"], "scale", Vector2.ONE * 1.08, 0.12)
			pulse.tween_property(entry["tile"], "scale", Vector2.ONE, 0.12)
			entry["pulse"] = pulse
		entry["item_seen"] = item
		entry["count_seen"] = count
		entry["button"].disabled = item == ""
		entry["button"].add_theme_stylebox_override("normal", _slot_selected if item != "" and item == selected else _slot_normal)
		entry["count"].text = "%d · ×%d" % [i + 1, int(counts.get(item, 0))] if item != "" else str(i + 1)
	if shelf_open():
		var stock: Dictionary = _doc.get("shelf_stock", {}).get(_shelf_id, {})
		for item in _shelf_buttons:
			_shelf_buttons[item]["count"].text = "×%d" % int(stock.get(item, 0))
			_shelf_buttons[item]["button"].disabled = int(stock.get(item, 0)) == 0 or bag.size() >= Game.INVENTORY_CAPACITY
		_return_button.disabled = selected == "" or not Game.shelf_items(_shelf_id).has(selected)


func _process(_delta: float) -> void:
	_refresh()


## The authority published a new Shop document. Everything below is a reading
## of it; a snapshot that arrives late is simply a newer truth.
func set_shop(document: Dictionary, local_at_msec: float) -> void:
	_doc = document
	_local_at = local_at_msec
	_refresh()


## What pressing interact would do right now, "" when there is nothing here.
func set_prompt(label: String) -> void:
	prompt_label.text = label
	prompt_label.visible = label != ""


## How far through a hold action we are, 0.0 when nothing is being held.
func set_hold(ratio: float) -> void:
	hold_bar.value = clampf(ratio, 0.0, 1.0)
	hold_bar.visible = ratio > 0.0


## A potion was accepted: the coins it paid, in gold, then fade.
func flash_serve(amount: int) -> void:
	serve_flash.text = "+%d coins" % amount
	serve_flash.modulate = Color(1.0, 1.0, 1.0, 1.0)
	serve_flash.visible = true
	var tween := create_tween()
	tween.tween_property(serve_flash, "modulate:a", 0.0, 1.2)
	tween.tween_callback(func() -> void: serve_flash.visible = false)


## A customer ran out of patience: a red flush over the screen.
func flash_timeout() -> void:
	timeout_flash.color = Color(0.9, 0.2, 0.2, 0.22)
	var tween := create_tween()
	tween.tween_property(timeout_flash, "color:a", 0.0, 0.6)


## The authority refused a Command: say why, briefly.
func flash_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	message_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(message_label, "modulate:a", 0.0, 1.8)


## A standing message that stays up until it is replaced or cleared: used while
## the client is still joining, so a shop with nothing in it never looks like a
## broken one.
func set_status(text: String) -> void:
	message_label.text = text
	message_label.visible = text != ""
	message_label.modulate = Color(1.0, 1.0, 1.0, 1.0)


func clear_status() -> void:
	set_status("")


## Turns a refusal reason id into something a player can read.
static func refuse_text(reason: String) -> String:
	match reason:
		"too_far":
			return "Move closer to interact"
		"blocked":
			return "Walk around to the open side"
		"wrong_station":
			return "That is not done here"
		"not_joined":
			return "Still joining the shop"
		"not_spawned":
			return "Not in the shop yet"
		"hands_full":
			return "Your hands are full"
		"inventory_full":
			return "Bag full · brew, serve, or return an item"
		"not_in_inventory":
			return "That item is not in your bag"
		"hands_empty":
			return "Your hands are empty"
		"shelf_empty":
			return "That pile is empty"
		"storage_empty":
			return "Storage is empty"
		"storage_full":
			return "Storage is full"
		"wrong_shelf":
			return "That ingredient belongs on a different shelf"
		"shelf_full":
			return "That shelf is full"
		"not_an_ingredient":
			return "The cauldron needs an ingredient"
		"not_a_recipe":
			return "The cauldron will not take that"
		"already_brewing":
			return "The cauldron is busy"
		"not_ready":
			return "The brew is not ready yet"
		"no_customer":
			return "No customer is waiting"
		"wrong_order":
			return "That is the wrong potion"
		"not_a_potion":
			return "That is not a potion"
		_:
			return reason if reason != "" else "That did not work"


## ---------------------------------------------------------------------------
## Everything below is a view of the snapshot; nothing is ever written back.
## ---------------------------------------------------------------------------

func _refresh() -> void:
	if _doc.is_empty():
		return
	var now := Time.get_ticks_msec()
	var server_now := float(_doc.get("now_msec", 0.0))
	var day := int(_doc.get("day", 1))
	var left := maxf(Game.seconds_left(float(_doc.get("day_started_msec", server_now)) + float(_doc.get("day_seconds", Game.DAY_SECONDS)) * 1000.0, server_now, _local_at, now), 0.0)
	day_label.text = "Day %d" % day
	clock_label.text = "%d:%02d until close" % [int(left) / 60, int(left) % 60]
	coins_label.text = "Coins: %d" % int(_doc.get("coins", 0))
	var reputation := int(_doc.get("reputation", 0))
	reputation_bar.value = reputation
	reputation_label.text = "Reputation %d / %d" % [reputation, Game.REPUTATION_MAX]
	_refresh_orders(server_now, now)
	_refresh_inventory()


func _refresh_orders(server_now: float, now: int) -> void:
	orders.visible = false
	return

func _legacy_orders(server_now: float, now: int) -> void:
	var customers: Array = _doc.get("customers", [])
	for i in customers.size():
		var row := _row(i)
		var entry: Dictionary = customers[i]
		var total := maxf(float(entry.get("patience_seconds", 1.0)), 0.001)
		var remaining := maxf(Game.seconds_left(float(entry.get("deadline_msec", 0.0)), server_now, _local_at, now), 0.0)
		var angry := bool(entry.get("angry", false))
		var icon: Control = row["icon"]
		var bar: ProgressBar = row["bar"]
		icon.setup(str(entry.get("order", "")), Vector2(36, 40))
		icon.modulate = Color(1, 1, 1, 0.35) if entry.get("phase", "") == "leaving" else Color.WHITE
		bar.value = clampf(remaining / total, 0.0, 1.0)
		bar.modulate = ANGRY_TEXT if angry else Color(1.0, 1.0, 1.0, 1.0)
	for i in range(customers.size(), _rows.size()):
		var row: Dictionary = _rows[i]
		(row["row"] as Control).visible = false


## One order row: the customer's order, and a bar that drains as
## their patience does. Rows are built once and then only updated.
func _row(index: int) -> Dictionary:
	while _rows.size() <= index:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var icon := ItemTile.new()
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(ROW_BAR_WIDTH, 13.0)
		bar.max_value = 1.0
		bar.value = 1.0
		bar.show_percentage = false
		row.add_child(icon)
		row.add_child(bar)
		orders.add_child(row)
		_rows.append({"row": row, "icon": icon, "bar": bar})
	var built: Dictionary = _rows[index]
	(built["row"] as Control).visible = true
	return built
