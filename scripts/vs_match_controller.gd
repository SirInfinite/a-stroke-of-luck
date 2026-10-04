class_name VsMatchController
extends Node
## Scene-local VS orchestration. Main retains all gameplay/outcome accounting.
var main: Node2D
var match_state: VsMatchState
var view: VsPresentation
var selected_opponent: StringName = &""
var model: AICourseModel
var planner := AIShotPlanner.new()
var decision: Dictionary = {}
var decisions: Array[Dictionary] = []
var ai_picks: Array[CardDefinition] = []
var decision_index := 0
var think_remaining := 0.0
var _aim_start_angle := 0.0
var watch_speed := 1
var skipping := false
var status := ""
var _base_ticks := 60
var _base_steps := 8
var _base_scale := 1.0
var _generation := 0
var _debug_copy: Label


func setup(composition_root: Node2D) -> void:
	main = composition_root
	view = VsPresentation.new()
	view.setup(main.hud_canvas_layer, main.RELEASE_THEME)
	if OS.is_debug_build():
		_debug_copy = Label.new()
		_debug_copy.name = "AIDiagnostics"
		main.debug_hud.add_child(_debug_copy)
	view.mode_selected.connect(_select_mode)
	view.opponent_selected.connect(_select_opponent)
	view.back_requested.connect(func() -> void: view.hide_page(); main.menu_play_button.grab_focus())
	view.continue_requested.connect(_continue)
	view.speed_requested.connect(set_watch_speed)
	view.skip_requested.connect(func() -> void: skipping = true; set_watch_speed(8))
	view.rematch_requested.connect(_rematch)
	view.new_opponent_requested.connect(_new_opponent)
	view.menu_requested.connect(return_to_menu)
	main.ball.shot_finished.connect(_shot_finished)
	main.ball.wall_impact.connect(func(_strength: float, _position: Vector2) -> void:
		if is_ai_turn() and not decisions.is_empty():
			decisions.back()["actual_bank"] = true)
	main.level_builder.bounce_pad_triggered.connect(func(_strength: float, _type: StringName, _position: Vector2) -> void:
		if is_ai_turn() and not decisions.is_empty():
			decisions.back()["actual_pad"] = true)


func is_active() -> bool:
	return match_state != null


func is_ai_turn() -> bool:
	return is_active() and match_state.turn == VsMatchState.Turn.OPPONENT


func start(opponent_id: StringName) -> void:
	_base_ticks = Engine.physics_ticks_per_second
	_base_steps = Engine.max_physics_steps_per_frame
	_base_scale = Engine.time_scale
	match_state = VsMatchState.new(main.run_state, opponent_id)
	main.shop_manager.shared_course_mode = true
	decision_index = 0
	decisions.clear()
	view.hide_page()


func cancel() -> void:
	_generation += 1
	if is_active():
		main.run_state = match_state.player
		main.shop_manager.bind_run_state(main.run_state)
		_restore_clock()
	match_state = null
	decision.clear()
	if model:
		model.dispose()
		model = null
	if main and main.ball and main.ball.is_node_ready():
		main.ball.set_external_control(false)
	if main and main.shop_manager:
		main.shop_manager.shared_course_mode = false
	if view:
		view.hide_page()
		view.match_bar.hide()
	if _debug_copy:
		_debug_copy.text = ""
	skipping = false
	watch_speed = 1


func player_hole_started() -> void:
	match_state.turn = VsMatchState.Turn.PLAYER
	match_state.opponent.strokes = 0
	decision.clear()
	view.hide_page()
	main.ball.set_external_control(false)
	main._refresh_card_effects()
	if model:
		model.dispose()
		model = null


