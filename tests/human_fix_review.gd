extends "res://tests/visual_overhaul_review.gd"
## Actual Main review, with no persistent settings writes or production input hooks.

func _ready() -> void:
	# Main may restore the player's display mode. The fixture, not production,
	# owns review dimensions and changes them only after Main has loaded.
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
	for remaining in [2, 1]:
		main.run_state.strokes = main.run_state.levels[0].par + RunState.STROKES_OVER_PAR - remaining
		main._update_status()
		await _capture("18_shots_left_%d" % remaining, main.release_hud)
	main.run_state.phase = RunState.Phase.HOLE_RESULTS
	main.run_state.tokens = 40
	main.run_state.difficulty_profile = Difficulties.get_profile(&"easy")
	main._show_shop(3)
	for index in range(4):
		var offer := CardRarityProfile.create(Cards.get_cards()[index], CardRarityProfile.IDS[index])
		main.shop_manager.shop_card_buttons[index].configure_card(offer, true, false, 1)
	await _capture("19_all_rarities", main.shop_manager.shop_overlay)
	_check_cards()
	var report := {"captures": captures, "capture_count": capture_count, "layout_checks": layout_checks, "layout_failures": layout_failures, "findings": findings}
	var file := FileAccess.open(output_directory.path_join("layout_report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("[HUMAN FIX REVIEW] %d captures / %d checks / %d failures" % [capture_count, layout_checks, layout_failures])
	get_tree().quit(0 if layout_failures == 0 else 1)
