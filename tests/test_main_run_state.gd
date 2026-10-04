extends GutTest

const MAIN_SCENE := preload("res://scenes/main.tscn")
const CardDatabase := preload("res://scripts/card_database.gd")
const DifficultyDatabase := preload("res://scripts/difficulty_database.gd")
const LevelValidator := preload("res://scripts/level_validator.gd")
const MovingHazardScript := preload("res://scripts/moving_hazard.gd")
const TEST_SEED := 424242


func test_starting_normal_run_builds_clean_eighteen_hole_contract() -> void:
	var main = _spawn_main_menu()
	main.run_state.level_index = 3
	main.run_state.strokes = 4
	main.run_state.total_strokes = 11
	main.run_state.tokens = 9
	main.run_state.level_elapsed = 42.5
	main.run_state.reward_bonus = 2
	main.run_state.owned_cards.append("Lucky Putter")
	main.run_stats.record_stroke()
	main.run_stats.update_time(42.5)

	main._start_normal_run(TEST_SEED)
	main.set_process(false)

	assert_eq(main.get_run_phase_name(), "RUN_START")
	assert_eq(main.run_state.run_seed, TEST_SEED)
	assert_eq(main.run_state.levels.size(), 18)
	assert_eq(main.biome_profiles.size(), 6)
	assert_eq(main.run_state.level_index, 0)
	assert_eq(main.run_state.biome_index, 0)
	assert_eq(main.run_state.hole_index, 0)
	assert_eq(main.run_state.overall_hole_number, 1)
	assert_eq(main.run_state.strokes, 0)
	assert_eq(main.run_state.total_strokes, 0)
	assert_eq(main.run_state.tokens, 2)
	assert_eq(main.run_state.level_elapsed, 0.0)
	assert_eq(main.run_state.reward_bonus, 0)
	assert_true(main.run_state.owned_cards.is_empty())
	assert_true(main.run_state.owned_card_definitions.is_empty())
	assert_true(main.run_state.active_card_curses.is_empty())
	assert_almost_eq(main.run_state.roll_damp_modifier, 1.0, 0.001)
	assert_almost_eq(main.run_state.cup_radius_scale, 1.0, 0.001)
	assert_eq(main.run_stats.total_strokes, 0)
	assert_eq(main.run_stats.total_run_time, 0.0)


func test_accepted_shot_increments_current_stroke_totals_once() -> void:
	var main = _spawn_playing_main()

	main.ball.shot_started.emit(Vector2.ZERO, Vector2.RIGHT, 0.5)
	main.ball.shot_finished.emit()

	assert_eq(main.run_state.strokes, 1)
	assert_eq(main.run_state.total_strokes, 1)
	assert_eq(main.run_stats.total_strokes, 1)


func test_hole_completion_awards_results_and_advances_once() -> void:
	var main = _spawn_playing_main()
	main.ball.sink_animation_duration = 0.0
	main.feedback_director.completion_pause_duration = 0.0

	main.level_builder.hole_body_entered.emit(main.ball)
	main.level_builder.hole_body_entered.emit(main.ball)

	assert_true(main.loading_next_level)
	assert_eq(main.run_state.level_index, 0)

	var sink_finished: bool = await wait_for_signal(main.ball.sink_animation_finished, 1.0)
	assert_true(sink_finished)
	await wait_process_frames(1)

	assert_eq(main.get_run_phase_name(), "HOLE_RESULTS")
	assert_eq(main.run_state.tokens, 5)
	assert_eq(main.run_state.level_index, 0)
	main.interstitial_continue_button.pressed.emit()
	await wait_process_frames(1)

	assert_eq(main.get_run_phase_name(), "HOLE_PLAY")
	assert_eq(main.run_state.level_index, 1)
	assert_eq(main.run_state.biome_index, 0)
	assert_eq(main.run_state.hole_index, 1)
	assert_eq(main.run_state.overall_hole_number, 2)
	assert_eq(main.run_state.tokens, 5)


func test_manual_current_hole_reset_preserves_cumulative_run_state() -> void:
	var main = _spawn_playing_main()
	main._load_level(2)
	main.run_state.tokens = 7
	main.ball.shot_started.emit(Vector2.ZERO, Vector2.RIGHT, 0.5)
	main.run_state.level_elapsed = 8.5

	main._reset_current_level()

	assert_eq(main.run_state.strokes, 1)
	assert_eq(main.run_state.level_elapsed, 8.5)
	assert_eq(main.run_state.total_strokes, 1)
	assert_eq(main.run_stats.total_strokes, 1)
	assert_eq(main.run_stats.manual_resets, 1)
	assert_eq(main.run_state.level_index, 2)
	assert_eq(main.run_state.biome_index, 0)
	assert_eq(main.run_state.hole_index, 2)
	assert_eq(main.run_state.overall_hole_number, 3)
	assert_eq(main.run_state.tokens, 7)


