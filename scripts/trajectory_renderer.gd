class_name TrajectoryRenderer
extends Node2D

const CourseVisualFactory := preload("res://scripts/course_visual_factory.gd")

@export_range(1.5, 6.0, 0.25) var dot_radius := 2.75
@export_range(0.5, 4.0, 0.25) var backing_width := 1.5

var prediction_points := PackedVector2Array()
var prediction_power := 0.0
var primary_color := Color("f4f0e6", 0.86)
var backing_color := Color("252a2c", 0.58)
var halo_color := Color("252a2c", 0.22)


func _ready() -> void:
	set_as_top_level(true)
	z_index = 20


func configure_level(level: Dictionary) -> void:
	var style := CourseVisualFactory.trajectory_style(
		level.get("terrain_palette", {}),
		level.get("background_palette", {})
	)
	primary_color = style.primary
	backing_color = style.backing
	halo_color = style.halo
	queue_redraw()


func set_prediction(points: PackedVector2Array, power: float) -> void:
	prediction_points = points
	prediction_power = clampf(power, 0.0, 1.0)
	visible = not prediction_points.is_empty()
	queue_redraw()


func set_prediction_data(prediction: Dictionary) -> void:
	if prediction.is_empty():
		clear_prediction()
		return
	var points: PackedVector2Array = prediction.get("points", PackedVector2Array())
	var display_power := clampf(float(prediction.get("power", 0.0)), 0.0, 1.0)
	set_prediction(points, display_power)


func clear_prediction() -> void:
	prediction_points = PackedVector2Array()
	prediction_power = 0.0
	visible = false
	queue_redraw()


func _draw() -> void:
	if prediction_points.is_empty():
		return
	var point_count := prediction_points.size()
	for index in range(point_count):
		var fade := lerpf(1.0, 0.38, float(index) / float(maxi(point_count - 1, 1)))
		var scale_factor := lerpf(1.12, 0.74, float(index) / float(maxi(point_count - 1, 1)))
		var radius := dot_radius * scale_factor
		draw_circle(prediction_points[index], radius + backing_width, Color(backing_color, backing_color.a * fade))
		draw_circle(prediction_points[index], radius, Color(primary_color, primary_color.a * fade))

	var target := prediction_points[-1]
	draw_circle(target, dot_radius * 3.0 + backing_width, Color(halo_color, halo_color.a * 0.72), false, 2.0, true)
	if point_count >= 2:
		var direction := (prediction_points[-1] - prediction_points[-2]).normalized()
		if not direction.is_zero_approx():
			var side := direction.orthogonal() * 5.0
			var tip := target + direction * 10.0
			var arrow := PackedVector2Array([tip, target - direction * 5.0 - side, target - direction * 5.0 + side])
			draw_colored_polygon(arrow, primary_color)
