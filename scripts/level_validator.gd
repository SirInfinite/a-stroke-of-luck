class_name LevelValidator
extends RefCounted

const GameplayHazardScript := preload("res://scripts/gameplay_hazard.gd")

const GRID_CELL_SIZE := 100.0
const MIN_ELEVATION := -1
const MAX_ELEVATION := 1
const STATIC_HAZARD_TYPES := ["sand", "water", "lava", "ice", "direction", "bounce_pad"]
const MOVING_HAZARD_TYPES := ["pendulum", "falling_ice", "rotating_fire_rod"]
const STRUCTURE_TYPES := ["hill", "pit", "lower_area", "bridge", "overpass"]
const BRANCH_TYPES := ["alternate", "dead_end", "shortcut"]
const REQUIRED_BUILDER_FIELDS := ["map", "start_cell", "hole_cell", "par", "hazards", "obstacles"]


static func validate_level(level: Dictionary, level_index: int, report_errors := true) -> bool:
	var label := "Level %d" % [level_index + 1] if report_errors else ""
	if not _has_valid_map(level, label):
		return false

	var is_valid := _validate_required_builder_fields(level, label)
	if not is_valid:
		return false

	var start_cell: Vector2i = level.start_cell
	var hole_cell: Vector2i = level.hole_cell
	if not _is_playable_cell(level, start_cell):
		_warn(label, "start_cell %s is not playable." % start_cell)
		is_valid = false
	if not _is_playable_cell(level, hole_cell):
		_warn(label, "hole_cell %s is not playable." % hole_cell)
		is_valid = false

	var elevation_result := _validate_elevation_contract(level, label)
	var elevation_lookup: Dictionary = elevation_result.lookup
	is_valid = bool(elevation_result.valid) and is_valid
	var start_elevation := int(level.get("start_elevation", 0))
	var hole_elevation := int(level.get("hole_elevation", 0))
	if not _surface_exists(elevation_lookup, start_cell, start_elevation):
		_warn(label, "start elevation %d has no surface at %s." % [start_elevation, start_cell])
		is_valid = false
	if not _surface_exists(elevation_lookup, hole_cell, hole_elevation):
		_warn(label, "hole elevation %d has no surface at %s." % [hole_elevation, hole_cell])
		is_valid = false

	is_valid = _validate_main_route(level, elevation_lookup, label) and is_valid
	is_valid = _validate_obstacles(level, elevation_lookup, label) and is_valid
	is_valid = _validate_static_hazards(level, elevation_lookup, label) and is_valid
	is_valid = _validate_moving_hazards(level, elevation_lookup, label) and is_valid
	is_valid = _validate_placement_occupancy(level, label) and is_valid
	is_valid = _validate_endpoint_safety(level, label) and is_valid
	is_valid = _validate_branches(level, label) and is_valid
	is_valid = _validate_optional_builder_fields(level, elevation_lookup, label) and is_valid

	if is_valid and not _has_connected_elevation_path(
		level,
		elevation_lookup,
		start_cell,
		start_elevation,
		hole_cell,
		hole_elevation
	):
		_warn(label, "has no valid elevation path from start to cup.")
		is_valid = false

	if is_valid and int(level.get("grammar_version", 0)) >= 2:
		var errors := generation_errors(level)
		for error in errors:
			_warn(label, error)
		is_valid = errors.is_empty()
	return is_valid


static func required_builder_fields() -> Array[String]:
	var fields: Array[String] = []
	for field_name in REQUIRED_BUILDER_FIELDS:
		fields.append(String(field_name))
	return fields


static func cell_elevations(level: Dictionary, cell: Vector2i) -> Array[int]:
	if not level.has("elevation_cells"):
		# A conditional array expression loses its element type in Godot 4.6.
		var flat_levels: Array[int] = []
		if _is_playable_cell(level, cell):
			flat_levels.append(0)
		return flat_levels
	for entry in level.elevation_cells:
		if entry is Dictionary and entry.get("cell") is Vector2i and Vector2i(entry.cell) == cell:
			var result: Array[int] = []
			for elevation in entry.get("levels", []):
				result.append(int(elevation))
			return result
	return []


static func placement_occupancy(level: Dictionary) -> Dictionary:
	var occupancy := {}
	for collection_name in ["hazards", "obstacles", "moving_hazards"]:
		var entries = level.get(collection_name, [])
		if not entries is Array:
			continue
		for entry_index in range(entries.size()):
			var definition = entries[entry_index]
			if not definition is Dictionary:
				continue
			if not definition.get("pos") is Vector2 or not definition.get("size") is Vector2:
				continue
			var placement_id := "%s:%d" % [collection_name, entry_index]
			for surface in _definition_surfaces(level, definition):
				if not occupancy.has(surface):
					occupancy[surface] = []
				occupancy[surface].append(placement_id)
	return occupancy


static func _validate_main_route(level: Dictionary, elevation_lookup: Dictionary, label: String) -> bool:
	var route = level.get("main_route_cells", [])
	if route is Array and route.is_empty():
		return true
	if not route is Array:
		_warn(label, "main_route_cells must be an Array.")
		return false
	if route.size() < 2:
		_warn(label, "main_route_cells must connect tee to cup.")
		return false
	if not route[0] is Vector2i or Vector2i(route[0]) != Vector2i(level.start_cell):
		_warn(label, "main route must begin at start_cell.")
		return false
	if not route[-1] is Vector2i or Vector2i(route[-1]) != Vector2i(level.hole_cell):
		_warn(label, "main route must end at hole_cell.")
		return false

	var valid := true
	var seen := {}
	var route_elevation := int(level.get("main_route_elevation", level.get("start_elevation", 0)))
	var occupancy := placement_occupancy(level)
	for route_index in range(route.size()):
		if not route[route_index] is Vector2i:
			_warn(label, "main route entry %d must be a Vector2i." % (route_index + 1))
			valid = false
			continue
		var cell := Vector2i(route[route_index])
		if seen.has(cell):
			_warn(label, "main route repeats cell %s." % cell)
			valid = false
		seen[cell] = true
		if not _is_playable_cell(level, cell) or not _surface_exists(elevation_lookup, cell, route_elevation):
			_warn(label, "main route cell %s has no playable route surface." % cell)
			valid = false
		if route_index > 0 and route[route_index - 1] is Vector2i:
			if _manhattan_distance(Vector2i(route[route_index - 1]), cell) != 1:
				_warn(label, "main route cells must be cardinally contiguous.")
				valid = false
		var surface := Vector3i(cell.x, cell.y, route_elevation)
		if occupancy.has(surface):
			_warn(label, "main route surface %s is occupied by %s." % [surface, ", ".join(occupancy[surface])])
			valid = false
	return valid


