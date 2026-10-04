class_name AICourseModel
extends RefCounted
## Query-only body: never moves the real ball or participates in collisions.
## Static contacts use the same BallMotion solver as the player preview/CCD.
var query_body := RID()
var query_shape := RID()
var level: Dictionary
var surfaces: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var movers: Array[Dictionary] = []
var ramps: Array[Dictionary] = []
var cells: Dictionary = {}
var distances: Dictionary = {}
var offset := Vector2.ZERO
var cup := Vector2.ZERO
var cup_elevation := 0
var cup_radius := 28.0
var params: Dictionary = {}


func configure(builder: LevelBuilder, ball: RigidBody2D, state: RunState) -> void:
	dispose()
	cells.clear()
	ramps.clear()
	level = builder.active_level.duplicate(true)
	cup = builder.level_point(level, "hole", "hole_cell")
	cup_elevation = int(level.get("hole_elevation", 0))
	cup_radius = float(level.get("cup_radius", 28.0))
	offset = builder.level_point(level, "start", "start_cell") - Vector2(level.start_cell) * 100.0
	for cell: Vector2i in builder.elevation_lookup:
		for elevation: int in builder.elevation_lookup[cell]:
			cells[Vector3i(cell.x, cell.y, elevation)] = true
	for node in builder.level_root.get_children():
		if node is ElevationRamp:
			ramps.append(node.get_presentation_data())
	query_shape = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(query_shape, ball.get_collision_radius())
	query_body = PhysicsServer2D.body_create()
	PhysicsServer2D.body_set_mode(query_body, PhysicsServer2D.BODY_MODE_KINEMATIC)
	PhysicsServer2D.body_add_shape(query_body, query_shape)
	PhysicsServer2D.body_set_collision_layer(query_body, 0)
	PhysicsServer2D.body_set_space(query_body, ball.get_world_2d().space)
	PhysicsServer2D.body_set_state(query_body, PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, Vector2(1000000, 1000000)))
	refresh(builder, ball, state)
	_build_distances()


func dispose() -> void:
	if query_body.is_valid():
		PhysicsServer2D.free_rid(query_body)
		query_body = RID()
	if query_shape.is_valid():
		PhysicsServer2D.free_rid(query_shape)
		query_shape = RID()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if query_body.is_valid():
			PhysicsServer2D.free_rid(query_body)
		if query_shape.is_valid():
			PhysicsServer2D.free_rid(query_shape)


func refresh(builder: LevelBuilder, ball: RigidBody2D, state: RunState) -> void:
	params = ball.shot_parameters()
	params["power_control"] = state.drag_modifier
	params["wind_force"] = 950.0 * state.direction_push_modifier
	surfaces.clear()
	hazards.clear()
	movers.clear()
	for definition: Dictionary in level.hazards:
		var item := definition.duplicate(true)
		item["rect"] = Rect2(Vector2(item.pos) - Vector2(item.size) * 0.5, item.size)
		hazards.append(item)
		if item.type in ["sand", "ice"]:
			item["intensity"] = float(item.get("intensity", 1.0))
			item["elevation"] = int(item.get("elevation", 0))
			surfaces.append(item)
	for node in builder.level_root.get_children():
		if node is MovingHazard:
			movers.append({"type": node.hazard_type, "origin": node.origin, "elapsed": node.elapsed,
				"period": node.period, "radius": node.travel_radius, "swing": node.swing_angle,
				"angular_speed": node.angular_speed, "elevation": node.elevation,
				"size": Vector2(node.collision_shape.shape.radius * 2.0, node.collision_shape.shape.radius * 2.0) if node.collision_shape.shape is CircleShape2D else node.collision_shape.shape.size,
				"fall_state": node.fall_state, "telegraph": node.telegraph_duration, "fall_elapsed": node.fall_elapsed})
		elif node is GameplayHazard and node.hazard_type == &"bounce_pad":
			for item in hazards:
				if item.type == "bounce_pad" and Vector2(item.pos).is_equal_approx(node.position):
					item["trigger_index"] = node._trigger_count


