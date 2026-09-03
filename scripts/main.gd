extends Node2D

const BALL_SCENE := preload("res://scenes/golf_ball.tscn")
const LevelBuilderScript := preload("res://scripts/level_builder.gd")
const LevelDatabase := preload("res://scripts/level_database.gd")
const TutorialDatabase := preload("res://scripts/tutorial_database.gd")
const TutorialManagerScript := preload("res://scripts/tutorial_manager.gd")
const LevelValidator := preload("res://scripts/level_validator.gd")
const RunStatsScript := preload("res://scripts/run_stats.gd")
const ShopManagerScript := preload("res://scripts/shop_manager.gd")
const BiomeDatabase := preload("res://scripts/biome_database.gd")
const HoleGenerator := preload("res://scripts/hole_generator.gd")
const CardEffectResolverScript := preload("res://scripts/card_effect_resolver.gd")
const ActiveCardCurseScript := preload("res://scripts/active_card_curse.gd")
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
const HoleRatingScript := preload("res://scripts/hole_rating.gd")
const RELEASE_THEME := preload("res://assets/release_theme.tres")

const STARTING_TOKENS := 2
const BIOME_COUNT := 6
const HOLES_PER_BIOME := 3
const TOTAL_HOLES := BIOME_COUNT * HOLES_PER_BIOME
const MAX_STROKES_OVER_PAR := 4
const SAND_DAMP := 12.0
const SAND_ENTRY_SPEED_SCALE := 0.35
const DIRECTION_PUSH_FORCE := 950.0
const OUT_OF_BOUNDS_RETURN_SECONDS := 3.0

enum RunPhase {
	MAIN_MENU,
	RUN_START,
	BIOME_INTRO,
	HOLE_PLAY,
	HOLE_RESULTS,
	SHOP,
	RUN_RESULTS,
	ENDING
}

const RUN_PHASE_NAMES := [
	"MAIN_MENU",
	"RUN_START",
	"BIOME_INTRO",
	"HOLE_PLAY",
	"HOLE_RESULTS",
	"SHOP",
	"RUN_RESULTS",
	"ENDING"
]