func test_run_timing_accumulates_only_during_hole_play() -> void:
	var main = _spawn_normal_main()

	main._process(1.25)
	assert_eq(main.run_state.level_elapsed, 0.0)
	assert_eq(main.run_stats.total_run_time, 0.0)

	main._on_interstitial_continue_pressed()
	main._process(1.25)
	assert_eq(main.run_state.level_elapsed, 0.0)
	assert_eq(main.run_stats.total_run_time, 0.0)

	main._on_interstitial_continue_pressed()
	main._process(1.25)
	assert_eq(main.run_state.level_elapsed, 1.25)
	assert_eq(main.run_stats.total_run_time, 1.25)

	main._set_run_phase(main.RunPhase.HOLE_RESOLVING)
	main._process(2.0)
	assert_eq(main.run_state.level_elapsed, 1.25)
	assert_eq(main.run_stats.total_run_time, 1.25)


func test_stroke_ceiling_forces_results_instead_of_softlocking() -> void:
	var main = _spawn_playing_main()
	var par: int = main.run_state.levels[main.run_state.level_index].par
	main.run_state.strokes = par + 3
	main.run_state.total_strokes = main.run_state.strokes
	main.run_stats.total_strokes = main.run_state.strokes

	main.ball.shot_started.emit(Vector2.ZERO, Vector2.RIGHT, 0.5)
	main.ball.shot_finished.emit()

	assert_eq(main.run_state.strokes, par + 4)
	assert_eq(main.get_run_phase_name(), "HOLE_RESULTS")
	assert_true(main.run_state.last_hole_forced)


func test_normal_shop_accepts_at_most_three_distinct_purchases() -> void:
	var main = _spawn_playing_main()
	main._load_level(2)
	main.run_state.tokens = 20
	main._complete_current_hole(false, false)
	main._on_interstitial_continue_pressed()
	assert_eq(main.get_run_phase_name(), "SHOP")

	main.shop_manager._on_shop_card_pressed(0)
	var tokens_after_first: int = main.run_state.tokens
	main.shop_manager._on_shop_card_pressed(0)
	assert_eq(main.run_state.tokens, tokens_after_first)
	assert_eq(main.shop_manager.purchases_this_visit, 1)

	main.shop_manager._on_shop_card_pressed(1)
	main.shop_manager._on_shop_card_pressed(2)
	var tokens_after_third: int = main.run_state.tokens
	main.shop_manager._on_shop_card_pressed(3)
	assert_eq(main.run_state.tokens, tokens_after_third)
	assert_eq(main.shop_manager.purchases_this_visit, 3)
	assert_eq(main.run_state.owned_cards.size(), 3)
	assert_eq(main.run_state.active_card_curses.size(), 3)


func test_card_bonus_persists_after_its_curse_expires_in_three_holes() -> void:
	var main = _spawn_playing_main()
	main._apply_card(_card_by_name("Coin Magnet"))

	assert_eq(main.run_state.reward_bonus, 1)
	assert_almost_eq(main.run_state.cup_radius_scale, 0.85, 0.001)
	assert_eq(main.run_state.trajectory_dot_bonus, 0)
	assert_eq(main.run_state.active_card_curses[0].remaining_holes, 3)
	main._update_status()
	assert_true(main.effects_status_label.text.contains("Coin Magnet (3 holes)"))

	for expected_remaining in [2, 1, 0]:
		main._complete_current_hole(false, false)
		assert_eq(main.get_run_phase_name(), "HOLE_RESULTS")
		if expected_remaining > 0:
			assert_eq(main.run_state.active_card_curses[0].remaining_holes, expected_remaining)
			main._on_interstitial_continue_pressed()
		else:
			assert_true(main.run_state.active_card_curses.is_empty())

	assert_eq(main.run_state.reward_bonus, 1)
	assert_eq(main.run_state.trajectory_dot_bonus, 0)
	assert_almost_eq(main.run_state.cup_radius_scale, 1.0, 0.001)
	assert_eq(main.run_state.owned_cards, ["Coin Magnet"])
	main._update_status()
	assert_true(main.effects_status_label.text.contains("Active curses: None"))


