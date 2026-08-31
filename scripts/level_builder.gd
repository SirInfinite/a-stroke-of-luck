class_name LevelBuilder
extends Node

const CourseVisualFactory := preload("res://scripts/course_visual_factory.gd")
const BiomeAmbienceScript := preload("res://scripts/biome_ambience.gd")

signal hole_body_entered(body: Node2D)
signal sand_body_entered(body: Node2D)
signal sand_body_exited(body: Node2D)
signal rough_body_entered(body: Node2D)
signal rough_body_exited(body: Node2D)
signal water_body_entered(body: Node2D, water_position: Vector2)
signal out_body_entered(body: Node2D, out_position: Vector2)
signal direction_body_entered(body: Node2D, area: Area2D)
signal direction_body_exited(body: Node2D, area: Area2D)

const GRID_CELL_SIZE := 100.0
const WALL_THICKNESS := 30.0
const GREEN_DARK := Color(0.232, 0.554, 0.248, 1.0)
const GREEN_DARKER := Color(0.161, 0.447, 0.201, 1.0)
const BORDER_BROWN := Color(0.34, 0.19, 0.09)

var level_root: Node2D
var active_terrain_palette: Dictionary = {}
var active_background_palette: Dictionary = {}


func build_level(level: Dictionary, parent: Node) -> Node2D:
	active_terrain_palette = level.get("terrain_palette", {}).duplicate(true)
	active_background_palette = level.get("background_palette", {}).duplicate(true)
	level_root = Node2D.new()
	level_root.name = "Level"
	level_root.z_index = -1
	parent.add_child(level_root)

	_create_background(level)
	_create_course(level)
	_create_start_marker(level_point(level, "start", "start_cell"))
	_create_hole(level_point(level, "hole", "hole_cell"), float(level.get("cup_radius", 28.0)))
	_create_hazards(level)

	for obstacle in level.obstacles:
		_create_box(obstacle.pos, obstacle.size, _terrain_color("border", BORDER_BROWN))
	_create_decorations(level)

	return level_root


func level_point(level: Dictionary, world_key: String, cell_key: String) -> Vector2:
	if level.has(cell_key):
		return _cell_to_world(level, level[cell_key])
	return level.get(world_key, Vector2.ZERO)


func _create_course(level: Dictionary) -> void:
	_create_floor(level)
	_create_bounds(level)


func _create_background(level: Dictionary) -> void:
	var map_size := _map_size(level)
	var surround_size := map_size + Vector2(1400.0, 1000.0)

	var backdrop := Polygon2D.new()
	backdrop.name = "BiomeBackground"
	backdrop.z_index = -2
	backdrop.polygon = _rectangle_polygon(surround_size)
	backdrop.color = _background_color("primary", Color(0.48, 0.66, 0.35))
	level_root.add_child(backdrop)

	var background_shapes := Node2D.new()
	background_shapes.name = "BiomeBackgroundVariants"
	background_shapes.z_index = -1
	level_root.add_child(background_shapes)
	var secondary := _background_color("secondary", backdrop.color.lightened(0.08))
	var highlight := _background_color("highlight", secondary.lightened(0.12))
	for i in range(8):
		var patch := Polygon2D.new()
		patch.name = "BackgroundPatch%d" % (i + 1)
		var side := -1.0 if i % 2 == 0 else 1.0
		var row := -1.0 if i % 4 < 2 else 1.0
		patch.position = Vector2(side * (map_size.x * 0.5 + 150.0 + float(i % 3) * 90.0), row * (map_size.y * 0.5 + 100.0 + float(i % 2) * 75.0))
		patch.rotation = float(i) * 0.43
		patch.polygon = _ellipse_polygon(Vector2(95.0 + float(i % 3) * 24.0, 42.0 + float(i % 2) * 16.0), 20)
		patch.color = Color(secondary if i % 3 != 0 else highlight, 0.36)
		background_shapes.add_child(patch)

	var ambience = BiomeAmbienceScript.new()
	ambience.name = "BiomeAmbience"
	ambience.configure(
		StringName(level.get("ambience", &"meadow_breeze")),
		secondary,
		_background_color("accent", highlight),
		map_size,
		surround_size,
		int(level.get("run_seed", 1)) + int(level.get("overall_hole_number", 1)) * 7919
	)
	level_root.add_child(ambience)


