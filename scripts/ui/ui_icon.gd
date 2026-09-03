class_name UIIcon
extends Control

@export var icon_name: StringName = &"hole":
	set(value):
		icon_name = value
		queue_redraw()
@export var icon_color := Color("f6f1df"):
	set(value):
		icon_color = value
		queue_redraw()
@export var accent_color := Color("edbf45"):
	set(value):
		accent_color = value
		queue_redraw()
@export var stroke_color := Color("17201e"):
	set(value):
		stroke_color = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = custom_minimum_size.max(Vector2(24.0, 24.0))
	queue_redraw()


func configure(new_icon_name: StringName, new_color: Color = Color("f6f1df"), new_accent: Color = Color("edbf45")) -> UIIcon:
	icon_name = new_icon_name
	icon_color = new_color
	accent_color = new_accent
	return self


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale_factor := minf(size.x, size.y) / 100.0
	var origin := (size - Vector2.ONE * 100.0 * scale_factor) * 0.5
	draw_set_transform(origin, 0.0, Vector2.ONE * scale_factor)

	match icon_name:
		&"strokes", &"club":
			_draw_club()
		&"par", &"target", &"rangefinder_lens":
			_draw_target()
		&"timer":
			_draw_timer()
		&"coin", &"coins":
			_draw_coin()
		&"hole":
			_draw_hole()
		&"biome":
			_draw_biome()
		&"power", &"overdrive_driver":
			_draw_power_club(true)
		&"control":
			_draw_target()
		&"sand", &"sand_cleats":
			_draw_sand_cleats()
		&"water":
			_draw_water()
		&"ice", &"snow":
			_draw_snow()
		&"lava", &"volcanic":
			_draw_volcanic()
		&"bonus":
			_draw_bonus()
		&"curse":
			_draw_curse()
		&"shop":
			_draw_shop()
		&"restart":
			_draw_restart()
		&"continue":
			_draw_continue()
		&"menu":
			_draw_menu()
		&"help", &"tutorial":
			_draw_help()
		&"quit":
			_draw_quit()
		&"card", &"cards":
			_draw_cards()
		&"power_club":
			_draw_power_club(false)
		&"coin_magnet":
			_draw_coin_magnet()
		&"gust_guard":
			_draw_gust_guard()
		&"heavy_core":
			_draw_heavy_core()
		&"lucky_putter":
			_draw_lucky_putter()
		&"meadow":
			_draw_meadow()
		&"desert":
			_draw_desert()
		&"autumn":
			_draw_autumn()
		&"swamp":
			_draw_swamp()
		&"score_good":
			_draw_score_good()
		&"score_bad":
			_draw_score_bad()
		&"seed":
			_draw_seed()
		&"star":
			_draw_star()
		&"lock":
			_draw_lock()
		&"stack":
			_draw_stack()
		_:
			_draw_hole()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _stroke(points: PackedVector2Array, color := Color.TRANSPARENT, width := 6.0, closed := false) -> void:
	var draw_color: Color = icon_color if color == Color.TRANSPARENT else color
	draw_polyline(points, stroke_color, width + 4.0, true)
	draw_polyline(points, draw_color, width, true)
	if closed and points.size() > 1:
		draw_line(points[-1], points[0], stroke_color, width + 4.0, true)
		draw_line(points[-1], points[0], draw_color, width, true)


func _line(from: Vector2, to: Vector2, color := Color.TRANSPARENT, width := 6.0) -> void:
	var draw_color: Color = icon_color if color == Color.TRANSPARENT else color
	draw_line(from, to, stroke_color, width + 4.0, true)
	draw_line(from, to, draw_color, width, true)


func _polygon(points: PackedVector2Array, color := Color.TRANSPARENT) -> void:
	var draw_color: Color = icon_color if color == Color.TRANSPARENT else color
	draw_colored_polygon(points, stroke_color)
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= maxf(float(points.size()), 1.0)
	var inset := PackedVector2Array()
	for point in points:
		inset.append(center + (point - center) * 0.88)
	draw_colored_polygon(inset, draw_color)