func test_generation_curse_adds_a_deterministic_valid_hazard_to_next_biome() -> void:
	var main = _spawn_playing_main()
	main._apply_card(_card_by_name("Power Club"))
	var base_hazard_count: int = main.run_state.normal_levels[3].hazards.size()

	main._load_level(3)
	var modified_level: Dictionary = main.run_state.levels[3]

	assert_eq(int(modified_level.card_hazard_count), 1)
	assert_eq(modified_level.hazards.size(), base_hazard_count + 1)
	assert_true(LevelValidator.validate_level(modified_level, 3))
	assert_eq(String(modified_level.hazards[-1].type), "direction")


func test_lucky_putter_uses_birdie_risk_reward_and_temporary_small_cup() -> void:
	var main = _spawn_playing_main()
	main._apply_card(_card_by_name("Lucky Putter"))
	var base_cup_radius := float(main.run_state.normal_levels[3].cup_radius)

	main._load_level(3)

	assert_almost_eq(float(main.run_state.levels[3].cup_radius), base_cup_radius * 0.6875, 0.001)
	assert_eq(main._token_reward_for_score(2, 3), 5)
	assert_eq(main._token_reward_for_score(3, 3), 2)


func test_rangefinder_improves_control_with_temporary_shot_power_curse() -> void:
	var main = _spawn_playing_main()
	main._apply_card(_card_by_name("Rangefinder Lens"))

	assert_eq(main.run_state.trajectory_dot_bonus, 0)
	assert_almost_eq(main.run_state.drag_modifier, 1.12, 0.001)
	assert_almost_eq(main.run_state.impulse_modifier, 0.875, 0.001)
	assert_null(main.ball.get_node_or_null("TrajectoryPreview"))


func test_roll_control_terrain_and_direction_effects_reach_gameplay_values() -> void:
	var main = _spawn_playing_main()
	var base_roll_damp: float = main.ball.base_linear_damp

	main._apply_card(_card_by_name("Heavy Core"))
	main._apply_card(_card_by_name("Sand Cleats"))
	main._apply_card(_card_by_name("Overdrive Driver"))
	main._apply_card(_card_by_name("Gust Guard"))

	assert_almost_eq(main.normal_ball_linear_damp, base_roll_damp * 0.8, 0.001)
	assert_almost_eq(main.run_state.impulse_modifier, 1.25, 0.001)
	assert_almost_eq(main.run_state.drag_modifier, 0.8125, 0.001)
	assert_almost_eq(main.run_state.terrain_mitigation_modifier, 0.1625, 0.001)
	assert_almost_eq(main.run_state.direction_push_modifier, 0.8125, 0.001)
	assert_eq(main.run_state.active_hazard_count_modifier, 1)
	assert_gt(main._terrain_entry_speed_scale(main.SAND_ENTRY_SPEED_SCALE), main.SAND_ENTRY_SPEED_SCALE)


func test_stacked_card_curses_expire_together_without_removing_bonuses() -> void:
	var main = _spawn_playing_main()
	var overdrive := _card_by_name("Overdrive Driver")
	main._apply_card(overdrive)
	main._apply_card(overdrive)

	assert_almost_eq(main.run_state.impulse_modifier, 1.5, 0.001)
	assert_almost_eq(main.run_state.drag_modifier, 0.625, 0.001)
	for _hole_index in range(3):
		main._advance_active_curses()

	assert_true(main.run_state.active_card_curses.is_empty())
	assert_almost_eq(main.run_state.impulse_modifier, 1.5, 0.001)
	assert_almost_eq(main.run_state.drag_modifier, 1.0, 0.001)


