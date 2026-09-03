extends GutTest

const BiomeAmbienceScript := preload("res://scripts/biome_ambience.gd")
const BiomeDatabaseScript := preload("res://scripts/biome_database.gd")
const CourseVisualFactoryScript := preload("res://scripts/course_visual_factory.gd")
const GameSettingsScript := preload("res://scripts/game_settings.gd")
const HoleGeneratorScript := preload("res://scripts/hole_generator.gd")
const HoleHistorySelectorScript := preload("res://scripts/ui/hole_history_selector.gd")
const HoleRatingScript := preload("res://scripts/hole_rating.gd")
const LevelBuilderScript := preload("res://scripts/level_builder.gd")
const SeedCodecScript := preload("res://scripts/seed_codec.gd")
const SettingsScreenScript := preload("res://scripts/ui/settings_screen.gd")


func test_hole_rating_boundaries_keep_strokes_primary_and_time_secondary() -> void:
	var expected := HoleRatingScript.expected_completion_seconds(4)
	var exceptional := HoleRatingScript.rate(2, 4, expected * 0.9)
	var fast_birdie := HoleRatingScript.rate(3, 4, expected * 0.7)
	var solid := HoleRatingScript.rate(5, 4, expected)
	var poor_but_fast := HoleRatingScript.rate(7, 4, expected * 0.2)
	var slow_eagle := HoleRatingScript.rate(2, 4, expected * 1.6)
	var forced := HoleRatingScript.rate(4, 4, expected * 0.2, true)

	assert_eq(exceptional.stars, 5)
	assert_eq(exceptional.golf_result, "EAGLE")
	assert_eq(fast_birdie.stars, 5)
	assert_eq(solid.stars, 3)
	assert_eq(poor_but_fast.stars, 1, "Fast play must not rescue a terrible stroke result.")
	assert_eq(slow_eagle.stars, 4, "Time may temper an elite stroke result without erasing it.")
	assert_eq(forced.stars, 1)
	assert_eq(forced.golf_result, "STROKE LIMIT")


func test_history_selector_exposes_played_holes_and_locks_future_holes() -> void:
	var selector = HoleHistorySelectorScript.new()
	add_child_autofree(selector)
	var history := [
		{"hole_number": 1, "biome_name": "Meadow", "strokes": 3, "par": 4, "stars": 5},
		{"hole_number": 2, "biome_name": "Meadow", "strokes": 5, "par": 4, "stars": 3},
	]
	selector.set_history(history, 2, 18)
	watch_signals(selector)

	assert_true(selector.can_select_hole(1))
	assert_true(selector.can_select_hole(2))
	assert_false(selector.can_select_hole(3))
	assert_false(selector.can_select_hole(18))
	assert_false(selector.select_hole(3))
	assert_true(selector.select_hole(1))
	assert_signal_emitted(selector, "selection_changed")
	assert_eq(selector.selected_hole, 1)
	selector.set_expanded(true)
	assert_true(selector.reel.visible)
	assert_gt(selector.custom_minimum_size.y, 200.0)


func test_settings_round_trip_and_screen_only_exposes_live_options() -> void:
	var save_path := "user://test_player_feedback_settings.cfg"
	var settings = GameSettingsScript.new()
	settings.fullscreen = true
	settings.resolution = Vector2i(1600, 900)
	settings.vsync_enabled = false
	settings.screen_shake_intensity = 0.35
	settings.visual_effects_intensity = 0.55
	settings.master_volume = 0.64
	settings.music_muted = true
	settings.shoot_keycode = KEY_ENTER
	settings.reset_keycode = KEY_BACKSPACE
	settings.aim_sensitivity = 1.45
	settings.trajectory_visible = false
	settings.reduced_motion = true
	assert_eq(settings.save_to(save_path), OK)

	var loaded = GameSettingsScript.new()
	assert_eq(loaded.load_from(save_path), OK)
	assert_true(loaded.fullscreen)
	assert_eq(loaded.resolution, Vector2i(1600, 900))
	assert_false(loaded.vsync_enabled)
	assert_almost_eq(loaded.screen_shake_intensity, 0.35, 0.001)
	assert_almost_eq(loaded.visual_effects_intensity, 0.55, 0.001)
	assert_almost_eq(loaded.master_volume, 0.64, 0.001)
	assert_true(loaded.music_muted)
	assert_eq(loaded.shoot_keycode, KEY_ENTER)
	assert_eq(loaded.reset_keycode, KEY_BACKSPACE)
	assert_almost_eq(loaded.aim_sensitivity, 1.45, 0.001)
	assert_false(loaded.trajectory_visible)
	assert_true(loaded.reduced_motion)

	var root := Node.new()
	add_child_autofree(root)
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	var screen = SettingsScreenScript.new()
	screen.setup(canvas, loaded)
	assert_eq(screen.tabs.get_tab_count(), 4)
	assert_not_null(screen.window_mode_option)
	assert_not_null(screen.master_slider)
	assert_not_null(screen.shoot_binding_button)
	assert_not_null(screen.trajectory_toggle)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func test_seed_input_validation_and_full_run_replay_are_deterministic() -> void:
	assert_false(SeedCodecScript.parse_seed("").valid)
	assert_false(SeedCodecScript.parse_seed("luck").valid)
	assert_false(SeedCodecScript.parse_seed("0").valid)
	assert_false(SeedCodecScript.parse_seed("2147483648").valid)
	var parsed := SeedCodecScript.parse_seed(" 486271 ")
	assert_true(parsed.valid)
	assert_eq(parsed.value, 486271)
	assert_eq(SeedCodecScript.format_seed(parsed.value), "486271")

	var profiles := BiomeDatabaseScript.get_profiles()
	var first := HoleGeneratorScript.generate_run(profiles, parsed.value)
	var repeated := HoleGeneratorScript.generate_run(profiles, parsed.value)
	assert_eq(first.size(), 18)
	assert_eq(repeated.size(), 18)
	for hole_index in range(first.size()):
		assert_eq(first[hole_index].map, repeated[hole_index].map)
		assert_eq(first[hole_index].hazards, repeated[hole_index].hazards)
		assert_eq(first[hole_index].obstacles, repeated[hole_index].obstacles)
		assert_eq(first[hole_index].moving_hazards, repeated[hole_index].moving_hazards)
		assert_eq(first[hole_index].quality_score, repeated[hole_index].quality_score)


