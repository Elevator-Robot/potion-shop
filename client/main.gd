extends Node2D
## What each player runs: joins the match, draws the shop room, and shows every
## player. Our own input moves only our own character; the authority checks the
## pose we publish, and everyone else is drawn from the poses they publish.
## Every shared fact - the customer queue, the shelves, the storage, the
## cauldron, the coins, the reputation, the day - is the authority's Shop
## document. This client only asks for things with Commands, and draws what
## comes back.

const Game = preload("res://network/game.gd")
const PlayerArchetype = preload("res://client/player_archetype.tres")
const HUD = preload("res://client/hud.gd")
const QueueView = preload("res://client/queue_view.gd")

## The station ids of the shared rules, and the nodes in this scene that draw
## them, so the highlight can land on the right one.
const STATION_NODES := {
	"shelves": "IngredientShelves",
	"storage": "Storage",
	"prep": "PrepStation",
	"cauldron": "CauldronStation",
	"bottling": "BottlingStation",
	"counter": "ServingCounter",
}
const LIT := Color(1.3, 1.3, 1.2, 1.0)
const UNLIT := Color(1.0, 1.0, 1.0, 1.0)

var spawner: SummerNetworkSpawner
## Our own seat (0 or 1), read from the authority's answer to the join Command.
var seat := -1
var waiting := {}      # entity id -> pose group that arrived before its entity
var entities: Node2D

## The authority's latest Shop document, and our own clock reading when it
## landed, so the countdowns animate here between snapshots.
var shop := {}
var _local_at := 0.0
var _interact_hold := 0.0
var _hold_locked := false
var _lit_station := ""

@onready var camera: Camera2D = $Camera2D
@onready var hud: HUD = $HUD
@onready var queue_view: QueueView = $Room/Queue/Customers
@onready var cauldron_label: Label = $Room/Stations/CauldronStation/PotLabel


func _ready() -> void:
	_fit_camera()
	get_viewport().size_changed.connect(_fit_camera)
	# A shop with nothing in it must never look like a broken one: say what we
	# are waiting for until the authority has given us a seat.
	hud.set_status("Joining the shop...")
	spawner = Game.build_network(self, PlayerArchetype)
	entities = get_node_or_null("Entities")
	# Connect before joining, or the first values arrive unseen.
	spawner.state_group_created.connect(_on_group_created)
	spawner.entity_spawned.connect(_on_entity_spawned)
	var initialized: SummerResult = await Summer.initialize(Game.GAME_ID).get_result_or_completed_signal()
	if not initialized.ok:
		push_error(initialized.message)
		hud.set_status("Could not reach Summer: %s" % initialized.message)
		return
	var join := Summer.client.join(SummerJoinTarget.queue(Game.QUEUE))
	# Hosted matchmaking may ask the player to accept a match.
	join.acceptance_required.connect(func(proposal: SummerMatchmakingProposal) -> void: proposal.accept())
	var joined: SummerResult = await join.get_result_or_completed_signal()
	if not joined.ok:
		push_error("join failed: %s %s" % [joined.code, joined.message])
		hud.set_status("Could not join the shop: %s" % joined.message)
		return
	if not spawner.is_network_ready():
		await spawner.network_ready
	var entered := await command({"c": "join"})
	if not entered.ok:
		push_error("could not enter the shop: %s" % entered.error)
		hud.set_status("Could not enter the shop: %s" % entered.error)
		return
	seat = int((entered.get("result", {}) as Dictionary).get("seat", -1))
	hud.clear_status()
	print("POTIONSHOP_CLIENT_JOINED")


func _process(delta: float) -> void:
	_update_interaction(delta)
	_update_queue()
	_update_cauldron()


