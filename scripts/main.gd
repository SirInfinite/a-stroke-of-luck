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
const RELEASE_THEME := preload("res://assets/release_theme.tres")

const STARTING_TOKENS := 2
const BIOME_COUNT := 6
const HOLES_PER_BIOME := 3
const TOTAL_HOLES := BIOME_COUNT * HOLES_PER_BIOME
const MAX_STROKES_OVER_PAR := 4
const SAND_DAMP := 12.0
const SAND_ENTRY_SPEED_SCALE := 0.35
const ROUGH_DAMP := 5.5
const ROUGH_ENTRY_SPEED_SCALE := 0.72
const DIRECTION_PUSH_FORCE := 950.0

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
	const LOW_COLOR := Color(1.0, 0.9, 0.08, 0.95)
	const HIGH_COLOR := Color(1.0, 0.08, 0.02, 0.98)
	const TRACK_COLOR := Color(0.08, 0.075, 0.055, 0.72)
	const OUTLINE_COLOR := Color(0.03, 0.025, 0.018, 0.95)
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
var active_rough_tiles := 0
var active_direction_pushes: Array[Vector2] = []
var hazard_resetting := false
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
var menu_resume_button: Button
var menu_play_button: Button
var menu_tutorial_button: Button
var menu_skip_button: Button
var interstitial_overlay: PanelContainer
var interstitial_title_label: Label
var interstitial_body_label: Label
var interstitial_continue_button: Button
var loading_next_level := false
var shop_manager
var tutorial_manager
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
	_create_world()
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


func _physics_process(_delta: float) -> void:
	if not _is_hole_play_active() or hazard_resetting:
		return

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
	ball.shot_finished.connect(feedback_director.play_stop_feedback)
	ball.shot_finished.connect(_on_ball_shot_finished)
	add_child(ball)
	normal_ball_linear_damp = ball.linear_damp

	level_builder = LevelBuilderScript.new()
	level_builder.hole_body_entered.connect(_on_hole_body_entered)
	level_builder.sand_body_entered.connect(_on_sand_body_entered)
	level_builder.sand_body_exited.connect(_on_sand_body_exited)
	level_builder.rough_body_entered.connect(_on_rough_body_entered)
	level_builder.rough_body_exited.connect(_on_rough_body_exited)
	level_builder.water_body_entered.connect(_on_water_body_entered)
	level_builder.out_body_entered.connect(_on_out_body_entered)
	level_builder.direction_body_entered.connect(_on_direction_body_entered)
	level_builder.direction_body_exited.connect(_on_direction_body_exited)
	add_child(level_builder)

	hud_canvas_layer = CanvasLayer.new()
	add_child(hud_canvas_layer)
	feedback_director.setup(ball, camera, hud_canvas_layer)
	feedback_director.sound_requested.connect(audio_controller.play_feedback)

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
	_create_interstitial_overlay()

	shop_manager = ShopManagerScript.new()
	shop_manager.card_bought.connect(_on_shop_card_bought)
	shop_manager.continued.connect(_on_shop_continued)
	shop_manager.feedback_requested.connect(_on_shop_feedback_requested)
	add_child(shop_manager)
	shop_manager.create_overlay(hud_canvas_layer)

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
	menu_button.theme = RELEASE_THEME
	main_menu_overlay.theme = RELEASE_THEME
	interstitial_overlay.theme = RELEASE_THEME
	shop_manager.shop_overlay.theme = RELEASE_THEME
	tutorial_manager.hint_panel.theme = RELEASE_THEME
	tutorial_manager.skip_button.theme = RELEASE_THEME


func _start_tutorial() -> void:
	_hide_main_menu()
	_hide_interstitial()
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
		audio_controller.update_ball_roll(0.0, false)
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
	var start_position: Vector2 = level_builder.level_point(level, "start", "start_cell")
	ball.reset_to(start_position)
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
	audio_controller.play_hole_completion()

	tokens += _token_reward_for_score(strokes, level.par)
	_advance_active_curses()
	tutorial_manager.notify_event("hole_completed")
	if level_index == levels.size() - 1:
		TutorialManagerScript.mark_tutorial_complete()
		_start_normal_run()
		return

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


