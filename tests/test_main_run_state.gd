extends GutTest

const MAIN_SCENE := preload("res://scenes/main.tscn")
const CardDatabase := preload("res://scripts/card_database.gd")
const LevelValidator := preload("res://scripts/level_validator.gd")
const TEST_SEED := 424242


func test_starting_normal_run_builds_clean_eighteen_hole_contract() -> void:
	var main = _spawn_main_menu()
	main.level_index = 3
	main.strokes = 4
	main.total_strokes = 11
	main.tokens = 9
	main.level_elapsed = 42.5
	main.reward_bonus = 2
	main.owned_cards.append("Lucky Putter")
	main.run_stats.record_stroke()
	main.run_stats.update_time(42.5)

	main._start_normal_run(TEST_SEED)
	main.set_process(false)

	assert_eq(main.get_run_phase_name(), "RUN_START")
	assert_eq(main.run_seed, TEST_SEED)
	assert_eq(main.levels.size(), 18)
	assert_eq(main.biome_profiles.size(), 6)
	assert_eq(main.level_index, 0)
	assert_eq(main.biome_index, 0)
	assert_eq(main.hole_index, 0)
	assert_eq(main.overall_hole_number, 1)
	assert_eq(main.strokes, 0)
	assert_eq(main.total_strokes, 0)
	assert_eq(main.tokens, 2)
	assert_eq(main.level_elapsed, 0.0)
	assert_eq(main.reward_bonus, 0)
	assert_true(main.owned_cards.is_empty())
	assert_true(main.owned_card_definitions.is_empty())
	assert_true(main.active_card_curses.is_empty())
	assert_almost_eq(main.roll_damp_modifier, 1.0, 0.001)
	assert_almost_eq(main.cup_radius_scale, 1.0, 0.001)
	assert_eq(main.run_stats.total_strokes, 0)
	assert_eq(main.run_stats.total_run_time, 0.0)


func test_accepted_shot_increments_current_stroke_totals_once() -> void:
	var main = _spawn_playing_main()

	main.ball.shot_started.emit(Vector2.ZERO, Vector2.RIGHT, 0.5)
	main.ball.shot_finished.emit()

	assert_eq(main.strokes, 1)
	assert_eq(main.total_strokes, 1)
	assert_eq(main.run_stats.total_strokes, 1)


func test_hole_completion_awards_results_and_advances_once() -> void:
	var main = _spawn_playing_main()
	main.ball.sink_animation_duration = 0.0
	main.feedback_director.completion_pause_duration = 0.0

	main.level_builder.hole_body_entered.emit(main.ball)
	main.level_builder.hole_body_entered.emit(main.ball)

	assert_true(main.loading_next_level)
	assert_eq(main.level_index, 0)

	var sink_finished: bool = await wait_for_signal(main.ball.sink_animation_finished, 1.0)
	assert_true(sink_finished)
	await wait_process_frames(1)

	assert_eq(main.get_run_phase_name(), "HOLE_RESULTS")
	assert_eq(main.tokens, 5)
	assert_eq(main.level_index, 0)
	main.interstitial_continue_button.pressed.emit()
	await wait_process_frames(1)

	assert_eq(main.get_run_phase_name(), "HOLE_PLAY")
	assert_eq(main.level_index, 1)
	assert_eq(main.biome_index, 0)
	assert_eq(main.hole_index, 1)
	assert_eq(main.overall_hole_number, 2)
	assert_eq(main.tokens, 5)


func test_manual_current_hole_reset_preserves_cumulative_run_state() -> void:
	var main = _spawn_playing_main()
	main._load_level(2)
	main.tokens = 7
	main.ball.shot_started.emit(Vector2.ZERO, Vector2.RIGHT, 0.5)
	main.level_elapsed = 8.5

	main._reset_current_level()

	assert_eq(main.strokes, 1)
	assert_eq(main.level_elapsed, 8.5)
	assert_eq(main.total_strokes, 1)
	assert_eq(main.run_stats.total_strokes, 1)
	assert_eq(main.run_stats.manual_resets, 1)
	assert_eq(main.level_index, 2)
	assert_eq(main.biome_index, 0)
	assert_eq(main.hole_index, 2)
	assert_eq(main.overall_hole_number, 3)
	assert_eq(main.tokens, 7)


