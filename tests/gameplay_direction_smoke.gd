extends "res://tests/hazard_practice_smoke.gd"
## Finite scripted input checks; manual-play mode has no automatic actions/exit.
var checks: Array[Dictionary] = []
const OUT := "res://artifacts/gameplay_direction"

func _run() -> void:
	host = preload("res://tests/gameplay_direction.tscn").instantiate()
	root.add_child(host)
	await _loaded()
	_check(host.main.ball.can_shoot(), "F6 scene opens immediately into playable A1")
	for index in 9:
		host.selector.item_selected.emit(index)
		await _loaded()
		_check(host.selected == index and not host.art_reference, "selector loads family variant %d" % index)
		_check(host.main.level_builder.active_level.benchmark_id == host.Catalog.IDS[index], "real builder receives selected dictionary")
		_key(KEY_TAB)
		await _frames(25)
		_check(not host.main.ball.input_enabled, "overview gates aiming")
		await _capture("play_" + host.Catalog.IDS[index])
		_key(KEY_TAB)
		await _frames(25)
	_key(KEY_F8)
	await _loaded()
	_check(host.tier == 2, "difficulty key selects Hard")
	_key(KEY_F6)
	await _loaded()
	_check(host.selected == 7, "previous key")
	_key(KEY_F7)
	await _loaded()
	_check(host.selected == 8, "next key")
	host._select(0)
	await _loaded()
	await _frames(30)
	if DisplayServer.get_name() != "headless":
		root.grab_focus()
		await _frames(5)
		var point: Vector2 = host.main.ball.get_global_transform_with_canvas().origin
		Input.warp_mouse(point)
		await _frames(3)
		_mouse(point, true)
		await _frames(2)
		print("MOUSE_PICK screen=", point, " viewport=", root.get_mouse_position(), " world=", host.main.ball.get_global_mouse_position(), " ball=", host.main.ball.global_position)
		_check(host.main.ball.selected, "mouse down selects actual ball")
		Input.warp_mouse(point - Vector2(50, 0))
		await _frames(4)
		_mouse(point - Vector2(50, 0), false)
		await physics_frame
		await physics_frame
		_check(host.main.run_state.strokes == 1, "native cursor drag plus viewport release accepts one shot")
		_key(KEY_R)
		await _frames(5)
		_check(host.main.run_state.strokes == 1 and host.main.ball.can_shoot(), "R keeps accepted stroke")
	_key(KEY_F9)
	await _loaded()
	_key_hold(KEY_UP, true)
	await _frames(8)
	_key_hold(KEY_UP, false)
	_key(KEY_SPACE)
	await physics_frame
	await physics_frame
	_check(host.main.run_state.strokes == 1, "keyboard aim plus Space accepts one shot")
	var mover: MovingHazard
	for child in host.main.level_builder.level_root.get_children():
		if child is MovingHazard:
			mover = child
	host.main._show_main_menu()
	await physics_frame
	var phase := mover.elapsed
	var position: Vector2 = host.main.ball.position
	await _frames(12)
	_check(is_equal_approx(mover.elapsed, phase), "pause freezes swing phase")
	_check(host.main.ball.position.is_equal_approx(position), "pause freezes moving ball")
	host.main._hide_main_menu()
	await _frames(5)
	_check(mover.elapsed > phase, "resume continues same swing")
	_key(KEY_F9)
	await _loaded()
	_check(host.main.run_state.strokes == 0 and host.main.run_state.total_strokes == 0, "fresh attempt resets both ledgers")
	_key(KEY_H)
	await _frames(3)
	_check(host.details, "course brief opens")
	await _capture("brief")
	_key(KEY_H)
	_key(KEY_F10)
	await _loaded()
	_check(host.art_reference, "shared Meadow reference opens")
	var reference := preload("res://tools/pixel_sample/sample_level.gd").create()
	for key in ["map", "start_cell", "hole_cell", "hazards", "obstacles", "moving_hazards"]:
		_check(host.main.level_builder.active_level[key] == reference[key], "shared art fixture preserves " + key)
	await _capture("shared_meadow")
	host._select(0)
	await _loaded()
	for size in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = size
		await _frames(8)
		_check(root.get_visible_rect().encloses(host.panel.get_global_rect()), "selector fits at %s" % size)
		await _capture("selector_%dx%d" % [size.x, size.y])
	var file := FileAccess.open(OUT + "/input_smoke.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures,
		"method": "Scripted Godot key/button events; actual OS cursor warp for mouse pick/drag, no human feel claim"}, "\t"))
	host.queue_free()
	await process_frame
	print("DIRECTION_INPUT_SMOKE checks=%d failures=%s" % [checks.size(), failures])
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, label: String) -> void:
	checks.append({"check": label, "passed": condition})
	super._check(condition, label)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "/after/" + label + ".png")

func _frames(count: int) -> void:
	for index in count:
		await process_frame

func _key_hold(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _mouse(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.global_position = point
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