func turn_resolved() -> void:
	decision.clear()
	var success: bool = not main.run_state.last_hole_forced
	if match_state.turn == VsMatchState.Turn.PLAYER:
		_begin_opponent_turn()
	elif match_state.turn == VsMatchState.Turn.OPPONENT:
		match_state.opponent.transition_to(RunState.Phase.HOLE_RESULTS)
		match_state.finish_hole()
		_restore_clock()
		main.run_state = match_state.player
		main.shop_manager.bind_run_state(main.run_state)
		main.ball.set_external_control(false)
		main._refresh_card_effects()
		main._show_hole_results()
	# Play after turn cleanup; otherwise that cleanup immediately silences the
	# player's result cue. Capture the outcome before swapping RunStates.
	main.audio_controller.play_hole_outcome(success, &"cup" if success else &"par_plus_four")


func _begin_opponent_turn() -> void:
	var token := _generation
	status = "YOU: %d STROKES  /  %s'S TURN" % [match_state.player.strokes, match_state.profile.short_name]
	# Stop old area notifications from becoming the other golfer's penalties.
	main.transition_generation += 1
	main.feedback_director.reset_feedback()
	main.audio_controller.stop_transient_audio()
	main._clear_hazard_effects()
	main.run_state = match_state.opponent
	main.run_state.level_index = match_state.player.level_index
	main.run_state.strokes = 0
	main.run_state.level_elapsed = 0.0
	main.run_state.invalidate_shot_refund()
	main._set_run_phase(RunState.Phase.PREPARE_HOLE)
	match_state.turn = VsMatchState.Turn.OPPONENT
	main.ball.set_external_control(true, match_state.profile.accent)
	main._refresh_card_effects()
	main.level_builder.reset_for_competitor()
	var definition := match_state.course_definition(main.run_state.level_index)
	var start: Vector2 = main.level_builder.level_point(definition, "start", "start_cell")
	main.ball.configure_level(definition)
	main.ball.reset_to(start, int(definition.get("start_elevation", 0)), true)
	main.camera.reset_for_hole(main.level_builder.get_playable_bounds())
	main.last_safe_shot_position = start
	main.last_safe_shot_elevation = int(definition.get("start_elevation", 0))
	main._cancel_out_of_bounds_recovery()
	await get_tree().physics_frame
	await get_tree().physics_frame
	if token != _generation or not is_ai_turn():
		return
	main._clear_hazard_effects()
	main.ball.configure_prediction_terrain(main._terrain_damp(main.SAND_DAMP), main._terrain_entry_speed_scale(main.SAND_ENTRY_SPEED_SCALE))
	model = AICourseModel.new()
	model.configure(main.level_builder, main.ball, main.run_state)
	main._set_run_phase(RunState.Phase.HOLE_PLAY)
	main._update_status()
	think_remaining = 0.5
	set_watch_speed(1)


