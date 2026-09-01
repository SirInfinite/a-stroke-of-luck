class_name BiomeAmbience
extends Node2D

const PARTICLE_COUNT := 24

var ambience_id: StringName = &"meadow_breeze"
var primary_color := Color.WHITE
var accent_color := Color.WHITE
var map_size := Vector2(1000.0, 600.0)
var surround_size := Vector2(2400.0, 1600.0)
var visual_seed := 1
var elapsed := 0.0


func configure(
	new_ambience_id: StringName,
	new_primary_color: Color,
	new_accent_color: Color,
	new_map_size: Vector2,
	new_surround_size: Vector2,
	new_visual_seed: int
) -> void:
	ambience_id = new_ambience_id
	primary_color = new_primary_color
	accent_color = new_accent_color
	map_size = new_map_size
	surround_size = new_surround_size
	visual_seed = maxi(absi(new_visual_seed), 1)
	z_index = -1
	queue_redraw()


func _process(delta: float) -> void:
	elapsed = fmod(elapsed + delta, 120.0)
	queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = visual_seed
	_draw_environment_layers(rng)
	for i in range(PARTICLE_COUNT):
		var point := _surround_point(rng, i)
		var phase := elapsed * (0.18 + float(i % 4) * 0.035) + float(i) * 0.71
		match ambience_id:
			&"meadow_breeze":
				_draw_pollen(point + Vector2(sin(phase) * 18.0, cos(phase * 0.7) * 7.0), i)
			&"dry_wind":
				_draw_wind_streak(point + Vector2(fmod(elapsed * 18.0 + float(i) * 13.0, 80.0), sin(phase) * 4.0), i)
			&"leaf_rustle":
				_draw_leaf(point + Vector2(sin(phase) * 24.0, fmod(elapsed * 8.0 + float(i) * 9.0, 50.0)), phase, i)
			&"winter_gust":
				_draw_snow(point + Vector2(sin(phase) * 15.0, fmod(elapsed * 7.0 + float(i) * 6.0, 45.0)), i)
			&"swamp_night":
				_draw_wisp(point + Vector2(sin(phase) * 8.0, -fmod(elapsed * 5.0 + float(i) * 4.0, 35.0)), i)
			&"volcanic_rumble":
				_draw_ember(point + Vector2(sin(phase) * 10.0, -fmod(elapsed * 11.0 + float(i) * 7.0, 60.0)), i)


func _draw_environment_layers(rng: RandomNumberGenerator) -> void:
	var half_map := map_size / 2.0
	match ambience_id:
		&"meadow_breeze":
			for side in [-1.0, 1.0]:
				var center := Vector2(side * (half_map.x + 190.0), -half_map.y * 0.18)
				draw_arc(center, 120.0, -1.2, 1.2, 24, Color(primary_color, 0.09), 5.0, true)
		&"dry_wind":
			for band in range(3):
				var y := half_map.y + 110.0 + float(band) * 42.0
				var points := PackedVector2Array()
				for point_index in range(9):
					var x := lerpf(-half_map.x - 320.0, half_map.x + 320.0, float(point_index) / 8.0)
					points.append(Vector2(x, y + sin(float(point_index) * 1.35 + float(band)) * 18.0))
				draw_polyline(points, Color(primary_color, 0.09), 6.0, true)
		&"leaf_rustle":
			for i in range(6):
				var x := rng.randf_range(-half_map.x - 280.0, half_map.x + 280.0)
				var y := (-half_map.y - 100.0) if i % 2 == 0 else (half_map.y + 100.0)
				draw_circle(Vector2(x, y), 34.0 + float(i % 3) * 12.0, Color(primary_color, 0.07))
		&"winter_gust":
			for side in [-1.0, 1.0]:
				var bank_center := Vector2(side * (half_map.x + 210.0), half_map.y * 0.35)
				draw_circle(bank_center, 95.0, Color(accent_color, 0.075))
				draw_arc(bank_center - Vector2(16.0, 8.0), 73.0, PI * 1.06, TAU * 0.94, 18, Color(primary_color.lightened(0.3), 0.1), 4.0, true)
		&"swamp_night":
			for i in range(5):
				var side := -1.0 if i % 2 == 0 else 1.0
				var center := Vector2(side * (half_map.x + 130.0 + float(i) * 26.0), rng.randf_range(-half_map.y, half_map.y))
				draw_circle(center, 24.0 + float(i % 3) * 9.0, Color(primary_color.darkened(0.15), 0.11))
				draw_arc(center, 11.0 + float(i % 2) * 5.0, 0.0, TAU, 16, Color(accent_color, 0.1), 2.0, true)
		&"volcanic_rumble":
			for side_value in [-1.0, 1.0]:
				var side := float(side_value)
				var x: float = side * (half_map.x + 160.0)
				var crack := PackedVector2Array([
					Vector2(x, -half_map.y - 220.0),
					Vector2(x - side * 24.0, -half_map.y * 0.4),
					Vector2(x + side * 18.0, half_map.y * 0.18),
					Vector2(x - side * 12.0, half_map.y + 220.0),
				])
				draw_polyline(crack, Color(accent_color, 0.13), 7.0, true)


