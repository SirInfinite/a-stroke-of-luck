class_name HoleGenerator
extends RefCounted

const LevelDatabase := preload("res://scripts/level_database.gd")
const LevelValidator := preload("res://scripts/level_validator.gd")
const BiomeHazardProfilesScript := preload("res://scripts/biome_hazard_profiles.gd")
const GameplayHazardScript := preload("res://scripts/gameplay_hazard.gd")
const CourseGrammarScript := preload("res://scripts/course_grammar.gd")
const BiomeDatabaseScript := preload("res://scripts/biome_database.gd")
const CourseQualityScript := preload("res://scripts/course_quality.gd")

const HOLES_PER_BIOME := 3
const MAX_GENERATION_ATTEMPTS := 8
const GRID_CELL_SIZE := 100.0
const HAZARD_TYPES := ["sand", "water", "lava", "ice", "direction", "bounce_pad"]
const DIFFICULTY_LABELS := ["Introductory", "Normal", "Hardest"]
const MINIMUM_QUALITY_SCORE := 72.0


static func generate_run(profiles: Array, run_seed: int, generation_options: Dictionary = {}) -> Array[Dictionary]:
	var generated_levels: Array[Dictionary] = []
	for biome_index in range(profiles.size()):
		for hole_index in range(HOLES_PER_BIOME):
			generated_levels.append(generate_hole(
				profiles[biome_index],
				run_seed,
				biome_index,
				hole_index,
				MAX_GENERATION_ATTEMPTS,
				generation_options
			))
	return generated_levels


static func generate_hole(
	profile,
	run_seed: int,
	biome_index: int,
	hole_index: int,
	max_attempts := MAX_GENERATION_ATTEMPTS,
	generation_options: Dictionary = {}
) -> Dictionary:
	var bounded_attempts := clampi(max_attempts, 0, MAX_GENERATION_ATTEMPTS)
	var best_candidate: Dictionary = {}
	var best_report: Dictionary = {}
	var valid_candidate_count := 0
	var candidate_scores: Array[Dictionary] = []
	var quality_rejections := 0
	for attempt in range(bounded_attempts):
		var candidate := _generate_candidate(profile, run_seed, biome_index, hole_index, attempt, generation_options)
		if not LevelValidator.validate_level(candidate, biome_index * HOLES_PER_BIOME + hole_index, false):
			candidate_scores.append({"candidate": attempt, "valid": false, "score": -1.0, "reasons": LevelValidator.generation_errors(candidate)})
			continue
		valid_candidate_count += 1
		var report := score_candidate(candidate)
		candidate["quality_score"] = float(report.score)
		candidate["quality_breakdown"] = Dictionary(report.breakdown).duplicate(true)
		candidate["generation_metrics"] = report.metrics if report.has("metrics") else quality_metrics(candidate)
		candidate_scores.append({"candidate": attempt, "valid": true, "score": float(report.score), "reasons": []})
		if float(report.score) < MINIMUM_QUALITY_SCORE:
			quality_rejections += 1
		if best_candidate.is_empty() or float(report.score) > float(best_report.score):
			best_candidate = candidate
			best_report = report

	if not best_candidate.is_empty() and float(best_report.score) >= MINIMUM_QUALITY_SCORE:
		best_candidate["candidate_count_considered"] = bounded_attempts
		best_candidate["candidate_valid_count"] = valid_candidate_count
		best_candidate["candidate_rejection_count"] = bounded_attempts - valid_candidate_count
		best_candidate["candidate_quality_rejection_count"] = quality_rejections
		best_candidate["candidate_scores"] = candidate_scores
		best_candidate["generation_retry_count"] = bounded_attempts - valid_candidate_count
		best_candidate["fallback_reason"] = ""
		best_candidate["quality_passed"] = true
		return best_candidate

	var fallback := fallback_hole(profile, run_seed, biome_index, hole_index, generation_options)
	if int(generation_options.get("added_hazard_count", 0)) > 0:
		fallback = apply_hazard_modifier(fallback, int(generation_options.added_hazard_count), StringName(generation_options.get("preferred_hazard_type", "direction")), int(generation_options.get("modifier_seed", run_seed)))
	var fallback_report := score_candidate(fallback)
	fallback["quality_score"] = float(fallback_report.score)
	fallback["quality_breakdown"] = Dictionary(fallback_report.breakdown).duplicate(true)
	fallback["candidate_count_considered"] = bounded_attempts
	fallback["candidate_valid_count"] = valid_candidate_count
	fallback["candidate_rejection_count"] = bounded_attempts - valid_candidate_count
	fallback["candidate_quality_rejection_count"] = valid_candidate_count
	fallback["candidate_scores"] = candidate_scores
	fallback["generation_retry_count"] = bounded_attempts - valid_candidate_count
	fallback["fallback_reason"] = "candidate_budget_zero" if bounded_attempts == 0 else "no_valid_candidate" if best_candidate.is_empty() else "quality_floor"
	fallback["quality_passed"] = false
	if not LevelValidator.validate_level(fallback, biome_index * HOLES_PER_BIOME + hole_index):
		push_error("Authored fallback failed validation for biome %s hole %d." % [profile.id, hole_index + 1])
	return fallback


