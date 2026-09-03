class_name BiomeAmbience
extends Node2D

const PARTICLE_COUNT := 40
const STATIC_DETAIL_COUNT := 64

var ambience_id: StringName = &"meadow_breeze"
var primary_color := Color.WHITE
var accent_color := Color.WHITE
var map_size := Vector2(1000.0, 600.0)
var surround_size := Vector2(7600.0, 4600.0)
var visual_seed := 1
var elapsed := 0.0
var static_details: Array[Dictionary] = []
var particles: Array[Dictionary] = []


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
	_build_layout()
	queue_redraw()


func _process(delta: float) -> void:
	elapsed = fmod(elapsed + delta, 240.0)
	queue_redraw()


func _draw() -> void:
	_draw_environment_base()
	for detail_index in range(static_details.size()):
		_draw_static_detail(static_details[detail_index], detail_index)
	for particle_index in range(particles.size()):
		_draw_particle(particles[particle_index], particle_index)


func _build_layout() -> void:
	static_details.clear()
	particles.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = visual_seed
	for detail_index in range(STATIC_DETAIL_COUNT):
		static_details.append({
			"position": _surround_point(rng, detail_index, 85.0),
			"scale": rng.randf_range(0.72, 1.35),
			"rotation": rng.randf_range(-0.22, 0.22),
			"variant": rng.randi_range(0, 7),
		})
	for particle_index in range(PARTICLE_COUNT):
		var speed := rng.randf_range(18.0, 54.0)
		var direction := Vector2.RIGHT.rotated(rng.randf_range(-0.45, 0.45))
		if ambience_id in [&"leaf_rustle", &"winter_gust"]:
			direction = Vector2(rng.randf_range(-0.35, 0.35), 1.0).normalized()
		elif ambience_id in [&"swamp_night", &"volcanic_rumble"]:
			direction = Vector2(rng.randf_range(-0.28, 0.28), -1.0).normalized()
		particles.append({
			"position": _surround_point(rng, particle_index + 101, 55.0),
			"velocity": direction * speed,
			"duration": rng.randf_range(5.5, 13.0),
			"phase": rng.randf_range(0.0, 17.0),
			"scale": rng.randf_range(0.72, 1.28),
		})


func _draw_environment_base() -> void:
	var half_map := map_size * 0.5
	match ambience_id:
		&"meadow_breeze":
			for side in [-1.0, 1.0]:
				_draw_ellipse(Vector2(side * (half_map.x + 340.0), -half_map.y * 0.18), Vector2(210.0, 118.0), Color("315f7a", 0.28))
				_draw_ellipse(Vector2(side * (half_map.x + 318.0), -half_map.y * 0.22), Vector2(154.0, 78.0), Color("5fa6b0", 0.15))
		&"dry_wind":
			for band in range(4):
				var y := half_map.y + 110.0 + float(band) * 56.0
				var points := PackedVector2Array()
				for point_index in range(11):
					var x := lerpf(-half_map.x - 720.0, half_map.x + 720.0, float(point_index) / 10.0)
					points.append(Vector2(x, y + sin(float(point_index) * 1.18 + float(band)) * 22.0))
				draw_polyline(points, Color(primary_color, 0.12), 9.0, true)
		&"leaf_rustle":
			for side in [-1.0, 1.0]:
				_draw_ellipse(Vector2(side * (half_map.x + 420.0), half_map.y + 210.0), Vector2(430.0, 115.0), Color(primary_color, 0.11))
		&"winter_gust":
			for side in [-1.0, 1.0]:
				var bank_center := Vector2(side * (half_map.x + 330.0), half_map.y * 0.28)
				_draw_ellipse(bank_center, Vector2(260.0, 130.0), Color(accent_color, 0.13))
				draw_arc(bank_center - Vector2(16.0, 8.0), 92.0, PI * 1.05, TAU * 0.94, 24, Color(primary_color.lightened(0.36), 0.16), 5.0, true)
		&"swamp_night":
			for side in [-1.0, 1.0]:
				_draw_ellipse(Vector2(side * (half_map.x + 300.0), half_map.y * 0.12), Vector2(310.0, 150.0), Color(primary_color.darkened(0.18), 0.2))
				_draw_ellipse(Vector2(side * (half_map.x + 286.0), half_map.y * 0.09), Vector2(225.0, 93.0), Color(accent_color, 0.08))
		&"volcanic_rumble":
			for side in [-1.0, 1.0]:
				var pool := Vector2(side * (half_map.x + 360.0), half_map.y * 0.24)
				_draw_ellipse(pool, Vector2(240.0, 118.0), Color("170f12", 0.46))
				_draw_ellipse(pool, Vector2(182.0, 71.0), Color(accent_color, 0.18))