class PowerMeter:
	extends Control

	const WIDTH_TOP := 44.0
	const WIDTH_BOTTOM := 18.0
	const TOP_CAP_HEIGHT := 20.0
	const BOTTOM_CAP_HEIGHT := 10.0
	const FILL_INSET := 5.0
	const FILL_STEPS := 36
	const LOW_COLOR := Color("edbf45")
	const HIGH_COLOR := Color("ed596f")
	const TRACK_COLOR := Color("152822")
	const OUTLINE_COLOR := Color("f6f1df")
	const TICK_COLOR := Color(0.42, 0.86, 0.76, 0.56)
	const FILL_SPEED := 5.5

	var power := 0.0
	var displayed_power := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(64.0, 170.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func set_power(new_power: float) -> void:
		power = clampf(new_power, 0.0, 1.0)

	func _process(delta: float) -> void:
		displayed_power = move_toward(displayed_power, power, FILL_SPEED * delta)
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var top_y := 4.0
		var bottom_y := rect.size.y - 4.0
		var center_x := rect.size.x * 0.5

		draw_colored_polygon(_meter_polygon(top_y, bottom_y, center_x), OUTLINE_COLOR)
		draw_colored_polygon(_meter_polygon(top_y + 2.0, bottom_y - 2.0, center_x, 2.0), TRACK_COLOR)
		for tick_index in range(1, 5):
			var amount := float(tick_index) / 5.0
			var tick_y := lerpf(bottom_y - 12.0, top_y + 22.0, amount)
			var half_width := _half_width_at_y(tick_y, top_y, bottom_y, 7.0)
			draw_line(Vector2(center_x - half_width, tick_y), Vector2(center_x + half_width, tick_y), TICK_COLOR, 2.0, true)
		_draw_fill(top_y, bottom_y, center_x)

	func _draw_fill(top_y: float, bottom_y: float, center_x: float) -> void:
		if displayed_power <= 0.0:
			return

		var inner_top := top_y + FILL_INSET
		var inner_bottom := bottom_y - FILL_INSET
		var fill_top := lerpf(inner_bottom, inner_top, displayed_power)
		if inner_bottom - fill_top < 1.0:
			return

		if displayed_power >= 0.995:
			var fill_polygon := _meter_polygon(inner_top, inner_bottom, center_x, FILL_INSET)
			draw_polygon(fill_polygon, _meter_vertex_colors(fill_polygon, top_y, bottom_y))
			return

		var fill_polygon := _meter_partial_fill_polygon(fill_top, inner_bottom, center_x, inner_top, inner_bottom)
		draw_polygon(fill_polygon, _meter_vertex_colors(fill_polygon, top_y, bottom_y))

	func _meter_polygon(top_y: float, bottom_y: float, center_x: float, inset := 0.0, closed := false) -> PackedVector2Array:
		var points := PackedVector2Array()
		var height := bottom_y - top_y
		if height <= 0.0:
			return points

		var cap_scale := minf(1.0, height / (TOP_CAP_HEIGHT + BOTTOM_CAP_HEIGHT))
		var top_cap_height := TOP_CAP_HEIGHT * cap_scale
		var bottom_cap_height := BOTTOM_CAP_HEIGHT * cap_scale
		var top_cap_center_y := top_y + top_cap_height
		var bottom_cap_center_y := bottom_y - bottom_cap_height
		var top_half_width := maxf(2.0, WIDTH_TOP * 0.5 - inset)
		var bottom_half_width := maxf(2.0, WIDTH_BOTTOM * 0.5 - inset)

		for i in range(13):
			var angle := lerpf(PI, 0.0, float(i) / 12.0)
			points.append(Vector2(center_x + cos(angle) * top_half_width, top_cap_center_y - sin(angle) * top_cap_height))

		for i in range(1, 12):
			var t := float(i) / 12.0
			var y := lerpf(top_cap_center_y, bottom_cap_center_y, t)
			points.append(Vector2(center_x + _half_width_at_t(t, inset), y))

		for i in range(13):
			var angle := lerpf(0.0, PI, float(i) / 12.0)
			points.append(Vector2(center_x + cos(angle) * bottom_half_width, bottom_cap_center_y + sin(angle) * bottom_cap_height))

		for i in range(11, 0, -1):
			var t := float(i) / 12.0
			var y := lerpf(top_cap_center_y, bottom_cap_center_y, t)
			points.append(Vector2(center_x - _half_width_at_t(t, inset), y))

		if closed:
			points.append(points[0])
		return points

	func _half_width_at_y(y: float, top_y: float, bottom_y: float, inset: float) -> float:
		var t := clampf((y - top_y) / (bottom_y - top_y), 0.0, 1.0)
		return _half_width_at_t(t, inset)

	func _half_width_at_t(t: float, inset: float) -> float:
		return maxf(2.0, lerpf(WIDTH_TOP, WIDTH_BOTTOM, t) * 0.5 - inset)

	func _meter_partial_fill_polygon(fill_top: float, fill_bottom: float, center_x: float, inner_top: float, inner_bottom: float) -> PackedVector2Array:
		var points := PackedVector2Array()
		var fill_height := fill_bottom - fill_top
		if fill_height <= 0.0:
			return points

		var top_cap_height := minf(10.0, fill_height * 0.45)
		var top_cap_center_y := fill_top + top_cap_height
		var top_cap_half_width := _half_width_at_y(top_cap_center_y, inner_top, inner_bottom, FILL_INSET)
		var bottom_cap_height := minf(BOTTOM_CAP_HEIGHT, fill_height * 0.45)
		var bottom_cap_center_y := fill_bottom - bottom_cap_height
		var bottom_cap_half_width := _half_width_at_y(bottom_cap_center_y, inner_top, inner_bottom, FILL_INSET)

		for i in range(13):
			var angle := lerpf(PI, 0.0, float(i) / 12.0)
			points.append(Vector2(center_x + cos(angle) * top_cap_half_width, top_cap_center_y - sin(angle) * top_cap_height))

		for i in range(1, 13):
			var t := float(i) / 12.0
			var y := lerpf(top_cap_center_y, bottom_cap_center_y, t)
			points.append(Vector2(center_x + _half_width_at_y(y, inner_top, inner_bottom, FILL_INSET), y))

		for i in range(13):
			var angle := lerpf(0.0, PI, float(i) / 12.0)
			points.append(Vector2(center_x + cos(angle) * bottom_cap_half_width, bottom_cap_center_y + sin(angle) * bottom_cap_height))

		for i in range(12, 0, -1):
			var t := float(i) / 12.0
			var y := lerpf(top_cap_center_y, bottom_cap_center_y, t)
			points.append(Vector2(center_x - _half_width_at_y(y, inner_top, inner_bottom, FILL_INSET), y))
		return points

	func _meter_vertex_colors(points: PackedVector2Array, top_y: float, bottom_y: float) -> PackedColorArray:
		var colors := PackedColorArray()
		for point in points:
			var color_power := 1.0 - ((point.y - top_y) / (bottom_y - top_y))
			colors.append(LOW_COLOR.lerp(HIGH_COLOR, clampf(color_power, 0.0, 1.0)))
		return colors

var level_index := 0
var biome_index := 0
var hole_index := 0
var overall_hole_number := 1
var run_seed := 0
var run_phase := RunPhase.MAIN_MENU
var transition_generation := 0
var generation_fallback_count := 0
var last_hole_reward := 0
var last_hole_forced := false
var last_hole_rating: Dictionary = {}
var strokes := 0
var total_strokes := 0
var tokens := STARTING_TOKENS
var level_elapsed := 0.0
@onready var feedback_director: FeedbackDirector = $FeedbackDirector
@onready var audio_controller: GameAudioController = $AudioController
var ball: RigidBody2D
var camera: Camera2D
var level_builder
var level_root: Node2D
var normal_ball_linear_damp := 0.0
var active_sand_tiles := 0
var active_direction_pushes: Array[Vector2] = []
var hazard_resetting := false
var out_of_bounds_active := false
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
var menu_button: Button
var main_menu_overlay: PanelContainer
var main_menu_title_label: Label
var main_menu_summary_label: Label
var main_menu_logo: UILogo
var title_attract_mode: TitleAttractMode
var menu_resume_button: Button
var menu_play_button: Button
var menu_tutorial_button: Button
var menu_skip_button: Button
var menu_settings_button: Button
var menu_quit_button: Button
var menu_seed_input: LineEdit
var menu_seed_button: Button
var menu_seed_status_label: Label
var settings_screen: SettingsScreen
var game_settings: GameSettings
var interstitial_overlay: PanelContainer
var interstitial_title_label: Label
var interstitial_body_label: Label
var interstitial_continue_button: Button
var loading_next_level := false
var shop_manager
var shop_presentation
var tutorial_manager
var release_hud
var transition_presentation
var tutorial_mode := false
var impulse_modifier := 1.0
var drag_modifier := 1.0
var roll_damp_modifier := 1.0
var trajectory_dot_bonus := 0
var sand_damp_modifier := 1.0
var direction_push_modifier := 1.0
var reward_bonus := 0
var birdie_reward_bonus := 0
var terrain_mitigation_modifier := 0.0
var cup_radius_scale := 1.0
var active_hazard_count_modifier := 0
var active_hazard_type: StringName = &""
var owned_cards: Array[String] = []
var owned_card_definitions: Array[CardDefinition] = []
var active_card_curses: Array[ActiveCardCurse] = []
var last_expired_curses: Array[String] = []
var biome_profiles: Array = BiomeDatabase.get_profiles()
var levels: Array[Dictionary] = []
var normal_levels: Array[Dictionary] = []
var tutorial_levels: Array[Dictionary] = TutorialDatabase.get_levels()
var run_stats := RunStatsScript.new()


func _ready() -> void:
	game_settings = GameSettingsScript.new()
	game_settings.load_from()
	game_settings.apply_runtime()
	_create_world()
	_apply_player_settings()
	_reset_run_state()
	_set_run_phase(RunPhase.MAIN_MENU)
	_show_main_menu()


func _process(delta: float) -> void:
	if _is_hole_play_active():
		level_elapsed += delta
		run_stats.update_time(delta)
	_center_camera_on_ball()
	if audio_controller and ball:
		audio_controller.update_ball_roll(ball.linear_velocity.length(), _is_hole_play_active() and ball.shot_in_progress)
	if not levels.is_empty() and level_index >= 0 and level_index < levels.size():
		_update_status()


func _physics_process(delta: float) -> void:
	if not _is_hole_play_active() or hazard_resetting:
		return
	_update_out_of_bounds_recovery(delta)

	for direction in active_direction_pushes:
		ball.apply_central_force(direction * DIRECTION_PUSH_FORCE * direction_push_modifier)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_level") and _is_hole_play_active():
		_reset_current_level()
	if event.is_action_pressed("toggle_debug"):
		_toggle_debug_hud()


func _create_world() -> void:
	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)

	ball = BALL_SCENE.instantiate()
	ball.shot_started.connect(feedback_director.play_shot_feedback)
	ball.shot_started.connect(_on_ball_shot_started)
	ball.shot_finished.connect(_on_ball_shot_finished)
	ball.ball_stopped.connect(feedback_director.play_stop_feedback)
	ball.wall_impact.connect(_on_ball_wall_impact)
	ball.tee_left.connect(_on_ball_left_tee)
	ball.elevation_changed.connect(_on_ball_elevation_changed)
	add_child(ball)
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
	feedback_director.sound_requested.connect(audio_controller.play_feedback)
	release_hud = ReleaseHUDScript.new()
	release_hud.setup(hud_canvas_layer)
	release_hud.seed_copy_requested.connect(_on_seed_copy_requested)

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
	power_meter.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	power_meter.offset_left = 16.0
	power_meter.offset_top = -186.0
	power_meter.offset_right = 80.0
	power_meter.offset_bottom = -16.0
	hud_canvas_layer.add_child(power_meter)

	_create_main_menu_overlay()
	settings_screen = SettingsScreenScript.new()
	settings_screen.setup(hud_canvas_layer, game_settings)
	settings_screen.close_requested.connect(_on_settings_closed)
	settings_screen.settings_changed.connect(_on_settings_changed)
	_create_interstitial_overlay()
	transition_presentation = TransitionPresentationScript.new()
	transition_presentation.setup(interstitial_overlay, interstitial_title_label, interstitial_body_label)

	shop_manager = ShopManagerScript.new()
	shop_manager.card_bought.connect(_on_shop_card_bought)
	shop_manager.continued.connect(_on_shop_continued)
	shop_manager.feedback_requested.connect(_on_shop_feedback_requested)
	add_child(shop_manager)
	shop_manager.create_overlay(hud_canvas_layer)
	shop_presentation = ShopPresentationScript.new()
	shop_presentation.setup(shop_manager)

	tutorial_manager = TutorialManagerScript.new()
	tutorial_manager.skip_requested.connect(_on_tutorial_skip_requested)
	add_child(tutorial_manager)
	tutorial_manager.setup(self, hud_canvas_layer)
	tutorial_manager.set_visible_enabled(false)
	_apply_release_theme()
	ball.set_input_enabled(false)
	ball.visible = false
	_center_camera_on_ball()