func _surround_point(rng: RandomNumberGenerator, index: int) -> Vector2:
	var half_map := map_size / 2.0
	var half_surround := surround_size / 2.0
	match index % 4:
		0:
			return Vector2(rng.randf_range(-half_surround.x, half_surround.x), rng.randf_range(-half_surround.y, -half_map.y - 55.0))
		1:
			return Vector2(rng.randf_range(-half_surround.x, half_surround.x), rng.randf_range(half_map.y + 55.0, half_surround.y))
		2:
			return Vector2(rng.randf_range(-half_surround.x, -half_map.x - 55.0), rng.randf_range(-half_surround.y, half_surround.y))
		_:
			return Vector2(rng.randf_range(half_map.x + 55.0, half_surround.x), rng.randf_range(-half_surround.y, half_surround.y))


func _draw_pollen(point: Vector2, index: int) -> void:
	draw_circle(point, 2.0 + float(index % 3), Color(accent_color, 0.2))


func _draw_wind_streak(point: Vector2, index: int) -> void:
	var length := 24.0 + float(index % 4) * 7.0
	draw_line(point - Vector2(length, 0.0), point + Vector2(length, 0.0), Color(primary_color, 0.12), 2.0, true)


func _draw_leaf(point: Vector2, angle: float, index: int) -> void:
	var direction := Vector2.RIGHT.rotated(angle)
	var side := direction.orthogonal() * 3.0
	var length := 7.0 + float(index % 3)
	draw_colored_polygon(PackedVector2Array([point - direction * length, point + side, point + direction * length, point - side]), Color(accent_color if index % 2 == 0 else primary_color, 0.22))


func _draw_snow(point: Vector2, index: int) -> void:
	var radius := 3.0 + float(index % 3)
	var color := Color(accent_color, 0.24)
	draw_line(point - Vector2(radius, 0.0), point + Vector2(radius, 0.0), color, 1.5, true)
	draw_line(point - Vector2(0.0, radius), point + Vector2(0.0, radius), color, 1.5, true)
	draw_line(point - Vector2(radius, radius), point + Vector2(radius, radius), color, 1.0, true)


func _draw_wisp(point: Vector2, index: int) -> void:
	var radius := 5.0 + float(index % 4) * 1.5
	draw_arc(point, radius, PI, TAU, 10, Color(accent_color, 0.16), 2.0, true)
	if index % 4 == 0:
		draw_circle(point + Vector2(0.0, 5.0), radius * 0.34, Color(primary_color, 0.12))


func _draw_ember(point: Vector2, index: int) -> void:
	var radius := 2.0 + float(index % 3)
	draw_circle(point, radius * 2.0, Color(primary_color, 0.07))
	draw_circle(point, radius, Color(accent_color, 0.3))
