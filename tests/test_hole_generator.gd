extends GutTest

const BiomeDatabase := preload("res://scripts/biome_database.gd")
const HoleGenerator := preload("res://scripts/hole_generator.gd")
const LevelValidator := preload("res://scripts/level_validator.gd")
const BiomeHazardProfiles := preload("res://scripts/biome_hazard_profiles.gd")
const DifficultyDatabase := preload("res://scripts/difficulty_database.gd")

const TEST_SEED := 8675309


func test_production_biome_profiles_have_required_data() -> void:
	var profiles: Array = BiomeDatabase.get_profiles()
	assert_eq(profiles.size(), 6)
	assert_eq(_profile_names(profiles), ["Meadow", "Desert", "Autumn", "Snow", "Swamp", "Volcanic"])

	for profile in profiles:
		assert_ne(String(profile.id), "")
		assert_ne(profile.display_name, "")
		assert_true(profile.terrain_palette.has("fairway_a"))
		assert_true(profile.background_palette.has("primary"))
		assert_false(profile.decoration_identifiers.is_empty())
		assert_false(profile.hazard_weights.is_empty())
		assert_true(profile.generator_difficulty.has("section_stretch"))
		assert_ne(String(profile.ambience), "")


func test_same_seed_generates_same_valid_eighteen_holes() -> void:
	var profiles: Array = BiomeDatabase.get_profiles()
	var first_run: Array[Dictionary] = HoleGenerator.generate_run(profiles, TEST_SEED)
	var second_run: Array[Dictionary] = HoleGenerator.generate_run(profiles, TEST_SEED)

	assert_eq(first_run.size(), 18)
	assert_eq(second_run.size(), 18)
	for index in range(first_run.size()):
		assert_eq(first_run[index], second_run[index], "Hole %d must be deterministic." % [index + 1])
		assert_true(LevelValidator.validate_level(first_run[index], index))
		assert_false(bool(first_run[index].used_fallback))
		assert_eq(int(first_run[index].biome_index), index / 3)
		assert_eq(int(first_run[index].hole_index), index % 3)
		assert_eq(int(first_run[index].overall_hole_number), index + 1)
		assert_eq(int(first_run[index].run_seed), TEST_SEED)


func test_each_biome_scales_authored_challenge_clusters_without_random_clutter() -> void:
	var levels: Array[Dictionary] = HoleGenerator.generate_run(BiomeDatabase.get_profiles(), TEST_SEED)
	for biome_index in range(6):
		var first_budget: int = levels[biome_index * 3].challenge_budget
		var second_budget: int = levels[biome_index * 3 + 1].challenge_budget
		var third_budget: int = levels[biome_index * 3 + 2].challenge_budget
		assert_lte(first_budget, second_budget)
		assert_lte(second_budget, third_budget)
		for arc in range(3):
			assert_lte(HoleGenerator.quality_metrics(levels[biome_index * 3 + arc]).occupied_ratio, 0.25, "Pressure keeps recovery space")
		assert_eq(String(levels[biome_index * 3].difficulty_name), "Introductory")
		assert_eq(String(levels[biome_index * 3 + 1].difficulty_name), "Normal")
		assert_eq(String(levels[biome_index * 3 + 2].difficulty_name), "Hardest")


func test_zero_retry_budget_uses_valid_authored_fallback() -> void:
	var profile = BiomeDatabase.get_profiles()[5]
	var fallback: Dictionary = HoleGenerator.generate_hole(profile, TEST_SEED, 5, 2, 0)

	assert_true(bool(fallback.used_fallback))
	assert_eq(int(fallback.overall_hole_number), 18)
	assert_eq(String(fallback.biome_name), "Volcanic")
	assert_true(LevelValidator.validate_level(fallback, 17))
	assert_true(_hazard_types(fallback).has("lava"))
	assert_true(_hazard_types(fallback).has("bounce_pad"))
	assert_false(_hazard_types(fallback).has("water"))


