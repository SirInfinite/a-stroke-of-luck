class_name HazardTelegraph
extends Node2D

var hazard_type: StringName = &"moving_hazard"
var region_size := Vector2(100.0, 100.0)
var path_points := PackedVector2Array()
var danger_color := Color("d9534f")
var cycle_duration := 2.0
var initial_phase := 0.0
var elapsed := 0.0
var fall_triggered := false
var _hazard_ref: WeakRef


func follow_hazard(hazard: Node2D) -> void:
	_hazard_ref = weakref(hazard)


func configure(
	new_hazard_type: StringName,
	new_region_size: Vector2,
	new_path_points: PackedVector2Array,
	new_danger_color: Color,
	new_cycle_duration: float,
	new_initial_phase: float = 0.0
) -> void:
	hazard_type = new_hazard_type
	region_size = new_region_size
	path_points = new_path_points
	danger_color = new_danger_color
	cycle_duration = maxf(new_cycle_duration, 0.2)
	initial_phase = fposmod(new_initial_phase, 1.0)
	set_meta("hazard_type", hazard_type)
	set_meta("cycle_duration", cycle_duration)
	queue_redraw()


func _process(delta: float) -> void:
	if hazard_type == &"falling_ice" and _hazard_ref:
		var hazard := _hazard_ref.get_ref() as MovingHazard
		if hazard and hazard.fall_state == MovingHazard.FALL_LANDED:
			visible = false
			return
		visible = true
		if hazard and hazard.fall_state == MovingHazard.FALL_ARMED:
			fall_triggered = false
	if hazard_type == &"falling_ice" and fall_triggered:
		elapsed = minf(elapsed + delta, cycle_duration)
	else:
		elapsed = fmod(elapsed + delta, cycle_duration)
	queue_redraw()


func trigger_drop(_data: Dictionary = {}) -> void:
	if hazard_type != &"falling_ice":
		return
	fall_triggered = true
	elapsed = 0.0
	queue_redraw()


func reset_for_competitor() -> void:
	elapsed = 0.0
	fall_triggered = false
	visible = true
	queue_redraw()


func _draw() -> void:
	var phase := fposmod(elapsed / cycle_duration + initial_phase, 1.0)
	_draw_collision_silhouette()
	if hazard_type != &"falling_ice" and path_points.size() >= 2:
		draw_polyline(path_points, Color(danger_color, 0.34), 4.0, true)
	match hazard_type:
		&"falling_ice":
			_draw_fall_timing(phase)
		&"rotating_lava_rod", &"rotating_fire_rod":
			_draw_rotation_timing(phase)
		&"pendulum", &"spike_ball":
			_draw_pendulum_timing(phase)
		&"fireball":
			_draw_travel_timing(phase)
		_:
			_draw_travel_timing(phase)


func _draw_collision_silhouette() -> void:
	var half := region_size / 2.0
	var silhouette := Rect2(-half, region_size)
	match hazard_type:
		&"falling_ice":
			draw_rect(silhouette, Color(0.07, 0.08, 0.1, 0.60), true)
			draw_rect(silhouette.grow(-1.5), Color(danger_color, 0.78), false, 3.0)
		&"rotating_lava_rod", &"rotating_fire_rod", &"pendulum", &"spike_ball":
			draw_arc(Vector2.ZERO, maxf(region_size.x, region_size.y) * 0.5, 0.0, TAU, 48, Color(danger_color, 0.2), 3.0, true)
		_:
			draw_rect(silhouette, Color(danger_color, 0.06), true)


func _draw_fall_timing(phase: float) -> void:
	var warning_phase := phase if fall_triggered else (sin(elapsed * 2.4) + 1.0) * 0.5
	var inset := lerpf(12.0, 3.0, warning_phase)
	draw_rect(Rect2(-region_size * 0.5, region_size).grow(-inset), Color(danger_color, lerpf(0.3, 0.92, warning_phase)), false, 2.0)


func _draw_rotation_timing(phase: float) -> void:
	var radius := maxf(region_size.x, region_size.y) * 0.5
	var direction := Vector2.RIGHT.rotated(phase * TAU)
	draw_line(Vector2.ZERO, direction * radius, Color(danger_color, 0.72), 4.0, true)
	draw_circle(direction * radius, 6.0, Color(danger_color, 0.86))


func _draw_pendulum_timing(_phase: float) -> void:
	var hazard := _hazard_ref.get_ref() as Node2D if _hazard_ref else null
	if not hazard:
		return
	var marker := to_local(hazard.global_position)
	draw_line(Vector2.ZERO, marker, Color("252a2c"), 5.0, true)
	draw_line(Vector2.ZERO, marker, Color("9b9e92"), 1.5, true)
	draw_circle(Vector2.ZERO, 7.0, Color("252a2c"))
	draw_circle(Vector2.ZERO, 3.0, Color("c8c8b9"))


func _draw_travel_timing(phase: float) -> void:
	if path_points.size() < 2:
		return
	var marker := path_points[0].lerp(path_points[-1], phase)
	var direction := (path_points[-1] - path_points[0]).normalized()
	var side := direction.orthogonal() * 6.0
	draw_colored_polygon(PackedVector2Array([
		marker + direction * 10.0,
		marker - direction * 8.0 - side,
		marker - direction * 8.0 + side,
	]), Color(danger_color, 0.82))


func _ellipse_points(radii: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(segments):
		var angle := TAU * float(point_index) / float(segments)
		points.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	points.append(points[0])
	return points
