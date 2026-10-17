@tool
extends StaticBody2D
const Game = preload("res://network/game.gd")
const ART := [preload("res://assets/furniture/library/clutter_0.png"), preload("res://assets/furniture/library/clutter_1.png"), preload("res://assets/furniture/library/clutter_2.png")]

@export var decor_id := "":
	set(value):
		decor_id = value
		if is_node_ready():
			_configure()

func _ready() -> void:
	_configure()

func _configure() -> void:
	if not Game.CLUTTER.has(decor_id):
		return
	var data: Dictionary = Game.CLUTTER[decor_id]
	position = data["at"]
	$Sprite.texture = ART[int(data["variant"])]
	var points := Game.furniture_polygon(decor_id).duplicate()
	for i in points.size():
		points[i] -= position
	var shape := ConvexPolygonShape2D.new()
	shape.points = points
	$Collision.shape = shape