func _on_rough_body_entered(body: Node2D) -> void:
	if body != ball or hazard_resetting or run_phase != RunPhase.HOLE_PLAY:
		return

	run_stats.record_hazard_entered("rough")
	if tutorial_mode:
		tutorial_manager.notify_event("entered_rough")
	feedback_director.play_terrain_feedback(&"rough", ball.global_position)
	active_rough_tiles += 1
	ball.linear_velocity *= _terrain_entry_speed_scale(ROUGH_ENTRY_SPEED_SCALE)
	ball.linear_damp = _terrain_damp(ROUGH_DAMP)


func _on_rough_body_exited(body: Node2D) -> void:
	if body != ball:
		return

	active_rough_tiles = maxi(active_rough_tiles - 1, 0)
	if active_rough_tiles == 0 and active_sand_tiles == 0:
		ball.linear_damp = normal_ball_linear_damp


func _on_water_body_entered(body: Node2D, water_position: Vector2) -> void:
	if body != ball or hazard_resetting or loading_next_level or run_phase != RunPhase.HOLE_PLAY:
		return

	run_stats.record_hazard_entered("water")
	if tutorial_mode:
		tutorial_manager.notify_event("entered_water")
	feedback_director.play_terrain_feedback(&"water", ball.global_position)
	run_stats.record_water_reset()
	_add_penalty_stroke()
	hazard_resetting = true
	var captured_transition := transition_generation
	active_sand_tiles = 0
	active_rough_tiles = 0
	active_direction_pushes.clear()
	ball.linear_damp = normal_ball_linear_damp
	ball.sink_for_reset(water_position)
	await ball.hazard_sink_finished
	if captured_transition != transition_generation or run_phase != RunPhase.HOLE_PLAY:
		return
	var level: Dictionary = levels[level_index]
	if not tutorial_mode and strokes >= int(level.par) + MAX_STROKES_OVER_PAR:
		hazard_resetting = false
		_complete_current_hole(false, true)
		return
	ball.reset_to(level_builder.level_point(level, "start", "start_cell"))
	hazard_resetting = false


func _on_out_body_entered(body: Node2D, out_position: Vector2) -> void:
	if body != ball or hazard_resetting or loading_next_level or run_phase != RunPhase.HOLE_PLAY:
		return

	run_stats.record_hazard_entered("out")
	if tutorial_mode:
		tutorial_manager.notify_event("entered_out")
	feedback_director.play_terrain_feedback(&"out", ball.global_position)
	run_stats.record_water_reset()
	_add_penalty_stroke()
	hazard_resetting = true
	var captured_transition := transition_generation
	active_sand_tiles = 0
	active_rough_tiles = 0
	active_direction_pushes.clear()
	ball.linear_damp = normal_ball_linear_damp
	ball.sink_for_reset(out_position)
	await ball.hazard_sink_finished
	if captured_transition != transition_generation or run_phase != RunPhase.HOLE_PLAY:
		return
	var level: Dictionary = levels[level_index]
	if not tutorial_mode and strokes >= int(level.par) + MAX_STROKES_OVER_PAR:
		hazard_resetting = false
		_complete_current_hole(false, true)
		return
	ball.reset_to(level_builder.level_point(level, "start", "start_cell"))
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


func _on_ball_shot_finished() -> void:
	if run_phase != RunPhase.HOLE_PLAY:
		return
	strokes += 1
	total_strokes += 1
	run_stats.record_stroke()
	if tutorial_mode:
		tutorial_manager.notify_event("shot_finished")
	_update_status()
	if not tutorial_mode and not loading_next_level:
		var level: Dictionary = levels[level_index]
		if strokes >= int(level.par) + MAX_STROKES_OVER_PAR:
			_complete_current_hole(false, true)


func _reset_current_level() -> void:
	if run_phase != RunPhase.HOLE_PLAY or levels.is_empty():
		return
	var level: Dictionary = levels[level_index]
	run_stats.record_manual_reset()
	feedback_director.reset_feedback()
	_clear_hazard_effects()
	ball.reset_to(level_builder.level_point(level, "start", "start_cell"))
	strokes = 0
	level_elapsed = 0.0
	_update_status()