func test_full_economy_smoke_buys_two_cards_in_all_five_shops() -> void:
	var main = _spawn_playing_main()
	var shop_visits := 0

	for expected_hole in range(1, 19):
		assert_eq(main.run_state.overall_hole_number, expected_hole)
		assert_eq(main.get_run_phase_name(), "HOLE_PLAY")
		main._complete_current_hole(false, false)
		for curse in main.run_state.active_card_curses:
			assert_gt(curse.remaining_holes, 0, "Only unexpired rarity-duration curses persist")
		main._on_interstitial_continue_pressed()

		if expected_hole < 18 and expected_hole % 3 == 0:
			shop_visits += 1
			assert_eq(main.get_run_phase_name(), "SHOP")
			assert_eq(main.shop_manager.current_shop_cards.size(), 5)
			var first_price: int = main.shop_manager.current_shop_cards[0].price
			var second_price: int = main.shop_manager.current_shop_cards[1].price
			var coins_before: int = main.run_state.tokens
			var curses_before: int = main.run_state.active_card_curses.size()
			main.shop_manager._on_shop_card_pressed(0)
			main.shop_manager._on_shop_card_pressed(1)
			assert_eq(main.run_state.tokens, coins_before - first_price - second_price)
			assert_eq(main.shop_manager.purchases_this_visit, 2)
			assert_eq(main.run_state.active_card_curses.size(), curses_before + 2)
			main.shop_manager._on_shop_continue_pressed()
			assert_eq(main.get_run_phase_name(), "BIOME_INTRO")
			main._on_interstitial_continue_pressed()

	assert_eq(shop_visits, 5)
	assert_eq(main.run_state.owned_cards.size(), 10)
	for curse in main.run_state.active_card_curses:
		assert_true(curse.card.rarity in [&"epic", &"legendary"])
	assert_eq(main.get_run_phase_name(), "RUN_RESULTS")