func _create_floor(level: Dictionary) -> void:
	var body := StaticBody2D.new()
	body.name = "Green"
	body.collision_layer = 2
	body.collision_mask = 1
	level_root.add_child(body)

	for cell in _playable_cells(level):
		var cell_center := _cell_to_world(level, cell)

		var visual := Polygon2D.new()
		visual.position = cell_center
		visual.name = "FairwayCell_%d_%d" % [cell.x, cell.y]
		visual.polygon = _rectangle_polygon(Vector2(GRID_CELL_SIZE + 2.0, GRID_CELL_SIZE + 2.0))
		visual.color = _terrain_color("fairway_a", GREEN_DARK) if (cell.x + cell.y) % 2 == 0 else _terrain_color("fairway_b", GREEN_DARKER)
		body.add_child(visual)
		if (cell.x * 3 + cell.y) % 4 == 0:
			var grain := Line2D.new()
			grain.name = "FairwayGrain_%d_%d" % [cell.x, cell.y]
			grain.position = cell_center
			grain.width = 2.0
			grain.default_color = Color(_terrain_color("fairway_detail", visual.color.lightened(0.08)), 0.28)
			grain.points = PackedVector2Array([Vector2(-24.0, 18.0), Vector2(-8.0, 15.0), Vector2(9.0, 18.0)])
			body.add_child(grain)

		var collision := CollisionShape2D.new()
		collision.position = cell_center
		var shape := RectangleShape2D.new()
		shape.size = Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE)
		collision.shape = shape
		body.add_child(collision)


func _create_bounds(level: Dictionary) -> void:
	var directions := [
		{"cell": Vector2i(0, -1), "offset": Vector2(0.0, -GRID_CELL_SIZE / 2.0 - WALL_THICKNESS / 2.0), "size": Vector2(GRID_CELL_SIZE, WALL_THICKNESS)},
		{"cell": Vector2i(1, 0), "offset": Vector2(GRID_CELL_SIZE / 2.0 + WALL_THICKNESS / 2.0, 0.0), "size": Vector2(WALL_THICKNESS, GRID_CELL_SIZE)},
		{"cell": Vector2i(0, 1), "offset": Vector2(0.0, GRID_CELL_SIZE / 2.0 + WALL_THICKNESS / 2.0), "size": Vector2(GRID_CELL_SIZE, WALL_THICKNESS)},
		{"cell": Vector2i(-1, 0), "offset": Vector2(-GRID_CELL_SIZE / 2.0 - WALL_THICKNESS / 2.0, 0.0), "size": Vector2(WALL_THICKNESS, GRID_CELL_SIZE)}
	]
	var corners := [
		{"side_a": Vector2i(0, -1), "side_b": Vector2i(-1, 0), "offset": Vector2(-GRID_CELL_SIZE / 2.0 - WALL_THICKNESS / 2.0, -GRID_CELL_SIZE / 2.0 - WALL_THICKNESS / 2.0)},
		{"side_a": Vector2i(0, -1), "side_b": Vector2i(1, 0), "offset": Vector2(GRID_CELL_SIZE / 2.0 + WALL_THICKNESS / 2.0, -GRID_CELL_SIZE / 2.0 - WALL_THICKNESS / 2.0)},
		{"side_a": Vector2i(0, 1), "side_b": Vector2i(1, 0), "offset": Vector2(GRID_CELL_SIZE / 2.0 + WALL_THICKNESS / 2.0, GRID_CELL_SIZE / 2.0 + WALL_THICKNESS / 2.0)},
		{"side_a": Vector2i(0, 1), "side_b": Vector2i(-1, 0), "offset": Vector2(-GRID_CELL_SIZE / 2.0 - WALL_THICKNESS / 2.0, GRID_CELL_SIZE / 2.0 + WALL_THICKNESS / 2.0)}
	]
	var created_corners := {}

	for cell in _playable_cells(level):
		var cell_center := _cell_to_world(level, cell)
		for direction in directions:
			var neighbor: Vector2i = cell + direction.cell
			if not _is_playable_cell(level, neighbor):
				_create_box(cell_center + direction.offset, direction.size, _terrain_color("border", BORDER_BROWN))

		for corner in corners:
			if _is_playable_cell(level, cell + corner.side_a) or _is_playable_cell(level, cell + corner.side_b):
				continue

			var corner_position: Vector2 = cell_center + corner.offset
			var corner_key := "%d,%d" % [roundi(corner_position.x), roundi(corner_position.y)]
			if created_corners.has(corner_key):
				continue

			created_corners[corner_key] = true
			_create_box(corner_position, Vector2(WALL_THICKNESS, WALL_THICKNESS), _terrain_color("border", BORDER_BROWN))


