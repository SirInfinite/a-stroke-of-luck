class_name HoleGenerator
extends RefCounted

const LevelDatabase := preload("res://scripts/level_database.gd")
const LevelValidator := preload("res://scripts/level_validator.gd")
const BiomeHazardProfilesScript := preload("res://scripts/biome_hazard_profiles.gd")

const HOLES_PER_BIOME := 3
const MAX_GENERATION_ATTEMPTS := 8
const GRID_CELL_SIZE := 100.0
const HAZARD_TYPES := ["sand", "water", "lava", "ice", "direction", "bounce_pad"]
const DIFFICULTY_LABELS := ["Introductory", "Normal", "Hardest"]
const MINIMUM_QUALITY_SCORE := 72.0


static func generate_run(profiles: Array, run_seed: int) -> Array[Dictionary]:
	var generated_levels: Array[Dictionary] = []
	for biome_index in range(profiles.size()):
		for hole_index in range(HOLES_PER_BIOME):
			generated_levels.append(generate_hole(profiles[biome_index], run_seed, biome_index, hole_index))
	return generated_levels


static func generate_hole(
	profile,
	run_seed: int,
	biome_index: int,
	hole_index: int,
	max_attempts := MAX_GENERATION_ATTEMPTS
) -> Dictionary:
	var bounded_attempts := clampi(max_attempts, 0, MAX_GENERATION_ATTEMPTS)
	var best_candidate: Dictionary = {}
	var best_report: Dictionary = {}
	for attempt in range(bounded_attempts):
		var candidate := _generate_candidate(profile, run_seed, biome_index, hole_index, attempt)
		if not LevelValidator.validate_level(candidate, biome_index * HOLES_PER_BIOME + hole_index):
			continue
		var report := score_candidate(candidate)
		candidate["quality_score"] = float(report.score)
		candidate["quality_breakdown"] = Dictionary(report.breakdown).duplicate(true)
		if best_candidate.is_empty() or float(report.score) > float(best_report.score):
			best_candidate = candidate
			best_report = report

	if not best_candidate.is_empty() and float(best_report.score) >= MINIMUM_QUALITY_SCORE:
		best_candidate["candidate_count_considered"] = bounded_attempts
		best_candidate["quality_passed"] = true
		return best_candidate

	var fallback := fallback_hole(profile, run_seed, biome_index, hole_index)
	var fallback_report := score_candidate(fallback)
	fallback["quality_score"] = float(fallback_report.score)
	fallback["quality_breakdown"] = Dictionary(fallback_report.breakdown).duplicate(true)
	fallback["candidate_count_considered"] = bounded_attempts
	fallback["quality_passed"] = false
	if not LevelValidator.validate_level(fallback, biome_index * HOLES_PER_BIOME + hole_index):
		push_error("Authored fallback failed validation for biome %s hole %d." % [profile.id, hole_index + 1])
	return fallback


static func score_candidate(level: Dictionary) -> Dictionary:
	var breakdown := {
		"route": 0.0,
		"width": 0.0,
		"safety": 0.0,
		"separation": 0.0,
		"recovery": 0.0,
		"rhythm": 0.0,
		"composition": 0.0,
	}
	if not level.has("map") or not level.map is Array:
		return {"score": 0.0, "breakdown": breakdown}

	var playable := _cell_lookup(_playable_cells_from_rows(level.map))
	var route: Array = level.get("main_route_cells", [])
	var start_cell := Vector2i(level.get("start_cell", Vector2i.ZERO))
	var hole_cell := Vector2i(level.get("hole_cell", Vector2i.ZERO))
	if _is_contiguous_route(route, start_cell, hole_cell):
		breakdown.route = 24.0

	if not route.is_empty():
		var broad_route_cells := 0
		for raw_cell in route:
			var cell := Vector2i(raw_cell)
			var open_neighbors := _cardinal_neighbor_count(playable, cell)
			if open_neighbors >= 3:
				broad_route_cells += 1
		var broad_ratio := float(broad_route_cells) / float(route.size())
		breakdown.width = clampf(broad_ratio * 18.0, 0.0, 18.0)

	var endpoint_clear := _endpoint_clearance_score(level, start_cell) + _endpoint_clearance_score(level, hole_cell)
	breakdown.safety = endpoint_clear * 7.0

	var occupied_surfaces := _all_placement_surfaces(level)
	var separated_count := 0
	for surface in occupied_surfaces:
		var isolated := true
		for other_surface in occupied_surfaces:
			if surface == other_surface or int(surface.z) != int(other_surface.z):
				continue
			if _manhattan_distance(Vector2i(surface.x, surface.y), Vector2i(other_surface.x, other_surface.y)) <= 1:
				isolated = false
				break
		if isolated:
			separated_count += 1
	breakdown.separation = 14.0 if occupied_surfaces.is_empty() else 14.0 * float(separated_count) / float(occupied_surfaces.size())

	var recoverable_cells := 0
	var playable_cells := _playable_cells_from_rows(level.map)
	for cell in playable_cells:
		if _cardinal_neighbor_count(playable, cell) >= 2:
			recoverable_cells += 1
	if not playable_cells.is_empty():
		breakdown.recovery = clampf(14.0 * float(recoverable_cells) / float(playable_cells.size()), 0.0, 14.0)

	var turn_count := _route_turn_count(route)
	var alternate_count := 0
	for branch in level.get("branches", []):
		if branch is Dictionary and String(branch.get("kind", "")) in ["alternate", "shortcut"]:
			alternate_count += 1
	breakdown.rhythm = clampf(2.0 + float(turn_count) * 1.5 + float(alternate_count) * 3.0, 0.0, 9.0)

	var map_area := maxi(_map_columns(level.map) * level.map.size(), 1)
	var fill_ratio := float(playable_cells.size()) / float(map_area)
	var target_distance := absf(fill_ratio - 0.62)
	breakdown.composition = clampf(7.0 - target_distance * 18.0, 0.0, 7.0)

	var total := 0.0
	for value in breakdown.values():
		total += float(value)
	return {"score": snappedf(clampf(total, 0.0, 100.0), 0.01), "breakdown": breakdown}