func predict(origin: Vector2, elevation: int, direction: Vector2, power: float, delay := 0.0, step := 1.0 / 30.0) -> Dictionary:
	var position := origin
	var velocity := direction.normalized() * clampf(power, 0.0, 1.0) * float(params.max_impulse) / float(params.mass)
	var elapsed := 0.0
	var stopped := 0
	var bounces := 0
	var danger := 0.0
	var reset := false
	var sunk := false
	var points := PackedVector2Array([origin])
	var pad_counts := {}
	var fall_times := {}
	var terrain := {"surfaces": surfaces, "elevation": elevation, "radius": params.radius,
		"normal_damp": params.normal_damp, "sand_damp": params.sand_damp,
		"sand_entry_scale": params.sand_entry_scale, "world_damp": params.world_damp}
	var pending := TrajectoryPredictor._surface_state(position, terrain, float(params.normal_damp))
	var previous: Dictionary = pending.sources
	for tick in 1800:
		terrain.elevation = elevation
		var surface := pending
		pending = TrajectoryPredictor._surface_state(position, terrain, float(params.normal_damp))
		for source in surface.sand:
			if not previous.has(source):
				velocity *= float(params.sand_entry_scale)
		previous = surface.sources
		for item in hazards:
			if item.type == "direction" and int(item.get("elevation", 0)) == elevation and Rect2(item.rect).grow(float(params.radius)).has_point(position):
				velocity += Vector2(item.direction).normalized() * float(params.wind_force) / float(params.mass) * step
		velocity = BallMotion.damp_velocity(velocity, float(surface.damping), step)
		PhysicsServer2D.body_set_collision_mask(query_body, 1 << (elevation + 5))
		var swept := BallMotion.sweep(query_body, Transform2D(0.0, position), velocity, step, float(params.bounce), float(params.friction))
		var next: Vector2 = swept.position
		velocity = swept.velocity
		bounces += swept.contacts.size()
		if elevation == cup_elevation and Geometry2D.get_closest_point_to_segment(cup, position, next).distance_to(cup) < cup_radius + float(params.radius) - 2.0:
			position = cup
			sunk = true
			break
		for item in hazards:
			if int(item.get("elevation", 0)) != elevation:
				continue
			if item.type in ["water", "lava"] and _segment_rect(position, next, Rect2(item.rect).grow(float(params.radius) - 1.0)):
				reset = true
			if item.type == "bounce_pad" and not pad_counts.has(item.pos):
				var pad_radius := minf(Vector2(item.size).x, Vector2(item.size).y) * 0.5
				if Geometry2D.get_closest_point_to_segment(item.pos, position, next).distance_to(item.pos) <= pad_radius + float(params.radius):
					velocity = GameplayHazard.deterministic_bounce_velocity(velocity, int(item.get("seed", 1)), int(item.get("trigger_index", 0)), float(item.get("speed_multiplier", 1.15)), float(item.get("minimum_exit_speed", 650.0)), float(item.get("maximum_exit_speed", 1450.0)))
					next = Vector2(item.pos) + velocity.normalized() * (pad_radius + float(params.radius) + 2.0)
					pad_counts[item.pos] = true
		for index in movers.size():
			var moving: Dictionary = movers[index]
			if int(moving.elevation) != elevation:
				continue
			var time := float(moving.elapsed) + delay + elapsed
			if moving.type == &"pendulum":
				var first := MovingHazard.pendulum_transform(moving.origin, moving.radius, moving.swing, moving.period, time)
				var last := MovingHazard.pendulum_transform(moving.origin, moving.radius, moving.swing, moving.period, time + step)
				if MovingHazard.relative_contact_fraction(position, next, first.origin, last.origin, float(params.radius) + Vector2(moving.size).x * 0.5) >= 0.0:
					reset = true
			elif moving.type == &"rotating_fire_rod":
				var local := (next - Vector2(moving.origin)).rotated(-time * float(moving.angular_speed))
				if Rect2(-Vector2(moving.size) * 0.5, moving.size).grow(float(params.radius)).has_point(local):
					reset = true
			elif moving.type == &"falling_ice" and Rect2(Vector2(moving.origin) - Vector2(50, 50), Vector2(100, 100)).grow(float(params.radius)).has_point(next):
				if not fall_times.has(index):
					fall_times[index] = elapsed if moving.fall_state == &"armed" else -float(moving.fall_elapsed)
				if moving.fall_state != &"landed" and elapsed - float(fall_times[index]) >= float(moving.telegraph):
					reset = true
		for ramp in ramps:
			if elevation not in [int(ramp.from_elevation), int(ramp.to_elevation)]:
				continue
			var vector: Vector2 = ramp.to_position - ramp.from_position
			var progress := (next - Vector2(ramp.from_position)).dot(vector) / maxf(vector.length_squared(), 1.0)
			var lateral := absf((next - Vector2(ramp.from_position)).cross(vector.normalized()))
			if progress >= 0.0 and progress <= 1.0 and lateral < float(ramp.width) * 0.5 + float(params.radius):
				elevation = ElevationRamp.elevation_for_progress(progress, int(ramp.from_elevation), int(ramp.to_elevation))
		position = next
		elapsed += step
		if tick % 3 == 0:
			points.append(position)
		stopped = stopped + 1 if velocity.length() <= float(params.stop_speed) else 0
		if reset or stopped >= int(params.stop_frames):
			break
	if not cells.has(cell_at(position, elevation)):
		reset = true
	if not pending.sand.is_empty():
		danger += 0.12
	points.append(position)
	return {"endpoint": position, "elevation": elevation, "points": points, "reset": reset,
		"sunk": sunk, "danger": danger, "bounces": bounces, "pads": pad_counts.size(), "duration": elapsed,
		"complete": stopped >= int(params.stop_frames) or sunk or reset}


