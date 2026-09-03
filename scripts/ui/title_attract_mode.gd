class_name TitleAttractMode
extends Control

const BiomeDatabase := preload("res://scripts/biome_database.gd")
const HoleGenerator := preload("res://scripts/hole_generator.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

const SAFE_SEED := 486271
const LOOP_SECONDS := 11.5
const CELL_SIZE := 100.0

var level: Dictionary = {}
var terrain: Dictionary = {}
var background: Dictionary = {}
var elapsed := 0.0
var parallax := Vector2.ZERO
var reduced_motion := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var profile = BiomeDatabase.get_profiles()[0]
	level = HoleGenerator.generate_hole(profile, SAFE_SEED, 0, 2)
	terrain = profile.terrain_palette.duplicate(true)
	background = profile.background_palette.duplicate(true)
	set_process(true)


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if reduced_motion:
		parallax = Vector2.ZERO
	queue_redraw()


func _process(delta: float) -> void:
	if not reduced_motion:
		elapsed = fmod(elapsed + delta, LOOP_SECONDS)
		var mouse := get_viewport().get_mouse_position()
		var viewport_size := get_viewport_rect().size
		var normalized := Vector2.ZERO
		if viewport_size.x > 0.0 and viewport_size.y > 0.0:
			normalized = (mouse / viewport_size - Vector2(0.5, 0.5)) * 2.0
		var target := normalized.clamp(Vector2(-1.0, -1.0), Vector2.ONE) * 14.0
		parallax = parallax.lerp(target, 1.0 - exp(-delta * 4.0))
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var base: Color = background.get("primary", Color("245c3a"))
	var secondary: Color = background.get("secondary", Color("3f7d44"))
	var accent: Color = background.get("accent", UIStyleScript.GOLD)
	draw_rect(rect, base.darkened(0.28))
	_draw_sky_layers(rect, secondary, accent)
	if not level.is_empty():
		_draw_course(rect)
	_draw_menu_scrim(rect)


func _draw_sky_layers(rect: Rect2, secondary: Color, accent: Color) -> void:
	var w := rect.size.x
	var h := rect.size.y
	var distant_offset := parallax * -0.22
	var mid_offset := parallax * -0.46
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.42, h * 0.62) + distant_offset,
		Vector2(w * 0.60, h * 0.42) + distant_offset,
		Vector2(w * 0.74, h * 0.55) + distant_offset,
		Vector2(w * 0.88, h * 0.34) + distant_offset,
		Vector2(w, h * 0.48) + distant_offset,
		Vector2(w, h) + distant_offset,
		Vector2(w * 0.34, h) + distant_offset,
	]), Color(secondary.darkened(0.2), 0.82))
	for tree_index in range(11):
		var x := w * (0.49 + float(tree_index) * 0.052) + mid_offset.x
		var y := h * (0.2 + float((tree_index * 7) % 5) * 0.12) + mid_offset.y
		var radius := 22.0 + float(tree_index % 3) * 9.0
		draw_line(Vector2(x, y + radius * 0.55), Vector2(x, y + radius * 1.5), Color("493421"), 9.0, true)
		draw_circle(Vector2(x, y), radius, Color(secondary.lightened(0.04), 0.7))
		draw_circle(Vector2(x - radius * 0.35, y + 4.0), radius * 0.7, Color(secondary, 0.75))
	var cloud_shift := 0.0 if reduced_motion else fmod(elapsed * 8.0, w * 0.36)
	for cloud_index in range(3):
		var center := Vector2(w * (0.48 + float(cloud_index) * 0.22) + cloud_shift, h * (0.1 + float(cloud_index % 2) * 0.11)) + distant_offset
		if center.x > w + 80.0:
			center.x -= w * 0.66
		draw_circle(center, 20.0, Color(UIStyleScript.PAPER, 0.09))
		draw_circle(center + Vector2(22.0, 4.0), 15.0, Color(UIStyleScript.PAPER, 0.08))
		draw_circle(center + Vector2(-21.0, 7.0), 13.0, Color(UIStyleScript.PAPER, 0.08))
	for glint_index in range(8):
		var phase := elapsed * (0.35 + float(glint_index % 3) * 0.08) + float(glint_index) * 0.9
		var point := Vector2(w * (0.48 + float((glint_index * 17) % 47) / 100.0), h * (0.12 + float((glint_index * 29) % 76) / 100.0))
		point += Vector2(sin(phase) * 6.0, cos(phase * 0.8) * 5.0) + parallax * -0.3
		draw_circle(point, 2.0 + float(glint_index % 2), Color(accent, 0.12))