func _apply_release_theme() -> void:
	score_label.theme = RELEASE_THEME
	effects_status_label.theme = RELEASE_THEME
	debug_hud.theme = RELEASE_THEME
	release_hud.theme = RELEASE_THEME
	menu_button.theme = RELEASE_THEME
	main_menu_overlay.theme = RELEASE_THEME
	settings_screen.theme = RELEASE_THEME
	interstitial_overlay.theme = RELEASE_THEME
	shop_manager.shop_overlay.theme = RELEASE_THEME
	tutorial_manager.hint_panel.theme = RELEASE_THEME
	tutorial_manager.skip_button.theme = RELEASE_THEME


func _start_tutorial() -> void:
	_hide_main_menu()
	_hide_interstitial()
	audio_controller.play_tutorial_music()
	tutorial_mode = true
	_reset_run_state()
	levels = tutorial_levels
	tutorial_manager.set_visible_enabled(true)
	_set_run_phase(RunPhase.HOLE_PLAY)
	_load_level(0)


func _start_normal_run(seed_override := 0) -> void:
	_hide_main_menu()
	_hide_interstitial()
	tutorial_mode = false
	_reset_run_state(seed_override)
	biome_profiles = BiomeDatabase.get_profiles()
	normal_levels = HoleGenerator.generate_run(biome_profiles, run_seed)
	levels = normal_levels.duplicate(true)
	generation_fallback_count = 0
	for level in normal_levels:
		if bool(level.get("used_fallback", false)):
			generation_fallback_count += 1
	if tutorial_manager:
		tutorial_manager.set_visible_enabled(false)
	_show_run_start()


func _reset_run_state(seed_override := 0) -> void:
	transition_generation += 1
	loading_next_level = false
	if feedback_director:
		feedback_director.reset_feedback()
	if audio_controller:
		audio_controller.stop_transient_audio()
	if level_root:
		level_root.queue_free()
		level_root = null
	level_index = 0
	biome_index = 0
	hole_index = 0
	overall_hole_number = 1
	run_seed = seed_override if seed_override != 0 else _new_run_seed()
	generation_fallback_count = 0
	last_hole_reward = 0
	last_hole_forced = false
	last_hole_rating.clear()
	strokes = 0
	total_strokes = 0
	tokens = STARTING_TOKENS
	level_elapsed = 0.0
	impulse_modifier = 1.0
	drag_modifier = 1.0
	roll_damp_modifier = 1.0
	trajectory_dot_bonus = 0
	sand_damp_modifier = 1.0
	direction_push_modifier = 1.0
	reward_bonus = 0
	birdie_reward_bonus = 0
	terrain_mitigation_modifier = 0.0
	cup_radius_scale = 1.0
	active_hazard_count_modifier = 0
	active_hazard_type = &""
	owned_cards.clear()
	owned_card_definitions.clear()
	active_card_curses.clear()
	last_expired_curses.clear()
	run_stats.reset()
	_clear_hazard_effects()
	if shop_manager:
		shop_manager.reset_for_new_run()
	if ball:
		ball.apply_card_modifiers(impulse_modifier, drag_modifier, trajectory_dot_bonus, roll_damp_modifier)
		normal_ball_linear_damp = ball.get_normal_linear_damp()
		ball.set_input_enabled(false)
		ball.visible = false