func _draw_static_detail(detail: Dictionary, index: int) -> void:
	var point: Vector2 = detail.position
	var scale_value := float(detail.scale)
	var variant := int(detail.variant)
	match ambience_id:
		&"meadow_breeze":
			match variant % 6:
				0: _draw_meadow_tree(point, scale_value)
				1: _draw_meadow_bush(point, scale_value)
				2: _draw_lily_flower(point, scale_value, index % 4 == 0)
				3: _draw_flower_cluster(point, scale_value)
				4: _draw_grass_tuft(point, scale_value)
				_: _draw_meadow_frog(point, scale_value)
		&"dry_wind":
			match variant % 5:
				0: _draw_cactus(point, scale_value, index % 3 == 0)
				1: _draw_rock_mound(point, scale_value, Color(primary_color.darkened(0.22), 0.42))
				2: _draw_tumbleweed(point, scale_value, float(detail.rotation))
				_: _draw_sand_ripple(point, scale_value)
		&"leaf_rustle":
			if variant % 3 == 0:
				_draw_autumn_tree(point, scale_value, index % 11 == 0)
			else:
				_draw_ground_leaves(point, scale_value, variant)
		&"winter_gust":
			match variant % 5:
				0: _draw_penguin(point, scale_value)
				1: _draw_ice_formation(point, scale_value)
				_: _draw_snowbank(point, scale_value)
		&"swamp_night":
			match variant % 4:
				0: _draw_reeds(point, scale_value)
				1: _draw_swamp_plant(point, scale_value)
				_: _draw_swamp_bubbles(point, scale_value)
		&"volcanic_rumble":
			match variant % 4:
				0: _draw_lava_crack(point, scale_value, float(detail.rotation))
				1: _draw_rock_mound(point, scale_value, Color("171318", 0.72))
				_: _draw_lava_vent(point, scale_value)


func _draw_particle(particle: Dictionary, index: int) -> void:
	var duration := float(particle.duration)
	var life := fmod(elapsed + float(particle.phase), duration) / duration
	var alpha := smoothstep(0.0, 0.14, life) * (1.0 - smoothstep(0.76, 1.0, life))
	var point: Vector2 = Vector2(particle.position) + Vector2(particle.velocity) * (life * duration)
	point += Vector2(sin((elapsed + float(index)) * 1.7) * 12.0, cos((elapsed + float(index)) * 1.1) * 5.0)
	var scale_value := float(particle.scale)
	match ambience_id:
		&"meadow_breeze": _draw_pollen(point, scale_value, alpha)
		&"dry_wind": _draw_wind_streak(point, scale_value, alpha)
		&"leaf_rustle": _draw_leaf(point, elapsed + float(index), scale_value, alpha)
		&"winter_gust": _draw_snow(point, scale_value, alpha)
		&"swamp_night": _draw_wisp(point, scale_value, alpha)
		&"volcanic_rumble": _draw_ember(point, scale_value, alpha)


func _surround_point(rng: RandomNumberGenerator, index: int, clearance: float) -> Vector2:
	var half_map := map_size * 0.5
	var half_surround := surround_size * 0.5
	var horizontal_reach := minf(half_surround.x - 80.0, half_map.x + 1380.0)
	var vertical_reach := minf(half_surround.y - 80.0, half_map.y + 980.0)
	match index % 4:
		0:
			return Vector2(rng.randf_range(-horizontal_reach, horizontal_reach), rng.randf_range(-vertical_reach, -half_map.y - clearance))
		1:
			return Vector2(rng.randf_range(-horizontal_reach, horizontal_reach), rng.randf_range(half_map.y + clearance, vertical_reach))
		2:
			return Vector2(rng.randf_range(-horizontal_reach, -half_map.x - clearance), rng.randf_range(-vertical_reach, vertical_reach))
		_:
			return Vector2(rng.randf_range(half_map.x + clearance, horizontal_reach), rng.randf_range(-vertical_reach, vertical_reach))