func test_card_hazard_modifier_is_seeded_bounded_and_valid() -> void:
	var profile = BiomeDatabase.get_profiles()[1]
	var base_level: Dictionary = HoleGenerator.generate_hole(profile, TEST_SEED, 1, 0)
	var first: Dictionary = HoleGenerator.apply_hazard_modifier(base_level, 2, &"direction", TEST_SEED + 17)
	var second: Dictionary = HoleGenerator.apply_hazard_modifier(base_level, 2, &"direction", TEST_SEED + 17)

	assert_eq(first, second)
	assert_eq(first.hazards.filter(func(hazard: Dictionary) -> bool: return bool(hazard.get("curse_added", false))).size(), 2)
	assert_eq(int(first.card_hazard_count), 2)
	assert_true(LevelValidator.validate_level(first, 3))
	for hazard: Dictionary in first.hazards:
		if bool(hazard.get("curse_added", false)):
			assert_eq(String(hazard.type), "direction")
			assert_true(hazard.has("direction"))

	var clamped: Dictionary = HoleGenerator.apply_hazard_modifier(base_level, 99, &"direction", TEST_SEED + 17)
	assert_lte(int(clamped.card_hazard_count), 4)
	assert_true(LevelValidator.validate_level(clamped, 3))


func test_large_seed_corpus_across_difficulties_is_valid_interactive_and_varied() -> void:
	var profiles: Array = BiomeDatabase.get_profiles()
	var cluster_sizes_seen := {}
	var terrain_sizes_seen := {"water": {}, "sand": {}}
	for difficulty in DifficultyDatabase.get_profiles():
		for seed_value in range(1, 49):
			var reproducible_seed := seed_value * 7919
			var levels: Array[Dictionary] = HoleGenerator.generate_run(profiles, reproducible_seed, difficulty.generation_options())
			assert_eq(levels.size(), 18)
			for index in range(levels.size()):
				var level := levels[index]
				var failure_context := "difficulty=%s seed=%d hole=%d" % [difficulty.id, reproducible_seed, index + 1]
				assert_true(LevelValidator.validate_level(level, index), failure_context)
				assert_false(bool(level.used_fallback), failure_context)
				assert_gte(float(level.quality_score), HoleGenerator.MINIMUM_QUALITY_SCORE, failure_context)
				assert_eq(StringName(level.run_difficulty_id), difficulty.id, failure_context)
				var metrics := HoleGenerator.quality_metrics(level)
				assert_gte(float(metrics.route_relevant_ratio), 0.65, failure_context)
				if difficulty.id != &"easy":
					assert_true(int(metrics.direct_line_interactions) > 0 or bool(metrics.direct_line_blocked_by_geometry), failure_context)
				assert_gte(int(metrics.challenge_role_count), 1, failure_context)
				for cluster_size in metrics.hazard_cluster_sizes:
					cluster_sizes_seen[int(cluster_size)] = true
				_assert_compact_hazard_clusters(level, failure_context, terrain_sizes_seen)
				for placements in LevelValidator.placement_occupancy(level).values():
					assert_eq(Array(placements).size(), 1, failure_context)
	for expected_size in range(1, 6):
		assert_true(cluster_sizes_seen.has(expected_size), "Corpus should contain cluster size %d." % expected_size)
	assert_gte(Dictionary(terrain_sizes_seen.water).size(), 4, "Water should use single, small, and rare larger formations.")
	assert_gte(Dictionary(terrain_sizes_seen.sand).size(), 3, "Sand should use multiple compact formation sizes.")


func test_best_candidate_selection_is_deterministic_and_score_driven() -> void:
	var profile = BiomeDatabase.get_profiles()[5]
	var selected := HoleGenerator.generate_hole(profile, TEST_SEED, 5, 2)
	var repeated := HoleGenerator.generate_hole(profile, TEST_SEED, 5, 2)
	assert_eq(selected, repeated)
	assert_eq(int(selected.candidate_count_considered), HoleGenerator.MAX_GENERATION_ATTEMPTS)
	assert_true(bool(selected.quality_passed))

	var best_score := -1.0
	for attempt in range(HoleGenerator.MAX_GENERATION_ATTEMPTS):
		var candidate := HoleGenerator._generate_candidate(profile, TEST_SEED, 5, 2, attempt)
		if LevelValidator.validate_level(candidate, 17):
			best_score = maxf(best_score, float(HoleGenerator.score_candidate(candidate).score))
	assert_eq(float(selected.quality_score), best_score)


