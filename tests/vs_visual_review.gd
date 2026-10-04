extends SceneTree
## Rendered fixture review; not a claim of human playtesting.
var main
var output := "user://vs_ai_20260907/screens"
var window_size := Vector2i(1600, 900)
var presentation_failures: Array[String] = []


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--size="):
			var dimensions := argument.get_slice("=", 1).split("x")
			window_size = Vector2i(int(dimensions[0]), int(dimensions[1]))
		elif argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	_run.call_deferred()


func _run() -> void:
	root.size = window_size
	main = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._on_menu_play_pressed()
	await capture("mode_select")
	main.vs_controller._select_mode(true)
	await capture("opponent_select")
	main.ui_appearance.apply_mode(&"light")
	await capture("opponent_select_light")
	main.ui_appearance.apply_mode(&"dark")
	main.vs_controller._select_opponent(&"woods")
	await capture("vs_run_setup")
	main._start_normal_run(424242, &"woods")
	main._load_level(4)
	await capture("player_turn")
	main._complete_current_hole(false, false) # Presentation fixture, not a player result benchmark.
	for frame in 100:
		await physics_frame
		if not main.vs_controller.decision.is_empty() and main.vs_controller.think_remaining < 0.25:
			break
	await capture("ai_aim", 1)
	main.vs_controller.set_watch_speed(2)
	await capture("ai_turn_2x", 1)
	main.vs_controller.set_watch_speed(4)
	for frame in 1800:
		await physics_frame
		if main.vs_controller.match_state.turn == VsMatchState.Turn.RESULTS:
			break
	if main.vs_controller.match_state.turn != VsMatchState.Turn.RESULTS:
		push_error("Rendered AI turn did not resolve.")
		quit(1)
		return
	await capture("hole_comparison")
	var session: VsMatchState = main.vs_controller.match_state
	main.vs_controller.view.hide_page()
	main.run_state.level_index = 5
	main.run_state.levels[5] = session.course_definition(4)
	main.run_state.tokens = 20
	session.opponent.tokens = 20
	main._show_shop(6)
	await capture("shared_shop")
	main.shop_manager._on_shop_card_pressed(0)
	main.shop_manager._on_shop_continue_pressed()
	await capture("ai_card_reveal")
	main.vs_controller.view.continue_requested.emit()
	main._on_interstitial_continue_pressed()
	await capture("shared_course_hud")
	main.vs_controller.view.hide_page()
	# Scoreboard fixtures are labeled in this harness; gameplay outcomes are not fabricated in production.
	session.player.stats.total_strokes = 57
	session.opponent.stats.total_strokes = 62
	session.hole_results.clear()
	for index in 18:
		session.hole_results.append({"par": 4, "winner": -1 if index % 3 else 1})
	main.vs_controller.view.show_final(session)
	await capture("match_results")
	main.ui_appearance.apply_mode(&"light")
	await capture("match_results_light")
	main.vs_controller.return_to_menu()
	main._start_normal_run(424242)
	main._load_level(0)
	await capture("solo_regression")
	print("VS_VISUAL_REVIEW_%s: real AI turn resolved; fixture screens captured; presentation failures=%s" % ["PASS" if presentation_failures.is_empty() else "FAIL", presentation_failures])
	main.queue_free()
	await process_frame
	quit(0 if presentation_failures.is_empty() else 1)


func capture(name_value: String, settle := 45) -> void:
	for frame in settle:
		await process_frame
	await RenderingServer.frame_post_draw
	var match_bar: Control = main.vs_controller.view.match_bar
	if match_bar.is_visible_in_tree() and main.power_meter.is_visible_in_tree():
		if match_bar.get_global_rect().intersects(main.power_meter.get_global_rect()):
			presentation_failures.append(name_value + ": match HUD covers power meter")
	_audit_fonts(main)
	DirAccess.make_dir_recursive_absolute(output)
	var path := output.path_join(name_value + ".png")
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Screenshot failed: " + path)
	print("VS_SCREEN ", path)


func _audit_fonts(node: Node) -> void:
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	var copy := ""
	var font: Font
	if node is Label or node is Button or node is LineEdit:
		copy = node.text
		font = node.get_theme_font("font")
	elif node is RichTextLabel:
		copy = node.get_parsed_text()
		font = node.get_theme_font("normal_font")
	if font and not copy.is_empty():
		var base_font := font
		while base_font is FontVariation:
			base_font = base_font.base_font
		if not base_font.resource_path.contains("Jersey10"):
			presentation_failures.append("Legacy font: " + str(node.get_path()))
		for character in copy:
			if character.unicode_at(0) > 32 and not font.has_char(character.unicode_at(0)):
				presentation_failures.append("Missing glyph '%s': %s" % [character, node.get_path()])
	for child in node.get_children():
		_audit_fonts(child)