func cell_at(position: Vector2, elevation: int) -> Vector3i:
	var cell := Vector2i(((position - offset) / 100.0 + Vector2(0.5, 0.5)).floor())
	return Vector3i(cell.x, cell.y, elevation)


func world_at(cell: Vector3i) -> Vector2:
	return offset + Vector2(cell.x, cell.y) * 100.0


func remaining_distance(position: Vector2, elevation: int) -> float:
	var key := cell_at(position, elevation)
	if not distances.has(key):
		return 100000.0
	if elevation == cup_elevation and position.distance_to(cup) < 110.0:
		return position.distance_to(cup)
	var best := float(distances[key]) + position.distance_to(world_at(key))
	for neighbor: Vector3i in _neighbors(key):
		if distances.has(neighbor) and float(distances[neighbor]) < float(distances[key]):
			best = minf(best, float(distances[neighbor]) + position.distance_to(world_at(neighbor)))
	return best


func targets(origin: Vector2, elevation: int) -> Array[Vector2]:
	var result: Array[Vector2] = [cup]
	var key := cell_at(origin, elevation)
	var previous := key
	var previous_direction := Vector3i.ZERO
	for index in 24:
		var best := key
		for neighbor in _neighbors(key):
			if float(distances.get(neighbor, INF)) < float(distances.get(best, INF)):
				best = neighbor
		if best == key:
			break
		var direction := best - key
		if direction != previous_direction and index > 0:
			result.append(world_at(key))
		if index in [1, 4, 8, 12]:
			result.append(world_at(best))
		previous = key
		key = best
		previous_direction = key - previous
	return result


func _build_distances() -> void:
	distances.clear()
	var target := cell_at(cup, cup_elevation)
	distances[target] = 0.0
	var pending: Array[Vector3i] = [target]
	while not pending.is_empty():
		var best_index := 0
		for index in range(1, pending.size()):
			if float(distances[pending[index]]) < float(distances[pending[best_index]]):
				best_index = index
		var key: Vector3i = pending.pop_at(best_index)
		for neighbor in _neighbors(key):
			var cost := 100.0
			for item in hazards:
				if int(item.get("elevation", 0)) == neighbor.z and Rect2(item.rect).has_point(world_at(neighbor)):
					cost += 1500.0 if item.type in ["water", "lava"] else 100.0 if item.type == "sand" else 15.0
			for obstacle: Dictionary in level.obstacles:
				if int(obstacle.get("elevation", 0)) == neighbor.z and Rect2(Vector2(obstacle.pos) - Vector2(obstacle.size) * 0.5, obstacle.size).has_point(world_at(neighbor)):
					cost += 1200.0
			var distance := float(distances[key]) + cost
			if distance < float(distances.get(neighbor, INF)):
				distances[neighbor] = distance
				if not pending.has(neighbor):
					pending.append(neighbor)


func _neighbors(key: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for direction in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0)]:
		if cells.has(key + direction):
			result.append(key + direction)
	for ramp in ramps:
		var first := cell_at(ramp.from_position, int(ramp.from_elevation))
		var second := cell_at(ramp.to_position, int(ramp.to_elevation))
		if key == first:
			result.append(second)
		elif key == second:
			result.append(first)
	return result


static func _segment_rect(first: Vector2, second: Vector2, rect: Rect2) -> bool:
	if rect.has_point(first) or rect.has_point(second):
		return true
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for index in 4:
		if Geometry2D.segment_intersects_segment(first, second, corners[index], corners[(index + 1) % 4]) != null:
			return true
	return false