func test_run_timing_accumulates_only_during_hole_play() -> void:
	var main = _spawn_normal_main()

	main._process(1.25)
	assert_eq(main.level_elapsed, 0.0)
	assert_eq(main.run_stats.total_run_time, 0.0)

	main._on_interstitial_continue_pressed()
	main._process(1.25)
	assert_eq(main.level_elapsed, 0.0)
	assert_eq(main.run_stats.total_run_time, 0.0)

	main._on_interstitial_continue_pressed()
	main._process(1.25)
	assert_eq(main.level_elapsed, 1.25)
	assert_eq(main.run_stats.total_run_time, 1.25)

	main.loading_next_level = true
	main._process(2.0)
	assert_eq(main.level_elapsed, 1.25)
	assert_eq(main.run_stats.total_run_time, 1.25)


func test_stroke_ceiling_forces_results_instead_of_softlocking() -> void:
	var main = _spawn_playing_main()
	var par: int = main.levels[main.level_index].par
	main.strokes = par + 3
	main.total_strokes = main.strokes
	main.run_stats.total_strokes = main.strokes

	main.ball.shot_started.emit(Vector2.ZERO, Vector2.RIGHT, 0.5)
	main.ball.shot_finished.emit()

	assert_eq(main.strokes, par + 4)
	assert_eq(main.get_run_phase_name(), "HOLE_RESULTS")
	assert_true(main.last_hole_forced)


func test_shop_accepts_at_most_two_distinct_purchases() -> void:
	var main = _spawn_playing_main()
	main._load_level(2)
	main.tokens = 20
	main._complete_current_hole(false, false)
	main._on_interstitial_continue_pressed()
	assert_eq(main.get_run_phase_name(), "SHOP")

	main.shop_manager._on_shop_card_pressed(0)
	var tokens_after_first: int = main.tokens
	main.shop_manager._on_shop_card_pressed(0)
	assert_eq(main.tokens, tokens_after_first)
	assert_eq(main.shop_manager.purchases_this_visit, 1)

	main.shop_manager._on_shop_card_pressed(1)
	var tokens_after_second: int = main.tokens
	main.shop_manager._on_shop_card_pressed(2)
	assert_eq(main.tokens, tokens_after_second)
	assert_eq(main.shop_manager.purchases_this_visit, 2)
	assert_eq(main.owned_cards.size(), 2)
	assert_eq(main.active_card_curses.size(), 2)


func test_card_bonus_persists_after_its_curse_expires_in_three_holes() -> void:
	var main = _spawn_playing_main()
	main._apply_card(_card_by_name("Coin Magnet"))

	assert_eq(main.reward_bonus, 1)
	assert_almost_eq(main.cup_radius_scale, 0.88, 0.001)
	assert_eq(main.trajectory_dot_bonus, 0)
	assert_eq(main.active_card_curses[0].remaining_holes, 3)
	main._update_status()
	assert_true(main.effects_status_label.text.contains("Coin Magnet (3 holes)"))

	for expected_remaining in [2, 1, 0]:
		main._complete_current_hole(false, false)
		assert_eq(main.get_run_phase_name(), "HOLE_RESULTS")
		if expected_remaining > 0:
			assert_eq(main.active_card_curses[0].remaining_holes, expected_remaining)
			main._on_interstitial_continue_pressed()
		else:
			assert_true(main.active_card_curses.is_empty())

	assert_eq(main.reward_bonus, 1)
	assert_eq(main.trajectory_dot_bonus, 0)
	assert_almost_eq(main.cup_radius_scale, 1.0, 0.001)
	assert_eq(main.owned_cards, ["Coin Magnet"])
	main._update_status()
	assert_true(main.effects_status_label.text.contains("Active curses: None"))


func test_generation_curse_adds_a_deterministic_valid_hazard_to_next_biome() -> void:
	var main = _spawn_playing_main()
	main._apply_card(_card_by_name("Power Club"))
	var base_hazard_count: int = main.normal_levels[3].hazards.size()

	main._load_level(3)
	var modified_level: Dictionary = main.levels[3]

	assert_eq(int(modified_level.card_hazard_count), 1)
	assert_eq(modified_level.hazards.size(), base_hazard_count + 1)
	assert_true(LevelValidator.validate_level(modified_level, 3))
	assert_eq(String(modified_level.hazards[-1].type), "direction")


func test_lucky_putter_uses_birdie_risk_reward_and_temporary_small_cup() -> void:
	var main = _spawn_playing_main()
	main._apply_card(_card_by_name("Lucky Putter"))
	var base_cup_radius := float(main.normal_levels[3].cup_radius)

	main._load_level(3)

	assert_almost_eq(float(main.levels[3].cup_radius), base_cup_radius * 0.75, 0.001)
	assert_eq(main._token_reward_for_score(2, 3), 5)
	assert_eq(main._token_reward_for_score(3, 3), 2)