func _disc(center: Vector2, radius: float, color := Color.TRANSPARENT) -> void:
	var draw_color: Color = icon_color if color == Color.TRANSPARENT else color
	draw_circle(center, radius + 3.0, stroke_color)
	draw_circle(center, radius, draw_color)


func _draw_club() -> void:
	_line(Vector2(66, 13), Vector2(39, 72), icon_color, 7.0)
	_polygon(PackedVector2Array([Vector2(22, 69), Vector2(44, 65), Vector2(52, 78), Vector2(31, 88), Vector2(17, 82)]), accent_color)
	_line(Vector2(61, 14), Vector2(72, 18), accent_color, 7.0)


func _draw_target() -> void:
	_disc(Vector2(50, 52), 34.0, Color(stroke_color, 0.18))
	draw_circle(Vector2(50, 52), 23.0, icon_color)
	draw_circle(Vector2(50, 52), 14.0, stroke_color)
	draw_circle(Vector2(50, 52), 7.0, accent_color)
	_line(Vector2(50, 8), Vector2(50, 25), accent_color, 4.0)
	_line(Vector2(50, 79), Vector2(50, 96), accent_color, 4.0)
	_line(Vector2(6, 52), Vector2(23, 52), accent_color, 4.0)
	_line(Vector2(77, 52), Vector2(94, 52), accent_color, 4.0)


func _draw_timer() -> void:
	_disc(Vector2(50, 56), 34.0, icon_color)
	draw_circle(Vector2(50, 56), 27.0, stroke_color)
	draw_circle(Vector2(50, 56), 23.0, Color("20302c"))
	_line(Vector2(50, 56), Vector2(50, 36), accent_color, 5.0)
	_line(Vector2(50, 56), Vector2(66, 65), accent_color, 5.0)
	_line(Vector2(39, 11), Vector2(61, 11), icon_color, 7.0)
	_line(Vector2(50, 12), Vector2(50, 20), icon_color, 5.0)


func _draw_coin() -> void:
	_disc(Vector2(50, 50), 36.0, accent_color)
	draw_circle(Vector2(50, 50), 27.0, Color("f6d775"))
	draw_arc(Vector2(50, 50), 20.0, -1.05, 1.05, 16, stroke_color, 5.0, true)
	draw_arc(Vector2(50, 50), 20.0, 2.1, 4.2, 16, stroke_color, 5.0, true)
	_disc(Vector2(50, 50), 4.0, stroke_color)


func _draw_hole() -> void:
	_line(Vector2(35, 14), Vector2(35, 77), icon_color, 6.0)
	_polygon(PackedVector2Array([Vector2(39, 18), Vector2(78, 29), Vector2(39, 43)]), accent_color)
	_draw_ellipse_shape(Vector2(42, 82), Vector2(30, 9), stroke_color)
	draw_arc(Vector2(42, 80), 30.0, 0.12, PI - 0.12, 22, icon_color, 5.0, true)


