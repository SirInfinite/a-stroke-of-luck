extends SceneTree

const Generator := preload("res://scripts/hole_generator.gd")
const Biomes := preload("res://scripts/biome_database.gd")
const Difficulties := preload("res://scripts/difficulty_database.gd")
const Validator := preload("res://scripts/level_validator.gd")
const Motifs := preload("res://scripts/course_motifs.gd")

func _init() -> void:
	var seed_count := 24
	var output_path := "user://procgen_overhaul_20260906/corpus.json"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed-count="):
			seed_count = clampi(int(argument.get_slice("=", 1)), 1, 1000)
		if argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	var summary := {"holes": 0, "validation_failures": 0, "fallbacks": 0, "quality_sum": 0.0, "quality_min": 100.0, "relevance_sum": 0.0, "relevance_min": 1.0, "trivial_direct_lines": 0, "branches": 0, "dead_ends": 0, "elevations": 0, "tunnels": 0, "moving_holes": 0, "bounce_holes": 0, "candidates": 0, "rejections": 0, "quality_rejections": 0, "clusters": {}, "motifs": {}, "by_difficulty": {}, "by_biome_arc": {}, "rejection_reasons": {}, "examples": {}, "fallback_examples": [], "curse_shortfalls": 0, "max_hole_ms": 0.0}
	var started := Time.get_ticks_usec()
	var generation_times: Array[float] = []
	summary["terrain_clusters"] = {}
	summary["retries"] = 0
	summary["rejected_candidate_examples"] = []
	summary["by_progression"] = {}
	summary["by_difficulty_progression"] = {}
	summary["baseline_by_difficulty"] = {}
	summary["baseline_by_progression"] = {}
	var profiles := Biomes.get_profiles()
	for seed_index in range(1, seed_count + 1):
		for difficulty in Difficulties.get_profiles():
			for curse_type in ["none", "direction", "water", "blocker"]:
				for index in range(18):
					var options := difficulty.generation_options()
					var count := 0 if curse_type == "none" else 2 if seed_index % 2 == 1 else 4
					options.merge({"added_hazard_count": count, "preferred_hazard_type": curse_type, "modifier_seed": seed_index * 104729})
					var tick := Time.get_ticks_usec()
					var level := Generator.generate_hole(profiles[index / 3], seed_index * 7919, index / 3, index % 3, Generator.MAX_GENERATION_ATTEMPTS, options)
					var elapsed_ms := (Time.get_ticks_usec() - tick) / 1000.0
					generation_times.append(elapsed_ms)
					summary.max_hole_ms = maxf(summary.max_hole_ms, elapsed_ms)
					_accumulate(summary, level, difficulty.id, curse_type, count)
		print("PROCGEN_PROGRESS seeds=%d/%d holes=%d fallbacks=%d" % [seed_index, seed_count, summary.holes, summary.fallbacks])
	summary["elapsed_seconds"] = (Time.get_ticks_usec() - started) / 1000000.0
	summary["average_hole_ms"] = summary.elapsed_seconds * 1000.0 / maxf(summary.holes, 1)
	summary["quality_average"] = summary.quality_sum / maxf(summary.holes, 1)
	summary["relevance_average"] = summary.relevance_sum / maxf(summary.holes, 1)
	summary["fallback_percent"] = summary.fallbacks * 100.0 / maxf(summary.holes, 1)
	summary["candidate_rejection_percent"] = summary.rejections * 100.0 / maxf(summary.candidates, 1)
	generation_times.sort()
	summary["generation_median_ms"] = generation_times[generation_times.size() / 2]
	summary["generation_p95_ms"] = generation_times[mini(int(generation_times.size() * 0.95), generation_times.size() - 1)]
	summary["missing_motifs"] = Motifs.IDS.filter(func(id: String) -> bool: return not summary.motifs.has(id))
	var json := JSON.stringify(summary, "  ")
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		push_error("Unable to save the procgen corpus report: %s" % error_string(FileAccess.get_open_error()))
		quit(1)
		return
	file.store_string(json)
	print("PROCGEN_CORPUS_JSON=" + json)
	var passed: bool = summary.validation_failures == 0 and summary.fallbacks == 0 and summary.curse_shortfalls == 0 and summary.quality_min >= Generator.MINIMUM_QUALITY_SCORE
	if seed_count >= 8:
		passed = passed and summary.missing_motifs.is_empty()
	quit(0 if passed else 1)