func test_rangefinder_improves_control_with_temporary_shot_power_curse() -> void:
	var main = _spawn_playing_main()
	main._apply_card(_card_by_name("Rangefinder Lens"))

	assert_eq(main.trajectory_dot_bonus, 0)
	assert_almost_eq(main.drag_modifier, 1.12, 0.001)
	assert_almost_eq(main.impulse_modifier, 0.9, 0.001)
	assert_null(main.ball.get_node_or_null("TrajectoryPreview"))


func test_roll_control_terrain_and_direction_effects_reach_gameplay_values() -> void:
	var main = _spawn_playing_main()
	var base_roll_damp: float = main.ball.base_linear_damp

	main._apply_card(_card_by_name("Heavy Core"))
	main._apply_card(_card_by_name("Sand Cleats"))
	main._apply_card(_card_by_name("Overdrive Driver"))
	main._apply_card(_card_by_name("Gust Guard"))

	assert_almost_eq(main.normal_ball_linear_damp, base_roll_damp * 0.8, 0.001)
	assert_almost_eq(main.impulse_modifier, 1.25, 0.001)
	assert_almost_eq(main.drag_modifier, 0.85, 0.001)
	assert_almost_eq(main.terrain_mitigation_modifier, 0.2, 0.001)
	assert_almost_eq(main.direction_push_modifier, 0.75, 0.001)
	assert_eq(main.active_hazard_count_modifier, 1)
	assert_gt(main._terrain_entry_speed_scale(main.SAND_ENTRY_SPEED_SCALE), main.SAND_ENTRY_SPEED_SCALE)


func test_stacked_card_curses_expire_together_without_removing_bonuses() -> void:
	var main = _spawn_playing_main()
	var overdrive := _card_by_name("Overdrive Driver")
	main._apply_card(overdrive)
	main._apply_card(overdrive)

	assert_almost_eq(main.impulse_modifier, 1.5, 0.001)
	assert_almost_eq(main.drag_modifier, 0.7, 0.001)
	for _hole_index in range(3):
		main._advance_active_curses()

	assert_true(main.active_card_curses.is_empty())
	assert_almost_eq(main.impulse_modifier, 1.5, 0.001)
	assert_almost_eq(main.drag_modifier, 1.0, 0.001)


func test_full_economy_smoke_buys_two_cards_in_all_five_shops() -> void:
	var main = _spawn_playing_main()
	var shop_visits := 0

	for expected_hole in range(1, 19):
		assert_eq(main.overall_hole_number, expected_hole)
		assert_eq(main.get_run_phase_name(), "HOLE_PLAY")
		main._complete_current_hole(false, false)
		if expected_hole > 3 and expected_hole % 3 == 0:
			assert_true(main.active_card_curses.is_empty(), "Biome curses must expire after exactly 3 holes.")
		main._on_interstitial_continue_pressed()

		if expected_hole < 18 and expected_hole % 3 == 0:
			shop_visits += 1
			assert_eq(main.get_run_phase_name(), "SHOP")
			assert_eq(main.shop_manager.current_shop_cards.size(), 4)
			var first_price: int = main.shop_manager.current_shop_cards[0].price
			var second_price: int = main.shop_manager.current_shop_cards[1].price
			var coins_before: int = main.tokens
			main.shop_manager._on_shop_card_pressed(0)
			main.shop_manager._on_shop_card_pressed(1)
			assert_eq(main.tokens, coins_before - first_price - second_price)
			assert_eq(main.shop_manager.purchases_this_visit, 2)
			assert_eq(main.active_card_curses.size(), 2)
			main.shop_manager._on_shop_continue_pressed()
			assert_eq(main.get_run_phase_name(), "BIOME_INTRO")
			main._on_interstitial_continue_pressed()

	assert_eq(shop_visits, 5)
	assert_eq(main.owned_cards.size(), 10)
	assert_true(main.active_card_curses.is_empty())
	assert_eq(main.get_run_phase_name(), "RUN_RESULTS")


