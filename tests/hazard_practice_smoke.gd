extends SceneTree
## Native input and pause/reset smoke for the development practice host.
const OUTPUT := "user://hazard_checkpoint_20260910"
var host
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	host = preload("res://tests/hazard_benchmark_play.gd").new()
	root.add_child(host)
	await _loaded()
	await _capture("practice_A1")
	for expected in range(1, 9):
		_key(KEY_F7)
		await _loaded()
		_check(host.selected == expected, "F7 selects fixture %d" % expected)
		_check(host.main.ball.can_shoot(), "new practice ball ready")
		if expected in [4, 6]:
			_key(KEY_TAB)
			for tick in 20:
				await process_frame
			await _capture("practice_" + ["A1", "A2", "A3", "B1", "B2", "B3", "C1", "C2", "C3"][expected] + "_overview")
			_key(KEY_TAB)
	_key(KEY_F8)
	await _loaded()
	_check(host.tier == 2, "timing difficulty changed")
	_key(KEY_F6)
	await _loaded()
	_check(host.selected == 7, "previous fixture")
	_key(KEY_F7)
	await _loaded()
	# The player's actual held Up input establishes keyboard aim/power.
	var aim := InputEventKey.new()
	aim.keycode = KEY_UP
	aim.physical_keycode = KEY_UP
	aim.pressed = true
	Input.parse_input_event(aim)
	Input.flush_buffered_events()
	for tick in 30:
		await physics_frame
	aim = aim.duplicate()
	aim.pressed = false
	Input.parse_input_event(aim)
	Input.flush_buffered_events()
	_key(KEY_SPACE)
	for tick in 3:
		await physics_frame
	_check(host.main.run_state.strokes == 1, "native keyboard shoot counts once")
	var mover: MovingHazard
	for node in host.main.level_builder.level_root.get_children():
		if node is MovingHazard:
			mover = node
	host.main._show_main_menu()
	await physics_frame
	var paused := mover.elapsed
	var stopped_position: Vector2 = host.main.ball.global_position
	for tick in 12:
		await physics_frame
	_check(is_equal_approx(mover.elapsed, paused), "menu freezes hazard phase")
	_check(host.main.ball.global_position.is_equal_approx(stopped_position), "menu freezes the ball")
	host.main._hide_main_menu()
	for tick in 3:
		await physics_frame
	_check(mover.elapsed > paused, "resume advances same phase")
	_key(KEY_R)
	for tick in 5:
		await physics_frame
	_check(host.main.run_state.strokes == 1 and host.main.ball.can_shoot(), "ordinary reset preserves stroke and restores input")
	_key(KEY_F9)
	await _loaded()
	_check(host.main.run_state.strokes == 0 and host.main.run_state.total_strokes == 0, "fresh practice attempt clears ledger")
	_key(KEY_H)
	await process_frame
	_check(host.details, "brief can be opened")
	await _capture("practice_brief")
	_key(KEY_H)
	await process_frame
	_check(not host.details, "brief can be hidden")
	await _capture("practice_compact")
	for size in [Vector2i(1280, 720), Vector2i(1600, 900)]:
		root.size = size
		for tick in 5:
			await process_frame
		await _capture("practice_%dx%d" % [size.x, size.y])
	var file := FileAccess.open(OUTPUT + "/practice_smoke.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "native_inputs": ["F6", "F7", "F8", "F9", "H", "Space", "R", "Tab"], "pause_resume": true}, "\t"))
	host.queue_free()
	await process_frame
	print("HAZARD_PRACTICE_SMOKE failures=", failures)
	quit(0 if failures.is_empty() else 1)

func _loaded() -> void:
	for tick in 3:
		await physics_frame
	var budget := 120
	while host.busy and budget > 0:
		await physics_frame
		budget -= 1
	_check(budget > 0, "practice load bounded")
	for tick in 5:
		await process_frame

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + "/gallery/" + label + ".png")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