func test_full_eighteen_hole_smoke_visits_every_runtime_state_and_resets() -> void:
	var main = _spawn_main_menu()
	var seen_states := {main.get_run_phase_name(): true}
	assert_true(main.main_menu_overlay.visible)
	assert_eq(main.main_menu_overlay.name, "MainMenuScreen")
	assert_eq(main.main_menu_logo.accessibility_name, "A STROKE OF LUCK")
	assert_eq(main.main_menu_title_label.text, "A STROKE OF LUCK")
	assert_not_null(main.menu_settings_button)
	assert_false(main.score_label.visible)
	main.menu_play_button.pressed.emit()
	assert_eq(main.vs_controller.view.page_id, &"mode_select")
	main.vs_controller.view.mode_selected.emit(false)
	assert_true(main.run_setup_screen.visible)
	assert_eq(main.get_run_phase_name(), "MAIN_MENU")
	main.run_setup_screen.settings = null
	main.run_setup_screen.seed_input.text = str(TEST_SEED)
	main.run_setup_screen._on_start_pressed()
	seen_states[main.get_run_phase_name()] = true
	assert_eq(main.get_run_phase_name(), "RUN_START")
	assert_true(main.interstitial_overlay.visible)
	assert_eq(main.interstitial_title_label.text, "TEE OFF")
	assert_true(main.transition_presentation.eyebrow_label.text.contains("COURSE IS DEALT"))
	assert_eq(main.interstitial_continue_button.text, "BEGIN COURSE")
	main.interstitial_continue_button.pressed.emit()
	seen_states[main.get_run_phase_name()] = true
	assert_eq(main.get_run_phase_name(), "BIOME_INTRO")
	assert_eq(main.interstitial_title_label.text, "MEADOW")
	assert_true(main.interstitial_body_label.text.contains("HOLES 01 — 03"))
	assert_eq(main.interstitial_continue_button.text, "PLAY HOLE 01")
	main.interstitial_continue_button.pressed.emit()
	seen_states[main.get_run_phase_name()] = true

	var shop_visits := 0
	for expected_hole in range(1, 19):
		assert_eq(main.get_run_phase_name(), "HOLE_PLAY", "Hole %d must begin in HOLE_PLAY." % expected_hole)
		assert_eq(main.run_state.overall_hole_number, expected_hole)
		assert_eq(main.run_state.biome_index, (expected_hole - 1) / 3)
		assert_eq(main.run_state.hole_index, (expected_hole - 1) % 3)
		assert_eq(int(main.run_state.levels[main.run_state.level_index].overall_hole_number), expected_hole)
		assert_eq(int(main.run_state.levels[main.run_state.level_index].biome_index), main.run_state.biome_index)
		assert_eq(int(main.run_state.levels[main.run_state.level_index].hole_index), main.run_state.hole_index)
		assert_false(main.score_label.visible)
		assert_true(main.release_hud.visible)
		assert_true(main.power_meter.visible)
		assert_false(main.interstitial_overlay.visible)
		assert_eq(main.release_hud.biome_label.text, String(main.run_state.levels[main.run_state.level_index].biome_name).to_upper())
		assert_true(main.release_hud.hole_label.text.contains("%02d / 18" % expected_hole))
		assert_eq(main.release_hud.timer_label.text, "00:00")

		main._complete_current_hole(false, false)
		seen_states[main.get_run_phase_name()] = true
		assert_eq(main.get_run_phase_name(), "HOLE_RESULTS")
		assert_false(main.score_label.visible)
		assert_eq(main.interstitial_title_label.text, String(main.run_state.last_hole_rating.golf_result))
		assert_eq(main.interstitial_body_label.text, "", "No filler or debug-like status copy should appear without a real curse event.")
		assert_true(main.transition_presentation.eyebrow_label.text.contains("HOLE %02d / 18" % expected_hole))
		main.interstitial_continue_button.pressed.emit()
		seen_states[main.get_run_phase_name()] = true

		if expected_hole < 18 and expected_hole % 3 == 0:
			assert_eq(main.get_run_phase_name(), "SHOP")
			shop_visits += 1
			assert_true(main.shop_manager.shop_overlay.visible)
			assert_eq(main.shop_manager.shop_title_label.text, "THE LUCKY CLUBHOUSE")
			assert_true(main.shop_manager.shop_destination_label.text.contains("Biome %d/6" % (shop_visits + 1)))
			assert_true(main.shop_manager.shop_destination_label.text.contains("overall %d/18" % (expected_hole + 1)))
			assert_false(main.shop_manager.continue_button.disabled)
			main.shop_manager.continue_button.pressed.emit()
			seen_states[main.get_run_phase_name()] = true
			assert_eq(main.get_run_phase_name(), "BIOME_INTRO")
			assert_eq(main.transition_presentation.eyebrow_label.text, "BIOME %02d / 06" % (shop_visits + 1))
			assert_eq(main.interstitial_continue_button.text, "PLAY HOLE %02d" % (expected_hole + 1))
			main.interstitial_continue_button.pressed.emit()
			seen_states[main.get_run_phase_name()] = true

	assert_eq(shop_visits, 5)
	assert_eq(main.get_run_phase_name(), "RUN_RESULTS")
	assert_eq(main.interstitial_title_label.text, "COURSE COMPLETE")
	assert_true(main.interstitial_body_label.text.contains("The score is yours"))
	assert_true(main.interstitial_menu_button.visible)
	assert_eq(main.interstitial_continue_button.text, "SEE ENDING")
	main.interstitial_continue_button.pressed.emit()
	seen_states[main.get_run_phase_name()] = true
	assert_eq(main.get_run_phase_name(), "ENDING")
	assert_eq(main.interstitial_title_label.text, "ANOTHER ROUND?")
	assert_true(main.interstitial_body_label.text.contains("all the way around"))
	assert_true(main.interstitial_menu_button.visible)
	assert_eq(main.interstitial_continue_button.text, "NEW RUN")

	main.run_state.tokens = 99
	main.run_state.owned_cards.append("Stale Card")
	var previous_seed: int = main.run_state.run_seed
	main.interstitial_continue_button.pressed.emit()
	seen_states[main.get_run_phase_name()] = true
	assert_eq(main.get_run_phase_name(), "RUN_START")
	assert_eq(main.interstitial_title_label.text, "TEE OFF")
	assert_ne(main.run_state.run_seed, previous_seed)
	assert_eq(main.run_state.tokens, 2)
	assert_true(main.run_state.owned_cards.is_empty())
	assert_eq(main.run_state.level_index, 0)
	assert_eq(main.run_state.biome_index, 0)
	assert_eq(main.run_state.hole_index, 0)
	assert_eq(main.run_state.overall_hole_number, 1)
	assert_eq(main.run_state.levels.size(), 18)

	for expected_state in ["MAIN_MENU", "RUN_START", "BIOME_INTRO", "HOLE_PLAY", "HOLE_RESULTS", "SHOP", "RUN_RESULTS", "ENDING"]:
		assert_true(seen_states.has(expected_state), "Smoke path did not visit %s." % expected_state)


