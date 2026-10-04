extends SceneTree
const Metrics := preload("res://tests/hazard_course_metrics.gd")
const OUTPUT := "user://hazard_checkpoint_20260910"

func _init() -> void:
	var seed_count := 6
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed-count="):
			seed_count = clampi(int(argument.get_slice("=", 1)), 1, 100)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var records: Array[Dictionary] = []
	var fixtures: Array[Dictionary] = []
	for sample in range(1, seed_count + 1):
		for difficulty in DifficultyDatabase.get_profiles():
			for index in 18:
				var started := Time.get_ticks_usec()
				var level := HoleGenerator.generate_hole(BiomeDatabase.get_profiles()[index / 3], sample * 7919, index / 3, index % 3, 8, difficulty.generation_options())
				var elapsed := (Time.get_ticks_usec() - started) / 1000.0
				var record := Metrics.measure(level)
				record["generation_ms"] = elapsed
				records.append(record)
				if sample == 1:
					fixtures.append(level)
		print("HAZARD_BASELINE seeds=%d/%d holes=%d" % [sample, seed_count, records.size()])
	var report := FileAccess.open(OUTPUT + "/baseline.json", FileAccess.WRITE)
	if not report:
		quit(1)
		return
	report.store_string(JSON.stringify({"seed_formula": "7919 * [1..seed_count]", "seed_count": seed_count, "records": records}, "\t"))
	var fixture_file := FileAccess.open(OUTPUT + "/baseline_fixtures.dat", FileAccess.WRITE)
	fixture_file.store_var(fixtures)
	var failures := records.filter(func(r: Dictionary) -> bool: return not r.valid).size()
	print("HAZARD_BASELINE_COMPLETE holes=%d invalid=%d path=%s" % [records.size(), failures, ProjectSettings.globalize_path(OUTPUT)])
	quit(0 if failures == 0 else 1)
