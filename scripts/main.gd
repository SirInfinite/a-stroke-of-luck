extends Node2D

const BALL_SCENE := preload("res://scenes/golf_ball.tscn")
const CourseCameraScript := preload("res://scripts/course_camera.gd")
const LevelBuilderScript := preload("res://scripts/level_builder.gd")
const LevelDatabase := preload("res://scripts/level_database.gd")
const TutorialDatabase := preload("res://scripts/tutorial_database.gd")
const TutorialManagerScript := preload("res://scripts/tutorial_manager.gd")
const LevelValidator := preload("res://scripts/level_validator.gd")
const ShopManagerScript := preload("res://scripts/shop_manager.gd")
const BiomeDatabase := preload("res://scripts/biome_database.gd")
const HoleGenerator := preload("res://scripts/hole_generator.gd")
const ReleaseHUDScript := preload("res://scripts/release_hud.gd")
const ShopPresentationScript := preload("res://scripts/shop_presentation.gd")
const TransitionPresentationScript := preload("res://scripts/transition_presentation.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const UIIconScript := preload("res://scripts/ui/ui_icon.gd")
const UIBackdropScript := preload("res://scripts/ui/ui_backdrop.gd")
const UIActionButtonScript := preload("res://scripts/ui/ui_action_button.gd")
const UILogoScript := preload("res://scripts/ui/ui_logo.gd")
const SettingsScreenScript := preload("res://scripts/ui/settings_screen.gd")
const TitleAttractModeScript := preload("res://scripts/ui/title_attract_mode.gd")
const GameSettingsScript := preload("res://scripts/game_settings.gd")
const SeedCodecScript := preload("res://scripts/seed_codec.gd")
const DifficultyDatabaseScript := preload("res://scripts/difficulty_database.gd")
const RunSetupScreenScript := preload("res://scripts/ui/run_setup_screen.gd")
const HoleRatingScript := preload("res://scripts/hole_rating.gd")
const RELEASE_THEME := preload("res://assets/release_theme.tres")

const STARTING_TOKENS := RunState.STARTING_TOKENS
const BIOME_COUNT := 6
const HOLES_PER_BIOME := 3
const TOTAL_HOLES := BIOME_COUNT * HOLES_PER_BIOME
const MAX_STROKES_OVER_PAR := RunState.STROKES_OVER_PAR
const SAND_DAMP := 12.0
const SAND_ENTRY_SPEED_SCALE := 0.35
const DIRECTION_PUSH_FORCE := 950.0
const OUT_OF_BOUNDS_RETURN_SECONDS := 3.0

const RunPhase := RunState.Phase
const RUN_PHASE_NAMES := RunState.PHASE_NAMES

const PowerMeter := preload("res://scripts/ui/power_meter.gd")

var run_state := RunState.new()
var vs_controller: VsMatchController
var run_phase: RunState.Phase:
	get: return run_state.phase
var transition_generation := 0
@onready var feedback_director: FeedbackDirector = $FeedbackDirector
@onready var audio_controller: GameAudioController = $AudioController
var ball: RigidBody2D
var camera: CourseCamera
var level_builder
var level_root: Node2D
var normal_ball_linear_damp := 0.0
var active_sand_tiles := 0
var active_direction_pushes: Array[Vector2] = []
var hazard_resetting := false
var out_of_bounds_active := false
var out_of_bounds_shot_id := -1
var out_of_bounds_remaining := OUT_OF_BOUNDS_RETURN_SECONDS
var last_safe_shot_position := Vector2.ZERO
var last_safe_shot_elevation := 0
var score_label: Label
var effects_status_label: Label
var hole_label: Label
var stroke_label: Label
var par_label: Label
var timer_label: Label
var tokens_label: Label
var obstacles_label: Label
var aim_label: Label
var cards_label: Label
var power_debug_label: Label
var debug_hud: VBoxContainer
var debug_visible := false
var power_meter: PowerMeter
var hud_canvas_layer: CanvasLayer
var ui_appearance: UIAppearance
var menu_button: Button
var main_menu_overlay: PanelContainer
var main_menu_title_label: Label
var main_menu_logo: UILogo
var title_attract_mode: TitleAttractMode
var menu_resume_button: Button
var menu_play_button: Button
var menu_tutorial_button: Button
var menu_skip_button: Button
var menu_settings_button: Button
var menu_quit_button: Button
var settings_screen: SettingsScreen
var run_setup_screen: RunSetupScreen
var game_settings: GameSettings
var menu_pause_dim: ColorRect
var menu_pause_blur_material: ShaderMaterial
var menu_title_layout: HBoxContainer
var menu_brand_column: VBoxContainer
var menu_action_panel: PanelContainer
var interstitial_overlay: PanelContainer
var interstitial_title_label: Label
var interstitial_body_label: Label
var interstitial_continue_button: Button
var interstitial_menu_button: Button
var loading_next_level: bool:
	get: return run_phase == RunPhase.HOLE_RESOLVING
var shop_manager
var shop_presentation
var tutorial_manager
var release_hud
var transition_presentation
var biome_profiles: Array = BiomeDatabase.get_profiles()
var tutorial_levels: Array[Dictionary] = TutorialDatabase.get_levels()
var run_stats: RunStats:
	get: return run_state.stats


func _ready() -> void:
	game_settings = GameSettingsScript.new()
	game_settings.load_from()
	run_state.difficulty_profile = DifficultyDatabaseScript.get_profile(game_settings.last_difficulty)
	# Render/test harnesses own their viewport size; release launches still apply
	# the player's saved display mode and resolution before building the UI.
	game_settings.apply_runtime(not OS.get_cmdline_args().has("--script"))
	_create_world()
	_apply_player_settings()
	_reset_run_state()
	_present_run_phase()
	_show_main_menu()


func _process(delta: float) -> void:
	if _is_hole_play_active() and not vs_controller.is_active():
		run_state.update_time(delta)
	_update_camera_layout()
	if audio_controller and ball:
		audio_controller.update_ball_roll(ball.linear_velocity.length(), _is_hole_play_active() and ball.shot_in_progress)
	if not run_state.levels.is_empty() and run_state.level_index >= 0 and run_state.level_index < run_state.levels.size():
		_update_status()


func _physics_process(delta: float) -> void:
	if not _is_hole_play_active() or hazard_resetting:
		return
	if vs_controller.is_active():
		run_state.update_time(delta)
	_update_out_of_bounds_recovery(delta)

	for direction in active_direction_pushes:
		ball.apply_central_force(direction * DIRECTION_PUSH_FORCE * run_state.direction_push_modifier)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_course_overview") and _can_toggle_course_overview():
		_toggle_course_overview()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("reset_level") and _is_hole_play_active() and not vs_controller.is_ai_turn():
		_reset_current_level()
	if event.is_action_pressed("toggle_debug"):
		_toggle_debug_hud()


func _create_world() -> void:
	camera = CourseCameraScript.new()
	camera.name = "CourseCamera"
	camera.enabled = true
	add_child(camera)
	get_viewport().size_changed.connect(_update_camera_layout)

	ball = BALL_SCENE.instantiate()
	ball.shot_started.connect(_on_ball_shot_started)
	ball.shot_finished.connect(_on_ball_shot_finished)
	ball.ball_stopped.connect(feedback_director.play_stop_feedback)
	ball.wall_impact.connect(_on_ball_wall_impact)
	ball.tee_left.connect(_on_ball_left_tee)
	ball.elevation_changed.connect(_on_ball_elevation_changed)
	add_child(ball)
	camera.setup(ball)
	camera.state_changed.connect(_on_camera_state_changed)
	feedback_director.cup_emphasis_requested.connect(camera.play_cup_emphasis)
	normal_ball_linear_damp = ball.linear_damp

	level_builder = LevelBuilderScript.new()
	level_builder.hole_body_entered.connect(_on_hole_body_entered)
	level_builder.sand_body_entered.connect(_on_sand_body_entered)
	level_builder.sand_body_exited.connect(_on_sand_body_exited)
	level_builder.reset_hazard_body_entered.connect(_on_reset_hazard_body_entered)
	level_builder.direction_body_entered.connect(_on_direction_body_entered)
	level_builder.direction_body_exited.connect(_on_direction_body_exited)
	level_builder.bounce_pad_triggered.connect(_on_bounce_pad_triggered)
	level_builder.hazard_triggered.connect(_on_hazard_triggered)
	add_child(level_builder)

	hud_canvas_layer = CanvasLayer.new()
	hud_canvas_layer.name = "HUD"
	add_child(hud_canvas_layer)
	feedback_director.setup(ball, camera, hud_canvas_layer)
	release_hud = ReleaseHUDScript.new()
	release_hud.setup(hud_canvas_layer)
	release_hud.seed_copy_requested.connect(_on_seed_copy_requested)
	release_hud.course_overview_requested.connect(_toggle_course_overview)

	score_label = Label.new()
	score_label.name = "HUDStatus"
	score_label.position = Vector2(16, 16)
	score_label.add_theme_font_size_override("font_size", 18)
	hud_canvas_layer.add_child(score_label)

	effects_status_label = Label.new()
	effects_status_label.name = "HUDEffects"
	effects_status_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	effects_status_label.offset_left = -900.0
	effects_status_label.offset_top = 68.0
	effects_status_label.offset_right = -16.0
	effects_status_label.offset_bottom = 94.0
	effects_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	effects_status_label.add_theme_font_size_override("font_size", 16)
	hud_canvas_layer.add_child(effects_status_label)

	debug_hud = VBoxContainer.new()
	debug_hud.name = "DebugHUD"
	debug_hud.position = Vector2(16, 104)
	debug_hud.custom_minimum_size = Vector2(260, 0)
	debug_hud.visible = debug_visible
	hud_canvas_layer.add_child(debug_hud)

	hole_label = _create_hud_label(debug_hud)
	stroke_label = _create_hud_label(debug_hud)
	par_label = _create_hud_label(debug_hud)
	timer_label = _create_hud_label(debug_hud)
	tokens_label = _create_hud_label(debug_hud)
	obstacles_label = _create_hud_label(debug_hud)
	aim_label = _create_hud_label(debug_hud)
	cards_label = _create_hud_label(debug_hud)
	power_debug_label = _create_hud_label(debug_hud)

	power_meter = PowerMeter.new()
	power_meter.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	power_meter.offset_left = -250.0
	power_meter.offset_top = -62.0
	power_meter.offset_right = 250.0
	power_meter.offset_bottom = -14.0
	hud_canvas_layer.add_child(power_meter)

	_create_main_menu_overlay()
	run_setup_screen = RunSetupScreenScript.new()
	run_setup_screen.setup(hud_canvas_layer, game_settings)
	run_setup_screen.start_requested.connect(_on_run_setup_start_requested)
	run_setup_screen.close_requested.connect(_on_run_setup_closed)
	settings_screen = SettingsScreenScript.new()
	settings_screen.setup(hud_canvas_layer, game_settings)
	settings_screen.close_requested.connect(_on_settings_closed)
	settings_screen.settings_changed.connect(_on_settings_changed)
	_create_interstitial_overlay()
	transition_presentation = TransitionPresentationScript.new()
	transition_presentation.setup(interstitial_overlay, interstitial_title_label, interstitial_body_label)

	shop_manager = ShopManagerScript.new()
	shop_manager.bind_run_state(run_state)
	shop_manager.card_bought.connect(_on_shop_card_bought)
	shop_manager.continued.connect(_on_shop_continued)
	shop_manager.feedback_requested.connect(_on_shop_feedback_requested)
	add_child(shop_manager)
	shop_manager.create_overlay(hud_canvas_layer)
	shop_presentation = ShopPresentationScript.new()
	shop_presentation.setup(shop_manager)

	tutorial_manager = TutorialManagerScript.new()
	tutorial_manager.name = "TutorialManager"
	tutorial_manager.skip_requested.connect(_on_tutorial_skip_requested)
	add_child(tutorial_manager)
	tutorial_manager.setup(ball, hud_canvas_layer, level_builder.level_point, _tutorial_effect_snapshot)
	audio_controller.bind_ui(hud_canvas_layer)
	tutorial_manager.set_visible_enabled(false)
	_apply_release_theme()
	ui_appearance = UIAppearance.new()
	add_child(ui_appearance)
	ui_appearance.setup(hud_canvas_layer, RELEASE_THEME)
	vs_controller = VsMatchController.new()
	vs_controller.name = "VsMatchController"
	add_child(vs_controller)
	vs_controller.setup(self)
	ball.set_input_enabled(false)
	ball.visible = false
	_update_camera_layout()


func _apply_release_theme() -> void:
	score_label.theme = RELEASE_THEME
	effects_status_label.theme = RELEASE_THEME
	debug_hud.theme = RELEASE_THEME
	release_hud.theme = RELEASE_THEME
	menu_button.theme = RELEASE_THEME
	main_menu_overlay.theme = RELEASE_THEME
	settings_screen.theme = RELEASE_THEME
	run_setup_screen.theme = RELEASE_THEME
	interstitial_overlay.theme = RELEASE_THEME
	shop_manager.shop_overlay.theme = RELEASE_THEME
	tutorial_manager.hint_panel.theme = RELEASE_THEME
	tutorial_manager.skip_button.theme = RELEASE_THEME


func _start_tutorial() -> void:
	vs_controller.cancel()
	_hide_main_menu()
	_hide_interstitial()
	audio_controller.play_tutorial_music()
	run_state.tutorial_mode = true
	_reset_run_state()
	run_state.levels = TutorialDatabase.get_levels()
	tutorial_manager.set_visible_enabled(true)
	_load_level(0)


func _start_normal_run(seed_override := 0, opponent_id: StringName = &"") -> void:
	_hide_main_menu()
	_hide_interstitial()
	run_state.tutorial_mode = false
	_reset_run_state(seed_override)
	run_state.tutorial_mode = false
	audio_controller.play_menu_music()
	biome_profiles = BiomeDatabase.get_profiles()
	if not run_state.difficulty_profile:
		run_state.difficulty_profile = DifficultyDatabaseScript.get_profile(game_settings.last_difficulty)
	if opponent_id.is_empty():
		run_state.normal_levels = HoleGenerator.generate_run(biome_profiles, run_state.run_seed, run_state.difficulty_profile.generation_options())
		run_state.levels = run_state.normal_levels.duplicate(true)
	else:
		# Future slots are not LevelDefinitions and never reach LevelBuilder.
		# Resolve both builds immediately before each shared physical hole.
		for index in TOTAL_HOLES:
			run_state.levels.append({"pending": true})
		vs_controller.start(opponent_id)
	run_state.generation_fallback_count = 0
	for level in run_state.normal_levels:
		if bool(level.get("used_fallback", false)):
			run_state.generation_fallback_count += 1
	if tutorial_manager:
		tutorial_manager.clear_presentation()
	_show_run_start()


func _reset_run_state(seed_override := 0) -> void:
	if vs_controller:
		vs_controller.cancel()
	transition_generation += 1
	if tutorial_manager:
		tutorial_manager.clear_presentation()
	if feedback_director:
		feedback_director.reset_feedback()
	if audio_controller:
		audio_controller.stop_transient_audio()
	if level_root:
		level_root.queue_free()
		level_root = null
	run_state.reset(seed_override if seed_override != 0 else _new_run_seed())
	_clear_hazard_effects()
	if shop_manager:
		shop_manager.reset_for_new_run()
	if ball:
		ball.reset_to(Vector2.ZERO, 0, false)
		ball.apply_card_modifiers(run_state.impulse_modifier, run_state.drag_modifier, run_state.trajectory_dot_bonus, run_state.roll_damp_modifier)
		normal_ball_linear_damp = ball.get_normal_linear_damp()
		ball.set_input_enabled(false)
		ball.visible = false
	if camera:
		camera.reset_for_hole(Rect2())


func _load_level(next_index: int) -> void:
	if not _set_run_phase(RunPhase.PREPARE_HOLE):
		return
	transition_generation += 1
	_hide_interstitial()
	feedback_director.reset_feedback()
	audio_controller.stop_transient_audio()
	if level_root:
		level_root.queue_free()
		level_root = null

	if run_state.levels.is_empty():
		push_error("Cannot load a hole because the active level list is empty.")
		_set_run_phase(RunPhase.MAIN_MENU)
		_show_main_menu()
		return
	if not run_state.tutorial_mode and (next_index < 0 or next_index >= TOTAL_HOLES):
		push_error("Refusing to load invalid production hole index %d." % next_index)
		_show_run_results()
		return

	run_state.level_index = next_index % run_state.levels.size() if run_state.tutorial_mode else next_index
	run_state.invalidate_shot_refund()
	run_state.strokes = 0
	run_state.level_elapsed = 0.0
	_clear_hazard_effects()

	var level: Dictionary
	if run_state.tutorial_mode:
		level = run_state.levels[run_state.level_index]
	elif vs_controller.is_active():
		level = vs_controller.match_state.prepare_course(run_state.level_index)
		if level.is_empty():
			push_error("Shared match course rejected; no competitor may play a different fallback.")
			vs_controller.return_to_menu()
			return
	else:
		var base_level: Dictionary = run_state.normal_levels[run_state.level_index] if run_state.level_index < run_state.normal_levels.size() else run_state.levels[run_state.level_index]
		level = _level_with_active_card_effects(base_level)
		run_state.levels[run_state.level_index] = level
	if not LevelValidator.validate_level(level, run_state.level_index):
		if vs_controller.is_active():
			push_error("Frozen match course failed revalidation; refusing a private fallback.")
			vs_controller.return_to_menu()
			return
		if run_state.tutorial_mode:
			push_error("Tutorial level %d failed validation; returning to the main menu." % [run_state.level_index + 1])
			_set_run_phase(RunPhase.MAIN_MENU)
			_show_main_menu()
			return
		var generation_options := run_state.difficulty_profile.generation_options() if run_state.difficulty_profile else {}
		level = _level_with_active_card_effects(HoleGenerator.fallback_hole(
			biome_profiles[run_state.biome_index],
			run_state.run_seed,
			run_state.biome_index,
			run_state.hole_index,
			generation_options
		))
		if not LevelValidator.validate_level(level, run_state.level_index):
			push_error("Production hole %d and its authored fallback both failed validation." % run_state.overall_hole_number)
			_show_run_results()
			return
		run_state.levels[run_state.level_index] = level
		run_state.generation_fallback_count += 1
	level_root = level_builder.build_level(level, self)
	feedback_director.configure_level(level)
	ball.configure_level(level)
	ball.configure_prediction_terrain(_terrain_damp(SAND_DAMP), _terrain_entry_speed_scale(SAND_ENTRY_SPEED_SCALE))
	var start_position: Vector2 = level_builder.level_point(level, "start", "start_cell")
	ball.reset_to(start_position, level_builder.get_start_elevation(level), true)
	camera.reset_for_hole(level_builder.get_playable_bounds())
	_update_camera_layout()
	level_builder.set_active_elevation(level_builder.get_start_elevation(level))
	last_safe_shot_position = start_position
	last_safe_shot_elevation = level_builder.get_start_elevation(level)
	_cancel_out_of_bounds_recovery()
	if level.has("forced_tokens"):
		run_state.tokens = maxi(run_state.tokens, int(level.forced_tokens))
	if run_state.tutorial_mode:
		tutorial_manager.set_level(level, run_state.level_index, run_state.levels.size())
	_set_run_phase(RunPhase.HOLE_PLAY)
	if vs_controller.is_active():
		vs_controller.player_hole_started()
	_update_status()


func _on_hole_body_entered(body: Node2D) -> void:
	if body != ball or loading_next_level or run_phase != RunPhase.HOLE_PLAY:
		return

	if run_state.tutorial_mode and not tutorial_manager.can_complete_level():
		tutorial_manager.show_blocker()
		_reset_current_level()
		return

	if run_state.tutorial_mode:
		_complete_tutorial_hole()
	else:
		_complete_current_hole(true, false)


func _complete_tutorial_hole() -> void:
	if not _set_run_phase(RunPhase.HOLE_RESOLVING):
		return
	run_state.invalidate_shot_refund()
	var captured_transition := transition_generation
	var level: Dictionary = run_state.levels[run_state.level_index]
	var hole_position: Vector2 = level_builder.level_point(level, "hole", "hole_cell")
	ball.set_input_enabled(false)
	feedback_director.play_cup_feedback(hole_position, false)
	audio_controller.play_cup_sink()
	ball.sink_to(hole_position)
	await ball.sink_animation_finished
	if captured_transition != transition_generation or not run_state.tutorial_mode:
		return
	if feedback_director.completion_pause_duration > 0.0:
		await get_tree().create_timer(feedback_director.completion_pause_duration).timeout
		if captured_transition != transition_generation or not run_state.tutorial_mode:
			return
	audio_controller.play_hole_outcome(true, &"tutorial_cup")

	run_state.tokens += _token_reward_for_score(run_state.strokes, level.par)
	_advance_active_curses()
	tutorial_manager.notify_event("hole_completed")
	if run_state.level_index == run_state.levels.size() - 1:
		TutorialManagerScript.mark_tutorial_complete()
		_return_from_tutorial()
		return

	if bool(level.get("open_shop", false)):
		_show_shop(run_state.level_index + 1)
		await shop_manager.continued
		if captured_transition != transition_generation or not run_state.tutorial_mode:
			return
		tutorial_manager.notify_event("shop_continued")
	_load_level(run_state.level_index + 1)


func _complete_current_hole(sink_ball: bool, forced: bool) -> void:
	if run_state.tutorial_mode or loading_next_level or run_phase != RunPhase.HOLE_PLAY:
		return

	if not _set_run_phase(RunPhase.HOLE_RESOLVING):
		return
	ball.set_input_enabled(false)
	var captured_transition := transition_generation
	var level: Dictionary = run_state.levels[run_state.level_index]
	forced = forced or run_state.strokes >= int(level.par) + MAX_STROKES_OVER_PAR
	if sink_ball:
		var hole_position: Vector2 = level_builder.level_point(level, "hole", "hole_cell")
		feedback_director.play_cup_feedback(hole_position, run_state.level_index == TOTAL_HOLES - 1)
		if not forced:
			audio_controller.play_cup_sink()
		ball.sink_to(hole_position)
		await ball.sink_animation_finished
		if captured_transition != transition_generation or run_state.tutorial_mode or run_phase != RunPhase.HOLE_RESOLVING:
			return
		if feedback_director.completion_pause_duration > 0.0:
			await get_tree().create_timer(feedback_director.completion_pause_duration).timeout
	else:
		ball.linear_velocity = Vector2.ZERO
		ball.angular_velocity = 0.0

	if captured_transition != transition_generation or run_state.tutorial_mode or run_phase != RunPhase.HOLE_RESOLVING:
		return

	run_state.last_hole_reward = _token_reward_for_score(run_state.strokes, int(level.par))
	run_state.last_hole_forced = forced
	run_state.tokens += run_state.last_hole_reward
	run_state.last_hole_rating = HoleRatingScript.rate(run_state.strokes, int(level.par), run_state.level_elapsed, forced)
	run_stats.record_hole_result({
		"hole_number": run_state.overall_hole_number,
		"biome_index": run_state.biome_index,
		"biome_name": String(level.get("biome_name", "Unknown")),
		"difficulty_name": String(level.get("difficulty_name", "Normal")),
		"strokes": run_state.strokes,
		"par": int(level.par),
		"time_seconds": run_state.level_elapsed,
		"time": _format_time(run_state.level_elapsed),
		"earned": run_state.last_hole_reward,
		"wallet": run_state.tokens,
		"forced": forced,
		"stars": int(run_state.last_hole_rating.stars),
		"golf_result": String(run_state.last_hole_rating.golf_result),
		"performance": String(run_state.last_hole_rating.performance),
	})
	_advance_active_curses()
	if vs_controller.is_active():
		vs_controller.turn_resolved()
	else:
		_show_hole_results()


func _on_sand_body_entered(body: Node2D) -> void:
	if body != ball or hazard_resetting or run_phase != RunPhase.HOLE_PLAY:
		return

	run_stats.record_hazard_entered("sand")
	if run_state.tutorial_mode:
		tutorial_manager.notify_event("entered_sand")
	feedback_director.play_terrain_feedback(&"sand", ball.global_position)
	audio_controller.play_terrain_impact(&"sand")
	active_sand_tiles += 1
	ball.linear_velocity *= _terrain_entry_speed_scale(SAND_ENTRY_SPEED_SCALE)
	ball.linear_damp = _terrain_damp(SAND_DAMP)


func _on_sand_body_exited(body: Node2D) -> void:
	if body != ball:
		return

	active_sand_tiles = maxi(active_sand_tiles - 1, 0)
	if active_sand_tiles == 0:
		ball.linear_damp = normal_ball_linear_damp


func _on_reset_hazard_body_entered(body: Node2D, hazard_position: Vector2, hazard_type: StringName) -> void:
	if body != ball or hazard_resetting or loading_next_level or run_phase != RunPhase.HOLE_PLAY:
		return

	run_stats.record_hazard_entered(String(hazard_type))
	if run_state.tutorial_mode and hazard_type == &"water":
		tutorial_manager.notify_event("entered_water")
	if hazard_type == &"water":
		feedback_director.play_terrain_feedback(&"water", ball.global_position)
		audio_controller.play_water()
	elif hazard_type != &"falling_ice":
		feedback_director.play_hazard_feedback(hazard_type, 1.0, ball.global_position)
		audio_controller.play_hazard_triggered(hazard_type, 1.0)
	run_stats.record_hazard_reset(String(hazard_type))
	run_state.invalidate_shot_refund()
	_add_penalty_stroke()
	hazard_resetting = true
	var captured_transition := transition_generation
	active_sand_tiles = 0
	active_direction_pushes.clear()
	ball.linear_damp = normal_ball_linear_damp
	ball.sink_for_reset(hazard_position)
	await ball.hazard_sink_finished
	if captured_transition != transition_generation or run_phase != RunPhase.HOLE_PLAY:
		return
	var level: Dictionary = run_state.levels[run_state.level_index]
	if not run_state.tutorial_mode and run_state.strokes >= int(level.par) + MAX_STROKES_OVER_PAR:
		hazard_resetting = false
		_complete_current_hole(false, true)
		return
	if run_state.tutorial_mode and hazard_type == &"water":
		level_builder.open_tutorial_water_lane(level)
	ball.reset_to(
		level_builder.level_point(level, "start", "start_cell"),
		level_builder.get_start_elevation(level),
		false
	)
	hazard_resetting = false
	_refresh_ball_input()


func _on_direction_body_entered(body: Node2D, area: Area2D) -> void:
	if body != ball or hazard_resetting or run_phase != RunPhase.HOLE_PLAY:
		return

	run_stats.record_hazard_entered("direction")
	if run_state.tutorial_mode:
		tutorial_manager.notify_event("entered_direction")
	feedback_director.play_terrain_feedback(&"direction", ball.global_position)
	active_direction_pushes.append(area.get_meta("direction"))


func _on_direction_body_exited(body: Node2D, area: Area2D) -> void:
	if body != ball:
		return

	active_direction_pushes.erase(area.get_meta("direction"))


func _on_ball_left_tee(position: Vector2, elevation: int) -> void:
	level_builder.on_ball_left_tee(position, elevation)


func _on_ball_elevation_changed(_previous_elevation: int, elevation: int, _position: Vector2) -> void:
	if level_builder:
		level_builder.set_active_elevation(elevation)


func _on_ball_wall_impact(strength: float, position: Vector2) -> void:
	feedback_director.play_wall_impact(strength, position)
	audio_controller.play_wall_impact(strength)


func _on_bounce_pad_triggered(strength: float, _pad_type: StringName, position: Vector2) -> void:
	feedback_director.play_hazard_feedback(&"bounce_pad", strength, position)
	audio_controller.play_boost_pad(strength)


func _on_hazard_triggered(hazard_type: StringName, intensity: float, position: Vector2) -> void:
	if hazard_type in [&"sand", &"direction", &"water", &"lava", &"bounce_pad"]:
		return
	feedback_director.play_hazard_feedback(hazard_type, intensity, position)
	audio_controller.play_hazard_triggered(hazard_type, intensity)


func _on_ball_shot_started(_position: Vector2, _direction: Vector2, _power: float) -> void:
	if run_phase != RunPhase.HOLE_PLAY:
		return
	feedback_director.play_shot_feedback(_position, _direction, _power)
	audio_controller.play_golf_strike(_power)
	last_safe_shot_position = _position
	last_safe_shot_elevation = int(ball.current_elevation)
	run_state.record_accepted_shot()
	if run_state.tutorial_mode:
		tutorial_manager.notify_event("shot_taken")
	_update_status()


func _on_ball_shot_finished() -> void:
	if run_phase != RunPhase.HOLE_PLAY:
		return
	# A stopped OOB ball still owns its pending failsafe/refund. Resolve the
	# ceiling only after the shot is known to have ended on playable terrain.
	if not level_builder.is_position_on_playable_surface(ball.global_position, int(ball.current_elevation)) and not hazard_resetting:
		return
	run_state.invalidate_shot_refund()
	if not run_state.tutorial_mode and not loading_next_level:
		var level: Dictionary = run_state.levels[run_state.level_index]
		if run_state.strokes >= int(level.par) + MAX_STROKES_OVER_PAR:
			_complete_current_hole(false, true)


func _reset_current_level() -> void:
	if run_phase != RunPhase.HOLE_PLAY or run_state.levels.is_empty():
		return
	var level: Dictionary = run_state.levels[run_state.level_index]
	# Invalidate a pending hazard sink before reset kills its tween. A later
	# sink signal must never resume a callback from an earlier hole/reset.
	transition_generation += 1
	run_stats.record_manual_reset()
	run_state.invalidate_shot_refund()
	if not run_state.tutorial_mode and run_state.strokes >= int(level.par) + MAX_STROKES_OVER_PAR:
		_complete_current_hole(false, true)
		return
	feedback_director.reset_feedback()
	audio_controller.stop_transient_audio()
	_clear_hazard_effects()
	level_builder.reset_dynamic_hazards()
	level_builder.restore_tee()
	ball.reset_to(
		level_builder.level_point(level, "start", "start_cell"),
		level_builder.get_start_elevation(level),
		true
	)
	camera.return_to_ball(true)
	_refresh_ball_input()
	_update_status()


func _clear_hazard_effects() -> void:
	active_sand_tiles = 0
	active_direction_pushes.clear()
	hazard_resetting = false
	if ball:
		ball.linear_damp = normal_ball_linear_damp
	_cancel_out_of_bounds_recovery()


func _update_out_of_bounds_recovery(delta: float) -> void:
	if not ball or not level_builder or ball.sunk:
		_cancel_out_of_bounds_recovery()
		return
	var is_valid: bool = level_builder.is_position_on_playable_surface(
		ball.global_position,
		int(ball.current_elevation)
	)
	if is_valid:
		_cancel_out_of_bounds_recovery()
		return
	ball.set_input_enabled(false)
	if not out_of_bounds_active:
		out_of_bounds_active = true
		out_of_bounds_shot_id = run_state.accepted_shot_id
		out_of_bounds_remaining = OUT_OF_BOUNDS_RETURN_SECONDS
	out_of_bounds_remaining = maxf(out_of_bounds_remaining - maxf(delta, 0.0), 0.0)
	if release_hud:
		release_hud.show_out_of_bounds(maxi(ceili(out_of_bounds_remaining), 1))
	if out_of_bounds_remaining <= 0.0:
		_return_ball_from_out_of_bounds()


func _cancel_out_of_bounds_recovery() -> void:
	var was_active := out_of_bounds_active
	out_of_bounds_active = false
	out_of_bounds_shot_id = -1
	out_of_bounds_remaining = OUT_OF_BOUNDS_RETURN_SECONDS
	if was_active:
		_refresh_ball_input()
	if release_hud:
		release_hud.hide_out_of_bounds()


func _return_ball_from_out_of_bounds() -> void:
	if not out_of_bounds_active or not ball:
		return
	run_state.refund_out_of_bounds_shot(out_of_bounds_shot_id)
	feedback_director.reset_feedback()
	audio_controller.stop_transient_audio()
	active_sand_tiles = 0
	active_direction_pushes.clear()
	ball.linear_damp = normal_ball_linear_damp
	ball.reset_to(last_safe_shot_position, last_safe_shot_elevation, false)
	_cancel_out_of_bounds_recovery()
	_update_status()


func _update_status() -> void:
	if run_state.levels.is_empty() or run_state.level_index < 0 or run_state.level_index >= run_state.levels.size():
		return
	var level: Dictionary = run_state.levels[run_state.level_index]
	if bool(level.get("pending", false)):
		return
	var biome_name := String(level.get("biome_name", "Tutorial" if run_state.tutorial_mode else "Unknown"))
	var displayed_hole := run_state.level_index + 1 if run_state.tutorial_mode else run_state.overall_hole_number
	var displayed_total := run_state.levels.size() if run_state.tutorial_mode else TOTAL_HOLES
	if run_state.tutorial_mode:
		score_label.text = "Tutorial   Hole: %d/%d   Seed: %d\nStrokes: %d   Total: %d   Par: %d   Time: %s   Coins: %d" % [
			displayed_hole,
			displayed_total,
			run_state.run_seed,
			run_state.strokes,
			run_state.total_strokes,
			level.par,
			_format_time(run_state.level_elapsed),
			run_state.tokens
		]
	else:
		score_label.text = "%s   Biome: %d/%d   Hole: %d/%d   Overall: %d/%d   Seed: %d\nStrokes: %d   Total: %d   Par: %d   Time: %s   Coins: %d" % [
			biome_name,
			run_state.biome_index + 1,
			BIOME_COUNT,
			run_state.hole_index + 1,
			HOLES_PER_BIOME,
			run_state.overall_hole_number,
			TOTAL_HOLES,
			run_state.run_seed,
			run_state.strokes,
			run_state.total_strokes,
			level.par,
			_format_time(run_state.level_elapsed),
			run_state.tokens
		]
	hole_label.text = "Hole: %d/%d" % [displayed_hole, displayed_total]
	if not run_state.tutorial_mode:
		hole_label.text += "  Biome: %d/%d  Local: %d/%d" % [run_state.biome_index + 1, BIOME_COUNT, run_state.hole_index + 1, HOLES_PER_BIOME]
	stroke_label.text = "Strokes: %d  Total: %d" % [run_state.strokes, run_state.total_strokes]
	par_label.text = "Par: %d" % level.par
	timer_label.text = "Timer: %s" % _format_time(run_state.level_elapsed)
	tokens_label.text = "Coins: %d" % run_state.tokens
	obstacles_label.text = "Obstacles: %s" % _obstacle_summary(level)
	cards_label.text = "Cards: %s" % _cards_summary()
	effects_status_label.text = "Run bonuses: %d card%s   Active curses: %s" % [
		run_state.owned_cards.size(),
		"" if run_state.owned_cards.size() == 1 else "s",
		_active_curses_summary()
	]
	var aim_power: float = ball.get_aim_power() if ball else 0.0
	var aim_text := "%.0f deg" % ball.get_aim_direction_degrees() if ball and ball.has_active_aim() else "none"
	power_meter.set_power(aim_power)
	power_debug_label.text = "Power: %d%%" % roundi(aim_power * 100.0)
	aim_label.text = "Aim: %s" % aim_text
	if release_hud:
		release_hud.set_tutorial_concepts(tutorial_manager.hud_concepts() if run_state.tutorial_mode else {})
		release_hud.update_display({
			"can_overview": _can_toggle_course_overview(),
			"biome_name": biome_name,
			"biome_number": 0 if run_state.tutorial_mode else run_state.biome_index + 1,
			"biome_total": BIOME_COUNT,
			"hole_number": displayed_hole,
			"hole_total": displayed_total,
			"strokes": run_state.strokes,
			"remaining_shots": -1 if run_state.tutorial_mode else run_state.remaining_shots(int(level.par)),
			"par": int(level.par),
			"time": _format_time(run_state.level_elapsed),
			"coins": run_state.tokens,
			"seed": run_state.run_seed,
			"bonuses": run_state.owned_cards.duplicate(),
			"owned_card_definitions": run_state.owned_card_definitions.duplicate(),
			"curses": _active_curse_display_items(),
		})
		release_hud.update_shot(aim_power, aim_text)


func _toggle_debug_hud() -> void:
	if not OS.is_debug_build():
		return
	debug_visible = not debug_visible
	if debug_hud:
		debug_hud.visible = debug_visible and run_phase == RunPhase.HOLE_PLAY


func _create_hud_label(parent: Control) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 18)
	parent.add_child(label)
	return label