func _draw_meadow_tree(point: Vector2, scale_value: float) -> void:
	draw_line(point + Vector2(0, 12) * scale_value, point + Vector2(0, -36) * scale_value, Color("342a22", 0.5), 9.0 * scale_value, true)
	draw_circle(point + Vector2(-14, -39) * scale_value, 24.0 * scale_value, Color(primary_color.darkened(0.18), 0.42))
	draw_circle(point + Vector2(15, -43) * scale_value, 27.0 * scale_value, Color(primary_color, 0.43))
	draw_circle(point + Vector2(0, -61) * scale_value, 24.0 * scale_value, Color(primary_color.lightened(0.08), 0.4))


func _draw_meadow_bush(point: Vector2, scale_value: float) -> void:
	for offset in [Vector2(-16, 2), Vector2(0, -8), Vector2(17, 2)]:
		draw_circle(point + offset * scale_value, 19.0 * scale_value, Color(primary_color.darkened(0.12), 0.38))
	for berry in [Vector2(-12, -4), Vector2(7, -10), Vector2(18, 5)]:
		draw_circle(point + berry * scale_value, 2.5 * scale_value, Color(accent_color, 0.46))


func _draw_lily_flower(point: Vector2, scale_value: float, frog: bool) -> void:
	_draw_ellipse(point, Vector2(20.0, 10.0) * scale_value, Color("568a60", 0.45))
	for petal_index in range(5):
		var petal := point + Vector2.RIGHT.rotated(TAU * float(petal_index) / 5.0) * 6.0 * scale_value
		draw_circle(petal, 4.0 * scale_value, Color("ed8dad", 0.52))
	if frog:
		draw_circle(point + Vector2(11, -8) * scale_value, 6.0 * scale_value, Color("6faa63", 0.58))
		draw_circle(point + Vector2(8, -13) * scale_value, 1.4 * scale_value, Color("141a15", 0.8))


func _draw_flower_cluster(point: Vector2, scale_value: float) -> void:
	for flower_index in range(5):
		var offset := Vector2(float((flower_index * 13) % 31) - 15.0, float((flower_index * 9) % 19) - 9.0) * scale_value
		draw_circle(point + offset, 3.2 * scale_value, Color("ef91b2" if flower_index % 2 == 0 else "f5dd72", 0.48))


func _draw_grass_tuft(point: Vector2, scale_value: float) -> void:
	for blade in range(5):
		var x := (float(blade) - 2.0) * 5.0 * scale_value
		draw_line(point + Vector2(x, 8.0 * scale_value), point + Vector2(x * 0.55, (-18.0 - float(blade % 2) * 7.0) * scale_value), Color(primary_color.lightened(0.12), 0.4), 2.4 * scale_value, true)


func _draw_meadow_frog(point: Vector2, scale_value: float) -> void:
	draw_circle(point, 12.0 * scale_value, Color("70a85f", 0.52))
	for side in [-1.0, 1.0]:
		draw_circle(point + Vector2(side * 8.0, -9.0) * scale_value, 5.0 * scale_value, Color("82ba69", 0.56))
		draw_circle(point + Vector2(side * 8.0, -10.0) * scale_value, 1.5 * scale_value, Color("111814", 0.8))


func _draw_cactus(point: Vector2, scale_value: float, flower: bool) -> void:
	var color := Color(primary_color.darkened(0.18), 0.5)
	draw_line(point + Vector2(0, 18) * scale_value, point + Vector2(0, -35) * scale_value, color, 11.0 * scale_value, true)
	draw_line(point + Vector2(0, -12) * scale_value, point + Vector2(-17, -23) * scale_value, color, 8.0 * scale_value, true)
	draw_line(point + Vector2(-17, -23) * scale_value, point + Vector2(-17, -34) * scale_value, color, 8.0 * scale_value, true)
	draw_line(point, point + Vector2(18, -10) * scale_value, color, 8.0 * scale_value, true)
	if flower:
		for petal_index in range(5):
			draw_circle(point + Vector2(-17, -40) * scale_value + Vector2.RIGHT.rotated(TAU * float(petal_index) / 5.0) * 4.0 * scale_value, 2.8 * scale_value, Color("ef87a8", 0.65))


