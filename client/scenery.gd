@tool
extends Node2D
const TREES := {
	"guardian": preload("res://assets/atmosphere/trees/guardian.png"),
	"willow": preload("res://assets/atmosphere/trees/willow.png"),
	"spirit_willow": preload("res://assets/atmosphere/trees/spirit_willow.png"),
}
const MUSHROOMS = preload("res://assets/atmosphere/mushrooms.png")
@export var asset := "willow":
	set(value):
		asset = value
		if is_node_ready(): _configure()
@export var variant := 0
@export var art_scale := 1.1
@export var foreground := false
var _elapsed := 0.0

func _ready() -> void:
	_configure()
	_elapsed = absf(position.x * 0.01 + position.y * 0.007)

func _configure() -> void:
	var sprite: Sprite2D = $Sprite
	sprite.texture = MUSHROOMS if asset == "mushroom" else TREES.get(asset, TREES["willow"])
	sprite.hframes = 4
	sprite.vframes = 4 if asset == "mushroom" else 1
	sprite.frame = clampi(variant, 0, 3) * 4 if asset == "mushroom" else 0
	sprite.scale = Vector2.ONE * art_scale
	var size := sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes) * art_scale
	sprite.position = Vector2(-size.x / 2, -size.y)

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_elapsed += delta
	$Sprite.frame = (clampi(variant, 0, 3) * 4 if asset == "mushroom" else 0) + int(_elapsed * 1.6) % 4
	var fade := false
	if foreground and asset != "mushroom":
		var box: Rect2 = $Sprite.get_rect()
		for player in get_tree().get_nodes_in_group("shop_players"):
			if player.global_position.y < global_position.y and box.has_point($Sprite.to_local(player.global_position - Vector2(0, 30))):
				fade = true
	$Sprite.modulate.a = move_toward($Sprite.modulate.a, 0.45 if fade else 1.0, delta * 2.5)