func _create_main_menu_overlay() -> void:
	menu_button = UIActionButtonScript.new()
	menu_button.name = "MenuButton"
	menu_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_button.custom_minimum_size = Vector2(136.0, 52.0)
	menu_button.offset_left = -150.0
	menu_button.offset_top = 164.0
	menu_button.offset_right = -14.0
	menu_button.offset_bottom = 216.0
	menu_button.configure("MENU", &"menu", &"quiet")
	menu_button.pressed.connect(_show_main_menu)
	hud_canvas_layer.add_child(menu_button)
	release_hud.secondary_controls_moved.connect(func(top: float) -> void:
		menu_button.offset_top = top
		menu_button.offset_bottom = top + 52.0
	)

	main_menu_overlay = PanelContainer.new()
	main_menu_overlay.name = "MainMenuScreen"
	main_menu_overlay.visible = false
	main_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_canvas_layer.add_child(main_menu_overlay)
	main_menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_menu_overlay.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	title_attract_mode = TitleAttractModeScript.new()
	title_attract_mode.name = "TitleAttractMode"
	main_menu_overlay.add_child(title_attract_mode)
	menu_pause_dim = ColorRect.new()
	menu_pause_dim.name = "PausedRunDim"
	menu_pause_dim.color = Color(0.015, 0.035, 0.03, 0.74)
	menu_pause_blur_material = UIStyleScript.pause_blur_material()
	menu_pause_dim.material = menu_pause_blur_material
	menu_pause_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_pause_dim.visible = false
	main_menu_overlay.add_child(menu_pause_dim)
	menu_pause_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.name = "SafeArea"
	margin.add_theme_constant_override("margin_left", 74)
	margin.add_theme_constant_override("margin_top", 54)
	margin.add_theme_constant_override("margin_right", 74)
	margin.add_theme_constant_override("margin_bottom", 54)
	main_menu_overlay.add_child(margin)

	menu_title_layout = HBoxContainer.new()
	menu_title_layout.name = "TitleLayout"
	menu_title_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_title_layout.add_theme_constant_override("separation", 48)
	margin.add_child(menu_title_layout)

	menu_brand_column = VBoxContainer.new()
	menu_brand_column.name = "BrandColumn"
	menu_brand_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_brand_column.size_flags_stretch_ratio = 1.35
	menu_brand_column.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_brand_column.add_theme_constant_override("separation", 8)
	menu_title_layout.add_child(menu_brand_column)

	main_menu_logo = UILogoScript.new()
	main_menu_logo.name = "Wordmark"
	main_menu_logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_brand_column.add_child(main_menu_logo)
	main_menu_title_label = main_menu_logo.title_label

	menu_action_panel = PanelContainer.new()
	menu_action_panel.name = "ActionPanel"
	menu_action_panel.custom_minimum_size = Vector2(410.0, 0.0)
	menu_action_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_action_panel.size_flags_stretch_ratio = 0.65
	menu_action_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu_action_panel.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("panel", 14.0))
	menu_title_layout.add_child(menu_action_panel)
	var action_margin := MarginContainer.new()
	action_margin.add_theme_constant_override("margin_left", 32)
	action_margin.add_theme_constant_override("margin_top", 31)
	action_margin.add_theme_constant_override("margin_right", 32)
	action_margin.add_theme_constant_override("margin_bottom", 31)
	menu_action_panel.add_child(action_margin)
	var action_layout := VBoxContainer.new()
	action_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	action_layout.add_theme_constant_override("separation", 18)
	action_margin.add_child(action_layout)

	menu_resume_button = _create_menu_button(action_layout, "RESUME ROUND", _hide_main_menu, &"continue", &"primary")
	menu_play_button = _create_menu_button(action_layout, "PLAY", _on_menu_play_pressed, &"hole", &"primary")

	menu_tutorial_button = _create_menu_button(action_layout, "TUTORIAL", _on_menu_restart_tutorial_pressed, &"tutorial", &"secondary")
	menu_settings_button = _create_menu_button(action_layout, "SETTINGS", _on_menu_settings_pressed, &"settings", &"secondary")
	menu_quit_button = _create_menu_button(action_layout, "QUIT", _on_menu_quit_pressed, &"quit", &"danger")
	for button in [menu_play_button, menu_resume_button]:
		button.display_size = 48
	for button in [menu_tutorial_button, menu_settings_button, menu_quit_button]:
		button.display_size = 38


