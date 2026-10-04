extends GutTest

const MainScene := preload("res://scenes/main.tscn")
const Cards := preload("res://scripts/card_database.gd")
const Difficulties := preload("res://scripts/difficulty_database.gd")


func test_lifecycle_rejects_duplicate_and_illegal_transitions() -> void:
	var state := RunState.new()
	assert_false(state.transition_to(RunState.Phase.HOLE_RESULTS))
	assert_false(state.transition_to(RunState.Phase.MAIN_MENU))
	for phase in [RunState.Phase.RUN_START, RunState.Phase.BIOME_INTRO, RunState.Phase.PREPARE_HOLE, RunState.Phase.HOLE_PLAY, RunState.Phase.HOLE_RESOLVING, RunState.Phase.HOLE_RESULTS, RunState.Phase.SHOP, RunState.Phase.BIOME_INTRO, RunState.Phase.PREPARE_HOLE, RunState.Phase.HOLE_PLAY, RunState.Phase.HOLE_RESOLVING, RunState.Phase.HOLE_RESULTS, RunState.Phase.RUN_RESULTS, RunState.Phase.ENDING]:
		assert_true(state.transition_to(phase), "Legal transition to %s" % RunState.PHASE_NAMES[phase])
		assert_false(state.transition_to(phase), "Repeated transition must have no side effects")
	assert_false(state.transition_to(RunState.Phase.SHOP))
	assert_true(state.transition_to(RunState.Phase.MAIN_MENU))


func test_run_state_instances_and_ui_snapshots_do_not_share_mutable_truth() -> void:
	var state := RunState.new()
	var other := RunState.new()
	state.add_card(Cards.get_cards()[0])
	state.record_stroke()
	state.stats.record_hole_result({"hole_number": 1, "strokes": 2})
	state.last_hole_rating = {"stars": 4, "detail": {"score": 1}}
	var copy := state.snapshot()
	copy.bonuses.clear()
	copy.history[0].strokes = 999
	copy.rating.detail.score = 999
	assert_eq(state.owned_cards.size(), 1)
	assert_eq(state.stats.history_snapshot()[0].strokes, 2)
	assert_eq(state.last_hole_rating.detail.score, 1)
	assert_true(other.owned_cards.is_empty())
	assert_true(other.active_card_curses.is_empty())
	assert_eq(other.total_strokes, 0)
	assert_same(state.owned_cards, state.stats.cards_bought)
	assert_eq(state.total_strokes, state.stats.total_strokes)


func test_reset_clears_accounting_effects_and_keeps_selected_difficulty() -> void:
	var state := RunState.new()
	state.difficulty_profile = Difficulties.get_profile(&"hard")
	state.add_card(Cards.get_cards()[0])
	state.record_stroke()
	state.levels = [{"par": 4}]
	state.normal_levels = state.levels
	var source_levels := state.levels
	state.tokens = 99
	state.menu_paused = true
	state.reset(12345)
	assert_eq(state.run_seed, 12345)
	assert_eq(state.tokens, 2)
	assert_eq(state.strokes, 0)
	assert_eq(state.total_strokes, 0)
	assert_true(state.owned_card_definitions.is_empty())
	assert_true(state.active_card_curses.is_empty())
	assert_eq(state.impulse_modifier, 1.0)
	assert_eq(state.cup_radius_scale, 1.0)
	assert_false(state.menu_paused)
	assert_eq(state.difficulty_profile.id, &"hard")
	assert_eq(source_levels.size(), 1, "Reset must not clear a shared authored lesson array")
	assert_true(state.levels.is_empty())


func test_clock_only_runs_in_unpaused_hole_play() -> void:
	var state := RunState.new()
	for phase in RunState.Phase.values():
		state.phase = phase
		state.update_time(1.0)
	assert_eq(state.level_elapsed, 1.0)
	state.phase = RunState.Phase.HOLE_PLAY
	state.menu_paused = true
	state.update_time(2.0)
	assert_eq(state.stats.total_run_time, 1.0)


