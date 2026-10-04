extends GutTest


func _match() -> VsMatchState:
	var player := RunState.new()
	player.difficulty_profile = DifficultyDatabase.get_profile(&"normal")
	player.reset(424242)
	for index in 18:
		player.levels.append({"pending": true})
	return VsMatchState.new(player, &"woods")


func _card(id: StringName) -> CardDefinition:
	for card in CardDatabase.get_cards():
		if card.id == id:
			return card
	return null


func test_every_effect_kind_has_explicit_vs_scope() -> void:
	var known := MatchCourseRules.COURSE_KINDS + MatchCourseRules.PERSONAL_KINDS
	assert_eq(known.size(), CardEffectSet.Kind.size())
	for kind in CardEffectSet.Kind.values():
		assert_eq(known.count(kind), 1)


func test_either_owners_course_curse_reaches_one_shared_definition() -> void:
	var base_radius := float(_match().prepare_course(3).cup_radius)
	for owner_index in 2:
		var session := _match()
		var owner_state := session.player if owner_index == 0 else session.opponent
		owner_state.add_card(_card(&"power_club"))
		owner_state.add_card(_card(&"lucky_putter"))
		var level := session.prepare_course(3)
		assert_false(level.is_empty())
		assert_eq(level, session.player.levels[3])
		assert_eq(level, session.opponent.levels[3])
		assert_eq(int(level.card_hazard_count), 1)
		assert_almost_eq(float(level.cup_radius), base_radius * 0.6875, 0.001)
		assert_true(LevelValidator.validate_level(level, 3, false))


func test_combination_is_commutative_deterministic_and_clamped() -> void:
	var session := _match()
	for index in 8:
		session.player.add_card(_card(&"power_club"))
		session.opponent.add_card(_card(&"lucky_putter"))
	var resolved := MatchCourseRules.resolve(session.player, session.opponent)
	assert_eq(resolved, MatchCourseRules.resolve(session.opponent, session.player))
	assert_eq(int(resolved.added_hazard_count), 4)
	assert_almost_eq(float(resolved.cup_radius_scale), 0.55, 0.001)
	var definition := session.prepare_course(14)
	assert_true(LevelValidator.validate_level(definition, 14, false))
	var repeated := _match()
	for index in 8:
		repeated.opponent.add_card(_card(&"power_club"))
		repeated.player.add_card(_card(&"lucky_putter"))
	assert_eq(definition, repeated.prepare_course(14))


func test_cached_course_cannot_be_mutated_or_regenerated_between_turns() -> void:
	var session := _match()
	var first := session.prepare_course(0)
	var copy := session.course_definition(0)
	copy.hazards.clear()
	copy.cup_radius = 999
	session.player.add_card(_card(&"power_club"))
	session.turn = VsMatchState.Turn.OPPONENT
	assert_eq(session.prepare_course(0), first)
	assert_eq(session.course_generation_count, 1)
	assert_eq(session.course_definition(0), first)
	assert_eq(session.turn, VsMatchState.Turn.OPPONENT)


func test_personal_effects_wallets_and_curse_expiry_stay_private() -> void:
	var session := _match()
	session.player.add_card(_card(&"overdrive_driver"))
	session.player.tokens = 17
	assert_eq(session.opponent.tokens, 2)
	assert_gt(session.player.impulse_modifier, session.opponent.impulse_modifier)
	assert_eq(session.opponent.impulse_modifier, 1.0)
	assert_true(session.opponent.active_card_curses.is_empty())
	assert_eq(MatchCourseRules.resolve(session.player, session.opponent), MatchCourseRules.resolve(_match().player, _match().opponent))
	session.opponent.add_card(_card(&"lucky_putter"))
	var remaining := session.opponent.active_card_curses[0].remaining_holes
	session.player.advance_curses()
	assert_eq(session.opponent.active_card_curses[0].remaining_holes, remaining)