static func _validate_placement_occupancy(level: Dictionary, label: String) -> bool:
	var valid := true
	var occupancy := placement_occupancy(level)
	for surface in occupancy:
		var placements: Array = occupancy[surface]
		if placements.size() > 1:
			_warn(label, "surface %s has conflicting placements: %s." % [surface, ", ".join(placements)])
			valid = false
	return valid


static func _validate_endpoint_safety(level: Dictionary, label: String) -> bool:
	var valid := true
	var endpoints := [
		Vector3i(level.start_cell.x, level.start_cell.y, int(level.get("start_elevation", 0))),
		Vector3i(level.hole_cell.x, level.hole_cell.y, int(level.get("hole_elevation", 0))),
	]
	var occupancy := placement_occupancy(level)
	for endpoint in endpoints:
		for surface in occupancy:
			var occupied_surface := Vector3i(surface)
			if endpoint.z != occupied_surface.z:
				continue
			if _manhattan_distance(Vector2i(endpoint.x, endpoint.y), Vector2i(occupied_surface.x, occupied_surface.y)) <= 1:
				_warn(label, "tee/cup recovery space is occupied at %s." % occupied_surface)
				valid = false
	return valid


static func _definition_surfaces(level: Dictionary, definition: Dictionary) -> Array[Vector3i]:
	var surfaces: Array[Vector3i] = []
	var size := Vector2(definition.size)
	var center := Vector2(definition.pos)
	if not size.is_finite() or not center.is_finite() or not _is_elevation_value(definition.get("elevation", 0)):
		return surfaces
	var map_extent := _map_top_left(level).abs() * 2.0 + Vector2.ONE * GRID_CELL_SIZE
	if size.x > map_extent.x or size.y > map_extent.y or center.abs().x > map_extent.x or center.abs().y > map_extent.y:
		return surfaces
	if String(definition.get("type", "")) == "pendulum":
		if not _number(definition.get("travel_radius", 0.0)) or not _number(definition.get("swing_angle", 0.9)):
			return surfaces
		var radius := maxf(float(definition.get("travel_radius", 0.0)), 0.0)
		var angle := clampf(float(definition.get("swing_angle", 0.9)), 0.15, 1.45)
		var drop_min := cos(angle) * radius
		center.y += (drop_min + radius) * 0.5
		size += Vector2(sin(angle) * radius * 2.0, radius - drop_min)
	elif String(definition.get("type", "")) == "rotating_fire_rod":
		# All orientations, not just the unrotated rectangle.
		size = Vector2.ONE * size.length()
	# Motion parameters are content too: bound the expanded sweep before loops.
	if not size.is_finite() or not center.is_finite() or size.x > map_extent.x or size.y > map_extent.y:
		return surfaces
	var rect := Rect2(center - size / 2.0, size)
	var top_left := _map_top_left(level)
	var min_cell := Vector2i(
		floori((rect.position.x - top_left.x) / GRID_CELL_SIZE),
		floori((rect.position.y - top_left.y) / GRID_CELL_SIZE)
	)
	var max_cell := Vector2i(
		floori((rect.end.x - top_left.x - 0.001) / GRID_CELL_SIZE),
		floori((rect.end.y - top_left.y - 0.001) / GRID_CELL_SIZE)
	)
	var elevation := int(definition.get("elevation", 0))
	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			surfaces.append(Vector3i(x, y, elevation))
	return surfaces


static func _validate_required_builder_fields(level: Dictionary, label: String) -> bool:
	var valid := true
	for field_name in REQUIRED_BUILDER_FIELDS:
		if not level.has(field_name):
			_warn(label, "is missing builder field %s." % field_name)
			valid = false
	if not valid:
		return false
	if not (level.start_cell is Vector2i):
		_warn(label, "start_cell must be a Vector2i.")
		valid = false
	if not (level.hole_cell is Vector2i):
		_warn(label, "hole_cell must be a Vector2i.")
		valid = false
	if not (level.par is int) or int(level.par) <= 0:
		_warn(label, "par must be a positive int.")
		valid = false
	if not (level.hazards is Array):
		_warn(label, "hazards must be an Array.")
		valid = false
	if not (level.obstacles is Array):
		_warn(label, "obstacles must be an Array.")
		valid = false
	return valid


