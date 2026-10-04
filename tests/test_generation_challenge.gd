extends GutTest

func test_high_pressure_swamp_recovers_without_authored_fallback() -> void:
	var level := HoleGenerator.generate_hole(BiomeDatabase.get_profiles()[4], 190056, 4, 1, 8, DifficultyDatabase.get_profile(&"hard").generation_options())
	if level.used_fallback:
		print("[PRESSURE REJECTIONS] ", JSON.stringify(level.candidate_scores))
	assert_false(level.used_fallback)

func test_resolved_challenge_preserves_independent_axes_and_three_hole_arc() -> void:
	for difficulty in [&"easy", &"normal", &"hard"]:
		for biome in range(6):
			var previous := 0
			for arc in range(3):
				var profile := GenerationChallenge.resolve(difficulty, biome, arc, CourseMotifs.design_for(&"snow"), {"added_hazard_count": 4})
				var pressure := int(profile.terrain_clusters) + int(profile.blockers)
				assert_gte(pressure, previous)
				previous = pressure
				assert_eq(profile.curse_count, 4)
				assert_lte(profile.max_moving, 2)
				assert_gte(profile.recovery_radius, 1)
		var early := GenerationChallenge.resolve(difficulty, 0, 0, CourseMotifs.design_for(&"meadow"), {})
		var late := GenerationChallenge.resolve(difficulty, 5, 2, CourseMotifs.design_for(&"volcanic"), {})
		assert_gt(late.terrain_clusters, early.terrain_clusters)

func test_generated_difficulty_and_progression_distributions_are_materially_distinct() -> void:
	var groups := {}
	for seed_value in [7919, 15838, 23757, 31676]:
		for difficulty in DifficultyDatabase.get_profiles():
			for index in range(18):
				var level := HoleGenerator.generate_hole(BiomeDatabase.get_profiles()[index / 3], seed_value, index / 3, index % 3, 8, difficulty.generation_options())
				assert_true(LevelValidator.validate_level(level, index, false))
				assert_false(level.used_fallback)
				var metrics := HoleGenerator.quality_metrics(level)
				assert_gte(metrics.route_relevant_ratio, 0.9)
				for key in [String(difficulty.id), ["early", "mid", "late"][index / 6]]:
					if not groups.has(key):
						groups[key] = {"count": 0.0, "placements": 0.0, "moving": 0.0, "blockers": 0.0, "branches": 0.0}
					groups[key].count += 1
					groups[key].placements += metrics.placement_count
					groups[key].moving += metrics.moving_count
					groups[key].blockers += level.obstacles.size()
					groups[key].branches += metrics.branch_count
	for pair in [["easy", "normal"], ["normal", "hard"], ["early", "late"]]:
		var first: Dictionary = groups[pair[0]]
		var second: Dictionary = groups[pair[1]]
		assert_gt(second.placements / second.count, first.placements / first.count * 1.12, "%s pressure should materially exceed %s" % [pair[1], pair[0]])
		assert_gt(second.blockers / second.count, first.blockers / first.count)
		assert_gt(second.moving / second.count, first.moving / first.count)
	print("GENERATION_CHALLENGE_METRICS ", JSON.stringify(groups))
