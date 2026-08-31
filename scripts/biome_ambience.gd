class_name BiomeAmbience
extends Node2D

const PARTICLE_COUNT := 16

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


func _draw_wisp(point: Vector2, index: int) -> void:
	var radius := 5.0 + float(index % 4) * 1.5
	draw_arc(point, radius, PI, TAU, 10, Color(accent_color, 0.16), 2.0, true)


func _draw_ember(point: Vector2, index: int) -> void:
	var radius := 2.0 + float(index % 3)
	draw_circle(point, radius * 2.0, Color(primary_color, 0.07))
	draw_circle(point, radius, Color(accent_color, 0.3))