func test_shop_and_run_use_one_wallet_and_reject_stale_purchase_intents() -> void:
	var main = _playing_main()
	main._complete_current_hole(false, false)
	main.run_state.tokens = 99
	main._show_shop(3)
	var shop: ShopManager = main.shop_manager
	var price := shop.current_shop_cards[0].price
	watch_signals(main.audio_controller)
	shop._on_shop_card_pressed(0)
	assert_eq(main.run_state.tokens, 99 - price)
	assert_eq(shop.tokens, main.run_state.tokens)
	assert_eq(main.run_state.owned_card_definitions.size(), 1)
	assert_eq(_cues(main.audio_controller).count(&"purchase"), 1)
	assert_eq(_cues(main.audio_controller).count(&"ui_click"), 0)
	shop._on_shop_continue_pressed()
	shop._on_shop_card_pressed(1)
	assert_eq(main.run_state.tokens, 99 - price)
	assert_eq(main.run_state.owned_card_definitions.size(), 1)


func test_rejected_purchase_produces_one_error_and_no_reward_cue() -> void:
	var main = _playing_main()
	main._complete_current_hole(false, false)
	main.run_state.tokens = 0
	main._show_shop(3)
	watch_signals(main.audio_controller)
	main.shop_manager._on_shop_card_pressed(0)
	assert_eq(_cues(main.audio_controller), [&"error"])
	assert_eq(main.run_state.tokens, 0)
	assert_true(main.run_state.owned_card_definitions.is_empty())


func test_purchase_feedback_keeps_card_in_its_original_layout_slot() -> void:
	var main = _playing_main()
	main._complete_current_hole(false, false)
	main.run_state.tokens = 99
	main._show_shop(3)
	await wait_seconds(0.6)
	var button: Button = main.shop_manager.shop_card_buttons[0]
	var slot: Control = main.shop_manager.shop_card_slots[0]
	var original_size := button.size
	button.pressed.emit()
	await wait_seconds(0.6)
	assert_eq(button.scale, Vector2.ONE)
	assert_eq(button.size, original_size, "Purchase animation must not leave enlarged layout offsets")
	assert_true(slot.get_global_rect().grow(1.0).encloses(button.get_global_rect()), "Purchased card %s must remain in slot %s (offsets %s / %s)" % [button.get_global_rect(), slot.get_global_rect(), button.offset_top, button.offset_bottom])


func test_par_plus_four_cup_plays_both_failures_and_never_positive_audio() -> void:
	var main = _playing_main()
	main.ball.sink_animation_duration = 0.0
	main.feedback_director.completion_pause_duration = 0.0
	main.run_state.strokes = int(main.run_state.levels[0].par) + 4
	watch_signals(main.audio_controller)
	main.level_builder.hole_body_entered.emit(main.ball)
	main.level_builder.hole_body_entered.emit(main.ball)
	await wait_for_signal(main.ball.sink_animation_finished, 1.0)
	await wait_process_frames(1)
	var cues := _cues(main.audio_controller)
	assert_eq(cues.count(&"failure_1"), 1)
	assert_eq(cues.count(&"failure_2"), 1)
	assert_false(cues.has(&"cup_sink"))
	assert_false(cues.has(&"hole_completion"))
	assert_true(main.run_state.last_hole_forced)
	assert_eq(main.run_stats.history_snapshot().size(), 1)
	var wallet: int = main.run_state.tokens
	main._show_hole_results()
	main._complete_current_hole(false, true)
	assert_eq(main.run_state.tokens, wallet)
	assert_eq(_cues(main.audio_controller).count(&"failure_1"), 1)


func test_reset_invalidates_an_old_hazard_sink_continuation() -> void:
	var main = _playing_main()
	main.ball.sink_animation_duration = 2.0
	main._on_reset_hazard_body_entered(main.ball, main.ball.global_position, &"water")
	assert_true(main.hazard_resetting)
	main._reset_current_level()
	assert_false(main.hazard_resetting)
	var changed_position: Vector2 = main.ball.global_position + Vector2(23.0, 0.0)
	main.ball.global_position = changed_position
	main.ball.hazard_sink_finished.emit()
	assert_eq(main.ball.global_position, changed_position, "Old continuation must not reset a later shot")
	assert_eq(main.run_state.strokes, 1, "Hazard cost remains exactly once")
	assert_eq(main.run_stats.manual_resets, 1)