## Frames the whole room on every client, from the live viewport size and the
## shared room rect: both players are always visible, whatever the window is.
func _fit_camera() -> void:
	var viewport := get_viewport_rect().size
	if viewport.x <= 0.0 or viewport.y <= 0.0:
		return
	var frame := Game.CAMERA_RECT
	var fit := minf(viewport.x / frame.size.x, viewport.y / frame.size.y)
	camera.zoom = Vector2(fit, fit)
	camera.position = frame.get_center()


## Sends one Command and waits for the authority's answer.
func command(payload: Dictionary) -> Dictionary:
	var admission := spawner.enqueue_command(Game.CMD, Game.pack(payload))
	if not admission.is_enqueued():
		return {"ok": false, "error": String(admission.get_code())}
	var handle := admission.get_handle()
	if not handle.is_terminal():
		await handle.completed
	if handle.get_outcome() == SummerNetworkCommandHandle.OUTCOME_ACCEPTED:
		return {"ok": true, "error": "", "result": Game.unpack(handle.get_result())}
	return {"ok": false, "error": String(handle.get_reason())}


func _on_group_created(group: SummerNetworkStateGroup) -> void:
	match group.get_stream_id():
		Game.MOTION:
			_attach_pose(group, int(group.get_state().get("entity", -1)))
		Game.SHOP:
			# The baseline is already installed when this fires; later changes
			# arrive through state_installed.
			_install_shop(group.get_state())
			group.state_installed.connect(func(state: Dictionary, _revision: int, _reset: bool) -> void: _install_shop(state))


## The pose group and the player's entity can arrive in either order.
func _attach_pose(group: SummerNetworkStateGroup, entity_id: int) -> void:
	var entity := spawner.get_entity(entity_id)
	if entity == null or entity.root == null:
		waiting[entity_id] = group
		return
	entity.root.bind(group)
	_sync_held()


func _on_entity_spawned(entity: SummerNetworkEntity) -> void:
	print("POTIONSHOP_CLIENT_ENTITY entity=%d root=%s" % [entity.entity_id, "none" if entity.root == null else entity.root.get_class()])
	if waiting.has(entity.entity_id):
		_attach_pose(waiting[entity.entity_id], entity.entity_id)
		waiting.erase(entity.entity_id)


## ---------------------------------------------------------------------------
## The Shop document: the authority's snapshot of every shared fact. Nothing
## here is ever written back, and nothing here is ever guessed locally.
## ---------------------------------------------------------------------------

func _install_shop(state: Dictionary) -> void:
	if state.is_empty():
		return
	var document := Game.unpack(state)
	if document.is_empty():
		return
	var before := shop
	shop = document
	_local_at = Time.get_ticks_msec()
	hud.set_shop(shop, _local_at)
	_sync_held()
	if before.is_empty():
		return
	var gained := int(document.get("coins", 0)) - int(before.get("coins", 0))
	if gained > 0:
		hud.flash_serve(gained)
		_float_text(Game.station_point("counter") - Vector2(0.0, 30.0), "+%d" % gained, Color(0.98, 0.86, 0.36, 1.0))
	if _angry_count(document) > _angry_count(before):
		hud.flash_timeout()


func _angry_count(document: Dictionary) -> int:
	var customers: Array = document.get("customers", [])
	var angry := 0
	for entry in customers:
		var customer: Dictionary = entry
		if bool(customer.get("angry", false)):
			angry += 1
	return angry


## The carried item rides above each player's head on every client: the
## snapshot says who is carrying what, so it never travels in a pose.
func _sync_held() -> void:
	var held: Dictionary = shop.get("held", {})
	for node in _player_nodes():
		node.call("set_held", str(held.get(str(int(node.get("seat"))), "")))


## ---------------------------------------------------------------------------
## Interaction: what the player is standing at, and which Command that means.
## ---------------------------------------------------------------------------