func test_quality_score_penalizes_a_broken_primary_route() -> void:
	var profile = BiomeDatabase.get_profiles()[2]
	var coherent := HoleGenerator.generate_hole(profile, TEST_SEED, 2, 1)
	var broken := coherent.duplicate(true)
	broken.main_route_cells = [broken.start_cell, broken.hole_cell]
	assert_gt(float(HoleGenerator.score_candidate(coherent).score), float(HoleGenerator.score_candidate(broken).score))


func test_all_generated_placements_are_surface_exclusive_and_endpoint_safe() -> void:
	var levels := HoleGenerator.generate_run(BiomeDatabase.get_profiles(), TEST_SEED)
	for level_index in range(levels.size()):
		var level: Dictionary = levels[level_index]
		for placements in LevelValidator.placement_occupancy(level).values():
			assert_eq(Array(placements).size(), 1, "hole=%d" % (level_index + 1))
		var start := Vector2i(level.start_cell)
		var cup := Vector2i(level.hole_cell)
		for surface in LevelValidator.placement_occupancy(level):
			var occupied_cell := Vector2i(surface.x, surface.y)
			assert_gt(_manhattan(start, occupied_cell), 1)
			assert_gt(_manhattan(cup, occupied_cell), 1)


func test_biome_hazard_profiles_map_required_release_semantics() -> void:
	assert_eq(BiomeHazardProfiles.reset_hazard_for(&"meadow"), "water")
	assert_eq(BiomeHazardProfiles.reset_hazard_for(&"snow"), "water")
	assert_eq(BiomeHazardProfiles.reset_hazard_for(&"volcanic"), "lava")
	assert_eq(BiomeHazardProfiles.moving_hazard_for(&"meadow", 2), "pendulum")
	assert_eq(BiomeHazardProfiles.moving_hazard_for(&"snow", 0), "falling_ice")
	assert_eq(BiomeHazardProfiles.moving_hazard_for(&"volcanic", 0), "rotating_fire_rod")
	assert_true(BiomeHazardProfiles.required_static_types(&"snow", 0).has("ice"))
	assert_true(BiomeHazardProfiles.required_static_types(&"desert", 0).has("sand"))


func test_generated_holes_use_no_removed_surface_hazards_and_include_biome_variants() -> void:
	# Availability is an aggregate contract, not a promise that every run has a pad.
	var levels: Array[Dictionary] = []
	for seed_offset in range(4):
		levels.append_array(HoleGenerator.generate_run(BiomeDatabase.get_profiles(), TEST_SEED + seed_offset))
	var seen_types := {}
	var seen_moving := {}
	for level in levels:
		for hazard in level.hazards:
			var hazard_type := String(hazard.type)
			assert_false(hazard_type in ["rough", "out"])
			seen_types[hazard_type] = true
		for hazard in level.moving_hazards:
			seen_moving[String(hazard.type)] = true

	assert_true(seen_types.has("water"))
	assert_true(seen_types.has("sand"))
	assert_true(seen_types.has("ice"))
	assert_true(seen_types.has("lava"))
	assert_true(seen_types.has("bounce_pad"))
	assert_true(seen_moving.has("pendulum"))
	assert_true(seen_moving.has("falling_ice"))
	assert_true(seen_moving.has("rotating_fire_rod"))


