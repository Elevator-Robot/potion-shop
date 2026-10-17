extends Node2D
## A browsing adventurer with directional animations, order and patience.
## The authority's snapshot decides everything; appearance is keyed by its ID.

const Game = preload("res://network/game.gd")
const CharacterAnimation = preload("res://client/character_animation.gd")
const EmoteIcon = preload("res://client/emote_icon.gd")

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
var _emote: Sprite2D
var _last_phase := ""
var _speech: PanelContainer
var _speech_label: Label

func emphasize_request(wrong: bool) -> void:
	if _request_tween != null:
		_request_tween.kill()
	$OrderBubble.scale = Vector2.ONE * 1.15
	$OrderBubble.modulate = Color(1.6, 0.6, 0.6) if wrong else Color(1.3, 1.2, 1.0)
	_request_tween = create_tween().set_parallel(true)
	_request_tween.tween_property($OrderBubble, "scale", Vector2.ONE, 0.6)
	_request_tween.tween_property($OrderBubble, "modulate", Color.WHITE, 0.6)
	if _emote != null:
		_emote.show_emote(1 if wrong else 4, 1.1)


func _ready() -> void:
	animation.idle_durations = Vector4(1.2, 0.3, 0.12, 0.3)
	_emote = EmoteIcon.new()
	add_child(_emote)
	_emote.position = Vector2(24, -40)
	_speech = PanelContainer.new()
	_speech.position = Vector2(-70, -100)
	_speech.z_index = 9
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f1dfbd")
	style.border_color = Color("745867")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	_speech.add_theme_stylebox_override("panel", style)
	_speech_label = Label.new()
	_speech_label.add_theme_color_override("font_color", Color("392f46"))
	_speech_label.add_theme_font_size_override("font_size", 12)
	_speech.add_child(_speech_label)
	add_child(_speech)
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(12,-69),Vector2(22,-69),Vector2(17,-58)])
	tail.color = Color("f1dfbd")
	tail.name = "SpeechTail"
	tail.z_index = 9
	add_child(tail)


func follow_snapshot(state: Dictionary) -> void:
	_target = state.get("position", Game.DOOR_ENTRY)
	_look_facing = float(state.get("facing", PI / 2.0))
	if not _positioned:
		position = _target
		_positioned = true
	var leaving: bool = state.get("phase", "") == "leaving"
	var phase := str(state.get("phase", ""))
	if phase != _last_phase:
		_last_phase = phase
		if leaving and bool(state.get("served", false)):
			_emote.show_emote(0, 2.5)
		elif phase == "waiting":
			_emote.show_emote(2, 1.1)
	var thinking := not leaving and phase not in ["talking", "chatting"] and posmod(int(Time.get_ticks_msec() / 1000) + customer_id * 7, 24) < 3
	order_icon.visible = thinking
	$OrderBubble.visible = thinking
	$OrderBubble.frame = int(Time.get_ticks_msec() / 400) % 4
	_speech.visible = not leaving and bool(state.get("speaking", false))
	$SpeechTail.visible = _speech.visible
	_speech_label.text = str(state.get("speech", ""))
	$BarBg.visible = not leaving
	bar_fill.visible = not leaving
	if bool(state.get("patience_paused", false)):
		bar_fill.color = Color("93cdd5")
	order_label.visible = false
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
