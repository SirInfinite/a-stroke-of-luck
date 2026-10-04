extends SceneTree
## Curated sample dictionaries in the existing frozen-course test seam.
## Player resolves after one real shot; AI takes its complete real turn.
var failures: Array[String] = []
var records: Array[Dictionary] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var main = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for id in ["A2", "B2", "C1", "C2", "C3"]:
		var level := preload("res://tests/hazard_benchmarks.gd").build(id)
		main._start_normal_run(int(level.run_seed), &"woods")
		var session: VsMatchState = main.vs_controller.match_state
		# Fixture injection only. Subsequent construction/handoff/AI are native.
		session._courses[0] = level.duplicate(true)
		session.player.levels[0] = level.duplicate(true)
		session.opponent.levels[0] = level.duplicate(true)
		main._load_level(0)
		await physics_frame
		await physics_frame
		var course_id: int = main.level_root.get_instance_id()
		var generations := session.course_generation_count
		main.ball.shoot_normalized(Vector2.RIGHT, 0.1)
		for tick in 300:
			await physics_frame
			if not main.ball.shot_in_progress:
				break
		main._complete_current_hole(false, true)
		for tick in 4:
			await physics_frame
		var reset_phases: Array[Dictionary] = []
		for child in main.level_root.get_children():
			if child is MovingHazard:
				reset_phases.append({"id": child.stable_id, "elapsed": child.elapsed, "initial": child.phase * child.period})
		main.vs_controller.skipping = true
		main.vs_controller.set_watch_speed(8)
		for frame in 10000:
			await process_frame
			if session.turn == VsMatchState.Turn.RESULTS:
				break
		if session.turn != VsMatchState.Turn.RESULTS:
			failures.append(id + " AI turn timed out")
		if course_id != main.level_root.get_instance_id() or main.level_builder.active_level != level or generations != session.course_generation_count:
			failures.append(id + " shared course changed at handoff")
		records.append({"id": id, "opponent": "woods", "ai_strokes": session.opponent.strokes,
			"ai_failed": session.opponent.last_hole_forced, "reset_phases": reset_phases,
			"decisions": main.vs_controller.decisions.duplicate(true), "same_physical_instance": course_id == main.level_root.get_instance_id()})
		print("SAMPLE_VS ", id, " strokes=", session.opponent.strokes, " forced=", session.opponent.last_hole_forced)
		main.vs_controller.cancel()
	var file := FileAccess.open("res://artifacts/gameplay_direction/vs_smoke.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"records": records, "failures": failures, "player": "One real shot, then explicitly forced fixture resolution", "ai": "Unmodified Expert profile and actual GolfBall shots"}, "\t"))
	main.queue_free()
	await process_frame
	print("DIRECTION_VS_SMOKE failures=", failures)
	quit(0 if failures.is_empty() else 1)