func _create_interstitial_overlay() -> void:
	interstitial_overlay = PanelContainer.new()
	interstitial_overlay.name = "InterstitialScreen"
	interstitial_overlay.visible = false
	interstitial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_canvas_layer.add_child(interstitial_overlay)
	interstitial_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.name = "SafeArea"
	margin.add_theme_constant_override("margin_left", 108)
	margin.add_theme_constant_override("margin_top", 84)
	margin.add_theme_constant_override("margin_right", 108)
	margin.add_theme_constant_override("margin_bottom", 84)
	interstitial_overlay.add_child(margin)

	var layout := HBoxContainer.new()
	layout.name = "Layout"
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 64)
	margin.add_child(layout)

	var hero_column := VBoxContainer.new()
	hero_column.name = "HeroColumn"
	hero_column.custom_minimum_size.x = 410.0
	hero_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_column.size_flags_stretch_ratio = 0.86
	hero_column.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_column.add_theme_constant_override("separation", 16)
	layout.add_child(hero_column)
	var eyebrow := Label.new()
	eyebrow.name = "Eyebrow"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIStyleScript.apply_ui(eyebrow, 14, UIStyleScript.GOLD, true)
	hero_column.add_child(eyebrow)
	var hero_icon_stage := PanelContainer.new()
	hero_icon_stage.name = "HeroIconStage"
	hero_icon_stage.custom_minimum_size = Vector2(174.0, 174.0)
	hero_column.add_child(hero_icon_stage)
	interstitial_title_label = Label.new()
	interstitial_title_label.name = "Title"
	interstitial_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	interstitial_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interstitial_title_label.custom_minimum_size.y = 116.0
	UIStyleScript.apply_display(interstitial_title_label, 50, UIStyleScript.PAPER)
	hero_column.add_child(interstitial_title_label)
	var identity := Label.new()
	identity.name = "Identity"
	identity.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	identity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyleScript.apply_ui(identity, 14, UIStyleScript.PAPER_MUTED, true)
	hero_column.add_child(identity)

	var detail_panel := PanelContainer.new()
	detail_panel.name = "DetailPanel"
	detail_panel.custom_minimum_size.x = 520.0
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_stretch_ratio = 1.14
	detail_panel.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color(UIStyleScript.INK, 0.92), Color(UIStyleScript.GOLD, 0.42), 20, 2, 12))
	layout.add_child(detail_panel)
	var detail_margin := MarginContainer.new()
	detail_margin.name = "DetailMargin"
	detail_margin.add_theme_constant_override("margin_left", 30)
	detail_margin.add_theme_constant_override("margin_top", 28)
	detail_margin.add_theme_constant_override("margin_right", 30)
	detail_margin.add_theme_constant_override("margin_bottom", 28)
	detail_panel.add_child(detail_margin)
	var detail_layout := VBoxContainer.new()
	detail_layout.name = "DetailLayout"
	detail_layout.add_theme_constant_override("separation", 18)
	detail_margin.add_child(detail_layout)

	interstitial_body_label = Label.new()
	interstitial_body_label.name = "Body"
	interstitial_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	interstitial_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interstitial_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interstitial_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UIStyleScript.apply_ui(interstitial_body_label, 21, UIStyleScript.PAPER)
	detail_layout.add_child(interstitial_body_label)
	var visual_details := VBoxContainer.new()
	visual_details.name = "VisualDetails"
	visual_details.add_theme_constant_override("separation", 10)
	detail_layout.add_child(visual_details)
	detail_layout.move_child(visual_details, 0)

	interstitial_continue_button = UIActionButtonScript.new()
	interstitial_continue_button.custom_minimum_size = Vector2(320.0, 60.0)
	interstitial_continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	interstitial_continue_button.pressed.connect(_on_interstitial_continue_pressed)
	detail_layout.add_child(interstitial_continue_button)
	interstitial_continue_button.configure("CONTINUE", &"continue", &"primary")
	interstitial_menu_button = UIActionButtonScript.new()
	interstitial_menu_button.name = "ResultsMenuButton"
	interstitial_menu_button.custom_minimum_size = Vector2(320, 56)
	interstitial_menu_button.configure("MAIN MENU", &"menu", &"secondary")
	interstitial_menu_button.pressed.connect(_show_main_menu)
	interstitial_menu_button.visible = false
	detail_layout.add_child(interstitial_menu_button)


