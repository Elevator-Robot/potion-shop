extends Control

const PORTRAITS := [
	preload("res://assets/characters/elf_adventurer_preview.tres"),
	preload("res://assets/characters/purple_shopkeeper/preview.tres"),
]

@onready var address: LineEdit = %Address
@onready var port: SpinBox = %Port
@onready var status: Label = %Status
@onready var buttons: VBoxContainer = %Buttons


func _ready() -> void:
	%Character.select(Session.selected_character)
	_pick_character(Session.selected_character)
	%Character.item_selected.connect(_pick_character)
	Session.started.connect(_start_game)
	Session.failed.connect(_failed)
	%Solo.pressed.connect(Session.solo)
	%Host.pressed.connect(func() -> void: Session.host(int(port.value)))
	%Join.pressed.connect(_join)
	%Cancel.pressed.connect(_cancel)
	%Solo.grab_focus.call_deferred()
	# CLI shortcuts for running two editor-independent instances.
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--port="):
			port.value = int(arg.trim_prefix("--port="))
	if "--solo" in args:
		Session.solo.call_deferred()
	elif "--host" in args:
		Session.host.call_deferred(int(port.value))
	else:
		for arg in args:
			if arg.begins_with("--join="):
				address.text = arg.trim_prefix("--join=")
				_join.call_deferred()


func _join() -> void:
	if address.text.strip_edges().is_empty():
		status.text = "Enter the host's address."
		return
	status.text = "Connecting..."
	_set_busy(true)
	Session.join_host(address.text.strip_edges(), int(port.value))


func _pick_character(index: int) -> void:
	Session.selected_character = index
	%Portrait.texture = PORTRAITS[index]


func _start_game() -> void:
	get_tree().change_scene_to_file.call_deferred("res://client/main.tscn")


func _failed(message: String) -> void:
	status.text = message
	_set_busy(false)


func _cancel() -> void:
	Session.close()
	status.text = ""
	_set_busy(false)


func _set_busy(busy: bool) -> void:
	%Character.disabled = busy
	for button in buttons.get_children():
		if button is Button:
			button.disabled = busy
	%Cancel.visible = busy
	if busy:
		%Cancel.grab_focus()
	else:
		%Solo.grab_focus()
