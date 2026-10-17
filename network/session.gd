extends Node
## Stable autoload RPC path on every peer. Solo uses the same authority rules
## as a listen-server host; ENet carries only inputs and authoritative state.

signal started
signal state_changed
signal failed(message: String)
signal command_finished(result: Dictionary)
signal corrected(pose: Dictionary)

const Game = preload("res://network/game.gd")
const Authority = preload("res://authority/main.gd")
const DEFAULT_PORT := 24567

var active := false
## Appearance choice persists when returning to the menu; the host validates it.
var selected_character := 1
var local_seat := -1
var players := {}
var document := {}
var authority: RefCounted
var _elapsed := 0.0
var _command_id := 0
var _joining := false
var _join_elapsed := 0.0
var _online := false


func _ready() -> void:
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func() -> void: _fail("Could not connect to the host."))
	multiplayer.server_disconnected.connect(func() -> void: _fail("The host disconnected. Return to the menu to start again."))
	multiplayer.peer_disconnected.connect(_peer_left)


func solo() -> void:
	close()
	authority = Authority.new()
	authority.join(1, selected_character)
	_publish()


func host(port: int = DEFAULT_PORT) -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, Game.MAX_PLAYERS - 1)
	if error != OK:
		_fail("Could not host on port %d: %s" % [port, error_string(error)])
		return error
	multiplayer.multiplayer_peer = peer
	_online = true
	authority = Authority.new()
	authority.join(1, selected_character)
	_publish()
	return OK


func join_host(address: String, port: int = DEFAULT_PORT) -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		_fail("Could not join: %s" % error_string(error))
		return error
	multiplayer.multiplayer_peer = peer
	_online = true
	_joining = true
	return OK


func close() -> void:
	active = false
	_joining = false
	_join_elapsed = 0.0
	_online = false
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	authority = null
	local_seat = -1
	players = {}
	document = {}
	_elapsed = 0.0
	_command_id = 0


func _fail(message: String) -> void:
	close()
	failed.emit(message)


func _connected() -> void:
	_request_join.rpc_id(1, selected_character)


@rpc("any_peer", "call_remote", "reliable")
func _request_join(character: int) -> void:
	if authority == null:
		return
	var peer := multiplayer.get_remote_sender_id()
	if authority.join(peer, character):
		_publish()
	else:
		_rejected.rpc_id(peer, "The shop is full.")


@rpc("authority", "call_remote", "reliable")
func _rejected(message: String) -> void:
	_fail(message)


func _peer_left(peer: int) -> void:
	if authority != null:
		authority.leave(peer)
		_publish()


func _process(delta: float) -> void:
	if _joining:
		_join_elapsed += delta
		if _join_elapsed > 10.0:
			_fail("Connection timed out. Check the host address and port.")
	if authority == null:
		return
	_elapsed += delta
	var changed: bool = authority.shop.tick()
	if changed or _elapsed >= Game.SHOP_HEARTBEAT:
		_elapsed = 0.0
		_publish()


func _publish() -> void:
	if authority == null:
		return
	_receive_state(authority.players, authority.shop.doc)
	if _online:
		# Only admitted peers receive game state.
		for peer in authority.players:
			if int(peer) != 1:
				_receive_state.rpc_id(int(peer), authority.players, authority.shop.doc)


@rpc("authority", "call_remote", "reliable")
func _receive_state(poses: Dictionary, shop: Dictionary) -> void:
	var peer := multiplayer.get_unique_id()
	if not poses.has(peer):
		return
	players = poses.duplicate(true)
	document = shop.duplicate(true)
	local_seat = int(players[peer]["seat"])
	_joining = false
	if not active:
		active = true
		started.emit()
	state_changed.emit()


func send_motion(position: Vector2, facing: float) -> void:
	if not active:
		return
	if authority != null:
		_apply_motion(1, position, facing)
	else:
		_motion.rpc_id(1, position, facing)


@rpc("any_peer", "call_remote", "reliable")
func _motion(position: Vector2, facing: float) -> void:
	if authority != null:
		_apply_motion(multiplayer.get_remote_sender_id(), position, facing)


func _apply_motion(peer: int, position: Vector2, facing: float) -> void:
	if not authority.players.has(peer):
		return
	if not authority.move(peer, position, facing):
		if peer == 1:
			_correct(authority.players[peer])
		else:
			_correct.rpc_id(peer, authority.players[peer])
	_publish()


@rpc("authority", "call_remote", "reliable")
func _correct(pose: Dictionary) -> void:
	corrected.emit(pose)


func send_command(action: String, station: String, item: String) -> void:
	if not active:
		return
	_command_id += 1
	if authority != null:
		_apply_command(1, _command_id, action, station, item)
	else:
		_command.rpc_id(1, _command_id, action, station, item)


@rpc("any_peer", "call_remote", "reliable")
func _command(id: int, action: String, station: String, item: String) -> void:
	if authority != null:
		_apply_command(multiplayer.get_remote_sender_id(), id, action, station, item)


func _apply_command(peer: int, id: int, action: String, station: String, item: String) -> void:
	var result: Dictionary = authority.command(peer, id, action, station, item)
	_publish()
	if peer == 1:
		_command_result(result)
	else:
		_command_result.rpc_id(peer, result)


@rpc("authority", "call_remote", "reliable")
func _command_result(result: Dictionary) -> void:
	command_finished.emit(result)
