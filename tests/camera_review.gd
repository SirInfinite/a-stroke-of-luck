extends SceneTree
## Development-only rendered camera evidence using the real Main and builder.
## godot4 --path . --script tests/camera_review.gd [-- --interactive]

const MAIN := preload("res://scenes/main.tscn")
const OUTPUT := "user://camera-review-20260908"
var main
var failures: Array[String] = []
var captures: Array[Dictionary] = []
var checks := 0
var max_lag := 0.0
var pad_events := 0
var examples := {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	main = MAIN.instantiate()
	root.add_child(main)
	main.game_settings.reset_to_defaults()
	main.game_settings.apply_runtime(false)
	main._apply_player_settings()
	main._start_normal_run(48159309)
	if OS.get_cmdline_user_args().has("--input-only"):
		main._load_level(0)
		await _settle(0.2)
		await _exercise_input()
		await _capture("input_diagnostic")
		quit(0 if failures.is_empty() else 1)
		return
	_select_examples()
	main.level_builder.bounce_pad_triggered.connect(func(_strength, _kind, _position): pad_events += 1)
	for resolution in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(3440,1440)]:
		root.size = resolution
		await _settle(0.08)
		for kind in ["small", "wide", "tall", "long", "branches", "elevation", "lower", "late"]:
			_show_level(examples[kind])
			await _settle(0.08)
			_check(main.camera.zoom == Vector2.ONE * main.camera.gameplay_zoom, "Fixed normal zoom " + kind)
			_check(main.camera.position.distance_to(main.ball.position) < 0.1, "Tee centered " + kind)
			if kind == "small":
				await _capture("%dx%d_ball" % [resolution.x, resolution.y])
			main._toggle_course_overview()
			await _settle(0.45)
			_check_overview(kind)
			await _capture("%dx%d_%s_overview" % [resolution.x, resolution.y, kind])
		print("[CAMERA REVIEW] framing complete at ", resolution, " logical ", main.get_viewport_rect().size)
	root.size = Vector2i(1920,1080)
	_show_level(examples.small)
	await _settle(0.1)
	await _exercise_input()
	for power in [0.15, 1.0]:
		main._reset_current_level()
		await _settle(0.06)
		var cup: Vector2 = main.level_builder.level_point(main.level_builder.active_level, "hole", "hole_cell")
		_check(main.ball.shoot_normalized((cup - main.ball.position).normalized(), power), "Rendered shot accepted")
		await _settle(0.04)
		await _sample_follow(6)
		await _capture("shot_%d" % roundi(power * 100))
		main._toggle_course_overview()
		await _settle(0.18)
		await _capture("moving_transition_%d" % roundi(power * 100))
		await _settle(0.24)
		_check_overview("moving shot")
		main._toggle_course_overview()
		_check(not main.camera.is_overview_active(), "Return toggle works even during hazard recovery")
		await _settle(0.42)
		await _sample_follow(24)
		_check(main.camera.zoom == Vector2.ONE * main.camera.gameplay_zoom, "Return restores fixed gameplay zoom")
		await _capture("return_current_ball_%d" % roundi(power * 100))
	_show_level(examples.bounce)
	await _settle(0.1)
	for hazard: Dictionary in main.level_builder.active_level.hazards:
		if String(hazard.type) != "bounce_pad":
			continue
		main.ball.reset_to(Vector2(hazard.pos) - Vector2(90, 0), int(hazard.get("elevation", 0)), false)
		main.camera.return_to_ball(true)
		await _settle(0.06)
		main.ball.shoot_normalized(Vector2.RIGHT, 1.0)
		await _sample_follow(5)
		await _capture("bounce_pad_launch")
		await _sample_follow(36)
		break
	_check(pad_events > 0, "Real bounce-pad signal observed")
	for layer in [-1, 1]:
		_show_level(examples.lower if layer == -1 else examples.elevation)
		await _settle(0.1)
		var found := false
		for entry: Dictionary in main.level_builder.active_level.elevation_cells:
			if not Array(entry.levels).has(layer):
				continue
			var at: Vector2 = main.level_builder.level_point(main.level_builder.active_level.merged({"probe_cell": entry.cell}), "unused", "probe_cell")
			main.ball.reset_to(at, layer, false)
			main.camera.return_to_ball(true)
			await _settle(0.06)
			await _capture("elevation_%d_ball" % layer)
			_check(main.camera.position.distance_to(main.ball.position) < 1.0, "No elevation camera bias")
			found = true
			break
		_check(found, "Rendered elevation %d" % layer)
	_show_level(examples.small)
	await _settle(0.1)
	main._toggle_course_overview()
	await _settle(0.42)
	main._complete_current_hole(true, false)
	await _settle(0.6)
	_check(not main.camera.is_overview_active(), "Results clear overview")
	await _capture("hole_results")
	main._advance_after_hole_results()
	await _settle(0.1)
	_check(main.camera.position.distance_to(main.ball.position) < 0.1, "Next tee centered")
	await _capture("next_hole_ball")
	main._show_main_menu()
	main._on_menu_settings_pressed()
	main.settings_screen.tabs.current_tab = 2
	await _settle(0.2)
	await _capture("controls_tab")
	_check(main.settings_screen.overview_binding_button.text == "Tab", "Controls show current overview binding")
	main.settings_screen.close()
	main._hide_main_menu()
	main.game_settings.ui_appearance = &"light"
	main._apply_player_settings()
	main._toggle_course_overview()
	await _settle(0.42)
	await _capture("light_overview")
	main.game_settings.ui_appearance = &"dark"
	main._apply_player_settings()
	main._start_tutorial()
	await _settle(0.1)
	main._toggle_course_overview()
	await _settle(0.45)
	_check_overview("tutorial coach clearance")
	await _capture("tutorial_overview")
	var report := {"checks": checks, "failures": failures, "captures": captures, "maximum_follow_lag_pixels": max_lag, "bounce_pad_events": pad_events, "gameplay_zoom": main.camera.gameplay_zoom, "transition_seconds": main.camera.transition_duration}
	FileAccess.open(OUTPUT.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("[CAMERA REVIEW] ", checks, " checks; ", captures.size(), " captures; ", failures.size(), " failures; maximum rendered lag ", max_lag)
	main._start_normal_run(48159309)
	_show_level(examples.small)
	if not OS.get_cmdline_user_args().has("--interactive"):
		quit(0 if failures.is_empty() else 1)


func _select_examples() -> void:
	var best := {"small": INF, "wide": -INF, "tall": -INF, "long": -INF, "branches": -INF, "elevation": -INF, "lower": -INF, "late": -INF, "bounce": -INF}
	var profiles := BiomeDatabase.get_profiles()
	var options := DifficultyDatabase.get_profile(&"hard").generation_options()
	for seed_value in [48159309, 8675309, 7919, 424242, 314159, 161803]:
		for index in range(18):
			var level := HoleGenerator.generate_hole(profiles[index / 3], seed_value, index / 3, index % 3, HoleGenerator.MAX_GENERATION_ATTEMPTS, options)
			var width := 0
			for row in level.map:
				width = maxi(width, String(row).length())
			var extent := Vector2(width, level.map.size())
			var area := extent.x * extent.y
			var branch_cells := 0
			for branch: Dictionary in level.get("branches", []):
				branch_cells += Array(branch.cells).size()
			var has_lower := false
			var has_upper := false
			var overpasses := 0
			for entry: Dictionary in level.get("elevation_cells", []):
				has_lower = has_lower or Array(entry.levels).has(-1)
				has_upper = has_upper or Array(entry.levels).has(1)
			for structure: Dictionary in level.get("elevation_structures", []):
				overpasses += 1 if String(structure.type) == "overpass" else 0
			var has_pad := false
			for hazard: Dictionary in level.hazards:
				has_pad = has_pad or String(hazard.type) == "bounce_pad"
			var scores := {"small": area, "wide": extent.x / extent.y, "tall": extent.y / extent.x, "long": maxf(extent.x, extent.y), "branches": branch_cells, "elevation": 1000 * overpasses + area if has_upper else -INF, "lower": area if has_lower else -INF, "late": area + level.hazards.size() * 10 if index >= 15 else -INF, "bounce": area if has_pad else -INF}
			for key in scores:
				if (key == "small" and scores[key] < best[key]) or (key != "small" and scores[key] > best[key]):
					best[key] = scores[key]
					examples[key] = level
	for key in best:
		_check(examples.has(key), "Generated example exists: " + key)
	print("[CAMERA REVIEW] representative shapes selected from 108 generated Hard holes")


func _show_level(level: Dictionary) -> void:
	var index := int(level.overall_hole_number) - 1
	main.run_state.run_seed = int(level.run_seed)
	main.run_state.normal_levels[index] = level.duplicate(true)
	main.run_state.levels[index] = level.duplicate(true)
	main._load_level(index)


func _exercise_input() -> void:
	var button: Button = main.release_hud.overview_button
	await _mouse_button(button.get_global_rect().get_center(), true)
	await _mouse_button(button.get_global_rect().get_center(), false)
	_check(main.camera.is_overview_active(), "Actual HUD mouse click enters overview")
	await _tap_key(KEY_TAB)
	await _settle(0.4)
	_check(not main.camera.is_overview_active(), "Actual Tab returns from HUD overview")
	var ball_screen: Vector2 = root.get_canvas_transform() * main.ball.global_position
	# Root Window polls the real OS cursor. The SubViewport GUT regression
	# exercises selection via injected pointer input without warping that cursor.
	main.ball.selected = true
	await _tap_key(KEY_TAB)
	await _mouse_button(ball_screen, false)
	await _tap_key(KEY_SPACE)
	_check(main.run_state.strokes == 0 and not main.ball.selected, "Tab cancels drag; release/confirm never fires")
	await _tap_key(KEY_TAB)
	await _settle(0.4)
	Input.action_press("ui_right")
	await _settle(0.08)
	Input.action_release("ui_right")
	_check(main.ball.keyboard_active, "Actual keyboard aiming starts")
	await _tap_key(KEY_TAB)
	_check(not main.ball.keyboard_active and main.ball.get_aim_power() == 0, "Overview cancels keyboard aim and power")
	await _tap_key(KEY_TAB)
	await _settle(0.4)
	main.game_settings.overview_keycode = KEY_M
	main.game_settings.apply_runtime(false)
	main._apply_player_settings()
	await _tap_key(KEY_M)
	_check(main.camera.is_overview_active(), "Rebound key enters overview")
	_check(main.release_hud.overview_button.tooltip_text.contains("M"), "HUD advertises rebound key")
	await _tap_key(KEY_M)
	main.game_settings.overview_keycode = KEY_TAB
	main.game_settings.apply_runtime(false)
	main._apply_player_settings()
	await _settle(0.4)


func _mouse_button(at: Vector2, pressed: bool) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion, true)
	await _settle(0.02)
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	root.push_input(event, true)
	await _settle(0.04)