func _accumulate(s: Dictionary, level: Dictionary, difficulty: StringName, curse: String, requested_count: int) -> void:
	s.holes += 1
	var valid := Validator.validate_level(level, int(level.overall_hole_number) - 1, false)
	s.validation_failures += 0 if valid else 1
	s.fallbacks += 1 if bool(level.used_fallback) else 0
	s.curse_shortfalls += 1 if int(level.get("card_hazard_count", 0)) < requested_count else 0
	if bool(level.used_fallback) and s.fallback_examples.size() < 12:
		s.fallback_examples.append({"seed": level.run_seed, "hole": level.overall_hole_number, "difficulty": difficulty, "curse": curse, "candidates": level.candidate_scores})
	var m := Generator.quality_metrics(level)
	s.quality_sum += float(level.quality_score)
	s.quality_min = minf(s.quality_min, float(level.quality_score))
	s.relevance_sum += float(m.route_relevant_ratio)
	s.relevance_min = minf(s.relevance_min, float(m.route_relevant_ratio))
	s.trivial_direct_lines += 1 if bool(m.get("trivial_direct_line", false)) else 0
	s.branches += 1 if not level.get("branches", []).is_empty() else 0
	s.elevations += 1 if not level.get("elevation_structures", []).is_empty() else 0
	s.moving_holes += 1 if not level.get("moving_hazards", []).is_empty() else 0
	s.bounce_holes += 1 if level.hazards.any(func(h: Dictionary) -> bool: return h.type == "bounce_pad") else 0
	for branch: Dictionary in level.get("branches", []):
		s.dead_ends += 1 if branch.kind == "dead_end" else 0
	for structure: Dictionary in level.get("elevation_structures", []):
		s.tunnels += 1 if structure.type == "overpass" else 0
	for size in m.hazard_cluster_sizes:
		_increment(s.clusters, str(size))
	var counted := {}
	for hazard: Dictionary in level.hazards:
		if hazard.type not in ["water", "lava", "sand", "ice"] or counted.has(hazard.get("cluster_id", "")):
			continue
		counted[hazard.get("cluster_id", "")] = true
		var size := int(hazard.get("cluster_size", 1))
		_increment(s.terrain_clusters, "%s_%d" % [hazard.type, size])
		_example(s, "cluster_%d" % size, level, difficulty, curse, requested_count)
	for motif in level.get("selected_motifs", []):
		_increment(s.motifs, motif)
		_example(s, motif, level, difficulty, curse, requested_count)
	s.candidates += int(level.candidate_count_considered)
	s.rejections += int(level.candidate_rejection_count)
	s.quality_rejections += int(level.candidate_quality_rejection_count)
	s.retries += int(level.generation_retry_count)
	for candidate: Dictionary in level.candidate_scores:
		if not candidate.valid and s.rejected_candidate_examples.size() < 20:
			s.rejected_candidate_examples.append({"seed": level.run_seed, "hole": level.overall_hole_number,
				"difficulty": difficulty, "curse": curse, "count": requested_count,
				"modifier_seed": int(level.run_seed) / 7919 * 104729, "candidate": candidate.duplicate(true)})
		for reason in candidate.reasons:
			_increment(s.rejection_reasons, reason)
	var stage: String = ["early", "mid", "late"][clampi((int(level.overall_hole_number) - 1) / 6, 0, 2)]
	for key in ["by_difficulty", "by_biome_arc", "by_progression", "by_difficulty_progression", "baseline_by_difficulty", "baseline_by_progression"]:
		if key.begins_with("baseline_") and curse != "none":
			continue
		var bucket := String(difficulty)
		if key == "by_biome_arc":
			bucket = "%s_%d" % [level.biome_id, level.hole_index + 1]
		elif key.ends_with("by_progression"):
			bucket = stage
		elif key == "by_difficulty_progression":
			bucket = "%s_%s" % [difficulty, stage]
		if not s[key].has(bucket):
			s[key][bucket] = {"holes": 0, "placements": 0, "shots": 0, "moving": 0, "elevation": 0, "branch": 0, "terrain": 0, "blockers": 0, "relevant": 0, "cluster_cells": 0, "clusters": 0, "quality_sum": 0.0, "fallbacks": 0}
		var group: Dictionary = s[key][bucket]
		group.holes += 1
		group.placements += int(m.placement_count)
		group.shots += int(m.get("minimum_shot_estimate", 0))
		group.moving += int(m.get("moving_count", 0))
		group.elevation += 1 if not level.get("elevation_structures", []).is_empty() else 0
		group.branch += 1 if not level.get("branches", []).is_empty() else 0
		group.terrain += level.hazards.size()
		group.blockers += level.obstacles.size()
		group.relevant += int(m.route_relevant_count)
		group.clusters += m.hazard_cluster_sizes.size()
		for size in m.hazard_cluster_sizes:
			group.cluster_cells += int(size)
		group.quality_sum += float(level.quality_score)
		group.fallbacks += 1 if bool(level.used_fallback) else 0

func _increment(histogram: Dictionary, key: String) -> void:
	histogram[key] = int(histogram.get(key, 0)) + 1

func _example(s: Dictionary, key: String, level: Dictionary, difficulty: StringName, curse: String, count: int) -> void:
	if not s.examples.has(key):
		s.examples[key] = {"seed": level.run_seed, "hole": level.overall_hole_number, "difficulty": difficulty, "curse": curse, "count": count, "modifier_seed": int(level.run_seed) / 7919 * 104729}