func _create_menu_button(parent: Control, text: String, callback: Callable, icon_name: StringName, variant: StringName) -> Button:
	var button := UIActionButtonScript.new()
	button.custom_minimum_size = Vector2(350.0, 82.0)
	button.pressed.connect(callback)
	parent.add_child(button)
	button.configure(text, icon_name, variant)
	return button


func _show_main_menu() -> void:
	if not main_menu_overlay:
		return
	var paused_run := level_root != null and run_phase == RunPhase.HOLE_PLAY
	if not paused_run:
		transition_generation += 1
		ball.cancel_sink_animation()
		_set_run_phase(RunPhase.MAIN_MENU)
		_hide_interstitial()
		feedback_director.reset_feedback()
		audio_controller.stop_transient_audio()
		audio_controller.play_menu_music()
	menu_resume_button.visible = paused_run
	menu_play_button.visible = true
	if title_attract_mode:
		title_attract_mode.visible = not paused_run
	if menu_pause_dim:
		menu_pause_dim.visible = paused_run
		menu_pause_dim.material = menu_pause_blur_material if _pause_blur_enabled() else null
	if menu_brand_column:
		menu_brand_column.visible = not paused_run
	if menu_action_panel:
		menu_action_panel.visible = true
		menu_action_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if paused_run else Control.SIZE_EXPAND_FILL
		menu_action_panel.custom_minimum_size = Vector2(520.0 if paused_run else 410.0, 0.0)
	if tutorial_manager:
		tutorial_manager.set_visible_enabled(false)
	main_menu_overlay.visible = true
	menu_button.visible = false
	if main_menu_logo:
		main_menu_logo.play_entrance()
	if run_phase == RunPhase.MAIN_MENU:
		audio_controller.play_menu_music()
	_update_gameplay_simulation_pause()
	_refresh_ball_input()
	if menu_resume_button.visible:
		menu_resume_button.grab_focus()
	else:
		menu_play_button.grab_focus()


