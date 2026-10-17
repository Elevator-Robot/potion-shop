extends Node2D
var _door_until := 0.0
var _server_now := 0.0
var _received := 0.0
var _open := 0.0

func apply_shop(document: Dictionary) -> void:
	_door_until = float(document.get("door_open_until", 0))
	_server_now = float(document.get("now_msec", 0))
	_received = Time.get_ticks_msec()

func _process(delta: float) -> void:
	var now := _server_now + Time.get_ticks_msec() - _received
	_open = move_toward(_open, 1.0 if now < _door_until else 0.0, delta * 5.0)
	$Door.frame = roundi(_open * 3.0)
	for i in 3:
		get_node("Window%d" % i).frame = (int(Time.get_ticks_msec() / 450) + i) % 4

func highlight_door(on: bool) -> void:
	$DoorCue.visible = on
