extends Node
## The match server. It runs headless and owns every rule: who gets which seat,
## where the room's walls are, and how fast a player is allowed to move.

const Game = preload("res://network/game.gd")
const PlayerArchetype = preload("res://authority/player_archetype.tres")
const Shop = preload("res://authority/shop.gd")
## How far a player may move in one burst after a network stall, in pixels.
const BURST := Game.MAX_SPEED * 0.5
## The station each fixed action belongs to. "take" is not here: it names its
## own station, because a shelf pile and the storage crate are both a take.
const STATION_OF := {
	"put": "storage",
	"prep": "prep",
	"add": "cauldron",
	"bottle": "bottling",
	"serve": "counter",
}

var spawner: SummerNetworkSpawner
var world: SummerNetworkWorld
var seat_of := {}       # session_id -> seat, held until the Session leaves
var allowance := {}     # seat -> pixels the player may still move
var refilled_at := {}   # seat -> msec of the last allowance refill

## The shop: every shared fact in the game lives in here.
var shop: Shop
var shop_group: SummerNetworkStateGroup
var receipts := {}      # session_id -> {request id: the answer we gave}
var _publish_elapsed := 0.0


func _ready() -> void:
	spawner = Game.build_network(self, PlayerArchetype)
	world = $World
	spawner.entity_spawned.connect(_on_player_spawned)
	spawner.command_received.connect(_on_command)
	world.session_left.connect(_on_session_left)
	shop = Shop.new()
	var initialized: SummerResult = await Summer.initialize(Game.GAME_ID).get_result_or_completed_signal()
	if not initialized.ok:
		push_error(initialized.message)
		return
	if not world.is_ready():
		await world.binding_ready
	if not spawner.is_network_ready():
		await spawner.network_ready
	# One shared shop document: the authority is its only writer, every player
	# renders it, and a player joining late receives it whole.
	shop_group = spawner.create_state_group(Game.SHOP, &"shop", Game.pack(shop.doc))
	print("POTIONSHOP_AUTHORITY_READY")


## The shop clock and the snapshot rate. Every deadline in the document is an
## absolute millisecond reading plus the clock the snapshot was taken at, so
## the clients animate the bars and the day clock themselves and the snapshot
## only has to carry changes and a slow heartbeat.
func _process(delta: float) -> void:
	if shop_group == null or not shop_group.active:
		return
	_publish_elapsed += delta
	var changed := shop.tick()
	if not changed and _publish_elapsed < Game.SHOP_HEARTBEAT:
		return
	_publish_elapsed = 0.0
	_publish()


## Sends the whole document, which is the only way shop state ever changes:
## every client, late joiners included, ends up with the same value.
func _publish() -> void:
	if shop_group != null and shop_group.active:
		shop_group.reset(Game.pack(shop.doc))


## A seat is a player's place in this World for their whole stay, across
## reconnects. Returns -1 when the shop is full.
func _seat(session: SummerSession) -> int:
	if seat_of.has(session.session_id):
		return seat_of[session.session_id]
	var taken := seat_of.values()
	for seat in Game.MAX_PLAYERS:
		if seat not in taken:
			seat_of[session.session_id] = seat
			return seat
	return -1


## The Spawner spawns one player entity per joined player, once that player's
## network is ready (and again after a reconnect). Its owner becomes the only
## writer of that seat's pose, and the group ends with the entity.
func _on_player_spawned(entity: SummerNetworkEntity) -> void:
	var seat := _seat(entity.session)
	if seat < 0:
		push_warning("no free seat")
		return
	allowance[seat] = BURST
	refilled_at[seat] = Time.get_ticks_msec()
	var group := spawner.create_state_group(Game.MOTION, Game.motion_key(seat), Game.spawn_pose(seat, entity.entity_id), entity.session, entity)
	group.set_acceptance_policy(_accept_motion.bind(seat))
	print("POTIONSHOP_PLAYER_SPAWNED seat=%d entity=%d" % [seat, entity.entity_id])


## Runs on every pose an owner submits. True accepts it unchanged; false
## refuses it, and the owner snaps back to the last accepted pose.
func _accept_motion(candidate: Dictionary, current: Dictionary, seat: int) -> bool:
	if int(candidate.get("entity", -1)) != int(current.get("entity", -2)):
		return false   # a player can move, never become someone else
	if int(candidate.get("seat", -1)) != int(current.get("seat", -2)):
		return false   # and never move to another seat
	var position: Vector2 = candidate.get("position", Vector2.ZERO)
	if not Game.in_bounds(position) or not is_finite(float(candidate.get("facing", 0.0))):
		return false
	# A distance allowance refilled at MAX_SPEED: bursts after a stall pass,
	# speed hacks and teleports across the room do not.
	var now := Time.get_ticks_msec()
	var last := int(refilled_at.get(seat, now))
	var budget := minf(float(allowance.get(seat, BURST)) + Game.MAX_SPEED * float(now - last) / 1000.0, BURST)
	refilled_at[seat] = now
	var from: Vector2 = current.get("position", position)
	var distance := position.distance_to(from)
	if distance > budget:
		allowance[seat] = budget
		return false
	allowance[seat] = budget - distance
	return true