## Reads the interact action against whatever we are standing at. Chopping is a
## hold of about a second; everything else fires the moment it is pressed.
func _update_interaction(delta: float) -> void:
	if seat < 0:
		return
	var me := _own_player()
	if me == null:
		return
	var action := _nearest_action(me.global_position)
	var station := str(action.get("station", ""))
	if station != _lit_station:
		_lit_station = station
		_highlight(station)
	hud.set_prompt(str(action.get("label", "")))
	if not Input.is_action_pressed(&"interact"):
		_interact_hold = 0.0
		_hold_locked = false
		hud.set_hold(0.0)
		return
	if str(action.get("action", "")) == "prep":
		if not _hold_locked:
			_interact_hold += delta
			if _interact_hold >= Game.PREP_HOLD_SECONDS:
				_interact_hold = 0.0
				_hold_locked = true
				_send(action)
		hud.set_hold(_interact_hold / Game.PREP_HOLD_SECONDS)
		return
	_interact_hold = 0.0
	hud.set_hold(0.0)
	if Input.is_action_just_pressed(&"interact"):
		_send(action)


## Sends one shop action. The request id makes a retry safe, and a refusal only
## ever reports why - it changes nothing here.
func _send(action: Dictionary) -> void:
	var payload := {
		"c": str(action.get("action", "")),
		"station": str(action.get("station", "")),
		"item": str(action.get("item", "")),
		"rid": "%s-%s-%d" % [str(action.get("action", "")), str(action.get("station", "")), Time.get_ticks_usec()],
	}
	var answer := await command(payload)
	if not bool(answer.get("ok", false)):
		hud.flash_message(HUD.refuse_text(str(answer.get("error", ""))))


## The station we are closest to, and what interact would do there. This uses
## the shared constants, so the prompt matches what the authority will accept.
func _nearest_action(at: Vector2) -> Dictionary:
	var best := {}
	var best_distance := Game.INTERACT_RADIUS
	for station in Game.STATIONS:
		var point := Game.station_point(station)
		var distance := at.distance_to(point)
		if distance > best_distance:
			continue
		var action := _action_at(station, "")
		if action.is_empty():
			continue
		best = action
		best_distance = distance
	for raw in Game.RAW_ITEMS:
		var spot := Game.shelf_spot(raw)
		var distance := at.distance_to(spot)
		if distance > best_distance:
			continue
		var action := _action_at("shelves", raw)
		if action.is_empty():
			continue
		best = action
		best_distance = distance
	return best


## What a station offers us right now, {} when there is nothing to do there.
func _action_at(station: String, item: String) -> Dictionary:
	var mine := _held()
	match station:
		"shelves":
			if mine != "":
				return {}
			var stock := _shelf_stock(item)
			if stock <= 0:
				return {}
			return _action("take", station, item, "[E] Take %s (%d left)" % [Game.item_label(item), stock])
		"storage":
			if mine != "":
				return _action("put", station, "", "[E] Store %s" % Game.item_label(mine))
			var stored := _storage()
			if stored.is_empty():
				return {}
			return _action("take", station, "", "[E] Take %s back" % Game.item_label(str(stored[-1])))
		"prep":
			if not Game.is_raw(mine):
				return {}
			return _action("prep", station, "", "[E] Hold to chop %s" % Game.item_label(mine))
		"cauldron":
			if not Game.is_prepped(mine) or _brewing():
				return {}
			return _action("add", station, "", "[E] Add %s" % Game.item_label(mine))
		"bottling":
			var cauldron := _cauldron()
			if mine != "" or not bool(cauldron.get("ready", false)):
				return {}
			return _action("bottle", station, "", "[E] Bottle the %s" % Game.item_label(str(cauldron.get("potion", ""))))
		"counter":
			if not Game.is_potion(mine):
				return {}
			var order := _front_order()
			if order == "":
				return {}
			return _action("serve", station, "", "[E] Serve the %s" % Game.item_label(order))
	return {}


func _action(verb: String, station: String, item: String, label: String) -> Dictionary:
	return {"action": verb, "station": station, "item": item, "label": label}