func _hide_main_menu() -> void:
	if main_menu_overlay:
		main_menu_overlay.visible = false
	if settings_screen:
		settings_screen.visible = false
	if run_setup_screen:
		run_setup_screen.visible = false
	if menu_action_panel:
		menu_action_panel.visible = true
	if tutorial_manager and run_state.tutorial_mode and run_phase == RunPhase.HOLE_PLAY:
		tutorial_manager.set_visible_enabled(true)
	menu_button.visible = run_phase == RunPhase.HOLE_PLAY
	_update_gameplay_simulation_pause()
	_refresh_ball_input()


func _on_menu_play_pressed() -> void:
	vs_controller.view.show_modes()


func _on_run_setup_start_requested(seed_value: int, difficulty_id: StringName) -> void:
	run_state.difficulty_profile = DifficultyDatabaseScript.get_profile(difficulty_id)
	TutorialManagerScript.mark_tutorial_complete()
	if tutorial_manager:
		tutorial_manager.clear_presentation()
	_start_normal_run(seed_value, vs_controller.selected_opponent)


func _on_run_setup_closed() -> void:
	if not vs_controller.selected_opponent.is_empty():
		vs_controller.view.show_opponents()
		return
	if main_menu_overlay and main_menu_overlay.visible and menu_play_button:
		menu_play_button.grab_focus()