func _load_level(next_index: int) -> void:
	loading_next_level = false
	_hide_interstitial()
	feedback_director.reset_feedback()
	if level_root:
		level_root.queue_free()
		level_root = null

	if levels.is_empty():
		push_error("Cannot load a hole because the active level list is empty.")
		_set_run_phase(RunPhase.MAIN_MENU)
		_show_main_menu()
		return
	if not tutorial_mode and (next_index < 0 or next_index >= TOTAL_HOLES):
		push_error("Refusing to load invalid production hole index %d." % next_index)
		_show_run_results()
		return

	level_index = next_index % levels.size() if tutorial_mode else next_index
	if not tutorial_mode:
		biome_index = level_index / HOLES_PER_BIOME
		hole_index = level_index % HOLES_PER_BIOME
		overall_hole_number = level_index + 1
	strokes = 0
	level_elapsed = 0.0
	_clear_hazard_effects()

	var level: Dictionary
	if tutorial_mode:
		level = levels[level_index]
	else:
		var base_level: Dictionary = normal_levels[level_index] if level_index < normal_levels.size() else levels[level_index]
		level = _level_with_active_card_effects(base_level)
		levels[level_index] = level
	if not LevelValidator.validate_level(level, level_index):
		if tutorial_mode:
			push_error("Tutorial level %d failed validation; returning to the main menu." % [level_index + 1])
			_set_run_phase(RunPhase.MAIN_MENU)
			_show_main_menu()
			return
		level = _level_with_active_card_effects(HoleGenerator.fallback_hole(biome_profiles[biome_index], run_seed, biome_index, hole_index))
		if not LevelValidator.validate_level(level, level_index):
			push_error("Production hole %d and its authored fallback both failed validation." % overall_hole_number)
			_show_run_results()
			return
		levels[level_index] = level
		generation_fallback_count += 1
	level_root = level_builder.build_level(level, self)
	feedback_director.configure_level(level)
	ball.configure_level(level)
	var start_position: Vector2 = level_builder.level_point(level, "start", "start_cell")
	ball.reset_to(start_position, level_builder.get_start_elevation(level), true)
	level_builder.set_active_elevation(level_builder.get_start_elevation(level))
	last_safe_shot_position = start_position
	last_safe_shot_elevation = level_builder.get_start_elevation(level)
	_cancel_out_of_bounds_recovery()
	if level.has("forced_tokens"):
		tokens = maxi(tokens, int(level.forced_tokens))
	if tutorial_mode:
		tutorial_manager.set_level(level, level_index, levels.size())
	_set_run_phase(RunPhase.HOLE_PLAY)
	_update_status()


func _on_hole_body_entered(body: Node2D) -> void:
	if body != ball or loading_next_level or run_phase != RunPhase.HOLE_PLAY:
		return

	if tutorial_mode and not tutorial_manager.can_complete_level():
		tutorial_manager.show_blocker()
		_reset_current_level()
		return

	if tutorial_mode:
		_complete_tutorial_hole()
	else:
		_complete_current_hole(true, false)


func _complete_tutorial_hole() -> void:
	loading_next_level = true
	var captured_transition := transition_generation
	var level: Dictionary = levels[level_index]
	var hole_position: Vector2 = level_builder.level_point(level, "hole", "hole_cell")
	ball.set_input_enabled(false)
	feedback_director.play_cup_feedback(hole_position, false)
	ball.sink_to(hole_position)
	await ball.sink_animation_finished
	if captured_transition != transition_generation or not tutorial_mode:
		return
	if feedback_director.completion_pause_duration > 0.0:
		await get_tree().create_timer(feedback_director.completion_pause_duration).timeout
		if captured_transition != transition_generation or not tutorial_mode:
			return
	audio_controller.play_hole_outcome(true, &"tutorial_cup")

	tokens += _token_reward_for_score(strokes, level.par)
	_advance_active_curses()
	tutorial_manager.notify_event("hole_completed")
	if level_index == levels.size() - 1:
		TutorialManagerScript.mark_tutorial_complete()
		_start_normal_run()
		return

	if bool(level.get("open_shop", false)):
		_show_shop(level_index + 1)
		await shop_manager.continued
		if captured_transition != transition_generation or not tutorial_mode:
			return
		tutorial_manager.notify_event("shop_continued")
	_load_level(level_index + 1)


func _complete_current_hole(sink_ball: bool, forced: bool) -> void:
	if tutorial_mode or loading_next_level or run_phase != RunPhase.HOLE_PLAY:
		return

	loading_next_level = true
	ball.set_input_enabled(false)
	var captured_transition := transition_generation
	var level: Dictionary = levels[level_index]
	if sink_ball:
		var hole_position: Vector2 = level_builder.level_point(level, "hole", "hole_cell")
		feedback_director.play_cup_feedback(hole_position, level_index == TOTAL_HOLES - 1)
		ball.sink_to(hole_position)
		await ball.sink_animation_finished
		if captured_transition != transition_generation or tutorial_mode or run_phase != RunPhase.HOLE_PLAY:
			return
		if feedback_director.completion_pause_duration > 0.0:
			await get_tree().create_timer(feedback_director.completion_pause_duration).timeout
	else:
		ball.linear_velocity = Vector2.ZERO
		ball.angular_velocity = 0.0

	if captured_transition != transition_generation or tutorial_mode or run_phase != RunPhase.HOLE_PLAY:
		return

	loading_next_level = false
	last_hole_reward = _token_reward_for_score(strokes, int(level.par))
	last_hole_forced = forced
	tokens += last_hole_reward
	last_hole_rating = HoleRatingScript.rate(strokes, int(level.par), level_elapsed, forced)
	run_stats.record_hole_result({
		"hole_number": overall_hole_number,
		"biome_index": biome_index,
		"biome_name": String(level.get("biome_name", "Unknown")),
		"difficulty_name": String(level.get("difficulty_name", "Normal")),
		"strokes": strokes,
		"par": int(level.par),
		"time_seconds": level_elapsed,
		"time": _format_time(level_elapsed),
		"earned": last_hole_reward,
		"wallet": tokens,
		"forced": forced,
		"stars": int(last_hole_rating.stars),
		"golf_result": String(last_hole_rating.golf_result),
		"performance": String(last_hole_rating.performance),
	})
	_advance_active_curses()
	_show_hole_results()


func _on_sand_body_entered(body: Node2D) -> void:
	if body != ball or hazard_resetting or run_phase != RunPhase.HOLE_PLAY:
		return

	run_stats.record_hazard_entered("sand")
	if tutorial_mode:
		tutorial_manager.notify_event("entered_sand")
	feedback_director.play_terrain_feedback(&"sand", ball.global_position)
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
	if tutorial_mode and hazard_type == &"water":
		tutorial_manager.notify_event("entered_water")
	if hazard_type == &"water":
		feedback_director.play_terrain_feedback(&"water", ball.global_position)
	elif hazard_type != &"falling_ice":
		feedback_director.play_hazard_feedback(hazard_type, 1.0, ball.global_position)
		audio_controller.play_hazard_triggered(hazard_type, 1.0)
	run_stats.record_hazard_reset(String(hazard_type))
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
	var level: Dictionary = levels[level_index]
	if not tutorial_mode and strokes >= int(level.par) + MAX_STROKES_OVER_PAR:
		hazard_resetting = false
		_complete_current_hole(false, true)
		return
	ball.reset_to(
		level_builder.level_point(level, "start", "start_cell"),
		level_builder.get_start_elevation(level),
		false
	)
	hazard_resetting = false