func _physics_process(delta: float) -> void:
	if not is_active():
		return
	var playing: bool = main._is_hole_play_active()
	view.update_match(match_state, status, playing, watch_speed)
	if not is_ai_turn() or not playing or not model:
		if main.run_state.menu_paused:
			_restore_clock()
		return
	_apply_clock()
	if not main.ball.can_shoot():
		return
	if think_remaining > 0.0:
		think_remaining -= delta
		if not decision.is_empty() and think_remaining < match_state.profile.preparation_time:
			var progress := clampf(1.0 - think_remaining / match_state.profile.preparation_time, 0.0, 1.0)
			if not UIStyle.motion_enabled(view.match_bar):
				progress = 1.0
			var eased := smoothstep(0.0, 1.0, progress)
			var angle := lerp_angle(_aim_start_angle, Vector2(decision.direction).angle(), eased)
			main.ball.set_external_aim(Vector2.from_angle(angle), lerpf(0.08, float(decision.power), eased))
		return
	if decision.is_empty():
		model.refresh(main.level_builder, main.ball, main.run_state)
		var seed_value := ("ai/v1/%d/%s/%d/%d" % [main.run_state.run_seed, match_state.profile.id, main.run_state.level_index, decision_index]).hash()
		decision = planner.plan(model, main.ball.global_position, main.ball.current_elevation, match_state.profile, seed_value)
		if _debug_copy:
			_debug_copy.text = "AI %s  /  %d candidates  /  %.0f ms\nAngle %.1f°  Power %.0f%%  Score %.1f\nPredicted %s" % [match_state.profile.id, decision.candidate_count, decision.decision_ms, rad_to_deg(Vector2(decision.direction).angle()), float(decision.power) * 100.0, decision.score, decision.forecast.endpoint]
		decision_index += 1
		# Move the golfer's aim/pullback, never the resting ball. Shot timing stays
		# identical to the planner's observable hazard-phase forecast.
		_aim_start_angle = Vector2(decision.direction).angle() - 0.22
		think_remaining = AIShotPlanner.AIM_TIME + float(decision.wait)
		status = "%s is lining up the shot…" % match_state.profile.short_name.capitalize()
		if skipping:
			status = "PLAYING OUT THE TURN…"
		return
	if main.ball.shoot_normalized(decision.direction, float(decision.power)):
		decisions.append(planner.diagnostics.duplicate(true))
		decisions.back()["actual_bank"] = false
		decisions.back()["actual_pad"] = false
		status = "%s  /  SHOT %d" % [match_state.profile.short_name, main.run_state.strokes]
	decision.clear()
	think_remaining = 0.25


func _shot_finished() -> void:
	if is_ai_turn() and not decisions.is_empty():
		decisions.back()["actual_endpoint"] = main.ball.global_position
		if _debug_copy:
			_debug_copy.text += "\nActual %s" % main.ball.global_position
		decision.clear()


func choose_shop_cards() -> void:
	# Called at shop OPEN: no access to what the player later chooses.
	var shop := ShopManager.new()
	shop.bind_run_state(match_state.opponent)
	shop.current_shop_cards = main.shop_manager.current_shop_cards.duplicate()
	shop.current_max_purchases = main.shop_manager.current_max_purchases
	shop.card_bought.connect(match_state.opponent.add_card)
	ai_picks = AICardPicker.choose(shop, match_state)
	shop.free()


func shop_continued() -> void:
	view.show_ai_cards(match_state, ai_picks)


func set_watch_speed(value: int) -> void:
	if not is_ai_turn() or value not in [1, 2, 4, 8]:
		return
	watch_speed = value
	_apply_clock()


func _apply_clock() -> void:
	# The increased tick rate keeps each physics step identical at all speeds.
	Engine.time_scale = _base_scale * watch_speed
	Engine.physics_ticks_per_second = _base_ticks * watch_speed
	Engine.max_physics_steps_per_frame = _base_steps * watch_speed


func _restore_clock() -> void:
	Engine.time_scale = _base_scale
	Engine.physics_ticks_per_second = _base_ticks
	Engine.max_physics_steps_per_frame = _base_steps


func _exit_tree() -> void:
	if is_active():
		_restore_clock()
	if model:
		model.dispose()


func _select_mode(vs_ai: bool) -> void:
	selected_opponent = &""
	if vs_ai:
		view.show_opponents()
	else:
		view.hide_page()
		main.run_setup_screen.open()


func _select_opponent(id: StringName) -> void:
	selected_opponent = id
	view.hide_page()
	main.run_setup_screen.open(AIDifficultyProfile.get_profile(id).display_name)


func _continue() -> void:
	var page_id := view.page_id
	view.hide_page()
	if page_id == &"ai_cards":
		main._finish_shop_transition()
	elif page_id == &"hole_comparison":
		main._advance_after_hole_results()


func _rematch() -> void:
	var seed_value := match_state.player.run_seed
	var id := match_state.profile.id
	main._start_normal_run(seed_value, id)


func _new_opponent() -> void:
	return_to_menu()
	view.show_opponents()


func return_to_menu() -> void:
	cancel()
	main._reset_run_state()
	main._hide_interstitial()
	main._show_main_menu()
