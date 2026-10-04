extends GutTest

const MAIN := preload("res://scenes/main.tscn")
const BALL := preload("res://scenes/golf_ball.tscn")
const Camera := preload("res://scripts/course_camera.gd")


func after_each() -> void:
	Engine.time_scale = 1.0
	var saved := GameSettings.new()
	saved.load_from()
	saved.apply_runtime(false)


func test_default_and_new_hole_start_at_ball_with_authoritative_zoom() -> void:
	var setup := _camera_setup()
	var camera: CourseCamera = setup.camera
	setup.ball.position = Vector2(410, -225)
	camera.reset_for_hole(Rect2(-900, -400, 1800, 800))
	assert_eq(camera.state, Camera.State.BALL_FOLLOW)
	assert_eq(camera.global_position, setup.ball.global_position)
	assert_eq(camera.zoom, Vector2.ONE * camera.gameplay_zoom)
	assert_false(camera.position_smoothing_enabled, "No second smoothing owner.")


func test_fast_follow_bounds_lag_without_overshoot_or_speed_zoom() -> void:
	var setup := _camera_setup()
	var camera: CourseCamera = setup.camera
	for fps in [30, 60, 144]:
		for speed in [80.0, 1600.0, 4000.0, GameplayHazard.MAX_BOUNCE_SPEED]:
			setup.ball.position = Vector2.ZERO
			camera.reset_for_hole(Rect2(-5000, -5000, 10000, 10000))
			for tick in range(60):
				var direction := Vector2.RIGHT if tick < 30 else Vector2.LEFT
				setup.ball.position += direction * speed / float(fps)
				camera._process(1.0 / float(fps))
				assert_lte(camera.position.distance_to(setup.ball.position) * camera.gameplay_zoom, camera.max_follow_lag_pixels + 0.01)
				assert_eq(camera.zoom, Vector2.ONE * camera.gameplay_zoom)
			for tick in range(60):
				camera._process(1.0 / float(fps))
			assert_lt(camera.position.distance_to(setup.ball.position), 0.1)


func test_overview_uses_occupied_cells_walls_and_all_layers_without_scenery() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	var builder := LevelBuilder.new()
	holder.add_child(builder)
	var level := {"map": ["       ", "  ###  ", "  ###  ", "       "], "start_cell": Vector2i(2, 1), "hole_cell": Vector2i(4, 2), "par": 3, "hazards": [], "obstacles": []}
	assert_not_null(builder.build_level(level, holder))
	var expected := Rect2(-150, -100, 300, 200).grow(LevelBuilder.WALL_THICKNESS)
	assert_eq(builder.get_playable_bounds(), expected, "Empty map allocation and distant decorations do not enlarge the view.")
	assert_gt(builder.level_root.get_node("BiomeBackground").polygon[1].distance_to(Vector2.ZERO), expected.size.length())
	# Reuse the builder's actual layer lookup; bounds never filter active elevation.
	builder.elevation_lookup[Vector2i(4, 2)] = [-1, 0, 1]
	for elevation in [-1, 0, 1]:
		builder.set_active_elevation(elevation)
		assert_eq(builder.get_playable_bounds(), expected)


func test_bounds_include_full_mover_travel_and_flag_not_just_its_origin() -> void:
	var builder := LevelBuilder.new()
	add_child_autofree(builder)
	# Isolated framing fixture; no gameplay construction or validation changes.
	builder.active_level = {"map": ["#"], "start": Vector2.ZERO, "hole": Vector2(220, -80), "hazards": [], "obstacles": [], "moving_hazards": [
		{"type": "pendulum", "pos": Vector2(500, 100), "size": Vector2(50, 50), "travel_radius": 180.0},
		{"type": "rotating_fire_rod", "pos": Vector2(-400, 0), "size": Vector2(260, 32)},
		{"type": "falling_ice", "pos": Vector2(0, -300), "size": Vector2(100, 100), "drop_distance": 120.0},
	]}
	builder.elevation_lookup = {Vector2i.ZERO: [0]}
	var bounds := builder.get_playable_bounds()
	for point in [Vector2(220, -166), Vector2(500, 305), Vector2(-530, 0), Vector2(0, -470)]:
		assert_true(bounds.grow(0.01).has_point(point), "Framing includes flag and swept hazard extent: %s" % point)


