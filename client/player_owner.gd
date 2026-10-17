extends CharacterBody2D
## Our own player. Only this client moves it, and it publishes where it is; the
## authority only snaps us somewhere on spawn, teleport, or a refused pose.
## Flat top-down walking: no gravity, no jumping, no y velocity.

const Game = preload("res://network/game.gd")
const CharacterAnimation = preload("res://client/character_animation.gd")

## Where the carried item rides above our head, in screen space: the shop is
## top-down, so "up" is -y whatever way we are facing.
const HELD_ABOVE := Vector2(0.0, -66.0)

## Authored idle/walk sheets for both selectable characters.
const CHARACTERS := {
	0: preload("res://assets/characters/elf_adventurer.png"),
	1: preload("res://assets/characters/purple_shopkeeper/sheet.png"),
}
## Readable character height in world pixels; keep the small feet collision
## footprint so the character can still walk through the shop's narrow aisles.
const ART_HEIGHT := 60.0

var seat := -1
var facing := Game.SPAWN_FACING
## The item the authority says we are carrying, "" for empty hands. It comes
## from the Shop snapshot, never from the pose we publish.
var carrying := ""
var _pose := {}          # the full pose; only position and facing ever change
var _sent := {}
var _send_elapsed := 0.0
var _tinted := -1
var animation := CharacterAnimation.new()

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
	_tint(int(_pose["character"]))


## Apply the selected character art without tinting the supplied texture.
func _tint(seat_number: int) -> void:
	if seat_number == _tinted:
		return
	_tinted = seat_number
	_use_character(seat_number)


## Draws the seat's character at a consistent height, preserving its aspect ratio.
func _use_character(seat_number: int) -> void:
	var art: Texture2D = CHARACTERS.get(seat_number, CHARACTERS[0])
	sprite.texture = art
	sprite.hframes = 4
	sprite.vframes = 2
	sprite.frame = 0
	animation.idle_durations = Vector4(1.2, 0.3, 0.12, 0.3) if seat_number == 1 else Vector4(0.2, 0.2, 0.2, 0.2)
	_face_art()


## Keep the artwork upright while applying idle breathing or walking motion.
func _face_art() -> void:
	animation.apply(sprite, rotation, ART_HEIGHT)


func _physics_process(delta: float) -> void:
	if not Session.active or seat < 0:
		return
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = input * Game.WALK_SPEED
	var previous := global_position
	move_and_slide()
	animation.advance(delta, previous.distance_to(global_position))
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
