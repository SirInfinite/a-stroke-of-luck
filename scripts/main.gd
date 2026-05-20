extends Node2D

const BALL_SCENE := preload("res://scenes/golf_ball.tscn")

const COURSE_SIZE := Vector2(1000.0, 600.0)
const WALL_THICKNESS := 30.0
const CHECKER_SIZE := 50.0
const GREEN_DARK := Color(0.232, 0.554, 0.248, 1.0)
const GREEN_DARKER := Color(0.161, 0.447, 0.201, 1.0)
const BORDER_BROWN := Color(0.34, 0.19, 0.09)
const STARTING_TOKENS := 2

const LEVELS := [
	{
		"start": Vector2(-360.0, 0.0),
		"hole": Vector2(360.0, 0.0),
		"par": 2,
		"obstacles": []
	},
	{
		"start": Vector2(-400.0, -180.0),
		"hole": Vector2(400.0, 180.0),
		"par": 3,
		"obstacles": [
			{"pos": Vector2(0.0, 0.0), "size": Vector2(45.0, 320.0)}
		]
	},
	{
		"start": Vector2(-400.0, 200.0),
		"hole": Vector2(400.0, -200.0),
		"par": 4,
		"obstacles": [
			{"pos": Vector2(-140.0, 20.0), "size": Vector2(45.0, 320.0)},
			{"pos": Vector2(140.0, -20.0), "size": Vector2(45.0, 320.0)}
		]
	},
	{
		"start": Vector2(-430.0, 0.0),
		"hole": Vector2(420.0, 0.0),
		"par": 4,
		"obstacles": [
			{"pos": Vector2(-80.0, -140.0), "size": Vector2(260.0, 45.0)},
			{"pos": Vector2(80.0, 140.0), "size": Vector2(260.0, 45.0)}
		]
	},
	{
		"start": Vector2(-430.0, -200.0),
		"hole": Vector2(420.0, 200.0),
		"par": 5,
		"obstacles": [
			{"pos": Vector2(-160.0, -60.0), "size": Vector2(45.0, 300.0)},
			{"pos": Vector2(20.0, 80.0), "size": Vector2(45.0, 300.0)},
			{"pos": Vector2(200.0, -60.0), "size": Vector2(45.0, 300.0)}
		]
	}
]

var level_index := 0
var strokes := 0
var total_strokes := 0
var tokens := STARTING_TOKENS
var level_elapsed := 0.0
var ball: RigidBody2D
var level_root: Node2D
var hole_label: Label
var stroke_label: Label
var par_label: Label
var timer_label: Label
var tokens_label: Label
var obstacles_label: Label
var aim_label: Label
var power_meter: ProgressBar
var loading_next_level := false


func _ready() -> void:
	get_viewport().size_changed.connect(_center_course)
	_create_world()
	_load_level(0)


func _process(delta: float) -> void:
	if not loading_next_level:
		level_elapsed += delta
	_update_status()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_level"):
		_reset_current_level()


func _create_world() -> void:
	ball = BALL_SCENE.instantiate()
	ball.shot_finished.connect(_on_ball_shot_finished)
	add_child(ball)

	var canvas_layer := CanvasLayer.new()
	add_child(canvas_layer)

	var hud := VBoxContainer.new()
	hud.position = Vector2(16, 16)
	hud.custom_minimum_size = Vector2(260, 0)
	canvas_layer.add_child(hud)

	hole_label = _create_hud_label(hud)
	stroke_label = _create_hud_label(hud)
	par_label = _create_hud_label(hud)
	timer_label = _create_hud_label(hud)
	tokens_label = _create_hud_label(hud)
	obstacles_label = _create_hud_label(hud)
	aim_label = _create_hud_label(hud)

	var power_label := _create_hud_label(hud)
	power_label.text = "Power"

	power_meter = ProgressBar.new()
	power_meter.min_value = 0.0
	power_meter.max_value = 100.0
	power_meter.value = 0.0
	power_meter.show_percentage = true
	power_meter.custom_minimum_size = Vector2(220, 18)
	hud.add_child(power_meter)

	_center_course()


func _load_level(next_index: int) -> void:
	loading_next_level = false
	if level_root:
		level_root.queue_free()

	level_index = next_index % LEVELS.size()
	strokes = 0
	level_elapsed = 0.0
	level_root = Node2D.new()
	level_root.name = "Level"
	level_root.z_index = -1
	add_child(level_root)

	var level: Dictionary = LEVELS[level_index]
	_create_floor()
	_create_bounds()
	_create_hole(level.hole)

	for obstacle in level.obstacles:
		_create_box(obstacle.pos, obstacle.size, Color(0.45, 0.5, 0.55))

	ball.reset_to(level.start)
	_update_status()