func test_fit_contains_padded_bounds_across_shapes_and_resolutions() -> void:
	for resolution in [Vector2(1280,720), Vector2(1600,900), Vector2(1920,1080), Vector2(2560,1440), Vector2(3440,1440)]:
		var safe := Rect2(Vector2(80, 180), resolution - Vector2(120, 300))
		for extent in [Vector2(300,200), Vector2(4800,500), Vector2(700,6000), Vector2(8000,1500), Vector2(3800,3400), Vector2(1800,1900), Vector2(6200,4300)]:
			var bounds := Rect2(Vector2(-370, 120), extent).grow(64)
			var frame := Camera.fit_bounds(bounds, resolution, safe, 1.25)
			var projected := Rect2((bounds.position - Vector2(frame.center)) * float(frame.zoom) + resolution * 0.5, bounds.size * float(frame.zoom))
			assert_true(safe.grow(0.01).encloses(projected), "Entire padded rectangle must fit inside HUD margins.")
			assert_gt(float(frame.zoom), 0.0)
			assert_lte(float(frame.zoom), 1.25)
			if float(frame.zoom) < 1.25:
				assert_true(is_equal_approx(projected.size.x, safe.size.x) or is_equal_approx(projected.size.y, safe.size.y), "Fit uses the available space; no arbitrary extra zoom-out.")


func test_transition_is_eased_and_return_tracks_current_ball_during_blend() -> void:
	var setup := _camera_setup()
	var camera: CourseCamera = setup.camera
	camera.reset_for_hole(Rect2(-2000, -1600, 5000, 3800))
	var start := camera.position
	camera.toggle_overview()
	assert_eq(camera.position, start, "Toggling must not snap the view.")
	camera._process(0.1)
	assert_lt(camera.zoom.x, camera.gameplay_zoom)
	assert_gt(camera.zoom.x, float(camera.overview_frame().zoom))
	camera._process(0.3)
	assert_eq(camera.state, Camera.State.COURSE_OVERVIEW)
	assert_almost_eq(camera.zoom.x, float(camera.overview_frame().zoom), 0.0001)
	camera.toggle_overview()
	for tick in range(30):
		setup.ball.position += Vector2(12, -3)
		camera._process(1.0 / 60.0)
	assert_eq(camera.state, Camera.State.BALL_FOLLOW)
	assert_lt(camera.position.distance_to(setup.ball.position), camera.max_follow_lag_pixels / camera.gameplay_zoom + 0.01)
	assert_eq(camera.zoom, Vector2.ONE * camera.gameplay_zoom)
	assert_gt(camera.position.x, 300.0, "Return follows the current ball, not its entry or exit snapshot.")


func test_rapid_toggle_resize_and_watch_speed_keep_transitions_bounded() -> void:
	var setup := _camera_setup()
	var camera: CourseCamera = setup.camera
	camera.reset_for_hole(Rect2(-2000, -1600, 5000, 3800))
	for tick in range(11):
		var previous := camera.position
		camera.toggle_overview()
		assert_eq(camera.position, previous)
		camera._process(0.03)
	camera.set_usable_viewport(Rect2(90, 260, 1400, 650))
	Engine.time_scale = 4.0
	camera._process(0.4 * Engine.time_scale)
	assert_almost_eq(camera.zoom.x, float(camera.overview_frame().zoom), 0.0001)
	assert_true(camera.position.is_finite())
	camera.reset_for_hole(Rect2(-100, -100, 200, 200))
	assert_eq(camera.state, Camera.State.BALL_FOLLOW)
	assert_eq(camera.zoom, Vector2.ONE * camera.gameplay_zoom)


