extends Node2D
## A queued adventurer with an idle sprite, order and patience indicator.
## The authority's snapshot decides everything; appearance is keyed by its ID.

const Game = preload("res://network/game.gd")

const BAR_WIDTH := 40.0
const BAR_FULL := Color(0.42, 0.85, 0.45, 1.0)
const BAR_HALF := Color(0.95, 0.8, 0.32, 1.0)
const BAR_LOW := Color(0.92, 0.3, 0.28, 1.0)
const BODY_ANGRY := Color(0.8, 0.28, 0.24, 1.0)
const PORTRAITS := [
	preload("res://assets/customers/elf_idle.png"),
	preload("res://assets/customers/knight_idle.png"),
	preload("res://assets/customers/wizard_idle.png"),
	preload("res://assets/customers/dwarf_idle.png"),
]

## The potion this customer wants, so a caller can look up who is queued.
var order := ""
var customer_id := -1
var _idle_time := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var order_icon: Sprite2D = $OrderIcon
@onready var order_label: Label = $OrderLabel
@onready var bar_fill: ColorRect = $BarFill
@onready var angry_mark: Label = $AngryMark


func _process(delta: float) -> void:
	if not visible:
		return
	_idle_time = fmod(_idle_time + delta, 0.8)
	sprite.frame = int(_idle_time * 5.0) % 4


## `ratio` is 1.0 with a full patience bar and 0.0 when the time is up.
func show_customer(id: int, potion: String, ratio: float, angry: bool) -> void:
	if id != customer_id:
		customer_id = id
		sprite.texture = PORTRAITS[posmod(id - 1, PORTRAITS.size())]
		_idle_time = posmod(id, 4) * 0.2
	order = potion
	var left := clampf(ratio, 0.0, 1.0)
	order_icon.modulate = Game.item_color(potion)
	order_label.text = Game.item_label(potion)
	sprite.modulate = Color(1.0, 0.65, 0.6) if angry else Color.WHITE
	angry_mark.visible = angry
	bar_fill.size = Vector2(BAR_WIDTH * left, bar_fill.size.y)
	if angry:
		bar_fill.color = BODY_ANGRY
	elif left > 0.5:
		bar_fill.color = BAR_FULL
	elif left > 0.25:
		bar_fill.color = BAR_HALF
	else:
		bar_fill.color = BAR_LOW
