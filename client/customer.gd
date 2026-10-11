extends Node2D
## One queued customer: flat placeholder shapes, the potion they are waiting
## for, and how much longer they will wait. Pure drawing - the authority's
## snapshot decides everything and this only shows it.

const Game = preload("res://network/game.gd")

const BAR_WIDTH := 40.0
const BAR_FULL := Color(0.42, 0.85, 0.45, 1.0)
const BAR_HALF := Color(0.95, 0.8, 0.32, 1.0)
const BAR_LOW := Color(0.92, 0.3, 0.28, 1.0)
const BODY_CALM := Color(0.55, 0.5, 0.62, 1.0)
const BODY_ANGRY := Color(0.8, 0.28, 0.24, 1.0)

## The potion this customer wants, so a caller can look up who is queued.
var order := ""

@onready var body: Polygon2D = $Body
@onready var head: Polygon2D = $Head
@onready var order_icon: Polygon2D = $OrderIcon
@onready var order_label: Label = $OrderLabel
@onready var bar_fill: ColorRect = $BarFill


## `ratio` is 1.0 with a full patience bar and 0.0 when the time is up.
func show_customer(potion: String, ratio: float, angry: bool) -> void:
	order = potion
	var left := clampf(ratio, 0.0, 1.0)
	order_icon.color = Game.item_color(potion)
	order_label.text = Game.item_label(potion)
	body.color = BODY_ANGRY if angry else BODY_CALM
	head.color = body.color.darkened(0.15)
	bar_fill.size = Vector2(BAR_WIDTH * left, bar_fill.size.y)
	if angry:
		bar_fill.color = BODY_ANGRY
	elif left > 0.5:
		bar_fill.color = BAR_FULL
	elif left > 0.25:
		bar_fill.color = BAR_HALF
	else:
		bar_fill.color = BAR_LOW
