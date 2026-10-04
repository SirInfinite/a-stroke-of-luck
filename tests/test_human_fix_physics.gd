extends GutTest

const BALL := preload("res://scenes/golf_ball.tscn")

func test_built_course_boundary_corners_contain_real_boosts() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	var builder := LevelBuilder.new()
	holder.add_child(builder)
	var level := {"map": ["#####", "#####", "#####", "#####", "#####"], "start_cell": Vector2i(1, 1), "hole_cell": Vector2i(4, 4), "par": 4, "hazards": [], "obstacles": []}
	assert_not_null(builder.build_level(level, holder))
	var ball = BALL.instantiate()
	holder.add_child(ball)
	await wait_physics_frames(3)
	for speed in [1600.0, 4000.0, GameplayHazard.MAX_BOUNCE_SPEED]:
		ball.reset_to(Vector2.ZERO, 0, false)
		await wait_physics_frames(2)
		ball.shoot(Vector2.ONE.normalized() * float(speed))
		for frame in range(80):
			await wait_physics_frames(1)
			assert_lte(maxf(absf(ball.position.x), absf(ball.position.y)), 238.2, "Ball circle stays inside actual LevelBuilder walls/corner fill")

func test_known_surface_forecast_uses_actual_sand_and_ice_response() -> void:
	var main = preload("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	main._start_normal_run(424242)
	main._load_level(0)
	main._hide_main_menu()
	main.set_process(false) # Isolated physical surface, not a generated OOB test.
	main.set_physics_process(false)
	main.level_builder.level_root.free()
	main.level_builder.level_root = null
	main.level_root = null
	var ball = main.ball
	for type in ["sand", "ice"]:
		var definition := {"type": type, "pos": Vector2(300, 0), "size": Vector2(100, 200), "elevation": 0, "intensity": 0.22}
		var area := GameplayHazard.new()
		area.configure(definition)
		area.position = definition.pos
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = definition.size
		collision.shape = shape
		area.add_child(collision)
		main.add_child(area)
		if type == "sand":
			area.body_entered.connect(main._on_sand_body_entered)
			area.body_exited.connect(main._on_sand_body_exited)
		ball.configure_level({"hazards": [definition]})
		for speed in [600.0, 1600.0]:
			ball.reset_to(Vector2.ZERO, 0, false)
			main.run_state.strokes = 0
			await wait_physics_frames(3)
			var prediction: Dictionary = ball.get_trajectory_prediction(Vector2.RIGHT * float(speed))
			assert_true(ball.can_shoot())
			ball.shoot(Vector2.RIGHT * float(speed))
			for frame in range(720):
				await wait_physics_frames(1)
				if not ball.shot_in_progress:
					break
			var error: float = prediction.endpoint.distance_to(ball.position)
			print("[SURFACE ENDPOINT] %s speed=%s predicted=%s actual=%s error=%.3f" % [type, speed, prediction.endpoint, ball.position, error])
			assert_false(ball.shot_in_progress)
			assert_lt(error, 18.0, "Known surface endpoint within 18 px (a tile is 100 px)")
		ball.reset_to(Vector2.ZERO, 0, false)
		await wait_physics_frames(2)
		area.free()
		await wait_physics_frames(2)
	main.level_builder.level_root = null

func test_player_preview_stays_straight_and_boost_still_collides() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	_wall(holder, Vector2(312, 0), Vector2(24, 3000))
	var ball = BALL.instantiate()
	holder.add_child(ball)
	await wait_physics_frames(3)
	for speed in [600.0, 1600.0, 4000.0]:
		ball.reset_to(Vector2.ZERO, 0, false)
		await wait_physics_frames(2)
		var impulse: Vector2 = Vector2(1.0, 0.2).normalized() * float(speed)
		var predicted: Dictionary = ball.get_trajectory_prediction(impulse)
		for point in predicted.points:
			assert_almost_eq(Vector2(point).cross(impulse.normalized()), 0.0, 0.1, "Player guide is a conditional straight resting line, not a ricochet")
		assert_gt(predicted.endpoint.x, 288.1, "Guide does not claim to predict the intervening wall")
		ball.shoot(impulse)
		for frame in range(600):
			await wait_physics_frames(1)
			assert_lte(ball.position.x, 288.1)
			if not ball.shot_in_progress:
				break
	ball.reset_to(Vector2(260, 0), 0, false)
	await wait_physics_frames(2)
	ball.shoot(Vector2.RIGHT * 100)
	ball.redirect_from_bounce_pad(Vector2.RIGHT * GameplayHazard.MAX_BOUNCE_SPEED, Vector2(260, 0), 39.0)
	for frame in range(120):
		await wait_physics_frames(1)
		assert_lte(ball.position.x, 288.1, "Pad separation and boosted travel must sweep the wall")

func test_actual_wall_reflection_preserves_incident_angle() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	_wall(holder, Vector2(312, 0), Vector2(24, 12000))
	var ball = BALL.instantiate()
	holder.add_child(ball)
	await wait_physics_frames(3)
	for speed in [600.0, 1600.0, 4000.0, 8000.0]:
		for degrees in [15.0, 35.0, 60.0, 75.0]:
			ball.reset_to(Vector2(265, 0), 0, false)
			await wait_physics_frames(2)
			assert_almost_eq(ball.position, Vector2(265, 0), Vector2.ONE, "Reset must clear the preceding collision")
			var incoming := Vector2.RIGHT.rotated(deg_to_rad(degrees))
			ball.shoot(incoming * speed)
			var reflected := false
			for frame in range(60):
				await wait_physics_frames(1)
				if ball.linear_velocity.x < -1.0:
					var error := absf(rad_to_deg(incoming.bounce(Vector2.LEFT).angle_to(ball.linear_velocity)))
					print("[REFLECTION] speed=%s angle=%s error=%.3f" % [speed, degrees, error])
					assert_lt(error, 3.0, "One restitution factor must preserve the reflection angle")
					assert_lte(ball.position.x, 288.1)
					reflected = true
					break
			assert_true(reflected, "Shot reaches and reflects from the wall: speed=%s angle=%s pos=%s vel=%s" % [speed, degrees, ball.position, ball.linear_velocity])

func test_isolated_corner_containment() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	_wall(holder, Vector2(222, 0), Vector2(44, 444))
	_wall(holder, Vector2(-222, 0), Vector2(44, 444))
	_wall(holder, Vector2(0, -222), Vector2(444, 44))
	_wall(holder, Vector2(0, 222), Vector2(444, 44))
	var ball = BALL.instantiate()
	holder.add_child(ball)
	await wait_physics_frames(3)
	ball.shoot(Vector2.ONE.normalized() * 4000)
	for frame in range(30):
		await wait_physics_frames(1)
		assert_lt(maxf(absf(ball.position.x), absf(ball.position.y)), 200.0)

func _wall(parent: Node, at: Vector2, dimensions: Vector2) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.position = at
	wall.collision_layer = 32
	wall.set_meta(&"collision_kind", &"boundary")
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	collision.shape = shape
	wall.add_child(collision)
	parent.add_child(wall)
	return wall

func test_actual_high_speed_straight_diagonal_and_corner_containment() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	_wall(holder, Vector2(222, 0), Vector2(44, 444))
	_wall(holder, Vector2(-222, 0), Vector2(44, 444))
	_wall(holder, Vector2(0, -222), Vector2(444, 44))
	_wall(holder, Vector2(0, 222), Vector2(444, 44))
	var ball = BALL.instantiate()
	holder.add_child(ball)
	await wait_physics_frames(3)
	for speed in [400.0, 1600.0, 4000.0, 1450.0, 8000.0]:
		for direction in [Vector2.RIGHT, Vector2(1, 0.37).normalized(), Vector2.ONE.normalized()]:
			ball.reset_to(Vector2.ZERO, 0, false)
			await wait_physics_frames(2)
			ball.shoot(direction * speed)
			var bounced := false
			var escaped := false
			for frame in range(100):
				await wait_physics_frames(1)
				if not escaped and (absf(ball.global_position.x) > 200 or absf(ball.global_position.y) > 200):
					print("[WALL ESCAPE] frame=%d speed=%s dir=%s pos=%s velocity=%s corrections=%d" % [frame, speed, direction, ball.global_position, ball.linear_velocity, ball.wall_sweep_corrections])
				escaped = escaped or absf(ball.global_position.x) > 200 or absf(ball.global_position.y) > 200
				bounced = bounced or ball.linear_velocity.dot(direction) < -1
			assert_false(escaped, "Containment at %s px/s, %s" % [speed, direction])
			assert_true(bounced, "A wall must bounce at %s px/s" % speed)
			assert_lte(ball.linear_velocity.length(), speed + 1.0)
		ball.reset_to(Vector2.ZERO)

func test_predicted_endpoint_matches_actual_stopping_position() -> void:
	var ball = BALL.instantiate()
	add_child_autofree(ball)
	await wait_physics_frames(3)
	for modifier in [1.0, 1.75, 2.5]:
		ball.apply_card_modifiers(modifier, 1, 0)
		for power in [0.08, 0.5, 1.0]:
			ball.reset_to(Vector2.ZERO, 0, false)
			await wait_physics_frames(2)
			var predicted: Dictionary = ball.get_trajectory_prediction_for_power(Vector2.RIGHT, power)
			ball.shoot(Vector2.RIGHT * ball.max_impulse * modifier * power)
			for frame in range(720):
				await wait_physics_frames(1)
				if not ball.shot_in_progress:
					break
			var error: float = Vector2(predicted.points[-1]).distance_to(ball.global_position)
			print("[ENDPOINT] power=%s modifier=%s error=%.3f" % [power, modifier, error])
			assert_false(ball.shot_in_progress)
			assert_lt(error, 12.0, "Endpoint within one ball radius")

func test_pendulum_live_transform_moves_art_and_detector_together() -> void:
	var moving := MovingHazard.new()
	moving.configure({"type": "pendulum", "pos": Vector2.ZERO, "travel_radius": 72.0, "period": 1.2})
	moving.setup_collision(Vector2(38, 38), true)
	add_child_autofree(moving)
	var art := CourseVisualFactory.create_moving_hazard_visual(&"pendulum", Vector2(38, 38), Color.GRAY, Color.WHITE)
	moving.add_child(art)
	moving.set_visual_node(art)
	var minimum_x := INF
	var maximum_x := -INF
	for frame in range(150):
		await wait_physics_frames(1)
		minimum_x = minf(minimum_x, moving.global_position.x)
		maximum_x = maxf(maximum_x, moving.global_position.x)
		assert_almost_eq(art.global_position, moving.collision_shape.global_position, Vector2.ONE * 0.1)
		assert_almost_eq(art.global_position, moving.detector.global_position, Vector2.ONE * 0.1)
	assert_gt(maximum_x - minimum_x, 90.0, "Spiky ball traverses the actual arc in live physics")
