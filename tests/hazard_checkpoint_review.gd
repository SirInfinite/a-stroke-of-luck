extends SceneTree
## Render actual builder output and exercise actual Main/GolfBall motion.
const Catalog := preload("res://tests/hazard_benchmarks.gd")
const Metrics := preload("res://tests/hazard_course_metrics.gd")
const OUTPUT := "user://hazard_checkpoint_20260910"
var main
var records: Array[Dictionary] = []
var failures: Array[String] = []
var banks := 0
var elevations: Array[int] = []
var presentation_samples: Array[Dictionary] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT + "/gallery")
	if OS.get_cmdline_user_args().has("--gallery"):
		await _gallery()
	else:
		await _physics()
	quit(0 if failures.is_empty() else 1)

func _gallery() -> void:
	var holder := Node2D.new()
	root.add_child(holder)
	var camera := Camera2D.new()
	holder.add_child(camera)
	var builder := LevelBuilder.new()
	holder.add_child(builder)
	var canvas := CanvasLayer.new()
	holder.add_child(canvas)
	var label := Label.new()
	label.position = Vector2(24, 12)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(label)
	var definitions: Array = []
	if OS.get_cmdline_user_args().has("--baseline"):
		var file := FileAccess.open(OUTPUT + "/baseline_fixtures.dat", FileAccess.READ)
		definitions = file.get_var()
	else:
		for id in Catalog.IDS:
			definitions.append(Catalog.build(id))
	for level: Dictionary in definitions:
		var course := builder.build_level(level, holder)
		if not course:
			failures.append("gallery build failed")
			continue
		var key := String(level.get("benchmark_id", "%s_%02d" % [level.run_difficulty_id, level.overall_hole_number]))
		label.text = "%s | %s | seed %d | %s\n%s" % [key, level.biome_name, level.run_seed, level.run_difficulty_name, level.get("benchmark_name", ", ".join(level.get("selected_motifs", [])))]
		camera.position = Vector2(0, -35)
		camera.zoom = Vector2.ONE * minf(1.0, minf(1700.0 / (level.map[0].length() * 100.0 + 120), 830.0 / (level.map.size() * 100.0 + 120)))
		for layer in ([0, 1] if key in ["C1", "C3"] else [-1] if key == "C2" else [0]):
			builder.set_active_elevation(layer)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUTPUT + "/gallery/%s_layer%d.png" % [key, layer])
		course.free()
	holder.queue_free()
	await process_frame
	print("HAZARD_GALLERY_COMPLETE holes=%d" % definitions.size())

func _load(level: Dictionary) -> void:
	main._hide_main_menu()
	main._hide_interstitial()
	main._reset_run_state(int(level.run_seed))
	main.run_state.difficulty_profile = DifficultyDatabase.get_profile(StringName(level.run_difficulty_id))
	for n in 18:
		main.run_state.normal_levels.append(level.duplicate(true))
	main.run_state.levels = main.run_state.normal_levels.duplicate(true)
	await physics_frame
	await physics_frame
	main._load_level(0)
	await physics_frame
	await physics_frame