func test_full_eighteen_hole_smoke_visits_every_runtime_state_and_resets() -> void:
	var main = _spawn_main_menu()
	var seen_states := {main.get_run_phase_name(): true}
	assert_true(main.main_menu_overlay.visible)
	assert_eq(main.main_menu_overlay.name, "MainMenuScreen")
	assert_eq(main.main_menu_title_label.text, "A Stroke Of Luck")
	assert_true(main.main_menu_summary_label.text.contains("Eighteen holes"))
	assert_false(main.score_label.visible)
	main.menu_play_button.pressed.emit()
	seen_states[main.get_run_phase_name()] = true
	assert_eq(main.get_run_phase_name(), "RUN_START")
	assert_true(main.interstitial_overlay.visible)
	assert_eq(main.interstitial_title_label.text, "Run Intro")
	assert_true(main.interstitial_body_label.text.contains("Seed: %d" % main.run_seed))
	assert_eq(main.interstitial_continue_button.text, "Begin Course")
	main.interstitial_continue_button.pressed.emit()
	seen_states[main.get_run_phase_name()] = true
	assert_eq(main.get_run_phase_name(), "BIOME_INTRO")
	assert_true(main.interstitial_title_label.text.contains("Biome 1/6: Meadow"))
	assert_true(main.interstitial_body_label.text.contains("Holes 1-3"))
	assert_eq(main.interstitial_continue_button.text, "Play Hole 1")
	main.interstitial_continue_button.pressed.emit()
	seen_states[main.get_run_phase_name()] = true

	var shop_visits := 0
	for expected_hole in range(1, 19):
		assert_eq(main.get_run_phase_name(), "HOLE_PLAY", "Hole %d must begin in HOLE_PLAY." % expected_hole)
		assert_eq(main.overall_hole_number, expected_hole)
		assert_eq(main.biome_index, (expected_hole - 1) / 3)
		assert_eq(main.hole_index, (expected_hole - 1) % 3)
		assert_eq(int(main.levels[main.level_index].overall_hole_number), expected_hole)
		assert_eq(int(main.levels[main.level_index].biome_index), main.biome_index)
		assert_eq(int(main.levels[main.level_index].hole_index), main.hole_index)
		assert_false(main.score_label.visible)
		assert_true(main.release_hud.visible)
		assert_true(main.power_meter.visible)
		assert_false(main.interstitial_overlay.visible)
		assert_true(main.release_hud.biome_label.text.contains("BIOME %d/6" % (main.biome_index + 1)))
		assert_eq(main.release_hud.hole_label.text, "HOLE %d / 18" % expected_hole)
		assert_eq(main.release_hud.timer_label.text, "TIME  00:00")

		main._complete_current_hole(false, false)
		seen_states[main.get_run_phase_name()] = true
		assert_eq(main.get_run_phase_name(), "HOLE_RESULTS")
		assert_false(main.score_label.visible)
		assert_eq(main.interstitial_title_label.text, "Hole %d Results" % expected_hole)
		assert_true(main.interstitial_body_label.text.contains("Coins held: %d" % main.tokens))
		main.interstitial_continue_button.pressed.emit()
		seen_states[main.get_run_phase_name()] = true

		if expected_hole < 18 and expected_hole % 3 == 0:
			assert_eq(main.get_run_phase_name(), "SHOP")
			shop_visits += 1
			assert_true(main.shop_manager.shop_overlay.visible)
			assert_eq(main.shop_manager.shop_title_label.text, "THE CLUBHOUSE SHOP")
			assert_true(main.shop_manager.shop_destination_label.text.contains("Biome %d/6" % (shop_visits + 1)))
			assert_true(main.shop_manager.shop_destination_label.text.contains("overall %d/18" % (expected_hole + 1)))
			assert_false(main.shop_manager.continue_button.disabled)
			main.shop_manager.continue_button.pressed.emit()
			seen_states[main.get_run_phase_name()] = true
			assert_eq(main.get_run_phase_name(), "BIOME_INTRO")
			assert_true(main.interstitial_title_label.text.contains("Biome %d/6" % (shop_visits + 1)))
			assert_eq(main.interstitial_continue_button.text, "Play Hole %d" % (expected_hole + 1))
			main.interstitial_continue_button.pressed.emit()
			seen_states[main.get_run_phase_name()] = true

	assert_eq(shop_visits, 5)
	assert_eq(main.get_run_phase_name(), "RUN_RESULTS")
	assert_eq(main.interstitial_title_label.text, "Run Results")
	assert_true(main.interstitial_body_label.text.contains("All 18 holes complete."))
	assert_eq(main.interstitial_continue_button.text, "See Ending")
	main.interstitial_continue_button.pressed.emit()
	seen_states[main.get_run_phase_name()] = true
	assert_eq(main.get_run_phase_name(), "ENDING")
	assert_eq(main.interstitial_title_label.text, "A Stroke of Luck")
	assert_true(main.interstitial_body_label.text.contains("all eighteen holes"))
	assert_eq(main.interstitial_continue_button.text, "New Run")

	main.tokens = 99
	main.owned_cards.append("Stale Card")
	var previous_seed: int = main.run_seed
	main.interstitial_continue_button.pressed.emit()
	seen_states[main.get_run_phase_name()] = true
	assert_eq(main.get_run_phase_name(), "RUN_START")
	assert_eq(main.interstitial_title_label.text, "Run Intro")
	assert_ne(main.run_seed, previous_seed)
	assert_eq(main.tokens, 2)
	assert_true(main.owned_cards.is_empty())
	assert_eq(main.level_index, 0)
	assert_eq(main.biome_index, 0)
	assert_eq(main.hole_index, 0)
	assert_eq(main.overall_hole_number, 1)
	assert_eq(main.levels.size(), 18)

	for expected_state in ["MAIN_MENU", "RUN_START", "BIOME_INTRO", "HOLE_PLAY", "HOLE_RESULTS", "SHOP", "RUN_RESULTS", "ENDING"]:
		assert_true(seen_states.has(expected_state), "Smoke path did not visit %s." % expected_state)


