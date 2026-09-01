extends GutTest

const BALL_SCENE := preload("res://scenes/golf_ball.tscn")
const GameplayHazardScript := preload("res://scripts/gameplay_hazard.gd")
const MovingHazardScript := preload("res://scripts/moving_hazard.gd")
const ElevationRampScript := preload("res://scripts/elevation_ramp.gd")
const TrajectoryPredictorScript := preload("res://scripts/trajectory_predictor.gd")


func test_trajectory_distance_scales_low_medium_high_without_fake_minimum() -> void:
	var low := _prediction_for_power(0.08)
	var medium := _prediction_for_power(0.5)
	var high := _prediction_for_power(1.0)

	assert_gt(float(low.distance), 0.0)
	assert_lt(float(low.distance), float(medium.distance))
	assert_lt(float(medium.distance), float(high.distance))
	assert_lt(float(low.distance), float(high.distance) * 0.15)
	assert_gte(PackedVector2Array(low.points).size(), 2)
	assert_lte(PackedVector2Array(high.points).size(), 24)
	assert_lt(float(low.dot_spacing), float(high.dot_spacing))


func test_bounce_pad_is_deterministic_bounded_and_never_zero() -> void:
	var incoming := Vector2(640.0, -120.0)
	var first: Vector2 = GameplayHazardScript.deterministic_bounce_velocity(incoming, 8147, 0, 0.76)
	var repeated: Vector2 = GameplayHazardScript.deterministic_bounce_velocity(incoming, 8147, 0, 0.76)
	var next_trigger: Vector2 = GameplayHazardScript.deterministic_bounce_velocity(incoming, 8147, 1, 0.76)
	var from_rest: Vector2 = GameplayHazardScript.deterministic_bounce_velocity(Vector2.ZERO, 8147, 0, 0.76)

	assert_eq(first, repeated)
	assert_ne(first.normalized(), next_trigger.normalized())
	assert_gte(first.length(), GameplayHazardScript.MIN_BOUNCE_SPEED)
	assert_lte(first.length(), GameplayHazardScript.MAX_BOUNCE_SPEED)
	assert_gte(from_rest.length(), GameplayHazardScript.MIN_BOUNCE_SPEED)


func test_ice_reduces_friction_and_restores_normal_grass_damping() -> void:
	var ball = BALL_SCENE.instantiate()
	add_child_autofree(ball)
	var normal_damping: float = ball.linear_damp

	ball.enter_ice_surface(101, 0.22)
	assert_true(ball.is_on_ice())
	assert_almost_eq(ball.linear_damp, normal_damping * 0.22, 0.001)

	ball.exit_ice_surface(101)
	assert_false(ball.is_on_ice())
	assert_almost_eq(ball.linear_damp, normal_damping, 0.001)


