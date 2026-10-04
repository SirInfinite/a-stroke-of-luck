extends GutTest
const Catalog := preload("res://tests/hazard_benchmarks.gd")
const Metrics := preload("res://tests/hazard_course_metrics.gd")

func test_all_benchmark_variants_pass_full_generated_contract() -> void:
	for tier in [&"easy", &"normal", &"hard"]:
		for id in Catalog.IDS:
			var level := Catalog.build(id, tier)
			assert_false(level.is_empty(), id)
			assert_true(LevelValidator.validate_level(level, 0, false), "%s %s: %s" % [id, tier, str(LevelValidator.generation_errors(level))])
			assert_true(LevelValidator.generation_errors(level).is_empty(), id)
			assert_false(level.main_route_cells.is_empty(), id)
			assert_lte(level.par, 4)

func test_variants_are_structurally_distinct_and_replay_without_global_rng() -> void:
	var signatures := {}
	for id in Catalog.IDS:
		var first := Catalog.build(id)
		var signature := Metrics.structural_signature(first)
		assert_false(signatures.has(signature), id + " must reshape geometry")
		signatures[signature] = true
		for n in 5:
			randf()
		assert_eq(first, Catalog.build(id))
		var recolored := first.duplicate(true)
		recolored.terrain_palette = {}
		recolored.hazards = []
		recolored.moving_hazards = []
		assert_eq(signature, Metrics.structural_signature(recolored))

func test_crossings_separate_layers_and_recovery_is_reachable() -> void:
	for id in ["C1", "C3"]:
		var level := Catalog.build(id)
		var crossings := 0
		for structure in level.elevation_structures:
			if structure.type != "overpass":
				continue
			crossings += 1
			assert_eq(structure.cells.size(), 2)
			for cell in structure.cells:
				assert_eq(LevelValidator.cell_elevations(level, cell), [0, 1])
				assert_false(LevelValidator.placement_occupancy(level).has(Vector3i(cell.x, cell.y, 0)), "No hidden lower threat")
		assert_eq(crossings, 1)
		var broken := level.duplicate(true)
		broken.elevation_transitions.clear()
		assert_false(LevelValidator.validate_level(broken, 0, false), "A visible crossing cannot substitute for a ramp")

func test_invalid_fixture_requests_fail_closed() -> void:
	assert_eq(Catalog.build("unknown"), {})
	assert_eq(Catalog.build("A1", &"impossible"), {})

func test_signature_ignores_grid_symmetry_but_keeps_route_endpoints_and_layers() -> void:
	var level := {"map": ["##  ", "####", "  # "], "start_cell": Vector2i(0, 0), "hole_cell": Vector2i(3, 1)}
	var mirror := {"map": ["  ##", "####", " #  "], "start_cell": Vector2i(3, 0), "hole_cell": Vector2i(0, 1)}
	var rotated := {"map": [" ##", " ##", "## ", " # "], "start_cell": Vector2i(2, 0), "hole_cell": Vector2i(1, 3)}
	var signature := Metrics.structural_signature(level)
	assert_eq(signature, Metrics.structural_signature(mirror), "Hand-authored mirror")
	assert_eq(signature, Metrics.structural_signature(rotated), "Hand-authored quarter turn")
	rotated.hole_cell = Vector2i(0, 2)
	assert_ne(signature, Metrics.structural_signature(rotated), "Different approach endpoint")
	level["elevation_cells"] = [{"cell": Vector2i(2, 2), "levels": [1]}]
	assert_ne(signature, Metrics.structural_signature(level), "Logical layer contributes to diversity")
	var crossing := {"map": ["###"], "start_cell": Vector2i(0, 0), "hole_cell": Vector2i(2, 0), "elevation_cells": [{"cell": Vector2i(0, 0), "levels": [0, 1]}, {"cell": Vector2i(2, 0), "levels": [0, 1]}]}
	var crossing_signature := Metrics.structural_signature(crossing)
	crossing["start_elevation"] = 1
	assert_ne(crossing_signature, Metrics.structural_signature(crossing), "Same crossing surfaces, different tee layer")
	crossing["start_elevation"] = 0
	crossing["hole_elevation"] = 1
	assert_ne(crossing_signature, Metrics.structural_signature(crossing), "Same crossing surfaces, different cup layer")

func test_query_simulation_and_competitor_reset_preserve_benchmark_contract() -> void:
	for id in ["A1", "B2", "C1"]:
		var holder := Node2D.new()
		add_child_autofree(holder)
		var builder := LevelBuilder.new()
		holder.add_child(builder)
		var level := Catalog.build(id)
		var original := level.duplicate(true)
		assert_not_null(builder.build_level(level, holder))
		var ball = preload("res://scenes/golf_ball.tscn").instantiate()
		holder.add_child(ball)
		var start := builder.level_point(level, "start", "start_cell")
		ball.reset_to(start, 0, false)
		var state := RunState.new()
		state.reset(int(level.run_seed))
		await wait_physics_frames(3)
		var model := AICourseModel.new()
		model.configure(builder, ball, state)
		var times: Array[float] = []
		for node in builder.level_root.get_children():
			if node is MovingHazard:
				times.append(node.elapsed)
		for power in [0.35, 0.65, 1.0]:
			var forecast := model.predict(start, 0, Vector2.RIGHT, power)
			assert_true(forecast.complete, "Finite simulation budget produces a terminal result")
		assert_eq(level, original, "Candidates cannot mutate the course definition")
		assert_eq(builder.active_level, original)
		assert_eq(ball.global_position, start, "Queries cannot move the real ball")
		var index := 0
		for node in builder.level_root.get_children():
			if node is MovingHazard:
				assert_eq(node.elapsed, times[index], "Queries cannot advance live phase")
				index += 1
		model.dispose()
		builder.reset_for_competitor()
		for node in builder.level_root.get_children():
			if node is MovingHazard:
				assert_eq(node.elapsed, node.phase * node.period, "Competitor starts with the authored phase")
		holder.queue_free()
		await wait_process_frames(1)