func _on_seed_copy_requested(seed_value: int) -> void:
	DisplayServer.clipboard_set(SeedCodecScript.format_seed(seed_value))
	if release_hud:
		release_hud.show_seed_copied()


func _on_menu_restart_tutorial_pressed() -> void:
	_start_tutorial()


func _on_menu_settings_pressed() -> void:
	if settings_screen:
		var pause_context := menu_resume_button.visible
		if pause_context:
			menu_action_panel.visible = false
			menu_pause_dim.visible = false
		settings_screen.open(pause_context)


func _on_settings_closed() -> void:
	if main_menu_overlay and main_menu_overlay.visible and menu_settings_button:
		menu_action_panel.visible = true
		menu_pause_dim.visible = menu_resume_button.visible
		menu_settings_button.grab_focus()


func _pause_blur_enabled() -> bool:
	return game_settings != null and game_settings.visual_effects_intensity >= 0.35 and not game_settings.reduced_motion


func _on_settings_changed(_settings: GameSettings) -> void:
	_apply_player_settings()


func _apply_player_settings() -> void:
	if not game_settings:
		return
	hud_canvas_layer.set_meta(&"reduced_motion", game_settings.reduced_motion)
	if ui_appearance:
		ui_appearance.apply_mode(game_settings.ui_appearance)
	set_meta(&"reduced_motion", game_settings.reduced_motion)
	if ball:
		ball.apply_player_settings(game_settings.trajectory_visible, game_settings.aim_sensitivity)
	if camera:
		camera.reduced_motion = game_settings.reduced_motion
	if release_hud:
		release_hud.set_overview_state(camera.is_overview_active(), OS.get_keycode_string(game_settings.overview_keycode))
	if feedback_director:
		feedback_director.apply_player_settings(
			game_settings.screen_shake_intensity,
			game_settings.visual_effects_intensity,
			game_settings.reduced_motion
		)
	if title_attract_mode:
		title_attract_mode.set_reduced_motion(game_settings.reduced_motion)


func _on_menu_skip_tutorial_pressed() -> void:
	TutorialManagerScript.mark_tutorial_complete()
	_return_from_tutorial()


func _on_menu_quit_pressed() -> void:
	get_tree().quit()


func _show_run_start() -> void:
	if not _set_run_phase(RunPhase.RUN_START):
		return
	_show_interstitial(
		"TEE OFF",
		"%s ROUND\n\nA shop between biomes.\nEvery upgrade comes with a curse.\n\nBuy power. Carry the trouble." % [run_state.difficulty_profile.display_name if run_state.difficulty_profile else "NORMAL"],
		"BEGIN COURSE"
	)
	transition_presentation.show_run_start(run_state.run_seed)


func _show_biome_intro() -> void:
	if not _set_run_phase(RunPhase.BIOME_INTRO):
		return
	var profile = biome_profiles[run_state.biome_index]
	audio_controller.set_biome(run_state.biome_index)
	if level_root:
		level_root.queue_free()
		level_root = null
	ball.visible = false
	_show_interstitial(
		String(profile.display_name).to_upper(),
		"HOLES %02d — %02d\n\nIN YOUR BAG\n%s\n\nACTIVE CURSES\n%s" % [
			run_state.biome_index * HOLES_PER_BIOME + 1,
			run_state.biome_index * HOLES_PER_BIOME + HOLES_PER_BIOME,
			_cards_summary(),
			_active_curses_summary()
		],
		"PLAY HOLE %02d" % run_state.overall_hole_number
	)
	transition_presentation.show_biome(profile, run_state.biome_index + 1, BIOME_COUNT)
	feedback_director.play_progression_feedback(
		&"biome_transition",
		profile.background_palette.get("accent", Color("e2b84b"))
	)
	audio_controller.play_biome_transition(run_state.biome_index)