func test_new_run_cleans_old_motion_audio_and_restores_run_intro_music() -> void:
	var main = _playing_main()
	main.audio_controller.set_biome(5)
	main.audio_controller.update_ball_roll(1400.0, true)
	main.audio_controller._process(1.0)
	main._start_normal_run(555)
	assert_eq(main.get_run_phase_name(), "RUN_START")
	assert_eq(main.audio_controller.music_state, &"menu")
	assert_eq(main.audio_controller.movement_intensity, 0.0)
	assert_false(main.ball.shot_in_progress)
	assert_false(main.ball.sunk)
	for player in main.audio_controller.sfx_players + main.audio_controller.ambience_players:
		assert_null(player.stream)


func test_shot_semantics_reach_audio_and_accounting_once() -> void:
	var main = _playing_main()
	watch_signals(main.audio_controller)
	main.ball.shot_started.emit(main.ball.global_position, Vector2.RIGHT, 0.5)
	assert_eq(main.run_state.strokes, 1)
	assert_eq(_cues(main.audio_controller), [&"golf_strike"])
	assert_false(main.feedback_director.has_signal("sound_requested"))


func test_speed_decision_is_bounded_continuous_and_rejects_nonfinite_values() -> void:
	for speed in [-10.0, 0.0, 519.0, INF, NAN]:
		assert_eq(GameAudioController.movement_amount(speed), 0.0)
	var previous := 0.0
	for speed in range(520, 2001, 10):
		var amount := GameAudioController.movement_amount(speed)
		assert_between(amount, previous, 1.0)
		previous = amount


func test_boost_samples_cover_actual_minimum_medium_and_maximum_launches() -> void:
	var audio := GameAudioController.new()
	add_child_autofree(audio)
	watch_signals(audio)
	for pair in [[0.0, &"boost_low"], [900.0, &"boost_medium"], [1450.0, &"boost_high"]]:
		var velocity := GameplayHazard.deterministic_bounce_velocity(Vector2.RIGHT * pair[0], 41, 0)
		audio.stop_transient_audio()
		audio.play_boost_pad(velocity.length() / GameplayHazard.MAX_BOUNCE_SPEED)
		assert_eq(_cues(audio).back(), pair[1], "Real launch strength must reach its supplied sound")


func test_ball_reset_cancels_queued_and_running_sink_animations() -> void:
	var ball = preload("res://scenes/golf_ball.tscn").instantiate()
	add_child_autofree(ball)
	ball.sink_animation_duration = 0.06
	var reset_position := Vector2(80, 40)
	ball.sink_for_reset(Vector2(300, 300))
	ball.reset_to(reset_position)
	await wait_seconds(0.16)
	assert_false(ball.sunk, "A deferred old sink must not start after reset")
	assert_true(ball.visible)
	assert_eq(ball.global_position, reset_position)
	ball.sink_to(Vector2(500, 500))
	await wait_process_frames(2)
	ball.reset_to(reset_position)
	await wait_seconds(0.16)
	assert_true(ball.visible, "A cancelled sink cannot hide a later shot")
	assert_eq(ball.scale, Vector2.ONE)
	assert_eq(ball.global_position, reset_position)


func test_audio_stop_then_same_menu_request_restarts_a_single_valid_state() -> void:
	var audio := GameAudioController.new()
	add_child_autofree(audio)
	watch_signals(audio)
	audio.play_menu_music()
	assert_signal_not_emitted(audio, "music_state_changed")
	audio.stop_all_audio()
	audio.play_menu_music()
	assert_signal_emit_count(audio, "music_state_changed", 1)
	assert_eq(audio.music_state, &"menu")
	assert_eq(audio.music_players.filter(func(p): return p.stream != null).size(), 1)