func _on_direction_body_entered(body: Node2D, area: Area2D) -> void:
	if body != ball or hazard_resetting or run_phase != RunPhase.HOLE_PLAY:
		return

	run_stats.record_hazard_entered("direction")
	if tutorial_mode:
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
	audio_controller.play_hazard_triggered(&"wall", clampf(strength, 0.0, 1.0))


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
	last_safe_shot_position = _position
	last_safe_shot_elevation = int(ball.current_elevation)
	strokes += 1
	total_strokes += 1
	run_stats.record_stroke()
	if tutorial_mode:
		tutorial_manager.notify_event("shot_taken")
	_update_status()


func _on_ball_shot_finished() -> void:
	if run_phase != RunPhase.HOLE_PLAY:
		return
	if not tutorial_mode and not loading_next_level:
		var level: Dictionary = levels[level_index]
		if strokes >= int(level.par) + MAX_STROKES_OVER_PAR:
			_complete_current_hole(false, true)


func _reset_current_level() -> void:
	if run_phase != RunPhase.HOLE_PLAY or levels.is_empty():
		return
	var level: Dictionary = levels[level_index]
	run_stats.record_manual_reset()
	if not tutorial_mode and strokes >= int(level.par) + MAX_STROKES_OVER_PAR:
		_complete_current_hole(false, true)
		return
	feedback_director.reset_feedback()
	audio_controller.stop_transient_audio()
	_clear_hazard_effects()
	level_builder.reset_dynamic_hazards()
	ball.reset_to(
		level_builder.level_point(level, "start", "start_cell"),
		level_builder.get_start_elevation(level),
		false
	)
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
	if not out_of_bounds_active:
		out_of_bounds_active = true
		out_of_bounds_remaining = OUT_OF_BOUNDS_RETURN_SECONDS
	out_of_bounds_remaining = maxf(out_of_bounds_remaining - maxf(delta, 0.0), 0.0)
	if release_hud:
		release_hud.show_out_of_bounds(maxi(ceili(out_of_bounds_remaining), 1))
	if out_of_bounds_remaining <= 0.0:
		_return_ball_from_out_of_bounds()


func _cancel_out_of_bounds_recovery() -> void:
	out_of_bounds_active = false
	out_of_bounds_remaining = OUT_OF_BOUNDS_RETURN_SECONDS
	if release_hud:
		release_hud.hide_out_of_bounds()


func _return_ball_from_out_of_bounds() -> void:
	if not out_of_bounds_active or not ball:
		return
	feedback_director.reset_feedback()
	audio_controller.stop_transient_audio()
	active_sand_tiles = 0
	active_direction_pushes.clear()
	ball.linear_damp = normal_ball_linear_damp
	ball.reset_to(last_safe_shot_position, last_safe_shot_elevation, false)
	_cancel_out_of_bounds_recovery()
	_update_status()


func _update_status() -> void:
	if levels.is_empty() or level_index < 0 or level_index >= levels.size():
		return
	var level: Dictionary = levels[level_index]
	var biome_name := String(level.get("biome_name", "Tutorial" if tutorial_mode else "Unknown"))
	var displayed_hole := level_index + 1 if tutorial_mode else overall_hole_number
	var displayed_total := levels.size() if tutorial_mode else TOTAL_HOLES
	if tutorial_mode:
		score_label.text = "Tutorial   Hole: %d/%d   Seed: %d\nStrokes: %d   Total: %d   Par: %d   Time: %s   Coins: %d" % [
			displayed_hole,
			displayed_total,
			run_seed,
			strokes,
			total_strokes,
			level.par,
			_format_time(level_elapsed),
			tokens
		]
	else:
		score_label.text = "%s   Biome: %d/%d   Hole: %d/%d   Overall: %d/%d   Seed: %d\nStrokes: %d   Total: %d   Par: %d   Time: %s   Coins: %d" % [
			biome_name,
			biome_index + 1,
			BIOME_COUNT,
			hole_index + 1,
			HOLES_PER_BIOME,
			overall_hole_number,
			TOTAL_HOLES,
			run_seed,
			strokes,
			total_strokes,
			level.par,
			_format_time(level_elapsed),
			tokens
		]
	hole_label.text = "Hole: %d/%d" % [displayed_hole, displayed_total]
	if not tutorial_mode:
		hole_label.text += "  Biome: %d/%d  Local: %d/%d" % [biome_index + 1, BIOME_COUNT, hole_index + 1, HOLES_PER_BIOME]
	stroke_label.text = "Strokes: %d  Total: %d" % [strokes, total_strokes]
	par_label.text = "Par: %d" % level.par
	timer_label.text = "Timer: %s" % _format_time(level_elapsed)
	tokens_label.text = "Coins: %d" % tokens
	obstacles_label.text = "Obstacles: %s" % _obstacle_summary(level)
	cards_label.text = "Cards: %s" % _cards_summary()
	effects_status_label.text = "Run bonuses: %d card%s   Active curses: %s" % [
		owned_cards.size(),
		"" if owned_cards.size() == 1 else "s",
		_active_curses_summary()
	]
	var aim_power: float = ball.get_aim_power() if ball else 0.0
	var aim_text := "%.0f deg" % ball.get_aim_direction_degrees() if ball and ball.has_active_aim() else "none"
	power_meter.set_power(aim_power)
	power_debug_label.text = "Power: %d%%" % roundi(aim_power * 100.0)
	aim_label.text = "Aim: %s" % aim_text
	if release_hud:
		release_hud.update_display({
			"biome_name": biome_name,
			"biome_number": 0 if tutorial_mode else biome_index + 1,
			"biome_total": BIOME_COUNT,
			"hole_number": displayed_hole,
			"hole_total": displayed_total,
			"strokes": strokes,
			"par": int(level.par),
			"time": _format_time(level_elapsed),
			"coins": tokens,
			"seed": run_seed,
			"bonuses": owned_cards,
			"curses": _active_curse_display_items(),
		})
		release_hud.update_shot(aim_power, aim_text)