func test_hud_menu_resume_and_tutorial_buttons_are_navigable() -> void:
	var main = _spawn_main_menu()

	main.menu_tutorial_button.pressed.emit()
	assert_true(main.tutorial_mode)
	assert_eq(main.get_run_phase_name(), "HOLE_PLAY")
	assert_false(main.score_label.visible)
	assert_true(main.release_hud.visible)
	assert_eq(main.release_hud.biome_label.text, "TUTORIAL")
	assert_eq(main.release_hud.hole_label.text, "HOLE 1 / 6")

	main.menu_button.pressed.emit()
	assert_true(main.main_menu_overlay.visible)
	assert_true(main.menu_resume_button.visible)
	assert_true(main.menu_skip_button.visible)
	assert_true(main.ball.simulation_paused)
	assert_eq(main.level_builder.level_root.process_mode, Node.PROCESS_MODE_DISABLED)
	main.menu_resume_button.pressed.emit()
	assert_false(main.main_menu_overlay.visible)
	assert_eq(main.get_run_phase_name(), "HOLE_PLAY")
	assert_false(main.ball.simulation_paused)
	assert_eq(main.level_builder.level_root.process_mode, Node.PROCESS_MODE_INHERIT)

	main.menu_button.pressed.emit()
	main.menu_skip_button.pressed.emit()
	assert_false(main.tutorial_mode)
	assert_eq(main.get_run_phase_name(), "RUN_START")
	assert_eq(main.interstitial_title_label.text, "Run Intro")


func test_menu_during_moving_ball_preserves_shot_and_blocks_background_progress() -> void:
	var main = _spawn_playing_main()
	main.ball.shot_in_progress = true
	main.ball.linear_velocity = Vector2(480.0, 60.0)
	main.ball.angular_velocity = 1.4
	var expected_velocity: Vector2 = main.ball.linear_velocity
	var expected_strokes: int = main.strokes
	var expected_phase: String = main.get_run_phase_name()

	main.menu_button.pressed.emit()
	assert_true(main.main_menu_overlay.visible)
	assert_true(main.ball.simulation_paused)
	assert_true(main.ball.freeze)
	main.ball._physics_process(1.0)
	assert_eq(main.strokes, expected_strokes)
	assert_eq(main.get_run_phase_name(), expected_phase)

	main.menu_resume_button.pressed.emit()
	assert_false(main.ball.simulation_paused)
	assert_true(main.ball.shot_in_progress)
	assert_eq(main.ball.linear_velocity, expected_velocity)


func test_manual_reset_at_par_plus_four_forces_result_without_erasing_cost() -> void:
	var main = _spawn_playing_main()
	var par: int = main.levels[main.level_index].par
	main.strokes = par + 3
	main.total_strokes = main.strokes
	main.run_stats.total_strokes = main.strokes
	main.ball.shot_in_progress = true
	main.ball.shot_started.emit(Vector2.ZERO, Vector2.RIGHT, 0.5)

	main._reset_current_level()

	assert_eq(main.strokes, par + 4)
	assert_eq(main.total_strokes, par + 4)
	assert_eq(main.run_stats.total_strokes, par + 4)
	assert_eq(main.get_run_phase_name(), "HOLE_RESULTS")
	assert_true(main.last_hole_forced)


func _spawn_main_menu() -> Variant:
	var main = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	main.set_process(false)
	return main


func _spawn_normal_main() -> Variant:
	var main = _spawn_main_menu()
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
