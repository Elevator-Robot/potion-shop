extends CanvasLayer
## The shop HUD: the queued orders and their patience bars, the day and the
## clock, the coins, the reputation, and what pressing interact would do where
## we are standing. It draws what it is told and counts down locally from the
## authority's timestamps; it never changes any game state.

const Game = preload("res://network/game.gd")

const ROW_NAME_WIDTH := 74.0
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


func _ready() -> void:
	reputation_bar.max_value = Game.REPUTATION_MAX
	hold_bar.max_value = 1.0
	hold_bar.visible = false
	serve_flash.visible = false
	_refresh()


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
			return "Stand closer to the station"
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
		"already_prepped":
			return "That is already chopped"
		"needs_prep":
			return "Chop it at the prep station first"
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
		var name_label: Label = row["name"]
		var bar: ProgressBar = row["bar"]
		name_label.text = "%d. %s" % [i + 1, Game.item_label(str(entry.get("order", "")))]
		name_label.add_theme_color_override("font_color", ANGRY_TEXT if angry else CALM_TEXT)
		bar.value = clampf(remaining / total, 0.0, 1.0)
		bar.modulate = ANGRY_TEXT if angry else Color(1.0, 1.0, 1.0, 1.0)
	for i in range(customers.size(), _rows.size()):
		var row: Dictionary = _rows[i]
		(row["row"] as Control).visible = false


## One queue row: the customer's place and order, and a bar that drains as
## their patience does. Rows are built once and then only updated.
func _row(index: int) -> Dictionary:
	while _rows.size() <= index:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var name_label := Label.new()
		name_label.custom_minimum_size = Vector2(ROW_NAME_WIDTH, 0.0)
		name_label.add_theme_font_size_override("font_size", 13)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(ROW_BAR_WIDTH, 13.0)
		bar.max_value = 1.0
		bar.value = 1.0
		bar.show_percentage = false
		row.add_child(name_label)
		row.add_child(bar)
		orders.add_child(row)
		_rows.append({"row": row, "name": name_label, "bar": bar})
	var built: Dictionary = _rows[index]
	(built["row"] as Control).visible = true
	return built
