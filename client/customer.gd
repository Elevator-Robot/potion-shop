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
	preload("res://assets/customers/cozy/elf_fantasy.png"),
	preload("res://assets/customers/cozy/knight_fantasy.png"),
	preload("res://assets/customers/cozy/wizard_fantasy.png"),
	preload("res://assets/customers/cozy/dwarf_fantasy.png"),
]
const SKIN_PALETTE_COUNT := 8
## Hold the relaxed pose; keep the blink brief, like the purple shopkeeper.
const IDLE_FRAME_ENDS := [1.2, 1.5, 1.62, 1.92]

## The potion this customer wants, so a caller can look up who is queued.
var order := ""
var customer_id := -1
var skin_palette_index := 0
var _idle_time := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var order_icon: Sprite2D = $OrderIcon
@onready var order_label: Label = $OrderLabel
@onready var bar_fill: ColorRect = $BarFill
@onready var angry_mark: Label = $AngryMark


func _process(delta: float) -> void:
	if not visible:
		return
	_idle_time = fmod(_idle_time + delta, IDLE_FRAME_ENDS[-1])
	_update_idle_frame()


func _update_idle_frame() -> void:
	for frame in IDLE_FRAME_ENDS.size():
		if _idle_time < float(IDLE_FRAME_ENDS[frame]):
			sprite.frame = skin_palette_index * 4 + frame
			return


## `ratio` is 1.0 with a full patience bar and 0.0 when the time is up.
func show_customer(id: int, potion: String, ratio: float, angry: bool) -> void:
	if id != customer_id:
		customer_id = id
		sprite.texture = PORTRAITS[posmod(id - 1, PORTRAITS.size())]
		# Cycle skin palettes independently of outfits, without consuming gameplay
		# RNG or changing across snapshots, queue positions, or co-op clients.
		var appearance := maxi(id - 1, 0)
		skin_palette_index = posmod(appearance * 3 + floori(float(appearance) / PORTRAITS.size()), SKIN_PALETTE_COUNT)
		_idle_time = posmod(id, 4) * 0.41
		_update_idle_frame()
	order = potion
	var left := clampf(ratio, 0.0, 1.0)
	order_icon.modulate = Game.item_color(potion)
	order_label.text = Game.item_label(potion)
	# Anger is communicated by the mark/bar, not by replacing fantasy skin colors.
	sprite.modulate = Color.WHITE
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