func _clear_hazard_effects() -> void:
	active_sand_tiles = 0
	active_rough_tiles = 0
	active_direction_pushes.clear()
	hazard_resetting = false
	if ball:
		ball.linear_damp = normal_ball_linear_damp


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
	power_meter.set_power(aim_power)
	power_debug_label.text = "Power: %d%%" % roundi(aim_power * 100.0)
	aim_label.text = "Aim: %.0f deg" % ball.get_aim_direction_degrees() if ball and ball.has_active_aim() else "Aim: none"


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
	menu_button = Button.new()
	menu_button.text = "Menu"
	menu_button.position = Vector2(1810.0, 104.0)
	menu_button.custom_minimum_size = Vector2(80.0, 38.0)
	menu_button.pressed.connect(_show_main_menu)
	hud_canvas_layer.add_child(menu_button)

	main_menu_overlay = PanelContainer.new()
	main_menu_overlay.name = "MainMenuScreen"
	main_menu_overlay.visible = false
	main_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	main_menu_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_canvas_layer.add_child(main_menu_overlay)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 720)
	margin.add_theme_constant_override("margin_top", 260)
	margin.add_theme_constant_override("margin_right", 720)
	margin.add_theme_constant_override("margin_bottom", 260)
	main_menu_overlay.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	main_menu_title_label = Label.new()
	main_menu_title_label.text = "A Stroke Of Luck"
	main_menu_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_menu_title_label.add_theme_font_size_override("font_size", 34)
	layout.add_child(main_menu_title_label)

	main_menu_summary_label = Label.new()
	main_menu_summary_label.text = "Six biomes. Eighteen holes. Every upgrade brings a curse.\nAim with mouse drag or arrow keys; shoot with release, Space, or Enter."
	main_menu_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_menu_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(main_menu_summary_label)

	menu_resume_button = _create_menu_button(layout, "Resume", _hide_main_menu)
	menu_play_button = _create_menu_button(layout, "Play 18-Hole Run", _on_menu_play_pressed)
	menu_tutorial_button = _create_menu_button(layout, "Restart Tutorial", _on_menu_restart_tutorial_pressed)
	menu_skip_button = _create_menu_button(layout, "Skip Tutorial", _on_menu_skip_tutorial_pressed)


func _create_interstitial_overlay() -> void:
	interstitial_overlay = PanelContainer.new()
	interstitial_overlay.name = "InterstitialScreen"
	interstitial_overlay.visible = false
	interstitial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	interstitial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_canvas_layer.add_child(interstitial_overlay)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 560)
	margin.add_theme_constant_override("margin_top", 235)
	margin.add_theme_constant_override("margin_right", 560)
	margin.add_theme_constant_override("margin_bottom", 235)
	interstitial_overlay.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)
	margin.add_child(layout)

	interstitial_title_label = Label.new()
	interstitial_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interstitial_title_label.add_theme_font_size_override("font_size", 38)
	layout.add_child(interstitial_title_label)

	interstitial_body_label = Label.new()
	interstitial_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interstitial_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interstitial_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interstitial_body_label.add_theme_font_size_override("font_size", 21)
	interstitial_body_label.custom_minimum_size = Vector2(0.0, 250.0)
	layout.add_child(interstitial_body_label)

	interstitial_continue_button = Button.new()
	interstitial_continue_button.custom_minimum_size = Vector2(280.0, 50.0)
	interstitial_continue_button.pressed.connect(_on_interstitial_continue_pressed)
	layout.add_child(interstitial_continue_button)


func _create_menu_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260.0, 44.0)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _show_main_menu() -> void:
	if not main_menu_overlay:
		return
	menu_resume_button.visible = level_root != null and run_phase == RunPhase.HOLE_PLAY
	menu_skip_button.visible = tutorial_mode or not TutorialManagerScript.is_tutorial_complete()
	main_menu_overlay.visible = true
	menu_button.visible = false
	_refresh_ball_input()
	if menu_resume_button.visible:
		menu_resume_button.grab_focus()
	else:
		menu_play_button.grab_focus()


func _hide_main_menu() -> void:
	if main_menu_overlay:
		main_menu_overlay.visible = false
	menu_button.visible = run_phase == RunPhase.HOLE_PLAY
	_refresh_ball_input()


func _on_menu_play_pressed() -> void:
	TutorialManagerScript.mark_tutorial_complete()
	_start_normal_run()


func _on_menu_restart_tutorial_pressed() -> void:
	_start_tutorial()


func _on_menu_skip_tutorial_pressed() -> void:
	TutorialManagerScript.mark_tutorial_complete()
	_start_normal_run()


