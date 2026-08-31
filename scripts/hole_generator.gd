class_name HoleGenerator
extends RefCounted

const LevelDatabase := preload("res://scripts/level_database.gd")
const LevelValidator := preload("res://scripts/level_validator.gd")

const HOLES_PER_BIOME := 3
const MAX_GENERATION_ATTEMPTS := 4
const GRID_CELL_SIZE := 100.0
const HAZARD_TYPES := ["rough", "sand", "water", "direction", "out"]
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
		hazard_type = "rough"
	var occupied_cells := {
		Vector2i(level.start_cell): true,
		Vector2i(level.hole_cell): true,
	}
	for hazard in level.hazards:
		if hazard is Dictionary and hazard.has("pos"):
			occupied_cells[_world_to_cell(level, Vector2(hazard.pos))] = true

	var candidates: Array[Vector2i] = []
	for y in range(level.map.size()):
		for x in range(String(level.map[y]).length()):
			var cell := Vector2i(x, y)
			if String(level.map[y])[x] == " " or occupied_cells.has(cell):
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
	for _hazard_index in range(mini(bounded_count, candidates.size())):
		var candidate_index := rng.randi_range(0, candidates.size() - 1)
		var cell: Vector2i = candidates.pop_at(candidate_index)
		var hazard: Dictionary = {
			"type": hazard_type,
			"pos": _cell_to_world(rows, cell),
			"size": Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE),
		}
		if hazard_type == "direction":
			var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
			hazard["direction"] = directions[rng.randi_range(0, directions.size() - 1)]
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
	var height := maxi(int(parameters.get("map_height", 6)), 5)
	var start_y := rng.randi_range(1, height - 2)
	var max_bend := maxi(int(parameters.get("max_bend", 1)), 0)
	var hole_y := clampi(start_y + rng.randi_range(-max_bend, max_bend), 1, height - 2)
	var start_cell := Vector2i(1, start_y)
	var hole_cell := Vector2i(width - 2, hole_y)
	var lane_radius := _lane_radius(parameters, hole_index)
	var route_centers: Array[int] = []
	for x in range(width):
		var progress := float(x) / float(width - 1)
		route_centers.append(roundi(lerpf(float(start_y), float(hole_y), progress)))

	var rows: Array[String] = []
	for y in range(height):
		var row := ""
		for x in range(width):
			row += "#" if absi(y - route_centers[x]) <= lane_radius else " "
		rows.append(row)

	var level := {
		"map": rows,
		"start_cell": start_cell,
		"hole_cell": hole_cell,
		"par": 3 if hole_index == 0 else 4,
		"cup_radius": 32.0 - float(hole_index) * 4.0,
		"hazards": _generate_hazards(profile, rows, route_centers, start_cell, hole_cell, hole_index, rng),
		"obstacles": []
	}
	_apply_profile_metadata(level, profile, run_seed, biome_index, hole_index, attempt + 1, false)
	return level


static func _generate_hazards(
	profile,
	rows: Array[String],
	route_centers: Array[int],
	start_cell: Vector2i,
	hole_cell: Vector2i,
	hole_index: int,
	rng: RandomNumberGenerator
) -> Array[Dictionary]:
	var candidates: Array[Vector2i] = []
	for y in range(rows.size()):
		for x in range(rows[y].length()):
			var cell := Vector2i(x, y)
			if rows[y][x] == " ":
				continue
			if absi(y - route_centers[x]) <= 0:
				continue
			if _manhattan_distance(cell, start_cell) <= 2 or _manhattan_distance(cell, hole_cell) <= 2:
				continue
			candidates.append(cell)

	var hazard_bonus := maxi(int(profile.generator_difficulty.get("hazard_bonus", 0)), 0)
	var desired_count := clampi(1 + hole_index + hazard_bonus, 1, 7)
	var hazards: Array[Dictionary] = []
	for _hazard_index in range(mini(desired_count, candidates.size())):
		var candidate_index := rng.randi_range(0, candidates.size() - 1)
		var cell := candidates[candidate_index]
		candidates.remove_at(candidate_index)
		var hazard_type := _pick_weighted_hazard(profile.hazard_weights, rng)
		var hazard := {
			"type": hazard_type,
			"pos": _cell_to_world(rows, cell),
			"size": Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE)
		}
		if hazard_type == "direction":
			var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
			hazard["direction"] = directions[rng.randi_range(0, directions.size() - 1)]
		hazards.append(hazard)
	return hazards


static func _pick_weighted_hazard(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total_weight := 0.0
	for hazard_type in HAZARD_TYPES:
		total_weight += maxf(float(weights.get(hazard_type, 0.0)), 0.0)
	if total_weight <= 0.0:
		return "rough"

	var roll := rng.randf() * total_weight
	for hazard_type in HAZARD_TYPES:
		roll -= maxf(float(weights.get(hazard_type, 0.0)), 0.0)
		if roll <= 0.0:
			return hazard_type
	return "rough"


static func _lane_radius(parameters: Dictionary, hole_index: int) -> int:
	match hole_index:
		0:
			return maxi(int(parameters.get("lane_radius_easy", 2)), 1)
		1:
			return maxi(int(parameters.get("lane_radius_normal", 2)), 1)
		_:
			return maxi(int(parameters.get("lane_radius_hard", 1)), 1)


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
