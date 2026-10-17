extends RefCounted
## Host-owned rules. The transport supplies the authenticated peer id; clients
## never choose their seat or write the shop document.

const Game = preload("res://network/game.gd")
const Shop = preload("res://authority/shop.gd")
const BURST := Game.MAX_SPEED * 0.5
const STATION_OF := {
	"put": "storage", "prep": "prep", "add": "cauldron",
	"bottle": "bottling", "serve": "counter",
}

var shop := Shop.new()
var players := {} # peer id -> accepted pose
var allowance := {}
var refilled_at := {}
var receipts := {} # peer id -> last command id and result


func join(peer: int, character: int = -1) -> bool:
	if players.has(peer):
		return true
	if players.size() >= Game.MAX_PLAYERS:
		return false
	var taken: Array = []
	for pose in players.values():
		taken.append(int(pose["seat"]))
	for seat in Game.MAX_PLAYERS:
		if seat not in taken:
			players[peer] = Game.spawn_pose(seat, peer)
			players[peer]["character"] = seat if character < 0 else clampi(character, 0, 1)
			allowance[peer] = BURST
			refilled_at[peer] = Time.get_ticks_msec()
			return true
	return false


func leave(peer: int) -> void:
	if players.has(peer):
		shop.release(int(players[peer]["seat"]))
	players.erase(peer)
	allowance.erase(peer)
	refilled_at.erase(peer)
	receipts.erase(peer)


func move(peer: int, position: Vector2, facing: float) -> bool:
	if not players.has(peer) or not Game.in_bounds(position) or not is_finite(facing):
		return false
	var now := Time.get_ticks_msec()
	var budget := minf(float(allowance[peer]) + Game.MAX_SPEED * float(now - int(refilled_at[peer])) / 1000.0, BURST)
	refilled_at[peer] = now
	var previous: Vector2 = players[peer]["position"]
	var distance := previous.distance_to(position)
	allowance[peer] = budget
	if distance > budget:
		return false
	allowance[peer] = budget - distance
	players[peer]["position"] = position
	players[peer]["facing"] = facing
	return true


func command(peer: int, id: int, action: String, station: String, item: String) -> Dictionary:
	if not players.has(peer):
		return _no("not_joined")
	if id <= 0:
		return _no("stale_command")
	var last: Dictionary = receipts.get(peer, {})
	if id <= int(last.get("id", 0)):
		return last["result"] if id == int(last.get("id", 0)) else _no("stale_command")
	var result := _apply(peer, action, station, item)
	receipts[peer] = {"id": id, "result": result}
	return result


func _apply(peer: int, action: String, station: String, item: String) -> Dictionary:
	var point: Variant = null
	if action == "take":
		if item != "" and station == "shelves" and Game.SHELF_SPOTS.has(item):
			point = Game.shelf_spot(item)
		elif item == "" and station == "storage":
			point = Game.station_point("storage")
	elif STATION_OF.has(action) and station == STATION_OF[action]:
		point = Game.station_point(station)
	if point == null:
		return _no("wrong_station")
	var position: Vector2 = players[peer]["position"]
	if position.distance_to(point) > Game.INTERACT_RADIUS + Game.INTERACT_SLACK:
		return _no("too_far")
	var seat := int(players[peer]["seat"])
	match action:
		"take": return shop.take(seat, item)
		"put": return shop.put(seat)
		"prep": return shop.prep(seat)
		"add": return shop.add(seat)
		"bottle": return shop.bottle(seat)
		"serve": return shop.serve(seat)
	return _no("unknown_command")


func _no(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "value": {}}
