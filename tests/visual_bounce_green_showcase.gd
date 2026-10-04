extends Node2D

const BALL_SCENE := preload("res://scenes/golf_ball.tscn")
const BiomeDatabase := preload("res://scripts/biome_database.gd")
const HoleGenerator := preload("res://scripts/hole_generator.gd")
const LevelBuilderScript := preload("res://scripts/level_builder.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

const SHOWCASE_SEED := 8675309
const LAST_STATE_INDEX := 5

var profiles: Array = []
var generated_levels: Array[Dictionary] = []
var level_builder
var level_root: Node2D
var camera: Camera2D
var ball: RigidBody2D
var motion_line: Line2D
var state_index := 0
var state_label: Label


func _ready() -> void:
	profiles = BiomeDatabase.get_profiles()
	generated_levels = HoleGenerator.generate_run(profiles, SHOWCASE_SEED)
	camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)
	level_builder = LevelBuilderScript.new()
	add_child(level_builder)
	_create_state_label()
	_show_state()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		state_index = mini(state_index + 1, LAST_STATE_INDEX)
		_show_state()
		get_viewport().set_input_as_handled()


func _show_state() -> void:
	_clear_state()
	match state_index:
		0:
			_show_putting_region(0, false, "MEADOW PUTTING REGION — FULL HOLE")
		1:
			_show_putting_region(0, true, "MEADOW CUP — TILED PUTTING REGION")
		2:
			_show_bounce_pad(false, false, "YELLOW BOUNCE PAD")
		3:
			_show_bounce_pad(true, false, "HIGH-SPEED APPROACH")
		4:
			_show_bounce_pad(true, true, "IMMEDIATELY AFTER BOUNCE")
		_:
			_show_putting_region(3, true, "DESERT PUTTING REGION — BIOME VARIANT")


func _show_putting_region(level_index: int, close_view: bool, label_text: String) -> void:
	var level: Dictionary = generated_levels[level_index]
	level_root = level_builder.build_level(level, self)
	level_builder.set_active_elevation(int(level.get("hole_elevation", 0)))
	var start: Vector2 = level_builder.level_point(level, "start", "start_cell")
	var finish: Vector2 = level_builder.level_point(level, "hole", "hole_cell")
	camera.global_position = finish if close_view else start.lerp(finish, 0.5)
	camera.zoom = Vector2(2.15, 2.15) if close_view else Vector2(0.86, 0.86)
	state_label.text = "%s  •  SEED %d" % [label_text, SHOWCASE_SEED]


func _show_bounce_pad(show_ball: bool, trigger_bounce: bool, label_text: String) -> void:
	var level := _level_with_bounce_pad()
	level_root = level_builder.build_level(level, self)
	var bounce_pad: GameplayHazard = _find_bounce_pad()
	if not bounce_pad:
		push_error("Bounce/green showcase seed did not produce a bounce pad.")
		return
	level_builder.set_active_elevation(int(bounce_pad.elevation))
	camera.global_position = bounce_pad.global_position
	camera.zoom = Vector2(2.35, 2.35)
	state_label.text = "%s  •  MIN 650  •  1.15x  •  MAX 1450" % label_text
	if not show_ball:
		return

	ball = BALL_SCENE.instantiate()
	ball.name = "ShowcaseBall"
	add_child(ball)
	var approach_start: Vector2 = bounce_pad.global_position - Vector2(92.0, 0.0)
	var crossed_end: Vector2 = bounce_pad.global_position + Vector2(92.0, 0.0)
	ball.reset_to(approach_start, int(bounce_pad.elevation), false)
	ball.freeze = true
	ball.shot_in_progress = true
	ball.linear_velocity = Vector2(2400.0, 0.0)
	if trigger_bounce:
		bounce_pad.try_swept_bounce(ball, approach_start, crossed_end)
		_add_motion_line(bounce_pad.global_position, ball.global_position, UIStyleScript.GOLD)
	else:
		_add_motion_line(approach_start, bounce_pad.global_position, UIStyleScript.PAPER)


func _level_with_bounce_pad() -> Dictionary:
	for level in generated_levels:
		for hazard in level.hazards:
			if String(hazard.type) == "bounce_pad":
				return level
	return generated_levels[0]


func _find_bounce_pad() -> GameplayHazard:
	for child in level_root.get_children():
		if child is GameplayHazard and StringName(child.hazard_type) == &"bounce_pad":
			return child as GameplayHazard
	return null


func _add_motion_line(from_position: Vector2, to_position: Vector2, color: Color) -> void:
	motion_line = Line2D.new()
	motion_line.name = "MotionDirection"
	motion_line.width = 5.0
	motion_line.default_color = Color(color, 0.88)
	motion_line.points = PackedVector2Array([from_position, to_position])
	motion_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	motion_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(motion_line)


func _create_state_label() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ShowcaseCanvas"
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.name = "StatePanel"
	panel.position = Vector2(28.0, 24.0)
	panel.custom_minimum_size = Vector2(940.0, 54.0)
	panel.add_theme_stylebox_override(
		"panel",
		UIStyleScript.panel_style(Color(UIStyleScript.INK_DEEP, 0.94), UIStyleScript.GOLD, 12, 2, 5)
	)
	canvas.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	state_label = Label.new()
	state_label.name = "StateLabel"
	UIStyleScript.apply_ui(state_label, 15, UIStyleScript.PAPER, true)
	margin.add_child(state_label)


func _clear_state() -> void:
	if is_instance_valid(level_root):
		level_root.free()
	level_root = null
	if is_instance_valid(ball):
		ball.free()
	ball = null
	if is_instance_valid(motion_line):
		motion_line.free()
	motion_line = null
