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
	var player: CharacterBody2D = shop.get_node("Entities/1")
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
	_check(player.animation.walk_amount > 0.5 and purple.frame >= 4, "walking uses purple character's drawn step frames")
	_key(KEY_W, false)
	await get_tree().create_timer(0.15).timeout
	_check(player.position.y < before.y - 10.0, "W keyboard input moves local character")
	_check(player.position.distance_to(Session.players[1]["position"]) < 3.0, "authority receives local movement")
	before = player.position
	_key(KEY_RIGHT, true)
	await get_tree().create_timer(0.25).timeout
	_key(KEY_RIGHT, false)
	await get_tree().create_timer(0.1).timeout
	_check(player.position.x > before.x + 10.0, "arrow keyboard input moves local character")
	await get_tree().create_timer(0.3).timeout
	_check(player.animation.walk_amount < 0.05, "stopped character returns to idle")
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
	var queue: Node2D = shop.get_node("Room/Queue/Customers")
	var customers := [
		{"id": 1, "order": Game.HEALING_POTION, "patience_seconds": 10.0, "angry": true},
		{"id": 2, "order": Game.MANA_POTION, "patience_seconds": 10.0, "angry": false},
	]
	queue.apply(customers, [0.0, 8.0])
	var first: Node2D = queue.get_child(0)
	var second: Node2D = queue.get_child(1)
	var second_texture: Texture2D = second.get_node("Sprite").texture
	_check(first.get_node("Sprite").texture != second_texture, "customers have distinct sprite assets")
	_check(first.get_node("AngryMark").visible, "angry customer keeps visible feedback")
	customers.remove_at(0)
	queue.apply(customers, [8.0])
	_check(first.get_node("Sprite").texture == second_texture, "appearance follows customer ID after queue shifts")
	_check(not first.get_node("AngryMark").visible and not second.visible, "reused queue slot clears old anger and hides unused customer")
	shop.queue_free()
	await get_tree().process_frame
	Session.selected_character = 0
	Session.solo()
	shop = preload("res://client/main.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	player = shop.get_node("Entities/1")
	var elf: Sprite2D = player.get_node("Sprite")
	var idle_frame := elf.frame
	await get_tree().create_timer(0.25).timeout
	_check(elf.frame < 4 and elf.frame != idle_frame, "elf cycles authored idle frames")
	_key(KEY_D, true)
	await get_tree().create_timer(0.2).timeout
	_check(elf.frame >= 4 and elf.frame < 8, "elf uses walking frames during movement")
	_key(KEY_D, false)
	await get_tree().create_timer(0.3).timeout
	_check(elf.frame < 4, "elf returns to idle frames after stopping")
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
	# Two sequential clients exercise disconnect, seat reuse and late snapshots.
	for cycle in 2:
		while Session.players.size() < 2:
			await get_tree().process_frame
		while str(Session.document["held"]["1"]) != Game.WATERBLOOM:
			await get_tree().process_frame
		_check(int(Session.document["shelves"][Game.WATERBLOOM]) == Game.SHELF_START_STOCK - cycle - 1, "host sees client interaction exactly once")
		while Session.players.size() > 1:
			await get_tree().process_frame
		_check(str(Session.document["held"]["1"]) == "", "disconnect clears inventory")
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
	Session.send_command("take", "shelves", Game.WATERBLOOM)
	while result.is_empty():
		await get_tree().process_frame
	_check(not bool(result["ok"]) and result["reason"] == "too_far", "remote out-of-range command refused")
	var position: Vector2 = Session.players[multiplayer.get_unique_id()]["position"]
	var target := Game.shelf_spot(Game.WATERBLOOM)
	# Transport integration: legal-speed pose updates, independent of rendering.
	while position.distance_to(target) > 0.1:
		position = position.move_toward(target, 12.0)
		Session.send_motion(position, 0.0)
		await get_tree().create_timer(0.08).timeout
	_check((Session.players[multiplayer.get_unique_id()]["position"] as Vector2).distance_to(target) < 1.0, "host accepts and replicates movement")
	result = {}
	Session.send_command("take", "shelves", Game.WATERBLOOM)
	while result.is_empty():
		await get_tree().process_frame
	_check(bool(result["ok"]), "remote ingredient pickup accepted")
	_check(str(Session.document["held"]["1"]) == Game.WATERBLOOM, "client receives authoritative held item")
	_check(int(Session.document["shelves"][Game.WATERBLOOM]) == stock - 1, "client stock converges")
	var shop := preload("res://client/main.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	_check(shop.get_node("Entities").get_child_count() == 2, "client scene creates owner and observer")
	_check(shop.seat == 1, "client scene owns second seat")
	var local: Node = shop.get_node("Entities/" + str(multiplayer.get_unique_id()))
	_check(local.get_node("Sprite").texture.resource_path == "res://assets/characters/purple_shopkeeper/sheet.png", "client uses chosen purple character sheet")
	_check(shop.get_node("Entities/1/Sprite").texture.resource_path == "res://assets/characters/elf_adventurer.png", "observer uses host elf sheet")
	await get_tree().create_timer(0.2).timeout
	shop.queue_free()
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
