extends GutTest

const BiomeDatabase := preload("res://scripts/biome_database.gd")
const CourseVisualFactory := preload("res://scripts/course_visual_factory.gd")
const HoleGenerator := preload("res://scripts/hole_generator.gd")
const LevelBuilderScript := preload("res://scripts/level_builder.gd")
const WorldArtScript := preload("res://scripts/presentation/world_art.gd")

const TEST_SEED := 24681357


func test_each_biome_has_a_complete_distinct_visual_profile() -> void:
	var profiles: Array = BiomeDatabase.get_profiles()
	var background_colors := {}
	for profile in profiles:
		assert_eq(profile.decoration_identifiers.size(), 4, "%s needs four reusable decoration assets." % profile.display_name)
		assert_false(profile.hazard_weights.has("rough"), "Rough is presentation-only and must not remain in hazard weights.")
		assert_false(profile.hazard_weights.has("out"), "Legacy red penalty tiles must not remain in biome profiles.")
		assert_false(profile.terrain_palette.has("out"), "Legacy red penalty tile presentation must be removed.")
		for palette_key in ["fairway_a", "fairway_b", "fairway_detail", "green", "green_a", "green_b", "green_detail", "tee", "outline", "sand", "sand_detail", "rough", "rough_detail", "water", "water_detail", "ice", "ice_detail", "lava", "lava_detail", "direction", "direction_detail", "flag", "hazard_telegraph", "elevation_edge", "elevation_highlight"]:
			assert_true(profile.terrain_palette.has(palette_key), "%s is missing terrain color %s." % [profile.display_name, palette_key])
		assert_ne(profile.terrain_palette.green_a, profile.terrain_palette.green_b, "%s putting tiles must retain checker variation." % profile.display_name)
		assert_ne(profile.terrain_palette.green_a, profile.terrain_palette.fairway_a, "%s needs a biome-local putting treatment." % profile.display_name)
		assert_ne(profile.terrain_palette.green_b, profile.terrain_palette.fairway_b, "%s needs a second biome-local putting treatment." % profile.display_name)
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
			var illustration := decoration.get_node_or_null("Illustration") as Sprite2D
			assert_not_null(illustration, "%s decoration %s needs its illustrated object." % [profile.display_name, decoration_id])
			_assert_original_sprite(illustration, true)
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
		assert_null(level_root.get_node_or_null("PuttingSurface"), "Putting color must come from course cells, never an overlay.")
		assert_not_null(level_root.get_node_or_null("FlagAsset"))
		assert_not_null(level_root.get_node_or_null("Hole"))
		assert_eq(_decoration_count(level_root), 0, "Ambience owns biome scenery without a second generic scatter")
		var ambience := level_root.get_node("BiomeAmbience") as BiomeAmbience
		assert_eq(ambience.landscape.size(), BiomeAmbience.LANDSCAPE_GROUPS)
		assert_gt(ambience.static_details.size(), 0)
		assert_eq(ambience.course_cells.size(), builder._playable_cells(level).size(), "Scenery banks follow the actual course footprint.")
		for detail in ambience.static_details:
			var on_painted_bank := false
			var on_playable_floor := false
			for cell: Rect2 in ambience.course_cells:
				on_painted_bank = on_painted_bank or cell.grow(BiomeAmbience.BANK_WIDTH).has_point(detail.position)
				on_playable_floor = on_playable_floor or cell.has_point(detail.position)
			assert_true(on_painted_bank, "Nearby scenery needs painted ground beneath its fixed contact point.")
			assert_false(on_playable_floor, "Decorative roots must stay outside reachable course cells.")
		var distance := level_root.get_node("BiomeBackgroundVariants").get_child(0) as CanvasItem
		assert_gt(_effective_z(distance), _effective_z(level_root.get_node("BiomeBackground")), "The distant art must draw above the opaque fallback, not be hidden behind it.")
		assert_true(ResourceLoader.exists(WorldArtScript.background_path(profiles[biome_index].id)))

		var floor := level_root.get_node("Green") as StaticBody2D
		var putting_colors := {}
		var putting_tile_count := 0
		var unchanged_fairway_checked := false
		for child in floor.get_children():
			if not child is Sprite2D or not child.has_meta(&"cell"):
				continue
			var tile := child as Sprite2D
			var checker_variant := int(tile.get_meta(&"checker_variant"))
			assert_eq(tile.texture.get_size() * tile.scale, Vector2(100, 100), "Pixel art must preserve the native square cell extent.")
			assert_eq(tile.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
			if bool(tile.get_meta(&"putting_surface")):
				putting_tile_count += 1
				putting_colors[tile.texture.resource_path] = true
				var putting_key := "green_a" if checker_variant == 0 else "green_b"
				assert_eq(tile.get_meta(&"surface_color"), Color(profiles[biome_index].terrain_palette[putting_key]))
				assert_true(tile.texture.resource_path.ends_with("%s_%s_quiet.png" % [profiles[biome_index].id, putting_key]), "Putting cells must use the darker version of this biome's own material family.")
			elif not unchanged_fairway_checked:
				var fairway_key := "fairway_a" if checker_variant == 0 else "fairway_b"
				assert_eq(tile.get_meta(&"surface_color"), Color(profiles[biome_index].terrain_palette[fairway_key]))
				assert_true(tile.texture.resource_path.contains("%s_%s" % [profiles[biome_index].id, fairway_key]))
				unchanged_fairway_checked = true
		assert_eq(putting_tile_count, builder.get_putting_region_cells().size())
		assert_gte(putting_tile_count, 2)
		assert_gte(putting_colors.size(), 2, "Putting region must preserve the underlying A/B checker pattern.")
		assert_true(unchanged_fairway_checked)


func test_hazards_use_illustrated_materials_and_preserve_surface_footprints() -> void:
	for hazard_type in ["sand", "rough", "water", "ice", "lava"]:
		var visual := CourseVisualFactory.create_hazard_visual(
			hazard_type,
			Vector2(100.0, 100.0),
			Color("55734a"),
			Color("f4f0e6"),
			Color("252a2c")
		)
		assert_null(visual.get_node_or_null("HazardOutline"), "Terrain hazards should not look like outlined game cards.")
		if hazard_type == "rough":
			assert_null(visual.get_node_or_null("HazardSurface"), "Cosmetic grass must not imitate a hazardous tile.")
			assert_null(visual.get_node_or_null("HazardEdgeShadow"))
			_assert_original_sprite(visual.get_node("RoughTuft0"), true)
		else:
			var surface = visual.get_node("HazardSurface")
			assert_eq(surface.kind, hazard_type)
			assert_eq(surface.dimensions, Vector2(100, 100))
			_assert_original_sprite(surface.body, false)
			assert_true(surface.body.region_enabled)
			assert_true((surface.body.region_rect.size * surface.body.scale).is_equal_approx(Vector2(100, 100)), "Full-tile terrain must still cover its physical area.")
			assert_gt(_unique_opaque_colors(surface.body.texture.get_image()), 1, "Material identity must include illustrated highlights or clusters, not color alone.")
		assert_eq(visual.get_meta(&"visual_footprint"), Vector2(100, 100))
		visual.free()
	var bounce_pad := CourseVisualFactory.create_hazard_visual(
		"bounce_pad",
		Vector2(84.0, 84.0),
		Color("824cc4"),
		Color("f4f0e6"),
		Color("252a2c")
	)
	var bounce_surface = bounce_pad.get_node("HazardSurface")
	assert_eq(bounce_surface.kind, "bounce_pad")
	assert_eq(bounce_surface.body.texture.get_size() * bounce_surface.body.scale, Vector2(84, 84))
	_assert_original_sprite(bounce_surface.body, true)
	var pad_colors: Image = bounce_surface.body.texture.get_image()
	var yellow_count := 0
	for y in pad_colors.get_height():
		for x in pad_colors.get_width():
			var color := pad_colors.get_pixel(x, y)
			if color.a > 0.9 and color.r > 0.6 and color.g > 0.4 and color.b < color.g * 0.75:
				yellow_count += 1
	assert_gt(yellow_count, 30, "Launch pads retain a substantial yellow mechanical face.")
	bounce_pad.free()


func test_snow_trajectory_style_uses_dark_foreground_and_backing() -> void:
	var snow_profile = BiomeDatabase.get_profiles()[3]
	var style := CourseVisualFactory.trajectory_style(snow_profile.terrain_palette, snow_profile.background_palette)
	var primary: Color = style.primary
	var backing: Color = style.backing
	assert_lt(primary.get_luminance(), 0.3)
	assert_gt(backing.get_luminance(), 0.7)
	assert_gt(float(style.minimum_contrast), 2.0)


func test_tee_and_flag_avoid_target_ring_or_surface_patch_language() -> void:
	var tee := CourseVisualFactory.create_start_marker(Color("8dcf63"), Color("252a2c"))
	assert_not_null(tee.get_node_or_null("TeeStem"))
	assert_not_null(tee.get_node_or_null("BallSeat"))
	var tee_sprite := tee.get_node("TeeStem") as Sprite2D
	_assert_original_sprite(tee_sprite, true)
	assert_eq(tee_sprite.texture.get_size(), Vector2(11, 16), "The export contains one measured half of the original paired tee sheet.")
	assert_eq(tee_sprite.position + Vector2(5.5, 3) * tee_sprite.scale, Vector2.ZERO, "The illustrated seat must center on the authoritative ball origin.")
	assert_eq(tee.get_meta(&"tee_art_count"), 1)
	assert_eq(tee.get_node("BallSeat").position, Vector2.ZERO)
	tee.free()

	var flag := CourseVisualFactory.create_flag(Color("d9534f"), Color("252a2c"))
	add_child_autofree(flag)
	assert_null(flag.get_node_or_null("FlagShadow"))
	assert_not_null(flag.get_node_or_null("Pole"))
	assert_not_null(flag.get_node_or_null("Flag"))
	_assert_original_sprite(flag.get_node("Flag"), true)
	assert_eq((flag.get_node("Flag") as Sprite2D).texture.get_height(), 35, "Flag art excludes the baked cup; LevelBuilder owns the sole cup.")
	for frame in ["a", "b"]:
		var image := WorldArtScript.texture("objects/flag_" + frame).get_image()
		var cup_edge := image.get_region(Rect2i(8, 34, image.get_width() - 8, 1))
		assert_eq(cup_edge.get_used_rect().get_area(), 0, "Neither flag pose may retain a baked cup edge beside its pole.")


func test_depth_wall_and_moving_hazard_visual_contracts_are_readable() -> void:
	var wall := CourseVisualFactory.create_connected_wall_visual(
		Vector2(100.0, 30.0),
		Color("6f4a2f"),
		{"left": true, "right": true}
	)
	assert_not_null(wall.get_node_or_null("WallSurface"))
	assert_eq(wall.get_meta("connections").left, true)
	var wall_surface = wall.get_node("WallSurface")
	assert_eq(wall_surface.dimensions, Vector2(100, 30))
	assert_true((wall_surface.image_sprite.region_rect.size * wall_surface.image_sprite.scale).is_equal_approx(Vector2(100, 30)), "Wall caps must retain the exact rectangular collider extent.")
	assert_eq(wall_surface.image_sprite.position, Vector2.ZERO)
	_assert_original_sprite(wall_surface.image_sprite, false)
	wall.free()

	var raised := CourseVisualFactory.create_elevation_cell_visual(Vector2(100.0, 100.0), 1, Color("63b75d"), Color("252a2c"))
	assert_not_null(raised.get_node_or_null("RaisedShadow"))
	assert_eq(int(raised.get_meta("elevation")), 1)
	assert_eq((raised.get_node("ElevationSurface") as Sprite2D).texture.get_size() * raised.get_node("ElevationSurface").scale, Vector2(100, 100))
	raised.free()

	var ramp := CourseVisualFactory.create_ramp_visual(Vector2(100.0, 100.0), 0, 1, Color("63b75d"), Color("252a2c"))
	assert_not_null(ramp.get_node_or_null("RampGrade0"))
	ramp.free()

	var bridge := CourseVisualFactory.create_bridge_visual(Vector2(180.0, 86.0), Color("63b75d"), Color("252a2c"))
	assert_not_null(bridge.get_node_or_null("BridgeShadow"))
	assert_not_null(bridge.get_node_or_null("BridgeRailTop"))
	bridge.free()

	var lower_course := CourseVisualFactory.create_lower_course_visual(Vector2(100.0, 100.0), Color("63b75d"), Color("252a2c"))
	assert_not_null(lower_course.get_node_or_null("LowerCourseEdge"))
	assert_not_null(lower_course.get_node_or_null("LowerCourseSurface"))
	assert_not_null(lower_course.get_node_or_null("UpperWallShadow"))
	var lower_surface := lower_course.get_node("LowerCourseSurface") as Sprite2D
	assert_true(lower_surface.texture.resource_path.contains("meadow_fairway_"), "Lower areas remain the normal biome material, not a pit or missing floor.")
	assert_eq(lower_surface.texture.get_size() * lower_surface.scale, Vector2(100, 100))
	lower_course.free()

	for hazard_type in [&"falling_ice", &"rotating_fire_rod", &"pendulum", &"fireball"]:
		var body := CourseVisualFactory.create_moving_hazard_visual(
			hazard_type,
			Vector2(100.0, 60.0),
			Color("d9534f"),
			Color("f4c95d")
		)
		assert_gt(body.get_child_count(), 1, "%s must have a distinct readable body silhouette." % hazard_type)
		_assert_original_sprite(body.get_child(0), hazard_type != &"fireball")
		var footprint := Vector2(100, 100) if hazard_type == &"falling_ice" else Vector2(100, 60)
		assert_true((body.get_child(0).texture.get_size() * body.get_child(0).scale).is_equal_approx(footprint), "Danger artwork must match the native hazard footprint.")
		assert_eq(body.get_node("ContactCenter").position, Vector2.ZERO)
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


func test_quiet_and_detailed_tiles_share_the_same_material_value() -> void:
	for biome in WorldArtScript.BIOMES:
		for material in ["fairway", "green"]:
			for variant in ["a", "b"]:
				var prefix := "terrain/%s_%s_%s" % [biome, material, variant]
				var quiet := WorldArtScript.texture(prefix + "_quiet").get_image()
				var detailed := WorldArtScript.texture(prefix).get_image()
				var same := 0
				for y in quiet.get_height():
					for x in quiet.get_width():
						if quiet.get_pixel(x, y).is_equal_approx(detailed.get_pixel(x, y)): same += 1
				assert_gt(float(same) / (quiet.get_width() * quiet.get_height()), 0.95, "A selected detail cluster must not recolor the entire %s tile." % prefix)


func test_native_pause_and_reduced_motion_freeze_decorative_clocks() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	var builder = LevelBuilderScript.new()
	holder.add_child(builder)
	var level: Dictionary = HoleGenerator.generate_hole(BiomeDatabase.get_profiles()[0], TEST_SEED, 0, 0)
	var level_root: Node2D = builder.build_level(level, holder)
	await get_tree().process_frame
	var ambience := level_root.get_node("BiomeAmbience") as BiomeAmbience
	var flag = level_root.get_node("FlagAsset")
	var anchors := ambience.static_details.duplicate(true)
	var original_transform := ambience.global_transform
	builder.set_gameplay_simulation_paused(true)
	var flag_time: float = flag.elapsed
	var ambience_time := ambience.elapsed
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(flag.elapsed, flag_time, "Pause freezes the flag's decorative clock.")
	assert_eq(ambience.elapsed, ambience_time, "Pause freezes ambient particles.")
	builder.set_gameplay_simulation_paused(false)
	holder.set_meta(&"reduced_motion", true)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(flag.elapsed, flag_time, "Reduced motion freezes flag frames independently of simulation.")
	assert_eq(ambience.elapsed, ambience_time)
	assert_eq(ambience.static_details, anchors)
	assert_eq(ambience.global_transform, original_transform, "Decorative motion never relocates nearby scenery.")


func _assert_original_sprite(sprite: Sprite2D, transparent: bool) -> void:
	assert_not_null(sprite)
	if not sprite: return
	assert_not_null(sprite.texture)
	if not sprite.texture: return
	assert_true(sprite.texture.resource_path.begins_with("res://assets/world/"), "Normal production uses production assets, never analysis or sample paths.")
	assert_eq(sprite.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	var image := sprite.texture.get_image()
	assert_gt(image.get_used_rect().get_area(), 0)
	if transparent: assert_true(image.detect_alpha() != Image.ALPHA_NONE, "Illustrated objects need clean transparent silhouettes.")


func _unique_opaque_colors(image: Image) -> int:
	var colors := {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a > 0.9: colors[color] = true
	return colors.size()


func _effective_z(item: CanvasItem) -> int:
	var value := item.z_index
	if item.z_as_relative and item.get_parent() is CanvasItem:
		value += _effective_z(item.get_parent())
	return value


func _decoration_count(level_root: Node2D) -> int:
	var count := 0
	for child in level_root.get_children():
		if child.name.begins_with("Decoration_"):
			count += 1
	return count
