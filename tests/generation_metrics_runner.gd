extends SceneTree

const BiomeDatabase := preload("res://scripts/biome_database.gd")
const DifficultyDatabase := preload("res://scripts/difficulty_database.gd")
const HoleGenerator := preload("res://scripts/hole_generator.gd")
const LevelValidator := preload("res://scripts/level_validator.gd")


func _init() -> void:
	var seed_count := _seed_count_from_args()
	var profiles: Array = BiomeDatabase.get_profiles()
	var metrics := {
		"seed_count": seed_count,
		"difficulty_count": 3,
		"hole_count": 0,
		"valid_holes": 0,
		"fallback_holes": 0,
		"quality_failures": 0,
		"route_relevant_sum": 0.0,
		"route_relevant_min": 1.0,
		"direct_line_interaction_holes": 0,
		"meaningful_challenge_holes": 0,
		"occupancy_conflicts": 0,
		"minimum_route_width": 999,
		"route_width_sum": 0.0,
		"elevation_holes": 0,
		"elevation_crossings": 0,
		"elevation_anomalies": 0,
		"maximum_tunnel_length": 0,
		"candidate_rejections": 0,
		"candidate_quality_rejections": 0,
		"candidate_considered": 0,
		"unreachable_cells": 0,
		"holes_with_unreachable_cells": 0,
		"cluster_size_histogram": {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0},
		"hazard_type_cells": {},
		"by_difficulty": {},
		"by_biome": {},
		"representative_examples": {},
	}
	for difficulty in DifficultyDatabase.get_profiles():
		metrics.by_difficulty[String(difficulty.id)] = {"holes": 0, "valid": 0, "fallbacks": 0}
		for seed_index in range(1, seed_count + 1):
			var run_seed := seed_index * 7919
			var levels := HoleGenerator.generate_run(profiles, run_seed, difficulty.generation_options())
			for level_index in range(levels.size()):
				_accumulate(metrics, levels[level_index], level_index, difficulty.id, run_seed)
	var hole_count := maxi(int(metrics.hole_count), 1)
	metrics["valid_route_percent"] = snappedf(float(metrics.valid_holes) / float(hole_count) * 100.0, 0.001)
	metrics["fallback_percent"] = snappedf(float(metrics.fallback_holes) / float(hole_count) * 100.0, 0.001)
	metrics["route_relevant_percent"] = snappedf(float(metrics.route_relevant_sum) / float(hole_count) * 100.0, 0.001)
	metrics["direct_line_interaction_percent"] = snappedf(float(metrics.direct_line_interaction_holes) / float(hole_count) * 100.0, 0.001)
	metrics["meaningful_challenge_percent"] = snappedf(float(metrics.meaningful_challenge_holes) / float(hole_count) * 100.0, 0.001)
	metrics["average_route_width"] = snappedf(float(metrics.route_width_sum) / float(hole_count), 0.001)
	metrics["candidate_rejection_percent"] = snappedf(
		float(metrics.candidate_rejections) / float(maxi(int(metrics.candidate_considered), 1)) * 100.0,
		0.001
	)
	metrics["candidate_quality_discard_percent"] = snappedf(
		float(metrics.candidate_quality_rejections) / float(maxi(int(metrics.candidate_considered), 1)) * 100.0,
		0.001
	)
	print("GENERATION_METRICS_JSON=%s" % JSON.stringify(metrics, "  ", false))
	quit(0 if int(metrics.valid_holes) == int(metrics.hole_count) and int(metrics.fallback_holes) == 0 else 1)