func test_tab_and_hud_share_toggle_and_key_echo_is_ignored() -> void:
	var main = _playing_main()
	assert_true(InputMap.has_action("toggle_course_overview"))
	assert_true(ProjectSettings.has_setting("input/toggle_course_overview"))
	await _key(KEY_TAB, true)
	assert_true(main.camera.is_overview_active())
	assert_true(main.release_hud.overview_button.button_pressed)
	assert_eq(main.release_hud.overview_button.focus_mode, Control.FOCUS_NONE)
	await _key(KEY_TAB, true, true)
	assert_true(main.camera.is_overview_active())
	await _key(KEY_TAB, false)
	main.release_hud.overview_button.pressed.emit()
	assert_false(main.camera.is_overview_active())
	assert_false(main.release_hud.overview_button.button_pressed)
	assert_true(main.release_hud.overview_button.tooltip_text.contains("Tab"))


func test_overview_cancels_mouse_and_keyboard_aim_without_firing() -> void:
	var main = _playing_main()
	main.ball.selected = true
	main.ball.keyboard_active = true
	main.ball.keyboard_power = 0.9
	main._toggle_course_overview()
	assert_false(main.ball.selected)
	assert_false(main.ball.keyboard_active)
	assert_false(main.ball.can_shoot())
	assert_eq(main.ball.get_aim_power(), 0.0)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	Input.parse_input_event(release)
	await _key(KEY_SPACE, true)
	await _key(KEY_SPACE, false)
	main.ball.shoot(Vector2.RIGHT * 1600)
	assert_eq(main.run_state.strokes, 0)
	assert_false(main.ball.shot_in_progress)
	main._toggle_course_overview()
	assert_true(main.ball.can_shoot())
	assert_false(main.ball.selected)
	assert_false(main.ball.keyboard_active)


func test_overview_keeps_live_shot_and_timer_running() -> void:
	var main = _playing_main()
	await wait_physics_frames(3)
	main.ball.shoot(Vector2.RIGHT * 400)
	main._toggle_course_overview()
	var before: Vector2 = main.ball.position
	var before_time: float = main.run_state.level_elapsed
	await wait_physics_frames(8)
	assert_gt(main.ball.position.distance_to(before), 1.0)
	assert_gt(main.run_state.level_elapsed, before_time)
	assert_false(main.ball.simulation_paused)
	assert_true(main.camera.is_overview_active())
	assert_eq(main.run_state.strokes, 1)
	await wait_seconds(1.0)
	assert_true(main.camera.is_overview_active(), "Stopping never auto-exits inspection.")


func test_mouse_selection_and_tab_cancel_through_viewport_input() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.world_2d = World2D.new()
	add_child_autofree(viewport)
	var main = MAIN.instantiate()
	viewport.add_child(main)
	main.game_settings.reset_to_defaults()
	main.game_settings.apply_runtime(false)
	main._start_normal_run(48159309)
	main._load_level(0)
	await wait_process_frames(3)
	var at: Vector2 = viewport.get_canvas_transform() * main.ball.global_position
	var motion := InputEventMouseMotion.new()
	motion.position = at
	viewport.push_input(motion, true)
	var click := InputEventMouseButton.new()
	click.position = at
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	viewport.push_input(click, true)
	assert_true(main.ball.selected, "Pointer input selects the real GolfBall.")
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	viewport.push_input(tab, true)
	assert_true(main.camera.is_overview_active())
	assert_false(main.ball.selected)
	click.pressed = false
	viewport.push_input(click, true)
	assert_eq(main.run_state.strokes, 0)
	assert_false(main.ball.shot_in_progress)
	assert_eq(main.ball.get_aim_power(), 0.0)


func test_overview_survives_pause_and_oob_return_without_reenabling_shots() -> void:
	var main = _playing_main()
	main._toggle_course_overview()
	main._show_main_menu()
	await _key(KEY_TAB, true)
	await _key(KEY_TAB, false)
	assert_true(main.camera.is_overview_active(), "Menus keep Tab focus navigation.")
	assert_true(main.ball.simulation_paused)
	main._hide_main_menu()
	assert_false(main.ball.simulation_paused)
	assert_false(main.ball.input_enabled)
	main.out_of_bounds_active = true
	main._cancel_out_of_bounds_recovery()
	assert_false(main.ball.input_enabled, "OOB cleanup must respect inspection's input gate.")
	main._reset_current_level()
	assert_false(main.camera.is_overview_active())
	assert_eq(main.camera.position, main.ball.position)
	assert_true(main.ball.input_enabled)