func _create_box(pos: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	level_root.add_child(body)

	var shadow := Polygon2D.new()
	shadow.name = "CollisionShadow"
	shadow.position = Vector2(4.0, 5.0)
	shadow.polygon = CourseVisualFactory.rounded_rectangle_polygon(size, 7.0)
	shadow.color = Color(0.03, 0.035, 0.04, 0.46)
	body.add_child(shadow)

	var visual := Polygon2D.new()
	visual.name = "CollisionVisual"
	visual.polygon = CourseVisualFactory.rounded_rectangle_polygon(size, 7.0)
	visual.color = color
	body.add_child(visual)

	var highlight := Line2D.new()
	highlight.name = "CollisionHighlight"
	highlight.width = 2.0
	highlight.default_color = Color(color.lightened(0.22), 0.7)
	highlight.points = PackedVector2Array([Vector2(-size.x * 0.36, -size.y * 0.3), Vector2(size.x * 0.36, -size.y * 0.3)])
	body.add_child(highlight)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _create_hole(pos: Vector2, radius: float) -> void:
	var green := CourseVisualFactory.create_green_patch(
		_terrain_color("green", _terrain_color("fairway_a", GREEN_DARK).lightened(0.18)),
		Color(_terrain_color("outline", BORDER_BROWN.darkened(0.25)), 0.48),
		radius
	)
	green.position = pos
	level_root.add_child(green)
	_create_hole_depth_visual(pos, radius)
	_create_hole_flag(pos)

	var area := Area2D.new()
	area.name = "Hole"
	area.position = pos
	area.body_entered.connect(_on_hole_body_entered)
	level_root.add_child(area)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	area.add_child(collision)


func _create_hole_depth_visual(pos: Vector2, radius: float) -> void:
	var fairway_color := _terrain_color("fairway_a", GREEN_DARK)
	var ring_colors := [
		Color(fairway_color.r, fairway_color.g, fairway_color.b, 0.15),
		Color(0.13, 0.28, 0.14, 0.45),
		Color(0.06, 0.12, 0.065, 0.78),
		Color(0.02, 0.018, 0.015, 1.0)
	]
	var radius_scale := radius / 28.0
	var ring_sizes := [
		Vector2(44.0, 28.0) * radius_scale,
		Vector2(38.0, 24.0) * radius_scale,
		Vector2(32.0, 20.0) * radius_scale,
		Vector2(27.0, 17.0) * radius_scale
	]

	for i in range(ring_sizes.size()):
		var ring := Polygon2D.new()
		ring.position = pos
		ring.polygon = _ellipse_polygon(ring_sizes[i])
		ring.color = ring_colors[i]
		level_root.add_child(ring)


func _create_hole_flag(pos: Vector2) -> void:
	var flag_root := CourseVisualFactory.create_flag(
		_terrain_color("flag", Color("d9534f")),
		_terrain_color("outline", Color("252a2c"))
	)
	flag_root.position = pos
	level_root.add_child(flag_root)


func _create_start_marker(pos: Vector2) -> void:
	var marker := CourseVisualFactory.create_start_marker(
		_terrain_color("tee", _terrain_color("fairway_a", GREEN_DARK).lightened(0.24)),
		_terrain_color("outline", BORDER_BROWN.darkened(0.25))
	)
	marker.position = pos
	level_root.add_child(marker)


func _create_hazards(level: Dictionary) -> void:
	for hazard in level.hazards:
		if not _hazard_fits_playable_map(level, hazard):
			push_warning("Skipping %s hazard because it does not fit the playable grid." % hazard.get("type", "unknown"))
			continue

		match hazard.type:
			"sand":
				_create_sand_tile(hazard.pos, hazard.size)
			"rough":
				_create_rough_tile(hazard.pos, hazard.size)
			"water":
				_create_water_tile(hazard.pos, hazard.size)
			"out":
				_create_out_tile(hazard.pos, hazard.size)
			"direction":
				_create_direction_tile(hazard.pos, hazard.size, hazard.direction.normalized())


func _create_sand_tile(pos: Vector2, size: Vector2) -> void:
	var area := _create_hazard_area("Sand", "sand", pos, size, _terrain_color("sand", Color(0.78, 0.62, 0.36, 0.95)), _terrain_color("sand_detail", Color("f2d99a")))
	area.body_entered.connect(_on_sand_body_entered)
	area.body_exited.connect(_on_sand_body_exited)


func _create_rough_tile(pos: Vector2, size: Vector2) -> void:
	var area := _create_hazard_area("Rough", "rough", pos, size, _terrain_color("rough", Color(0.12, 0.36, 0.14, 0.92)), _terrain_color("rough_detail", Color("73a86f")))
	area.body_entered.connect(_on_rough_body_entered)
	area.body_exited.connect(_on_rough_body_exited)


func _create_water_tile(pos: Vector2, size: Vector2) -> void:
	var area := _create_hazard_area("Water", "water", pos, size, _terrain_color("water", Color(0.35, 0.72, 0.95, 0.9)), _terrain_color("water_detail", Color("a8e4f5")))
	area.body_entered.connect(_on_water_body_entered.bind(pos))


func _create_out_tile(pos: Vector2, size: Vector2) -> void:
	var area := _create_hazard_area("OutOfBounds", "out", pos, size, _terrain_color("out", Color(0.72, 0.08, 0.08, 0.82)), _terrain_color("out_detail", Color("f59a85")))
	area.body_entered.connect(_on_out_body_entered.bind(pos))


func _create_direction_tile(pos: Vector2, size: Vector2, direction: Vector2) -> void:
	var area := _create_hazard_area("Direction", "direction", pos, size, _terrain_color("direction", Color(0.52, 0.72, 0.62, 0.9)), _terrain_color("direction_detail", Color("e8f4de")))
	area.set_meta("direction", direction)
	area.body_entered.connect(_on_direction_body_entered.bind(area))
	area.body_exited.connect(_on_direction_body_exited.bind(area))

	var arrow := Line2D.new()
	arrow.width = 5.0
	arrow.default_color = _terrain_color("direction_detail", Color("e8f4de"))
	arrow.points = PackedVector2Array([-direction * 24.0, direction * 24.0])
	area.add_child(arrow)

	var head := Polygon2D.new()
	head.position = direction * 24.0
	head.rotation = direction.angle()
	head.polygon = PackedVector2Array([
		Vector2(12.0, 0.0),
		Vector2(-8.0, -7.0),
		Vector2(-8.0, 7.0)
	])
	head.color = _terrain_color("direction_detail", Color("e8f4de"))
	area.add_child(head)


func _create_hazard_area(name: String, hazard_type: String, pos: Vector2, size: Vector2, color: Color, detail_color: Color) -> Area2D:
	var area := Area2D.new()
	area.name = name
	area.position = pos
	level_root.add_child(area)

	var visual := CourseVisualFactory.create_hazard_visual(
		hazard_type,
		size,
		color,
		detail_color,
		Color(_terrain_color("outline", BORDER_BROWN.darkened(0.25)), 0.82)
	)
	area.add_child(visual)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)

	return area