func test_secondary_branches_are_optional_valid_and_never_replace_main_route() -> void:
	var levels := HoleGenerator.generate_run(BiomeDatabase.get_profiles(), TEST_SEED)
	var holes_with_branches := 0
	var dead_end_count := 0
	for level_index in range(levels.size()):
		var level: Dictionary = levels[level_index]
		if not level.branches.is_empty():
			holes_with_branches += 1
		for branch in level.branches:
			assert_true(String(branch.kind) in ["alternate", "dead_end", "shortcut"])
			assert_true(Array(branch.cells).has(branch.entry_cell))
			assert_true(Array(branch.cells).has(branch.escape_cell) or branch.escape_cell == branch.entry_cell)
			if String(branch.kind) == "dead_end":
				dead_end_count += 1
		assert_true(LevelValidator.validate_level(level, level_index))

	assert_gte(holes_with_branches, 1)
	assert_lte(holes_with_branches, 12, "Branches must no longer appear on almost every hole.")
	assert_lte(dead_end_count, 6)


func test_later_generation_adds_discrete_elevation_and_overpasses() -> void:
	var levels := HoleGenerator.generate_run(BiomeDatabase.get_profiles(), TEST_SEED)
	var elevation_holes := 0
	var saw_ramp := false
	var saw_overpass := false
	var saw_lower_area := false
	for level_index in range(3, levels.size()):
		var level: Dictionary = levels[level_index]
		if not level.elevation_transitions.is_empty():
			elevation_holes += 1
			saw_ramp = true
			for structure in level.elevation_structures:
				saw_overpass = saw_overpass or String(structure.type) == "overpass"
				saw_lower_area = saw_lower_area or String(structure.type) == "lower_area"
				if String(structure.type) == "overpass":
					assert_lte(int(structure.tunnel_length), 2)
					assert_lte(Array(structure.cells).size(), 2)
	assert_gte(elevation_holes, 1)
	assert_lte(elevation_holes, 8)
	assert_true(saw_ramp)
	# Crossings and lower areas are sampled in the expanded grammar corpus;
	# they are no longer forced onto one fixed hole of every run.


func _profile_names(profiles: Array) -> Array:
	var names: Array = []
	for profile in profiles:
		names.append(profile.display_name)
	return names


func _hazard_types(level: Dictionary) -> Array[String]:
	var types: Array[String] = []
	for hazard in level.hazards:
		types.append(String(hazard.type))
	return types


func _manhattan(first: Vector2i, second: Vector2i) -> int:
	return absi(first.x - second.x) + absi(first.y - second.y)


func _cluster_count(level: Dictionary) -> int:
	var ids := {}
	for hazard in level.hazards:
		if String(hazard.type) == "bounce_pad":
			continue
		ids[String(hazard.get("cluster_id", "legacy_%d" % ids.size()))] = true
	return ids.size()


func _assert_compact_hazard_clusters(level: Dictionary, context: String, terrain_sizes_seen: Dictionary) -> void:
	var clusters := {}
	var cluster_types := {}
	for hazard in level.hazards:
		var cluster_id := String(hazard.get("cluster_id", ""))
		assert_false(cluster_id.is_empty(), context)
		if not clusters.has(cluster_id):
			clusters[cluster_id] = []
		clusters[cluster_id].append(HoleGenerator._world_to_cell(level, Vector2(hazard.pos)))
		cluster_types[cluster_id] = String(hazard.type)
	for cluster_id in clusters:
		var cells: Array = clusters[cluster_id]
		assert_gte(cells.size(), 1, context)
		assert_lte(cells.size(), 5, context)
		var visited := {Vector2i(cells[0]): true}
		var frontier: Array[Vector2i] = [Vector2i(cells[0])]
		while not frontier.is_empty():
			var cell: Vector2i = frontier.pop_front()
			for other_cell in cells:
				var typed_cell := Vector2i(other_cell)
				if not visited.has(typed_cell) and _manhattan(cell, typed_cell) == 1:
					visited[typed_cell] = true
					frontier.append(typed_cell)
		assert_eq(visited.size(), cells.size(), "%s cluster=%s" % [context, cluster_id])
		var hazard_type := String(cluster_types[cluster_id])
		if terrain_sizes_seen.has(hazard_type):
			terrain_sizes_seen[hazard_type][cells.size()] = true
