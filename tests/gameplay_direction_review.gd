extends "res://tests/hazard_checkpoint_probe.gd"
## Separate, finite automation. The playable scene never instantiates this runner.
const OUT := "res://artifacts/gameplay_direction"

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT + "/after")
	if OS.get_cmdline_user_args().has("--gallery"):
		await _capture_catalog()
	else:
		await _physics()
	quit(0 if failures.is_empty() else 1)

func _strategy_definitions() -> Array:
	if OS.get_cmdline_user_args().has("--before"):
		var file := FileAccess.open(OUT + "/before/fixtures.dat", FileAccess.READ)
		return file.get_var()
	var result: Array[Dictionary] = []
	for id in Catalog.IDS:
		result.append(Catalog.build(id))
	return result

func _physics() -> void:
	main = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.ball.wall_impact.connect(func(_strength: float, _point: Vector2) -> void: banks += 1)
	main.ball.elevation_changed.connect(func(_from: int, to: int, _point: Vector2) -> void: elevations.append(to))
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 64
	var kind := "strategies" if OS.get_cmdline_user_args().has("--strategies") else "probes"
	if kind == "strategies":
		await _strategies()
	else:
		await _bank_probes()
		await _timing_probes()
		await _exit_gate_probes()
		_require_timing_windows()
		await _recoveries()
		await _ice_probe()
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	Engine.max_physics_steps_per_frame = 8
	var side := "before" if OS.get_cmdline_user_args().has("--before") else "after"
	_write(side + "/" + kind + ".json", {"records": records, "failures": failures,
		"sample_version": 1 if side == "before" else Catalog.SAMPLE_VERSION,
		"engine": Engine.get_version_info(), "physics_delta": 1.0 / 60.0,
		"strategy_contract": "Fixed strategies: direct full, direct 20-power search, 5-degree immediate full-power angle search, existing Legend route/power/timing planner (seed 1000 + decision index). Common harness resets initial phase; waits advance real physics and retain penalties, cancelling a stale plan if hit. Run with --fixed-fps 480 and 8x clock, retaining 1/60 physics delta. Before uses frozen old definitions with the same current runtime as after.",
		"course_modifiers": {}, "personal_modifiers": {}})
	main.queue_free()
	await process_frame
	print("DIRECTION_REVIEW %s/%s records=%d failures=%s" % [side, kind, records.size(), failures])

func _capture_catalog() -> void:
	var holder := Node2D.new()
	root.add_child(holder)
	var camera := Camera2D.new()
	holder.add_child(camera)
	var builder := LevelBuilder.new()
	holder.add_child(builder)
	var report: Array[Dictionary] = []
	var contract: Array[Dictionary] = []
	var fixtures := _strategy_definitions()
	var snapshot := FileAccess.open(OUT + "/after/fixtures.dat", FileAccess.WRITE)
	snapshot.store_var(fixtures)
	snapshot.close()
	for level: Dictionary in fixtures:
		var course := builder.build_level(level, holder)
		if not course:
			failures.append("Build failed: " + level.benchmark_id)
			continue
		camera.zoom = Vector2.ONE * minf(1.0, minf(1700.0 / (level.map[0].length() * 100.0 + 120), 830.0 / (level.map.size() * 100.0 + 120)))
		var metric := Metrics.measure(level)
		metric["id"] = level.benchmark_id
		report.append(metric)
		for layer in ([0, 1] if level.benchmark_id in ["C1", "C3"] else [0, -1] if level.benchmark_id == "C2" else [0]):
			builder.set_active_elevation(layer)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT + "/after/%s_layer%d.png" % [level.benchmark_id, layer])
		var movers: Array[Dictionary] = []
		for child in course.get_children():
			if child is MovingHazard:
				movers.append(child.get_presentation_state())
		contract.append({"id": level.benchmark_id, "seed": level.run_seed, "version": level.benchmark_version,
			"cell_size": 100, "ball_radius": 12, "elevation": builder.get_elevation_presentation_data(),
			"surfaces": level.elevation_cells, "ramps": level.elevation_transitions,
			"structures": level.elevation_structures, "hazards": level.hazards,
			"obstacles": level.obstacles, "movers": movers, "notes": level.benchmark_notes})
		course.free()
	_write("after/metrics.json", report)
	_write("after/art_contract.json", contract)
	holder.free()
	print("DIRECTION_GALLERY_COMPLETE 9 courses and layered snapshots")

func _ice_probe() -> void:
	await super._ice_probe()
	# Diagnostic only: use the existing intensity contract, a short patch and a
	# visible sand stop. Nothing adopts these values in a production biome.
	var level := {"map": ["########################################", "########################################", "########################################", "########################################", "########################################"], "start_cell": Vector2i(2, 2), "hole_cell": Vector2i(37, 0), "par": 4,
		"hazards": [{"type": "ice", "pos": Vector2(-1250, 0), "size": Vector2(100, 100), "intensity": 0.55, "elevation": 0}, {"type": "sand", "pos": Vector2(-1050, 0), "size": Vector2(100, 100), "elevation": 0}],
		"obstacles": [], "moving_hazards": [], "run_seed": 910900, "run_difficulty_id": "normal"}
	for power in [0.4, 0.65, 1.0]:
		await _load(level)
		records.append(await _shot("surface_short_ice_sand", "existing_intensity_0.55_%.2f" % power, Vector2.RIGHT, power))

func _exit_gate_probes() -> void:
	# Isolate the fork exit and each second gate, with the same legal short shot
	# at sixteen waits. These are arranged starts, not whole-hole completions.
	var cases := {"A2": Vector2(12, 3), "B1": Vector2(9, -1), "B2": Vector2(10, 0), "B3": Vector2(11, -1), "C1": Vector2(10, -1), "C2": Vector2(8, -1), "C3": Vector2(9, -1)}
	for id in cases:
		var level := Catalog.build(id)
		for sample in 16:
			await _arrange(level, cases[id])
			main.level_builder.reset_dynamic_hazards()
			var delay := sample * float(level.moving_hazards[-1].period) / 16.0
			for tick in roundi(delay * 60.0):
				await physics_frame
			var row := await _shot(id, "exit_timing_%02d" % sample, Vector2.DOWN, 0.18)
			row["wait_seconds"] = delay
			records.append(row)
		print("EXIT_GATE_PROBE ", id, " complete")

func _require_timing_windows() -> void:
	var groups := {}
	for row in records:
		if not String(row.get("case", "")).contains("timing_"):
			continue
		var key := String(row.id) + ("/exit" if String(row.case).begins_with("exit") else "/entry")
		if not groups.has(key):
			groups[key] = {"clear": 0, "hit": 0}
		groups[key]["clear" if row.hazard_resets.is_empty() else "hit"] += 1
	for key in groups:
		if groups[key].clear == 0 or groups[key].hit == 0:
			failures.append("No demonstrated timing choice for %s: %s" % [key, str(groups[key])])

func _write(path: String, value: Variant) -> void:
	var file := FileAccess.open(OUT + "/" + path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_plain(value), "\t"))

func _plain(value: Variant) -> Variant:
	if value is Transform2D:
		return {"x": _plain(value.x), "y": _plain(value.y), "origin": _plain(value.origin)}
	return super._plain(value)
