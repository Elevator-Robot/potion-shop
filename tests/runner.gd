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
	Session.solo()
	var shop := preload("res://client/main.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	var player: CharacterBody2D = shop.get_node("Entities/1")
	var before := player.position
	Input.action_press("move_up")
	await get_tree().create_timer(0.25).timeout
	Input.action_release("move_up")
	await get_tree().create_timer(0.15).timeout
	_check(player.position.y < before.y - 10.0, "real movement input moves local character")
	_check(player.position.distance_to(Session.players[1]["position"]) < 3.0, "authority receives local movement")
	_check(shop.seat == 0 and shop.shop.has("coins"), "solo scene receives seat and shop")
	shop.queue_free()
	await get_tree().process_frame


func _host(port: int, ready_file: String) -> void:
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
	await get_tree().create_timer(0.2).timeout
	shop.queue_free()
	await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
