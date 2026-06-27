extends Node2D

const BALL_SCENE := preload("res://scenes/golf_ball.tscn")
const LevelBuilderScript := preload("res://scripts/level_builder.gd")
const LevelDatabase := preload("res://scripts/level_database.gd")
const LevelValidator := preload("res://scripts/level_validator.gd")
const ShopManagerScript := preload("res://scripts/shop_manager.gd")

const STARTING_TOKENS := 2
const SAND_DAMP := 12.0
const SAND_ENTRY_SPEED_SCALE := 0.35
const DIRECTION_PUSH_FORCE := 950.0
const CAMERA_SHAKE_DURATION := 0.14
const CAMERA_SHAKE_INTENSITY := 5.0
const HOLE_COMPLETE_BANNER_DURATION := 0.9

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
var strokes := 0
var total_strokes := 0
var tokens := STARTING_TOKENS
var level_elapsed := 0.0
var run_elapsed := 0.0
var ball: RigidBody2D
var camera: Camera2D
var level_builder
var level_root: Node2D
var normal_ball_linear_damp := 0.0
var camera_shake_time := 0.0
var camera_shake_intensity := 0.0
var active_sand_tiles := 0
var active_direction_pushes: Array[Vector2] = []
var hazard_resetting := false
var score_label: Label
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
var loading_next_level := false
var hole_complete_banner: Control
var run_summary_overlay: Control
var run_summary_label: Label
var shop_manager
var impulse_modifier := 1.0
var drag_modifier := 1.0
var trajectory_dot_bonus := 0
var sand_damp_modifier := 1.0
var direction_push_modifier := 1.0
var reward_bonus := 0
var owned_cards: Array[String] = []
var levels := LevelDatabase.get_levels()


func _ready() -> void:
	_create_world()
	_load_level(0)


func _process(delta: float) -> void:
	if not loading_next_level:
		level_elapsed += delta
		run_elapsed += delta
	_center_camera_on_ball()
	_update_camera_shake(delta)
	_update_status()


func _physics_process(_delta: float) -> void:
	if hazard_resetting:
		return

	for direction in active_direction_pushes:
		ball.apply_central_force(direction * DIRECTION_PUSH_FORCE * direction_push_modifier)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_level") and not (run_summary_overlay and run_summary_overlay.visible):
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
	ball.shot_finished.connect(_on_ball_shot_finished)
	ball.wall_hit.connect(_on_ball_wall_hit)
	add_child(ball)
	normal_ball_linear_damp = ball.linear_damp

	level_builder = LevelBuilderScript.new()
	level_builder.hole_body_entered.connect(_on_hole_body_entered)
	level_builder.sand_body_entered.connect(_on_sand_body_entered)
	level_builder.sand_body_exited.connect(_on_sand_body_exited)
	level_builder.water_body_entered.connect(_on_water_body_entered)
	level_builder.direction_body_entered.connect(_on_direction_body_entered)
	level_builder.direction_body_exited.connect(_on_direction_body_exited)
	add_child(level_builder)

	var canvas_layer := CanvasLayer.new()
	add_child(canvas_layer)

	score_label = Label.new()
	score_label.position = Vector2(16, 16)
	score_label.add_theme_font_size_override("font_size", 18)
	canvas_layer.add_child(score_label)

	debug_hud = VBoxContainer.new()
	debug_hud.position = Vector2(16, 46)
	debug_hud.custom_minimum_size = Vector2(260, 0)
	debug_hud.visible = debug_visible
	canvas_layer.add_child(debug_hud)

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
	canvas_layer.add_child(power_meter)

	_create_hole_complete_banner(canvas_layer)
	_create_run_summary_overlay(canvas_layer)

	shop_manager = ShopManagerScript.new()
	shop_manager.card_bought.connect(_on_shop_card_bought)
	add_child(shop_manager)
	shop_manager.create_overlay(canvas_layer)
	_center_camera_on_ball()


func _load_level(next_index: int) -> void:
	loading_next_level = false
	if level_root:
		level_root.queue_free()

	level_index = next_index % levels.size()
	strokes = 0
	level_elapsed = 0.0
	_clear_hazard_effects()

	var level: Dictionary = levels[level_index]
	LevelValidator.validate_level(level, level_index)
	level_root = level_builder.build_level(level, self)
	var start_position: Vector2 = level_builder.level_point(level, "start", "start_cell")
	ball.reset_to(start_position)
	_update_status()


func _on_hole_body_entered(body: Node2D) -> void:
	if loading_next_level:
		return

	if body == ball:
		loading_next_level = true
		var level: Dictionary = levels[level_index]
		ball.sink_to(level_builder.level_point(level, "hole", "hole_cell"))
		tokens += _token_reward_for_score(strokes + 1, level.par)
		await ball.sink_animation_finished
		await _show_hole_complete_banner()
		if level_index == levels.size() - 1:
			_show_run_summary()
		else:
			_show_shop(level_index + 1)
			await shop_manager.continued
			_load_level(level_index + 1)