static func fallback_hole(profile, run_seed: int, biome_index: int, hole_index: int) -> Dictionary:
	var authored_levels := LevelDatabase.get_levels()
	var fallback: Dictionary = authored_levels[clampi(hole_index, 0, authored_levels.size() - 1)].duplicate(true)
	_apply_release_contract_defaults(fallback, run_seed, biome_index, hole_index)
	_apply_fallback_hazard_profile(fallback, profile, run_seed, biome_index, hole_index)
	_apply_profile_metadata(fallback, profile, run_seed, biome_index, hole_index, MAX_GENERATION_ATTEMPTS, true)
	return fallback


static func apply_hazard_modifier(
	base_level: Dictionary,
	added_hazard_count: int,
	preferred_hazard_type: StringName,
	modifier_seed: int
) -> Dictionary:
	var level: Dictionary = base_level.duplicate(true)
	var bounded_count := clampi(added_hazard_count, 0, 4)
	if bounded_count == 0:
		level["card_hazard_count"] = 0
		return level

	var hazard_type := String(preferred_hazard_type)
	if not HAZARD_TYPES.has(hazard_type):
		hazard_type = "direction"
	var occupied_surfaces := {}
	_reserve_surface(occupied_surfaces, Vector2i(level.start_cell), int(level.get("start_elevation", 0)))
	_reserve_surface(occupied_surfaces, Vector2i(level.hole_cell), int(level.get("hole_elevation", 0)))
	for surface in _all_placement_surfaces(level):
		occupied_surfaces[surface] = true
	var main_route_lookup := {}
	for route_cell in level.get("main_route_cells", []):
		if route_cell is Vector2i:
			main_route_lookup[Vector2i(route_cell)] = true

	var candidates: Array[Vector2i] = []
	for cell in _playable_cells_from_rows(level.map):
		if main_route_lookup.has(cell):
			continue
		var elevation := _elevation_for_cell(level, cell)
		if occupied_surfaces.has(Vector3i(cell.x, cell.y, elevation)):
			continue
		if _manhattan_distance(cell, Vector2i(level.start_cell)) <= 1:
			continue
		if _manhattan_distance(cell, Vector2i(level.hole_cell)) <= 1:
			continue
		candidates.append(cell)

	var rng := RandomNumberGenerator.new()
	rng.seed = maxi(absi(modifier_seed), 1)
	var added_count := 0
	var rows: Array[String] = []
	for row in level.map:
		rows.append(String(row))
	for hazard_index in range(mini(bounded_count, candidates.size())):
		var candidate_index := rng.randi_range(0, candidates.size() - 1)
		var cell: Vector2i = candidates.pop_at(candidate_index)
		var hazard := _static_hazard_definition(
			hazard_type,
			_cell_to_world(rows, cell),
			_elevation_for_cell(level, cell),
			modifier_seed + hazard_index * 7919,
			rng
		)
		level.hazards.append(hazard)
		_reserve_surface(occupied_surfaces, cell, int(hazard.elevation))
		added_count += 1
	level["card_hazard_count"] = added_count
	return level


