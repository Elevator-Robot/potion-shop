extends RefCounted
## Host-owned rules. The transport supplies the authenticated peer id; clients
## never choose their seat or write the shop document.

const Game = preload("res://network/game.gd")
const Shop = preload("res://authority/shop.gd")
const BURST := Game.MAX_SPEED * 0.5

var shop := Shop.new()
var players := {} # peer id -> accepted pose
var allowance := {}
var refilled_at := {}
var receipts := {} # peer id -> last command id and result

func _init() -> void:
	shop.player_poses = players


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
			var spawn := _free_spawn(Game.spawn_point(seat))
			if not spawn.is_finite():
				return false
			players[peer] = Game.spawn_pose(seat, peer)
			players[peer]["position"] = spawn
			players[peer]["character"] = seat if character < 0 else clampi(character, 0, 1)
			allowance[peer] = BURST
			refilled_at[peer] = Time.get_ticks_msec()
			return true
	return false

func _free_spawn(preferred: Vector2) -> Vector2:
	for ring in 8:
		for step in (1 if ring == 0 else 16):
			var point := preferred + Vector2.RIGHT.rotated(TAU * step / 16.0) * ring * 24
			if not Game.floor_clear(point):
				continue
			var clear := true
			for pose in players.values():
				clear = clear and point.distance_to(pose["position"]) >= Game.PLAYER_RADIUS * 2 + 1
			for customer in shop.doc["customers"]:
				clear = clear and point.distance_to(customer["position"]) >= Game.PLAYER_RADIUS + Game.CUSTOMER_RADIUS + 1
			if clear:
				return point
	return Vector2.INF


func leave(peer: int) -> void:
	if players.has(peer):
		shop.release(int(players[peer]["seat"]))
	players.erase(peer)
	allowance.erase(peer)
	refilled_at.erase(peer)
	receipts.erase(peer)


func move(peer: int, position: Vector2, facing: float) -> bool:
	if not players.has(peer) or not Game.floor_clear(position) or not is_finite(facing):
		return false
	var now := Time.get_ticks_msec()
	var budget := minf(float(allowance[peer]) + Game.MAX_SPEED * float(now - int(refilled_at[peer])) / 1000.0, BURST)
	refilled_at[peer] = now
	var previous: Vector2 = players[peer]["position"]
	var distance := previous.distance_to(position)
	allowance[peer] = budget
	if distance > budget or not Game.motion_clear(previous, position, Game.PLAYER_RADIUS - 0.5):
		return false
	for other in players:
		if other != peer and not Game.actor_motion_clear(previous, position, players[other]["position"], Game.PLAYER_RADIUS * 2 - 0.5):
			return false
	for customer in shop.doc["customers"]:
		if not Game.actor_motion_clear(previous, position, customer["position"], Game.PLAYER_RADIUS + Game.CUSTOMER_RADIUS - 0.5):
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
	var seat := int(players[peer]["seat"])
	if station == "inventory" and action == "select":
		return shop.select_item(seat, item)
	var point: Variant = null
	if station == "door" and action == "door":
		point = Game.DOOR_POINT
	elif station == "customer" and action in ["serve", "talk"] and item.is_valid_int():
		var customer := shop.get_customer(int(item))
		if customer.is_empty() or customer["phase"] == "leaving":
			return _no("no_customer")
		point = customer["position"]
	elif Game.FURNITURE.has(station):
		var data: Dictionary = Game.FURNITURE[station]
		match data["kind"]:
			"shelf":
				if action in ["take", "restock"] and Game.shelf_items(station).has(item):
					point = Game.station_point(station)
				elif action == "inspect" and item == "":
					point = Game.station_point(station)
			"cauldron":
				if action in ["add", "collect", "clear", "inspect"]:
					point = Game.station_point(station)
	if point == null:
		return _no("wrong_station")
	var position: Vector2 = players[peer]["position"]
	if position.distance_to(point) > Game.INTERACT_RADIUS + Game.INTERACT_SLACK:
		return _no("too_far")
	if not Game.motion_clear(position, point, 1.0):
		return _no("blocked")
	var outcome := _no("unknown_command")
	match action:
		"take": outcome = shop.take(seat, item, station)
		"restock": outcome = shop.restock(seat, item, station)
		"add": outcome = shop.add(seat)
		"collect": outcome = shop.collect(seat)
		"clear": outcome = shop.clear_cauldron(seat)
		"serve": outcome = shop.serve(seat, int(item))
		"talk": outcome = shop.talk(int(item), position)
		"door": outcome = shop.door()
		"inspect": outcome = {"ok": true, "reason": "", "value": {"message": "Press R to read the recipes"} if station == "cauldron" else {"shelf": station}}
	if bool(outcome["ok"]):
		shop.record_effect(action, station, seat, position, point, outcome["value"])
	return outcome


func _no(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "value": {}}
