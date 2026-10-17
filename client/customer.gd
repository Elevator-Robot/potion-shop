extends Node2D
## A browsing adventurer with directional animations, order and patience.
## The authority's snapshot decides everything; appearance is keyed by its ID.

const Game = preload("res://network/game.gd")
const CharacterAnimation = preload("res://client/character_animation.gd")

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
const WALK_SPEED := Game.CUSTOMER_SPEED * 1.5
const FRAMES_PER_PALETTE := 24

## The potion this customer wants.
var order := ""
var customer_id := -1
var skin_palette_index := 0
var facing := -PI / 2.0
var animation := CharacterAnimation.new()
var _target := Vector2.ZERO
var _positioned := false
var _look_facing := PI / 2.0

@onready var sprite: Sprite2D = $Sprite
@onready var order_icon: Sprite2D = $OrderIcon
@onready var order_label: Label = $OrderLabel
@onready var bar_fill: ColorRect = $BarFill
@onready var angry_mark: Label = $AngryMark
var _request_tween: Tween

func emphasize_request(wrong: bool) -> void:
	if _request_tween != null:
		_request_tween.kill()
	$OrderBubble.scale = Vector2.ONE * 1.15
	$OrderBubble.modulate = Color(1.6, 0.6, 0.6) if wrong else Color(1.3, 1.2, 1.0)
	_request_tween = create_tween().set_parallel(true)
	_request_tween.tween_property($OrderBubble, "scale", Vector2.ONE, 0.6)
	_request_tween.tween_property($OrderBubble, "modulate", Color.WHITE, 0.6)


func _ready() -> void:
	animation.idle_durations = Vector4(1.2, 0.3, 0.12, 0.3)


func follow_snapshot(state: Dictionary) -> void:
	_target = state.get("position", Game.DOOR_ENTRY)
	_look_facing = float(state.get("facing", PI / 2.0))
	if not _positioned:
		position = _target
		_positioned = true
	var leaving: bool = state.get("phase", "") == "leaving"
	order_icon.visible = not leaving
	$OrderBubble.visible = not leaving or bool(state.get("served", false))
	$BarBg.visible = not leaving
	bar_fill.visible = not leaving
	order_label.visible = leaving and bool(state.get("served", false))
	order_label.text = "♥"


func _process(delta: float) -> void:
	if not visible:
		return
	var previous := position
	if _positioned:
		position = position.move_toward(_target, WALK_SPEED * delta)
	var motion := position - previous
	if motion.length_squared() > 0.0001:
		facing = motion.angle()
	else:
		facing = _look_facing
	animation.advance(delta, motion.length())
	_update_frame()


func _update_frame() -> void:
	sprite.frame = skin_palette_index * FRAMES_PER_PALETTE + animation.frame_index(facing)
	if absf(cos(facing)) > 0.25:
		sprite.flip_h = cos(facing) < 0.0


## `ratio` is 1.0 with a full patience bar and 0.0 when the time is up.
func show_customer(id: int, potion: String, ratio: float, angry: bool) -> void:
	if id != customer_id:
		customer_id = id
		sprite.texture = PORTRAITS[posmod(id - 1, PORTRAITS.size())]
		# Cycle skin palettes independently of outfits, without consuming gameplay
		# RNG or changing across snapshots, queue positions, or co-op clients.
		var appearance := maxi(id - 1, 0)
		skin_palette_index = posmod(appearance * 3 + floori(float(appearance) / PORTRAITS.size()), SKIN_PALETTE_COUNT)
		animation = CharacterAnimation.new()
		animation.idle_durations = Vector4(1.2, 0.3, 0.12, 0.3)
		animation.advance(posmod(id, 4) * 0.41, 0.0)
		_update_frame()
	order = potion
	var left := clampf(ratio, 0.0, 1.0)
	order_icon.set_item(potion)
	order_label.visible = false
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
