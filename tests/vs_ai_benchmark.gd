extends SceneTree
## Real GolfBall + Main accounting benchmark. Never substitutes predicted results.
## Player turns are harness fixtures; only actual AI strokes enter the report.
var main
var records: Array[Dictionary] = []
var seed_count := 2
var watch_speed := 8
var hole_indices: Array[int] = []
var opponents: Array[StringName] = []
var output := "user://vs_ai_20260907/ai_benchmark.json"


func _init() -> void:
	for index in 18:
		hole_indices.append(index)
	opponents.assign(AIDifficultyProfile.IDS)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seeds="):
			seed_count = clampi(int(argument.get_slice("=", 1)), 1, 20)
		elif argument.begins_with("--holes="):
			hole_indices.clear()
			for number in argument.get_slice("=", 1).split(","):
				hole_indices.append(clampi(int(number), 0, 17))
		elif argument.begins_with("--opponents="):
			opponents.clear()
			for id in argument.get_slice("=", 1).split(","):
				opponents.append(StringName(id))
		elif argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		elif argument.begins_with("--speed="):
			watch_speed = clampi(int(argument.get_slice("=", 1)), 1, 8)
	_run.call_deferred()


func _run() -> void:
	main = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for id in opponents:
		for seed_index in seed_count:
			for hole in hole_indices:
				await _play(id, 424242 + seed_index * 7919, hole)
	var summary := {}
	var timeouts := 0
	for id in opponents:
		var rows := records.filter(func(row: Dictionary) -> bool: return row.opponent == id)
		var total := {"holes": rows.size(), "strokes": 0, "completed": 0, "failed": 0, "timeouts": 0,
			"oob": 0, "hazard_resets": 0, "decisions": 0, "decision_ms": 0.0, "decision_max_ms": 0.0,
			"power": 0.0, "max_power": 0, "banks": 0, "pads": 0}
		for row in rows:
			for key in ["strokes", "completed", "failed", "oob", "hazard_resets", "timeouts", "decisions", "decision_ms", "power", "max_power", "banks", "pads"]:
				total[key] += row[key]
			total.decision_max_ms = maxf(total.decision_max_ms, row.decision_max_ms)
		var count := maxf(rows.size(), 1)
		var shots := maxf(total.decisions, 1)
		total["average_strokes"] = total.strokes / count
		total["completion_percent"] = total.completed * 100.0 / count
		total["failure_percent"] = total.failed * 100.0 / count
		total["max_power_percent"] = total.max_power * 100.0 / shots
		total["average_power"] = total.power / shots
		total["average_decision_ms"] = total.decision_ms / shots
		total["bank_percent"] = total.banks * 100.0 / shots
		timeouts += total.timeouts
		summary[id] = total
	var report := {"engine": Engine.get_version_info().string, "physics": "actual GolfBall; fixed 1/60 simulation steps; no outcome substitution",
		"seed_count": seed_count, "records": records, "summary": summary, "timeouts": timeouts}
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("AI_BENCHMARK_SUMMARY=", JSON.stringify(summary))
	main.queue_free()
	await process_frame
	quit(0 if timeouts == 0 else 1)


func _play(id: StringName, seed_value: int, hole: int) -> void:
	main.run_state.difficulty_profile = DifficultyDatabase.get_profile(&"normal")
	main._start_normal_run(seed_value, id)
	main._load_level(hole)
	var session: VsMatchState = main.vs_controller.match_state
	main._complete_current_hole(false, false)
	await physics_frame
	await physics_frame
	await physics_frame
	main.vs_controller.skipping = true
	main.vs_controller.set_watch_speed(watch_speed)
	var frames := 0
	while session.turn != VsMatchState.Turn.RESULTS and frames < 6000:
		await process_frame
		frames += 1
	var log: Array = main.vs_controller.decisions.duplicate(true)
	var hazard_resets := 0
	for count in session.opponent.stats.hazard_resets.values():
		hazard_resets += int(count)
	var record := {"opponent": id, "seed": seed_value, "hole": hole + 1, "par": session.opponent.levels[hole].par,
		"strokes": session.opponent.strokes, "completed": int(session.turn == VsMatchState.Turn.RESULTS and not session.opponent.last_hole_forced),
		"failed": int(session.opponent.last_hole_forced), "timeouts": int(session.turn != VsMatchState.Turn.RESULTS),
		"oob": 0, "hazard_resets": hazard_resets, "decisions": log.size(),
		"decision_ms": 0.0, "decision_max_ms": 0.0, "power": 0.0, "max_power": 0, "banks": 0, "pads": 0,
		"shots": log}
	record.oob = maxi(session.opponent.accepted_shot_id + hazard_resets - session.opponent.strokes, 0)
	for shot in log:
		record.decision_ms += float(shot.decision_ms)
		record.decision_max_ms = maxf(record.decision_max_ms, float(shot.decision_ms))
		record.power += float(shot.power)
		record.max_power += int(float(shot.power) >= 0.98)
		record.banks += int(shot.get("actual_bank", false))
		record.pads += int(shot.get("actual_pad", false))
	records.append(record)
	print("AI_HOLE ", JSON.stringify(record.merged({"shots": []}, true)))
	main.vs_controller.return_to_menu()
	await process_frame
