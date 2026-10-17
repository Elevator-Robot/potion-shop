extends Node2D
## Someone else's player: a drawing on our screen with no collision. It glides
## between the poses its owner published, drawn VIEW_DELAY in the past so there
## is always a newer pose to glide to.

const Game = preload("res://network/game.gd")

## How far behind the authority's acceptance time we draw other players, in
## seconds.
const VIEW_DELAY := 0.1

## Where the carried item rides above their head, in screen space.
const HELD_ABOVE := Vector2(0.0, -34.0)

## One front-facing character per seat, the same two designs our own character
## draws: seat 0 is the elf (P1) and seat 1 is the robed potion maker (P2). The
## art is a single static pose, so a texture is all each seat needs - there is
## no walk cycle to play.
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

## Their seat, so main.gd can look up what they are carrying in the snapshot.
var seat := -1
## The item the authority says they are carrying, "" for empty hands. It comes
## from the Shop snapshot, not from the pose.
var carrying := ""
var _samples: Array = []    # [time, position, facing] per received pose
var _tinted := -1

@onready var sprite: Sprite2D = $Sprite
@onready var held: Node2D = $Held
@onready var held_icon: Polygon2D = $Held/HeldIcon
@onready var held_label: Label = $Held/HeldLabel


func apply_pose(state: Dictionary, reset: bool) -> void:
	if state.is_empty():
		return
	var pose := Game.pose_from(state)
	_tint(int(pose["seat"]))
	var position: Vector2 = pose["position"]
	var facing := float(pose["facing"])
	if reset:
		_samples.clear()   # a spawn or a teleport is a cut, not a slide
		global_position = position
		rotation = facing
	_samples.append([Time.get_ticks_usec() / 1000000.0, position, facing])
	if _samples.size() > 20:
		_samples.pop_front()


## Picks the seat's character art, and remembers whose pose this is. The flat
## placeholder tint is gone: the art itself says who is who, so nothing is ever
## drawn over the sprite.
func _tint(seat_number: int) -> void:
	seat = seat_number
	if seat_number == _tinted:
		return
	_tinted = seat_number
	_use_character(seat_number)


## Draws the seat's character, sized to stand ART_HEIGHT tall on screen with a
## whole-number scale factor.
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
## towards the way they are walking.
func _face_art() -> void:
	var upright := -rotation
	sprite.rotation = upright
	sprite.position = ART_ABOVE.rotated(upright)
	var lean := Vector2.RIGHT.rotated(rotation).x
	if absf(lean) > 0.25:
		sprite.flip_h = lean < 0.0


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


func _process(_delta: float) -> void:
	if _samples.is_empty():
		_place()
		return
	var at := Time.get_ticks_usec() / 1000000.0 - VIEW_DELAY
	var newest: Array = _samples[-1]
	var newest_position: Vector2 = newest[1]
	if at >= float(newest[0]) or _samples.size() == 1:
		global_position = newest_position
		rotation = float(newest[2])
		_place()
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
			_place()
			return
	var oldest: Vector2 = _samples[0][1]
	global_position = oldest
	_place()
