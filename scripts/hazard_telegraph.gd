class_name HazardTelegraph
extends Node2D

var hazard_type: StringName = &"moving_hazard"
var region_size := Vector2(100.0, 100.0)
var path_points := PackedVector2Array()
var danger_color := Color("d9534f")
var cycle_duration := 2.0
var initial_phase := 0.0
var elapsed := 0.0


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
	elapsed = fmod(elapsed + delta, cycle_duration)
	queue_redraw()


func _draw() -> void:
	var phase := fposmod(elapsed / cycle_duration + initial_phase, 1.0)
	_draw_collision_silhouette()
	if path_points.size() >= 2:
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
			draw_rect(silhouette, Color(danger_color, 0.08), true)
			draw_dashed_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Color(danger_color, 0.64), 3.0, 8.0, true)
		&"rotating_lava_rod", &"rotating_fire_rod", &"pendulum", &"spike_ball":
			draw_arc(Vector2.ZERO, maxf(region_size.x, region_size.y) * 0.5, 0.0, TAU, 48, Color(danger_color, 0.2), 3.0, true)
		_:
			draw_rect(silhouette, Color(danger_color, 0.06), true)


func _draw_fall_timing(phase: float) -> void:
	var radius := lerpf(maxf(region_size.x, region_size.y) * 0.42, 8.0, phase)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(danger_color, lerpf(0.22, 0.86, phase)), 4.0, true)
	draw_line(Vector2(-region_size.x * 0.28, 0.0), Vector2(region_size.x * 0.28, 0.0), Color(danger_color, 0.72), 2.0, true)
	draw_line(Vector2(0.0, -region_size.y * 0.28), Vector2(0.0, region_size.y * 0.28), Color(danger_color, 0.72), 2.0, true)


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
