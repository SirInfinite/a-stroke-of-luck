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
		assert_false(profile.hazard_weights.has("rough"), "Rough is presentation-only and must not remain in hazard weights.")
		assert_false(profile.hazard_weights.has("out"), "Legacy red penalty tiles must not remain in biome profiles.")
		assert_false(profile.terrain_palette.has("out"), "Legacy red penalty tile presentation must be removed.")
		for palette_key in ["fairway_a", "fairway_b", "fairway_detail", "green", "tee", "outline", "sand", "sand_detail", "rough", "rough_detail", "water", "water_detail", "ice", "ice_detail", "lava", "lava_detail", "direction", "direction_detail", "flag", "hazard_telegraph", "elevation_edge", "elevation_highlight"]:
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
		"ice": "IceCrack",
		"lava": "LavaFlow0",
	}
	for hazard_type in expected_pattern:
		var visual := CourseVisualFactory.create_hazard_visual(
			hazard_type,
			Vector2(100.0, 100.0),
			Color("55734a"),
			Color("f4f0e6"),
			Color("252a2c")
		)
		assert_null(visual.get_node_or_null("HazardOutline"), "Terrain hazards should not look like outlined game cards.")
		assert_not_null(visual.get_node_or_null("HazardEdgeShadow"))
		assert_not_null(visual.get_node_or_null("HazardSurface"))
		assert_not_null(visual.get_node_or_null(expected_pattern[hazard_type]))
		visual.free()
	var bounce_pad := CourseVisualFactory.create_hazard_visual(
		"bounce_pad",
		Vector2(84.0, 84.0),
		Color("824cc4"),
		Color("f4f0e6"),
		Color("252a2c")
	)
	assert_not_null(bounce_pad.get_node_or_null("BouncePadOuterRing"))
	assert_not_null(bounce_pad.get_node_or_null("BouncePadSurface"))
	assert_not_null(bounce_pad.get_node_or_null("BouncePadArrow0"))
	bounce_pad.free()


func test_snow_trajectory_style_uses_dark_foreground_and_backing() -> void:
	var snow_profile = BiomeDatabase.get_profiles()[3]
	var style := CourseVisualFactory.trajectory_style(snow_profile.terrain_palette, snow_profile.background_palette)
	var primary: Color = style.primary
	var backing: Color = style.backing
	assert_lt(primary.get_luminance(), 0.3)
	assert_gt(backing.get_luminance(), 0.7)
	assert_gt(float(style.minimum_contrast), 2.0)


func test_tee_flag_and_green_avoid_target_ring_language() -> void:
	var tee := CourseVisualFactory.create_start_marker(Color("8dcf63"), Color("252a2c"))
	assert_not_null(tee.get_node_or_null("TeeStem"))
	assert_not_null(tee.get_node_or_null("BallSeat"))
	tee.free()

	var green := CourseVisualFactory.create_green_patch(Color("8dcf63"), Color("252a2c"), 28.0)
	assert_null(green.get_node_or_null("GreenOutline"))
	assert_not_null(green.get_node_or_null("GreenShadow"))
	assert_not_null(green.get_node_or_null("GreenSurface"))
	green.free()

	var flag := CourseVisualFactory.create_flag(Color("d9534f"), Color("252a2c"))
	assert_not_null(flag.get_node_or_null("Pole"))
	assert_not_null(flag.get_node_or_null("Flag"))
	flag.free()


func test_depth_wall_and_moving_hazard_visual_contracts_are_readable() -> void:
	var wall := CourseVisualFactory.create_connected_wall_visual(
		Vector2(100.0, 30.0),
		Color("6f4a2f"),
		{"left": true, "right": true}
	)
	assert_not_null(wall.get_node_or_null("WallSurface"))
	assert_eq(wall.get_meta("connections").left, true)
	var wall_surface := wall.get_node("WallSurface") as Polygon2D
	assert_eq(wall_surface.polygon[0].x, -50.0, "Connected wall ends must stay square and continuous.")
	assert_eq(wall_surface.polygon[1].x, 50.0, "Connected wall ends must stay square and continuous.")
	wall.free()

	var raised := CourseVisualFactory.create_elevation_cell_visual(Vector2(100.0, 100.0), 1, Color("63b75d"), Color("252a2c"))
	assert_not_null(raised.get_node_or_null("RaisedShadow"))
	assert_eq(int(raised.get_meta("elevation")), 1)
	raised.free()

	var ramp := CourseVisualFactory.create_ramp_visual(Vector2(100.0, 100.0), 0, 1, Color("63b75d"), Color("252a2c"))
	assert_not_null(ramp.get_node_or_null("RampGrade0"))
	ramp.free()

	var bridge := CourseVisualFactory.create_bridge_visual(Vector2(180.0, 86.0), Color("63b75d"), Color("252a2c"))
	assert_not_null(bridge.get_node_or_null("BridgeShadow"))
	assert_not_null(bridge.get_node_or_null("BridgeRailTop"))
	bridge.free()

	var pit := CourseVisualFactory.create_pit_visual(Vector2(100.0, 100.0), Color("63b75d"), Color("252a2c"))
	assert_not_null(pit.get_node_or_null("PitDepth"))
	assert_not_null(pit.get_node_or_null("PitFloor"))
	pit.free()

	for hazard_type in [&"falling_ice", &"rotating_fire_rod", &"pendulum", &"fireball"]:
		var body := CourseVisualFactory.create_moving_hazard_visual(
			hazard_type,
			Vector2(100.0, 60.0),
			Color("d9534f"),
			Color("f4c95d")
		)
		assert_gt(body.get_child_count(), 1, "%s must have a distinct readable body silhouette." % hazard_type)
		body.free()
		var telegraph := CourseVisualFactory.create_hazard_telegraph(
			hazard_type,
			Vector2(100.0, 100.0),
			PackedVector2Array([Vector2(-50.0, 0.0), Vector2(50.0, 0.0)]),
			Color("d9534f")
		)
		assert_not_null(telegraph.get_node_or_null("MotionPath"))
		assert_gt(telegraph.get_child_count(), 1)
		telegraph.free()


func _decoration_count(level_root: Node2D) -> int:
	var count := 0
	for child in level_root.get_children():
		if child.name.begins_with("Decoration_"):
			count += 1
	return count