static func score_candidate(level: Dictionary) -> Dictionary:
	if int(level.get("grammar_version", 0)) >= 2:
		return CourseQualityScript.score(level)
	var breakdown := {
		"route": 0.0,
		"width": 0.0,
		"safety": 0.0,
		"separation": 0.0,
		"recovery": 0.0,
		"rhythm": 0.0,
		"composition": 0.0,
		"interaction": 0.0,
	}
	if not level.has("map") or not level.map is Array:
		return {"score": 0.0, "breakdown": breakdown}

	var playable := _cell_lookup(_playable_cells_from_rows(level.map))
	var route: Array = level.get("main_route_cells", [])
	var start_cell := Vector2i(level.get("start_cell", Vector2i.ZERO))
	var hole_cell := Vector2i(level.get("hole_cell", Vector2i.ZERO))
	if _is_contiguous_route(route, start_cell, hole_cell):
		breakdown.route = 18.0

	if not route.is_empty():
		var broad_route_cells := 0
		for raw_cell in route:
			var cell := Vector2i(raw_cell)
			var open_neighbors := _cardinal_neighbor_count(playable, cell)
			if open_neighbors >= 3:
				broad_route_cells += 1
		var broad_ratio := float(broad_route_cells) / float(route.size())
		breakdown.width = clampf(broad_ratio * 12.0, 0.0, 12.0)

	var endpoint_clear := _endpoint_clearance_score(level, start_cell) + _endpoint_clearance_score(level, hole_cell)
	breakdown.safety = endpoint_clear * 5.0

	var occupied_surfaces := _all_placement_surfaces(level)
	var occupancy := LevelValidator.placement_occupancy(level)
	var conflicting_surfaces := 0
	for surface in occupancy:
		if Array(occupancy[surface]).size() > 1:
			conflicting_surfaces += 1
	breakdown.separation = 8.0 if conflicting_surfaces == 0 else 0.0

	var recoverable_cells := 0
	var playable_cells := _playable_cells_from_rows(level.map)
	for cell in playable_cells:
		if _cardinal_neighbor_count(playable, cell) >= 2:
			recoverable_cells += 1
	if not playable_cells.is_empty():
		breakdown.recovery = clampf(12.0 * float(recoverable_cells) / float(playable_cells.size()), 0.0, 12.0)

	var turn_count := _route_turn_count(route)
	var alternate_count := 0
	for branch in level.get("branches", []):
		if branch is Dictionary and String(branch.get("kind", "")) in ["alternate", "shortcut"]:
			alternate_count += 1
	breakdown.rhythm = clampf(2.0 + float(turn_count) * 1.4 + float(alternate_count) * 2.5, 0.0, 10.0)

	var map_area := maxi(_map_columns(level.map) * level.map.size(), 1)
	var fill_ratio := float(playable_cells.size()) / float(map_area)
	var target_distance := absf(fill_ratio - 0.62)
	breakdown.composition = clampf(8.0 - target_distance * 18.0, 0.0, 8.0)

	var metrics := quality_metrics(level)
	if int(metrics.placement_count) > 0:
		breakdown.interaction = clampf(
			float(metrics.route_relevant_ratio) * 14.0
			+ minf(float(metrics.direct_line_interactions) * 2.0, 4.0)
			+ minf(float(metrics.challenge_role_count) * 1.35, 4.0),
			0.0,
			22.0
		)

	var total := 0.0
	for value in breakdown.values():
		total += float(value)
	return {"score": snappedf(clampf(total, 0.0, 100.0), 0.01), "breakdown": breakdown}


