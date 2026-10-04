extends GutTest
const BALL := preload("res://scenes/golf_ball.tscn")
const Catalog := preload("res://tests/hazard_benchmarks.gd")
const Metrics := preload("res://tests/hazard_course_metrics.gd")

func test_relative_sweep_distinguishes_contact_graze_and_departure() -> void:
	assert_almost_eq(MovingHazard.relative_contact_fraction(Vector2(-200, 0), Vector2(200, 0), Vector2.ZERO, Vector2.ZERO, 56), 0.36, 0.001)
	assert_lt(MovingHazard.relative_contact_fraction(Vector2(-200, 57), Vector2(200, 57), Vector2.ZERO, Vector2.ZERO, 56), 0.0)
	assert_gt(MovingHazard.relative_contact_fraction(Vector2.ZERO, Vector2.ZERO, Vector2(-100, 0), Vector2(100, 0), 56), 0.0)
	assert_lt(MovingHazard.relative_contact_fraction(Vector2(-60, 0), Vector2(-100, 0), Vector2.ZERO, Vector2.ZERO, 56), 0.0)
	assert_eq(MovingHazard.relative_contact_fraction(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, 56), 0.0)

func test_real_pendulum_cannot_be_skipped_at_normal_boosted_or_stress_speed() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	var ball = BALL.instantiate()
	holder.add_child(ball)
	var mover := MovingHazard.new()
	mover.configure({"id": "contact_fixture", "type": "pendulum", "pos": Vector2(0, -100), "travel_radius": 100.0, "period": 3.2})
	mover.setup_collision(Vector2(88, 88), true)
	holder.add_child(mover)
	watch_signals(mover)
	for speed in [400.0, 1600.0, 4000.0, 8000.0]:
		for phase in [0.0, 0.25, 0.5, 0.75]:
			mover.phase = phase
			mover.reset_state()
			ball.reset_to(Vector2(-190, -20), 0, false)
			await wait_physics_frames(2)
			var before: int = get_signal_emit_count(mover, "body_hit")
			ball.shoot(Vector2.RIGHT * speed)
			await wait_physics_frames(90)
			assert_gt(get_signal_emit_count(mover, "body_hit"), before, "real contact speed=%s phase=%s (8000 is stress beyond card cap)" % [speed, phase])
	ball.reset_to(Vector2(-190, -20), -1, false)
	mover.reset_state()
	await wait_physics_frames(2)
	var before: int = get_signal_emit_count(mover, "body_hit")
	ball.shoot(Vector2.RIGHT * 4000)
	await wait_physics_frames(12)
	assert_eq(get_signal_emit_count(mover, "body_hit"), before, "lower ball passes under an upper contact footprint")
	assert_gt(ball.position.x, 0.0)
	clear_signal_watcher()

func test_native_and_overlap_contact_share_one_event_and_reset_rearms() -> void:
	var mover := MovingHazard.new()
	mover.configure({"type": "pendulum", "pos": Vector2(0, -100), "travel_radius": 100.0})
	mover.setup_collision(Vector2(76, 76), true)
	add_child_autofree(mover)
	var ball = BALL.instantiate()
	ball.position = Vector2(-300, 0)
	add_child_autofree(ball)
	watch_signals(mover)
	assert_true(mover.register_body_contact(ball))
	mover._on_detector_body_entered(ball)
	assert_false(mover.register_body_contact(ball))
	assert_signal_emit_count(mover, "body_hit", 1)
	mover.reset_state()
	assert_true(mover.register_body_contact(ball))
	assert_signal_emit_count(mover, "body_hit", 2)
	var state := mover.get_presentation_state()
	assert_eq(state.footprint, Vector2(76, 76))
	assert_eq(state.position, mover.collision_shape.global_position)
	assert_eq(state.position, mover.detector.global_position)
	assert_true(state.collision_active)
	clear_signal_watcher()

func test_sample_density_difficulty_and_safe_underpasses() -> void:
	for id in Catalog.IDS:
		var easy := Catalog.build(id, &"easy")
		var normal := Catalog.build(id)
		var hard := Catalog.build(id, &"hard")
		assert_gte(Metrics.measure(normal).independent_threats, 6, id)
		assert_gt(Metrics.measure(hard).independent_threats, Metrics.measure(normal).independent_threats, id)
		assert_gt(float(easy.moving_hazards[0].period), float(normal.moving_hazards[0].period), id)
		assert_gt(float(normal.moving_hazards[0].period), float(hard.moving_hazards[0].period), id)
		assert_eq(normal.benchmark_version, 2)
		var identities := {}
		for group in ["hazards", "obstacles", "moving_hazards"]:
			for object: Dictionary in normal[group]:
				assert_false(identities.has(object.id), "Each physical object has a distinct stable ID")
				identities[object.id] = true
		for hazard: Dictionary in normal.moving_hazards:
			assert_false(String(hazard.id).is_empty())
			assert_true(hazard.has("interaction"))
		for structure in normal.elevation_structures:
			if structure.type == "overpass":
				for cell in structure.cells:
					assert_false(LevelValidator.placement_occupancy(normal).has(Vector3i(cell.x, cell.y, 0)), "covered lower passage stays empty")

func test_actual_ball_circle_has_clear_static_primary_routes() -> void:
	for id in Catalog.IDS:
		var holder := Node2D.new()
		add_child_autofree(holder)
		var builder := LevelBuilder.new()
		holder.add_child(builder)
		var level := Catalog.build(id)
		assert_not_null(builder.build_level(level, holder))
		var ball = BALL.instantiate()
		holder.add_child(ball)
		ball.reset_to(builder.level_point(level, "start", "start_cell"), 0)
		await wait_physics_frames(2)
		var model := AICourseModel.new()
		model.configure(builder, ball, RunState.new())
		PhysicsServer2D.body_set_collision_mask(model.query_body, 1 << 5)
		var route: Array = level.main_route_cells
		for index in range(1, route.size()):
			var first := model.offset + Vector2(route[index - 1]) * 100.0
			var last := model.offset + Vector2(route[index]) * 100.0
			var sweep := BallMotion.sweep(model.query_body, Transform2D(0.0, first), last - first, 1.0)
			assert_true(sweep.contacts.is_empty(), "%s: 12px ball clearance at step %d" % [id, index])
			assert_almost_eq(sweep.position, last, Vector2.ONE * 0.1)
		model.dispose()
		holder.queue_free()
		await wait_process_frames(1)