func _toggle_debug_hud() -> void:
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
	menu_button.offset_top = 122.0
	menu_button.offset_right = -14.0
	menu_button.offset_bottom = 174.0
	menu_button.configure("MENU", &"menu", &"quiet")
	menu_button.pressed.connect(_show_main_menu)
	hud_canvas_layer.add_child(menu_button)

	main_menu_overlay = PanelContainer.new()
	main_menu_overlay.name = "MainMenuScreen"
	main_menu_overlay.visible = false
	main_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_canvas_layer.add_child(main_menu_overlay)
	main_menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	title_attract_mode = TitleAttractModeScript.new()
	title_attract_mode.name = "TitleAttractMode"
	main_menu_overlay.add_child(title_attract_mode)

	var margin := MarginContainer.new()
	margin.name = "SafeArea"
	margin.add_theme_constant_override("margin_left", 74)
	margin.add_theme_constant_override("margin_top", 54)
	margin.add_theme_constant_override("margin_right", 74)
	margin.add_theme_constant_override("margin_bottom", 54)
	main_menu_overlay.add_child(margin)

	var layout := HBoxContainer.new()
	layout.name = "TitleLayout"
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 48)
	margin.add_child(layout)

	var brand_column := VBoxContainer.new()
	brand_column.name = "BrandColumn"
	brand_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_column.size_flags_stretch_ratio = 1.35
	brand_column.alignment = BoxContainer.ALIGNMENT_CENTER
	brand_column.add_theme_constant_override("separation", 8)
	layout.add_child(brand_column)

	main_menu_logo = UILogoScript.new()
	main_menu_logo.name = "Wordmark"
	main_menu_logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_column.add_child(main_menu_logo)
	main_menu_title_label = main_menu_logo.title_label

	var action_panel := PanelContainer.new()
	action_panel.name = "ActionPanel"
	action_panel.custom_minimum_size = Vector2(410.0, 0.0)
	action_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_panel.size_flags_stretch_ratio = 0.8
	action_panel.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color(UIStyleScript.INK, 0.9), Color(UIStyleScript.GOLD, 0.55), 22, 3, 14))
	layout.add_child(action_panel)
	var action_margin := MarginContainer.new()
	action_margin.add_theme_constant_override("margin_left", 32)
	action_margin.add_theme_constant_override("margin_top", 31)
	action_margin.add_theme_constant_override("margin_right", 32)
	action_margin.add_theme_constant_override("margin_bottom", 31)
	action_panel.add_child(action_margin)
	var action_layout := VBoxContainer.new()
	action_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	action_layout.add_theme_constant_override("separation", 13)
	action_margin.add_child(action_layout)

	menu_resume_button = _create_menu_button(action_layout, "RESUME ROUND", _hide_main_menu, &"continue", &"primary")
	menu_play_button = _create_menu_button(action_layout, "PLAY", _on_menu_play_pressed, &"hole", &"primary")

	var seed_panel := PanelContainer.new()
	seed_panel.name = "SeedEntry"
	seed_panel.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color(UIStyleScript.INK_DEEP, 0.72), Color(UIStyleScript.GOLD, 0.28), 12, 2, 2))
	action_layout.add_child(seed_panel)
	var seed_margin := MarginContainer.new()
	seed_margin.add_theme_constant_override("margin_left", 10)
	seed_margin.add_theme_constant_override("margin_top", 8)
	seed_margin.add_theme_constant_override("margin_right", 10)
	seed_margin.add_theme_constant_override("margin_bottom", 8)
	seed_panel.add_child(seed_margin)
	var seed_layout := VBoxContainer.new()
	seed_layout.add_theme_constant_override("separation", 5)
	seed_margin.add_child(seed_layout)
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 8)
	seed_layout.add_child(seed_row)
	menu_seed_input = LineEdit.new()
	menu_seed_input.name = "SeedInput"
	menu_seed_input.placeholder_text = "OPTIONAL SEED"
	menu_seed_input.max_length = 10
	menu_seed_input.custom_minimum_size = Vector2(220.0, 48.0)
	menu_seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_seed_input.add_theme_font_override("font", UIStyleScript.UI_BOLD_FONT)
	menu_seed_input.add_theme_font_size_override("font_size", 17)
	menu_seed_input.text_submitted.connect(func(_text: String) -> void: _on_menu_seed_pressed())
	seed_row.add_child(menu_seed_input)
	menu_seed_button = UIActionButtonScript.new()
	menu_seed_button.custom_minimum_size = Vector2(132.0, 48.0)
	menu_seed_button.configure("USE SEED", &"seed", &"secondary")
	menu_seed_button.pressed.connect(_on_menu_seed_pressed)
	seed_row.add_child(menu_seed_button)
	menu_seed_status_label = Label.new()
	menu_seed_status_label.name = "SeedStatus"
	menu_seed_status_label.text = ""
	menu_seed_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyleScript.apply_ui(menu_seed_status_label, 12, UIStyleScript.PAPER_MUTED, true)
	seed_layout.add_child(menu_seed_status_label)
	main_menu_summary_label = menu_seed_status_label

	menu_tutorial_button = _create_menu_button(action_layout, "TUTORIAL", _on_menu_restart_tutorial_pressed, &"tutorial", &"secondary")
	menu_settings_button = _create_menu_button(action_layout, "SETTINGS", _on_menu_settings_pressed, &"control", &"secondary")
	menu_quit_button = _create_menu_button(action_layout, "QUIT", _on_menu_quit_pressed, &"quit", &"danger")


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


func _create_menu_button(parent: Control, text: String, callback: Callable, icon_name: StringName, variant: StringName) -> Button:
	var button := UIActionButtonScript.new()
	button.custom_minimum_size = Vector2(350.0, 68.0)
	button.pressed.connect(callback)
	parent.add_child(button)
	button.configure(text, icon_name, variant)
	return button


func _show_main_menu() -> void:
	if not main_menu_overlay:
		return
	menu_resume_button.visible = level_root != null and run_phase == RunPhase.HOLE_PLAY
	menu_play_button.visible = true
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
	menu_button.visible = run_phase == RunPhase.HOLE_PLAY
	_update_gameplay_simulation_pause()
	_refresh_ball_input()


func _on_menu_play_pressed() -> void:
	TutorialManagerScript.mark_tutorial_complete()
	_start_normal_run()


func _on_menu_seed_pressed() -> void:
	var parsed := SeedCodecScript.parse_seed(menu_seed_input.text)
	menu_seed_status_label.text = String(parsed.message)
	UIStyleScript.apply_ui(
		menu_seed_status_label,
		12,
		UIStyleScript.BONUS if bool(parsed.valid) else UIStyleScript.CURSE,
		true
	)
	if not bool(parsed.valid):
		return
	TutorialManagerScript.mark_tutorial_complete()
	_start_normal_run(int(parsed.value))