static func _validate_elevation_contract(level: Dictionary, label: String) -> Dictionary:
	var lookup := {}
	var valid := true
	if not level.has("elevation_cells"):
		for cell in _playable_cells(level):
			lookup[cell] = [0]
	else:
		if not (level.elevation_cells is Array):
			_warn(label, "elevation_cells must be an Array.")
			return {"valid": false, "lookup": lookup}
		for entry_index in range(level.elevation_cells.size()):
			var entry = level.elevation_cells[entry_index]
			if not (entry is Dictionary):
				_warn(label, "elevation cell %d must be a Dictionary." % (entry_index + 1))
				valid = false
				continue
			if not entry.get("cell") is Vector2i or not entry.get("levels") is Array:
				_warn(label, "elevation cell %d requires Vector2i cell and Array levels." % (entry_index + 1))
				valid = false
				continue
			var cell: Vector2i = entry.cell
			if not _is_playable_cell(level, cell):
				_warn(label, "elevation cell %s is not playable." % cell)
				valid = false
				continue
			if lookup.has(cell):
				_warn(label, "elevation cell %s is duplicated." % cell)
				valid = false
				continue
			var levels: Array[int] = []
			for raw_elevation in entry.levels:
				if not raw_elevation is int:
					_warn(label, "elevation at %s must be an int." % cell)
					valid = false
					continue
				var elevation := int(raw_elevation)
				if elevation < MIN_ELEVATION or elevation > MAX_ELEVATION or levels.has(elevation):
					_warn(label, "elevation %d at %s is invalid or duplicated." % [elevation, cell])
					valid = false
					continue
				levels.append(elevation)
			if levels.is_empty():
				_warn(label, "elevation cell %s has no levels." % cell)
				valid = false
			lookup[cell] = levels
		for cell in _playable_cells(level):
			if not lookup.has(cell):
				_warn(label, "playable cell %s has no elevation surface." % cell)
				valid = false

	if not _is_elevation_value(level.get("start_elevation", 0)):
		_warn(label, "start_elevation must be an int from -1 through 1.")
		valid = false
	if not _is_elevation_value(level.get("hole_elevation", 0)):
		_warn(label, "hole_elevation must be an int from -1 through 1.")
		valid = false

	var transitions = level.get("elevation_transitions", [])
	if not transitions is Array:
		_warn(label, "elevation_transitions must be an Array.")
		return {"valid": false, "lookup": lookup}
	for transition_index in range(transitions.size()):
		if not _validate_transition(transitions[transition_index], lookup, label, transition_index):
			valid = false
	return {"valid": valid, "lookup": lookup}


static func _validate_transition(
	transition,
	elevation_lookup: Dictionary,
	label: String,
	transition_index: int
) -> bool:
	if not transition is Dictionary:
		_warn(label, "elevation transition %d must be a Dictionary." % (transition_index + 1))
		return false
	for key in ["type", "from_cell", "to_cell", "from_elevation", "to_elevation"]:
		if not transition.has(key):
			_warn(label, "elevation transition %d is missing %s." % [transition_index + 1, key])
			return false
	if String(transition.type) != "ramp":
		_warn(label, "elevation transition %d must use type ramp." % (transition_index + 1))
		return false
	if not transition.from_cell is Vector2i or not transition.to_cell is Vector2i:
		_warn(label, "elevation transition %d cells must be Vector2i." % (transition_index + 1))
		return false
	if not _is_elevation_value(transition.from_elevation) or not _is_elevation_value(transition.to_elevation):
		_warn(label, "elevation transition %d levels must be ints from -1 through 1." % (transition_index + 1))
		return false
	var from_cell: Vector2i = transition.from_cell
	var to_cell: Vector2i = transition.to_cell
	var from_elevation := int(transition.from_elevation)
	var to_elevation := int(transition.to_elevation)
	if _manhattan_distance(from_cell, to_cell) != 1:
		_warn(label, "elevation transition %d must connect adjacent cells." % (transition_index + 1))
		return false
	if absi(from_elevation - to_elevation) != 1:
		_warn(label, "elevation transition %d must change exactly one level." % (transition_index + 1))
		return false
	if not _surface_exists(elevation_lookup, from_cell, from_elevation) or not _surface_exists(elevation_lookup, to_cell, to_elevation):
		_warn(label, "elevation transition %d references a missing surface." % (transition_index + 1))
		return false
	if transition.has("width") and (not _positive_number(transition.width) or float(transition.width) < 24.0 or float(transition.width) > GRID_CELL_SIZE):
		_warn(label, "elevation transition %d width must fit its cell." % (transition_index + 1))
		return false
	return true


static func _validate_obstacles(level: Dictionary, elevation_lookup: Dictionary, label: String) -> bool:
	var valid := true
	for obstacle_index in range(level.obstacles.size()):
		var obstacle = level.obstacles[obstacle_index]
		if not obstacle is Dictionary:
			_warn(label, "obstacle %d must be a Dictionary." % (obstacle_index + 1))
			valid = false
			continue
		if not obstacle.get("pos") is Vector2 or not obstacle.get("size") is Vector2:
			_warn(label, "obstacle %d requires Vector2 pos and size." % (obstacle_index + 1))
			valid = false
			continue
		if Vector2(obstacle.size).x <= 0.0 or Vector2(obstacle.size).y <= 0.0:
			_warn(label, "obstacle %d size must be positive." % (obstacle_index + 1))
			valid = false
			continue
		var elevation_value = obstacle.get("elevation", 0)
		if not _is_elevation_value(elevation_value):
			_warn(label, "obstacle %d elevation is invalid." % (obstacle_index + 1))
			valid = false
			continue
		if String(obstacle.get("type", "blocker")) != "blocker":
			_warn(label, "obstacle %d has unsupported type %s." % [obstacle_index + 1, obstacle.get("type")])
			valid = false
		if not _rect_fits_surface(level, Rect2(obstacle.pos - obstacle.size / 2.0, obstacle.size), int(elevation_value), elevation_lookup):
			_warn(label, "obstacle %d does not fit its elevation surface." % (obstacle_index + 1))
			valid = false
	return valid


