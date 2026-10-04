extends SceneTree
## Player score fixtures + a REAL 18-hole AI run, including shared-course shops.
var main
var results: Array[Dictionary] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	main = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.run_state.difficulty_profile = DifficultyDatabase.get_profile(&"normal")
	main._start_normal_run(573921, &"woods")
	main._load_level(0)
	var session: VsMatchState = main.vs_controller.match_state
	for index in 18:
		var frozen := session.course_definition(index)
		var instance_id: int = main.level_root.get_instance_id()
		for stroke in int(frozen.par):
			main.run_state.record_accepted_shot() # Explicit player fixture, not AI scoring.
		main._complete_current_hole(false, false)
		for frame in 3:
			await physics_frame
		main.vs_controller.skipping = true
		main.vs_controller.set_watch_speed(8)
		for frame in 6000:
			await process_frame
			if session.turn == VsMatchState.Turn.RESULTS:
				break
		if session.turn != VsMatchState.Turn.RESULTS:
			_fail("AI turn timed out at hole %d" % (index + 1))
			return
		if main.level_root.get_instance_id() != instance_id or frozen != main.level_builder.active_level or session.course_generation_count != index + 1:
			_fail("Shared physical course changed between competitors")
			return
		results.append({"hole": index + 1, "ai_strokes": session.opponent.strokes,
			"ai_failed": session.opponent.last_hole_forced, "course": frozen.match_course_modifiers,
			"player_cards": session.player.owned_cards.duplicate(), "ai_cards": session.opponent.owned_cards.duplicate()})
		print("VS_FULL_HOLE ", JSON.stringify(results.back()))
		main.vs_controller.view.continue_requested.emit()
		if index < 17 and index % 3 == 2:
			if main.vs_controller.ai_picks.is_empty():
				print("AI skipped shop at hole ", index + 1)
			for offer in main.shop_manager.current_shop_cards.size():
				main.shop_manager._on_shop_card_pressed(offer)
			main.shop_manager._on_shop_continue_pressed()
			main.vs_controller.view.continue_requested.emit()
			main._on_interstitial_continue_pressed()
	if main.get_run_phase_name() != "RUN_RESULTS" or session.hole_results.size() != 18 or session.opponent.stats.hole_history.size() != 18:
		_fail("Full-match results/history did not resolve")
		return
	var path := "user://vs_ai_20260907/full_match_smoke.json"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"holes": results, "summary": session.summary(), "course_generations": session.course_generation_count}, "  "))
	main.vs_controller.view.rematch_requested.emit()
	main._load_level(0)
	if main.run_state.run_seed != 573921 or main.run_state.total_strokes != 0 or Engine.time_scale != 1.0:
		_fail("Rematch did not restore initial state/clock")
		return
	print("VS_FULL_MATCH_PASS: 18 real AI turns, five shops, shared courses, final results, rematch")
	main.queue_free()
	await process_frame
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	main.queue_free()
	quit(1)