func _show_run_start() -> void:
	_set_run_phase(RunPhase.RUN_START)
	_show_interstitial(
		"Run Intro",
		"Seed: %d\n\nSix biomes, three holes each. Hole difficulty rises from introductory to normal to hardest inside every biome. Shops appear after biomes 1-5." % run_seed,
		"Begin Course"
	)


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
		"Biome %d/%d: %s" % [biome_index + 1, BIOME_COUNT, profile.display_name],
		"Holes %d-%d\nDecorations: %s\nAmbience: %s\n\nRun bonuses: %s\nActive curses: %s\n\nOne shared generator applies this biome's palette, hazard weights, difficulty data, and active hazard curses." % [
			biome_index * HOLES_PER_BIOME + 1,
			biome_index * HOLES_PER_BIOME + HOLES_PER_BIOME,
			", ".join(profile.decoration_identifiers),
			String(profile.ambience).replace("_", " "),
			_cards_summary(),
			_active_curses_summary()
		],
		"Play Hole %d" % overall_hole_number
	)
	feedback_director.play_progression_feedback(
		&"biome_transition",
		profile.background_palette.get("accent", Color("e2b84b"))
	)


func _show_hole_results() -> void:
	var level: Dictionary = levels[level_index]
	var score_to_par := strokes - int(level.par)
	var completion_note := "Stroke ceiling reached — hole advanced safely." if last_hole_forced else "Cup completed."
	ball.visible = false
	_clear_hazard_effects()
	_set_run_phase(RunPhase.HOLE_RESULTS)
	audio_controller.play_hole_completion()
	_show_interstitial(
		"Hole %d Results" % overall_hole_number,
		"%s — %s hole %d/%d\n%s\n\nStrokes: %d   Par: %d   Score: %s\nHole time: %s   Coins earned: %d   Coins held: %d\nActive curses: %s%s" % [
			String(level.get("biome_name", "Unknown")),
			String(level.get("difficulty_name", "Normal")),
			hole_index + 1,
			HOLES_PER_BIOME,
			completion_note,
			strokes,
			int(level.par),
			_format_score_to_par(score_to_par),
			_format_time(level_elapsed),
			last_hole_reward,
			tokens,
			_active_curses_summary(),
			"\nExpired: %s" % ", ".join(last_expired_curses) if not last_expired_curses.is_empty() else ""
		],
		"Continue"
	)


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
	_show_interstitial(
		"Run Results",
		"All %d holes complete.\n\nTotal strokes: %d   Total par: %d   Score: %s\nPlay time: %s   Grade: %s\nCoins remaining: %d   Cards: %s\nSeed: %d   Generator fallbacks: %d" % [
			TOTAL_HOLES,
			total_strokes,
			total_par,
			_format_score_to_par(score_to_par),
			_format_time(run_stats.total_run_time),
			_letter_grade(score_to_par),
			tokens,
			_cards_summary(),
			run_seed,
			generation_fallback_count
		],
		"See Ending"
	)
	feedback_director.play_progression_feedback(&"final_completion", Color("e2b84b"))


func _show_ending() -> void:
	_set_run_phase(RunPhase.ENDING)
	_show_interstitial(
		"A Stroke of Luck",
		"You crossed Meadow, Desert, Autumn, Snow, Swamp, and Volcanic terrain and finished all eighteen holes.\n\nThe course is complete — but a new seed is ready whenever you are.",
		"New Run"
	)
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
	interstitial_title_label.text = title
	interstitial_body_label.text = body
	interstitial_continue_button.text = button_text
	interstitial_overlay.visible = true
	interstitial_continue_button.grab_focus()


func _hide_interstitial() -> void:
	if interstitial_overlay:
		interstitial_overlay.visible = false


func _set_run_phase(next_phase: RunPhase) -> void:
	run_phase = next_phase
	var gameplay_hud_visible := run_phase == RunPhase.HOLE_PLAY
	score_label.visible = gameplay_hud_visible
	effects_status_label.visible = gameplay_hud_visible
	debug_hud.visible = gameplay_hud_visible and debug_visible
	power_meter.visible = gameplay_hud_visible
	menu_button.visible = gameplay_hud_visible and not main_menu_overlay.visible
	_refresh_ball_input()


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
	shop_manager.show_shop(
		next_level_index,
		tokens,
		levels.size(),
		run_seed,
		forced_cards,
		_shop_destination(next_level_index)
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