static func quality_metrics(level: Dictionary) -> Dictionary:
	if int(level.get("grammar_version", 0)) >= 2:
		return CourseQualityScript.metrics(level)
	var route: Array = level.get("main_route_cells", [])
	var direct_line_lookup := _cell_lookup(_direct_line_cells(
		Vector2i(level.get("start_cell", Vector2i.ZERO)),
		Vector2i(level.get("hole_cell", Vector2i.ZERO))
	))
	var placement_count := 0
	var route_relevant_count := 0
	var direct_line_interactions := 0
	var challenge_roles := {}
	var cluster_sizes := {}
	for collection_name in ["hazards", "obstacles", "moving_hazards"]:
		for definition in level.get(collection_name, []):
			if not definition is Dictionary or not definition.get("pos") is Vector2:
				continue
			placement_count += 1
			var cell := _world_to_cell(level, Vector2(definition.pos))
			var route_distance := _distance_to_route(cell, route)
			if route_distance <= 2 or direct_line_lookup.has(cell):
				route_relevant_count += 1
			if direct_line_lookup.has(cell):
				direct_line_interactions += 1
			var role := String(definition.get("placement_role", ""))
			if not role.is_empty():
				challenge_roles[role] = true
			var cluster_id := String(definition.get("cluster_id", ""))
			if not cluster_id.is_empty():
				cluster_sizes[cluster_id] = maxi(int(cluster_sizes.get(cluster_id, 0)), int(definition.get("cluster_size", 1)))
	var ordered_cluster_sizes: Array[int] = []
	for cluster_size in cluster_sizes.values():
		ordered_cluster_sizes.append(int(cluster_size))
	ordered_cluster_sizes.sort()
	return {
		"placement_count": placement_count,
		"route_relevant_count": route_relevant_count,
		"route_relevant_ratio": 1.0 if placement_count == 0 else float(route_relevant_count) / float(placement_count),
		"direct_line_interactions": direct_line_interactions,
		"challenge_role_count": challenge_roles.size(),
		"hazard_cluster_sizes": ordered_cluster_sizes,
		"route_turn_count": _route_turn_count(route),
	}