func test_hud_menu_resume_and_tutorial_buttons_are_navigable() -> void:
	var main = _spawn_main_menu()
	main.game_settings.reduced_motion = false
	main.game_settings.visual_effects_intensity = 1.0
	main._apply_player_settings()

	main.menu_tutorial_button.pressed.emit()
	assert_true(main.run_state.tutorial_mode)
	assert_eq(main.get_run_phase_name(), "HOLE_PLAY")
	assert_false(main.score_label.visible)
	assert_true(main.release_hud.visible)
	assert_eq(main.release_hud.biome_label.text, "TUTORIAL")
	assert_eq(main.release_hud.hole_label.text, "HOLE 01 / 06")

	main.menu_button.pressed.emit()
	assert_true(main.main_menu_overlay.visible)
	assert_true(main.menu_resume_button.visible)
	assert_false(main.title_attract_mode.visible)
	assert_true(main.menu_pause_dim.visible)
	assert_eq(main.menu_pause_dim.material, main.menu_pause_blur_material)
	assert_true(main.level_root.visible)
	assert_not_null(main.menu_settings_button)
	assert_true(main.ball.simulation_paused)
	assert_eq(main.level_builder.level_root.process_mode, Node.PROCESS_MODE_DISABLED)
	main.menu_resume_button.pressed.emit()
	assert_false(main.main_menu_overlay.visible)
	assert_eq(main.get_run_phase_name(), "HOLE_PLAY")
	assert_false(main.ball.simulation_paused)
	assert_eq(main.level_builder.level_root.process_mode, Node.PROCESS_MODE_INHERIT)

	main.menu_button.pressed.emit()
	main.menu_settings_button.pressed.emit()
	assert_true(main.settings_screen.visible)
	assert_false(main.menu_action_panel.visible)
	assert_false(main.menu_pause_dim.visible)
	assert_true(main.settings_screen.pause_dim.visible)
	assert_eq(main.settings_screen.pause_dim.material, main.settings_screen.pause_blur_material)
	main.settings_screen.close_button.pressed.emit()
	assert_false(main.settings_screen.visible)
	assert_true(main.menu_action_panel.visible)
	assert_true(main.menu_pause_dim.visible)
	main.menu_play_button.pressed.emit()
	assert_eq(main.vs_controller.view.page_id, &"mode_select")
	main.vs_controller.view.mode_selected.emit(false)
	assert_true(main.run_setup_screen.visible)
	main.run_setup_screen.settings = null
	main.run_setup_screen.seed_input.text = str(TEST_SEED)
	main.run_setup_screen._on_start_pressed()
	assert_false(main.run_state.tutorial_mode)
	assert_eq(main.get_run_phase_name(), "RUN_START")
	assert_eq(main.interstitial_title_label.text, "TEE OFF")


func test_pause_blur_falls_back_to_a_translucent_dim_for_reduced_effects() -> void:
	var main = _spawn_playing_main()
	main.game_settings.visual_effects_intensity = 0.2
	main.game_settings.reduced_motion = false
	main.menu_button.pressed.emit()
	assert_true(main.menu_pause_dim.visible)
	assert_null(main.menu_pause_dim.material)
	main.menu_resume_button.pressed.emit()
	main.game_settings.visual_effects_intensity = 1.0
	main.game_settings.reduced_motion = true
	main.menu_button.pressed.emit()
	assert_true(main.menu_pause_dim.visible)
	assert_null(main.menu_pause_dim.material)