static func _validate_static_hazards(level: Dictionary, elevation_lookup: Dictionary, label: String) -> bool:
	var valid := true
	for hazard_index in range(level.hazards.size()):
		var hazard = level.hazards[hazard_index]
		if not hazard is Dictionary:
			_warn(label, "hazard %d must be a Dictionary." % (hazard_index + 1))
			valid = false
			continue
		if not hazard.get("type") is String and not hazard.get("type") is StringName:
			_warn(label, "hazard %d requires a string type." % (hazard_index + 1))
			valid = false
			continue
		var hazard_type := String(hazard.type)
		if not STATIC_HAZARD_TYPES.has(hazard_type):
			_warn(label, "hazard %d uses unsupported type %s." % [hazard_index + 1, hazard_type])
			valid = false
			continue
		if not hazard.get("pos") is Vector2 or not hazard.get("size") is Vector2:
			_warn(label, "hazard %d requires Vector2 pos and size." % (hazard_index + 1))
			valid = false
			continue
		var size: Vector2 = hazard.size
		if size.x <= 0.0 or size.y <= 0.0:
			_warn(label, "hazard %d size must be positive." % (hazard_index + 1))
			valid = false
			continue
		var elevation_value = hazard.get("elevation", 0)
		if not _is_elevation_value(elevation_value):
			_warn(label, "hazard %d elevation is invalid." % (hazard_index + 1))
			valid = false
			continue
		if not _rect_fits_surface(level, Rect2(hazard.pos - size / 2.0, size), int(elevation_value), elevation_lookup):
			_warn(label, "hazard %d does not fit its elevation surface." % (hazard_index + 1))
			valid = false
		if not _nonnegative_number(hazard.get("intensity", 1.0)):
			_warn(label, "hazard %d intensity must be a nonnegative number." % (hazard_index + 1))
			valid = false
		if hazard.has("seed") and not hazard.seed is int:
			_warn(label, "hazard %d seed must be an int." % (hazard_index + 1))
			valid = false
		if hazard_type == "direction" and (not hazard.get("direction") is Vector2 or Vector2(hazard.direction).is_zero_approx()):
			_warn(label, "direction hazard %d requires a nonzero Vector2 direction." % (hazard_index + 1))
			valid = false
		if hazard_type == "bounce_pad":
			if not hazard.get("seed", 0) is int or int(hazard.get("seed", 0)) == 0:
				_warn(label, "bounce pad %d requires a nonzero deterministic seed." % (hazard_index + 1))
				valid = false
			if not _positive_number(hazard.get("minimum_exit_speed", GameplayHazardScript.MIN_BOUNCE_SPEED)):
				_warn(label, "bounce pad %d minimum exit speed must be positive." % (hazard_index + 1))
				valid = false
			if not _positive_number(hazard.get("speed_multiplier", GameplayHazardScript.DEFAULT_BOUNCE_SPEED_MULTIPLIER)):
				_warn(label, "bounce pad %d speed multiplier must be positive." % (hazard_index + 1))
				valid = false
			if not _positive_number(hazard.get("maximum_exit_speed", GameplayHazardScript.MAX_BOUNCE_SPEED)):
				_warn(label, "bounce pad %d maximum exit speed must be positive." % (hazard_index + 1))
				valid = false
			if (
				_positive_number(hazard.get("minimum_exit_speed", GameplayHazardScript.MIN_BOUNCE_SPEED))
				and _positive_number(hazard.get("maximum_exit_speed", GameplayHazardScript.MAX_BOUNCE_SPEED))
				and float(hazard.get("minimum_exit_speed", GameplayHazardScript.MIN_BOUNCE_SPEED)) > float(hazard.get("maximum_exit_speed", GameplayHazardScript.MAX_BOUNCE_SPEED))
			):
				_warn(label, "bounce pad %d minimum exit speed cannot exceed its maximum." % (hazard_index + 1))
				valid = false
			if not _positive_number(hazard.get("retrigger_cooldown", GameplayHazardScript.DEFAULT_RETRIGGER_COOLDOWN)):
				_warn(label, "bounce pad %d retrigger cooldown must be positive." % (hazard_index + 1))
				valid = false
		if hazard_type == "ice" and not _positive_number(hazard.get("intensity", 0.22)):
			_warn(label, "ice hazard %d intensity must be positive." % (hazard_index + 1))
			valid = false
	return valid


static func _validate_moving_hazards(level: Dictionary, elevation_lookup: Dictionary, label: String) -> bool:
	var moving_hazards = level.get("moving_hazards", [])
	if not moving_hazards is Array:
		_warn(label, "moving_hazards must be an Array.")
		return false
	var valid := true
	for hazard_index in range(moving_hazards.size()):
		var hazard = moving_hazards[hazard_index]
		if not hazard is Dictionary:
			_warn(label, "moving hazard %d must be a Dictionary." % (hazard_index + 1))
			valid = false
			continue
		var hazard_type := String(hazard.get("type", ""))
		if not MOVING_HAZARD_TYPES.has(hazard_type):
			_warn(label, "moving hazard %d has unsupported type %s." % [hazard_index + 1, hazard_type])
			valid = false
			continue
		if not hazard.get("pos") is Vector2 or not hazard.get("size") is Vector2:
			_warn(label, "moving hazard %d requires Vector2 pos and size." % (hazard_index + 1))
			valid = false
			continue
		if Vector2(hazard.size).x <= 0.0 or Vector2(hazard.size).y <= 0.0:
			_warn(label, "moving hazard %d size must be positive." % (hazard_index + 1))
			valid = false
			continue
		if hazard_type == "falling_ice" and Vector2(hazard.size) != Vector2.ONE * GRID_CELL_SIZE:
			_warn(label, "falling ice must occupy exactly one full tile.")
			valid = false
		var elevation_value = hazard.get("elevation", 0)
		if not _is_elevation_value(elevation_value):
			_warn(label, "moving hazard %d elevation is invalid." % (hazard_index + 1))
			valid = false
			continue
		if not _rect_fits_surface(level, Rect2(hazard.pos - hazard.size / 2.0, hazard.size), int(elevation_value), elevation_lookup):
			_warn(label, "moving hazard %d does not fit its elevation surface." % (hazard_index + 1))
			valid = false
		if not _positive_number(hazard.get("period", 0.0)):
			_warn(label, "moving hazard %d period must be positive." % (hazard_index + 1))
			valid = false
		if not _number(hazard.get("phase", 0.0)):
			_warn(label, "moving hazard %d phase must be numeric." % (hazard_index + 1))
			valid = false
		if bool(hazard.get("blocks_main_route", true)):
			_warn(label, "moving hazard %d may not permanently block the validated main route." % (hazard_index + 1))
			valid = false
		if not _nonnegative_number(hazard.get("intensity", 1.0)):
			_warn(label, "moving hazard %d intensity must be a nonnegative number." % (hazard_index + 1))
			valid = false
		for optional_positive_name in ["travel_radius", "telegraph_duration", "active_duration", "cooldown_duration", "drop_distance"]:
			if hazard.has(optional_positive_name) and not _positive_number(hazard[optional_positive_name]):
				_warn(label, "moving hazard %d %s must be positive." % [hazard_index + 1, optional_positive_name])
				valid = false
		for optional_numeric_name in ["swing_angle", "angular_speed"]:
			if hazard.has(optional_numeric_name) and not _number(hazard[optional_numeric_name]):
				_warn(label, "moving hazard %d %s must be numeric." % [hazard_index + 1, optional_numeric_name])
				valid = false
		if _definition_surfaces(level, hazard).is_empty():
			_warn(label, "moving hazard %d has an invalid or unbounded swept footprint." % (hazard_index + 1))
			valid = false
	return valid


