class_name HoleGenerator
extends RefCounted

const LevelDatabase := preload("res://scripts/level_database.gd")
const LevelValidator := preload("res://scripts/level_validator.gd")
const BiomeHazardProfilesScript := preload("res://scripts/biome_hazard_profiles.gd")

const HOLES_PER_BIOME := 3
const MAX_GENERATION_ATTEMPTS := 4
const GRID_CELL_SIZE := 100.0
const HAZARD_TYPES := ["sand", "water", "lava", "ice", "direction", "bounce_pad"]
const DIFFICULTY_LABELS := ["Introductory", "Normal", "Hardest"]


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
	for attempt in range(bounded_attempts):
		var candidate := _generate_candidate(profile, run_seed, biome_index, hole_index, attempt)
		if LevelValidator.validate_level(candidate, biome_index * HOLES_PER_BIOME + hole_index):
			return candidate

	var fallback := fallback_hole(profile, run_seed, biome_index, hole_index)
	if not LevelValidator.validate_level(fallback, biome_index * HOLES_PER_BIOME + hole_index):
		push_error("Authored fallback failed validation for biome %s hole %d." % [profile.id, hole_index + 1])
	return fallback


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
	var occupied_cells := {
		Vector2i(level.start_cell): true,
		Vector2i(level.hole_cell): true,
	}
	for hazard in level.hazards:
		if hazard is Dictionary and hazard.has("pos"):
			occupied_cells[_world_to_cell(level, Vector2(hazard.pos))] = true

	var candidates: Array[Vector2i] = []
	for cell in _playable_cells_from_rows(level.map):
		if occupied_cells.has(cell):
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
	var route_centers: Array[int] = []
	var main_route_cells: Array[Vector2i] = []
	var playable := {}
	for x in range(width):
		var progress := float(x) / float(width - 1)
		var route_y := clampi(roundi(lerpf(float(start_y), float(hole_y), progress)), 1, height - 2)
		route_centers.append(route_y)
		main_route_cells.append(Vector2i(x, route_y))
		_carve_disc(playable, Vector2i(x, route_y), lane_radius, width, height)

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
		route_centers,
		width,
		height,
		biome_index,
		hole_index
	)
	var rows := _rows_from_playable(playable, width, height)
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
		rng
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
		rng
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
		rng
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
			_carve_disc(playable, cell, 0, width, height)
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
	var should_add_elevation := biome_index >= 1 and (hole_index >= 1 or biome_index >= 3)
	if should_add_elevation:
		for branch in branches:
			if String(branch.kind) != "alternate":
				continue
			var path: Array = branch.cells
			if path.size() < 5:
				continue
			var elevation := -1 if biome_index == 4 and hole_index == 2 else 1
			var elevated_cells: Array[Vector2i] = []
			for path_index in range(1, path.size() - 1):
				var cell := Vector2i(path[path_index])
				levels_by_cell[cell] = [elevation]
				elevated_cells.append(cell)
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
	rng: RandomNumberGenerator
) -> Array[Dictionary]:
	var main_route_lookup := _cell_lookup(main_route_cells)
	var candidates := _candidate_cells(playable, start_cell, hole_cell, main_route_lookup, 2)
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
	rng: RandomNumberGenerator
) -> Array[Dictionary]:
	var main_route_lookup := _cell_lookup(main_route_cells)
	var candidates := _candidate_cells(playable, start_cell, hole_cell, main_route_lookup, 2)
	var desired_count := clampi(hole_index + floori(float(biome_index) / 3.0), 0, 3)
	var obstacles: Array[Dictionary] = []
	for _obstacle_index in range(mini(desired_count, candidates.size())):
		var cell: Vector2i = candidates.pop_at(rng.randi_range(0, candidates.size() - 1))
		var vertical := rng.randi_range(0, 1) == 0
		obstacles.append({
			"type": "blocker",
			"pos": _cell_to_world(rows, cell),
			"size": Vector2(24.0, 76.0) if vertical else Vector2(76.0, 24.0),
			"elevation": int(Array(levels_by_cell.get(cell, [0]))[0]),
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
	rng: RandomNumberGenerator
) -> Array[Dictionary]:
	var hazard_type := BiomeHazardProfilesScript.moving_hazard_for(profile.id, hole_index)
	if hazard_type == "":
		return []
	var main_route_lookup := _cell_lookup(main_route_cells)
	var candidates := _candidate_cells(playable, start_cell, hole_cell, main_route_lookup, 2)
	var count := 1 + (1 if biome_index >= 4 and hole_index == 2 else 0)
	var moving_hazards: Array[Dictionary] = []
	for _moving_index in range(mini(count, candidates.size())):
		var cell: Vector2i = candidates.pop_at(rng.randi_range(0, candidates.size() - 1))
		var definition := {
			"type": hazard_type,
			"pos": _cell_to_world(rows, cell),
			"size": Vector2(38.0, 38.0),
			"elevation": int(Array(levels_by_cell.get(cell, [0]))[0]),
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
		occupied[_world_to_cell(level, Vector2(hazard.pos))] = true

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
