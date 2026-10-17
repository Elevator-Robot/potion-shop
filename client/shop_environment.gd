@tool
extends Node2D
const Game = preload("res://network/game.gd")
const WALL_SHADER = preload("res://client/wall_tiles.gdshader")
const WALLS := [
	preload("res://assets/cottage/walls/fieldstone.png"), preload("res://assets/cottage/walls/oak_post.png"),
	preload("res://assets/cottage/walls/cracked_plaster.png"), preload("res://assets/cottage/walls/mossy_boards.png"),
	preload("res://assets/cottage/walls/log_wall.png"), preload("res://assets/cottage/walls/cross_brace.png"),
	preload("res://assets/cottage/walls/ivy_stone.png"), preload("res://assets/cottage/walls/lantern.png"),
	preload("res://assets/cottage/walls/round_glass.png"), preload("res://assets/cottage/walls/arched_glass.png"),
	preload("res://assets/cottage/walls/shadow_niche.png"), preload("res://assets/cottage/walls/root_pillar.png"),
]
var _door_until := 0.0
var _server_now := 0.0
var _received := 0.0
var _open := 0.0

func _ready() -> void:
	_build_outline()
	var woodland := Node2D.new()
	woodland.name = "Woodland"
	woodland.y_sort_enabled = true
	add_child(woodland)
	move_child(woodland, 2)
	for i in 3:
		var rug := Sprite2D.new()
		rug.texture = load("res://assets/atmosphere/rug_%d.png" % i)
		rug.position = [Vector2(312,100), Vector2(304,216), Vector2(400,352)][i]
		rug.scale = Vector2(1.5,1.1)
		add_child(rug)
	for point in [Vector2(108, 8), Vector2(500, 8)]:
		var ray := Sprite2D.new()
		ray.texture = preload("res://assets/atmosphere/rays.png")
		ray.hframes = 4
		ray.centered = false
		ray.position = point - Vector2(48, 0)
		add_child(ray)
	for i in 10:
		var scenery := preload("res://client/scenery.tscn").instantiate()
		scenery.asset = ["guardian", "willow", "spirit_willow"][i % 3]
		scenery.position = [Vector2(-40,70),Vector2(60,-40),Vector2(560,-48),Vector2(650,100),Vector2(-45,280),Vector2(660,310),Vector2(-35,450),Vector2(650,465),Vector2(120,480),Vector2(510,490)][i]
		scenery.art_scale = 1.15
		scenery.foreground = i >= 6
		if i >= 6 and not Engine.is_editor_hint():
			get_parent().get_node("World").add_child(scenery)
		else:
			woodland.add_child(scenery)
	for i in 18:
		var mushroom := preload("res://client/scenery.tscn").instantiate()
		mushroom.asset = "mushroom"
		mushroom.variant = i % 4
		mushroom.position = Vector2((-35 if i % 2 == 0 else 651) + sin(i * 2.7) * 17, 48 + (i / 2) * 49 + sin(i * 1.3) * 13)
		mushroom.art_scale = 0.65 + (i % 3) * 0.15
		woodland.add_child(mushroom)
	for point in [Vector2(-40,120), Vector2(-40,360), Vector2(18,500), Vector2(150,560), Vector2(350,550), Vector2(600,560), Vector2(800,400), Vector2(820,200), Vector2(760,40), Vector2(200,-110), Vector2(600,-100)]:
		var mote := Sprite2D.new()
		mote.texture = preload("res://assets/cottage/emotes.png")
		mote.hframes = 4
		mote.vframes = 5
		mote.frame = 12
		mote.position = point
		mote.scale = Vector2.ONE * 0.25
		$Motes.add_child(mote)

func _build_outline() -> void:
	for child in $GeneratedWalls.get_children():
		$GeneratedWalls.remove_child(child)
		child.queue_free()
	var boundary := StaticBody2D.new()
	boundary.name = "Boundary"
	$GeneratedWalls.add_child(boundary)
	var points: Array = Game.Cottage.FLOOR_POINTS
	var back_tile := 0
	for i in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		var segment := SegmentShape2D.new()
		segment.a = a
		segment.b = b
		var collision := CollisionShape2D.new()
		collision.shape = segment
		boundary.add_child(collision)
		var edge := b - a
		var tall := absf(edge.y) < 0.1 and a.y <= 0.0
		var depth := 92.0 if tall else 22.0
		var offset := Vector2(edge.y, -edge.x).normalized() * depth
		var pieces := maxi(1, ceili(edge.length() / 96.0)) if tall else 1
		for part in pieces:
			var start := a.lerp(b, float(part) / pieces)
			var finish := a.lerp(b, float(part + 1) / pieces)
			var wall := Polygon2D.new()
			wall.polygon = PackedVector2Array([start + offset, finish + offset, finish, start])
			wall.uv = PackedVector2Array([Vector2(0, 0), Vector2(256, 0), Vector2(256, 64), Vector2(0, 64)])
			wall.texture = WALLS[back_tile % WALLS.size()] if tall else WALLS[[0, 4, 6][i % 3]]
			wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var material := ShaderMaterial.new()
			material.shader = WALL_SHADER
			material.set_shader_parameter("repeats", Vector2(1.0, 1.0) if tall else Vector2(edge.length() / 96.0, depth / 96.0))
			wall.material = material
			$GeneratedWalls.add_child(wall)
			if tall:
				back_tile += 1
		# Join the outer edges at bevels and alcoves instead of leaving gaps.
		var previous: Vector2 = points[posmod(i - 1, points.size())]
		var prior_edge := a - previous
		var prior_depth := 92.0 if absf(prior_edge.y) < 0.1 and a.y <= 0.0 else 22.0
		var prior_offset := Vector2(prior_edge.y, -prior_edge.x).normalized() * prior_depth
		var corner := Polygon2D.new()
		corner.polygon = PackedVector2Array([a, a + offset, a + prior_offset])
		corner.color = Color("4b473c")
		$GeneratedWalls.add_child(corner)
	$Door.position = Game.DOOR_ENTRY - Vector2(36, 78)
	$DoorCue.position = Game.DOOR_POINT - Vector2(5, 145)
	for decoration in [{"tile": 10, "at": Vector2(304, -100), "scale": 0.65}, {"tile": 11, "at": Vector2(482, -92), "scale": 0.8}]:
		var panel := Sprite2D.new()
		panel.texture = WALLS[int(decoration["tile"])]
		panel.hframes = 4
		panel.centered = false
		panel.position = decoration["at"]
		panel.scale = Vector2.ONE * float(decoration["scale"])
		panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		$GeneratedWalls.add_child(panel)

func apply_shop(document: Dictionary) -> void:
	_door_until = float(document.get("door_open_until", 0))
	_server_now = float(document.get("now_msec", 0))
	_received = Time.get_ticks_msec()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var now := _server_now + Time.get_ticks_msec() - _received
	_open = move_toward(_open, 1.0 if now < _door_until else 0.0, delta * 5.0)
	$Door.frame = roundi(_open * 3.0)
	for i in 3:
		get_node("Window%d" % i).frame = (int(Time.get_ticks_msec() / 450) + i) % 4
	for i in $Motes.get_child_count():
		var mote: Sprite2D = $Motes.get_child(i)
		mote.frame = 12 + (int(Time.get_ticks_msec() / 300) + i) % 4
		mote.modulate.a = 0.25 + (sin(Time.get_ticks_msec() * 0.0015 + i) + 1.0) * 0.25

func highlight_door(on: bool) -> void:
	$DoorCue.visible = on