## Moves a player on purpose (respawn, pushed out of a wall). The owner snaps
## to it, because a reset install is a cut.
func teleport(seat: int, position: Vector2, facing: float) -> void:
	var group := spawner.get_state_group(Game.MOTION, Game.motion_key(seat))
	if group != null and group.active:
		var pose: Dictionary = group.get_state().duplicate()
		pose["position"] = position
		pose["facing"] = facing
		allowance[seat] = BURST
		refilled_at[seat] = Time.get_ticks_msec()
		group.reset(pose)


func _on_command(request: SummerNetworkCommandRequest) -> void:
	var command := Game.unpack(request.payload)
	match str(command.get("c", "")):
		"join":
			_join(request)
		"take", "put", "prep", "add", "bottle", "serve":
			_shop_action(request, command)
		_:
			request.refuse(&"unknown_command")


## A shop action. The sender is a verified Session on a known seat who is
## standing near the station the action belongs to; check all of that first,
## then let the shop rules change state only through the shared document.
func _shop_action(request: SummerNetworkCommandRequest, command: Dictionary) -> void:
	var session := request.get_session()
	var seat: int = seat_of.get(session.session_id, -1)
	if seat < 0:
		request.refuse(&"not_joined")
		return
	var action := str(command.get("c", ""))
	var item := str(command.get("item", ""))
	# A retry of a request already answered gets the same answer, applied once:
	# a Command that timed out on the client may already have been applied.
	var rid := str(command.get("rid", ""))
	var answered: Dictionary = receipts.get(session.session_id, {})
	if rid != "" and answered.has(rid):
		request.accept({}, Game.pack(answered[rid]))
		return
	# Where the player stands is their latest accepted pose, never the payload.
	var position: Variant = _seat_position(seat)
	if position == null:
		request.refuse(&"not_spawned")
		return
	var point: Variant = _action_point(action, command, item)
	if point == null:
		request.refuse(&"wrong_station")
		return
	if (position as Vector2).distance_to(point) > Game.INTERACT_RADIUS + Game.INTERACT_SLACK:
		request.refuse(&"too_far")
		return
	var outcome := _apply(seat, action, item)
	if not bool(outcome["ok"]):
		request.refuse(StringName(outcome["reason"]))
		return
	var value: Dictionary = outcome["value"]
	if rid != "":
		answered[rid] = value
		if answered.size() > 24:
			answered.clear()
		receipts[session.session_id] = answered
	_publish()
	request.accept({}, Game.pack(value))


func _apply(seat: int, action: String, item: String) -> Dictionary:
	match action:
		"take":
			return shop.take(seat, item)
		"put":
			return shop.put(seat)
		"prep":
			return shop.prep(seat)
		"add":
			return shop.add(seat)
		"bottle":
			return shop.bottle(seat)
		"serve":
			return shop.serve(seat)
	return {"ok": false, "reason": "unknown_command", "value": {}}


## Where a player must be standing for this action: the shelf pile they named,
## the storage crate for a take with no item, or the station that action
## belongs to. Null when the payload names something that cannot be used there.
func _action_point(action: String, command: Dictionary, item: String) -> Variant:
	var station := str(command.get("station", ""))
	if action == "take" and item != "":
		if station != "shelves" or not Game.SHELF_SPOTS.has(item):
			return null
		return Game.shelf_spot(item)
	if action == "take":
		return Game.station_point("storage") if station == "storage" else null
	var expected := str(STATION_OF.get(action, ""))
	if expected == "" or station != expected:
		return null
	return Game.station_point(expected)


## The seat's latest accepted pose, or null when that player has not spawned.
func _seat_position(seat: int) -> Variant:
	var group := spawner.get_state_group(Game.MOTION, Game.motion_key(seat))
	if group == null or not group.active:
		return null
	var position: Variant = group.get_state().get("position", null)
	return position if position is Vector2 else null


## A client sends "join" once its network is ready, and gets its seat back.
func _join(request: SummerNetworkCommandRequest) -> void:
	var seat := _seat(request.get_session())
	if seat < 0:
		request.refuse(&"match_full")
		return
	request.accept({}, Game.pack({"seat": seat}))
	print("POTIONSHOP_PLAYER_JOINED seat=%d" % seat)


## The Session ended for good: free the seat and the item they were carrying.
## (Its pose group already ended with the player's entity.) A disconnect is not
## this: a dropped player keeps their seat and may reconnect.
func _on_session_left(session: SummerSession, reason: String) -> void:
	var seat: int = seat_of.get(session.session_id, -1)
	seat_of.erase(session.session_id)
	allowance.erase(seat)
	refilled_at.erase(seat)
	receipts.erase(session.session_id)
	if seat >= 0 and shop != null:
		shop.release(seat)
		_publish()
	print("POTIONSHOP_PLAYER_LEFT seat=%d reason=%s" % [seat, reason])