func test_shared_resolver_does_not_change_solo_resolution() -> void:
	var session := _match()
	session.player.add_card(_card(&"power_club"))
	var before := CardEffectResolver.resolve(session.player.owned_card_definitions, session.player.active_card_curses, 1.25)
	session.opponent.add_card(_card(&"lucky_putter"))
	MatchCourseRules.resolve(session.player, session.opponent)
	var after := CardEffectResolver.resolve(session.player.owned_card_definitions, session.player.active_card_curses, 1.25)
	assert_eq(before.hazard_count_delta, after.hazard_count_delta)
	assert_eq(before.cup_radius_scale_delta, after.cup_radius_scale_delta)
	assert_eq(after.cup_radius_scale_delta, 0.0)
	assert_eq(before.shot_power_delta, after.shot_power_delta)


func test_scores_use_strokes_before_time_and_duplicate_results_are_rejected() -> void:
	assert_eq(VsMatchState.compare_scores(2, 3, 100.0, 1.0), -1)
	assert_eq(VsMatchState.compare_scores(3, 3, 100.0, 1.0), 1)
	assert_eq(VsMatchState.compare_scores(3, 3, 1.01, 1.02), 0)
	var session := _match()
	session.prepare_course(0)
	session.player.strokes = 2
	session.opponent.strokes = 3
	session.turn = VsMatchState.Turn.OPPONENT
	assert_eq(int(session.finish_hole().winner), -1)
	assert_true(session.finish_hole().is_empty())
	assert_eq(session.hole_results.size(), 1)


func test_ai_uses_same_shop_transactions_offers_and_private_wallet() -> void:
	var session := _match()
	session.opponent.tokens = 20
	var shop := ShopManager.new()
	add_child_autofree(shop)
	shop.bind_run_state(session.opponent)
	shop.current_shop_cards = CardDatabase.get_cards()
	shop.current_max_purchases = 3
	shop.card_bought.connect(session.opponent.add_card)
	var offers := shop.current_shop_cards.duplicate()
	var picked := AICardPicker.choose(shop, session)
	assert_false(picked.is_empty())
	assert_eq(shop.current_shop_cards, offers)
	assert_eq(session.player.tokens, 2)
	assert_true(session.player.owned_card_definitions.is_empty())
	assert_eq(picked.size(), session.opponent.owned_card_definitions.size())
	var spent := 0
	for card in picked:
		spent += card.price
	assert_eq(session.opponent.tokens, 20 - spent)
	assert_false(shop.try_purchase_card(shop.purchased_card_indices[0]))


func test_course_curse_disclosure_is_vs_only() -> void:
	var card := UICard.new()
	add_child_autofree(card)
	card.configure_card(_card(&"power_club"), true, false, 0, 1.25, true)
	assert_true(card.tooltip_text.contains("affects both golfers"))
	assert_true(String(card.curse_panel.get_node("Margin/Row/Copy/Heading").text).contains("COURSE CURSE"))
	card.configure_card(_card(&"power_club"), true, false)
	assert_false(card.tooltip_text.contains("affects both golfers"))


func test_ai_card_choice_uses_shared_marginal_cost_and_is_deterministic() -> void:
	var session := _match()
	var card := _card(&"power_club")
	var initial := AICardPicker.value_for(card, session)
	for index in 4:
		session.player.add_card(card)
	var saturated := AICardPicker.value_for(card, session)
	assert_gt(saturated, initial, "A shared curse at its existing cap adds no new physical downside")
	assert_true(session.opponent.owned_card_definitions.is_empty(), "Evaluation cannot purchase or mutate ownership")
	var selections: Array = []
	for attempt in 2:
		var repeated := _match()
		repeated.opponent.tokens = 20
		var shop := ShopManager.new()
		shop.bind_run_state(repeated.opponent)
		shop.current_shop_cards = CardDatabase.get_cards()
		shop.current_max_purchases = 3
		shop.card_bought.connect(repeated.opponent.add_card)
		var ids: Array[StringName] = []
		for picked in AICardPicker.choose(shop, repeated):
			ids.append(picked.id)
		selections.append(ids)
		shop.free()
	assert_eq(selections[0], selections[1])


