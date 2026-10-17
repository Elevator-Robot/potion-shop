extends RefCounted
## Authored sprite-sheet animation, with per-character idle frame timing.
## Collision, network poses and carried-item placement stay independent.

const STRIDE := 36.0
var walk_amount := 0.0
var idle_durations := Vector4(0.2, 0.2, 0.2, 0.2)
var _step := 0.0
var _idle_time := 0.0


func advance(delta: float, distance: float) -> void:
	var idle_total := idle_durations.x + idle_durations.y + idle_durations.z + idle_durations.w
	_idle_time = fmod(_idle_time + delta, idle_total)
	# Ignore spawn/correction jumps. Steps follow distance, not held input, so
	# pushing against a counter settles back into idle instead of walking in place.
	var walking := distance > 0.01 and distance < 48.0
	var target := 1.0 if walking else 0.0
	walk_amount = lerpf(walk_amount, target, 1.0 - exp(-14.0 * delta))
	if walking:
		_step = fmod(_step + distance * TAU / STRIDE, TAU)
	elif walk_amount < 0.01:
		_step = 0.0


func apply(sprite: Sprite2D, body_rotation: float, height: float) -> void:
	if sprite.texture == null:
		return
	var horizontal := cos(body_rotation)
	if absf(horizontal) > 0.25:
		sprite.flip_h = horizontal < 0.0
	var walking := walk_amount > 0.15
	sprite.frame = 4 + int(_step / TAU * 4.0) % 4 if walking else _idle_frame()
	var frame_height := sprite.texture.get_size().y / sprite.vframes
	sprite.scale = Vector2.ONE * height / frame_height
	sprite.rotation = -body_rotation
	sprite.position = Vector2(0.0, -height * 0.5).rotated(-body_rotation)


func _idle_frame() -> int:
	var until := 0.0
	for frame in 4:
		until += idle_durations[frame]
		if _idle_time < until:
			return frame
	return 3
