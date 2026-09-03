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
			var shadow_points := _ellipse_points(Vector2(half.x * 0.82, half.y * 0.48), 36)
			draw_colored_polygon(shadow_points, Color("171a21") if fall_triggered else Color(0.07, 0.08, 0.1, 0.72))
			draw_polyline(shadow_points, Color(danger_color, 0.78), 3.0, true)
		&"rotating_lava_rod", &"rotating_fire_rod", &"pendulum", &"spike_ball":
			draw_arc(Vector2.ZERO, maxf(region_size.x, region_size.y) * 0.5, 0.0, TAU, 48, Color(danger_color, 0.2), 3.0, true)
		_:
			draw_rect(silhouette, Color(danger_color, 0.06), true)


func _draw_fall_timing(phase: float) -> void:
	var warning_phase := phase if fall_triggered else (sin(elapsed * 2.4) + 1.0) * 0.5
	var radius := lerpf(maxf(region_size.x, region_size.y) * 0.56, maxf(region_size.x, region_size.y) * 0.42, warning_phase)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, Color(danger_color, lerpf(0.3, 0.92, warning_phase)), 3.0, true)
	if fall_triggered and phase >= 0.82:
		draw_arc(Vector2.ZERO, radius + 7.0, 0.0, TAU, 36, Color("f7fbff"), 3.0, true)


func _draw_rotation_timing(phase: float) -> void:
	var radius := maxf(region_size.x, region_size.y) * 0.5
	var direction := Vector2.RIGHT.rotated(phase * TAU)
	draw_line(Vector2.ZERO, direction * radius, Color(danger_color, 0.72), 4.0, true)
	draw_circle(direction * radius, 6.0, Color(danger_color, 0.86))


func _draw_pendulum_timing(phase: float) -> void:
	if path_points.size() < 2:
		return
	var swing := (sin(phase * TAU - PI * 0.5) + 1.0) * 0.5
	var marker := path_points[0].lerp(path_points[-1], swing)
	draw_circle(Vector2.ZERO, 6.0, Color(danger_color, 0.86))
	draw_line(Vector2.ZERO, marker, Color("252a2c"), 4.0, true)
	draw_circle(marker, 7.0, Color(danger_color, 0.82))
	draw_circle(marker, 11.0, Color(danger_color, 0.18))


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