func _create_decorations(level: Dictionary) -> void:
	var decoration_ids: PackedStringArray = level.get("decoration_identifiers", PackedStringArray())
	if decoration_ids.is_empty():
		return

	var rows: Array = level.map
	var columns := 0
	for row in rows:
		columns = maxi(columns, String(row).length())
	var map_size := Vector2(float(columns), float(rows.size())) * GRID_CELL_SIZE
	var primary := _background_color("highlight", Color(0.46, 0.65, 0.4))
	var secondary := _background_color("secondary", Color(0.36, 0.55, 0.3))
	var accent := _background_color("accent", primary.lightened(0.2))
	for i in range(decoration_ids.size()):
		for copy_index in range(2):
			var decoration := CourseVisualFactory.create_decoration(String(decoration_ids[i]), primary, secondary, accent)
			decoration.name = "Decoration_%s_%d" % [decoration_ids[i], copy_index + 1]
			if i % 2 == 0:
				decoration.position = Vector2(
					lerpf(-map_size.x * 0.38, map_size.x * 0.38, float(i + copy_index) / float(decoration_ids.size())),
					(-1.0 if copy_index == 0 else 1.0) * (map_size.y * 0.5 + 70.0 + float(i) * 10.0)
				)
			else:
				decoration.position = Vector2(
					(-1.0 if copy_index == 0 else 1.0) * (map_size.x * 0.5 + 75.0 + float(i) * 12.0),
					lerpf(-map_size.y * 0.32, map_size.y * 0.32, float(i) / float(decoration_ids.size() - 1))
				)
			decoration.rotation = (float(i) - 1.5) * 0.08 * (-1.0 if copy_index == 0 else 1.0)
			decoration.scale = Vector2.ONE * (0.9 + float((i + copy_index) % 3) * 0.1)
			level_root.add_child(decoration)