static func _generate_candidate(
	profile,
	run_seed: int,
	biome_index: int,
	hole_index: int,
	attempt: int
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = _generation_seed(run_seed, biome_index, hole_index, attempt)

	var parameters: Dictionary = profile.generator_difficulty
	var width := maxi(int(parameters.get("map_width", 10)), 8)
	var height := maxi(int(parameters.get("map_height", 6)), 6)
	var start_y := rng.randi_range(1, height - 2)
	var max_bend := maxi(int(parameters.get("max_bend", 1)), 0)
	var hole_y := clampi(start_y + rng.randi_range(-max_bend, max_bend), 1, height - 2)
	var start_cell := Vector2i(1, start_y)
	var hole_cell := Vector2i(width - 2, hole_y)
	var lane_radius := _lane_radius(parameters, hole_index)
	var route_centers := _generate_route_centers(
		width,
		height,
		start_y,
		hole_y,
		max_bend,
		hole_index,
		rng
	)
	var main_route_cells: Array[Vector2i] = [start_cell]
	for x in range(start_cell.x + 1, hole_cell.x + 1):
		_append_cardinal_line(main_route_cells, main_route_cells[-1], Vector2i(x, route_centers[x]))
	var playable := {}
	for x in range(width):
		_carve_disc(playable, Vector2i(x, route_centers[x]), lane_radius, width, height)

	var branches := _generate_branches(
		playable,
		route_centers,
		width,
		height,
		lane_radius,
		biome_index,
		hole_index,
		rng
	)
	var elevation_contract := _generate_elevation_contract(
		playable,
		branches,
		main_route_cells,
		route_centers,
		width,
		height,
		biome_index,
		hole_index
	)
	var rows := _rows_from_playable(playable, width, height)
	var reserved_surfaces := {}
	_reserve_surface(reserved_surfaces, start_cell, 0)
	_reserve_surface(reserved_surfaces, hole_cell, 0)
	var hazards := _generate_hazards(
		profile,
		rows,
		playable,
		main_route_cells,
		start_cell,
		hole_cell,
		elevation_contract.levels_by_cell,
		biome_index,
		hole_index,
		run_seed,
		rng,
		reserved_surfaces
	)
	var obstacles := _generate_obstacles(
		rows,
		playable,
		main_route_cells,
		start_cell,
		hole_cell,
		elevation_contract.levels_by_cell,
		biome_index,
		hole_index,
		rng,
		reserved_surfaces
	)
	var moving_hazards := _generate_moving_hazards(
		profile,
		rows,
		playable,
		main_route_cells,
		start_cell,
		hole_cell,
		elevation_contract.levels_by_cell,
		biome_index,
		hole_index,
		rng,
		reserved_surfaces
	)

	var level := {
		"map": rows,
		"start_cell": start_cell,
		"hole_cell": hole_cell,
		"start_elevation": 0,
		"hole_elevation": 0,
		"par": 3 if hole_index == 0 else 4,
		"cup_radius": 32.0 - float(hole_index) * 4.0,
		"hazards": hazards,
		"moving_hazards": moving_hazards,
		"obstacles": obstacles,
		"branches": branches,
		"main_route_cells": main_route_cells,
		"elevation_cells": elevation_contract.elevation_cells,
		"elevation_transitions": elevation_contract.transitions,
		"elevation_structures": elevation_contract.structures,
		"visual_rough_cells": _visual_rough_cells(playable, main_route_cells, start_cell, hole_cell),
		"tee": {"cell": start_cell, "elevation": 0},
		"placement_reservation_count": reserved_surfaces.size(),
	}
	_apply_profile_metadata(level, profile, run_seed, biome_index, hole_index, attempt + 1, false)
	return level


static func _generate_branches(
	playable: Dictionary,
	route_centers: Array[int],
	width: int,
	height: int,
	lane_radius: int,
	biome_index: int,
	hole_index: int,
	rng: RandomNumberGenerator
) -> Array[Dictionary]:
	var branches: Array[Dictionary] = []
	var branch_count := 0 if biome_index == 0 and hole_index == 0 else 1
	if hole_index == 2:
		branch_count += 1
	for branch_index in range(branch_count):
		var start_x := clampi(2 + branch_index * 2, 2, width - 5)
		var end_x := clampi(width - 3 - branch_index, start_x + 2, width - 2)
		var base_y := route_centers[start_x]
		var offset_distance := lane_radius + 2
		var can_go_up := base_y - offset_distance >= 0
		var can_go_down := base_y + offset_distance < height
		var side := -1
		if not can_go_up:
			side = 1
		elif can_go_down and rng.randi_range(0, 1) == 1:
			side = 1
		var branch_y := clampi(base_y + side * offset_distance, 0, height - 1)
		var kind := "alternate" if branch_index == 0 else "dead_end"
		var entry_cell := Vector2i(start_x, route_centers[start_x])
		var path_cells: Array[Vector2i] = [entry_cell]
		_append_cardinal_line(path_cells, entry_cell, Vector2i(start_x, branch_y))
		var branch_end_x := end_x if kind == "alternate" else maxi(start_x + 2, end_x - 1)
		_append_cardinal_line(path_cells, path_cells[-1], Vector2i(branch_end_x, branch_y))
		var exit_cell := entry_cell
		if kind == "alternate":
			exit_cell = Vector2i(end_x, route_centers[end_x])
			_append_cardinal_line(path_cells, path_cells[-1], exit_cell)
		for cell in path_cells:
			_carve_disc(playable, cell, 1, width, height)
		branches.append({
			"kind": kind,
			"cells": path_cells,
			"entry_cell": entry_cell,
			"exit_cell": exit_cell if kind == "alternate" else null,
			"escape_cell": entry_cell,
			"temptation": "shortcut" if kind == "alternate" else "hazard_angle",
		})
	return branches


static func _generate_elevation_contract(
	playable: Dictionary,
	branches: Array[Dictionary],
	main_route_cells: Array[Vector2i],
	route_centers: Array[int],
	width: int,
	height: int,
	biome_index: int,
	hole_index: int
) -> Dictionary:
	var levels_by_cell := {}
	for cell in playable.keys():
		levels_by_cell[Vector2i(cell)] = [0]
	var transitions: Array[Dictionary] = []
	var structures: Array[Dictionary] = []
	var main_route_lookup := _cell_lookup(main_route_cells)
	var should_add_elevation := biome_index >= 1 and (hole_index >= 1 or biome_index >= 3)
	if should_add_elevation:
		for branch in branches:
			if String(branch.kind) != "alternate":
				continue
			var path: Array = branch.cells
			if path.size() < 5:
				continue
			var branch_crosses_main_route := false
			for path_index in range(1, path.size() - 1):
				if main_route_lookup.has(Vector2i(path[path_index])):
					branch_crosses_main_route = true
					break
			if branch_crosses_main_route:
				continue
			var elevation := -1 if biome_index == 4 and hole_index == 2 else 1
			var elevated_cells: Array[Vector2i] = []
			var elevated_lookup := {}
			for path_index in range(1, path.size() - 1):
				var cell := Vector2i(path[path_index])
				var previous_cell := Vector2i(path[path_index - 1])
				var next_cell := Vector2i(path[path_index + 1])
				var direction := next_cell - previous_cell
				var width_offsets: Array[Vector2i] = [Vector2i.ZERO]
				if absi(direction.x) >= absi(direction.y):
					width_offsets.append(Vector2i.UP)
					width_offsets.append(Vector2i.DOWN)
				else:
					width_offsets.append(Vector2i.LEFT)
					width_offsets.append(Vector2i.RIGHT)
				for width_offset in width_offsets:
					var elevated_cell := cell + width_offset
					if not playable.has(elevated_cell):
						continue
					if elevated_cell == Vector2i(path[0]) or elevated_cell == Vector2i(path[-1]):
						continue
					if main_route_lookup.has(elevated_cell):
						continue
					var main_y := route_centers[clampi(elevated_cell.x, 0, route_centers.size() - 1)]
					if width_offset != Vector2i.ZERO and elevated_cell.y == main_y:
						continue
					levels_by_cell[elevated_cell] = [elevation]
					if not elevated_lookup.has(elevated_cell):
						elevated_lookup[elevated_cell] = true
						elevated_cells.append(elevated_cell)
			transitions.append({
				"type": "ramp",
				"from_cell": Vector2i(path[0]),
				"to_cell": Vector2i(path[1]),
				"from_elevation": 0,
				"to_elevation": elevation,
			})
			transitions.append({
				"type": "ramp",
				"from_cell": Vector2i(path[-2]),
				"to_cell": Vector2i(path[-1]),
				"from_elevation": elevation,
				"to_elevation": 0,
			})
			structures.append({
				"type": "pit" if elevation < 0 else "hill",
				"cells": elevated_cells.duplicate(),
				"elevation": elevation,
			})
			if elevation > 0:
				structures.append({"type": "bridge", "cells": elevated_cells.duplicate(), "elevation": elevation})
			if elevation > 0 and hole_index == 2:
				var cross_cell: Vector2i = elevated_cells[floori(float(elevated_cells.size()) / 2.0)]
				var main_y := route_centers[clampi(cross_cell.x, 0, route_centers.size() - 1)]
				var beyond_y := clampi(cross_cell.y + signi(cross_cell.y - main_y), 0, height - 1)
				var lower_spur: Array[Vector2i] = [Vector2i(cross_cell.x, main_y)]
				_append_cardinal_line(lower_spur, lower_spur[-1], Vector2i(cross_cell.x, beyond_y))
				for spur_cell in lower_spur:
					_carve_disc(playable, spur_cell, 0, width, height)
					if spur_cell == cross_cell:
						levels_by_cell[spur_cell] = [0, 1]
					elif not levels_by_cell.has(spur_cell):
						levels_by_cell[spur_cell] = [0]
				branches.append({
					"kind": "dead_end",
					"cells": lower_spur,
					"entry_cell": lower_spur[0],
					"exit_cell": null,
					"escape_cell": lower_spur[0],
					"temptation": "underpass_angle",
				})
				structures.append({
					"type": "overpass",
					"cells": [cross_cell],
					"elevation": 1,
					"lower_elevation": 0,
				})
			break

	for cell in playable.keys():
		if not levels_by_cell.has(cell):
			levels_by_cell[Vector2i(cell)] = [0]
	var elevation_cells: Array[Dictionary] = []
	for cell in _sorted_cells(playable):
		var levels: Array = levels_by_cell.get(cell, [0])
		levels.sort()
		elevation_cells.append({"cell": cell, "levels": levels.duplicate()})
	return {
		"levels_by_cell": levels_by_cell,
		"elevation_cells": elevation_cells,
		"transitions": transitions,
		"structures": structures,
	}


static func _generate_hazards(
	profile,
	rows: Array[String],
	playable: Dictionary,
	main_route_cells: Array[Vector2i],
	start_cell: Vector2i,
	hole_cell: Vector2i,
	levels_by_cell: Dictionary,
	biome_index: int,
	hole_index: int,
	run_seed: int,
	rng: RandomNumberGenerator,
	reserved_surfaces: Dictionary
) -> Array[Dictionary]:
	var main_route_lookup := _cell_lookup(main_route_cells)
	var candidates := _candidate_cells(playable, start_cell, hole_cell, main_route_lookup, 2)
	candidates = _available_candidates(candidates, levels_by_cell, reserved_surfaces)
	var hazard_bonus := maxi(int(profile.generator_difficulty.get("hazard_bonus", 0)), 0)
	var desired_count := clampi(1 + hole_index + hazard_bonus, 1, 7)
	var required := BiomeHazardProfilesScript.required_static_types(profile.id, hole_index)
	desired_count = maxi(desired_count, required.size())
	var hazards: Array[Dictionary] = []
	for hazard_index in range(mini(desired_count, candidates.size())):
		var candidate_index := rng.randi_range(0, candidates.size() - 1)
		var cell: Vector2i = candidates.pop_at(candidate_index)
		var hazard_type := String(required[hazard_index]) if hazard_index < required.size() else _pick_weighted_hazard(
			BiomeHazardProfilesScript.static_weights_for(profile.id),
			rng
		)
		var elevation := int(Array(levels_by_cell.get(cell, [0]))[0])
		_reserve_surface(reserved_surfaces, cell, elevation)
		hazards.append(_static_hazard_definition(
			hazard_type,
			_cell_to_world(rows, cell),
			elevation,
			run_seed + biome_index * 1009 + hole_index * 9176 + hazard_index * 7919,
			rng
		))
	return hazards


static func _generate_obstacles(
	rows: Array[String],
	playable: Dictionary,
	main_route_cells: Array[Vector2i],
	start_cell: Vector2i,
	hole_cell: Vector2i,
	levels_by_cell: Dictionary,
	biome_index: int,
	hole_index: int,
	rng: RandomNumberGenerator,
	reserved_surfaces: Dictionary
) -> Array[Dictionary]:
	var main_route_lookup := _cell_lookup(main_route_cells)
	var candidates := _candidate_cells(playable, start_cell, hole_cell, main_route_lookup, 2)
	candidates = _available_candidates(candidates, levels_by_cell, reserved_surfaces)
	var desired_count := clampi(hole_index + floori(float(biome_index) / 3.0), 0, 3)
	var obstacles: Array[Dictionary] = []
	for _obstacle_index in range(mini(desired_count, candidates.size())):
		var cell: Vector2i = candidates.pop_at(rng.randi_range(0, candidates.size() - 1))
		var vertical := rng.randi_range(0, 1) == 0
		var elevation := int(Array(levels_by_cell.get(cell, [0]))[0])
		_reserve_surface(reserved_surfaces, cell, elevation)
		obstacles.append({
			"type": "blocker",
			"pos": _cell_to_world(rows, cell),
			"size": Vector2(24.0, 76.0) if vertical else Vector2(76.0, 24.0),
			"elevation": elevation,
		})
	return obstacles


static func _generate_moving_hazards(
	profile,
	rows: Array[String],
	playable: Dictionary,
	main_route_cells: Array[Vector2i],
	start_cell: Vector2i,
	hole_cell: Vector2i,
	levels_by_cell: Dictionary,
	biome_index: int,
	hole_index: int,
	rng: RandomNumberGenerator,
	reserved_surfaces: Dictionary
) -> Array[Dictionary]:
	var hazard_type := BiomeHazardProfilesScript.moving_hazard_for(profile.id, hole_index)
	if hazard_type == "":
		return []
	var main_route_lookup := _cell_lookup(main_route_cells)
	var candidates := _candidate_cells(playable, start_cell, hole_cell, main_route_lookup, 2)
	candidates = _available_candidates(candidates, levels_by_cell, reserved_surfaces)
	var count := 1 + (1 if biome_index >= 4 and hole_index == 2 else 0)
	var moving_hazards: Array[Dictionary] = []
	for _moving_index in range(mini(count, candidates.size())):
		var cell: Vector2i = candidates.pop_at(rng.randi_range(0, candidates.size() - 1))
		var elevation := int(Array(levels_by_cell.get(cell, [0]))[0])
		_reserve_surface(reserved_surfaces, cell, elevation)
		var definition := {
			"type": hazard_type,
			"pos": _cell_to_world(rows, cell),
			"size": Vector2(38.0, 38.0),
			"elevation": elevation,
			"period": 2.8 - minf(float(biome_index) * 0.12, 0.6),
			"phase": rng.randf(),
			"intensity": clampf(0.55 + float(biome_index + hole_index) * 0.06, 0.55, 1.0),
			"blocks_main_route": false,
		}
		match hazard_type:
			"pendulum":
				definition["travel_radius"] = 28.0
				definition["swing_angle"] = 0.9
			"falling_ice":
				definition["size"] = Vector2(72.0, 72.0)
				definition["telegraph_duration"] = 0.8
				definition["active_duration"] = 0.55
				definition["cooldown_duration"] = 1.15
				definition["drop_distance"] = 110.0
			"rotating_fire_rod":
				definition["size"] = Vector2(82.0, 20.0)
				definition["angular_speed"] = 1.5 + float(hole_index) * 0.18
		moving_hazards.append(definition)
	return moving_hazards


static func _static_hazard_definition(
	hazard_type: String,
	world_position: Vector2,
	elevation: int,
	seed_value: int,
	rng: RandomNumberGenerator
) -> Dictionary:
	var definition := {
		"type": hazard_type,
		"pos": world_position,
		"size": Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE),
		"elevation": elevation,
		"intensity": 1.0,
		"seed": maxi(absi(seed_value), 1),
	}
	match hazard_type:
		"direction":
			var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
			definition["direction"] = directions[rng.randi_range(0, directions.size() - 1)]
		"bounce_pad":
			definition["size"] = Vector2(78.0, 78.0)
			definition["retention"] = 0.76
			definition["retrigger_cooldown"] = 0.22
		"ice":
			definition["intensity"] = 0.22
	return definition


