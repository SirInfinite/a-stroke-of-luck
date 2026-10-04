extends "res://tests/visual_overhaul_review.gd"
## Real-screen icon QA. Fixture state only; no settings saves, gameplay hooks or
## production debug bindings. Includes all inherited screens and six biomes.


func _ready() -> void:
	super._ready()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--review-size="):
			var dimensions := argument.trim_prefix("--review-size=").split("x")
			get_window().mode = Window.MODE_WINDOWED
			get_window().size = Vector2i(int(dimensions[0]), int(dimensions[1]))
			output_directory = output_directory.get_base_dir().path_join(argument.trim_prefix("--review-size="))
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory))


func _run_review() -> void:
	await super._run_review()
	main._start_normal_run(SAFE_SEED)
	main._load_level(0)
	main.run_state.add_card(Cards.get_cards()[0])
	main._update_status()
	await _capture("20_hud_active_effects", main.release_hud)
	for remaining in [2, 1]:
		main.run_state.strokes = main.run_state.levels[0].par + RunState.STROKES_OVER_PAR - remaining
		main._update_status()
		await _capture("21_shots_left_%d" % remaining, main.release_hud)
	# Hold this presentation snapshot; the in-bounds physics tick would otherwise
	# correctly clear an injected warning before the screenshot is taken.
	var was_processing_physics: bool = main.is_physics_processing()
	main.set_physics_process(false)
	main.release_hud.show_out_of_bounds(2)
	await _capture("22_oob", main.release_hud)
	_check(main.release_hud.oob_panel.is_visible_in_tree(), "OOB warning must actually be rendered")
	_check(not main.release_hud.stroke_warning.visible, "OOB snapshot must suppress the stroke warning")
	var countdown: Label = main.release_hud.oob_countdown_label
	var copy_width := countdown.get_theme_font("font").get_string_size(countdown.text, HORIZONTAL_ALIGNMENT_LEFT, -1, countdown.get_theme_font_size("font_size")).x
	_check(countdown.size.x >= copy_width, "OOB explanation must not be squeezed out by its icon")
	main.release_hud.hide_out_of_bounds()
	main.set_physics_process(was_processing_physics)
	main.run_state.phase = RunState.Phase.HOLE_RESULTS
	main.run_state.tokens = 40
	main.run_state.difficulty_profile = Difficulties.get_profile(&"easy")
	main._show_shop(3)
	for page in range(2):
		for index in range(4):
			var offer := CardRarityProfile.create(Cards.get_cards()[page * 4 + index], CardRarityProfile.IDS[index])
			main.shop_manager.shop_card_buttons[index].configure_card(offer, true, false, 1)
		await _capture("23_equipment_rarities_%d" % page, main.shop_manager.shop_overlay)
		_check_cards()
	# The inherited long sequence replaces run-level arrays. Reacquire authored
	# lessons for this isolated presentation fixture rather than reuse its state.
	main.tutorial_levels = TutorialDatabase.get_levels()
	main._start_tutorial()
	# Visit authored terrain lessons, retaining their actual instruction and event.
	for level_index in main.tutorial_levels.size():
		var lesson: Dictionary = main.tutorial_levels[level_index]
		for step_index in lesson.get("steps", []).size():
			var event_name := String(lesson.steps[step_index].get("event", ""))
			if "sand" not in event_name and "water" not in event_name:
				continue
			main._load_level(level_index)
			main.tutorial_manager.current_step_index = step_index
			main.tutorial_manager._update_hint()
			await _capture("24_tutorial_" + event_name, main.tutorial_manager.hint_panel)
	var report := {"captures": captures, "capture_count": capture_count, "layout_checks": layout_checks, "layout_failures": layout_failures, "findings": findings}
	var file := FileAccess.open(output_directory.path_join("layout_report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("[ICON BRAND REVIEW] %d captures / %d checks / %d failures" % [capture_count, layout_checks, layout_failures])
	main.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if layout_failures == 0 else 1)


func _check_tree(node: Node, context: String) -> void:
	super._check_tree(node, context)
	if node is UIIcon and node.is_visible_in_tree():
		_check(IconCatalog.has_icon(node.icon_name), context + " unknown icon: " + String(node.icon_name))
		_check(get_viewport_rect().grow(2).encloses(node.get_global_rect()), context + " icon offscreen: " + String(node.name))
