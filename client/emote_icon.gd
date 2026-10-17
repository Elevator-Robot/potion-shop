extends Sprite2D
const SHEET = preload("res://assets/cottage/emotes.png")
var _until := 0
var _kind := 0
var _elapsed := 0.0
var _auto_free := false

func show_emote(kind: int, seconds: float = 1.4, auto_free: bool = false, display_scale: float = 1.0) -> void:
	texture = SHEET
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hframes = 4
	vframes = 5
	_kind = clampi(kind, 0, 4)
	_until = Time.get_ticks_msec() + int(seconds * 1000)
	_auto_free = auto_free
	_elapsed = 0.0
	visible = true
	z_index = 12
	scale = Vector2.ONE * 0.4 * display_scale
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.35 * display_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 1.15 * display_scale, 0.15)

func _process(delta: float) -> void:
	var left := _until - Time.get_ticks_msec()
	if left <= 0:
		visible = false
		if _auto_free:
			queue_free()
		return
	_elapsed += delta
	frame = _kind * 4 + int(_elapsed * 5.0) % 4
	modulate.a = clampf(float(left) / 350.0, 0.0, 1.0)