static func _validate_branches(level: Dictionary, label: String) -> bool:
	var branches = level.get("branches", [])
	if not branches is Array:
		_warn(label, "branches must be an Array.")
		return false
	var valid := true
	for branch_index in range(branches.size()):
		var branch = branches[branch_index]
		if not branch is Dictionary:
			_warn(label, "branch %d must be a Dictionary." % (branch_index + 1))
			valid = false
			continue
		var kind := String(branch.get("kind", ""))
		if not BRANCH_TYPES.has(kind) or not branch.get("cells") is Array:
			_warn(label, "branch %d has invalid kind or cells." % (branch_index + 1))
			valid = false
			continue
		var cells: Array = branch.cells
		if cells.size() < 2 or not branch.get("entry_cell") is Vector2i or not branch.get("escape_cell") is Vector2i:
			_warn(label, "branch %d requires cells, entry_cell, and escape_cell." % (branch_index + 1))
			valid = false
			continue
		for cell_index in range(cells.size()):
			if not cells[cell_index] is Vector2i or not _is_playable_cell(level, cells[cell_index]):
				_warn(label, "branch %d contains a non-playable cell." % (branch_index + 1))
				valid = false
				break
			if cell_index > 0 and _manhattan_distance(cells[cell_index - 1], cells[cell_index]) != 1:
				_warn(label, "branch %d cells must form a contiguous route." % (branch_index + 1))
				valid = false
				break
		if not cells.has(branch.entry_cell) or not _is_playable_cell(level, branch.escape_cell):
			_warn(label, "branch %d entry/escape is not reachable terrain." % (branch_index + 1))
			valid = false
		if kind in ["alternate", "shortcut"]:
			if not branch.get("exit_cell") is Vector2i or not cells.has(branch.exit_cell):
				_warn(label, "branch %d requires a connected exit_cell." % (branch_index + 1))
				valid = false
	return valid


static func _validate_optional_builder_fields(level: Dictionary, elevation_lookup: Dictionary, label: String) -> bool:
	var valid := true
	if level.has("cup_radius") and (not _positive_number(level.cup_radius)):
		_warn(label, "cup_radius must be positive.")
		valid = false
	for palette_name in ["terrain_palette", "background_palette"]:
		if level.has(palette_name) and not level[palette_name] is Dictionary:
			_warn(label, "%s must be a Dictionary." % palette_name)
			valid = false
		elif level.has(palette_name):
			for palette_value in Dictionary(level[palette_name]).values():
				if not palette_value is Color:
					_warn(label, "%s values must be Colors." % palette_name)
					valid = false
					break
	if level.has("decoration_identifiers"):
		if not (level.decoration_identifiers is Array or level.decoration_identifiers is PackedStringArray):
			_warn(label, "decoration_identifiers must be a string array.")
			valid = false
		else:
			for decoration_id in level.decoration_identifiers:
				if not (decoration_id is String or decoration_id is StringName):
					_warn(label, "decoration_identifiers entries must be strings.")
					valid = false
					break
	if level.has("ambience") and not (level.ambience is String or level.ambience is StringName):
		_warn(label, "ambience must be a String or StringName.")
		valid = false
	for numeric_name in ["run_seed", "overall_hole_number", "generation_attempt", "biome_index", "hole_index"]:
		if level.has(numeric_name) and not level[numeric_name] is int:
			_warn(label, "%s must be an int." % numeric_name)
			valid = false

	var visual_rough_cells = level.get("visual_rough_cells", [])
	if not visual_rough_cells is Array:
		_warn(label, "visual_rough_cells must be an Array.")
		valid = false
	else:
		for cell in visual_rough_cells:
			if not cell is Vector2i or not _is_playable_cell(level, cell):
				_warn(label, "visual rough cells must reference playable Vector2i cells.")
				valid = false
				break

	if level.has("tee"):
		var tee = level.tee
		if not tee is Dictionary or not tee.get("cell") is Vector2i or not _is_elevation_value(tee.get("elevation", 0)):
			_warn(label, "tee requires a playable cell and valid elevation.")
			valid = false
		elif Vector2i(tee.cell) != Vector2i(level.start_cell) or not _surface_exists(elevation_lookup, tee.cell, int(tee.get("elevation", 0))):
			_warn(label, "tee must match the start surface.")
			valid = false

	var structures = level.get("elevation_structures", [])
	if not structures is Array:
		_warn(label, "elevation_structures must be an Array.")
		valid = false
	else:
		var overpass_count := 0
		for structure_index in range(structures.size()):
			var structure = structures[structure_index]
			if not structure is Dictionary or not STRUCTURE_TYPES.has(String(structure.get("type", ""))) or not structure.get("cells") is Array:
				_warn(label, "elevation structure %d is malformed." % (structure_index + 1))
				valid = false
				continue
			if not _is_elevation_value(structure.get("elevation", 0)):
				_warn(label, "elevation structure %d has an invalid elevation." % (structure_index + 1))
				valid = false
				continue
			for cell in structure.cells:
				if not cell is Vector2i or not _surface_exists(elevation_lookup, cell, int(structure.get("elevation", 0))):
					_warn(label, "elevation structure %d references a missing surface." % (structure_index + 1))
					valid = false
					break
			if String(structure.type) == "overpass":
				overpass_count += 1
				var lower_elevation = structure.get("lower_elevation", 0)
				var tunnel_length = structure.get("tunnel_length", Array(structure.cells).size())
				if not tunnel_length is int or int(tunnel_length) < 1 or int(tunnel_length) > 2:
					_warn(label, "overpass %d tunnel_length must be 1 or 2." % (structure_index + 1))
					valid = false
				if Array(structure.cells).size() > 2:
					_warn(label, "overpass %d may cover at most two crossing cells." % (structure_index + 1))
					valid = false
				if not _is_elevation_value(lower_elevation):
					valid = false
				else:
					for cell in structure.cells:
						if not _surface_exists(elevation_lookup, cell, int(lower_elevation)):
							_warn(label, "overpass %d has no lower crossing surface." % (structure_index + 1))
							valid = false
		if overpass_count > 1:
			_warn(label, "a generated hole may contain at most one elevation crossing.")
			valid = false
	return valid