func test_shared_course_survives_expiry_and_next_hole_resolves_fresh() -> void:
	var session := _match()
	session.player.add_card(_card(&"power_club"))
	session.opponent.add_card(_card(&"lucky_putter"))
	for owner_state in [session.player, session.opponent]:
		owner_state.active_card_curses[0].remaining_holes = 1
	var course := session.prepare_course(3)
	session.player.advance_curses()
	assert_eq(session.course_definition(3), course)
	session.opponent.advance_curses()
	assert_eq(session.prepare_course(3), course)
	var next := session.prepare_course(4)
	assert_eq(int(next.match_course_modifiers.added_hazard_count), 0)
	assert_eq(float(next.match_course_modifiers.cup_radius_scale), 1.0)
	assert_gt(session.player.impulse_modifier, 1.0, "Persistent private benefit remains")


func test_runtime_reset_restores_movers_pad_and_ramp_without_rebuilding() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	var builder := LevelBuilder.new()
	holder.add_child(builder)
	var definition := {"map": ["########", "########", "########", "########", "########"], "start_cell": Vector2i(1, 2), "hole_cell": Vector2i(6, 2), "par": 3, "hazards": [], "obstacles": []}
	var course := builder.build_level(definition, holder)
	# Fixtures exercise each runtime reset owner through the actual builder hook.
	var pendulum := MovingHazard.new()
	pendulum.configure({"type": "pendulum", "period": 2.8, "phase": 0.25})
	course.add_child(pendulum)
	pendulum.setup_collision(Vector2(40, 40), true)
	var ice := MovingHazard.new()
	ice.configure({"type": "falling_ice"})
	course.add_child(ice)
	ice.setup_collision(Vector2(100, 100))
	var pad := GameplayHazard.new()
	pad.configure({"type": "bounce_pad", "seed": 321, "size": Vector2(80, 80)})
	course.add_child(pad)
	var ramp := ElevationRamp.new()
	ramp.configure(Vector2.ZERO, Vector2(100, 0), 0, 1)
	course.add_child(ramp)
	var warning := HazardTelegraph.new()
	course.add_child(warning)
	assert_false(ramp.has_method("reset_state"), "Do not change Solo's generic reset dispatch")
	assert_false(warning.has_method("reset_state"), "VS presentation reset must not change Solo")
	var root_id := course.get_instance_id()
	var frozen := builder.active_level.duplicate(true)
	builder.set_gameplay_simulation_paused(true)
	pendulum.advance_cycle(1.1)
	ice.fall_state = MovingHazard.FALL_LANDED
	ice.fall_elapsed = 2.0
	pad._trigger_count = 6
	pad._body_cooldowns[123] = 1.0
	ramp._tracked_bodies[123] = holder
	warning.fall_triggered = true
	warning.hide()
	builder.reset_for_competitor()
	await wait_physics_frames(2)
	assert_eq(builder.level_root.get_instance_id(), root_id)
	assert_eq(builder.active_level, frozen)
	assert_almost_eq(pendulum.elapsed, 0.7, 0.00001)
	assert_eq(ice.fall_state, MovingHazard.FALL_ARMED)
	assert_eq(ice.fall_elapsed, 0.0)
	assert_true(ice.collision_shape.disabled)
	assert_eq(pad._trigger_count, 0)
	assert_true(pad._body_cooldowns.is_empty())
	assert_true(ramp._tracked_bodies.is_empty())
	assert_false(warning.fall_triggered)
	assert_true(warning.visible)


func test_opponents_have_ordered_search_and_error_profiles() -> void:
	var last_samples := 0
	var last_error := 100.0
	for id in AIDifficultyProfile.IDS:
		var profile := AIDifficultyProfile.get_profile(id)
		assert_gt(profile.angle_samples * profile.power_samples, last_samples)
		assert_lt(profile.aim_error + profile.power_error, last_error)
		last_samples = profile.angle_samples * profile.power_samples
		last_error = profile.aim_error + profile.power_error


