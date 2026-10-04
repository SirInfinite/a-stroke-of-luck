extends "res://tests/visual_overhaul_review.gd"
## Actual production UI/physics, arranged for reproducible review. Never saves
## user settings, submits clipboard writes, or claims these fixtures are playtests.
var review_size := Vector2i(1280, 720)


func _ready() -> void:
	super._ready()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--review-size="):
			var parts := argument.trim_prefix("--review-size=").split("x")
			review_size = Vector2i(int(parts[0]), int(parts[1]))
	main.game_settings.reduced_motion = false
	main.game_settings.ui_appearance = &"dark"
	main._apply_player_settings()
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = review_size
	output_directory = output_directory.get_base_dir().path_join("%dx%d" % [review_size.x, review_size.y])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory))


func _run_review() -> void:
	_move_mouse(Vector2(80, 90))
	await _capture("00_title_parallax_left", main.main_menu_overlay)
	var left: Vector2 = main.title_attract_mode.parallax
	_move_mouse(Vector2(1800, 950))
	await _capture("00_title_parallax_right", main.main_menu_overlay)
	_check(main.title_attract_mode.parallax.distance_to(left) > 20.0, "Cursor actually moves the title parallax: %s -> %s; reduced=%s; mouse=%s; size=%s; elapsed=%s" % [left, main.title_attract_mode.parallax, main.title_attract_mode.reduced_motion, main.title_attract_mode.get_local_mouse_position(), main.title_attract_mode.size, main.title_attract_mode.elapsed])
	main.title_attract_mode.set_reduced_motion(true)
	_check(main.title_attract_mode.parallax == Vector2.ZERO, "Reduced Motion still suppresses parallax")
	main.title_attract_mode.set_reduced_motion(false)
	_move_mouse(Vector2(1850, 50))
	await super._run_review()
	main._show_main_menu()
	main._on_menu_settings_pressed()
	for mode in [&"dark", &"light"]:
		main.game_settings.ui_appearance = mode
		main._apply_player_settings()
		main.settings_screen.vsync_toggle.set_pressed_no_signal(true)
		await _capture("20_settings_%s_on" % mode, main.settings_screen)
		main.settings_screen.vsync_toggle.set_pressed_no_signal(false)
		await _capture("21_settings_%s_off" % mode, main.settings_screen)
		_move_mouse(main.settings_screen.vsync_toggle.get_global_rect().get_center())
		await _capture("22_settings_%s_help" % mode, main.settings_screen)
		_check(not main.settings_screen.help_label.text.is_empty(), "Hovered setting has help: mouse=%s control=%s" % [main.settings_screen.get_global_mouse_position(), main.settings_screen.vsync_toggle.get_global_rect()])
		_move_mouse(Vector2(1850, 50))
	main.settings_screen.close()
	main._start_normal_run(SAFE_SEED)
	main._load_level(0)
	for mode in [&"dark", &"light"]:
		main.game_settings.ui_appearance = mode
		main._apply_player_settings()
		var seed: SeedTicket = main.release_hud.seed_ticket
		seed.set_hovered(false)
		await _capture("23_seed_%s_idle" % mode, main.release_hud)
		seed.set_hovered(true)
		await _capture("24_seed_%s_hover" % mode, main.release_hud)
		seed.show_copied() # Exercise feedback without touching the user's clipboard.
		await _capture("25_seed_%s_copied" % mode, main.release_hud)
	main.game_settings.ui_appearance = &"dark"
	main._apply_player_settings()
	main._start_tutorial()
	await _capture("26_tutorial_hidden", main.release_hud)
	main.ball.set_external_control(true)
	main.ball.set_external_aim(Vector2.RIGHT, 0.2)
	await get_tree().create_timer(0.2).timeout
	main.ball.set_external_aim(Vector2.RIGHT, 0.65)
	await get_tree().create_timer(0.2).timeout
	main.ball.shoot_normalized(Vector2.RIGHT, 0.55)
	await _capture("27_tutorial_score_revealed", main.release_hud)
	main.ball.set_external_control(false)
	main._load_level(1)
	await _capture("28_tutorial_sand_band", main.tutorial_manager.hint_panel)
	main.ball.shoot_normalized(Vector2.RIGHT, 0.7)
	for frame in range(180):
		await get_tree().physics_frame
		if main.tutorial_manager.completed_events.has(&"entered_sand"):
			break
	_check(main.tutorial_manager.completed_events.has(&"entered_sand"), "Actual shot enters the sand band")
	await _capture("29_tutorial_sand_contact", main.tutorial_manager.hint_panel)
	main._load_level(2)
	await _capture("30_tutorial_water_band", main.tutorial_manager.hint_panel)
	main.ball.shoot_normalized(Vector2.RIGHT, 0.8)
	for frame in range(240):
		await get_tree().physics_frame
		if main.tutorial_manager.completed_events.has(&"entered_water") and not main.hazard_resetting:
			break
	_check(main.run_state.levels[2].hazards[0].size == Vector2(100, 200), "Real water reset opens recovery lanes")
	await _capture("31_tutorial_water_opened", main.tutorial_manager.hint_panel)
	main._load_level(4)
	await _capture("32_tutorial_coins_revealed", main.release_hud)
	main._show_shop(5)
	await _capture("33_tutorial_cards_revealed", main.shop_manager.shop_overlay)
	main._return_from_tutorial()
	await _capture("34_tutorial_menu_return", main.main_menu_overlay)
	main._start_normal_run(SAFE_SEED)
	main._load_level(0)
	main.run_state.phase = RunState.Phase.HOLE_RESULTS
	main.run_state.tokens = 40
	main.run_state.difficulty_profile = Difficulties.get_profile(&"easy")
	main._show_shop(3)
	for index in range(4):
		main.shop_manager.shop_card_buttons[index].configure_card(CardRarityProfile.create(Cards.get_cards()[index], CardRarityProfile.IDS[index]), true, false, 1)
	await _capture("35_rarity_stock", main.shop_manager.shop_overlay)
	_check_cards()
	main._start_normal_run(424242, &"woods")
	main._load_level(4)
	main._complete_current_hole(false, false)
	var samples := 0
	for frame in range(260):
		await get_tree().physics_frame
		var controller: VsMatchController = main.vs_controller
		if not controller.decision.is_empty() and controller.think_remaining < 0.5 and samples == 0:
			samples += 1
			await RenderingServer.frame_post_draw
			var capture_path := output_directory.path_join("36_ai_preparation.png")
			_check(get_viewport().get_texture().get_image().save_png(capture_path) == OK, "AI preparation capture saved")
			captures.append(capture_path)
			capture_count += 1
			break
	_check(samples == 1, "AI visibly prepares its selected shot")
	main.vs_controller.return_to_menu()
	var report := {"captures": captures, "capture_count": capture_count, "layout_checks": layout_checks, "layout_failures": layout_failures, "findings": findings}
	var file := FileAccess.open(output_directory.path_join("polish_report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("[POLISH REVIEW] %d captures / %d checks / %d failures" % [capture_count, layout_checks, layout_failures])
	get_tree().quit(0 if layout_failures == 0 else 1)


func _move_mouse(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	get_viewport().push_input(event, true)