func test_results_next_hole_and_new_run_clear_overview_and_cup_zoom() -> void:
	var main = _playing_main()
	main._toggle_course_overview()
	await wait_seconds(0.4)
	main._complete_current_hole(false, true)
	assert_false(main.camera.is_overview_active())
	assert_eq(main.camera.zoom, Vector2.ONE * main.camera.gameplay_zoom)
	main._advance_after_hole_results()
	assert_false(main.camera.is_overview_active())
	assert_eq(main.camera.position, main.ball.position)
	main._toggle_course_overview()
	main._start_normal_run(98765)
	assert_false(main.camera.is_overview_active())
	assert_eq(main.camera.zoom, Vector2.ONE * main.camera.gameplay_zoom)
	assert_eq(main.camera.playable_bounds, Rect2())


func test_overview_can_exit_during_hazard_recovery_without_unlocking_shots() -> void:
	var main = _playing_main()
	main._toggle_course_overview()
	main._on_reset_hazard_body_entered(main.ball, main.ball.position, &"water")
	assert_true(main.hazard_resetting)
	await _key(KEY_TAB, true)
	await _key(KEY_TAB, false)
	assert_false(main.camera.is_overview_active(), "Hazard animation must not swallow the return toggle.")
	assert_false(main.ball.can_shoot(), "Returning the camera does not bypass hazard recovery.")
	await wait_seconds(1.0)
	assert_false(main.hazard_resetting)
	assert_false(main.camera.is_overview_active())
	assert_eq(main.camera.zoom, Vector2.ONE * main.camera.gameplay_zoom)
	assert_lt(main.camera.position.distance_to(main.ball.position), 0.1)
	assert_true(main.ball.can_shoot())


func test_shake_is_preserved_in_ball_view_suppressed_in_overview_and_cleans_up() -> void:
	var main = _playing_main()
	main.feedback_director.apply_player_settings(1.0, 1.0, false)
	main.feedback_director.play_shot_feedback(main.ball.position, Vector2.RIGHT, 1.0)
	assert_gt(main.camera.offset.length(), 0.0)
	main._toggle_course_overview()
	assert_eq(main.camera.offset, Vector2.ZERO)
	main.feedback_director.play_wall_impact(1600, main.ball.position)
	main.feedback_director.play_hazard_feedback(&"bounce_pad", 1.0, main.ball.position)
	await wait_seconds(0.4)
	assert_eq(main.camera.offset, Vector2.ZERO)
	assert_almost_eq(main.camera.zoom.x, float(main.camera.overview_frame().zoom), 0.0001)
	main._toggle_course_overview()
	main.feedback_director.play_shot_feedback(main.ball.position, Vector2.RIGHT, 1.0)
	assert_gt(main.camera.offset.length(), 0.0)
	await wait_seconds(0.4)
	assert_eq(main.camera.offset, Vector2.ZERO)
	assert_eq(main.camera.zoom, Vector2.ONE * main.camera.gameplay_zoom)