func _terrain_color(key: String, fallback: Color) -> Color:
	return active_terrain_palette.get(key, fallback)


func _background_color(key: String, fallback: Color) -> Color:
	return active_background_palette.get(key, fallback)


func _on_hole_body_entered(body: Node2D) -> void:
	hole_body_entered.emit(body)


func _on_sand_body_entered(body: Node2D) -> void:
	sand_body_entered.emit(body)


func _on_sand_body_exited(body: Node2D) -> void:
	sand_body_exited.emit(body)


func _on_rough_body_entered(body: Node2D) -> void:
	rough_body_entered.emit(body)


func _on_rough_body_exited(body: Node2D) -> void:
	rough_body_exited.emit(body)


func _on_water_body_entered(body: Node2D, water_position: Vector2) -> void:
	water_body_entered.emit(body, water_position)


func _on_out_body_entered(body: Node2D, out_position: Vector2) -> void:
	out_body_entered.emit(body, out_position)


func _on_direction_body_entered(body: Node2D, area: Area2D) -> void:
	direction_body_entered.emit(body, area)


func _on_direction_body_exited(body: Node2D, area: Area2D) -> void:
	direction_body_exited.emit(body, area)


func _playable_cells(level: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var rows: Array = level.map
	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var cell := Vector2i(x, y)
			if _is_playable_cell(level, cell):
				cells.append(cell)
	return cells


func _is_playable_cell(level: Dictionary, cell: Vector2i) -> bool:
	var rows: Array = level.map
	if cell.y < 0 or cell.y >= rows.size():
		return false

	var row: String = rows[cell.y]
	if cell.x < 0 or cell.x >= row.length():
		return false

	return row[cell.x] != " "


func _hazard_fits_playable_map(level: Dictionary, hazard: Dictionary) -> bool:
	if not hazard.has("pos") or not hazard.has("size"):
		return false

	var size: Vector2 = hazard.size
	if size.x <= 0.0 or size.y <= 0.0:
		return false

	var rect := Rect2(hazard.pos - size / 2.0, size)
	var top_left := _map_top_left(level)
	if not _rect_aligns_to_grid(rect, top_left):
		return false

	var min_cell := Vector2i(
		floori((rect.position.x - top_left.x) / GRID_CELL_SIZE),
		floori((rect.position.y - top_left.y) / GRID_CELL_SIZE)
	)
	var max_cell := Vector2i(
		floori((rect.end.x - top_left.x - 0.001) / GRID_CELL_SIZE),
		floori((rect.end.y - top_left.y - 0.001) / GRID_CELL_SIZE)
	)

	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			if not _is_playable_cell(level, Vector2i(x, y)):
				return false

	return true


func _rect_aligns_to_grid(rect: Rect2, grid_origin: Vector2) -> bool:
	return (
		_value_aligns_to_grid(rect.position.x, grid_origin.x)
		and _value_aligns_to_grid(rect.position.y, grid_origin.y)
		and _value_aligns_to_grid(rect.end.x, grid_origin.x)
		and _value_aligns_to_grid(rect.end.y, grid_origin.y)
	)


func _value_aligns_to_grid(value: float, origin: float) -> bool:
	var cell_position := (value - origin) / GRID_CELL_SIZE
	return absf(cell_position - roundf(cell_position)) < 0.001


func _cell_to_world(level: Dictionary, cell: Vector2i) -> Vector2:
	return _map_top_left(level) + Vector2(float(cell.x) + 0.5, float(cell.y) + 0.5) * GRID_CELL_SIZE


func _map_top_left(level: Dictionary) -> Vector2:
	return -_map_size(level) / 2.0


func _map_size(level: Dictionary) -> Vector2:
	var rows: Array = level.map
	var columns := 0
	for row in rows:
		columns = maxi(columns, String(row).length())
	return Vector2(float(columns), float(rows.size())) * GRID_CELL_SIZE


func _ellipse_polygon(radii: Vector2, segments := 32) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


func _rectangle_polygon(size: Vector2) -> PackedVector2Array:
	var half_size := size / 2.0
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])