func _show_hole_results() -> void:
	if not _set_run_phase(RunPhase.HOLE_RESULTS):
		return
	if vs_controller.is_active():
		ball.visible = false
		_clear_hazard_effects()
		vs_controller.view.show_comparison(vs_controller.match_state)
		return
	var level: Dictionary = run_state.levels[run_state.level_index]
	var score_to_par := run_state.strokes - int(level.par)
	ball.visible = false
	_clear_hazard_effects()
	audio_controller.play_hole_outcome(not run_state.last_hole_forced, &"par_plus_four" if run_state.last_hole_forced else &"cup")
	_show_interstitial(
		String(run_state.last_hole_rating.get("golf_result", _score_result_heading(score_to_par, run_state.last_hole_forced))),
		_hole_result_status_copy(),
		"CONTINUE"
	)
	transition_presentation.show_hole_result(
		score_to_par,
		run_state.last_hole_forced,
		String(level.get("biome_name", "Unknown")),
		run_state.overall_hole_number,
		TOTAL_HOLES,
		{
			"strokes": run_state.strokes,
			"par": int(level.par),
			"time": _format_time(run_state.level_elapsed),
			"earned": run_state.last_hole_reward,
			"wallet": run_state.tokens,
			"rating": run_state.last_hole_rating.duplicate(true),
			"history": run_stats.history_snapshot(),
			"current_hole": run_state.overall_hole_number,
		}
	)


func _hole_result_status_copy() -> String:
	var lines := PackedStringArray()
	var active_curses := _active_curses_summary()
	if active_curses != "None":
		lines.append("ACTIVE CURSE  •  %s" % active_curses)
	if not run_state.last_expired_curses.is_empty():
		lines.append("CURSE CLEARED  •  %s" % ", ".join(run_state.last_expired_curses))
	return "\n".join(lines)


func _advance_after_hole_results() -> void:
	if run_state.level_index >= TOTAL_HOLES - 1:
		_show_run_results()
		return

	if run_state.hole_index == HOLES_PER_BIOME - 1:
		_show_shop(run_state.level_index + 1)
		return

	_load_level(run_state.level_index + 1)


func _show_run_results() -> void:
	if not _set_run_phase(RunPhase.RUN_RESULTS):
		return
	var total_par := _total_par()
	var score_to_par := run_state.total_strokes - total_par
	if level_root:
		level_root.queue_free()
		level_root = null
	ball.visible = false
	run_stats.print_summary(total_par)
	audio_controller.play_results_music()
	if vs_controller.is_active():
		vs_controller.view.show_final(vs_controller.match_state)
		audio_controller.play_final_run_completion()
		return
	_show_interstitial(
		"COURSE COMPLETE",
		"The score is yours. So were the risks.",
		"SEE ENDING"
	)
	transition_presentation.show_run_results({
		"grade": _letter_grade(score_to_par),
		"score": _format_score_to_par(score_to_par),
		"strokes": run_state.total_strokes,
		"par": total_par,
		"time": _format_time(run_stats.total_run_time),
		"coins": run_state.tokens,
		"seed": run_state.run_seed,
		"cards": run_state.owned_card_definitions.duplicate(),
	})
	feedback_director.play_progression_feedback(&"final_completion", Color("e2b84b"))
	audio_controller.play_final_run_completion()


func _show_ending() -> void:
	if not _set_run_phase(RunPhase.ENDING):
		return
	_show_interstitial(
		"ANOTHER ROUND?",
		"You made it all the way around.\n\nTake a breath.\nThen tempt fate again.",
		"NEW RUN"
	)
	transition_presentation.show_ending()
	feedback_director.play_progression_feedback(&"ending_transition", Color("17221f"))


func _on_interstitial_continue_pressed() -> void:
	match run_phase:
		RunPhase.RUN_START:
			_show_biome_intro()
		RunPhase.BIOME_INTRO:
			_load_level(run_state.level_index)
		RunPhase.HOLE_RESULTS:
			_advance_after_hole_results()
		RunPhase.RUN_RESULTS:
			_show_ending()
		RunPhase.ENDING:
			_start_normal_run()


func _show_interstitial(title: String, body: String, button_text: String) -> void:
	if transition_presentation:
		transition_presentation.show_generic()
	interstitial_title_label.text = title
	interstitial_body_label.text = body
	interstitial_menu_button.visible = run_phase in [RunPhase.RUN_RESULTS, RunPhase.ENDING]
	var action_button := interstitial_continue_button as UIActionButton
	if action_button:
		action_button.configure(button_text, &"restart" if button_text.contains("NEW RUN") else &"continue", &"primary")
	else:
		interstitial_continue_button.text = button_text
	interstitial_overlay.visible = true
	interstitial_continue_button.grab_focus()


func _hide_interstitial() -> void:
	if interstitial_overlay:
		interstitial_overlay.visible = false
	if transition_presentation:
		transition_presentation.reset_presentation()


func _set_run_phase(next_phase: RunState.Phase) -> bool:
	if not run_state.transition_to(next_phase):
		return false
	_present_run_phase()
	return true


func _present_run_phase() -> void:
	if camera and run_phase != RunPhase.HOLE_PLAY:
		camera.return_to_ball(run_phase != RunPhase.HOLE_RESOLVING)
	var gameplay_hud_visible := run_phase in [RunPhase.HOLE_PLAY, RunPhase.HOLE_RESOLVING]
	score_label.visible = false
	effects_status_label.visible = false
	if release_hud:
		release_hud.set_hud_visible(gameplay_hud_visible)
	debug_hud.visible = gameplay_hud_visible and debug_visible
	power_meter.visible = gameplay_hud_visible
	menu_button.visible = gameplay_hud_visible and not main_menu_overlay.visible
	_update_gameplay_simulation_pause()
	_refresh_ball_input()


func _update_gameplay_simulation_pause() -> void:
	var menu_open := main_menu_overlay != null and main_menu_overlay.visible
	run_state.menu_paused = menu_open
	var should_pause := run_phase not in [RunPhase.HOLE_PLAY, RunPhase.HOLE_RESOLVING] or menu_open
	if audio_controller:
		audio_controller.set_gameplay_paused(menu_open and run_phase in [RunPhase.HOLE_PLAY, RunPhase.HOLE_RESOLVING])
	if ball:
		ball.set_gameplay_simulation_paused(should_pause)
	if level_builder:
		level_builder.set_gameplay_simulation_paused(should_pause)
	if camera:
		camera.set_process(not menu_open)


func _refresh_ball_input() -> void:
	if not ball:
		return
	var menu_open := main_menu_overlay != null and main_menu_overlay.visible
	# AI submission uses this same ball gate; its external-control guard already
	# rejects player input. Inspection must not stall the opponent simulation.
	var player_inspecting := camera and camera.is_overview_active() and not (vs_controller and vs_controller.is_ai_turn())
	ball.set_input_enabled(run_phase == RunPhase.HOLE_PLAY and not loading_next_level and not hazard_resetting and not out_of_bounds_active and not menu_open and not player_inspecting)


func _is_hole_play_active() -> bool:
	var menu_open := main_menu_overlay != null and main_menu_overlay.visible
	return run_phase == RunPhase.HOLE_PLAY and not loading_next_level and not hazard_resetting and not menu_open


func get_run_phase_name() -> String:
	return RUN_PHASE_NAMES[run_phase]


func _new_run_seed() -> int:
	var time_component := int(Time.get_unix_time_from_system() * 1000.0)
	var tick_component := int(Time.get_ticks_usec())
	return maxi(absi((time_component + tick_component) % 2147483647), 1)


func _format_score_to_par(score_to_par: int) -> String:
	if score_to_par == 0:
		return "E"
	if score_to_par > 0:
		return "+%d" % score_to_par
	return "%d" % score_to_par


func _score_result_heading(score_to_par: int, forced: bool) -> String:
	if forced:
		return "HOLE CLOSED"
	if score_to_par <= -2:
		return "EAGLE"
	if score_to_par == -1:
		return "BIRDIE"
	if score_to_par == 0:
		return "PAR"
	if score_to_par == 1:
		return "BOGEY"
	return "%+d OVER" % score_to_par


func _letter_grade(score_to_par: int) -> String:
	if score_to_par <= -6:
		return "A"
	if score_to_par <= 0:
		return "B"
	if score_to_par <= 8:
		return "C"
	if score_to_par <= 16:
		return "D"
	return "F"


func _format_time(seconds: float) -> String:
	var total_seconds := int(floor(seconds))
	var minutes := total_seconds / 60
	var remaining_seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]


func _obstacle_summary(level: Dictionary) -> String:
	var obstacles: Array = level.obstacles
	var card_hazard_count := int(level.get("card_hazard_count", 0))
	if obstacles.is_empty() and card_hazard_count == 0:
		return "None"
	var parts: Array[String] = []
	if not obstacles.is_empty():
		parts.append("%d wall%s" % [obstacles.size(), "" if obstacles.size() == 1 else "s"])
	if card_hazard_count > 0:
		parts.append("%d curse hazard%s" % [card_hazard_count, "" if card_hazard_count == 1 else "s"])
	return ", ".join(parts)


func _token_reward_for_score(final_strokes: int, par: int) -> int:
	return run_state.reward_for_score(final_strokes, par)