func _accumulate(
	metrics: Dictionary,
	level: Dictionary,
	level_index: int,
	difficulty_id: StringName,
	run_seed: int
) -> void:
	metrics.hole_count += 1
	var is_valid := LevelValidator.validate_level(level, level_index)
	if is_valid:
		metrics.valid_holes += 1
	var used_fallback := bool(level.get("used_fallback", false))
	if used_fallback:
		metrics.fallback_holes += 1
	var difficulty_metrics: Dictionary = metrics.by_difficulty[String(difficulty_id)]
	difficulty_metrics.holes += 1
	difficulty_metrics.valid += 1 if is_valid else 0
	difficulty_metrics.fallbacks += 1 if used_fallback else 0
	var biome_name := String(level.get("biome_name", "unknown"))
	if not metrics.by_biome.has(biome_name):
		metrics.by_biome[biome_name] = {"holes": 0, "valid": 0, "fallbacks": 0}
	var biome_metrics: Dictionary = metrics.by_biome[biome_name]
	biome_metrics.holes += 1
	biome_metrics.valid += 1 if is_valid else 0
	biome_metrics.fallbacks += 1 if used_fallback else 0
	if not bool(level.get("quality_passed", false)):
		metrics.quality_failures += 1
	metrics.candidate_rejections += int(level.get("candidate_rejection_count", 0))
	metrics.candidate_quality_rejections += int(level.get("candidate_quality_rejection_count", 0))
	metrics.candidate_considered += int(level.get("candidate_count_considered", 0))
	var quality := HoleGenerator.quality_metrics(level)
	var relevant_ratio := float(quality.route_relevant_ratio)
	metrics.route_relevant_sum += relevant_ratio
	metrics.route_relevant_min = minf(float(metrics.route_relevant_min), relevant_ratio)
	if int(quality.direct_line_interactions) > 0:
		metrics.direct_line_interaction_holes += 1
	if int(quality.route_relevant_count) > 0 and int(quality.challenge_role_count) > 0:
		metrics.meaningful_challenge_holes += 1
	for cluster_size in quality.hazard_cluster_sizes:
		var size_key := str(clampi(int(cluster_size), 1, 5))
		metrics.cluster_size_histogram[size_key] = int(metrics.cluster_size_histogram[size_key]) + 1
	for hazard in level.get("hazards", []):
		var hazard_type := String(hazard.get("type", ""))
		metrics.hazard_type_cells[hazard_type] = int(metrics.hazard_type_cells.get(hazard_type, 0)) + 1
		if hazard_type == "water" and int(hazard.get("cluster_index", 0)) == 0:
			var cluster_size := int(hazard.get("cluster_size", 1))
			if cluster_size == 1:
				_record_example(metrics, "water_single", level, level_index, difficulty_id, run_seed, {"cluster_size": cluster_size})
			elif cluster_size <= 3:
				_record_example(metrics, "water_small_cluster", level, level_index, difficulty_id, run_seed, {"cluster_size": cluster_size})
			else:
				_record_example(metrics, "water_large_cluster", level, level_index, difficulty_id, run_seed, {"cluster_size": cluster_size})
		if hazard_type == "sand" and int(hazard.get("cluster_index", 0)) == 0:
			_record_example(metrics, "sand_cluster", level, level_index, difficulty_id, run_seed, {"cluster_size": int(hazard.get("cluster_size", 1))})
	if not level.get("obstacles", []).is_empty():
		_record_example(metrics, "blocker_interaction", level, level_index, difficulty_id, run_seed)
	if not level.get("moving_hazards", []).is_empty():
		_record_example(metrics, "moving_hazard_interaction", level, level_index, difficulty_id, run_seed)
	for branch in level.get("branches", []):
		if String(branch.get("kind", "")) == "dead_end":
			_record_example(metrics, "branch_dead_end", level, level_index, difficulty_id, run_seed)
			break
	for placements in LevelValidator.placement_occupancy(level).values():
		if Array(placements).size() > 1:
			metrics.occupancy_conflicts += 1
	var width := _minimum_route_width(level)
	metrics.minimum_route_width = mini(int(metrics.minimum_route_width), width)
	metrics.route_width_sum += float(width)
	var unreachable_count := _unreachable_cell_count(level)
	metrics.unreachable_cells += unreachable_count
	metrics.holes_with_unreachable_cells += 1 if unreachable_count > 0 else 0
	if not level.get("elevation_transitions", []).is_empty():
		metrics.elevation_holes += 1
	for structure in level.get("elevation_structures", []):
		var structure_type := String(structure.get("type", ""))
		if structure_type == "lower_area":
			_record_example(metrics, "lower_elevation", level, level_index, difficulty_id, run_seed)
		if structure_type != "overpass":
			continue
		_record_example(metrics, "short_overpass", level, level_index, difficulty_id, run_seed)
		metrics.elevation_crossings += 1
		var tunnel_length := int(structure.get("tunnel_length", Array(structure.get("cells", [])).size()))
		metrics.maximum_tunnel_length = maxi(int(metrics.maximum_tunnel_length), tunnel_length)
		if tunnel_length < 1 or tunnel_length > 2 or Array(structure.get("cells", [])).size() > 2:
			metrics.elevation_anomalies += 1
	if difficulty_id == &"hard" and level_index >= 15:
		_record_example(metrics, "late_hard_hole", level, level_index, difficulty_id, run_seed)


func _record_example(
	metrics: Dictionary,
	key: String,
	level: Dictionary,
	level_index: int,
	difficulty_id: StringName,
	run_seed: int,
	extra: Dictionary = {}
) -> void:
	if metrics.representative_examples.has(key):
		return
	var example := {
		"seed": run_seed,
		"difficulty": String(difficulty_id),
		"hole": level_index + 1,
		"biome": String(level.get("biome_name", "unknown")),
		"quality_score": snappedf(float(level.get("quality_score", 0.0)), 0.001),
	}
	for extra_key in extra:
		example[extra_key] = extra[extra_key]
	metrics.representative_examples[key] = example


func _minimum_route_width(level: Dictionary) -> int:
	var playable := {}
	for y in range(level.map.size()):
		var row := String(level.map[y])
		for x in range(row.length()):
			if row[x] != " ":
				playable[Vector2i(x, y)] = true
	var minimum_width := 5
	for cell in level.get("main_route_cells", []):
		var open_neighbors := 1
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if playable.has(Vector2i(cell) + Vector2i(direction)):
				open_neighbors += 1
		minimum_width = mini(minimum_width, open_neighbors)
	return minimum_width


func _unreachable_cell_count(level: Dictionary) -> int:
	var playable := {}
	for y in range(level.map.size()):
		var row := String(level.map[y])
		for x in range(row.length()):
			if row[x] != " ":
				playable[Vector2i(x, y)] = true
	var start := Vector2i(level.start_cell)
	var visited := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var neighbor: Vector2i = current + Vector2i(direction)
			if playable.has(neighbor) and not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	return maxi(playable.size() - visited.size(), 0)


func _seed_count_from_args() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed-count="):
			return clampi(int(argument.get_slice("=", 1)), 1, 1000)
	return 48
