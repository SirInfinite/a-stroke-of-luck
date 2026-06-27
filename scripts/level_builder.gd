class_name LevelBuilder
extends Node

signal hole_body_entered(body: Node2D)
signal sand_body_entered(body: Node2D)
signal sand_body_exited(body: Node2D)
signal water_body_entered(body: Node2D, water_position: Vector2)
signal direction_body_entered(body: Node2D, area: Area2D)
signal direction_body_exited(body: Node2D, area: Area2D)

const GRID_CELL_SIZE := 100.0
const WALL_THICKNESS := 30.0
const GREEN_DARK := Color(0.232, 0.554, 0.248, 1.0)
const GREEN_DARKER := Color(0.161, 0.447, 0.201, 1.0)
const BORDER_BROWN := Color(0.34, 0.19, 0.09)
const HOLE_SCALE := 0.75
const FLAG_OFFSET := Vector2(-7.0, 7.0)

var level_root: Node2D


func build_level(level: Dictionary, parent: Node) -> Node2D:
	level_root = Node2D.new()
	level_root.name = "Level"
	level_root.z_index = -1
	parent.add_child(level_root)

	_create_course(level)
	_create_hole(level_point(level, "hole", "hole_cell"))
	_create_hazards(level)

	for obstacle in level.obstacles:
		_create_box(obstacle.pos, obstacle.size, BORDER_BROWN)

	return level_root


func level_point(level: Dictionary, world_key: String, cell_key: String) -> Vector2:
	if level.has(cell_key):
		return _cell_to_world(level, level[cell_key])
	return level.get(world_key, Vector2.ZERO)


func _create_course(level: Dictionary) -> void:
	_create_floor(level)
	_create_bounds(level)


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
		visual.polygon = _rectangle_polygon(Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE))
		visual.color = GREEN_DARK if (cell.x + cell.y) % 2 == 0 else GREEN_DARKER
		body.add_child(visual)

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
				_create_box(cell_center + direction.offset, direction.size, BORDER_BROWN)

		for corner in corners:
			if _is_playable_cell(level, cell + corner.side_a) or _is_playable_cell(level, cell + corner.side_b):
				continue

			var corner_position: Vector2 = cell_center + corner.offset
			var corner_key := "%d,%d" % [roundi(corner_position.x), roundi(corner_position.y)]
			if created_corners.has(corner_key):
				continue

			created_corners[corner_key] = true
			_create_box(corner_position, Vector2(WALL_THICKNESS, WALL_THICKNESS), BORDER_BROWN)