static func fallback_hole(
	profile,
	run_seed: int,
	biome_index: int,
	hole_index: int,
	generation_options: Dictionary = {}
) -> Dictionary:
	var authored_levels := LevelDatabase.get_levels()
	var fallback: Dictionary = authored_levels[clampi(hole_index, 0, authored_levels.size() - 1)].duplicate(true)
	_apply_release_contract_defaults(fallback, run_seed, biome_index, hole_index)
	_apply_fallback_hazard_profile(fallback, profile, run_seed, biome_index, hole_index)
	_apply_profile_metadata(fallback, profile, run_seed, biome_index, hole_index, MAX_GENERATION_ATTEMPTS, true, generation_options)
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
	if int(base_level.get("grammar_version", 0)) >= 2 and not bool(base_level.get("used_fallback", false)):
		var options: Dictionary = base_level.get("generation_options", {}).duplicate(true)
		options.merge({"added_hazard_count": bounded_count, "preferred_hazard_type": preferred_hazard_type, "modifier_seed": modifier_seed}, true)
		var profile = BiomeDatabaseScript.get_profiles()[clampi(int(base_level.biome_index), 0, 5)]
		return generate_hole(profile, int(base_level.run_seed), int(base_level.biome_index), int(base_level.hole_index), MAX_GENERATION_ATTEMPTS, options)

	var hazard_type := String(preferred_hazard_type)
	if not HAZARD_TYPES.has(hazard_type) and hazard_type != "blocker":
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
	var ordered_route: Array[Vector2i] = []
	for route_cell in level.get("main_route_cells", []):
		if route_cell is Vector2i:
			ordered_route.append(Vector2i(route_cell))
	var direct_line_lookup := _cell_lookup(_direct_line_cells(Vector2i(level.start_cell), Vector2i(level.hole_cell)))
	var playable_lookup := _cell_lookup(_playable_cells_from_rows(level.map))
	var added_count := 0
	var rows: Array[String] = []
	for row in level.map:
		rows.append(String(row))
	for hazard_index in range(mini(bounded_count, candidates.size())):
		var cell := _select_route_candidate(candidates, ordered_route, direct_line_lookup, playable_lookup, rng)
		candidates.erase(cell)
		var hazard := _static_hazard_definition(
			hazard_type,
			_cell_to_world(rows, cell),
			_elevation_for_cell(level, cell),
			modifier_seed + hazard_index * 7919,
			rng
		)
		hazard["route_distance"] = _distance_to_route(cell, ordered_route)
		hazard["placement_role"] = _placement_role(cell, ordered_route, direct_line_lookup)
		hazard["curse_added"] = true
		if hazard_type == "blocker":
			hazard["size"] = Vector2(48.0, 76.0)
			level.obstacles.append(hazard)
		else:
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
	attempt: int,
	generation_options: Dictionary = {}
) -> Dictionary:
	var level := CourseGrammarScript.compose(profile, run_seed, biome_index, hole_index, attempt, generation_options)
	_apply_profile_metadata(level, profile, run_seed, biome_index, hole_index, attempt + 1, false, generation_options)
	return level


static func _select_route_candidate(
	candidates: Array[Vector2i],
	main_route_cells: Array[Vector2i],
	direct_line_lookup: Dictionary,
	playable: Dictionary,
	rng: RandomNumberGenerator
) -> Vector2i:
	var best_cell := candidates[0]
	var best_score := -INF
	for cell in candidates:
		var score := _candidate_priority(cell, main_route_cells, direct_line_lookup, playable)
		score += rng.randf() * 18.0
		if score > best_score:
			best_score = score
			best_cell = cell
	return best_cell


static func _candidate_priority(
	cell: Vector2i,
	main_route_cells: Array[Vector2i],
	direct_line_lookup: Dictionary,
	playable: Dictionary
) -> float:
	var route_distance := _distance_to_route(cell, main_route_cells)
	var score := 0.0
	match route_distance:
		1:
			score += 92.0
		2:
			score += 54.0
		3:
			score += 18.0
	if direct_line_lookup.has(cell):
		score += 78.0
	if _near_route_turn(cell, main_route_cells):
		score += 26.0
	var open_neighbors := _cardinal_neighbor_count(playable, cell)
	if open_neighbors >= 3:
		score += 10.0
	elif open_neighbors <= 1:
		score -= 20.0
	return score


static func _placement_role(
	cell: Vector2i,
	main_route_cells: Array[Vector2i],
	direct_line_lookup: Dictionary
) -> String:
	if direct_line_lookup.has(cell):
		return "direct_line_guard"
	if _near_route_turn(cell, main_route_cells):
		return "corner_guard"
	if _distance_to_route(cell, main_route_cells) == 1:
		return "lane_divider"
	return "route_pressure"