func test_player_outcome_audio_survives_turn_cleanup_without_changing_owner() -> void:
	var main = preload("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	for forced in [false, true]:
		main._start_normal_run(424242, &"woods")
		main._load_level(0)
		main.vs_controller.set_physics_process(false)
		main.audio_controller.stop_transient_audio()
		main._complete_current_hole(false, forced)
		var cues: Dictionary = main.audio_controller.last_cue_time_msec
		assert_true(cues.has(&"crowd_failure") if forced else cues.has(&"crowd_success"), "Turn cleanup must not clear the player's outcome cue")
		assert_false(cues.has(&"crowd_success") if forced else cues.has(&"crowd_failure"))
		assert_eq(main.run_state, main.vs_controller.match_state.opponent)
		await wait_physics_frames(3)
		main.vs_controller.return_to_menu()
	await wait_process_frames(2)


func test_turn_reset_keeps_physical_root_definition_and_player_accounting() -> void:
	var main = preload("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	main._start_normal_run(424242, &"woods")
	main._load_level(0)
	main.vs_controller.set_physics_process(false)
	var session: VsMatchState = main.vs_controller.match_state
	var root_id: int = main.level_root.get_instance_id()
	var definition: Dictionary = main.level_builder.active_level.duplicate(true)
	session.player.add_card(_card(&"overdrive_driver"))
	session.opponent.add_card(_card(&"rangefinder_lens"))
	main._refresh_card_effects()
	main.ball.shot_started.emit(main.ball.position, Vector2.RIGHT, 0.5)
	main._complete_current_hole(false, false)
	await wait_physics_frames(4)
	assert_true(main.vs_controller.is_ai_turn())
	assert_eq(main.run_state, session.opponent)
	assert_eq(main.level_root.get_instance_id(), root_id)
	assert_eq(main.level_builder.active_level, definition)
	assert_eq(session.course_generation_count, 1)
	assert_eq(session.player.strokes, 1)
	assert_eq(session.opponent.strokes, 0)
	assert_true(main.ball.external_controlled)
	assert_almost_eq(float(main.ball.impulse_multiplier), session.opponent.impulse_modifier, 0.0001)
	assert_true(main.level_builder.tee_marker.visible)
	main.ball.shot_started.emit(main.ball.position, Vector2.RIGHT, 0.4)
	assert_eq(session.player.strokes, 1)
	assert_eq(session.opponent.strokes, 1)
	main._complete_current_hole(false, false)
	assert_eq(main.run_state, session.player)
	assert_almost_eq(float(main.ball.impulse_multiplier), session.player.impulse_modifier, 0.0001)
	assert_eq(main.get_run_phase_name(), "HOLE_RESULTS")
	assert_eq(session.hole_results.size(), 1)
	assert_eq(main.vs_controller.view.page_id, &"hole_comparison")
	main.vs_controller.set_watch_speed(4)
	main.vs_controller.return_to_menu()
	assert_eq(Engine.time_scale, 1.0)
	assert_eq(Engine.physics_ticks_per_second, 60)
	assert_false(main.ball.external_controlled)
	assert_false(main.vs_controller.is_active())


func test_ai_planner_submits_legal_non_maximum_shot_on_simple_course() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	var builder := LevelBuilder.new()
	holder.add_child(builder)
	var definition := {"map": ["########", "########", "########"], "start_cell": Vector2i(1, 1), "hole_cell": Vector2i(6, 1), "par": 3, "hazards": [], "obstacles": []}
	builder.build_level(definition, holder)
	var ball = preload("res://scenes/golf_ball.tscn").instantiate()
	holder.add_child(ball)
	ball.reset_to(builder.level_point(definition, "start", "start_cell"), 0, true)
	await wait_physics_frames(3)
	var state := _match().opponent
	var model := AICourseModel.new()
	model.configure(builder, ball, state)
	var planner := AIShotPlanner.new()
	var choice := planner.plan(model, ball.position, 0, AIDifficultyProfile.get_profile(&"woods"), 123)
	print("[AI SIMPLE] ", planner.diagnostics)
	assert_true(Vector2(choice.direction).is_finite())
	assert_between(float(choice.power), 0.015, 1.0)
	assert_lt(float(choice.power), 0.9)
	assert_true(choice.forecast.sunk)
	var duplicate := planner.plan(model, ball.position, 0, AIDifficultyProfile.get_profile(&"woods"), 123)
	assert_eq(choice.direction, duplicate.direction)
	assert_eq(choice.power, duplicate.power)
	assert_true(ball.shoot_normalized(choice.direction, choice.power))
	assert_false(ball.shoot_normalized(choice.direction, choice.power))
	var cups := [0]
	builder.hole_body_entered.connect(func(_body: Node2D) -> void: cups[0] += 1)
	for frame in 360:
		await wait_physics_frames(1)
		if cups[0] > 0:
			break
	assert_eq(cups[0], 1, "Actual player physics reaches the cup, not just the forecast")
	model.dispose()


func test_query_respects_static_boundaries_and_avoids_obvious_water() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	var builder := LevelBuilder.new()
	holder.add_child(builder)
	var definition := {"map": ["########", "########", "########", "########", "########"], "start_cell": Vector2i(1, 2), "hole_cell": Vector2i(6, 2), "par": 3,
		"hazards": [{"type": "water", "pos": Vector2(-50, 0), "size": Vector2(100, 100), "elevation": 0}], "obstacles": []}
	assert_not_null(builder.build_level(definition, holder))
	var ball = preload("res://scenes/golf_ball.tscn").instantiate()
	holder.add_child(ball)
	ball.reset_to(builder.level_point(definition, "start", "start_cell"), 0, true)
	await wait_physics_frames(3)
	var model := AICourseModel.new()
	model.configure(builder, ball, _match().opponent)
	var wall := model.predict(ball.position, 0, Vector2.LEFT, 1.0)
	assert_gt(int(wall.bounces), 0, "Prediction must query the actual ground collision layer")
	assert_true(model.cells.has(model.cell_at(wall.endpoint, 0)), "The rebound remains within the physical course")
	var direct := model.predict(ball.position, 0, Vector2.RIGHT, 0.7)
	assert_true(direct.reset)
	var choice := AIShotPlanner.new().plan(model, ball.position, 0, AIDifficultyProfile.get_profile(&"woods"), 123)
	assert_false(choice.forecast.reset, "The safe detour must outrank obvious water")
	assert_gt(model.remaining_distance(ball.position, 0), model.remaining_distance(choice.forecast.endpoint, choice.forecast.elevation))
	model.dispose()


func test_vs_pause_speed_oob_and_cancel_keep_player_state_safe() -> void:
	var main = preload("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	main._start_normal_run(424242, &"palmer")
	main._load_level(0)
	main.vs_controller.set_physics_process(false)
	main._complete_current_hole(false, false)
	await wait_physics_frames(4)
	var session: VsMatchState = main.vs_controller.match_state
	var original_player := session.player.snapshot()
	for speed in [1, 2, 4, 8]:
		main.vs_controller.set_watch_speed(speed)
		assert_almost_eq(Engine.time_scale / Engine.physics_ticks_per_second, 1.0 / 60.0, 0.000001)
	main._show_main_menu()
	var time_before: float = session.opponent.level_elapsed
	main._physics_process(1.0)
	assert_eq(session.opponent.level_elapsed, time_before)
	assert_true(main.ball.simulation_paused)
	main._hide_main_menu()
	main.vs_controller.set_watch_speed(1)
	assert_true(main.ball.shoot_normalized(Vector2.RIGHT, 0.5))
	main.ball.position = Vector2(10000, 10000) # Test arrangement, never an AI operation.
	main._update_out_of_bounds_recovery(3.1)
	main._return_ball_from_out_of_bounds()
	assert_eq(session.opponent.strokes, 0)
	assert_eq(session.player.snapshot(), original_player)
	assert_eq(session.course_generation_count, 1)
	main.vs_controller.return_to_menu()
	assert_eq(Engine.time_scale, 1.0)
	assert_eq(Engine.physics_ticks_per_second, 60)


func test_forecast_observes_moving_phase_without_advancing_live_hazard() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	var builder := LevelBuilder.new()
	holder.add_child(builder)
	var definition := {"map": ["########", "########", "########", "########", "########"], "start_cell": Vector2i(1, 2), "hole_cell": Vector2i(6, 2), "par": 3, "hazards": [], "obstacles": []}
	var course := builder.build_level(definition, holder)
	var moving := MovingHazard.new()
	moving.configure({"type": "pendulum", "pos": Vector2(-50, -130), "period": 2.4, "phase": 0.0, "travel_radius": 130.0, "swing_angle": 1.2})
	course.add_child(moving)
	moving.setup_collision(Vector2(50, 50), true)
	var ball = preload("res://scenes/golf_ball.tscn").instantiate()
	holder.add_child(ball)
	ball.reset_to(builder.level_point(definition, "start", "start_cell"), 0, true)
	await wait_physics_frames(3)
	builder.set_gameplay_simulation_paused(true)
	var model := AICourseModel.new()
	model.configure(builder, ball, _match().opponent)
	var elapsed := moving.elapsed
	var risks := 0
	for sample in 16:
		var forecast := model.predict(ball.position, 0, Vector2.RIGHT, 0.5, sample * 0.15, 1.0 / 60.0)
		risks += int(forecast.reset)
	assert_between(risks, 1, 15, "Observable timing has both safe and unsafe launch windows")
	assert_eq(moving.elapsed, elapsed, "Querying future timing must not advance the real hazard")
	assert_gt(AIDifficultyProfile.get_profile(&"woods").timing_samples, AIDifficultyProfile.get_profile(&"palmer").timing_samples)
	model.dispose()


func test_complete_match_lifecycle_shops_results_and_rematch() -> void:
	var main = preload("res://scenes/main.tscn").instantiate()
	add_child_autofree(main)
	main._start_normal_run(424242, &"woods")
	main._load_level(0)
	main.vs_controller.set_physics_process(false)
	var session: VsMatchState = main.vs_controller.match_state
	for index in 18:
		assert_eq(main.run_state, session.player)
		assert_eq(main.run_state.level_index, index)
		main.run_state.record_accepted_shot()
		main._complete_current_hole(false, false)
		await wait_physics_frames(3)
		assert_eq(main.run_state, session.opponent)
		main.run_state.record_accepted_shot()
		main.run_state.record_accepted_shot()
		main._complete_current_hole(false, false)
		assert_eq(session.hole_results.size(), index + 1)
		main.vs_controller.view.continue_requested.emit()
		if index < 17 and index % 3 == 2:
			assert_eq(main.get_run_phase_name(), "SHOP")
			var offers: Array = main.shop_manager.current_shop_cards.duplicate()
			var ai_wallet := session.opponent.tokens
			main.shop_manager._on_shop_card_pressed(0)
			assert_eq(session.opponent.tokens, ai_wallet)
			assert_eq(main.shop_manager.current_shop_cards, offers)
			main.shop_manager._on_shop_continue_pressed()
			assert_eq(main.vs_controller.view.page_id, &"ai_cards")
			main.vs_controller.view.continue_requested.emit()
			assert_eq(main.get_run_phase_name(), "BIOME_INTRO")
			main._on_interstitial_continue_pressed()
	assert_eq(main.get_run_phase_name(), "RUN_RESULTS")
	assert_eq(main.vs_controller.view.page_id, &"match_results")
	assert_eq(session.course_generation_count, 18)
	assert_eq(session.player.stats.hole_history.size(), 18)
	assert_eq(session.opponent.stats.hole_history.size(), 18)
	assert_eq(session.player.total_strokes, 18)
	assert_eq(session.opponent.total_strokes, 36)
	var first_course := session.course_definition(0)
	main.vs_controller.view.rematch_requested.emit()
	assert_eq(main.run_state.run_seed, 424242)
	assert_eq(main.vs_controller.match_state.profile.id, &"woods")
	assert_eq(main.run_state.total_strokes, 0)
	main._load_level(0)
	assert_eq(main.vs_controller.match_state.course_definition(0), first_course)
	await wait_process_frames(2)