func test_elevation_treatment_promotes_only_the_active_layer() -> void:
	var profiles := BiomeDatabaseScript.get_profiles()
	var level: Dictionary = {}
	for candidate in HoleGeneratorScript.generate_run(profiles, 486271):
		var has_nonzero_layer := false
		for entry in candidate.get("elevation_cells", []):
			for elevation in entry.get("levels", []):
				if int(elevation) != 0:
					has_nonzero_layer = true
		if has_nonzero_layer:
			level = candidate
			break
	assert_false(level.is_empty(), "The release run must include at least one discrete depth structure.")
	if level.is_empty():
		return
	var parent := Node2D.new()
	add_child_autofree(parent)
	var builder = LevelBuilderScript.new()
	parent.add_child(builder)
	var level_root: Node2D = builder.build_level(level, parent)
	assert_not_null(level_root)
	if level_root == null:
		return
	var base_surface := level_root.get_node_or_null("Green") as CanvasItem
	var raised_surface: CanvasItem = null
	for child in level_root.get_children():
		if child is CanvasItem and child.has_meta(&"elevation") and int(child.get_meta(&"elevation")) != 0:
			raised_surface = child as CanvasItem
			break
	assert_not_null(base_surface)
	assert_not_null(raised_surface, "Late generated holes should expose a non-zero visual elevation layer.")
	if base_surface == null or raised_surface == null:
		return
	var raised_elevation := int(raised_surface.get_meta(&"elevation"))
	builder.set_active_elevation(0)
	assert_eq(base_surface.self_modulate, Color.WHITE)
	assert_ne(raised_surface.self_modulate, Color.WHITE)
	builder.set_active_elevation(raised_elevation)
	assert_ne(base_surface.self_modulate, Color.WHITE)
	assert_eq(raised_surface.self_modulate, Color.WHITE)


func test_biome_surface_assets_and_ambience_follow_release_contract() -> void:
	for profile in BiomeDatabaseScript.get_profiles():
		assert_lt(Color(profile.terrain_palette.green).get_luminance(), Color(profile.terrain_palette.fairway_a).get_luminance())
	var putting_surface := CourseVisualFactoryScript.create_green_patch(Color("406b46"), Color("18251c"), 28.0)
	assert_not_null(putting_surface.get_node_or_null("BiomePuttingTile"))
	assert_null(putting_surface.get_node_or_null("GreenShadow"))
	putting_surface.free()
	var flag := CourseVisualFactoryScript.create_flag(Color.RED, Color.BLACK)
	assert_null(flag.get_node_or_null("FlagShadow"))
	assert_not_null(flag.get_node_or_null("Pole"))
	assert_not_null(flag.get_node_or_null("Flag"))
	flag.free()

	var ambience = BiomeAmbienceScript.new()
	add_child_autofree(ambience)
	ambience.configure(&"volcanic_rumble", Color("542d27"), Color("ff7138"), Vector2(1200, 800), Vector2(7600, 4600), 992)
	assert_eq(ambience.static_details.size(), BiomeAmbienceScript.STATIC_DETAIL_COUNT)
	assert_eq(ambience.particles.size(), BiomeAmbienceScript.PARTICLE_COUNT)
	assert_gte(ambience.surround_size.x, 7600.0)
	assert_gte(ambience.surround_size.y, 4600.0)
