extends CharacterBody2D
## Our own player. Only this client moves it, and it publishes where it is; the
## authority only snaps us somewhere on spawn, teleport, or a refused pose.
## Flat top-down walking: no gravity, no jumping, no y velocity.

const Game = preload("res://network/game.gd")

## Where the carried item rides above our head, in screen space: the shop is
## top-down, so "up" is -y whatever way we are facing.
const HELD_ABOVE := Vector2(0.0, -34.0)

## One front-facing character per seat: seat 0 is the elf (P1) and seat 1 is the
## robed potion maker (P2). The art is a single static pose, so a texture is all
## each seat needs - there is no walk cycle to play.
const CHARACTERS := {
	0: preload("res://assets/characters/elf.png"),
	1: preload("res://assets/characters/potionmaker.png"),
}
## How tall the character art stands on screen, in pixels: roughly a 32x32
## footprint in a 640x420 room. The art is drawn far larger, so it is shrunk by
## the sprite's whole-number scale rather than scaled up.
const ART_HEIGHT := 32.0
## The art's centre, half its on-screen height above the body origin, so the
## character's feet stay on the player's spot however the body is turned.
const ART_ABOVE := Vector2(0.0, -ART_HEIGHT * 0.5)

var seat := -1
var facing := Game.SPAWN_FACING
## The item the authority says we are carrying, "" for empty hands. It comes
## from the Shop snapshot, never from the pose we publish.
var carrying := ""
var _pose := {}          # the full pose; only position and facing ever change
var _sent := {}
var _send_elapsed := 0.0
var _tinted := -1

@onready var sprite: Sprite2D = $Sprite
@onready var held: Node2D = $Held
@onready var held_icon: Polygon2D = $Held/HeldIcon
@onready var held_label: Label = $Held/HeldLabel


func _ready() -> void:
	Session.corrected.connect(func(pose: Dictionary) -> void: apply_pose(pose, true))


func apply_pose(state: Dictionary, reset: bool) -> void:
	if state.is_empty():
		return
	# Ignore normal snapshot echoes of our own predicted movement. Only spawn
	# and explicit authority corrections reset the local position.
	if not reset and not _pose.is_empty():
		return
	_adopt(state)
	global_position = _pose["position"]
	rotation = float(_pose["facing"])
	facing = float(_pose["facing"])
	velocity = Vector2.ZERO


## Takes a pose as our own, with exactly the declared field types.
func _adopt(state: Dictionary) -> void:
	_pose = Game.pose_from(state)
	_sent = _pose.duplicate()
	seat = int(_pose["seat"])
	_tint(seat)


## Picks the seat's character art. The flat placeholder tint is gone: the art
## itself says who is who, so nothing is ever drawn over the sprite.
func _tint(seat_number: int) -> void:
	if seat_number == _tinted:
		return
	_tinted = seat_number
	_use_character(seat_number)


## Draws the seat's character, sized to stand ART_HEIGHT tall on screen with a
## whole-number scale factor, and kept upright.
func _use_character(seat_number: int) -> void:
	var art: Texture2D = CHARACTERS.get(seat_number, CHARACTERS[0])
	sprite.texture = art
	var native := art.get_size().y
	if native > 0.0:
		# The reference art is drawn far larger than a 32 px character, so the
		# factor normally shrinks it (1/2, 1/4, 1/8 ...). Art smaller than the
		# target is doubled up in whole steps, which keeps its pixels square.
		var factor := ART_HEIGHT / native
		if factor > 1.0:
			factor = pow(2.0, floor(log(factor) / log(2.0)))
		sprite.scale = Vector2.ONE * factor
		print("POTIONSHOP_CHARACTER seat=%d art=%dx%d scale=%.4f tall=%.1f" % [seat_number, int(art.get_size().x), int(native), factor, native * factor])
	_face_art()


## A single front-facing pose is never rotated with the body: the art stays
## upright, keeps its feet on the player's spot, and only leans by flipping
## towards the way we are walking.
func _face_art() -> void:
	var upright := -rotation
	sprite.rotation = upright
	sprite.position = ART_ABOVE.rotated(upright)
	var lean := Vector2.RIGHT.rotated(rotation).x
	if absf(lean) > 0.25:
		sprite.flip_h = lean < 0.0


func _physics_process(delta: float) -> void:
	if not Session.active or seat < 0:
		return
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = input * Game.WALK_SPEED
	move_and_slide()
	if input != Vector2.ZERO:
		facing = atan2(input.y, input.x)
		rotation = facing
	_face_art()
	if held.visible:
		_place_held()
	_publish(delta)


## Draws what we are carrying: main.gd reads it out of the authority's Shop
## snapshot, because a pose never carries an item.
func set_held(item: String) -> void:
	if item == carrying:
		return
	carrying = item
	held.visible = item != ""
	if item == "":
		return
	held_icon.color = Game.item_color(item)
	held_label.text = Game.item_label(item)
	_place_held()


## Keeps the carried item above our head and upright however we are turned,
## with a gentle bob so it reads as being carried rather than worn.
func _place_held() -> void:
	var turned := -rotation
	held.rotation = turned
	held.position = HELD_ABOVE.rotated(turned) + Vector2(0.0, sin(Time.get_ticks_msec() * 0.006) * 2.0)


## Publishes the pose 20 times a second, and only when it changed.
func _publish(delta: float) -> void:
	if _pose.is_empty():
		return
	_send_elapsed += delta
	if _send_elapsed < Game.SEND_INTERVAL:
		return
	_send_elapsed = 0.0
	_pose["position"] = global_position
	_pose["facing"] = facing
	if _pose == _sent:
		return
	Session.send_motion(global_position, facing)
	_sent = _pose.duplicate()