static func _has_connected_elevation_path(
	level: Dictionary,
	elevation_lookup: Dictionary,
	start_cell: Vector2i,
	start_elevation: int,
	hole_cell: Vector2i,
	hole_elevation: int
) -> bool:
	var start_state := Vector3i(start_cell.x, start_cell.y, start_elevation)
	var target_state := Vector3i(hole_cell.x, hole_cell.y, hole_elevation)
	var queue: Array[Vector3i] = [start_state]
	var visited := {start_state: true}
	var transition_neighbors := _transition_neighbor_lookup(level)
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

	while not queue.is_empty():
		var state: Vector3i = queue.pop_front()
		if state == target_state:
			return true
		var cell := Vector2i(state.x, state.y)
		for direction in directions:
			var neighbor_cell := cell + direction
			if not _surface_exists(elevation_lookup, neighbor_cell, state.z):
				continue
			var neighbor_state := Vector3i(neighbor_cell.x, neighbor_cell.y, state.z)
			if not visited.has(neighbor_state):
				visited[neighbor_state] = true
				queue.append(neighbor_state)
		for neighbor_state in transition_neighbors.get(state, []):
			if not visited.has(neighbor_state):
				visited[neighbor_state] = true
				queue.append(neighbor_state)
	return false


static func _transition_neighbor_lookup(level: Dictionary) -> Dictionary:
	var lookup := {}
	for transition in level.get("elevation_transitions", []):
		if not transition is Dictionary:
			continue
		var from_cell: Vector2i = transition.from_cell
		var to_cell: Vector2i = transition.to_cell
		var from_state := Vector3i(from_cell.x, from_cell.y, int(transition.from_elevation))
		var to_state := Vector3i(to_cell.x, to_cell.y, int(transition.to_elevation))
		if not lookup.has(from_state):
			lookup[from_state] = []
		if not lookup.has(to_state):
			lookup[to_state] = []
		lookup[from_state].append(to_state)
		lookup[to_state].append(from_state)
	return lookup


static func _has_valid_map(level: Dictionary, label: String) -> bool:
	if not level.has("map"):
		_warn(label, "is missing map.")
		return false
	if not level.map is Array or level.map.is_empty():
		_warn(label, "map must be a nonempty Array of row strings.")
		return false
	var has_playable_cell := false
	for y in range(level.map.size()):
		if not level.map[y] is String or String(level.map[y]).is_empty():
			_warn(label, "map row %d must be a nonempty String." % y)
			return false
		for x in range(String(level.map[y]).length()):
			if String(level.map[y])[x] != " ":
				has_playable_cell = true
	if not has_playable_cell:
		_warn(label, "map has no playable cells.")
	return has_playable_cell