func _draw_rock_mound(point: Vector2, scale_value: float, color: Color) -> void:
	for rock in range(3):
		var offset := Vector2((float(rock) - 1.0) * 17.0, -float(rock % 2) * 8.0) * scale_value
		draw_circle(point + offset, (15.0 + float(rock % 2) * 5.0) * scale_value, color)


func _draw_tumbleweed(point: Vector2, scale_value: float, rotation: float) -> void:
	for ring in range(3):
		draw_arc(point, (12.0 + float(ring) * 5.0) * scale_value, rotation + float(ring), rotation + float(ring) + PI * 1.55, 15, Color(primary_color.darkened(0.25), 0.42), 2.0 * scale_value, true)


func _draw_sand_ripple(point: Vector2, scale_value: float) -> void:
	for line_index in range(3):
		draw_arc(point + Vector2(0, float(line_index) * 8.0) * scale_value, (22.0 + float(line_index) * 7.0) * scale_value, 0.12, PI - 0.12, 18, Color(primary_color, 0.18), 2.5 * scale_value, true)


func _draw_autumn_tree(point: Vector2, scale_value: float, apple: bool) -> void:
	draw_line(point + Vector2(0, 20) * scale_value, point + Vector2(0, -38) * scale_value, Color("38231f", 0.58), 10.0 * scale_value, true)
	for offset in [Vector2(-21, -37), Vector2(1, -55), Vector2(23, -35), Vector2(0, -25)]:
		draw_circle(point + offset * scale_value, 23.0 * scale_value, Color(primary_color.lightened(offset.x / 250.0), 0.46))
	if apple:
		for offset in [Vector2(-15, -45), Vector2(18, -34), Vector2(3, -62)]:
			draw_circle(point + offset * scale_value, 3.8 * scale_value, Color("d94e45", 0.72))


func _draw_ground_leaves(point: Vector2, scale_value: float, variant: int) -> void:
	for leaf_index in range(5):
		var offset := Vector2(float((leaf_index * 19 + variant * 7) % 41) - 20.0, float((leaf_index * 11) % 21) - 10.0) * scale_value
		var direction := Vector2.RIGHT.rotated(float(leaf_index) * 0.9)
		var side := direction.orthogonal() * 3.0 * scale_value
		draw_colored_polygon(PackedVector2Array([point + offset - direction * 7.0 * scale_value, point + offset + side, point + offset + direction * 7.0 * scale_value, point + offset - side]), Color(accent_color if leaf_index % 2 == 0 else primary_color, 0.42))


func _draw_penguin(point: Vector2, scale_value: float) -> void:
	_draw_ellipse(point, Vector2(14.0, 24.0) * scale_value, Color("172027", 0.62))
	_draw_ellipse(point + Vector2(0, 5) * scale_value, Vector2(8.0, 14.0) * scale_value, Color("eef5ef", 0.58))
	draw_colored_polygon(PackedVector2Array([point + Vector2(-2, -10) * scale_value, point + Vector2(9, -6) * scale_value, point + Vector2(-2, -3) * scale_value]), Color("efad46", 0.7))


func _draw_ice_formation(point: Vector2, scale_value: float) -> void:
	for shard in range(3):
		var x := (float(shard) - 1.0) * 13.0 * scale_value
		var height := (30.0 + float(shard % 2) * 16.0) * scale_value
		draw_colored_polygon(PackedVector2Array([point + Vector2(x - 8.0 * scale_value, 15.0 * scale_value), point + Vector2(x, 15.0 * scale_value - height), point + Vector2(x + 9.0 * scale_value, 15.0 * scale_value)]), Color(accent_color, 0.32))


func _draw_snowbank(point: Vector2, scale_value: float) -> void:
	_draw_ellipse(point, Vector2(39.0, 17.0) * scale_value, Color(accent_color, 0.18))
	draw_arc(point - Vector2(5, 2) * scale_value, 22.0 * scale_value, PI * 1.05, TAU * 0.94, 18, Color(primary_color.lightened(0.25), 0.22), 3.0 * scale_value, true)


func _draw_reeds(point: Vector2, scale_value: float) -> void:
	for reed_index in range(5):
		var x := (float(reed_index) - 2.0) * 7.0 * scale_value
		var height := (28.0 + float(reed_index % 3) * 8.0) * scale_value
		draw_line(point + Vector2(x, 16.0 * scale_value), point + Vector2(x + 3.0 * scale_value, 16.0 * scale_value - height), Color(primary_color.lightened(0.12), 0.46), 3.0 * scale_value, true)
		draw_line(point + Vector2(x + 3.0 * scale_value, 16.0 * scale_value - height), point + Vector2(x + 3.0 * scale_value, 10.0 * scale_value - height), Color("5b4630", 0.52), 6.0 * scale_value, true)