func test_tutorial_presentation_cleans_up_on_menu_skip_and_new_run() -> void:
	var main = _spawn_main_menu()
	main._start_tutorial()
	main.tutorial_manager._process(0.016)

	assert_true(main.tutorial_manager.presentation_enabled)
	assert_true(main.tutorial_manager.hint_panel.visible)
	assert_true(main.tutorial_manager.skip_button.visible)
	assert_true(main.tutorial_manager.highlight.visible)
	assert_eq(main.tutorial_manager.hint_label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
	assert_eq(main.tutorial_manager.hint_label.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING)
	assert_gte(main.tutorial_manager.hint_label.custom_minimum_size.y, 58.0)

	main._show_main_menu()
	assert_false(main.tutorial_manager.presentation_enabled)
	assert_false(main.tutorial_manager.hint_panel.visible)
	assert_false(main.tutorial_manager.skip_button.visible)
	assert_false(main.tutorial_manager.highlight.visible)
	main._hide_main_menu()
	main.tutorial_manager._process(0.016)
	assert_true(main.tutorial_manager.hint_panel.visible)
	assert_true(main.tutorial_manager.highlight.visible)

	main._on_tutorial_skip_requested()
	assert_false(main.run_state.tutorial_mode)
	assert_eq(main.get_run_phase_name(), "MAIN_MENU")
	assert_true(main.run_state.levels.is_empty(), "Skip does not generate a real run")
	assert_false(main.tutorial_manager.presentation_enabled)
	assert_true(main.tutorial_manager.current_level.is_empty())
	assert_false(main.tutorial_manager.hint_panel.visible)
	assert_false(main.tutorial_manager.skip_button.visible)
	assert_false(main.tutorial_manager.highlight.visible)

	main._show_main_menu()
	assert_false(main.tutorial_manager.hint_panel.visible)
	assert_false(main.tutorial_manager.highlight.visible)


func test_tutorial_completion_transition_clears_every_tutorial_overlay() -> void:
	var main = _spawn_main_menu()
	main._start_tutorial()
	main.tutorial_manager._process(0.016)
	assert_true(main.tutorial_manager.highlight.visible)

	main._start_normal_run(TEST_SEED)
	assert_false(main.run_state.tutorial_mode)
	assert_false(main.tutorial_manager.presentation_enabled)
	assert_true(main.tutorial_manager.current_level.is_empty())
	assert_false(main.tutorial_manager.hint_panel.visible)
	assert_false(main.tutorial_manager.skip_button.visible)
	assert_false(main.tutorial_manager.highlight.visible)


func test_menu_during_moving_ball_preserves_shot_and_blocks_background_progress() -> void:
	var main = _spawn_playing_main()
	main.ball.shot_in_progress = true
	main.ball.linear_velocity = Vector2(480.0, 60.0)
	main.ball.angular_velocity = 1.4
	var expected_velocity: Vector2 = main.ball.linear_velocity
	var expected_strokes: int = main.run_state.strokes
	var expected_phase: String = main.get_run_phase_name()

	main.menu_button.pressed.emit()
	assert_true(main.main_menu_overlay.visible)
	assert_true(main.ball.simulation_paused)
	assert_true(main.ball.freeze)
	main.ball._physics_process(1.0)
	assert_eq(main.run_state.strokes, expected_strokes)
	assert_eq(main.get_run_phase_name(), expected_phase)

	main.menu_resume_button.pressed.emit()
	assert_false(main.ball.simulation_paused)
	assert_true(main.ball.shot_in_progress)
	assert_eq(main.ball.linear_velocity, expected_velocity)


func test_pause_freezes_and_resume_advances_a_pendulum_cycle() -> void:
	var main = _spawn_playing_main()
	var hazard = MovingHazardScript.new()
	hazard.configure({
		"type": "pendulum",
		"pos": Vector2.ZERO,
		"size": Vector2(38.0, 38.0),
		"elevation": 0,
		"period": 2.4,
		"phase": 0.0,
		"travel_radius": 60.0,
		"blocks_main_route": false,
	})
	main.level_root.add_child(hazard)
	await get_tree().physics_frame
	main.menu_button.pressed.emit()
	var paused_elapsed: float = hazard.elapsed
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(hazard.elapsed, paused_elapsed)
	main.menu_resume_button.pressed.emit()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_gt(hazard.elapsed, paused_elapsed)


func test_moving_hazard_contact_adds_one_penalty_and_one_reset_record() -> void:
	var main = _spawn_playing_main()
	var strokes_before: int = main.run_state.strokes
	var total_before: int = main.run_state.total_strokes
	var resets_before := int(main.run_stats.hazard_resets.get("pendulum", 0))
	var level: Dictionary = main.run_state.levels[main.run_state.level_index]
	var start_position: Vector2 = main.level_builder.level_point(level, "start", "start_cell")

	main._on_reset_hazard_body_entered(main.ball, main.ball.global_position, &"pendulum")
	assert_eq(main.run_state.strokes, strokes_before + 1)
	assert_eq(main.run_state.total_strokes, total_before + 1)
	assert_true(main.hazard_resetting)
	await main.ball.hazard_sink_finished
	await get_tree().process_frame

	assert_false(main.hazard_resetting)
	assert_eq(int(main.run_stats.hazard_resets.get("pendulum", 0)), resets_before + 1)
	assert_eq(main.ball.global_position, start_position)


func test_manual_reset_at_par_plus_four_forces_result_without_erasing_cost() -> void:
	var main = _spawn_playing_main()
	var par: int = main.run_state.levels[main.run_state.level_index].par
	main.run_state.strokes = par + 3
	main.run_state.total_strokes = main.run_state.strokes
	main.run_stats.total_strokes = main.run_state.strokes
	main.ball.shot_in_progress = true
	main.ball.shot_started.emit(Vector2.ZERO, Vector2.RIGHT, 0.5)

	main._reset_current_level()

	assert_eq(main.run_state.strokes, par + 4)
	assert_eq(main.run_state.total_strokes, par + 4)
	assert_eq(main.run_stats.total_strokes, par + 4)
	assert_eq(main.get_run_phase_name(), "HOLE_RESULTS")
	assert_true(main.run_state.last_hole_forced)


func test_out_of_bounds_countdown_returns_to_shot_origin_without_double_accounting() -> void:
	var main = _spawn_playing_main()
	var safe_position: Vector2 = main.ball.global_position
	main._on_ball_shot_started(safe_position, Vector2.RIGHT, 1.0)
	var strokes_after_shot: int = main.run_state.strokes
	var total_after_shot: int = main.run_state.total_strokes
	var resets_before: Dictionary = main.run_stats.hazard_resets.duplicate()

	main.ball.global_position = Vector2(100000.0, 100000.0)
	main._update_out_of_bounds_recovery(0.1)
	assert_true(main.out_of_bounds_active)
	assert_true(main.release_hud.oob_panel.visible)
	assert_string_contains(main.release_hud.oob_countdown_label.text, "3")
	main._update_out_of_bounds_recovery(3.0)

	assert_false(main.out_of_bounds_active)
	assert_false(main.release_hud.oob_panel.visible)
	assert_eq(main.ball.global_position, safe_position)
	assert_eq(main.run_state.strokes, strokes_after_shot - 1)
	assert_eq(main.run_state.total_strokes, total_after_shot - 1)
	assert_eq(main.run_stats.hazard_resets, resets_before)
	main._update_out_of_bounds_recovery(3.0)
	assert_eq(main.run_state.strokes, strokes_after_shot - 1)
	assert_true(main.ball.input_enabled)


func test_oob_at_limit_refunds_only_accepted_shot_before_history_and_reward() -> void:
	var main = _spawn_playing_main()
	var par: int = main.run_state.levels[main.run_state.level_index].par
	var origin: Vector2 = main.ball.position
	for index in range(par + 3):
		main._on_ball_shot_started(origin, Vector2.RIGHT, 0.5)
		main._on_ball_shot_finished()
	for repeat in range(3):
		main._on_ball_shot_started(origin, Vector2.RIGHT, 1.0)
		var ticket: int = main.run_state.accepted_shot_id
		main.ball.position = Vector2(100000, 100000)
		main._on_ball_shot_finished()
		assert_eq(main.get_run_phase_name(), "HOLE_PLAY")
		main._update_out_of_bounds_recovery(0.1)
		main._update_out_of_bounds_recovery(3.0)
		assert_eq(main.run_state.strokes, par + 3)
		assert_eq(main.run_state.total_strokes, par + 3)
		assert_eq(main.run_state.remaining_shots(par), 1)
		assert_false(main.run_state.refund_out_of_bounds_shot(ticket))
	main._on_ball_shot_started(origin, Vector2.RIGHT, 0.5)
	main._on_ball_shot_finished()
	assert_eq(main.get_run_phase_name(), "HOLE_RESULTS")
	assert_eq(main.run_state.strokes, par + 4)
	assert_eq(main.run_stats.total_strokes, par + 4)
	assert_eq(main.run_state.last_hole_reward, 0)
	assert_eq(main.run_stats.history_snapshot()[0].strokes, par + 4)


func test_out_of_bounds_warning_cancels_when_ball_returns_to_play() -> void:
	var main = _spawn_playing_main()
	var safe_position: Vector2 = main.ball.global_position
	main.ball.global_position = Vector2(-100000.0, -100000.0)
	main._update_out_of_bounds_recovery(0.5)
	assert_true(main.out_of_bounds_active)
	main.ball.global_position = safe_position
	main._update_out_of_bounds_recovery(0.1)
	assert_false(main.out_of_bounds_active)
	assert_false(main.release_hud.oob_panel.visible)


func _spawn_main_menu() -> Variant:
	var main = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	main.set_process(false)
	return main


func _spawn_normal_main() -> Variant:
	var main = _spawn_main_menu()
	main.run_state.difficulty_profile = DifficultyDatabase.get_profile(&"normal")
	main._start_normal_run(TEST_SEED)
	return main


func _spawn_playing_main() -> Variant:
	var main = _spawn_normal_main()
	main._on_interstitial_continue_pressed()
	main._on_interstitial_continue_pressed()
	return main


func _card_by_name(card_name: String) -> CardDefinition:
	for card in CardDatabase.get_cards():
		if card.name == card_name:
			return card
	return null
