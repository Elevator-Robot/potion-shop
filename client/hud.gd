extends CanvasLayer
## The shop HUD: visitor orders and patience bars, the day and the
## clock, the coins, the reputation, and what pressing interact would do where
## we are standing. It draws what it is told and counts down locally from the
## authority's timestamps; it never changes any game state.

const Game = preload("res://network/game.gd")
const ItemTile = preload("res://client/item_tile.gd")

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


func _ready() -> void:
	reputation_bar.max_value = Game.REPUTATION_MAX
	hold_bar.max_value = 1.0
	hold_bar.visible = false
	serve_flash.visible = false
	_build_recipes()
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
	_recipe_panel.visible = not _recipe_panel.visible


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


func _refresh_orders(server_now: float, now: int) -> void:
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
