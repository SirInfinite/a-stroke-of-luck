class_name TrajectoryPredictor
extends RefCounted

const DEFAULT_PHYSICS_STEP := 1.0 / 60.0
const DEFAULT_MAX_PREDICTION_TIME := 8.0
const DEFAULT_MIN_DOT_COUNT := 2
const DEFAULT_MAX_DOT_COUNT := 24
const DEFAULT_PREFERRED_DOT_SPACING := 56.0


static func predict(
	origin: Vector2,
	impulse: Vector2,
	body_mass: float,
	linear_damping: float,
	stop_speed: float,
	preferred_dot_spacing := DEFAULT_PREFERRED_DOT_SPACING,
	min_dot_count := DEFAULT_MIN_DOT_COUNT,
	max_dot_count := DEFAULT_MAX_DOT_COUNT,
	physics_step := DEFAULT_PHYSICS_STEP,
	max_prediction_time := DEFAULT_MAX_PREDICTION_TIME
) -> Dictionary:
	var safe_mass := maxf(body_mass, 0.001)
	var safe_step := maxf(physics_step, 0.001)
	var velocity := impulse / safe_mass
	var initial_speed := velocity.length()
	if impulse.is_zero_approx() or initial_speed <= maxf(stop_speed, 0.0):
		return _empty_prediction(origin, initial_speed)

	var raw_points := PackedVector2Array([origin])
	var cumulative_distances := PackedFloat32Array([0.0])
	var position := origin
	var elapsed := 0.0
	var total_distance := 0.0
	var safe_damping := maxf(linear_damping, 0.0)
	var speed_floor := maxf(stop_speed, 0.01)
	var bounded_time := maxf(max_prediction_time, safe_step)

	while elapsed < bounded_time and velocity.length() > speed_floor:
		var next_position := position + velocity * safe_step
		total_distance += position.distance_to(next_position)
		position = next_position
		raw_points.append(position)
		cumulative_distances.append(total_distance)
		velocity /= 1.0 + safe_damping * safe_step
		elapsed += safe_step

	if total_distance <= 0.001:
		return _empty_prediction(origin, initial_speed)

	var bounded_min_dots := maxi(min_dot_count, 1)
	var bounded_max_dots := maxi(max_dot_count, bounded_min_dots)
	var safe_preferred_spacing := maxf(preferred_dot_spacing, 1.0)
	var dot_count := clampi(
		ceili(total_distance / safe_preferred_spacing),
		bounded_min_dots,
		bounded_max_dots
	)
	var sampled_points := _sample_by_distance(
		raw_points,
		cumulative_distances,
		total_distance,
		dot_count
	)

	return {
		"origin": origin,
		"points": sampled_points,
		"distance": total_distance,
		"dot_spacing": total_distance / float(dot_count),
		"initial_speed": initial_speed,
		"duration": elapsed,
	}


static func _sample_by_distance(
	raw_points: PackedVector2Array,
	cumulative_distances: PackedFloat32Array,
	total_distance: float,
	dot_count: int
) -> PackedVector2Array:
	var sampled := PackedVector2Array()
	var raw_index := 1
	for dot_index in range(dot_count):
		var target_distance := total_distance * float(dot_index + 1) / float(dot_count)
		while raw_index < cumulative_distances.size() - 1 and cumulative_distances[raw_index] < target_distance:
			raw_index += 1

		var previous_index := maxi(raw_index - 1, 0)
		var segment_start_distance := float(cumulative_distances[previous_index])
		var segment_end_distance := float(cumulative_distances[raw_index])
		var segment_length := segment_end_distance - segment_start_distance
		var segment_progress := 1.0
		if segment_length > 0.001:
			segment_progress = clampf(
				(target_distance - segment_start_distance) / segment_length,
				0.0,
				1.0
			)
		sampled.append(raw_points[previous_index].lerp(raw_points[raw_index], segment_progress))
	return sampled


static func _empty_prediction(origin: Vector2, initial_speed: float) -> Dictionary:
	return {
		"origin": origin,
		"points": PackedVector2Array(),
		"distance": 0.0,
		"dot_spacing": 0.0,
		"initial_speed": initial_speed,
		"duration": 0.0,
	}