func _tap_key(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = pressed
		Input.parse_input_event(event)
		await _settle(0.02)


func _check_overview(label: String) -> void:
	var button: Button = main.release_hud.overview_button
	var text_width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
	_check(text_width + button.get_theme_stylebox("normal").get_minimum_size().x <= button.size.x, "Overview label fits both button states")
	var bounds: Rect2 = main.level_builder.get_playable_bounds()
	var screen_rect: Rect2 = root.get_canvas_transform() * bounds.grow(main.camera.overview_padding)
	_check(main.camera.is_overview_active(), label + " overview active")
	_check(main.camera.usable_viewport.grow(1).encloses(screen_rect), label + " padded course fits actual canvas transform")
	_check(not main.ball.input_enabled, label + " inspection blocks shots")
	# Independently inspect actual constructed collision shapes across all layers.
	for node in main.level_root.find_children("*", "CollisionShape2D", true, false):
		var shape = node.shape
		var extent := Vector2.ZERO
		if shape is RectangleShape2D:
			extent = shape.size
		elif shape is CircleShape2D:
			extent = Vector2.ONE * shape.radius * 2.0
		else:
			continue
		var world_rect: Rect2 = node.global_transform * Rect2(-extent * 0.5, extent)
		_check(bounds.grow(2).encloses(world_rect), label + " built collision footprint included")


func _sample_follow(frames: int) -> void:
	for frame in range(frames):
		await RenderingServer.frame_post_draw
		if main.camera.is_overview_active() or main.run_phase != RunState.Phase.HOLE_PLAY:
			continue
		var lag: float = main.camera.position.distance_to(main.ball.position) * main.camera.gameplay_zoom
		max_lag = maxf(max_lag, lag)
		_check(lag <= main.camera.max_follow_lag_pixels + 0.1, "Rendered follow lag stays bounded")
		_check(main.camera.zoom == Vector2.ONE * main.camera.gameplay_zoom, "Rendered moving zoom stays fixed")


func _settle(seconds: float) -> void:
	await create_timer(seconds).timeout
	await RenderingServer.frame_post_draw


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := OUTPUT.path_join(label + ".png")
	_check(root.get_texture().get_image().save_png(path) == OK, "Capture " + label)
	captures.append({"label": label, "path": path, "window": str(root.size), "logical": str(main.get_viewport_rect().size), "bounds": str(main.camera.playable_bounds), "zoom": main.camera.zoom.x, "seed": main.level_builder.active_level.get("run_seed", 0), "hole": main.run_state.overall_hole_number})


func _check(passed: bool, description: String) -> void:
	checks += 1
	if not passed:
		failures.append(description)
		push_error("[CAMERA REVIEW] " + description)