func _on_sand_body_entered(body: Node2D) -> void:
	if body != ball or hazard_resetting:
		return

	active_sand_tiles += 1
	ball.linear_velocity *= SAND_ENTRY_SPEED_SCALE
	ball.linear_damp = SAND_DAMP * sand_damp_modifier


func _on_sand_body_exited(body: Node2D) -> void:
	if body != ball:
		return

	active_sand_tiles = maxi(active_sand_tiles - 1, 0)
	if active_sand_tiles == 0:
		ball.linear_damp = normal_ball_linear_damp


func _on_water_body_entered(body: Node2D, water_position: Vector2) -> void:
	if body != ball or hazard_resetting or loading_next_level:
		return

	hazard_resetting = true
	active_sand_tiles = 0
	active_direction_pushes.clear()
	ball.linear_damp = normal_ball_linear_damp
	_create_splash_effect(water_position)
	ball.sink_for_reset(water_position)
	await ball.hazard_sink_finished
	var level: Dictionary = levels[level_index]
	ball.reset_to(level_builder.level_point(level, "start", "start_cell"))
	hazard_resetting = false


func _on_direction_body_entered(body: Node2D, area: Area2D) -> void:
	if body != ball or hazard_resetting:
		return

	active_direction_pushes.append(area.get_meta("direction"))


func _on_direction_body_exited(body: Node2D, area: Area2D) -> void:
	if body != ball:
		return

	active_direction_pushes.erase(area.get_meta("direction"))


func _on_ball_shot_finished() -> void:
	strokes += 1
	total_strokes += 1
	_update_status()


func _on_ball_wall_hit() -> void:
	camera_shake_time = CAMERA_SHAKE_DURATION
	camera_shake_intensity = CAMERA_SHAKE_INTENSITY


func _reset_current_level() -> void:
	var level: Dictionary = levels[level_index]
	_clear_hazard_effects()
	ball.reset_to(level_builder.level_point(level, "start", "start_cell"))
	strokes = 0
	level_elapsed = 0.0
	_update_status()


func _clear_hazard_effects() -> void:
	active_sand_tiles = 0
	active_direction_pushes.clear()
	hazard_resetting = false
	if ball:
		ball.linear_damp = normal_ball_linear_damp


func _update_camera_shake(delta: float) -> void:
	if not camera:
		return

	if camera_shake_time <= 0.0:
		camera.offset = Vector2.ZERO
		return

	camera_shake_time = maxf(camera_shake_time - delta, 0.0)
	var fade := camera_shake_time / CAMERA_SHAKE_DURATION
	camera.offset = Vector2(
		randf_range(-camera_shake_intensity, camera_shake_intensity),
		randf_range(-camera_shake_intensity, camera_shake_intensity)
	) * fade


func _update_status() -> void:
	var level: Dictionary = levels[level_index]
	score_label.text = "Hole: %d/%d   Strokes: %d   Total: %d   Par: %d   Tokens: %d" % [
		level_index + 1,
		levels.size(),
		strokes,
		total_strokes,
		level.par,
		tokens
	]
	hole_label.text = "Hole: %d/%d" % [level_index + 1, levels.size()]
	stroke_label.text = "Strokes: %d  Total: %d" % [strokes, total_strokes]
	par_label.text = "Par: %d" % level.par
	timer_label.text = "Timer: %s" % _format_time(level_elapsed)
	tokens_label.text = "Tokens: %d" % tokens
	obstacles_label.text = "Obstacles: %s" % _obstacle_summary(level)
	cards_label.text = "Cards: %s" % _cards_summary()
	var aim_power: float = ball.get_aim_power() if ball else 0.0
	power_meter.set_power(aim_power)
	power_debug_label.text = "Power: %d%%" % roundi(aim_power * 100.0)
	aim_label.text = "Aim: %.0f deg" % ball.get_aim_direction_degrees() if ball and ball.has_active_aim() else "Aim: none"


func _toggle_debug_hud() -> void:
	debug_visible = not debug_visible
	if debug_hud:
		debug_hud.visible = debug_visible


func _create_hud_label(parent: Control) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 18)
	parent.add_child(label)
	return label


func _format_time(seconds: float) -> String:
	var total_seconds := int(floor(seconds))
	var minutes := total_seconds / 60
	var remaining_seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]


func _obstacle_summary(level: Dictionary) -> String:
	var obstacles: Array = level.obstacles
	if obstacles.is_empty():
		return "None"
	return "%d wall%s" % [obstacles.size(), "" if obstacles.size() == 1 else "s"]


func _token_reward_for_score(final_strokes: int, par: int) -> int:
	var score_to_par := final_strokes - par
	var reward := 0
	if score_to_par <= -1:
		reward = 3
	elif score_to_par == 0:
		reward = 2
	elif score_to_par == 1:
		reward = 1
	return reward + reward_bonus