func _draw_course(rect: Rect2) -> void:
	var map_size := Vector2(float(_map_columns()), float(level.map.size())) * CELL_SIZE
	var target_width := clampf(rect.size.x * 0.47, 540.0, 900.0)
	var scale_factor := minf(target_width / map_size.x, rect.size.y * 0.76 / map_size.y)
	var course_center := Vector2(rect.size.x * 0.73, rect.size.y * 0.56) + parallax * 0.34
	var course_top_left := course_center - map_size * scale_factor * 0.5

	for cell in _playable_cells():
		var cell_rect := Rect2(
			course_top_left + Vector2(cell) * CELL_SIZE * scale_factor,
			Vector2.ONE * (CELL_SIZE * scale_factor + 1.0)
		)
		var color: Color = terrain.get("fairway_a", Color("63b75d")) if (cell.x + cell.y) % 2 == 0 else terrain.get("fairway_b", Color("58a852"))
		draw_rect(cell_rect, color.darkened(0.08))
		draw_rect(cell_rect, Color(terrain.get("border", Color("6f4a2f")), 0.28), false, maxf(1.0, scale_factor * 2.2))

	for hazard in level.get("hazards", []):
		var hazard_point := _world_to_screen(Vector2(hazard.pos), course_top_left, map_size, scale_factor)
		var hazard_size := Vector2(hazard.size) * scale_factor * 0.86
		var hazard_rect := Rect2(hazard_point - hazard_size * 0.5, hazard_size)
		match String(hazard.type):
			"water":
				draw_rect(hazard_rect, Color(terrain.get("water", Color("4fa6d8")), 0.92))
				for line_index in range(3):
					var y := hazard_rect.position.y + hazard_rect.size.y * (0.28 + float(line_index) * 0.22)
					draw_line(Vector2(hazard_rect.position.x + 8.0, y), Vector2(hazard_rect.end.x - 8.0, y), Color(UIStyleScript.PAPER, 0.24), 2.0, true)
			"sand":
				draw_rect(hazard_rect, terrain.get("sand", Color("d9bc78")))
			"bounce_pad":
				draw_circle(hazard_point, hazard_size.x * 0.38, Color(background.get("accent", UIStyleScript.GOLD), 0.88))
			_:
				draw_rect(hazard_rect, Color(terrain.get("direction", Color("79b88b")), 0.86))

	for obstacle in level.get("obstacles", []):
		var obstacle_point := _world_to_screen(Vector2(obstacle.pos), course_top_left, map_size, scale_factor)
		var obstacle_size := Vector2(obstacle.size) * scale_factor
		draw_rect(Rect2(obstacle_point - obstacle_size * 0.5, obstacle_size), terrain.get("border", Color("6f4a2f")))

	var cup_point := _cell_to_screen(Vector2i(level.hole_cell), course_top_left, scale_factor)
	draw_circle(cup_point, maxf(6.0, 15.0 * scale_factor), UIStyleScript.INK_DEEP)
	draw_line(cup_point, cup_point + Vector2(0.0, -58.0 * scale_factor), UIStyleScript.PAPER, maxf(2.0, 5.0 * scale_factor), true)
	draw_colored_polygon(PackedVector2Array([
		cup_point + Vector2(3.0, -57.0) * scale_factor,
		cup_point + Vector2(39.0, -47.0) * scale_factor,
		cup_point + Vector2(3.0, -35.0) * scale_factor,
	]), UIStyleScript.CURSE)

	var route: Array = level.get("main_route_cells", [])
	if route.size() >= 2:
		var route_points := PackedVector2Array()
		for raw_cell in route:
			route_points.append(_cell_to_screen(Vector2i(raw_cell), course_top_left, scale_factor))
		draw_polyline(route_points, Color(UIStyleScript.PAPER, 0.08), maxf(2.0, 4.0 * scale_factor), true)
		var loop_progress := 0.36 if reduced_motion else elapsed / LOOP_SECONDS
		var ball_point := _point_along_route(route_points, loop_progress)
		var seam_alpha := smoothstep(0.0, 0.07, loop_progress) * (1.0 - smoothstep(0.91, 1.0, loop_progress))
		_draw_ball(ball_point, maxf(8.0, 15.0 * scale_factor), seam_alpha)


func _draw_ball(center: Vector2, radius: float, alpha: float) -> void:
	draw_circle(center + Vector2(radius * 0.28, radius * 0.34), radius * 1.05, Color(0.0, 0.0, 0.0, 0.26 * alpha))
	draw_circle(center, radius, Color(UIStyleScript.PAPER, alpha))
	for offset in [Vector2(-0.3, -0.25), Vector2(0.35, -0.3), Vector2(0.1, 0.35)]:
		draw_circle(center + offset * radius, maxf(1.0, radius * 0.09), Color(UIStyleScript.INK_SOFT, 0.34 * alpha))


func _draw_menu_scrim(rect: Rect2) -> void:
	var w := rect.size.x
	var h := rect.size.y
	draw_colored_polygon(PackedVector2Array([
		Vector2.ZERO,
		Vector2(w * 0.62, 0.0),
		Vector2(w * 0.51, h),
		Vector2(0.0, h),
	]), Color(UIStyleScript.INK_DEEP, 0.86))
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.47, 0.0),
		Vector2(w, 0.0),
		Vector2(w, h),
		Vector2(w * 0.57, h),
	]), Color(UIStyleScript.INK_DEEP, 0.18))


func _point_along_route(points: PackedVector2Array, progress: float) -> Vector2:
	var bounded := clampf(progress, 0.0, 1.0)
	var scaled := bounded * float(points.size() - 1)
	var index := mini(floori(scaled), points.size() - 2)
	return points[index].lerp(points[index + 1], scaled - float(index))


func _cell_to_screen(cell: Vector2i, top_left: Vector2, scale_factor: float) -> Vector2:
	return top_left + (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE * scale_factor


func _world_to_screen(world: Vector2, top_left: Vector2, map_size: Vector2, scale_factor: float) -> Vector2:
	return top_left + (world + map_size * 0.5) * scale_factor


func _map_columns() -> int:
	var columns := 0
	for row in level.map:
		columns = maxi(columns, String(row).length())
	return columns


func _playable_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(level.map.size()):
		var row := String(level.map[y])
		for x in range(row.length()):
			if row[x] != " ":
				cells.append(Vector2i(x, y))
	return cells