static func _near_route_turn(cell: Vector2i, main_route_cells: Array[Vector2i]) -> bool:
	for route_index in range(1, main_route_cells.size() - 1):
		var previous := Vector2i(main_route_cells[route_index - 1])
		var current := Vector2i(main_route_cells[route_index])
		var next := Vector2i(main_route_cells[route_index + 1])
		if current - previous == next - current:
			continue
		if _manhattan_distance(cell, current) <= 2:
			return true
	return false


static func _distance_to_route(cell: Vector2i, main_route_cells: Array) -> int:
	var nearest_distance := 999999
	for route_cell in main_route_cells:
		if route_cell is Vector2i:
			nearest_distance = mini(nearest_distance, _manhattan_distance(cell, Vector2i(route_cell)))
	return nearest_distance


static func _direct_line_cells(start_cell: Vector2i, hole_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var seen := {}
	var step_count := maxi(absi(hole_cell.x - start_cell.x), absi(hole_cell.y - start_cell.y))
	if step_count == 0:
		return [start_cell]
	for step in range(step_count + 1):
		var progress := float(step) / float(step_count)
		var cell := Vector2i(
			roundi(lerpf(float(start_cell.x), float(hole_cell.x), progress)),
			roundi(lerpf(float(start_cell.y), float(hole_cell.y), progress))
		)
		if not seen.has(cell):
			seen[cell] = true
			cells.append(cell)
	return cells


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
			definition["minimum_exit_speed"] = GameplayHazardScript.MIN_BOUNCE_SPEED
			definition["speed_multiplier"] = GameplayHazardScript.DEFAULT_BOUNCE_SPEED_MULTIPLIER
			definition["maximum_exit_speed"] = GameplayHazardScript.MAX_BOUNCE_SPEED
			definition["retrigger_cooldown"] = GameplayHazardScript.DEFAULT_RETRIGGER_COOLDOWN
		"ice":
			definition["intensity"] = 0.22
	return definition


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
	# Authored obstacles can cover several cells even when their anchor does not.
	for surface in LevelValidator.placement_occupancy(level):
		occupied[Vector2i(surface.x, surface.y)] = true

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
	used_fallback: bool,
	generation_options: Dictionary = {}
) -> void:
	level["biome_id"] = profile.id
	level["biome_name"] = profile.display_name
	level["biome_index"] = biome_index
	level["hole_index"] = hole_index
	level["overall_hole_number"] = biome_index * HOLES_PER_BIOME + hole_index + 1
	level["difficulty_name"] = DIFFICULTY_LABELS[clampi(hole_index, 0, DIFFICULTY_LABELS.size() - 1)]
	level["run_difficulty_id"] = StringName(generation_options.get("difficulty_id", &"normal"))
	level["run_difficulty_name"] = String(generation_options.get("difficulty_name", "NORMAL"))
	level["generation_difficulty_factor"] = clampf(float(generation_options.get("generation_difficulty_factor", 1.0)), 0.85, 1.2)
	level["run_seed"] = run_seed
	level["generation_attempt"] = generation_attempt
	level["used_fallback"] = used_fallback
	level["terrain_palette"] = profile.terrain_palette.duplicate(true)
	level["background_palette"] = profile.background_palette.duplicate(true)
	level["decoration_identifiers"] = profile.decoration_identifiers.duplicate()
	level["ambience"] = profile.ambience
	level["gameplay_hazard_profile"] = profile.id


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
	return LevelValidator._definition_surfaces(level, definition)


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


static func _playable_cells_from_rows(rows: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(rows.size()):
		var row := String(rows[y])
		for x in range(row.length()):
			if row[x] != " ":
				cells.append(Vector2i(x, y))
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