## Lights up the station we are standing at, so it is obvious where an action
## is available.
func _highlight(station: String) -> void:
	for id in STATION_NODES:
		var body := get_node_or_null("Room/Stations/%s/Body" % STATION_NODES[id]) as CanvasItem
		if body == null:
			continue
		body.modulate = LIT if id == station else UNLIT


## A floating number at a world position, drifting up and fading out.
func _float_text(at: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.size = Vector2(72.0, 22.0)
	label.position = at - Vector2(36.0, 11.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position - Vector2(0.0, 30.0), 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.tween_callback(label.queue_free)


## ---------------------------------------------------------------------------
## Reading the snapshot. Every number is drawn with the local countdown, so the
## bars and the clock stay smooth while the snapshot rate stays low.
## ---------------------------------------------------------------------------

func _update_queue() -> void:
	var customers := _customers()
	var remaining: Array = []
	var now := Time.get_ticks_msec()
	var server_now := float(shop.get("now_msec", 0.0))
	for entry in customers:
		var customer: Dictionary = entry
		var left := Game.seconds_left(float(customer.get("deadline_msec", 0.0)), server_now, _local_at, now)
		remaining.append(maxf(left, 0.0))
	queue_view.apply(customers, remaining)


## What is in the cauldron and how far the brew has got, written beside it.
func _update_cauldron() -> void:
	var cauldron := _cauldron()
	var contents: Array = cauldron.get("contents", [])
	var potion := str(cauldron.get("potion", ""))
	if potion == "" and contents.is_empty():
		cauldron_label.text = "Cauldron: empty"
		return
	var names: Array = []
	for item in contents:
		names.append(Game.item_label(Game.raw_of(str(item))))
	var line := "Cauldron: %s" % ", ".join(names)
	if potion == "":
		cauldron_label.text = "%s ..." % line
		return
	if bool(cauldron.get("ready", false)):
		cauldron_label.text = "%s -> %s ready!" % [line, Game.item_label(potion)]
		return
	var start := float(cauldron.get("brew_start_msec", 0.0))
	var finish := float(cauldron.get("brew_end_msec", 0.0))
	var span := maxf(finish - start, 0.001)
	var left := Game.seconds_left(finish, float(shop.get("now_msec", 0.0)), _local_at, Time.get_ticks_msec())
	cauldron_label.text = "%s -> brewing %s %d%%" % [line, Game.item_label(potion), int(clampf(1.0 - left / span, 0.0, 1.0) * 100.0)]


func _held() -> String:
	var held: Dictionary = shop.get("held", {})
	return str(held.get(str(seat), ""))


func _shelf_stock(raw: String) -> int:
	var shelves: Dictionary = shop.get("shelves", {})
	return int(shelves.get(raw, 0))


func _storage() -> Array:
	var stored: Array = shop.get("storage", [])
	return stored


func _cauldron() -> Dictionary:
	var cauldron: Dictionary = shop.get("cauldron", {})
	return cauldron


func _customers() -> Array:
	var customers: Array = shop.get("customers", [])
	return customers


## The potion the customer being served is waiting for, "" when nobody is.
func _front_order() -> String:
	for entry in _customers():
		var customer: Dictionary = entry
		if not bool(customer.get("angry", false)):
			return str(customer.get("order", ""))
	return ""


func _brewing() -> bool:
	var cauldron := _cauldron()
	return not str(cauldron.get("potion", "")).is_empty() or bool(cauldron.get("ready", false))


## ---------------------------------------------------------------------------
## The players this client draws.
## ---------------------------------------------------------------------------

func _player_nodes() -> Array:
	if entities == null:
		return []
	var nodes: Array = []
	for child in entities.get_children():
		if child.has_method("set_held"):
			nodes.append(child)
	return nodes


## Our own character: the one CharacterBody2D this client's archetype spawns.
func _own_player() -> Node2D:
	for node in _player_nodes():
		if node is CharacterBody2D:
			return node
	return null
