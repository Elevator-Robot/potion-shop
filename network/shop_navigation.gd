extends RefCounted
## Walkable nodes connected only when the whole segment clears shared footprints.
## This prevents corners of angled furniture being cut by a clear-endpoint path.
const Game = preload("res://network/game.gd")
const WIDTH := 40
const HEIGHT := 26
const SPACING := 16.0
const RADIUS := 12.0
static var _shared_graph: AStar2D
var graph: AStar2D

func _init() -> void:
	if _shared_graph != null:
		graph = _shared_graph
		return
	graph = AStar2D.new()
	for y in HEIGHT:
		for x in WIDTH:
			var point := Vector2(x * SPACING + 8, y * SPACING + 8)
			if Game.floor_clear(point, RADIUS):
				graph.add_point(y * WIDTH + x, point)
	for id in graph.get_point_ids():
		for other in [id + 1, id + WIDTH]:
			if not graph.has_point(other):
				continue
			var from := graph.get_point_position(id)
			var to := graph.get_point_position(other)
			if from.distance_to(to) <= SPACING + 0.1 and Game.motion_clear(from, to, RADIUS):
				graph.connect_points(id, other)
	_shared_graph = graph

func route(from: Vector2, to: Vector2) -> Array[Vector2]:
	var start := _nearest(from)
	var finish := _nearest(to)
	var result: Array[Vector2] = []
	if start < 0 or finish < 0:
		return result
	for point in graph.get_point_path(start, finish):
		result.append(point)
	if not result.is_empty():
		result.append(to)
	return result

func _nearest(point: Vector2) -> int:
	var best := -1
	var distance := INF
	for id in graph.get_point_ids():
		var candidate := graph.get_point_position(id)
		var squared := point.distance_squared_to(candidate)
		if squared < distance and Game.motion_clear(point, candidate, RADIUS):
			distance = squared
			best = id
	return best