func _draw_ellipse_shape(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _draw_biome() -> void:
	_polygon(PackedVector2Array([Vector2(10, 75), Vector2(34, 39), Vector2(50, 60), Vector2(67, 24), Vector2(93, 75)]), icon_color)
	_line(Vector2(8, 78), Vector2(94, 78), accent_color, 6.0)


func _draw_power_club(show_speed: bool) -> void:
	_draw_club()
	_polygon(PackedVector2Array([Vector2(67, 42), Vector2(89, 34), Vector2(78, 52), Vector2(92, 54), Vector2(62, 79), Vector2(70, 58), Vector2(58, 56)]), accent_color)
	if show_speed:
		_line(Vector2(12, 33), Vector2(34, 33), accent_color, 4.0)
		_line(Vector2(8, 45), Vector2(28, 45), accent_color, 4.0)


func _draw_sand_cleats() -> void:
	_polygon(PackedVector2Array([Vector2(22, 24), Vector2(55, 24), Vector2(57, 54), Vector2(83, 63), Vector2(80, 76), Vector2(41, 76), Vector2(24, 60)]), icon_color)
	for x in [36.0, 50.0, 65.0]:
		_disc(Vector2(x, 82), 3.0, accent_color)
	_stroke(PackedVector2Array([Vector2(8, 91), Vector2(27, 85), Vector2(46, 91), Vector2(65, 85), Vector2(91, 91)]), accent_color, 4.0)


func _draw_water() -> void:
	for y in [34.0, 51.0, 68.0]:
		_stroke(PackedVector2Array([Vector2(9, y), Vector2(27, y - 7), Vector2(46, y + 2), Vector2(65, y - 7), Vector2(91, y)]), icon_color if y != 51.0 else accent_color, 5.0)


func _draw_snow() -> void:
	for angle in [0.0, PI / 3.0, PI * 2.0 / 3.0]:
		var direction := Vector2(cos(angle), sin(angle))
		_line(Vector2(50, 50) - direction * 37.0, Vector2(50, 50) + direction * 37.0, icon_color, 5.0)
		for sign_value in [-1.0, 1.0]:
			var branch_base: Vector2 = Vector2(50, 50) + direction * 27.0 * sign_value
			var branch := direction.rotated(0.65 * sign_value)
			_line(branch_base, branch_base - branch * 12.0, accent_color, 3.0)


func _draw_volcanic() -> void:
	_polygon(PackedVector2Array([Vector2(8, 82), Vector2(31, 51), Vector2(43, 57), Vector2(57, 32), Vector2(92, 82)]), Color("54302d"))
	_polygon(PackedVector2Array([Vector2(38, 79), Vector2(48, 58), Vector2(57, 68), Vector2(66, 48), Vector2(76, 79)]), accent_color)
	_stroke(PackedVector2Array([Vector2(10, 89), Vector2(32, 85), Vector2(51, 91), Vector2(72, 85), Vector2(92, 90)]), accent_color, 4.0)


func _draw_bonus() -> void:
	_polygon(PackedVector2Array([Vector2(17, 58), Vector2(50, 20), Vector2(83, 58), Vector2(66, 58), Vector2(66, 84), Vector2(34, 84), Vector2(34, 58)]), accent_color)
	_line(Vector2(18, 90), Vector2(82, 90), icon_color, 5.0)


func _draw_curse() -> void:
	_polygon(PackedVector2Array([Vector2(50, 8), Vector2(94, 86), Vector2(6, 86)]), accent_color)
	_line(Vector2(50, 32), Vector2(50, 61), stroke_color, 8.0)
	_disc(Vector2(50, 73), 5.0, stroke_color)


func _draw_shop() -> void:
	_polygon(PackedVector2Array([Vector2(14, 38), Vector2(24, 16), Vector2(76, 16), Vector2(88, 38)]), accent_color)
	for x in [23.0, 41.0, 59.0, 77.0]:
		_line(Vector2(x, 39), Vector2(x + 2.0, 53), icon_color, 8.0)
	_polygon(PackedVector2Array([Vector2(19, 51), Vector2(82, 51), Vector2(78, 88), Vector2(23, 88)]), icon_color)
	_polygon(PackedVector2Array([Vector2(58, 62), Vector2(73, 62), Vector2(72, 88), Vector2(58, 88)]), stroke_color)


func _draw_restart() -> void:
	draw_arc(Vector2(51, 53), 32.0, -2.6, 2.1, 32, stroke_color, 10.0, true)
	draw_arc(Vector2(51, 53), 32.0, -2.6, 2.1, 32, icon_color, 6.0, true)
	_polygon(PackedVector2Array([Vector2(15, 18), Vector2(39, 19), Vector2(25, 39)]), accent_color)


func _draw_continue() -> void:
	_line(Vector2(12, 50), Vector2(76, 50), icon_color, 8.0)
	_polygon(PackedVector2Array([Vector2(61, 21), Vector2(93, 50), Vector2(61, 79)]), accent_color)


func _draw_menu() -> void:
	for y in [27.0, 50.0, 73.0]:
		_disc(Vector2(18, y), 4.0, accent_color)
		_line(Vector2(32, y), Vector2(86, y), icon_color, 7.0)


func _draw_help() -> void:
	_disc(Vector2(50, 50), 38.0, icon_color)
	draw_circle(Vector2(50, 50), 30.0, stroke_color)
	draw_arc(Vector2(50, 41), 15.0, PI, TAU, 18, accent_color, 7.0, true)
	_line(Vector2(65, 41), Vector2(50, 60), accent_color, 7.0)
	_disc(Vector2(50, 76), 5.0, accent_color)


func _draw_quit() -> void:
	_polygon(PackedVector2Array([Vector2(16, 14), Vector2(61, 14), Vector2(61, 86), Vector2(16, 86)]), icon_color)
	_disc(Vector2(48, 52), 4.0, accent_color)
	_line(Vector2(50, 50), Vector2(89, 50), accent_color, 7.0)
	_polygon(PackedVector2Array([Vector2(76, 33), Vector2(95, 50), Vector2(76, 67)]), accent_color)


func _draw_cards() -> void:
	_polygon(PackedVector2Array([Vector2(12, 25), Vector2(58, 12), Vector2(76, 76), Vector2(29, 89)]), Color("36534a"))
	_polygon(PackedVector2Array([Vector2(39, 14), Vector2(87, 24), Vector2(74, 89), Vector2(26, 79)]), icon_color)
	_disc(Vector2(56, 50), 9.0, accent_color)


func _draw_coin_magnet() -> void:
	_stroke(PackedVector2Array([Vector2(18, 17), Vector2(18, 57), Vector2(29, 77), Vector2(50, 85), Vector2(71, 77), Vector2(82, 57), Vector2(82, 17)]), icon_color, 12.0)
	_line(Vector2(18, 18), Vector2(18, 39), accent_color, 12.0)
	_line(Vector2(82, 18), Vector2(82, 39), accent_color, 12.0)
	_disc(Vector2(50, 47), 10.0, accent_color)


func _draw_gust_guard() -> void:
	_polygon(PackedVector2Array([Vector2(50, 9), Vector2(87, 24), Vector2(80, 68), Vector2(50, 92), Vector2(20, 68), Vector2(13, 24)]), Color("3c6f78"))
	for y in [37.0, 51.0, 65.0]:
		_stroke(PackedVector2Array([Vector2(27, y), Vector2(43, y - 6), Vector2(60, y + 2), Vector2(75, y - 4)]), accent_color, 4.0)


func _draw_heavy_core() -> void:
	_disc(Vector2(50, 56), 32.0, Color("8f93a7"))
	draw_circle(Vector2(50, 56), 20.0, stroke_color)
	draw_circle(Vector2(50, 56), 13.0, accent_color)
	_line(Vector2(27, 18), Vector2(73, 18), icon_color, 7.0)
	_line(Vector2(35, 18), Vector2(30, 29), icon_color, 5.0)
	_line(Vector2(65, 18), Vector2(70, 29), icon_color, 5.0)


func _draw_lucky_putter() -> void:
	_draw_hole()
	for offset in [Vector2(-7, 0), Vector2(7, 0), Vector2(0, -7), Vector2(0, 7)]:
		_disc(Vector2(73, 67) + offset, 6.0, accent_color)
	_disc(Vector2(73, 67), 3.0, stroke_color)


func _draw_meadow() -> void:
	for offset in [Vector2(-9, 0), Vector2(9, 0), Vector2(0, -9), Vector2(0, 9)]:
		_disc(Vector2(50, 39) + offset, 8.0, icon_color)
	_disc(Vector2(50, 39), 6.0, accent_color)
	_line(Vector2(50, 51), Vector2(50, 88), icon_color, 5.0)
	_stroke(PackedVector2Array([Vector2(50, 69), Vector2(30, 59), Vector2(35, 76), Vector2(50, 81)]), accent_color, 4.0)


func _draw_desert() -> void:
	_disc(Vector2(72, 27), 15.0, accent_color)
	_line(Vector2(38, 25), Vector2(38, 83), icon_color, 9.0)
	_line(Vector2(38, 48), Vector2(19, 39), icon_color, 8.0)
	_line(Vector2(19, 39), Vector2(19, 27), icon_color, 8.0)
	_line(Vector2(38, 60), Vector2(57, 50), icon_color, 8.0)
	_line(Vector2(57, 50), Vector2(57, 38), icon_color, 8.0)


func _draw_autumn() -> void:
	_polygon(PackedVector2Array([Vector2(50, 7), Vector2(61, 30), Vector2(88, 23), Vector2(75, 50), Vector2(91, 65), Vector2(61, 70), Vector2(50, 94), Vector2(39, 70), Vector2(9, 65), Vector2(25, 50), Vector2(12, 23), Vector2(39, 30)]), accent_color)
	_line(Vector2(50, 26), Vector2(50, 82), stroke_color, 5.0)


func _draw_swamp() -> void:
	for x in [23.0, 48.0, 72.0]:
		_line(Vector2(x, 84), Vector2(x + 5.0, 25), icon_color, 6.0)
		_polygon(PackedVector2Array([Vector2(x + 5, 25), Vector2(x + 14, 11), Vector2(x + 11, 35)]), accent_color)
	_stroke(PackedVector2Array([Vector2(7, 88), Vector2(27, 82), Vector2(48, 89), Vector2(69, 82), Vector2(93, 88)]), accent_color, 4.0)


func _draw_score_good() -> void:
	_polygon(PackedVector2Array([Vector2(50, 7), Vector2(61, 36), Vector2(93, 38), Vector2(68, 58), Vector2(76, 90), Vector2(50, 72), Vector2(24, 90), Vector2(32, 58), Vector2(7, 38), Vector2(39, 36)]), accent_color)


func _draw_score_bad() -> void:
	_draw_curse()


func _draw_seed() -> void:
	_polygon(PackedVector2Array([Vector2(16, 23), Vector2(50, 8), Vector2(84, 23), Vector2(84, 76), Vector2(50, 92), Vector2(16, 76)]), icon_color)
	for point in [Vector2(36, 35), Vector2(64, 35), Vector2(50, 51), Vector2(36, 68), Vector2(64, 68)]:
		_disc(point, 4.0, accent_color)


func _draw_star() -> void:
	var points := PackedVector2Array()
	for point_index in range(10):
		var angle := -PI * 0.5 + float(point_index) * PI / 5.0
		var radius := 39.0 if point_index % 2 == 0 else 17.0
		points.append(Vector2(50.0, 51.0) + Vector2(cos(angle), sin(angle)) * radius)
	_polygon(points, accent_color)


func _draw_lock() -> void:
	draw_arc(Vector2(50, 43), 22.0, PI, TAU, 20, stroke_color, 14.0, true)
	draw_arc(Vector2(50, 43), 22.0, PI, TAU, 20, icon_color, 8.0, true)
	_polygon(PackedVector2Array([Vector2(22, 42), Vector2(78, 42), Vector2(82, 88), Vector2(18, 88)]), accent_color)
	_disc(Vector2(50, 63), 6.0, stroke_color)
	_line(Vector2(50, 68), Vector2(50, 78), stroke_color, 5.0)


func _draw_stack() -> void:
	for offset in [Vector2(13, 15), Vector2(6, 8), Vector2.ZERO]:
		_polygon(PackedVector2Array([
			Vector2(24, 19) + offset,
			Vector2(78, 19) + offset,
			Vector2(78, 85) + offset,
			Vector2(24, 85) + offset,
		]), Color(icon_color, 0.9))
	_line(Vector2(36, 39), Vector2(66, 39), accent_color, 5.0)
	_line(Vector2(36, 52), Vector2(60, 52), accent_color, 5.0)