func _create_box(pos: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	level_root.add_child(body)

	var visual := Polygon2D.new()
	visual.polygon = _rectangle_polygon(size)
	visual.color = color
	body.add_child(visual)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _create_hole(pos: Vector2) -> void:
	_create_hole_depth_visual(pos)
	_create_hole_flag(pos)

	var area := Area2D.new()
	area.name = "Hole"
	area.position = pos
	area.body_entered.connect(_on_hole_body_entered)
	level_root.add_child(area)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 28.0 * HOLE_SCALE
	collision.shape = shape
	area.add_child(collision)


func _create_hole_depth_visual(pos: Vector2) -> void:
	var ring_colors := [
		Color(GREEN_DARK.r, GREEN_DARK.g, GREEN_DARK.b, 0.15),
		Color(0.13, 0.28, 0.14, 0.45),
		Color(0.06, 0.12, 0.065, 0.78),
		Color(0.02, 0.018, 0.015, 1.0)
	]
	var ring_sizes := [
		Vector2(44.0, 28.0) * HOLE_SCALE,
		Vector2(38.0, 24.0) * HOLE_SCALE,
		Vector2(32.0, 20.0) * HOLE_SCALE,
		Vector2(27.0, 17.0) * HOLE_SCALE
	]

	for i in range(ring_sizes.size()):
		var ring := Polygon2D.new()
		ring.position = pos
		ring.polygon = _ellipse_polygon(ring_sizes[i])
		ring.color = ring_colors[i]
		level_root.add_child(ring)


func _create_hole_flag(pos: Vector2) -> void:
	var flag_root := Node2D.new()
	flag_root.position = pos + FLAG_OFFSET
	level_root.add_child(flag_root)

	var segment_height := 14.0
	var stem_top := -78.0
	var stem_bottom := -8.0
	var segment_index := 0
	for y in range(int(stem_bottom), int(stem_top), -int(segment_height)):
		var next_y := maxf(float(y) - segment_height, stem_top)
		var segment := Line2D.new()
		segment.width = 4.0
		segment.default_color = Color.WHITE if segment_index % 2 == 0 else Color(0.85, 0.05, 0.04)
		segment.points = PackedVector2Array([Vector2(0.0, float(y)), Vector2(0.0, next_y)])
		flag_root.add_child(segment)
		segment_index += 1

	var flag := Polygon2D.new()
	flag.polygon = PackedVector2Array([
		Vector2(3.0, stem_top),
		Vector2(51.0, stem_top + 13.0),
		Vector2(3.0, stem_top + 26.0)
	])
	flag.color = Color(0.9, 0.03, 0.03)
	flag_root.add_child(flag)

	var separator := Line2D.new()
	separator.width = 3.0
	separator.default_color = Color(0.32, 0.0, 0.0)
	separator.points = PackedVector2Array([Vector2(4.0, stem_top), Vector2(4.0, stem_top + 26.0)])
	flag_root.add_child(separator)


func _create_hazards(level: Dictionary) -> void:
	for hazard in level.hazards:
		if not _hazard_fits_playable_map(level, hazard):
			push_warning("Skipping %s hazard because it does not fit the playable grid." % hazard.get("type", "unknown"))
			continue

		match hazard.type:
			"sand":
				_create_sand_tile(hazard.pos, hazard.size)
			"water":
				_create_water_tile(hazard.pos, hazard.size)
			"direction":
				_create_direction_tile(hazard.pos, hazard.size, hazard.direction.normalized())


func _create_sand_tile(pos: Vector2, size: Vector2) -> void:
	var area := _create_hazard_area("Sand", pos, size, Color(0.78, 0.62, 0.36, 0.95))
	area.body_entered.connect(_on_sand_body_entered)
	area.body_exited.connect(_on_sand_body_exited)


func _create_water_tile(pos: Vector2, size: Vector2) -> void:
	var area := _create_hazard_area("Water", pos, size, Color(0.35, 0.72, 0.95, 0.9))
	area.body_entered.connect(_on_water_body_entered.bind(pos))


func _create_direction_tile(pos: Vector2, size: Vector2, direction: Vector2) -> void:
	var area := _create_hazard_area("Direction", pos, size, Color(0.52, 0.72, 0.62, 0.9))
	area.set_meta("direction", direction)
	area.body_entered.connect(_on_direction_body_entered.bind(area))
	area.body_exited.connect(_on_direction_body_exited.bind(area))

	var arrow := Line2D.new()
	arrow.width = 5.0
	arrow.default_color = Color(0.08, 0.18, 0.12, 0.95)
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
	head.color = Color(0.08, 0.18, 0.12, 0.95)
	area.add_child(head)


func _create_hazard_area(name: String, pos: Vector2, size: Vector2, color: Color) -> Area2D:
	var area := Area2D.new()
	area.name = name
	area.position = pos
	level_root.add_child(area)

	var visual := Polygon2D.new()
	visual.polygon = _rectangle_polygon(size)
	visual.color = color
	area.add_child(visual)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)

	return area


func _on_hole_body_entered(body: Node2D) -> void:
	hole_body_entered.emit(body)


func _on_sand_body_entered(body: Node2D) -> void:
	sand_body_entered.emit(body)


func _on_sand_body_exited(body: Node2D) -> void:
	sand_body_exited.emit(body)


func _on_water_body_entered(body: Node2D, water_position: Vector2) -> void:
	water_body_entered.emit(body, water_position)


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
	var rows: Array = level.map
	var columns := 0
	for row in rows:
		columns = maxi(columns, String(row).length())

	var map_size := Vector2(float(columns), float(rows.size())) * GRID_CELL_SIZE
	return -map_size / 2.0


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
