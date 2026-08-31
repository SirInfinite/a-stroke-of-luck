extends GutTest

const BiomeDatabase := preload("res://scripts/biome_database.gd")
const CourseVisualFactory := preload("res://scripts/course_visual_factory.gd")
const HoleGenerator := preload("res://scripts/hole_generator.gd")
const LevelBuilderScript := preload("res://scripts/level_builder.gd")

const TEST_SEED := 24681357


func test_each_biome_has_a_complete_distinct_visual_profile() -> void:
	var profiles: Array = BiomeDatabase.get_profiles()
	var background_colors := {}
	for profile in profiles:
		assert_eq(profile.decoration_identifiers.size(), 4, "%s needs four reusable decoration assets." % profile.display_name)
		for palette_key in ["fairway_a", "fairway_b", "fairway_detail", "green", "tee", "outline", "sand", "sand_detail", "rough", "rough_detail", "water", "water_detail", "out", "out_detail", "direction", "direction_detail", "flag"]:
			assert_true(profile.terrain_palette.has(palette_key), "%s is missing terrain color %s." % [profile.display_name, palette_key])
		for background_key in ["primary", "secondary", "accent", "shadow", "highlight"]:
			assert_true(profile.background_palette.has(background_key), "%s is missing background color %s." % [profile.display_name, background_key])
		background_colors[profile.background_palette.primary] = true
		for decoration_id in profile.decoration_identifiers:
			var decoration := CourseVisualFactory.create_decoration(
				decoration_id,
				profile.background_palette.highlight,
				profile.background_palette.secondary,
				profile.background_palette.accent
			)
			assert_gte(decoration.get_child_count(), 3, "%s decoration %s needs a readable primitive silhouette." % [profile.display_name, decoration_id])
			decoration.free()
	assert_eq(background_colors.size(), 6)


func test_shared_course_renderer_builds_all_required_visual_assets_for_every_biome() -> void:
	var profiles: Array = BiomeDatabase.get_profiles()
	for biome_index in range(profiles.size()):
		var holder := Node2D.new()
		add_child_autofree(holder)
		var builder = LevelBuilderScript.new()
		holder.add_child(builder)
		var level: Dictionary = HoleGenerator.generate_hole(profiles[biome_index], TEST_SEED, biome_index, 0)
		var level_root: Node2D = builder.build_level(level, holder)

		assert_not_null(level_root.get_node_or_null("BiomeBackground"))
		assert_not_null(level_root.get_node_or_null("BiomeBackgroundVariants"))
		assert_not_null(level_root.get_node_or_null("BiomeAmbience"))
		assert_not_null(level_root.get_node_or_null("Green"))
		assert_not_null(level_root.get_node_or_null("TeeStartMarker"))
		assert_not_null(level_root.get_node_or_null("PuttingGreen"))
		assert_not_null(level_root.get_node_or_null("FlagAsset"))
		assert_not_null(level_root.get_node_or_null("Hole"))
		assert_eq(_decoration_count(level_root), 8)


func test_hazards_use_shape_patterns_in_addition_to_color() -> void:
	var expected_pattern := {
		"sand": "SandGrain0",
		"rough": "RoughTuft0",
		"water": "WaterRipple0",
		"out": "WarningStripe0",
	}
	for hazard_type in expected_pattern:
		var visual := CourseVisualFactory.create_hazard_visual(
			hazard_type,
			Vector2(100.0, 100.0),
			Color("55734a"),
			Color("f4f0e6"),
			Color("252a2c")
		)
		assert_not_null(visual.get_node_or_null("HazardOutline"))
		assert_not_null(visual.get_node_or_null("HazardSurface"))
		assert_not_null(visual.get_node_or_null(expected_pattern[hazard_type]))
		visual.free()


func _decoration_count(level_root: Node2D) -> int:
	var count := 0
	for child in level_root.get_children():
		if child.name.begins_with("Decoration_"):
			count += 1
	return count
