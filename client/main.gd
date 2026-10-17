extends Node2D
## Interactive shop view. The host owns objects, customers and inventory;
## this client chooses a nearby target and renders accepted actions.
const Game = preload("res://network/game.gd")
const PlayerOwner = preload("res://client/player_owner.tscn")
const PlayerObserver = preload("res://client/player_observer.tscn")
const HUD = preload("res://client/hud.gd")
const ItemIcon = preload("res://client/item_icon.gd")

var seat := -1
var shop := {}
var _local_at := 0.0
var _last_effect := -1
var _lit_station := ""
var _last_customer := 0

@onready var camera: Camera2D = $Camera2D
@onready var hud: HUD = $HUD
@onready var entities: Node2D = $World/Entities
@onready var customers: Node2D = $World/Customers
@onready var props: Node2D = $World/Props

func _ready() -> void:
	_fit_camera()
	get_viewport().size_changed.connect(_fit_camera)
	Session.state_changed.connect(_sync_session)
	Session.command_finished.connect(_command_finished)
	Session.failed.connect(_session_failed)
	if not Session.active:
		Session.solo()
	_sync_session()
	hud.clear_status()
	print("POTIONSHOP_CLIENT_JOINED")

func _process(_delta: float) -> void:
	_update_interaction()
	_update_customers()
	if Input.is_action_just_pressed("ui_cancel"):
		Session.close()
		get_tree().change_scene_to_file("res://client/menu.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		hud.toggle_recipes()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		var prop := props.get_node_or_null(_lit_station)
		if prop != null:
			prop.cycle_selection()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var player := _own_player()
		if player != null and Session.active:
			_send(_nearest_action(player.global_position))
			get_viewport().set_input_as_handled()

func _fit_camera() -> void:
	var viewport := get_viewport_rect().size
	if viewport.x <= 0.0 or viewport.y <= 0.0:
		return
	var frame := Game.CAMERA_RECT
	camera.zoom = Vector2.ONE * minf(viewport.x / frame.size.x, viewport.y / frame.size.y)
	camera.position = frame.get_center()

func _sync_session() -> void:
	seat = Session.local_seat
	for node in entities.get_children():
		if not Session.players.has(int(str(node.name))):
			entities.remove_child(node)
			node.queue_free()
	for peer in Session.players:
		var pose: Dictionary = Session.players[peer]
		var node := entities.get_node_or_null(str(peer))
		var created := node == null
		if created:
			var scene: PackedScene = PlayerOwner if int(pose["seat"]) == seat else PlayerObserver
			node = scene.instantiate()
			node.name = str(peer)
			entities.add_child(node)
		node.apply_pose(pose, created)
	_install_shop(Session.document)

func _command_finished(result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		hud.flash_message(HUD.refuse_text(str(result.get("reason", "unknown_command"))))
		if result.get("reason", "") == "wrong_order":
			var customer := customers.get_node_or_null("Customer_%d" % _last_customer)
			if customer != null:
				customer.emphasize_request(true)
	else:
		var message := str((result.get("value", {}) as Dictionary).get("message", ""))
		if message != "":
			hud.flash_message(message)

func _session_failed(message: String) -> void:
	seat = -1
	hud.set_status(message + " Press Esc for menu.")

func _install_shop(document: Dictionary) -> void:
	if document.is_empty():
		return
	shop = document
	_local_at = Time.get_ticks_msec()
	hud.set_shop(shop, _local_at)
	$Environment.apply_shop(shop)
	for prop in props.get_children():
		prop.apply_shop(shop)
	_sync_held()
	var effects: Array = shop.get("effects", [])
	if _last_effect < 0:
		_last_effect = int(effects[-1]["id"]) if not effects.is_empty() else 0
	else:
		for event in effects:
			if int(event["id"]) > _last_effect:
				_play_effect(event)
				_last_effect = int(event["id"])

func _sync_held() -> void:
	var held: Dictionary = shop.get("held", {})
	for node in entities.get_children():
		node.set_held(str(held.get(str(int(node.get("seat"))), "")))

func _update_interaction() -> void:
	if seat < 0:
		return
	var me := _own_player()
	if me == null:
		return
	var action := _nearest_action(me.global_position)
	var station := str(action.get("station", ""))
	if station != _lit_station:
		_lit_station = station
		for prop in props.get_children():
			prop.set_highlighted(prop.prop_id == station)
		$Environment.highlight_door(station == "door")
	hud.set_prompt(str(action.get("label", "Match the bottle your customer wants · R: recipes")))
	if Input.is_action_just_pressed("interact"):
		_send(action)

func _send(action: Dictionary) -> void:
	if action.is_empty():
		return
	_last_customer = int(action.get("item", "0")) if action.get("station", "") == "customer" else 0
	var player := _own_player()
	if player != null:
		Session.send_motion(player.global_position, player.rotation)
	Session.send_command(str(action.get("action", "")), str(action.get("station", "")), str(action.get("item", "")))

func _nearest_action(at: Vector2) -> Dictionary:
	var best := {}
	var nearest := Game.INTERACT_RADIUS
	# A visible request bubble is a direct target, even when another customer is
	# slightly closer. This makes giving the visually matched bottle intentional.
	var mouse := get_global_mouse_position()
	for customer in shop.get("customers", []):
		var point: Vector2 = customer.get("position", Vector2.ZERO)
		if customer.get("phase", "") == "leaving" or at.distance_to(point) > Game.INTERACT_RADIUS:
			continue
		if Rect2(point + Vector2(-21, -111), Vector2(42, 54)).has_point(mouse) or Rect2(point + Vector2(-18, -50), Vector2(36, 50)).has_point(mouse):
			return _customer_action(customer)
	for id in Game.FURNITURE:
		var distance := at.distance_to(Game.station_point(id))
		if distance <= nearest:
			var action := _action_at(id)
			if not action.is_empty():
				best = action
				nearest = distance
				var prop := props.get_node_or_null(id)
				if prop != null and prop.mouse_over_stock(get_global_mouse_position()):
					return action
	if at.distance_to(Game.DOOR_POINT) <= nearest:
		nearest = at.distance_to(Game.DOOR_POINT)
		best = _action("door", "door", "", "[E] Open / close the door")
	for customer in shop.get("customers", []):
		if customer.get("phase", "") == "leaving":
			continue
		var point: Vector2 = customer.get("position", Vector2.ZERO)
		if at.distance_to(point) <= nearest:
			nearest = at.distance_to(point)
			best = _customer_action(customer)
	return best

func _customer_action(customer: Dictionary) -> Dictionary:
	var serving := Game.is_potion(_held())
	return _action("serve" if serving else "talk", "customer", str(customer["id"]), "[E / click] Offer your bottle" if serving else "[E / click] Ask about their order")

func _action_at(id: String) -> Dictionary:
	var data: Dictionary = Game.FURNITURE[id]
	var mine := _held()
	match data["kind"]:
		"shelf":
			var item: String = props.get_node(id).choose_item(get_global_mouse_position(), mine)
			if mine == item:
				return _action("restock", id, item, "[E / click] Place your item on the shelf")
			if mine == "":
				var stock := int(shop.get("shelf_stock", {}).get(id, {}).get(item, 0))
				return _action("take", id, item, "Point at a sprite · E / click to take · Tab to cycle · ×%d" % stock)
		"storage":
			if mine != "":
				return _action("put", id, "", "[E / click] Store held item")
			var stored: Array = shop.get("storage", [])
			if not stored.is_empty():
				return _action("take", id, "", "[E / click] Retrieve last stored item")
			return _action("inspect", id, "", "[E] Open storage chest")
		"cauldron":
			var pot: Dictionary = shop.get("cauldron", {})
			var potion := str(pot.get("potion", ""))
			if bool(pot.get("ready", false)) and mine == "":
				return _action("collect", id, "", "[E / click] Collect the finished bottle")
			if potion != "":
				var now := Time.get_ticks_msec()
				var left := maxf(Game.seconds_left(float(pot.get("brew_end_msec", 0)), float(shop.get("now_msec", 0)), _local_at, now), 0.0)
				return _action("inspect", id, "", "Brewing · %.1fs · R: visual recipes" % left)
			if Game.is_raw(mine):
				return _action("add", id, "", "[E / click] Add your ingredient")
			var contents: Array = pot.get("contents", [])
			if mine == "" and not contents.is_empty():
				return _action("clear", id, "", "[E] Empty unfinished mix · R: visual recipes")
			return _action("inspect", id, "", "[E] Inspect cauldron · R: recipes")
	return {}

func _action(verb: String, station: String, item: String, label: String) -> Dictionary:
	return {"action": verb, "station": station, "item": item, "label": label}

func _update_customers() -> void:
	var entries: Array = shop.get("customers", [])
	var remaining: Array = []
	for entry in entries:
		remaining.append(maxf(Game.seconds_left(float(entry.get("deadline_msec", 0)), float(shop.get("now_msec", 0)), _local_at, Time.get_ticks_msec()), 0.0))
	customers.apply(entries, remaining)

func _play_effect(event: Dictionary) -> void:
	var station := str(event["station"])
	var prop := props.get_node_or_null(station)
	if prop != null:
		prop.interact()
	var action := str(event["action"])
	var item := str(event["item"])
	var from: Vector2 = event["from"]
	var to: Vector2 = event["to"]
	if item != "":
		var start := from - Vector2(0, 78)
		var end: Vector2 = prop.item_position(item) if prop != null else to - Vector2(0, 65)
		if action in ["take", "collect"]:
			start = end
			end = from - Vector2(0, 78)
		var icon := ItemIcon.new()
		add_child(icon)
		icon.set_item(item)
		icon.scale = Vector2.ONE
		icon.z_index = 10
		icon.position = start
		var tween := create_tween()
		tween.tween_property(icon, "position", end, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(icon, "rotation", TAU, 0.35)
		tween.tween_property(icon, "modulate:a", 0.0, 0.15)
		tween.tween_callback(icon.queue_free)
	if action == "serve":
		var reward := int(event["reward"])
		hud.flash_serve(reward)
		_float_text(to - Vector2(0, 70), "+%d  ♥" % reward, Color(1, 0.84, 0.5))
	elif action == "add":
		_float_text(to - Vector2(0, 80), "plop!", Color(0.65, 0.95, 0.8))
	elif action == "talk":
		var customer := customers.get_node_or_null("Customer_%d" % int(event.get("customer", 0)))
		if customer != null:
			customer.emphasize_request(false)

func _float_text(at: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.z_index = 10
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", at - Vector2(0, 24), 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.tween_callback(label.queue_free)

func _held() -> String:
	return str((shop.get("held", {}) as Dictionary).get(str(seat), ""))

func _own_player() -> Node2D:
	for node in entities.get_children():
		if node is CharacterBody2D:
			return node
	return null
