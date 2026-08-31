extends GutTest

const BiomeDatabase := preload("res://scripts/biome_database.gd")
const HoleGenerator := preload("res://scripts/hole_generator.gd")
const LevelValidator := preload("res://scripts/level_validator.gd")

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
		assert_true(profile.generator_difficulty.has("map_width"))
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


func test_each_biome_scales_hazard_count_across_its_three_holes() -> void:
	var levels: Array[Dictionary] = HoleGenerator.generate_run(BiomeDatabase.get_profiles(), TEST_SEED)
	for biome_index in range(6):
		var first_count: int = levels[biome_index * 3].hazards.size()
		var second_count: int = levels[biome_index * 3 + 1].hazards.size()
		var third_count: int = levels[biome_index * 3 + 2].hazards.size()
		assert_true(first_count < second_count)
		assert_true(second_count < third_count)
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


func test_card_hazard_modifier_is_seeded_bounded_and_valid() -> void:
	var profile = BiomeDatabase.get_profiles()[1]
	var base_level: Dictionary = HoleGenerator.generate_hole(profile, TEST_SEED, 1, 0)
	var first: Dictionary = HoleGenerator.apply_hazard_modifier(base_level, 2, &"direction", TEST_SEED + 17)
	var second: Dictionary = HoleGenerator.apply_hazard_modifier(base_level, 2, &"direction", TEST_SEED + 17)

	assert_eq(first, second)
	assert_eq(first.hazards.size(), base_level.hazards.size() + 2)
	assert_eq(int(first.card_hazard_count), 2)
	assert_true(LevelValidator.validate_level(first, 3))
	for hazard_index in range(base_level.hazards.size(), first.hazards.size()):
		assert_eq(String(first.hazards[hazard_index].type), "direction")
		assert_true(first.hazards[hazard_index].has("direction"))

	var clamped: Dictionary = HoleGenerator.apply_hazard_modifier(base_level, 99, &"direction", TEST_SEED + 17)
	assert_lte(int(clamped.card_hazard_count), 4)
	assert_true(LevelValidator.validate_level(clamped, 3))


func test_batch_seeds_keep_every_generated_hole_valid() -> void:
	var profiles: Array = BiomeDatabase.get_profiles()
	for seed_value in range(1, 33):
		var levels: Array[Dictionary] = HoleGenerator.generate_run(profiles, seed_value * 7919)
		assert_eq(levels.size(), 18)
		for index in range(levels.size()):
			assert_true(LevelValidator.validate_level(levels[index], index))


func _profile_names(profiles: Array) -> Array:
	var names: Array = []
	for profile in profiles:
		names.append(profile.display_name)
	return names