func _create_hole_complete_banner(parent: CanvasLayer) -> void:
	hole_complete_banner = PanelContainer.new()
	hole_complete_banner.visible = false
	hole_complete_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hole_complete_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hole_complete_banner.offset_left = 220.0
	hole_complete_banner.offset_top = 42.0
	hole_complete_banner.offset_right = -220.0
	hole_complete_banner.offset_bottom = 106.0
	parent.add_child(hole_complete_banner)

	var label := Label.new()
	label.text = "Hole Complete"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	hole_complete_banner.add_child(label)


func _show_hole_complete_banner() -> void:
	hole_complete_banner.visible = true
	hole_complete_banner.modulate = Color(1.0, 1.0, 1.0, 0.0)
	hole_complete_banner.scale = Vector2(0.92, 0.92)

	var tween := create_tween()
	tween.tween_property(hole_complete_banner, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(hole_complete_banner, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(HOLE_COMPLETE_BANNER_DURATION)
	tween.tween_property(hole_complete_banner, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	hole_complete_banner.visible = false


func _create_splash_effect(pos: Vector2) -> void:
	var splash := Node2D.new()
	splash.position = pos
	splash.z_index = 4
	level_root.add_child(splash)

	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(0.75, 0.95, 1.0, 0.95)
	ring.closed = true
	ring.points = _ellipse_points(Vector2(18.0, 10.0), 28)
	splash.add_child(ring)

	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var direction := Vector2(cos(angle), sin(angle))
		var droplet := Line2D.new()
		droplet.width = 2.0
		droplet.default_color = Color(0.65, 0.9, 1.0, 0.85)
		droplet.points = PackedVector2Array([direction * 10.0, direction * 22.0])
		splash.add_child(droplet)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(splash, "scale", Vector2(1.8, 1.8), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(splash, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(splash.queue_free)


func _ellipse_points(radii: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


func _create_run_summary_overlay(parent: CanvasLayer) -> void:
	run_summary_overlay = PanelContainer.new()
	run_summary_overlay.visible = false
	run_summary_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	run_summary_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(run_summary_overlay)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_right", 64)
	margin.add_theme_constant_override("margin_bottom", 48)
	run_summary_overlay.add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Run Complete"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	layout.add_child(title)

	run_summary_label = Label.new()
	run_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_summary_label.add_theme_font_size_override("font_size", 20)
	layout.add_child(run_summary_label)

	var restart_button := Button.new()
	restart_button.text = "Restart Run"
	restart_button.custom_minimum_size = Vector2(260, 46)
	restart_button.pressed.connect(_on_restart_run_pressed)
	layout.add_child(restart_button)


func _show_run_summary() -> void:
	var total_par := _total_par()
	var score_to_par := total_strokes - total_par
	run_summary_label.text = "Total Strokes: %d\nTotal Par: %d\nScore: %s\nCards Bought: %s\nTime: %s" % [
		total_strokes,
		total_par,
		_format_score_to_par(score_to_par),
		_cards_bought_summary(),
		_format_time(run_elapsed)
	]
	run_summary_overlay.visible = true
	_update_status()


func _total_par() -> int:
	var total := 0
	for level in levels:
		total += int(level.par)
	return total


func _format_score_to_par(score_to_par: int) -> String:
	if score_to_par == 0:
		return "Even par"
	if score_to_par > 0:
		return "+%d over par" % score_to_par
	return "%d under par" % absi(score_to_par)


func _cards_bought_summary() -> String:
	if owned_cards.is_empty():
		return "None"
	return ", ".join(owned_cards)


func _on_restart_run_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _show_shop(next_level_index: int) -> void:
	shop_manager.show_shop(next_level_index, tokens, levels.size())
	_update_status()


func _on_shop_card_bought(card: Dictionary) -> void:
	tokens -= card.cost
	_apply_card(card)
	_update_status()


func _apply_card(card: Dictionary) -> void:
	var effects: Dictionary = card.effects
	impulse_modifier = maxf(0.25, impulse_modifier + effects.get("impulse", 0.0))
	drag_modifier = maxf(0.35, drag_modifier + effects.get("drag", 0.0))
	trajectory_dot_bonus = maxi(-10, trajectory_dot_bonus + effects.get("trajectory", 0))
	sand_damp_modifier = maxf(0.25, sand_damp_modifier + effects.get("sand", 0.0))
	direction_push_modifier = maxf(0.25, direction_push_modifier + effects.get("direction", 0.0))
	reward_bonus = maxi(0, reward_bonus + effects.get("reward", 0))
	owned_cards.append(card.name)
	ball.apply_card_modifiers(impulse_modifier, drag_modifier, trajectory_dot_bonus)


func _cards_summary() -> String:
	if owned_cards.is_empty():
		return "None"
	if owned_cards.size() <= 2:
		return ", ".join(owned_cards)
	return "%d owned" % owned_cards.size()


func _center_camera_on_ball() -> void:
	if camera and ball:
		camera.global_position = ball.global_position