func _create_floor() -> void:
	var body := StaticBody2D.new()
	body.name = "Green"
	body.collision_layer = 2
	body.collision_mask = 1
	level_root.add_child(body)

	var visual := Polygon2D.new()
	visual.polygon = _rectangle_polygon(COURSE_SIZE)
	visual.color = GREEN_DARK
	body.add_child(visual)

	_create_checkerboard(body)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = COURSE_SIZE
	collision.shape = shape
	body.add_child(collision)


func _create_bounds() -> void:
	var half_size := COURSE_SIZE / 2.0
	_create_box(Vector2(0, -half_size.y - WALL_THICKNESS / 2.0), Vector2(COURSE_SIZE.x + WALL_THICKNESS * 2.0, WALL_THICKNESS), BORDER_BROWN)
	_create_box(Vector2(0, half_size.y + WALL_THICKNESS / 2.0), Vector2(COURSE_SIZE.x + WALL_THICKNESS * 2.0, WALL_THICKNESS), BORDER_BROWN)
	_create_box(Vector2(-half_size.x - WALL_THICKNESS / 2.0, 0), Vector2(WALL_THICKNESS, COURSE_SIZE.y), BORDER_BROWN)
	_create_box(Vector2(half_size.x + WALL_THICKNESS / 2.0, 0), Vector2(WALL_THICKNESS, COURSE_SIZE.y), BORDER_BROWN)


func _create_box(pos: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	level_root.add_child(body)

	var visual := Polygon2D.new()
	visual.polygon = _rectangle_polygon(size)
	visual.color = color
	body.add_child(visual)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _create_hole(pos: Vector2) -> void:
	var marker := Polygon2D.new()
	marker.position = pos
	marker.polygon = _circle_polygon(22.0)
	marker.color = Color(0.02, 0.018, 0.015)
	level_root.add_child(marker)

	var area := Area2D.new()
	area.name = "Hole"
	area.position = pos
	area.body_entered.connect(_on_hole_body_entered)
	level_root.add_child(area)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 28.0
	collision.shape = shape
	area.add_child(collision)


func _create_checkerboard(parent: Node2D) -> void:
	var columns := int(ceil(COURSE_SIZE.x / CHECKER_SIZE))
	var rows := int(ceil(COURSE_SIZE.y / CHECKER_SIZE))
	var top_left := -COURSE_SIZE / 2.0

	for y in range(rows):
		for x in range(columns):
			var tile := Polygon2D.new()
			tile.position = top_left + Vector2(x + 0.5, y + 0.5) * CHECKER_SIZE
			tile.polygon = _rectangle_polygon(Vector2(CHECKER_SIZE, CHECKER_SIZE))
			tile.color = GREEN_DARK if (x + y) % 2 == 0 else GREEN_DARKER
			parent.add_child(tile)


func _on_hole_body_entered(body: Node2D) -> void:
	if loading_next_level:
		return

	if body == ball:
		loading_next_level = true
		var level: Dictionary = LEVELS[level_index]
		ball.sink_to(level.hole)
		tokens += _token_reward_for_score(strokes + 1, level.par)
		await ball.sink_animation_finished
		_load_level(level_index + 1)


func _on_ball_shot_finished() -> void:
	strokes += 1
	total_strokes += 1
	_update_status()


func _reset_current_level() -> void:
	var level: Dictionary = LEVELS[level_index]
	ball.reset_to(level.start)
	strokes = 0
	level_elapsed = 0.0
	_update_status()


func _update_status() -> void:
	var level: Dictionary = LEVELS[level_index]
	hole_label.text = "Hole: %d/%d" % [level_index + 1, LEVELS.size()]
	stroke_label.text = "Strokes: %d  Total: %d" % [strokes, total_strokes]
	par_label.text = "Par: %d" % level.par
	timer_label.text = "Timer: %s" % _format_time(level_elapsed)
	tokens_label.text = "Tokens: %d" % tokens
	obstacles_label.text = "Obstacles: %s" % _obstacle_summary(level)
	power_meter.value = ball.get_aim_power() * 100.0 if ball else 0.0
	aim_label.text = "Aim: %.0f deg" % ball.get_aim_direction_degrees() if ball and ball.has_active_aim() else "Aim: none"


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
	if score_to_par <= -1:
		return 3
	if score_to_par == 0:
		return 2
	if score_to_par == 1:
		return 1
	return 0


func _center_course() -> void:
	position = get_viewport_rect().size / 2.0


func _circle_polygon(radius: float, segments := 32) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _rectangle_polygon(size: Vector2) -> PackedVector2Array:
	var half_size := size / 2.0
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])