static func _pick_weighted_hazard(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total_weight := 0.0
	for hazard_type in HAZARD_TYPES:
		total_weight += maxf(float(weights.get(hazard_type, 0.0)), 0.0)
	if total_weight <= 0.0:
		return "sand"

	var roll := rng.randf() * total_weight
	for hazard_type in HAZARD_TYPES:
		roll -= maxf(float(weights.get(hazard_type, 0.0)), 0.0)
		if roll <= 0.0:
			return hazard_type
	return "sand"


static func _apply_release_contract_defaults(level: Dictionary, run_seed: int, biome_index: int, hole_index: int) -> void:
	level["moving_hazards"] = level.get("moving_hazards", [])
	level["branches"] = level.get("branches", [])
	level["main_route_cells"] = level.get("main_route_cells", [])
	level["start_elevation"] = int(level.get("start_elevation", 0))
	level["hole_elevation"] = int(level.get("hole_elevation", 0))
	level["elevation_cells"] = level.get("elevation_cells", _flat_elevation_cells(level.map))
	level["elevation_transitions"] = level.get("elevation_transitions", [])
	level["elevation_structures"] = level.get("elevation_structures", [])
	level["visual_rough_cells"] = level.get("visual_rough_cells", [])
	level["tee"] = level.get("tee", {"cell": level.start_cell, "elevation": level.start_elevation})
	for hazard_index in range(level.hazards.size()):
		level.hazards[hazard_index]["elevation"] = int(level.hazards[hazard_index].get("elevation", 0))
		level.hazards[hazard_index]["intensity"] = float(level.hazards[hazard_index].get("intensity", 1.0))
		level.hazards[hazard_index]["seed"] = int(level.hazards[hazard_index].get(
			"seed",
			run_seed + biome_index * 1009 + hole_index * 9176 + hazard_index * 7919
		))
	for obstacle in level.obstacles:
		obstacle["type"] = String(obstacle.get("type", "blocker"))
		obstacle["elevation"] = int(obstacle.get("elevation", 0))


static func _apply_fallback_hazard_profile(
	level: Dictionary,
	profile,
	run_seed: int,
	biome_index: int,
	hole_index: int
) -> void:
	var reset_hazard := BiomeHazardProfilesScript.reset_hazard_for(profile.id)
	var occupied := {
		Vector2i(level.start_cell): true,
		Vector2i(level.hole_cell): true,
	}
	for hazard in level.hazards:
		var hazard_type := String(hazard.get("type", ""))
		if hazard_type in ["water", "lava"]:
			hazard["type"] = reset_hazard
		if hazard.has("pos"):
			occupied[_world_to_cell(level, Vector2(hazard.pos))] = true
	for obstacle in level.get("obstacles", []):
		if obstacle is Dictionary and obstacle.has("pos"):
			occupied[_world_to_cell(level, Vector2(obstacle.pos))] = true
	for moving_hazard in level.get("moving_hazards", []):
		if moving_hazard is Dictionary and moving_hazard.has("pos"):
			occupied[_world_to_cell(level, Vector2(moving_hazard.pos))] = true

	var candidates: Array[Vector2i] = []
	for cell in _playable_cells_from_rows(level.map):
		if occupied.has(cell):
			continue
		if _manhattan_distance(cell, Vector2i(level.start_cell)) <= 2:
			continue
		if _manhattan_distance(cell, Vector2i(level.hole_cell)) <= 2:
			continue
		candidates.append(cell)

	var rng := RandomNumberGenerator.new()
	rng.seed = _generation_seed(run_seed, biome_index, hole_index, MAX_GENERATION_ATTEMPTS + 1)
	for required_type in BiomeHazardProfilesScript.required_static_types(profile.id, hole_index):
		if _level_has_hazard_type(level, required_type) or candidates.is_empty():
			continue
		var candidate_index := rng.randi_range(0, candidates.size() - 1)
		var cell: Vector2i = candidates.pop_at(candidate_index)
		level.hazards.append(_static_hazard_definition(
			required_type,
			_cell_to_world(_string_rows(level.map), cell),
			_elevation_for_cell(level, cell),
			run_seed + biome_index * 1009 + hole_index * 9176 + level.hazards.size() * 7919,
			rng
		))


static func _level_has_hazard_type(level: Dictionary, hazard_type: String) -> bool:
	for hazard in level.hazards:
		if String(hazard.get("type", "")) == hazard_type:
			return true
	return false


static func _string_rows(raw_rows: Array) -> Array[String]:
	var rows: Array[String] = []
	for row in raw_rows:
		rows.append(String(row))
	return rows


static func _apply_profile_metadata(
	level: Dictionary,
	profile,
	run_seed: int,
	biome_index: int,
	hole_index: int,
	generation_attempt: int,
	used_fallback: bool
) -> void:
	level["biome_id"] = profile.id
	level["biome_name"] = profile.display_name
	level["biome_index"] = biome_index
	level["hole_index"] = hole_index
	level["overall_hole_number"] = biome_index * HOLES_PER_BIOME + hole_index + 1
	level["difficulty_name"] = DIFFICULTY_LABELS[clampi(hole_index, 0, DIFFICULTY_LABELS.size() - 1)]
	level["run_seed"] = run_seed
	level["generation_attempt"] = generation_attempt
	level["used_fallback"] = used_fallback
	level["terrain_palette"] = profile.terrain_palette.duplicate(true)
	level["background_palette"] = profile.background_palette.duplicate(true)
	level["decoration_identifiers"] = profile.decoration_identifiers.duplicate()
	level["ambience"] = profile.ambience
	level["gameplay_hazard_profile"] = profile.id


static func _generate_route_centers(
	width: int,
	height: int,
	start_y: int,
	hole_y: int,
	max_bend: int,
	hole_index: int,
	rng: RandomNumberGenerator
) -> Array[int]:
	var first_x := clampi(roundi(float(width - 1) * 0.36), 2, width - 4)
	var second_x := clampi(roundi(float(width - 1) * 0.68), first_x + 1, width - 3)
	var bend_strength := maxi(max_bend, 1)
	if hole_index == 2:
		bend_strength += 1
	var first_offset := rng.randi_range(-bend_strength, bend_strength)
	if first_offset == 0 and hole_index > 0:
		first_offset = -1 if rng.randi_range(0, 1) == 0 else 1
	var first_y := clampi(start_y + first_offset, 1, height - 2)
	var second_offset := rng.randi_range(-bend_strength, bend_strength)
	if hole_index > 0 and signi(second_offset) == signi(first_y - start_y):
		second_offset = -signi(first_y - start_y) * maxi(absi(second_offset), 1)
	var second_y := clampi(hole_y + second_offset, 1, height - 2)
	var anchors: Array[Vector2i] = [
		Vector2i(0, start_y),
		Vector2i(1, start_y),
		Vector2i(first_x, first_y),
		Vector2i(second_x, second_y),
		Vector2i(width - 2, hole_y),
		Vector2i(width - 1, hole_y),
	]
	var centers: Array[int] = []
	centers.resize(width)
	for anchor_index in range(anchors.size() - 1):
		var from_anchor := anchors[anchor_index]
		var to_anchor := anchors[anchor_index + 1]
		var span := maxi(to_anchor.x - from_anchor.x, 1)
		for x in range(from_anchor.x, to_anchor.x + 1):
			var progress := float(x - from_anchor.x) / float(span)
			centers[x] = clampi(roundi(lerpf(float(from_anchor.y), float(to_anchor.y), progress)), 1, height - 2)
	centers[0] = start_y
	centers[1] = start_y
	centers[width - 2] = hole_y
	centers[width - 1] = hole_y
	return centers


static func _available_candidates(
	candidates: Array[Vector2i],
	levels_by_cell: Dictionary,
	reserved_surfaces: Dictionary
) -> Array[Vector2i]:
	var available: Array[Vector2i] = []
	for cell in candidates:
		var elevations: Array = levels_by_cell.get(cell, [0])
		if elevations.is_empty():
			continue
		var surface := Vector3i(cell.x, cell.y, int(elevations[0]))
		if not reserved_surfaces.has(surface):
			available.append(cell)
	return available


static func _reserve_surface(reserved_surfaces: Dictionary, cell: Vector2i, elevation: int) -> void:
	reserved_surfaces[Vector3i(cell.x, cell.y, elevation)] = true


static func _all_placement_surfaces(level: Dictionary) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var seen := {}
	for collection_name in ["hazards", "obstacles", "moving_hazards"]:
		for definition in level.get(collection_name, []):
			if not definition is Dictionary or not definition.get("pos") is Vector2:
				continue
			for surface in _definition_surfaces(level, definition):
				if not seen.has(surface):
					seen[surface] = true
					result.append(surface)
	return result


static func _definition_surfaces(level: Dictionary, definition: Dictionary) -> Array[Vector3i]:
	var surfaces: Array[Vector3i] = []
	var size := Vector2(definition.get("size", Vector2.ONE))
	if String(definition.get("type", "")) == "pendulum":
		size += Vector2(float(definition.get("travel_radius", 0.0)) * 2.0, 0.0)
	var rect := Rect2(Vector2(definition.pos) - size / 2.0, size)
	var top_left := -Vector2(float(_map_columns(level.map)), float(level.map.size())) * GRID_CELL_SIZE / 2.0
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


static func _is_contiguous_route(route: Array, start_cell: Vector2i, hole_cell: Vector2i) -> bool:
	if route.size() < 2 or not route[0] is Vector2i or not route[-1] is Vector2i:
		return false
	if Vector2i(route[0]) != start_cell or Vector2i(route[-1]) != hole_cell:
		return false
	var seen := {}
	for route_index in range(route.size()):
		if not route[route_index] is Vector2i:
			return false
		var cell := Vector2i(route[route_index])
		if seen.has(cell):
			return false
		seen[cell] = true
		if route_index > 0 and _manhattan_distance(Vector2i(route[route_index - 1]), cell) != 1:
			return false
	return true


static func _cardinal_neighbor_count(playable: Dictionary, cell: Vector2i) -> int:
	var count := 0
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		if playable.has(cell + direction):
			count += 1
	return count


static func _endpoint_clearance_score(level: Dictionary, endpoint: Vector2i) -> float:
	for surface in _all_placement_surfaces(level):
		if _manhattan_distance(endpoint, Vector2i(surface.x, surface.y)) <= 1:
			return 0.0
	return 1.0


static func _route_turn_count(route: Array) -> int:
	var turns := 0
	var previous_direction := Vector2i.ZERO
	for route_index in range(1, route.size()):
		if not route[route_index - 1] is Vector2i or not route[route_index] is Vector2i:
			continue
		var direction := Vector2i(route[route_index]) - Vector2i(route[route_index - 1])
		if previous_direction != Vector2i.ZERO and direction != previous_direction:
			turns += 1
		previous_direction = direction
	return turns


static func _map_columns(rows: Array) -> int:
	var columns := 0
	for row in rows:
		columns = maxi(columns, String(row).length())
	return columns


static func _lane_radius(parameters: Dictionary, hole_index: int) -> int:
	match hole_index:
		0:
			return maxi(int(parameters.get("lane_radius_easy", 2)), 1)
		1:
			return maxi(int(parameters.get("lane_radius_normal", 2)), 1)
		_:
			return maxi(int(parameters.get("lane_radius_hard", 1)), 1)


static func _candidate_cells(
	playable: Dictionary,
	start_cell: Vector2i,
	hole_cell: Vector2i,
	excluded: Dictionary,
	endpoint_clearance: int
) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for cell in _sorted_cells(playable):
		if excluded.has(cell):
			continue
		if _manhattan_distance(cell, start_cell) <= endpoint_clearance:
			continue
		if _manhattan_distance(cell, hole_cell) <= endpoint_clearance:
			continue
		candidates.append(cell)
	return candidates


static func _visual_rough_cells(
	playable: Dictionary,
	main_route_cells: Array[Vector2i],
	start_cell: Vector2i,
	hole_cell: Vector2i
) -> Array[Vector2i]:
	var main_lookup := _cell_lookup(main_route_cells)
	var rough_cells: Array[Vector2i] = []
	for cell in _sorted_cells(playable):
		if main_lookup.has(cell) or cell == start_cell or cell == hole_cell:
			continue
		if rough_cells.size() >= 18:
			break
		rough_cells.append(cell)
	return rough_cells


static func _flat_elevation_cells(rows: Array) -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	for cell in _playable_cells_from_rows(rows):
		cells.append({"cell": cell, "levels": [0]})
	return cells


static func _elevation_for_cell(level: Dictionary, cell: Vector2i) -> int:
	for entry in level.get("elevation_cells", []):
		if entry is Dictionary and Vector2i(entry.get("cell", Vector2i(-999, -999))) == cell:
			var levels: Array = entry.get("levels", [0])
			return int(levels[0]) if not levels.is_empty() else 0
	return 0


static func _carve_disc(playable: Dictionary, center: Vector2i, radius: int, width: int, height: int) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if x < 0 or x >= width or y < 0 or y >= height:
				continue
			playable[Vector2i(x, y)] = true


static func _append_cardinal_line(cells: Array[Vector2i], from_cell: Vector2i, to_cell: Vector2i) -> void:
	var cursor := from_cell
	while cursor.x != to_cell.x:
		cursor.x += signi(to_cell.x - cursor.x)
		if cells.is_empty() or cells[-1] != cursor:
			cells.append(cursor)
	while cursor.y != to_cell.y:
		cursor.y += signi(to_cell.y - cursor.y)
		if cells.is_empty() or cells[-1] != cursor:
			cells.append(cursor)


static func _rows_from_playable(playable: Dictionary, width: int, height: int) -> Array[String]:
	var rows: Array[String] = []
	for y in range(height):
		var row := ""
		for x in range(width):
			row += "#" if playable.has(Vector2i(x, y)) else " "
		rows.append(row)
	return rows


static func _playable_cells_from_rows(rows: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(rows.size()):
		var row := String(rows[y])
		for x in range(row.length()):
			if row[x] != " ":
				cells.append(Vector2i(x, y))
	return cells


static func _sorted_cells(playable: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in playable.keys():
		cells.append(Vector2i(cell))
	cells.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
		return first.y < second.y or (first.y == second.y and first.x < second.x)
	)
	return cells


static func _cell_lookup(cells: Array[Vector2i]) -> Dictionary:
	var lookup := {}
	for cell in cells:
		lookup[cell] = true
	return lookup


static func _generation_seed(run_seed: int, biome_index: int, hole_index: int, attempt: int) -> int:
	return absi(run_seed) + (biome_index + 1) * 1000003 + (hole_index + 1) * 10007 + attempt * 101


static func _cell_to_world(rows: Array[String], cell: Vector2i) -> Vector2:
	var columns := 0
	for row in rows:
		columns = maxi(columns, row.length())
	var top_left := -Vector2(float(columns), float(rows.size())) * GRID_CELL_SIZE / 2.0
	return top_left + Vector2(float(cell.x) + 0.5, float(cell.y) + 0.5) * GRID_CELL_SIZE


static func _world_to_cell(level: Dictionary, world_position: Vector2) -> Vector2i:
	var rows: Array = level.map
	var columns := 0
	for row in rows:
		columns = maxi(columns, String(row).length())
	var top_left := -Vector2(float(columns), float(rows.size())) * GRID_CELL_SIZE / 2.0
	return Vector2i(
		floori((world_position.x - top_left.x) / GRID_CELL_SIZE),
		floori((world_position.y - top_left.y) / GRID_CELL_SIZE)
	)


static func _manhattan_distance(first: Vector2i, second: Vector2i) -> int:
	return absi(first.x - second.x) + absi(first.y - second.y)