func _draw_swamp_plant(point: Vector2, scale_value: float) -> void:
	for leaf_index in range(5):
		var direction := Vector2.UP.rotated(lerpf(-0.82, 0.82, float(leaf_index) / 4.0))
		draw_line(point, point + direction * (24.0 + float(leaf_index % 2) * 9.0) * scale_value, Color(primary_color, 0.4), 5.0 * scale_value, true)


func _draw_swamp_bubbles(point: Vector2, scale_value: float) -> void:
	for bubble in range(3):
		draw_arc(point + Vector2(float(bubble) * 10.0, -float(bubble % 2) * 7.0) * scale_value, (4.0 + float(bubble) * 2.0) * scale_value, 0.0, TAU, 14, Color(accent_color, 0.25), 1.8 * scale_value, true)


func _draw_lava_crack(point: Vector2, scale_value: float, rotation: float) -> void:
	var direction := Vector2.RIGHT.rotated(rotation)
	var normal := direction.orthogonal()
	var crack := PackedVector2Array([point - direction * 32.0 * scale_value, point - direction * 10.0 * scale_value + normal * 7.0 * scale_value, point + direction * 9.0 * scale_value - normal * 5.0 * scale_value, point + direction * 34.0 * scale_value])
	draw_polyline(crack, Color("110d10", 0.7), 7.0 * scale_value, true)
	draw_polyline(crack, Color(accent_color, 0.38), 3.0 * scale_value, true)


func _draw_lava_vent(point: Vector2, scale_value: float) -> void:
	_draw_ellipse(point, Vector2(24.0, 11.0) * scale_value, Color("130e10", 0.68))
	_draw_ellipse(point, Vector2(15.0, 6.0) * scale_value, Color(accent_color, 0.28))
	for smoke_index in range(3):
		draw_circle(point + Vector2(float(smoke_index - 1) * 8.0, -18.0 - float(smoke_index) * 8.0) * scale_value, (7.0 + float(smoke_index) * 2.0) * scale_value, Color(primary_color, 0.08))


func _draw_pollen(point: Vector2, scale_value: float, alpha: float) -> void:
	draw_circle(point, 2.8 * scale_value, Color(accent_color, 0.25 * alpha))


func _draw_wind_streak(point: Vector2, scale_value: float, alpha: float) -> void:
	var length := 34.0 * scale_value
	draw_line(point - Vector2(length, 0.0), point + Vector2(length, 0.0), Color(primary_color, 0.18 * alpha), 2.2 * scale_value, true)


func _draw_leaf(point: Vector2, angle: float, scale_value: float, alpha: float) -> void:
	var direction := Vector2.RIGHT.rotated(angle)
	var side := direction.orthogonal() * 3.4 * scale_value
	var length := 8.5 * scale_value
	draw_colored_polygon(PackedVector2Array([point - direction * length, point + side, point + direction * length, point - side]), Color(accent_color, 0.38 * alpha))


func _draw_snow(point: Vector2, scale_value: float, alpha: float) -> void:
	var radius := 4.2 * scale_value
	var color := Color(accent_color, 0.34 * alpha)
	for angle in [0.0, PI / 3.0, PI * 2.0 / 3.0]:
		var direction := Vector2.RIGHT.rotated(angle) * radius
		draw_line(point - direction, point + direction, color, 1.5 * scale_value, true)


func _draw_wisp(point: Vector2, scale_value: float, alpha: float) -> void:
	draw_circle(point, 9.0 * scale_value, Color(primary_color, 0.07 * alpha))
	draw_arc(point, 7.0 * scale_value, PI, TAU, 12, Color(accent_color, 0.26 * alpha), 2.0 * scale_value, true)


func _draw_ember(point: Vector2, scale_value: float, alpha: float) -> void:
	draw_circle(point, 7.0 * scale_value, Color(primary_color, 0.08 * alpha))
	draw_circle(point, 3.1 * scale_value, Color(accent_color, 0.52 * alpha))


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for point_index in range(28):
		var angle := TAU * float(point_index) / 28.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
