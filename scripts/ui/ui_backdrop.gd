class_name UIBackdrop
extends Control

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

@export var mode: StringName = &"menu":
	set(value):
		mode = value
		queue_redraw()
@export var accent := UIStyleScript.FOCUS:
	set(value):
		accent = value
		queue_redraw()
@export var base_color := UIStyleScript.INK:
	set(value):
		base_color = value
		queue_redraw()

var _elapsed := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func configure(new_mode: StringName, new_accent: Color, new_base := UIStyleScript.INK) -> UIBackdrop:
	mode = new_mode
	accent = new_accent
	base_color = new_base
	return self


func _process(delta: float) -> void:
	_elapsed = fmod(_elapsed + delta, 1000.0)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, base_color)
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return

	match mode:
		&"shop":
			_draw_shop(rect)
		&"results":
			_draw_results(rect)
		&"biome":
			_draw_biome(rect)
		_:
			_draw_menu(rect)
	_draw_particles(rect)


func _draw_menu(rect: Rect2) -> void:
	var w := rect.size.x
	var h := rect.size.y
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.56, 0.0),
		Vector2(w, 0.0),
		Vector2(w, h),
		Vector2(w * 0.69, h),
		Vector2(w * 0.61, h * 0.72),
		Vector2(w * 0.73, h * 0.43),
	]), Color(accent, 0.075))

	var course := PackedVector2Array([
		Vector2(w * 0.69, h * 0.94),
		Vector2(w * 0.61, h * 0.75),
		Vector2(w * 0.68, h * 0.58),
		Vector2(w * 0.82, h * 0.49),
		Vector2(w * 0.78, h * 0.26),
		Vector2(w * 0.86, h * 0.08),
	])
	draw_polyline(course, Color(UIStyleScript.INK_DEEP, 0.86), maxf(116.0, w * 0.075), true)
	draw_polyline(course, Color("376c51"), maxf(92.0, w * 0.058), true)
	draw_polyline(course, Color("65ad6b"), maxf(58.0, w * 0.038), true)

	var ball_center := Vector2(w * 0.69, h * 0.87)
	draw_circle(ball_center + Vector2(9.0, 11.0), 22.0, Color(0.0, 0.0, 0.0, 0.34))
	draw_circle(ball_center, 22.0, UIStyleScript.PAPER)
	for offset in [Vector2(-7, -5), Vector2(7, -8), Vector2(2, 7), Vector2(-10, 9)]:
		draw_circle(ball_center + offset, 2.5, Color(UIStyleScript.INK_SOFT, 0.32))

	var flag_x := w * 0.845
	var flag_y := h * 0.13
	draw_line(Vector2(flag_x, flag_y), Vector2(flag_x, flag_y + 105.0), UIStyleScript.PAPER, 6.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(flag_x + 4.0, flag_y + 5.0),
		Vector2(flag_x + 82.0, flag_y + 28.0),
		Vector2(flag_x + 4.0, flag_y + 53.0),
	]), accent)
	draw_circle(Vector2(flag_x, flag_y + 111.0), 18.0, UIStyleScript.INK_DEEP)

	_draw_card_silhouette(Vector2(w * 0.915, h * 0.61), Vector2(190, 260), 0.14, Color(accent, 0.12))
	_draw_card_silhouette(Vector2(w * 0.60, h * 0.18), Vector2(150, 210), -0.18, Color(UIStyleScript.GOLD, 0.075))


func _draw_shop(rect: Rect2) -> void:
	var w := rect.size.x
	var h := rect.size.y
	draw_rect(Rect2(0.0, 0.0, w, h * 0.17), Color("101916"))
	for index in range(10):
		var x := float(index) * w / 10.0
		var stripe_color := Color(UIStyleScript.GOLD, 0.08 if index % 2 == 0 else 0.025)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, 0.0),
			Vector2(x + w * 0.065, 0.0),
			Vector2(x + w * 0.045, h * 0.17),
			Vector2(x - w * 0.02, h * 0.17),
		]), stripe_color)
	draw_rect(Rect2(0.0, h * 0.17, w, 5.0), Color(UIStyleScript.GOLD, 0.65))
	_draw_card_silhouette(Vector2(w * 0.05, h * 0.58), Vector2(170, 250), -0.16, Color(UIStyleScript.FOCUS, 0.055))
	_draw_card_silhouette(Vector2(w * 0.94, h * 0.55), Vector2(170, 250), 0.14, Color(UIStyleScript.CURSE, 0.05))
	draw_arc(Vector2(w * 0.5, h * 1.08), w * 0.44, PI, TAU, 72, Color(UIStyleScript.GOLD, 0.05), 70.0, true)


func _draw_results(rect: Rect2) -> void:
	var w := rect.size.x
	var h := rect.size.y
	var band_height := h / 6.0
	var colors := [Color("71d37b"), Color("efb75e"), Color("df7a4a"), Color("9de5f2"), Color("77c79d"), Color("f16b49")]
	for index in range(colors.size()):
		var x_shift := sin(float(index) * 1.8) * w * 0.025
		draw_colored_polygon(PackedVector2Array([
			Vector2(w * 0.75 + x_shift, band_height * index),
			Vector2(w, band_height * index),
			Vector2(w, band_height * (index + 1)),
			Vector2(w * 0.70 - x_shift, band_height * (index + 1)),
		]), Color(colors[index], 0.08))
	draw_arc(Vector2(w * 0.84, h * 0.48), minf(w, h) * 0.29, 0.0, TAU, 80, Color(accent, 0.12), 34.0, true)
	draw_arc(Vector2(w * 0.84, h * 0.48), minf(w, h) * 0.2, 0.0, TAU, 80, Color(accent, 0.08), 5.0, true)


func _draw_biome(rect: Rect2) -> void:
	var w := rect.size.x
	var h := rect.size.y
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.58, 0.0),
		Vector2(w, 0.0),
		Vector2(w, h),
		Vector2(w * 0.76, h),
		Vector2(w * 0.64, h * 0.61),
		Vector2(w * 0.72, h * 0.25),
	]), Color(accent, 0.12))
	for index in range(4):
		var radius := minf(w, h) * (0.12 + float(index) * 0.07)
		draw_arc(Vector2(w * 0.82, h * 0.46), radius, 0.35, 5.9, 56, Color(accent, 0.09 - float(index) * 0.014), 5.0, true)


func _draw_particles(rect: Rect2) -> void:
	var w := rect.size.x
	var h := rect.size.y
	for index in range(12):
		var base_x := fmod(float(index * 173 + 91), 997.0) / 997.0
		var base_y := fmod(float(index * 281 + 47), 991.0) / 991.0
		var drift := sin(_elapsed * 0.32 + float(index) * 1.7) * 9.0
		var point := Vector2(base_x * w + drift, base_y * h + cos(_elapsed * 0.25 + index) * 5.0)
		var radius := 1.5 + float(index % 3)
		draw_circle(point, radius, Color(accent, 0.12 + float(index % 2) * 0.08))


func _draw_card_silhouette(center: Vector2, card_size: Vector2, rotation: float, color: Color) -> void:
	var half := card_size * 0.5
	var corners := PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	var transformed := PackedVector2Array()
	for corner in corners:
		transformed.append(center + corner.rotated(rotation))
	draw_colored_polygon(transformed, color)
	draw_polyline(PackedVector2Array([transformed[0], transformed[1], transformed[2], transformed[3], transformed[0]]), Color(color, minf(color.a * 2.2, 0.28)), 3.0, true)
