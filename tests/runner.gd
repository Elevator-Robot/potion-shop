extends Node

const Game = preload("res://network/game.gd")
const Rules = preload("res://tests/rules.gd")
var failures: Array[String] = []
var result := {}


func _ready() -> void:
	# A hard deadline also catches broken RPC admission and test coroutines.
	get_tree().create_timer(35.0).timeout.connect(func() -> void:
		push_error("Test deadline exceeded")
		get_tree().quit(1))
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var port := 24567
	var ready_file := ""
	for arg in args:
		if arg.begins_with("--port="):
			port = int(arg.trim_prefix("--port="))
		if arg.begins_with("--ready-file="):
			ready_file = arg.trim_prefix("--ready-file=")
	if "--test-host" in args:
		await _host(port, ready_file)
	elif "--test-client" in args:
		await _client(port)
	else:
		await _basic()
	Session.close()
	for failure in failures:
		printerr("CHECK FAILED: " + failure)
	print("CHECKS_PASSED" if failures.is_empty() else "CHECKS_FAILED")
	get_tree().quit(0 if failures.is_empty() else 1)


func _basic() -> void:
	failures.append_array(Rules.new().run())
	for path in ["res://client/menu.tscn", "res://client/player_owner.tscn", "res://client/player_observer.tscn", "res://client/customer.tscn", "res://client/hud.tscn"]:
		var scene := load(path) as PackedScene
		_check(scene != null, "load " + path)
		if scene != null:
			var instance := scene.instantiate()
			instance.free()
	Session.selected_character = 1
	Session.solo()
	var shop := preload("res://client/main.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	var player: CharacterBody2D = shop.get_node("World/Entities/1")
	_check(player.get_node("Sprite").texture.resource_path == "res://assets/characters/purple_shopkeeper/sheet.png", "solo uses chosen sprite rather than seat default")
	var before := player.position
	var purple: Sprite2D = player.get_node("Sprite")
	_check(purple.frame == 0, "purple character begins in relaxed pose")
	await get_tree().create_timer(1.25).timeout
	_check(purple.frame == 1, "purple character advances to drawn inhale frame")
	# Observe the short blink rather than assuming timer and physics callbacks
	# land on exactly the same frame under different headless frame rates.
	var blink_deadline := Time.get_ticks_msec() + 600
	while purple.frame != 2 and Time.get_ticks_msec() < blink_deadline:
		await get_tree().process_frame
	_check(purple.frame == 2, "purple character briefly uses drawn blink frame")
	_key(KEY_W, true)
	await get_tree().create_timer(0.25).timeout
	_check(player.animation.walk_amount > 0.5 and purple.frame >= 12 and purple.frame < 16, "Renna uses rear walking frames for W input")
	_key(KEY_W, false)
	await get_tree().create_timer(0.15).timeout
	_check(player.position.y < before.y - 10.0, "W keyboard input moves local character")
	_check(player.position.distance_to(Session.players[1]["position"]) < 3.0, "authority receives local movement")
	before = player.position
	_key(KEY_RIGHT, true)
	await get_tree().create_timer(0.25).timeout
	_check(purple.frame >= 20 and purple.frame < 24 and not purple.flip_h, "Renna uses the right-facing profile walk")
	_key(KEY_RIGHT, false)
	await get_tree().create_timer(0.1).timeout
	_check(player.position.x > before.x + 10.0, "arrow keyboard input moves local character")
	await get_tree().create_timer(0.3).timeout
	_check(player.animation.walk_amount < 0.05, "stopped character returns to idle")
	_check(purple.frame >= 16 and purple.frame < 20, "horizontal release keeps profile idle")
	_key(KEY_LEFT, true)
	await get_tree().create_timer(0.2).timeout
	_check(purple.frame >= 20 and purple.frame < 24 and purple.flip_h, "left movement mirrors the drawn profile")
	_key(KEY_LEFT, false)
	await get_tree().create_timer(0.3).timeout
	_check(purple.frame >= 16 and purple.frame < 20 and purple.flip_h, "left-facing profile persists while idle")
	_key(KEY_W, true)
	_key(KEY_D, true)
	await get_tree().create_timer(0.2).timeout
	_check(purple.frame >= 12 and purple.frame < 16, "upward diagonal movement also faces away")
	_key(KEY_W, false)
	_key(KEY_D, false)
	await get_tree().create_timer(0.3).timeout
	_check(purple.frame >= 8 and purple.frame < 12, "stopping retains rear-facing idle")
	_key(KEY_S, true)
	await get_tree().create_timer(0.2).timeout
	_check(purple.frame >= 4 and purple.frame < 8, "downward movement returns to front-facing walk")
	_key(KEY_S, false)
	for code in [KEY_A, KEY_D, KEY_W, KEY_S, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_E, KEY_SPACE]:
		var action: StringName = {
			KEY_A: &"move_left", KEY_D: &"move_right", KEY_W: &"move_up", KEY_S: &"move_down",
			KEY_LEFT: &"move_left", KEY_RIGHT: &"move_right", KEY_UP: &"move_up", KEY_DOWN: &"move_down",
			KEY_E: &"interact", KEY_SPACE: &"interact",
		}[code]
		_key(code, true)
		_check(Input.is_action_pressed(action), "keyboard mapping for " + OS.get_keycode_string(code))
		_key(code, false)
	_check(shop.seat == 0 and shop.shop.has("coins"), "solo scene receives seat and shop")
	# A separate presentation fixture is not overwritten by live shop snapshots.
	var queue: Node2D = preload("res://client/customer_view.gd").new()
	add_child(queue)
	var customers := [
		{"id": 1, "order": Game.HEALING_POTION, "patience_seconds": 10.0, "angry": true, "position": Vector2(200, 200), "facing": -PI / 2.0, "phase": "browsing"},
		{"id": 2, "order": Game.MANA_POTION, "patience_seconds": 10.0, "angry": false, "position": Vector2(260, 200), "facing": -PI / 2.0, "phase": "browsing"},
	]
	queue.apply(customers, [0.0, 8.0])
	var first: Node2D = queue.get_child(0)
	var second: Node2D = queue.get_child(1)
	var second_texture: Texture2D = second.get_node("Sprite").texture
	var second_skin: int = second.skin_palette_index
	_check(first.skin_palette_index != second_skin, "neighboring customers have varied fantasy skin")
	_check(first.get_node("Sprite").texture != second_texture, "customers have distinct sprite assets")
	_check(first.get_node("AngryMark").visible, "angry customer keeps visible feedback")
	customers[0]["position"] = Vector2(200, 184)
	customers[1]["position"] = Vector2(260, 184)
	queue.apply(customers, [0.0, 8.0])
	await get_tree().create_timer(0.2).timeout
	_check(first.get_node("Sprite").frame % 24 >= 12 and first.get_node("Sprite").frame % 24 < 16, "arriving customer uses rear walking frames")
	await get_tree().create_timer(0.6).timeout
	_check(first.get_node("Sprite").frame % 24 >= 8 and first.get_node("Sprite").frame % 24 < 12, "waiting customer faces the counter with rear idle frames")
	var old_position := second.position
	customers.remove_at(0)
	customers[0]["position"] = Vector2(304, 184)
	customers[0]["facing"] = 0.0
	queue.apply(customers, [8.0])
	_check(queue.get_node("Customer_2") == second and not queue.has_node("Customer_1"), "queue retains the surviving customer node and removes the served customer")
	_check(second.get_node("Sprite").texture == second_texture, "appearance follows customer ID after queue shifts")
	_check(second.skin_palette_index == second_skin, "skin color survives queue reordering")
	_check(second.position == old_position, "queue shift does not teleport the customer")
	await get_tree().create_timer(0.2).timeout
	_check(second.position.x > old_position.x and second.position.x < 304.0, "customer smoothly follows authoritative browsing motion")
	_check(second.get_node("Sprite").frame % 24 >= 20, "customer uses profile walking frames while shifting sideways")
	_check(second.get_node("Sprite").modulate == Color.WHITE, "skin is not recolored by whole-body tint")
	_check(not second.get_node("AngryMark").visible, "surviving customer keeps its own calm state")
	# Every outfit gets every palette, rather than binding a color to a role.
	for kind in 4:
		var seen := {}
		for visit in 8:
			second.show_customer(1 + kind + visit * 4, Game.HEALING_POTION, 1.0, false)
			seen[second.skin_palette_index] = true
			_check(second.get_node("Sprite").frame / 24 == second.skin_palette_index, "animation stays within the correct skin palette block")
		_check(seen.size() == 8, "all fantasy palettes available to outfit %d" % kind)
	queue.queue_free()
	shop.queue_free()
	await get_tree().process_frame
	Session.selected_character = 0
	Session.solo()
	shop = preload("res://client/main.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	player = shop.get_node("World/Entities/1")
	var witch: Sprite2D = player.get_node("Sprite")
	_check(witch.texture.resource_path == "res://assets/characters/blue_witch/sheet.png", "slot zero uses the redrawn original witch")
	var idle_frame := witch.frame
	await get_tree().create_timer(1.25).timeout
	_check(witch.frame < 4 and witch.frame != idle_frame, "blue witch cycles authored idle frames")
	_key(KEY_D, true)
	await get_tree().create_timer(0.2).timeout
	_check(witch.frame >= 20 and witch.frame < 24, "Aaron uses the drawn profile when walking right")
	_key(KEY_D, false)
	await get_tree().create_timer(0.3).timeout
	_check(witch.frame >= 16 and witch.frame < 20, "Aaron keeps profile idle when stopping")
	_key(KEY_UP, true)
	await get_tree().create_timer(0.2).timeout
	_check(witch.frame >= 12 and witch.frame < 16, "Aaron uses rear walking frames for up-arrow input")
	_key(KEY_UP, false)
	await get_tree().create_timer(0.3).timeout
	_check(witch.frame >= 8 and witch.frame < 12, "Aaron retains rear idle on release")
	await _interactive_inputs(shop)
	shop.queue_free()
	await get_tree().process_frame


func _host(port: int, ready_file: String) -> void:
	Session.selected_character = 0
	_check(Session.host(port) == OK, "host listens")
	if not Session.active:
		return
	var shop := preload("res://client/main.tscn").instantiate()
	add_child(shop)
	var file := FileAccess.open(ready_file, FileAccess.WRITE)
	file.store_string("ready")
	file.close()
	var initial_stock := int(Session.document["shelves"][Game.WATERBLOOM])
	# Two sequential clients exercise disconnect, seat reuse and late snapshots.
	for cycle in 2:
		while Session.players.size() < 2:
			await get_tree().process_frame
		var saw_rear_walk := false
		var saw_profile_walk := false
		while str(Session.document["held"]["1"]) != Game.WATERBLOOM:
			for node in shop.get_node("World/Entities").get_children():
				if node.get("seat") == 1:
					var sprite: Sprite2D = node.get_node("Sprite")
					if sprite.frame >= 12 and sprite.frame < 16:
						saw_rear_walk = true
					if sprite.frame >= 20 and sprite.frame < 24 and sprite.flip_h:
						saw_profile_walk = true
			await get_tree().process_frame
		_check(saw_rear_walk, "host observes remote player's rear walking animation")
		_check(saw_profile_walk, "host observes remote player's left-facing profile walk")
		_check(int(Session.document["shelves"][Game.WATERBLOOM]) == initial_stock - cycle - 1, "host sees client interaction exactly once")
		while Session.players.size() > 1:
			await get_tree().process_frame
		_check(str(Session.document["held"]["1"]) == "", "disconnect clears inventory")
		_check((Session.document["inventory"]["1"] as Array).is_empty(), "disconnect clears the remote bag as well as its selected item")
	shop.queue_free()
	await get_tree().process_frame


func _client(port: int) -> void:
	Session.selected_character = 1
	Session.command_finished.connect(func(value: Dictionary) -> void: result = value)
	_check(Session.join_host("127.0.0.1", port) == OK, "client starts connection")
	while not Session.active:
		await get_tree().process_frame
	_check(Session.local_seat == 1 and Session.players.size() == 2, "join receives distinct seat and both players")
	var stock := int(Session.document["shelves"][Game.WATERBLOOM])
	var local_stock := int(Session.document["shelf_stock"][Game.shelf_id(Game.WATERBLOOM)][Game.WATERBLOOM])
	Session.send_command("take", Game.shelf_id(Game.WATERBLOOM), Game.WATERBLOOM)
	while result.is_empty():
		await get_tree().process_frame
	_check(not bool(result["ok"]) and result["reason"] == "too_far", "remote out-of-range command refused")
	var position: Vector2 = Session.players[multiplayer.get_unique_id()]["position"]
	# Actual northward movement must also select rear frames on the other peer.
	for step in 4:
		position += Vector2(0.0, -8.0)
		Session.send_motion(position, -PI / 2.0)
		await get_tree().create_timer(0.08).timeout
	for step in 4:
		position += Vector2(-8.0, 0.0)
		Session.send_motion(position, PI)
		await get_tree().create_timer(0.08).timeout
	var target := Game.shelf_spot(Game.WATERBLOOM)
	# Transport integration: legal-speed pose updates, independent of rendering.
	var navigation := preload("res://network/shop_navigation.gd").new()
	for waypoint in navigation.route(position, target):
		while position.distance_to(waypoint) > 0.1:
			var direction := (waypoint - position).angle()
			position = position.move_toward(waypoint, 12.0)
			Session.send_motion(position, direction)
			await get_tree().create_timer(0.08).timeout
	_check((Session.players[multiplayer.get_unique_id()]["position"] as Vector2).distance_to(target) < 1.0, "host accepts and replicates movement")
	result = {}
	Session.send_command("take", Game.shelf_id(Game.WATERBLOOM), Game.WATERBLOOM)
	while result.is_empty():
		await get_tree().process_frame
	_check(bool(result["ok"]), "remote ingredient pickup accepted")
	_check(str(Session.document["held"]["1"]) == Game.WATERBLOOM, "client receives authoritative held item")
	_check((Session.document["inventory"]["1"] as Array).has(Game.WATERBLOOM), "remote inventory contents replicate alongside selected item")
	_check(int(Session.document["shelves"][Game.WATERBLOOM]) == stock - 1, "client stock converges")
	_check(int(Session.document["shelf_stock"][Game.shelf_id(Game.WATERBLOOM)][Game.WATERBLOOM]) == local_stock - 1, "specific shelf stack replicates to client")
	var shop := preload("res://client/main.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	_check(shop.get_node("World/Entities").get_child_count() == 2, "client scene creates owner and observer")
	_check(shop.seat == 1, "client scene owns second seat")
	var local: Node = shop.get_node("World/Entities/" + str(multiplayer.get_unique_id()))
	_check(local.get_node("Sprite").texture.resource_path == "res://assets/characters/purple_shopkeeper/sheet.png", "client uses chosen purple character sheet")
	_check(shop.get_node("World/Entities/1/Sprite").texture.resource_path == "res://assets/characters/blue_witch/sheet.png", "observer uses host blue witch sheet")
	await get_tree().create_timer(0.2).timeout
	shop.queue_free()
	await get_tree().process_frame


func _interactive_inputs(shop: Node2D) -> void:
	# Position fixtures isolate real E-key targeting and scene feedback. Movement
	# and route reachability are covered separately; this is not a human walkthrough.
	Session.authority.shop.doc["customers"] = []
	Session.authority.shop._paths.clear()
	Session.authority.shop._next_arrival_msec = Time.get_ticks_msec() + 60000
	var potion_rack: Node = shop.get_node("World/Props/water_south")
	var visible_bottles := 0
	for stack in potion_rack._icons:
		for icon in stack:
			if icon.visible:
				visible_bottles += 1
	_check(visible_bottles == 0, "empty potion furniture contains no baked or runtime stock")
	for item in Game.ALL_ITEMS:
		var icon := preload("res://client/item_icon.gd").new()
		icon.set_item(item)
		_check(icon.texture != null and icon.texture.get_size() == Vector2(128, 40), "independent animated item asset exists: " + str(item))
		icon.free()
	# Exercise actual CharacterBody collision against the front of the tall shelf.
	var approach := Game.shelf_spot(Game.MOONLEAF)
	Session.authority.players[1]["position"] = approach
	Session._correct(Session.authority.players[1])
	Session._publish()
	var player: CharacterBody2D = shop.get_node("World/Entities/1")
	_key(KEY_W, true)
	await get_tree().create_timer(0.5).timeout
	_key(KEY_W, false)
	_check(Game.floor_clear(player.position, Game.PLAYER_RADIUS - 0.6) and player.position.y > 115, "actual player stops at angled shelf front instead of walking through sprite")
	_check(player.position.y < approach.y - 5.0, "player can approach until feet reach collision")
	_check(Game.floor_clear(player.position, Game.PLAYER_RADIUS - 0.5), "physical body and shared footprint agree")
	for fixture in [{"id": "moon_island", "key": KEY_W}, {"id": "water_east", "key": KEY_W}, {"id": "fire_east", "key": KEY_W}]:
		var start := Game.station_point(fixture["id"])
		Session.authority.players[1]["position"] = start
		Session._correct(Session.authority.players[1])
		Session._publish()
		_key(fixture["key"], true)
		await get_tree().create_timer(0.45).timeout
		_key(fixture["key"], false)
		await get_tree().create_timer(0.1).timeout
		_check(player.position.distance_to(start) > 3.0, "player approaches oriented shelf: " + fixture["id"])
		_check(Game.floor_clear(player.position, Game.PLAYER_RADIUS - 0.5), "physical collision follows angled footprint: " + fixture["id"])
		_check(player.position.distance_to(Session.players[1]["position"]) < 2.0, "collision and authority stay synchronized: " + fixture["id"])
	for raw in Game.recipe_needs(Game.HEALING_POTION):
		await _search_collect(shop, Game.shelf_id(raw), raw)
		_check(Session.authority.shop.inventory(0).has(raw), "search panel collects an ingredient into inventory")
	_check(Session.authority.shop.inventory(0).size() == 2, "two ingredients can be carried together")
	_key(KEY_1, true)
	await get_tree().process_frame
	_key(KEY_1, false)
	_check(Session.authority.shop.held(0) == Game.MOONLEAF, "inventory hotkey selects the first ingredient")
	await _interact_at(Game.station_point("cauldron"))
	_check(Session.authority.shop.inventory(0).size() == 1, "adding one ingredient preserves the rest of the bag")
	await _interact_at(Game.station_point("cauldron"))
	_check(Session.authority.shop.inventory(0).is_empty(), "second selected ingredient completes the recipe")
	await get_tree().create_timer(5.2).timeout
	await _interact_at(Game.station_point("cauldron"))
	_check(Session.authority.shop.held(0) == Game.HEALING_POTION, "E collects brewed potion from cauldron")
	await _interact_at(Game.station_point("water_south"))
	_check(Session.authority.shop.held(0) == "", "display shelf directly accepts the selected bottle")
	_check(Session.authority.shop.stock_at("water_south", Game.HEALING_POTION) == 1, "crafted bottle can be placed on an empty shelf")
	await _interact_at(Game.station_point("water_south"))
	await _click_control(shop.hud._shelf_buttons[Game.HEALING_POTION]["button"])
	_check(Session.authority.shop.held(0) == Game.HEALING_POTION, "bottle can be picked back up from shelf")
	shop.hud.close_panels()
	_check(not shop.has_node("World/Props/storage_west"), "chests are removed from the room")
	_check(not shop.has_node("Walls"), "old rectangular collision walls are absent")
	_check(shop.get_node("Environment/GeneratedWalls/Boundary").get_child_count() == Game.Cottage.FLOOR_POINTS.size(), "physics follows every edge of the irregular cottage outline")
	Session.authority.shop._arrive(Time.get_ticks_msec())
	var customer: Dictionary = Session.authority.shop.doc["customers"][0]
	customer["position"] = Vector2(288, 192)
	customer["order"] = Game.HEALING_POTION
	customer["phase"] = "waiting"
	customer["look_until"] = Time.get_ticks_msec() + 10000
	Session.authority.shop._arrive(Time.get_ticks_msec())
	var other: Dictionary = Session.authority.shop.doc["customers"][1]
	other["position"] = Vector2(320, 192)
	other["order"] = Game.MANA_POTION
	other["phase"] = "waiting"
	other["look_until"] = Time.get_ticks_msec() + 10000
	Session.authority.shop._paths.clear()
	Session.authority.players[1]["position"] = Vector2(288, 206)
	Session._correct(Session.authority.players[1])
	Session._publish()
	await get_tree().process_frame
	await _click_world(shop, Vector2(320, 104))
	_check(not customer["served"] and Session.authority.shop.held(0) == Game.HEALING_POTION, "clicking another request targets that customer, not the nearest one")
	await _click_world(shop, Vector2(288, 104))
	_check(customer["served"] and int(Session.document["coins"]) == Game.reward(Game.HEALING_POTION), "E serves nearby roaming customer and awards coins")
	Session.authority.shop.doc["door_open_until"] = 0
	await _interact_at(Game.DOOR_POINT)
	await get_tree().create_timer(0.25).timeout
	_check(shop.get_node("Environment/Door").frame > 0, "E plays door opening frames")
	await _search_collect(shop, Game.shelf_id(Game.WATERBLOOM), Game.WATERBLOOM)
	_check(Session.authority.shop.held(0) == Game.WATERBLOOM, "search UI targets a non-default ingredient sprite")
	_key(KEY_R, true)
	await get_tree().process_frame
	_key(KEY_R, false)
	_check(shop.hud._recipe_panel.visible, "R opens recipe book")
	for potion in Game.POTIONS:
		var row: Node = shop.hud._recipe_panel.find_child("Recipe_" + str(potion), true, false)
		var shown: Array = []
		if row != null:
			for child in row.get_children():
				if child.has_method("setup"):
					shown.append(child.icon.item_id)
		var expected: Array = Game.recipe_needs(potion).keys()
		expected.append(potion)
		_check(shown == expected, "recipe shows exact reusable ingredient/bottle sprites, without item names")
	_check(not shop.has_node("Room/Queue") and not shop.has_node("World/Props/prep"), "old queue rectangle and removed stations are absent")
	shop.hud.close_panels()
	Session.authority.shop.doc["customers"] = [other]
	other["position"] = Vector2(248, 200)
	other["phase"] = "waiting"
	other["look_until"] = Time.get_ticks_msec() + 20000
	Session.authority.shop._paths.clear()
	Session.authority.players[1]["position"] = Vector2(248, 240)
	Session._correct(Session.authority.players[1])
	Session._publish()
	await get_tree().create_timer(1.5).timeout
	_key(KEY_W, true)
	await get_tree().create_timer(0.6).timeout
	_key(KEY_W, false)
	_check(player.position.y >= 218.4, "real player input stops at customer feet")

func _click_world(shop: Node2D, point: Vector2) -> void:
	var at := get_viewport().get_screen_transform() * (shop.get_global_transform_with_canvas() * point)
	await _click_screen(at)

func _click_control(control: Control) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var at := get_viewport().get_screen_transform() * (control.get_global_transform_with_canvas() * (control.size * 0.5))
	await _click_screen(at)

func _search_collect(shop: Node2D, station: String, item: String) -> void:
	await _interact_at(Game.station_point(station))
	_check(shop.hud.shelf_open(), "E opens nearby shelf discoveries")
	if shop.hud.shelf_open():
		await _click_control(shop.hud._shelf_buttons[item]["button"])
		shop.hud.close_panels()

func _click_screen(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.device = InputEvent.DEVICE_ID_MOUSE
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.device = InputEvent.DEVICE_ID_MOUSE
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await get_tree().process_frame

func _interact_at(point: Vector2, selected_item: String = "") -> void:
	Session.authority.players[1]["position"] = point
	Session._correct(Session.authority.players[1])
	Session._publish()
	await get_tree().process_frame
	if selected_item != "":
		get_node("Main/World/Props/" + Game.shelf_id(selected_item)).select_item(selected_item)
	_key(KEY_E, true)
	await get_tree().process_frame
	await get_tree().physics_frame
	_key(KEY_E, false)
	await get_tree().process_frame

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.device = InputEvent.DEVICE_ID_KEYBOARD
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