static func _playable_cells(level: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(level.map.size()):
		var row := String(level.map[y])
		for x in range(row.length()):
			if row[x] != " ":
				cells.append(Vector2i(x, y))
	return cells


static func _is_playable_cell(level: Dictionary, cell: Vector2i) -> bool:
	if not level.has("map") or not level.map is Array:
		return false
	if cell.y < 0 or cell.y >= level.map.size():
		return false
	var row := String(level.map[cell.y])
	return cell.x >= 0 and cell.x < row.length() and row[cell.x] != " "


static func _rect_fits_surface(
	level: Dictionary,
	rect: Rect2,
	elevation: int,
	elevation_lookup: Dictionary
) -> bool:
	if not rect.position.is_finite() or not rect.size.is_finite() or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return false
	var top_left := _map_top_left(level)
	if rect.position.x < top_left.x - 0.001 or rect.position.y < top_left.y - 0.001 or rect.end.x > -top_left.x + 0.001 or rect.end.y > -top_left.y + 0.001:
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
			if not _surface_exists(elevation_lookup, Vector2i(x, y), elevation):
				return false
	return true


static func _surface_exists(lookup: Dictionary, cell: Vector2i, elevation: int) -> bool:
	return lookup.has(cell) and Array(lookup[cell]).has(elevation)


static func _is_elevation_value(value) -> bool:
	return value is int and int(value) >= MIN_ELEVATION and int(value) <= MAX_ELEVATION


static func _positive_number(value) -> bool:
	return _number(value) and float(value) > 0.0


static func _nonnegative_number(value) -> bool:
	return _number(value) and float(value) >= 0.0


static func _number(value) -> bool:
	return (value is float or value is int) and is_finite(float(value))


static func _map_top_left(level: Dictionary) -> Vector2:
	var columns := 0
	for row in level.map:
		columns = maxi(columns, String(row).length())
	return -Vector2(float(columns), float(level.map.size())) * GRID_CELL_SIZE / 2.0


static func _manhattan_distance(first: Vector2i, second: Vector2i) -> int:
	return absi(first.x - second.x) + absi(first.y - second.y)


static func _warn(label: String, message: String) -> void:
	if not label.is_empty():
		push_warning("%s %s" % [label, message])


## Independent authored-grammar checks. No generator or reservation metadata is
## trusted to establish reachability, occupancy, cluster size or motion bounds.
## Call after the base builder schema is valid (validate_level does this).
static func generation_errors(level: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var route: Array = level.get("main_route_cells", [])
	if route.size() < 2:
		errors.append("generated primary route is missing or unreachable")
	var lookup := {}
	for entry: Dictionary in level.get("elevation_cells", []):
		lookup[entry.cell] = entry.levels
	var occupancy := placement_occupancy(level)
	_validate_generation_contract(level, lookup, errors)
	for endpoint: Vector2i in [level.start_cell, level.hole_cell]:
		for y in range(endpoint.y - 1, endpoint.y + 2):
			for x in range(endpoint.x - 1, endpoint.x + 2):
				if not _surface_exists(lookup, Vector2i(x, y), 0) or occupancy.has(Vector3i(x, y, 0)):
					_add_error(errors, "tee/cup requires a clear 3 by 3 landing region")
	for definition: Dictionary in level.get("moving_hazards", []):
		for surface in _definition_surfaces(level, definition):
			if not _surface_exists(lookup, Vector2i(surface.x, surface.y), surface.z):
				_add_error(errors, "moving hazard swept footprint leaves its elevation surface")
	for transition: Dictionary in level.get("elevation_transitions", []):
		for prefix in ["from", "to"]:
			var cell: Vector2i = transition[prefix + "_cell"]
			if occupancy.has(Vector3i(cell.x, cell.y, transition[prefix + "_elevation"])):
				_add_error(errors, "elevation transition landing is occupied")
	var visited := _reachable_clear_surfaces(level, lookup, occupancy)
	for cell: Vector2i in lookup:
		for elevation: int in lookup[cell]:
			var surface := Vector3i(cell.x, cell.y, elevation)
			if not occupancy.has(surface) and not visited.has(surface):
				_add_error(errors, "unrecoverable pocket or disconnected elevation surface")
	for branch: Dictionary in level.get("branches", []):
		var entry: Vector2i = branch.entry_cell
		var escape: Vector2i = branch.escape_cell
		if not visited.has(Vector3i(entry.x, entry.y, 0)) or not visited.has(Vector3i(escape.x, escape.y, 0)):
			_add_error(errors, "branch entry/escape is not reachable")
		if String(branch.kind) == "dead_end":
			var end: Vector2i = branch.cells[-1]
			var open_neighbors := 0
			for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var neighbor: Vector2i = end + direction
				if visited.has(Vector3i(neighbor.x, neighbor.y, 0)):
					open_neighbors += 1
			if open_neighbors < 3:
				_add_error(errors, "dead end has no useful turnaround pocket")
	var zones = level.get("shot_zones", [])
	if not zones is Array or zones.size() < 2:
		_add_error(errors, "generated hole requires tee, recovery and cup shot zones")
	else:
		for zone in zones:
			if not zone is Dictionary or not zone.get("cell") is Vector2i or not zone.get("cells") is Array or zone.cells.size() < 9 or not _is_elevation_value(zone.get("elevation", 0)):
				_add_error(errors, "shot zone contract is malformed")
				continue
			for y in range(zone.cell.y - 1, zone.cell.y + 2):
				for x in range(zone.cell.x - 1, zone.cell.x + 2):
					if not zone.cells.has(Vector2i(x, y)):
						_add_error(errors, "shot zone is missing its turnaround footprint")
			for cell in zone.cells:
				if not cell is Vector2i:
					_add_error(errors, "shot zone must contain typed cells")
				elif not _surface_exists(lookup, cell, int(zone.get("elevation", 0))) or occupancy.has(Vector3i(cell.x, cell.y, int(zone.get("elevation", 0)))):
					_add_error(errors, "shot recovery zone is not clear")
	var clusters := {}
	var terrain_cells := {}
	for hazard: Dictionary in level.hazards:
		if String(hazard.type) == "bounce_pad" and not bounce_exit_is_safe(level, hazard, occupancy, lookup):
			_add_error(errors, "bounce pad has no safe initial launch runway")
		var cluster_id := String(hazard.get("cluster_id", ""))
		if cluster_id.is_empty():
			_add_error(errors, "generated hazard is missing its formation identity")
			continue
		if not clusters.has(cluster_id):
			clusters[cluster_id] = []
		clusters[cluster_id].append(hazard)
		if String(hazard.type) in ["water", "lava", "sand", "ice"]:
			for surface in _definition_surfaces(level, hazard):
				terrain_cells[surface] = hazard
	for surface: Vector3i in terrain_cells:
		for direction in [Vector3i(1, 0, 0), Vector3i(0, 1, 0)]:
			var neighbor: Vector3i = surface + direction
			if terrain_cells.has(neighbor) and terrain_cells[surface].type == terrain_cells[neighbor].type and terrain_cells[surface].cluster_id != terrain_cells[neighbor].cluster_id:
				_add_error(errors, "touching terrain guards must form one bounded cluster")
	for group: Array in clusters.values():
		var cells := {}
		for hazard: Dictionary in group:
			var footprint := _definition_surfaces(level, hazard)
			if footprint.size() != 1 or String(hazard.type) != String(group[0].type) or int(hazard.get("cluster_size", 0)) != group.size():
				_add_error(errors, "hazard formation footprint/type/size is malformed")
			for surface in footprint:
				cells[Vector2i(surface.x, surface.y)] = true
		if cells.size() > 5 or not _connected_cells(cells):
			_add_error(errors, "hazard formation must be connected and contain 1 to 5 cells")
	for structure: Dictionary in level.get("elevation_structures", []):
		var elevation := int(structure.get("elevation", 0))
		if structure.cells.is_empty():
			_add_error(errors, "empty elevation structure")
		if String(structure.type) == "overpass":
			var cells := {}
			for cell: Vector2i in structure.cells:
				cells[cell] = true
			if int(structure.get("tunnel_length", cells.size())) != cells.size() or not _connected_cells(cells) or int(structure.get("lower_elevation", 0)) >= elevation:
				_add_error(errors, "tunnel length or crossing levels do not match actual surfaces")
		else:
			for cell: Vector2i in structure.cells:
				var horizontal := _surface_exists(lookup, cell + Vector2i.LEFT, elevation) or _surface_exists(lookup, cell + Vector2i.RIGHT, elevation)
				var vertical := _surface_exists(lookup, cell + Vector2i.UP, elevation) or _surface_exists(lookup, cell + Vector2i.DOWN, elevation)
				if not horizontal or not vertical:
					_add_error(errors, "elevated playable surfaces require at least two-cell width")
	return errors

static func _validate_generation_contract(level: Dictionary, lookup: Dictionary, errors: Array[String]) -> void:
	var primary := {}
	for field in ["design_route_cells", "primary_corridor_cells"]:
		var cells = level.get(field)
		if not cells is Array or cells.size() < 2:
			_add_error(errors, "generated route/corridor contract is missing")
			continue
		for cell in cells:
			if not cell is Vector2i or not lookup.has(cell):
				_add_error(errors, "generated route/corridor references invalid terrain")
			elif field == "primary_corridor_cells":
				primary[cell] = true
		if field == "design_route_cells":
			if cells[0] != level.start_cell or cells[-1] != level.hole_cell:
				_add_error(errors, "design route must run from tee to cup")
			for index in range(1, cells.size()):
				if cells[index] is Vector2i and cells[index - 1] is Vector2i and _manhattan_distance(cells[index], cells[index - 1]) != 1:
					_add_error(errors, "design route must be cardinal and contiguous")
	for cell in level.get("main_route_cells", []):
		if not primary.has(cell):
			_add_error(errors, "validated main route leaves its primary corridor")
	# At least two cells across the underlying main terrain, independent of the
	# supplied width label. Obstacles may guard part of that playable width.
	for cell: Vector2i in primary:
		var horizontal := lookup.has(cell + Vector2i.LEFT) or lookup.has(cell + Vector2i.RIGHT)
		var vertical := lookup.has(cell + Vector2i.UP) or lookup.has(cell + Vector2i.DOWN)
		if not horizontal or not vertical:
			_add_error(errors, "primary terrain has an unusable one-cell strip")
	var corridors = level.get("shot_corridors")
	if not corridors is Array or corridors.is_empty():
		_add_error(errors, "generated shot corridors are missing")
	else:
		for corridor in corridors:
			if not corridor is Dictionary or not corridor.get("from_cell") is Vector2i or not corridor.get("to_cell") is Vector2i or not corridor.get("width") is int:
				_add_error(errors, "shot corridor contract is malformed")
				continue
			var delta: Vector2i = corridor.to_cell - corridor.from_cell
			if delta == Vector2i.ZERO or (delta.x != 0 and delta.y != 0) or int(corridor.width) < 3 or int(corridor.width) > 5:
				_add_error(errors, "shot corridor requires a useful cardinal lane")
				continue
			if not lookup.has(corridor.from_cell) or not lookup.has(corridor.to_cell):
				_add_error(errors, "shot corridor endpoints must be playable")
				continue
			var cell: Vector2i = corridor.from_cell
			var direction := delta.sign()
			var side := Vector2i(-direction.y, direction.x)
			for _step in range(absi(delta.x) + absi(delta.y) + 1):
				for lateral in range(-int(corridor.width) / 2, int(corridor.width) / 2 + 1):
					if not lookup.has(cell + side * lateral):
						_add_error(errors, "shot corridor width disagrees with actual terrain")
				cell += direction
	var options = level.get("generation_options")
	if not options is Dictionary or not options.get("added_hazard_count", 0) is int:
		_add_error(errors, "generation options are malformed")
	else:
		var expected := clampi(int(options.get("added_hazard_count", 0)), 0, 4)
		var actual := 0
		for group in ["hazards", "obstacles"]:
			for definition: Dictionary in level.get(group, []):
				actual += 1 if bool(definition.get("curse_added", false)) else 0
		if actual != expected or not level.get("card_hazard_count") is int or int(level.card_hazard_count) != expected:
			_add_error(errors, "requested curse placements were not fulfilled")

static func _reachable_clear_surfaces(level: Dictionary, lookup: Dictionary, occupancy: Dictionary) -> Dictionary:
	var start := Vector3i(level.start_cell.x, level.start_cell.y, int(level.get("start_elevation", 0)))
	var visited := {start: true}
	var queue: Array[Vector3i] = [start]
	var transitions := _transition_neighbor_lookup(level)
	var cursor := 0
	while cursor < queue.size():
		var current := queue[cursor]
		cursor += 1
		var neighbors: Array = transitions.get(current, []).duplicate()
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var cell := Vector2i(current.x, current.y) + Vector2i(direction)
			if _surface_exists(lookup, cell, current.z):
				neighbors.append(Vector3i(cell.x, cell.y, current.z))
		for next: Vector3i in neighbors:
			if not visited.has(next) and not occupancy.has(next):
				visited[next] = true
				queue.append(next)
	return visited

static func bounce_exit_is_safe(level: Dictionary, pad: Dictionary, occupancy: Dictionary, lookup: Dictionary) -> bool:
	var velocity := GameplayHazardScript.deterministic_bounce_velocity(Vector2.RIGHT * 650.0, int(pad.seed), 0)
	var direction := velocity.normalized()
	var own_surfaces := _definition_surfaces(level, pad)
	for distance in [60.0, 100.0, 150.0, 200.0]:
		var point: Vector2 = Vector2(pad.pos) + direction * float(distance)
		var cell := Vector2i(((point - _map_top_left(level)) / GRID_CELL_SIZE).floor())
		var surface := Vector3i(cell.x, cell.y, int(pad.get("elevation", 0)))
		if not _surface_exists(lookup, cell, surface.z) or (occupancy.has(surface) and not own_surfaces.has(surface)):
			return false
	return true

static func _connected_cells(cells: Dictionary) -> bool:
	if cells.is_empty():
		return false
	var queue: Array[Vector2i] = [Vector2i(cells.keys()[0])]
	var visited := {queue[0]: true}
	var cursor := 0
	while cursor < queue.size():
		var current := queue[cursor]
		cursor += 1
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = current + direction
			if cells.has(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)
	return visited.size() == cells.size()

static func _add_error(errors: Array[String], error: String) -> void:
	if not errors.has(error):
		errors.append(error)
