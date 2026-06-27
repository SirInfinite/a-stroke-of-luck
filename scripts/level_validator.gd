class_name LevelValidator
extends RefCounted

const GRID_CELL_SIZE := 100.0


static func validate_level(level: Dictionary, level_index: int) -> bool:
	var is_valid := true
	var label := "Level %d" % [level_index + 1]

	if not _has_valid_map(level, label):
		return false

	if not level.has("start_cell"):
		push_warning("%s is missing start_cell." % label)
		is_valid = false
	elif not (level.start_cell is Vector2i):
		push_warning("%s start_cell must be a Vector2i." % label)
		is_valid = false
	if not level.has("hole_cell"):
		push_warning("%s is missing hole_cell." % label)
		is_valid = false
	elif not (level.hole_cell is Vector2i):
		push_warning("%s hole_cell must be a Vector2i." % label)
		is_valid = false
	if not level.has("hazards"):
		push_warning("%s is missing hazards; expected an Array." % label)
		is_valid = false
	elif not (level.hazards is Array):
		push_warning("%s hazards must be an Array." % label)
		is_valid = false

	if not level.has("start_cell") or not (level.start_cell is Vector2i) or not level.has("hole_cell") or not (level.hole_cell is Vector2i):
		return false

	var start_cell: Vector2i = level.start_cell
	var hole_cell: Vector2i = level.hole_cell

	if not _is_playable_cell(level, start_cell):
		push_warning("%s start_cell %s is not playable." % [label, start_cell])
		is_valid = false
	if not _is_playable_cell(level, hole_cell):
		push_warning("%s hole_cell %s is not playable." % [label, hole_cell])
		is_valid = false

	if level.has("hazards") and level.hazards is Array:
		for i in range(level.hazards.size()):
			if not (level.hazards[i] is Dictionary):
				push_warning("%s hazard %d must be a Dictionary." % [label, i + 1])
				is_valid = false
				continue

			var hazard: Dictionary = level.hazards[i]
			if not _hazard_fits_playable_map(level, hazard):
				push_warning("%s hazard %d (%s) does not fit on playable cells." % [label, i + 1, hazard.get("type", "unknown")])
				is_valid = false

	if _is_playable_cell(level, start_cell) and _is_playable_cell(level, hole_cell) and not _has_connected_path(level, start_cell, hole_cell):
		push_warning("%s has no connected grid path from start_cell %s to hole_cell %s." % [label, start_cell, hole_cell])
		is_valid = false

	return is_valid


static func _has_valid_map(level: Dictionary, label: String) -> bool:
	if not level.has("map"):
		push_warning("%s is missing map." % label)
		return false
	if not (level.map is Array):
		push_warning("%s map must be an Array of row strings." % label)
		return false
	if level.map.is_empty():
		push_warning("%s map must have at least one row." % label)
		return false

	var has_playable_cell := false
	for y in range(level.map.size()):
		if not (level.map[y] is String):
			push_warning("%s map row %d must be a String." % [label, y])
			return false
		if String(level.map[y]).is_empty():
			push_warning("%s map row %d is empty." % [label, y])
			return false
		for x in range(String(level.map[y]).length()):
			if String(level.map[y])[x] != " ":
				has_playable_cell = true

	if not has_playable_cell:
		push_warning("%s map has no playable cells." % label)
		return false

	return true


static func _has_connected_path(level: Dictionary, start_cell: Vector2i, hole_cell: Vector2i) -> bool:
	var visited := {}
	var queue: Array[Vector2i] = [start_cell]
	var directions: Array[Vector2i] = [
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 0)
	]
	visited[start_cell] = true

	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell == hole_cell:
			return true

		for direction in directions:
			var neighbor := cell + direction
			if visited.has(neighbor) or not _is_playable_cell(level, neighbor):
				continue
			visited[neighbor] = true
			queue.append(neighbor)

	return false


static func _is_playable_cell(level: Dictionary, cell: Vector2i) -> bool:
	if not level.has("map") or not (level.map is Array):
		return false

	var rows: Array = level.map
	if cell.y < 0 or cell.y >= rows.size():
		return false
	if not (rows[cell.y] is String):
		return false

	var row := String(rows[cell.y])
	if cell.x < 0 or cell.x >= row.length():
		return false

	return row[cell.x] != " "


static func _hazard_fits_playable_map(level: Dictionary, hazard: Dictionary) -> bool:
	if not hazard.has("pos") or not hazard.has("size"):
		return false
	if not (hazard.pos is Vector2) or not (hazard.size is Vector2):
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


static func _rect_aligns_to_grid(rect: Rect2, grid_origin: Vector2) -> bool:
	return (
		_value_aligns_to_grid(rect.position.x, grid_origin.x)
		and _value_aligns_to_grid(rect.position.y, grid_origin.y)
		and _value_aligns_to_grid(rect.end.x, grid_origin.x)
		and _value_aligns_to_grid(rect.end.y, grid_origin.y)
	)


static func _value_aligns_to_grid(value: float, origin: float) -> bool:
	var cell_position := (value - origin) / GRID_CELL_SIZE
	return absf(cell_position - roundf(cell_position)) < 0.001


static func _map_top_left(level: Dictionary) -> Vector2:
	if not level.has("map") or not (level.map is Array):
		return Vector2.ZERO

	var rows: Array = level.map
	var columns := 0
	for row in rows:
		columns = maxi(columns, String(row).length())

	var map_size := Vector2(float(columns), float(rows.size())) * GRID_CELL_SIZE
	return -map_size / 2.0