func _on_seed_copy_requested(seed_value: int) -> void:
	DisplayServer.clipboard_set(SeedCodecScript.format_seed(seed_value))
	if release_hud:
		release_hud.show_seed_copied()


func _on_menu_restart_tutorial_pressed() -> void:
	_start_tutorial()


func _on_menu_settings_pressed() -> void:
	if settings_screen:
		settings_screen.open()


func _on_settings_closed() -> void:
	if main_menu_overlay and main_menu_overlay.visible and menu_settings_button:
		menu_settings_button.grab_focus()


func _on_settings_changed(_settings: GameSettings) -> void:
	_apply_player_settings()


func _apply_player_settings() -> void:
	if not game_settings:
		return
	if ball:
		ball.apply_player_settings(game_settings.trajectory_visible, game_settings.aim_sensitivity)
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
	_start_normal_run()


func _on_menu_quit_pressed() -> void:
	get_tree().quit()


func _show_run_start() -> void:
	_set_run_phase(RunPhase.RUN_START)
	_show_interstitial(
		"TEE OFF",
		"A fresh 18-hole course is ready.\n\nSIX BIOMES  •  THREE HOLES EACH\nShops open after every biome except the last.\n\nBuy power. Carry the curse.",
		"BEGIN COURSE"
	)
	transition_presentation.show_run_start(run_seed)


func _show_biome_intro() -> void:
	biome_index = level_index / HOLES_PER_BIOME
	hole_index = level_index % HOLES_PER_BIOME
	overall_hole_number = level_index + 1
	var profile = biome_profiles[biome_index]
	audio_controller.set_biome(biome_index)
	if level_root:
		level_root.queue_free()
		level_root = null
	ball.visible = false
	_set_run_phase(RunPhase.BIOME_INTRO)
	_show_interstitial(
		String(profile.display_name).to_upper(),
		"HOLES %02d — %02d\n%s\n\nLOADOUT\nBONUS  •  %s\nCURSE   •  %s" % [
			biome_index * HOLES_PER_BIOME + 1,
			biome_index * HOLES_PER_BIOME + HOLES_PER_BIOME,
			String(profile.ambience).replace("_", " ").to_upper(),
			_cards_summary(),
			_active_curses_summary()
		],
		"PLAY HOLE %02d" % overall_hole_number
	)
	transition_presentation.show_biome(profile, biome_index + 1, BIOME_COUNT)
	feedback_director.play_progression_feedback(
		&"biome_transition",
		profile.background_palette.get("accent", Color("e2b84b"))
	)


func _show_hole_results() -> void:
	var level: Dictionary = levels[level_index]
	var score_to_par := strokes - int(level.par)
	ball.visible = false
	_clear_hazard_effects()
	_set_run_phase(RunPhase.HOLE_RESULTS)
	audio_controller.play_hole_outcome(not last_hole_forced, &"par_plus_four" if last_hole_forced else &"cup")
	_show_interstitial(
		String(last_hole_rating.get("golf_result", _score_result_heading(score_to_par, last_hole_forced))),
		_hole_result_status_copy(),
		"CONTINUE"
	)
	transition_presentation.show_hole_result(
		score_to_par,
		last_hole_forced,
		String(level.get("biome_name", "Unknown")),
		overall_hole_number,
		TOTAL_HOLES,
		{
			"strokes": strokes,
			"par": int(level.par),
			"time": _format_time(level_elapsed),
			"earned": last_hole_reward,
			"wallet": tokens,
			"rating": last_hole_rating,
			"history": run_stats.history_snapshot(),
			"current_hole": overall_hole_number,
		}
	)


func _hole_result_status_copy() -> String:
	var lines := PackedStringArray()
	var active_curses := _active_curses_summary()
	if active_curses != "None":
		lines.append("ACTIVE CURSE  •  %s" % active_curses)
	if not last_expired_curses.is_empty():
		lines.append("CURSE CLEARED  •  %s" % ", ".join(last_expired_curses))
	return "\n".join(lines)


func _advance_after_hole_results() -> void:
	if level_index >= TOTAL_HOLES - 1:
		_show_run_results()
		return

	if hole_index == HOLES_PER_BIOME - 1:
		_show_shop(level_index + 1)
		return

	_load_level(level_index + 1)


func _show_run_results() -> void:
	var total_par := _total_par()
	var score_to_par := total_strokes - total_par
	if level_root:
		level_root.queue_free()
		level_root = null
	ball.visible = false
	run_stats.print_summary(total_par)
	_set_run_phase(RunPhase.RUN_RESULTS)
	audio_controller.play_results_music()
	_show_interstitial(
		"COURSE COMPLETE",
		"SIX BIOMES  •  EIGHTEEN FLAGS\nThe course remembers every choice.\n\nBAG  •  %s\nACTIVE CURSES  •  %s" % [
			_cards_summary(),
			_active_curses_summary()
		],
		"SEE ENDING"
	)
	transition_presentation.show_run_results({
		"grade": _letter_grade(score_to_par),
		"score": _format_score_to_par(score_to_par),
		"strokes": total_strokes,
		"par": total_par,
		"time": _format_time(run_stats.total_run_time),
		"coins": tokens,
		"seed": run_seed,
		"cards": owned_card_definitions,
	})
	feedback_director.play_progression_feedback(&"final_completion", Color("e2b84b"))


func _show_ending() -> void:
	_set_run_phase(RunPhase.ENDING)
	_show_interstitial(
		"ANOTHER ROUND?",
		"Six biomes crossed. Eighteen flags down.\n\nYour strange little bag did its job.\nA fresh course is already being dealt.",
		"NEW RUN"
	)
	transition_presentation.show_ending()
	feedback_director.play_progression_feedback(&"ending_transition", Color("17221f"))


func _on_interstitial_continue_pressed() -> void:
	match run_phase:
		RunPhase.RUN_START:
			_show_biome_intro()
		RunPhase.BIOME_INTRO:
			_load_level(level_index)
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


func _set_run_phase(next_phase: RunPhase) -> void:
	run_phase = next_phase
	var gameplay_hud_visible := run_phase == RunPhase.HOLE_PLAY
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
	var should_pause := run_phase != RunPhase.HOLE_PLAY or menu_open
	if ball:
		ball.set_gameplay_simulation_paused(should_pause)
	if level_builder:
		level_builder.set_gameplay_simulation_paused(should_pause)


