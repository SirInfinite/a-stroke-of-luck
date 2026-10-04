class_name TrajectoryPredictor
extends RefCounted

const DEFAULT_PHYSICS_STEP := 1.0 / 60.0
const DEFAULT_MAX_PREDICTION_TIME := 8.0
const DEFAULT_MIN_DOT_COUNT := 2
const DEFAULT_MAX_DOT_COUNT := 24
const DEFAULT_PREFERRED_DOT_SPACING := 56.0
const ASSUMPTIONS := "Straight-line resting point with known sand/ice. Walls, hazards, ramps, wind and pads interrupt this line; ricochets are not shown."


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
	max_prediction_time := DEFAULT_MAX_PREDICTION_TIME,
	body := RID(),
	stopped_frames_required := 8,
	bounce := 0.35,
	friction := 0.4,
	terrain: Dictionary = {}
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
	var stopped_frames := 0
	var pending_surface := _surface_state(position, terrain, safe_damping)
	var previous_surfaces: Dictionary = pending_surface.sources

	while elapsed < bounded_time and stopped_frames < stopped_frames_required:
		if not terrain.is_empty():
			# Area2D enter/exit notifications consume the preceding physics broad
			# phase. Match that one-step delay, especially sand's entry impulse.
			var surface := pending_surface
			pending_surface = _surface_state(position, terrain, safe_damping)
			for id in surface.sand:
				if not previous_surfaces.has(id):
					velocity *= float(terrain.sand_entry_scale)
			previous_surfaces = surface.sources
			safe_damping = surface.damping
		velocity = BallMotion.damp_velocity(velocity, safe_damping, safe_step)
		var next_position := position + velocity * safe_step
		if body.is_valid():
			var swept := BallMotion.sweep(body, Transform2D(0.0, position), velocity, safe_step, bounce, friction)
			for contact_position: Vector2 in swept.points:
				total_distance += position.distance_to(contact_position)
				position = contact_position
				raw_points.append(position)
				cumulative_distances.append(total_distance)
			next_position = swept.position
			velocity = swept.velocity
		total_distance += position.distance_to(next_position)
		position = next_position
		raw_points.append(position)
		cumulative_distances.append(total_distance)
		stopped_frames = stopped_frames + 1 if velocity.length() <= speed_floor else 0
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
		"endpoint": position,
		"complete": stopped_frames >= stopped_frames_required,
		"assumptions": ASSUMPTIONS,
	}

static func _surface_state(position: Vector2, terrain: Dictionary, fallback_damping: float) -> Dictionary:
	var sources := {}
	var sand: Array[int] = []
	var ice_scale := 1.0
	var surfaces: Array = terrain.get("surfaces", [])
	for index in range(surfaces.size()):
		var surface: Dictionary = surfaces[index]
		if surface.elevation != int(terrain.elevation):
			continue
		var rect: Rect2 = surface.rect
		var nearest := position.clamp(rect.position, rect.end)
		if position.distance_squared_to(nearest) > pow(float(terrain.radius), 2):
			continue
		sources[index] = true
		if surface.type == "sand":
			sand.append(index)
		elif surface.type == "ice":
			ice_scale = minf(ice_scale, clampf(float(surface.intensity), 0.05, 1.0))
	var damping := fallback_damping
	if not terrain.is_empty():
		damping = (maxf(float(terrain.sand_damp), float(terrain.normal_damp)) if not sand.is_empty() else float(terrain.normal_damp) * ice_scale) + float(terrain.world_damp)
	return {"sources": sources, "sand": sand, "damping": damping}


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
		"endpoint": origin, "complete": true,
	}