func test_binding_persists_resets_and_migrates_old_tab_without_conflicts() -> void:
	var settings := GameSettings.new()
	settings.overview_keycode = KEY_M
	var path := "user://camera_test_settings.cfg"
	assert_eq(settings.save_to(path), OK)
	var loaded := GameSettings.new()
	assert_eq(loaded.load_from(path), OK)
	assert_eq(loaded.overview_keycode, KEY_M)
	loaded.apply_runtime(false)
	assert_eq(InputMap.action_get_events("toggle_course_overview")[0].keycode, KEY_M)
	loaded.reset_to_defaults()
	assert_eq(loaded.overview_keycode, KEY_TAB)
	loaded.shoot_keycode = KEY_TAB
	loaded.apply_runtime(false)
	assert_eq(loaded.shoot_keycode, KEY_TAB)
	assert_ne(loaded.overview_keycode, KEY_TAB)
	for key in [KEY_ENTER, KEY_SPACE, KEY_LEFT, KEY_F2, KEY_R]:
		assert_false(settings.binding_conflict(&"toggle_course_overview", key).is_empty())
	assert_false(settings.binding_conflict(&"shoot", KEY_M).is_empty())
	assert_eq(settings.binding_conflict(&"toggle_course_overview", KEY_O), "")
	DirAccess.remove_absolute(path)


func test_reduced_motion_keeps_functional_framing_and_no_elevation_bias() -> void:
	var setup := _camera_setup()
	var camera: CourseCamera = setup.camera
	camera.reduced_motion = true
	camera.reset_for_hole(Rect2(-2200, -900, 4400, 1800))
	setup.ball.position = Vector2(340, 150)
	camera._process(1.0 / 60.0)
	assert_eq(camera.position, setup.ball.position)
	camera.toggle_overview()
	camera._process(0.16)
	assert_almost_eq(camera.zoom.x, float(camera.overview_frame().zoom), 0.0001)
	camera.toggle_overview()
	camera._process(0.16)
	assert_eq(camera.position, setup.ball.position)


func test_real_maximum_legal_shot_and_wall_rebounds_stay_near_center() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	var builder := LevelBuilder.new()
	holder.add_child(builder)
	builder.build_level({"map": ["#####", "#####", "#####", "#####", "#####"], "start_cell": Vector2i(1,1), "hole_cell": Vector2i(4,4), "par": 4, "hazards": [], "obstacles": []}, holder)
	var ball = BALL.instantiate()
	holder.add_child(ball)
	var camera := Camera.new()
	holder.add_child(camera)
	camera.setup(ball)
	ball.apply_card_modifiers(2.5, 1.0, 0)
	ball.reset_to(Vector2.ZERO, 0, false)
	await wait_physics_frames(3)
	watch_signals(ball)
	assert_true(ball.shoot_normalized(Vector2.ONE.normalized(), 1.0))
	for tick in range(90):
		# Timers run after node processing; GUT's frame waiter otherwise samples
		# before the camera's deliberately late presentation update.
		await get_tree().create_timer(0.0).timeout
		assert_lte(camera.position.distance_to(ball.position) * camera.gameplay_zoom, camera.max_follow_lag_pixels + 0.1)
		assert_eq(camera.zoom, Vector2.ONE * camera.gameplay_zoom)
	assert_signal_emitted(ball, "wall_impact")


func test_overview_does_not_stall_external_ai_shot_submission() -> void:
	var main = _playing_main(&"beginner")
	main.vs_controller.match_state.turn = VsMatchState.Turn.OPPONENT
	main.ball.set_external_control(true)
	main._toggle_course_overview()
	assert_true(main.camera.is_overview_active())
	assert_true(main.ball.input_enabled)
	await wait_physics_frames(3)
	assert_true(main.ball.shoot_normalized(Vector2.RIGHT, 0.3))
	assert_true(main.ball.shot_in_progress)
	assert_false(main.ball.simulation_paused)


func _camera_setup() -> Dictionary:
	var holder := Node2D.new()
	add_child_autofree(holder)
	var target := Node2D.new()
	holder.add_child(target)
	var camera := Camera.new()
	holder.add_child(camera)
	camera.setup(target)
	camera.set_process(false)
	return {"camera": camera, "ball": target}


func _playing_main(opponent: StringName = &""):
	var main = MAIN.instantiate()
	add_child_autofree(main)
	main.game_settings.reset_to_defaults()
	main.game_settings.apply_runtime(false)
	main._apply_player_settings()
	main._start_normal_run(48159309, opponent)
	main._load_level(0)
	return main


func _key(code: Key, pressed: bool, echo := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
	await wait_process_frames(1)