func test_audio_ui_binding_is_scoped_and_rebinding_disconnects_old_buttons() -> void:
	var audio := GameAudioController.new()
	add_child_autofree(audio)
	var first := Button.new()
	var second := Button.new()
	add_child_autofree(first)
	add_child_autofree(second)
	audio.bind_ui(first)
	watch_signals(audio)
	second.pressed.emit()
	assert_signal_not_emitted(audio, "cue_requested")
	first.pressed.emit()
	assert_signal_emit_count(audio, "cue_requested", 1)
	audio.bind_ui(second)
	first.pressed.emit()
	assert_signal_emit_count(audio, "cue_requested", 1)
	second.pressed.emit()
	assert_signal_emit_count(audio, "cue_requested", 2)


func test_pause_retains_music_state_and_stops_swoosh_without_restarting() -> void:
	var audio := GameAudioController.new()
	add_child_autofree(audio)
	audio.set_biome(2)
	var active_stream: AudioStream = audio.music_players[audio.active_music_player_index].stream
	watch_signals(audio)
	audio.update_ball_roll(1400.0, true)
	audio._process(0.2)
	audio.set_gameplay_paused(true)
	assert_eq(audio.movement_intensity, 0.0)
	audio.set_gameplay_paused(false)
	assert_same(audio.music_players[audio.active_music_player_index].stream, active_stream)
	assert_signal_not_emitted(audio, "music_state_changed")


func test_failure_suppresses_late_success_but_new_hole_clears_guard() -> void:
	var audio := GameAudioController.new()
	add_child_autofree(audio)
	watch_signals(audio)
	audio.play_failure()
	audio.play_cup_sink()
	audio.play_hole_outcome(true)
	assert_eq(_cues(audio), [&"failure_1", &"failure_2", &"crowd_failure"])
	audio.stop_transient_audio()
	audio.play_cup_sink()
	assert_eq(_cues(audio).back(), &"cup_sink")


func test_all_audio_settings_persist_and_target_the_real_buses() -> void:
	var saved: Array[Dictionary] = []
	for name in [&"Master", &"Music", &"SFX"]:
		var index := AudioServer.get_bus_index(name)
		saved.append({"index": index, "db": AudioServer.get_bus_volume_db(index), "mute": AudioServer.is_bus_mute(index)})
	var settings := GameSettings.new()
	settings.master_volume = 0.37
	settings.music_volume = 0.24
	settings.sfx_volume = 0.62
	settings.master_muted = true
	settings.music_muted = true
	settings.sfx_muted = true
	var path := "user://structural_audio_overhaul_20260906/settings_test.cfg"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	assert_eq(settings.save_to(path), OK)
	var restored := GameSettings.new()
	assert_eq(restored.load_from(path), OK)
	restored.apply_runtime(false)
	for pair in [[&"Master", 0.37], [&"Music", 0.24], [&"SFX", 0.62]]:
		var index := AudioServer.get_bus_index(pair[0])
		assert_almost_eq(db_to_linear(AudioServer.get_bus_volume_db(index)), pair[1], 0.001)
		assert_true(AudioServer.is_bus_mute(index))
	restored.reset_to_defaults()
	restored.apply_runtime(false)
	for pair in [[&"Master", 1.0], [&"Music", 0.72], [&"SFX", 0.9]]:
		var index := AudioServer.get_bus_index(pair[0])
		assert_almost_eq(db_to_linear(AudioServer.get_bus_volume_db(index)), pair[1], 0.001)
		assert_false(AudioServer.is_bus_mute(index))
	for bus in saved:
		AudioServer.set_bus_volume_db(bus.index, bus.db)
		AudioServer.set_bus_mute(bus.index, bus.mute)


func _playing_main() -> Variant:
	var main = MainScene.instantiate()
	add_child_autofree(main)
	main.set_process(false)
	main.run_state.difficulty_profile = Difficulties.get_profile(&"normal")
	main._start_normal_run(424242)
	main._on_interstitial_continue_pressed()
	main._on_interstitial_continue_pressed()
	return main


func _cues(audio: GameAudioController) -> Array:
	var result: Array = []
	for index in range(get_signal_emit_count(audio, "cue_requested")):
		result.append(get_signal_parameters(audio, "cue_requested", index)[0])
	return result