func _refresh_ball_input() -> void:
	if not ball:
		return
	var menu_open := main_menu_overlay != null and main_menu_overlay.visible
	ball.set_input_enabled(run_phase == RunPhase.HOLE_PLAY and not loading_next_level and not hazard_resetting and not menu_open)


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
	var score_to_par := final_strokes - par
	var reward := 0
	if score_to_par <= -1:
		reward = 3
	elif score_to_par == 0:
		reward = 2
	elif score_to_par == 1:
		reward = 1
	var performance_bonus := birdie_reward_bonus if score_to_par <= -1 else 0
	return reward + reward_bonus + performance_bonus


func _total_par() -> int:
	var total := 0
	for level in levels:
		total += int(level.par)
	return total


func _show_shop(next_level_index: int) -> void:
	_hide_interstitial()
	_set_run_phase(RunPhase.SHOP)
	var level: Dictionary = levels[level_index]
	var forced_cards: Array[String] = []
	for card_name in level.get("shop_cards", []):
		forced_cards.append(String(card_name))
	var explicit_cards: Array[CardDefinition] = []
	var existing_card_ids: Array[StringName] = []
	for owned_card in owned_card_definitions:
		existing_card_ids.append(owned_card.id)
	if tutorial_mode:
		explicit_cards.assign(TutorialDatabase.get_tutorial_cards())
	shop_manager.show_shop(
		next_level_index,
		tokens,
		levels.size(),
		run_seed,
		forced_cards,
		_shop_destination(next_level_index),
		explicit_cards,
		int(level.get("minimum_shop_purchases", 0)),
		existing_card_ids
	)
	if tutorial_mode:
		tutorial_manager.notify_event("shop_opened")
	_update_status()


func _on_shop_continued() -> void:
	if tutorial_mode or run_phase != RunPhase.SHOP:
		return
	level_index += 1
	biome_index = level_index / HOLES_PER_BIOME
	hole_index = level_index % HOLES_PER_BIOME
	overall_hole_number = level_index + 1
	_show_biome_intro()


func _shop_destination(next_level_index: int) -> String:
	if tutorial_mode:
		return "Tutorial Hole %d/%d" % [next_level_index % levels.size() + 1, levels.size()]
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
	tokens -= card.price
	_apply_card(card)
	_update_status()


func _on_shop_feedback_requested(kind: StringName) -> void:
	match kind:
		&"purchase":
			audio_controller.play_purchase()
		&"error":
			audio_controller.play_error()


func _apply_card(card: CardDefinition) -> void:
	owned_card_definitions.append(card)
	active_card_curses.append(ActiveCardCurseScript.new(card))
	owned_cards.append(card.name)
	run_stats.record_card_bought(card.name)
	_refresh_card_effects()
	if tutorial_mode:
		tutorial_manager.notify_event("card_bought")


func _refresh_card_effects() -> void:
	var effects: CardEffectSet = CardEffectResolverScript.resolve(owned_card_definitions, active_card_curses)
	impulse_modifier = 1.0 + effects.shot_power_delta
	drag_modifier = 1.0 + effects.power_control_delta
	roll_damp_modifier = 1.0 + effects.roll_damping_delta
	trajectory_dot_bonus = effects.trajectory_dot_delta
	terrain_mitigation_modifier = effects.terrain_mitigation_delta
	sand_damp_modifier = 1.0 - terrain_mitigation_modifier
	direction_push_modifier = 1.0 - effects.direction_mitigation_delta
	reward_bonus = effects.coin_reward_delta
	birdie_reward_bonus = effects.birdie_reward_delta
	active_hazard_count_modifier = effects.hazard_count_delta
	active_hazard_type = effects.hazard_type
	cup_radius_scale = 1.0 + effects.cup_radius_scale_delta
	if ball:
		ball.apply_card_modifiers(impulse_modifier, drag_modifier, trajectory_dot_bonus, roll_damp_modifier)
		normal_ball_linear_damp = ball.get_normal_linear_damp()


func _advance_active_curses() -> void:
	last_expired_curses.clear()
	for curse_index in range(active_card_curses.size() - 1, -1, -1):
		var active_curse := active_card_curses[curse_index]
		if active_curse.advance_hole():
			last_expired_curses.append(active_curse.card.name)
			active_card_curses.remove_at(curse_index)
	last_expired_curses.reverse()
	_refresh_card_effects()


func _level_with_active_card_effects(base_level: Dictionary) -> Dictionary:
	var modifier_seed := run_seed + (level_index + 1) * 104729 + active_hazard_count_modifier * 1009
	var level := HoleGenerator.apply_hazard_modifier(
		base_level,
		active_hazard_count_modifier,
		active_hazard_type,
		modifier_seed
	)
	level["cup_radius"] = float(base_level.get("cup_radius", 28.0)) * cup_radius_scale
	level["card_cup_radius_scale"] = cup_radius_scale
	return level


func _terrain_entry_speed_scale(base_scale: float) -> float:
	if terrain_mitigation_modifier >= 0.0:
		return lerpf(base_scale, 1.0, terrain_mitigation_modifier)
	return clampf(base_scale * (1.0 + terrain_mitigation_modifier), 0.1, 1.0)


func _terrain_damp(base_damp: float) -> float:
	return maxf(base_damp * sand_damp_modifier, normal_ball_linear_damp)


func _active_curses_summary() -> String:
	if active_card_curses.is_empty():
		return "None"
	var summaries: Array[String] = []
	for active_curse in active_card_curses:
		summaries.append(active_curse.summary())
	return ", ".join(summaries)


func _active_curse_display_items() -> Array[String]:
	var items: Array[String] = []
	for active_curse in active_card_curses:
		items.append("%s — %s · %d hole%s" % [
			active_curse.card.name,
			active_curse.card.curse_description,
			active_curse.remaining_holes,
			"" if active_curse.remaining_holes == 1 else "s",
		])
	return items


func _cards_summary() -> String:
	if owned_cards.is_empty():
		return "None"
	if owned_cards.size() <= 2:
		return ", ".join(owned_cards)
	return "%d owned" % owned_cards.size()


func _center_camera_on_ball() -> void:
	if camera and ball:
		camera.global_position = ball.global_position


func _add_penalty_stroke() -> void:
	strokes += 1
	total_strokes += 1
	run_stats.record_stroke()
	_update_status()


func _on_tutorial_skip_requested() -> void:
	TutorialManagerScript.mark_tutorial_complete()
	_start_normal_run()