func test_ball_pause_freezes_a_live_shot_and_resumes_coherently() -> void:
	var ball = BALL_SCENE.instantiate()
	add_child_autofree(ball)
	ball.shot_in_progress = true
	ball.linear_velocity = Vector2(410.0, -75.0)
	ball.angular_velocity = 1.25
	var expected_velocity: Vector2 = ball.linear_velocity

	ball.set_gameplay_simulation_paused(true)
	assert_true(ball.simulation_paused)
	assert_true(ball.freeze)
	assert_eq(ball.process_mode, Node.PROCESS_MODE_DISABLED)
	ball._physics_process(1.0 / 60.0)
	assert_eq(ball.stopped_frames, 0)

	ball.set_gameplay_simulation_paused(false)
	assert_false(ball.simulation_paused)
	assert_false(ball.freeze)
	assert_eq(ball.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_eq(ball.linear_velocity, expected_velocity)
	assert_true(ball.shot_in_progress)


func test_ball_pause_suspends_bound_tweens_until_resume() -> void:
	var ball = BALL_SCENE.instantiate()
	add_child_autofree(ball)
	var ball_art := ball.get_node("BallArt") as Node2D
	ball_art.scale = Vector2.ONE
	var tween: Tween = ball._create_gameplay_transition_tween()
	tween.tween_property(ball_art, "scale", Vector2(1.5, 1.5), 0.08)
	ball.set_gameplay_simulation_paused(true)

	await wait_seconds(0.12)
	assert_eq(ball_art.scale, Vector2.ONE)

	ball.set_gameplay_simulation_paused(false)
	await wait_seconds(0.12)
	assert_almost_eq(ball_art.scale.x, 1.5, 0.01)


func test_ball_stopped_emits_once_for_one_moving_to_still_transition() -> void:
	var ball = BALL_SCENE.instantiate()
	add_child_autofree(ball)
	watch_signals(ball)
	ball.stopped_frames_required = 2
	ball.shot_in_progress = true
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0.0

	for _frame in range(5):
		ball._physics_process(1.0 / 60.0)

	assert_signal_emit_count(ball, "shot_finished", 1)
	assert_signal_emit_count(ball, "ball_stopped", 1)


func test_discrete_elevation_masks_do_not_collide_across_levels() -> void:
	var ball = BALL_SCENE.instantiate()
	add_child_autofree(ball)

	ball.set_current_elevation(-1)
	var lower_mask: int = ball.collision_mask
	var lower_z: int = ball.z_index
	ball.set_current_elevation(0)
	var ground_mask: int = ball.collision_mask
	var ground_z: int = ball.z_index
	ball.set_current_elevation(1)
	var upper_mask: int = ball.collision_mask
	var upper_z: int = ball.z_index

	assert_eq(lower_mask, 1 << 4)
	assert_eq(ground_mask, 1 << 5)
	assert_eq(upper_mask, 1 << 6)
	assert_eq(lower_mask & ground_mask, 0)
	assert_eq(ground_mask & upper_mask, 0)
	assert_eq(ground_z - lower_z, ball.ELEVATION_Z_STRIDE)
	assert_eq(upper_z - ground_z, ball.ELEVATION_Z_STRIDE)


func test_ramp_transition_is_discrete_and_bounded() -> void:
	assert_eq(ElevationRampScript.elevation_for_progress(0.0, 0, 1), 0)
	assert_eq(ElevationRampScript.elevation_for_progress(0.49, 0, 1), 0)
	assert_eq(ElevationRampScript.elevation_for_progress(0.5, 0, 1), 1)
	assert_eq(ElevationRampScript.elevation_for_progress(1.0, 0, 1), 1)
	assert_eq(ElevationRampScript.elevation_for_progress(0.25, 0, -1), 0)
	assert_eq(ElevationRampScript.elevation_for_progress(0.75, 0, -1), -1)


func test_moving_hazard_reset_restores_seeded_initial_state_without_timers() -> void:
	var hazard = MovingHazardScript.new()
	hazard.configure({
		"type": "pendulum",
		"pos": Vector2(120.0, 80.0),
		"size": Vector2(38.0, 38.0),
		"elevation": 0,
		"period": 2.4,
		"phase": 0.25,
		"travel_radius": 52.0,
		"blocks_main_route": false,
	})
	var initial_position: Vector2 = hazard.position
	var initial_rotation: float = hazard.rotation
	hazard.advance_cycle(0.7)
	assert_ne(hazard.position, initial_position)

	hazard.reset_state()
	assert_eq(hazard.position, initial_position)
	assert_almost_eq(hazard.rotation, initial_rotation, 0.0001)
	assert_eq(hazard.find_children("*", "Timer", true, false).size(), 0)
	hazard.free()


func _prediction_for_power(power: float) -> Dictionary:
	return TrajectoryPredictorScript.predict(
		Vector2.ZERO,
		Vector2.RIGHT * 1600.0 * power,
		1.0,
		1.8,
		5.0,
		56.0,
		2,
		24,
		1.0 / 60.0,
		8.0
	)