func _physics() -> void:
	main = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.ball.wall_impact.connect(func(_strength: float, _point: Vector2) -> void: banks += 1)
	main.ball.elevation_changed.connect(func(_from: int, to: int, _point: Vector2) -> void: elevations.append(to))
	# Fixed 1/60 simulation delta even when running the scene faster.
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 64
	for id in Catalog.IDS:
		var level := Catalog.build(id)
		var metric := Metrics.measure(level)
		metric["id"] = id
		records.append({"kind": "geometry", "metrics": metric})
		await _load(level)
		presentation_samples.append(_presentation_snapshot(level))
		var model := AICourseModel.new()
		model.configure(main.level_builder, main.ball, main.run_state)
		var start: Vector2 = main.ball.global_position
		var target: Vector2 = model.cup
		var direct := (target - start).normalized()
		var predicted := model.predict(start, 0, direct, 1.0, 0.0, 1.0 / 60.0)
		model.dispose()
		records.append(await _shot(id, "naive_full_to_cup", direct, 1.0, predicted))
		await _load(level)
		records.append(await _shot(id, "full_along_entry", Vector2.RIGHT, 1.0))
		if id.begins_with("B"):
			for power in [0.38, 0.65, 1.0]:
				await _load(level)
				var point: Vector2 = main.level_builder.level_point(level, "unused", "benchmark_setup_cell")
				main.ball.reset_to(point, 0, false)
				main.last_safe_shot_position = point
				await physics_frame
				await physics_frame
				records.append(await _shot(id, "fork_setup_%.2f" % power, Vector2.RIGHT, power))
		if id.begins_with("C"):
			await _load(level)
			var point: Vector2 = main.level_builder.level_point(level, "unused", "benchmark_setup_cell")
			main.ball.reset_to(point, 0, false)
			main.last_safe_shot_position = point
			await physics_frame
			await physics_frame
			records.append(await _shot(id, "ramp_from_setup", Vector2.DOWN, 0.65))
		print("HAZARD_SHOTS ", id, " complete")
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	Engine.max_physics_steps_per_frame = 8
	var report := FileAccess.open(OUTPUT + "/checkpoint_physics.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"records": records, "failures": failures, "simulation": "Actual Main/GolfBall at fixed 1/60; setup positions explicitly arranged; predictions are diagnostic only"}, "\t"))
	var presentation := FileAccess.open(OUTPUT + "/art_contract.json", FileAccess.WRITE)
	presentation.store_string(JSON.stringify(_plain({"version": 1, "units": "100 px square cells; logical layers -1, 0, 1; world y increases down", "samples": presentation_samples}), "\t"))
	main.queue_free()
	await process_frame
	print("HAZARD_PHYSICS_COMPLETE records=%d failures=%s" % [records.size(), str(failures)])

func _shot(id: String, name: String, direction: Vector2, power: float, prediction: Dictionary = {}) -> Dictionary:
	banks = 0
	elevations.clear()
	var origin: Vector2 = main.ball.global_position
	var accepted: bool = main.ball.shoot_normalized(direction, power)
	var steps := 0
	while steps < 1800 and (main.ball.shot_in_progress or main.hazard_resetting or steps < 3):
		await physics_frame
		steps += 1
	var row := {"id": id, "case": name, "accepted": accepted, "origin": origin, "direction": direction, "power": power,
		"endpoint": main.ball.global_position, "strokes": main.run_state.strokes, "banks": banks,
		"elevation": main.ball.current_elevation, "elevation_changes": elevations.duplicate(), "steps": steps,
		"hazard_resets": main.run_stats.hazard_resets.duplicate(), "hazard_entries": main.run_stats.hazards_entered.duplicate(),
		"sunk": main.ball.sunk, "cup_completed": main.ball.sunk and main.run_state.strokes < int(main.run_state.levels[main.run_state.level_index].par) + RunState.STROKES_OVER_PAR,
		"timeout": steps >= 1800, "prediction": prediction}
	if not accepted or steps >= 1800:
		failures.append(id + ":" + name + " rejected or timed out")
	return row

func _presentation_snapshot(level: Dictionary) -> Dictionary:
	var moving: Array[Dictionary] = []
	for node in main.level_builder.level_root.get_children():
		if node is MovingHazard:
			moving.append({"type": node.hazard_type, "layer": node.elevation, "origin": node.origin,
				"position": node.position, "initial_phase": node.phase, "elapsed_seconds": node.elapsed,
				"cycle_fraction": fposmod(node.elapsed, node.period) / node.period, "period_seconds": node.period,
				"active": node.active, "collision_radius_px": node.collision_shape.shape.radius,
				"sweep_radius_px": node.travel_radius, "swing_radians": node.swing_angle,
				"telegraph": node.get_telegraph_data()})
	return {"id": level.benchmark_id, "active_layer": main.level_builder.active_elevation,
		"ball_radius_px": main.ball.get_collision_radius(), "cell_origin_world": main.level_builder.level_point(level, "start", "start_cell") - Vector2(level.start_cell) * 100,
		"surfaces": level.elevation_cells, "ramps": level.elevation_transitions,
		"structures": level.elevation_structures, "routes": level.benchmark_routes,
		"hazard_definitions": level.hazards, "hazard_footprints": Metrics.measure(level).footprints, "movers": moving}

func _plain(value: Variant) -> Variant:
	match typeof(value):
		TYPE_VECTOR2, TYPE_VECTOR2I: return [value.x, value.y]
		TYPE_VECTOR3, TYPE_VECTOR3I: return [value.x, value.y, value.z]
		TYPE_COLOR: return [value.r, value.g, value.b, value.a]
		TYPE_STRING_NAME: return String(value)
		TYPE_DICTIONARY:
			var result := {}
			for key in value:
				result[String(key)] = _plain(value[key])
			return result
		TYPE_ARRAY, TYPE_PACKED_VECTOR2_ARRAY:
			var result: Array = []
			for entry in value:
				result.append(_plain(entry))
			return result
	return value
