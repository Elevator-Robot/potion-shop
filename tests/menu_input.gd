extends SceneTree
## Drive GUI events through the viewport instead of emitting button signals.

func _initialize() -> void:
	_test.call_deferred()


func _test() -> void:
	var menu: Control = load("res://client/menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	await process_frame
	var solo: Button = menu.get_node("Center/Content/Buttons/Solo")
	if "--keyboard" in OS.get_cmdline_user_args():
		if not solo.has_focus():
			printerr("MENU_INPUT_FAIL: Play Solo has no initial keyboard focus")
			quit(1)
			return
		for pressed in [true, false]:
			var key := InputEventKey.new()
			key.device = InputEvent.DEVICE_ID_KEYBOARD
			key.keycode = KEY_ENTER
			key.physical_keycode = KEY_ENTER
			key.pressed = pressed
			root.push_input(key, true)
			await process_frame
	else:
		var point := solo.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.device = InputEvent.DEVICE_ID_MOUSE
		motion.position = point
		motion.global_position = point
		root.push_input(motion, true)
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.device = InputEvent.DEVICE_ID_MOUSE
			event.position = point
			event.global_position = point
			event.button_index = MOUSE_BUTTON_LEFT
			event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
			event.pressed = pressed
			# Local viewport coordinates also work with headless stretch transforms.
			root.push_input(event, true)
			await process_frame
	await process_frame
	var passed := current_scene != null and current_scene.scene_file_path == "res://client/main.tscn"
	print("CHECKS_PASSED" if passed else "CHECKS_FAILED: menu input did not open the shop")
	quit(0 if passed else 1)