func _total_par() -> int:
	var total := 0
	for level in run_state.levels:
		total += int(level.par)
	return total


func _show_shop(next_level_index: int) -> void:
	if not _set_run_phase(RunPhase.SHOP):
		return
	_hide_interstitial()
	var level: Dictionary = run_state.levels[run_state.level_index]
	var forced_cards: Array[String] = []
	for card_name in level.get("shop_cards", []):
		forced_cards.append(String(card_name))
	var explicit_cards: Array[CardDefinition] = []
	var existing_card_ids: Array[StringName] = []
	for owned_card in run_state.owned_card_definitions:
		existing_card_ids.append(owned_card.id)
	if run_state.tutorial_mode:
		explicit_cards.assign(TutorialDatabase.get_tutorial_cards())
	var shop_offer_count := 4 if run_state.tutorial_mode or not run_state.difficulty_profile else run_state.difficulty_profile.shop_offer_count
	var shop_purchase_limit := 2 if run_state.tutorial_mode or not run_state.difficulty_profile else run_state.difficulty_profile.max_purchases
	var shop_curse_multiplier := 1.0 if run_state.tutorial_mode or not run_state.difficulty_profile else run_state.difficulty_profile.curse_strength_multiplier
	shop_manager.show_shop(
		next_level_index,
		run_state.tokens,
		run_state.levels.size(),
		run_state.run_seed,
		forced_cards,
		_shop_destination(next_level_index),
		explicit_cards,
		int(level.get("minimum_shop_purchases", 0)),
		existing_card_ids,
		shop_offer_count,
		shop_purchase_limit,
		shop_curse_multiplier
	)
	if run_state.tutorial_mode:
		tutorial_manager.notify_event("shop_opened")
	elif vs_controller.is_active():
		vs_controller.choose_shop_cards()
	_update_status()


func _on_shop_continued() -> void:
	if run_state.tutorial_mode or run_phase != RunPhase.SHOP:
		return
	if vs_controller.is_active():
		vs_controller.shop_continued()
		return
	_finish_shop_transition()


func _finish_shop_transition() -> void:
	run_state.level_index += 1
	_show_biome_intro()


func _shop_destination(next_level_index: int) -> String:
	if run_state.tutorial_mode:
		return "Tutorial Hole %d/%d" % [next_level_index % run_state.levels.size() + 1, run_state.levels.size()]
	var next_biome_index := next_level_index / HOLES_PER_BIOME
	var next_hole_index := next_level_index % HOLES_PER_BIOME
	return "%s — Biome %d/%d, Hole %d/%d (overall %d/%d)" % [
		biome_profiles[next_biome_index].display_name,
		next_biome_index + 1,
		BIOME_COUNT,
		next_hole_index + 1,
		HOLES_PER_BIOME,
		next_level_index + 1,
		TOTAL_HOLES
	]


func _on_shop_card_bought(card: CardDefinition) -> void:
	_apply_card(card)
	_update_status()


func _on_shop_feedback_requested(kind: StringName) -> void:
	match kind:
		&"purchase":
			var last_card := run_state.owned_card_definitions.back() as CardDefinition
			var stack_count := 0
			for card in run_state.owned_card_definitions:
				if card.id == last_card.id:
					stack_count += 1
			audio_controller.play_card_acquired(stack_count > 1)
		&"error":
			audio_controller.play_error()


func _apply_card(card: CardDefinition) -> void:
	run_state.add_card(card)
	_refresh_card_effects()
	if run_state.tutorial_mode:
		tutorial_manager.notify_event("card_bought")


func _refresh_card_effects() -> void:
	run_state.refresh_effects()
	if ball:
		ball.apply_card_modifiers(run_state.impulse_modifier, run_state.drag_modifier, run_state.trajectory_dot_bonus, run_state.roll_damp_modifier)
		normal_ball_linear_damp = ball.get_normal_linear_damp()
		ball.configure_prediction_terrain(_terrain_damp(SAND_DAMP), _terrain_entry_speed_scale(SAND_ENTRY_SPEED_SCALE))


func _advance_active_curses() -> void:
	run_state.advance_curses()
	_refresh_card_effects()


func _level_with_active_card_effects(base_level: Dictionary) -> Dictionary:
	var modifier_seed := run_state.run_seed + (run_state.level_index + 1) * 104729 + run_state.active_hazard_count_modifier * 1009
	var level := HoleGenerator.apply_hazard_modifier(
		base_level,
		run_state.active_hazard_count_modifier,
		run_state.active_hazard_type,
		modifier_seed
	)
	level["cup_radius"] = float(base_level.get("cup_radius", 28.0)) * run_state.cup_radius_scale
	level["card_cup_radius_scale"] = run_state.cup_radius_scale
	return level


func _terrain_entry_speed_scale(base_scale: float) -> float:
	if run_state.terrain_mitigation_modifier >= 0.0:
		return lerpf(base_scale, 1.0, run_state.terrain_mitigation_modifier)
	return clampf(base_scale * (1.0 + run_state.terrain_mitigation_modifier), 0.1, 1.0)


func _terrain_damp(base_damp: float) -> float:
	return maxf(base_damp * run_state.sand_damp_modifier, normal_ball_linear_damp)


func _active_curses_summary() -> String:
	if run_state.active_card_curses.is_empty():
		return "None"
	var summaries: Array[String] = []
	for active_curse in run_state.active_card_curses:
		summaries.append(active_curse.summary())
	return ", ".join(summaries)


func _active_curse_display_items() -> Array[String]:
	var items: Array[String] = []
	for active_curse in run_state.active_card_curses:
		if vs_controller.is_active() and MatchCourseRules.affects_course(active_curse.card.curse_effects):
			continue # The frozen match-course configuration is disclosed below.
		items.append("%s — %s · %d hole%s" % [
			active_curse.card.name,
			active_curse.card.curse_description_for_multiplier(1.0 if run_state.tutorial_mode or not run_state.difficulty_profile else run_state.difficulty_profile.curse_strength_multiplier),
			active_curse.remaining_holes,
			"" if active_curse.remaining_holes == 1 else "s",
		])
	if vs_controller.is_active():
		var shared := vs_controller.match_state.shared_configuration
		if int(shared.get("added_hazard_count", 0)) > 0:
			items.append("COURSE • BOTH GOLFERS — +%d %s hazards" % [shared.added_hazard_count, shared.preferred_hazard_type])
		if not is_equal_approx(float(shared.get("cup_radius_scale", 1.0)), 1.0):
			items.append("COURSE • BOTH GOLFERS — cup size %d%%" % roundi(float(shared.cup_radius_scale) * 100.0))
	return items


func _cards_summary() -> String:
	if run_state.owned_cards.is_empty():
		return "None"
	if run_state.owned_cards.size() <= 2:
		return ", ".join(run_state.owned_cards)
	return "%d owned" % run_state.owned_cards.size()


func _toggle_course_overview() -> void:
	if not _can_toggle_course_overview():
		return
	_update_camera_layout()
	camera.toggle_overview()


func _can_toggle_course_overview() -> bool:
	# Inspection remains available during a hazard reset; shot input stays locked.
	var menu_open := main_menu_overlay != null and main_menu_overlay.visible
	return run_phase == RunPhase.HOLE_PLAY and not loading_next_level and not menu_open


func _on_camera_state_changed(_state: CourseCamera.State) -> void:
	feedback_director.set_camera_motion_enabled(not camera.is_overview_active())
	if release_hud:
		release_hud.set_overview_state(camera.is_overview_active(), OS.get_keycode_string(game_settings.overview_keycode))
	_refresh_ball_input() # Existing disable path cancels both aim modes/previews.
	_update_status()


func _update_camera_layout() -> void:
	if not camera or not release_hud:
		return
	var safe: Rect2 = release_hud.get_course_view_rect()
	if tutorial_manager and tutorial_manager.hint_panel.is_visible_in_tree():
		safe.end.y = minf(safe.end.y, tutorial_manager.hint_panel.get_global_rect().position.y - 24.0)
	if vs_controller and vs_controller.view.match_bar.is_visible_in_tree():
		safe.end.y = minf(safe.end.y, vs_controller.view.match_bar.get_global_rect().position.y - 24.0)
	camera.set_usable_viewport(safe)


func _add_penalty_stroke() -> void:
	run_state.record_stroke()
	_update_status()


func _on_tutorial_skip_requested() -> void:
	TutorialManagerScript.mark_tutorial_complete()
	_return_from_tutorial()

func _return_from_tutorial() -> void:
	_reset_run_state()
	run_state.tutorial_mode = false
	_hide_interstitial()
	_set_run_phase(RunPhase.MAIN_MENU)
	_show_main_menu()


func _tutorial_effect_snapshot() -> Dictionary:
	return {"has_bonus": not run_state.owned_card_definitions.is_empty(), "has_curse": not run_state.active_card_curses.is_empty()}
