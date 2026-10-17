extends Node2D
## Someone else's player: a drawing on our screen with no collision. It glides
## between the poses its owner published, drawn VIEW_DELAY in the past so there
## is always a newer pose to glide to.

const Game = preload("res://network/game.gd")
const CharacterAnimation = preload("res://client/character_animation.gd")

## How far behind the authority's acceptance time we draw other players, in
## seconds.
const VIEW_DELAY := 0.1

## Where the carried item rides above their head, in screen space.
const HELD_ABOVE := Vector2(0.0, -66.0)

## The same authored animation sheets used by the local player.
const CHARACTERS := {
	0: preload("res://assets/characters/blue_witch/sheet.png"),
	1: preload("res://assets/characters/purple_shopkeeper/sheet.png"),
}
## Match the local player's readable height without changing its feet footprint.
const ART_HEIGHT := 60.0

## Their seat, so main.gd can look up what they are carrying in the snapshot.
var seat := -1
## The item the authority says they are carrying, "" for empty hands. It comes
## from the Shop snapshot, not from the pose.
var carrying := ""
var _samples: Array = []    # [time, position, facing] per received pose
var _tinted := -1
var animation := CharacterAnimation.new()

@onready var sprite: Sprite2D = $Sprite
@onready var held: Node2D = $Held
@onready var held_icon: Polygon2D = $Held/HeldIcon
@onready var held_label: Label = $Held/HeldLabel


func apply_pose(state: Dictionary, reset: bool) -> void:
	if state.is_empty():
		return
	var pose := Game.pose_from(state)
	seat = int(pose["seat"])
	_tint(int(pose["character"]))
	var position: Vector2 = pose["position"]
	var facing := float(pose["facing"])
	if reset:
		_samples.clear()   # a spawn or a teleport is a cut, not a slide
		global_position = position
		rotation = facing
	_samples.append([Time.get_ticks_usec() / 1000000.0, position, facing])
	if _samples.size() > 20:
		_samples.pop_front()


## Apply the character choice received from the host.
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
	animation.idle_durations = Vector4(1.2, 0.3, 0.12, 0.3)
	_face_art()


## Animate the original artwork without rotating it with the player's body.
func _face_art() -> void:
	animation.apply(sprite, rotation, ART_HEIGHT)


## Draws what they are carrying: main.gd reads it out of the authority's Shop
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


## Above their head and upright, with the same gentle bob our own item has.
func _place_held() -> void:
	var turned := -rotation
	held.rotation = turned
	held.position = HELD_ABOVE.rotated(turned) + Vector2(0.0, sin(Time.get_ticks_msec() * 0.006) * 2.0)


## Every frame ends here: the art and the carried item are both kept upright
## however the body is turned.
func _place() -> void:
	_face_art()
	if held.visible:
		_place_held()


func _process(delta: float) -> void:
	var previous := global_position
	_update_pose()
	animation.advance(delta, previous.distance_to(global_position))
	_place()


func _update_pose() -> void:
	if _samples.is_empty():
		return
	var at := Time.get_ticks_usec() / 1000000.0 - VIEW_DELAY
	var newest: Array = _samples[-1]
	var newest_position: Vector2 = newest[1]
	if at >= float(newest[0]) or _samples.size() == 1:
		global_position = newest_position
		rotation = float(newest[2])
		return
	for i in range(_samples.size() - 1, 0, -1):
		var a: Array = _samples[i - 1]
		var b: Array = _samples[i]
		if at >= float(a[0]):
			var span := maxf(float(b[0]) - float(a[0]), 0.0001)
			var t := clampf((at - float(a[0])) / span, 0.0, 1.0)
			var from: Vector2 = a[1]
			var to: Vector2 = b[1]
			global_position = from.lerp(to, t)
			rotation = lerp_angle(float(a[2]), float(b[2]), t)
			return
	var oldest: Vector2 = _samples[0][1]
	global_position = oldest
