extends Node2D

const BALL_SCENE := preload("res://scenes/golf_ball.tscn")

const COURSE_SIZE := Vector2(1000.0, 600.0)
const WALL_THICKNESS := 30.0
const CHECKER_SIZE := 50.0
const GREEN_DARK := Color(0.232, 0.554, 0.248, 1.0)
const GREEN_DARKER := Color(0.161, 0.447, 0.201, 1.0)
const BORDER_BROWN := Color(0.34, 0.19, 0.09)
const STARTING_TOKENS := 2
const SAND_DAMP := 12.0
const SAND_ENTRY_SPEED_SCALE := 0.35
const DIRECTION_PUSH_FORCE := 950.0

const LEVELS := [
	{
		"start": Vector2(-360.0, 0.0),
		"hole": Vector2(360.0, 0.0),
		"par": 2,
		"hazards": [],
		"obstacles": []
	},
	{
		"start": Vector2(-400.0, -180.0),
		"hole": Vector2(400.0, 180.0),
		"par": 3,
		"hazards": [
			{"type": "sand", "pos": Vector2(-180.0, -40.0), "size": Vector2(160.0, 120.0)}
		],
		"obstacles": [
			{"pos": Vector2(0.0, 0.0), "size": Vector2(45.0, 320.0)}
		]
	},
	{
		"start": Vector2(-400.0, 200.0),
		"hole": Vector2(400.0, -200.0),
		"par": 4,
		"hazards": [
			{"type": "water", "pos": Vector2(0.0, 0.0), "size": Vector2(180.0, 140.0)}
		],
		"obstacles": [
			{"pos": Vector2(-140.0, 20.0), "size": Vector2(45.0, 320.0)},
			{"pos": Vector2(140.0, -20.0), "size": Vector2(45.0, 320.0)}
		]
	},
	{
		"start": Vector2(-430.0, 0.0),
		"hole": Vector2(420.0, 0.0),
		"par": 4,
		"hazards": [
			{"type": "direction", "pos": Vector2(-240.0, 0.0), "size": Vector2(110.0, 90.0), "direction": Vector2.RIGHT},
			{"type": "sand", "pos": Vector2(220.0, -120.0), "size": Vector2(150.0, 110.0)}
		],
		"obstacles": [
			{"pos": Vector2(-80.0, -140.0), "size": Vector2(260.0, 45.0)},
			{"pos": Vector2(80.0, 140.0), "size": Vector2(260.0, 45.0)}
		]
	},
	{
		"start": Vector2(-430.0, -200.0),
		"hole": Vector2(420.0, 200.0),
		"par": 5,
		"hazards": [
			{"type": "water", "pos": Vector2(-260.0, 40.0), "size": Vector2(160.0, 130.0)},
			{"type": "direction", "pos": Vector2(0.0, -150.0), "size": Vector2(120.0, 90.0), "direction": Vector2.DOWN},
			{"type": "direction", "pos": Vector2(260.0, 70.0), "size": Vector2(120.0, 90.0), "direction": Vector2.RIGHT}
		],
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
var camera: Camera2D
var level_root: Node2D
var normal_ball_linear_damp := 0.0
var active_sand_tiles := 0
var active_direction_pushes: Array[Vector2] = []
var hazard_resetting := false
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
	_create_world()
	_load_level(0)


func _process(delta: float) -> void:
	if not loading_next_level:
		level_elapsed += delta
	_center_camera_on_ball()
	_update_status()


func _physics_process(_delta: float) -> void:
	if hazard_resetting:
		return

	for direction in active_direction_pushes:
		ball.apply_central_force(direction * DIRECTION_PUSH_FORCE)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_level"):
		_reset_current_level()


func _create_world() -> void:
	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)

	ball = BALL_SCENE.instantiate()
	ball.shot_finished.connect(_on_ball_shot_finished)
	add_child(ball)
	normal_ball_linear_damp = ball.linear_damp

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

	_center_camera_on_ball()


func _load_level(next_index: int) -> void:
	loading_next_level = false
	if level_root:
		level_root.queue_free()

	level_index = next_index % LEVELS.size()
	strokes = 0
	level_elapsed = 0.0
	active_sand_tiles = 0
	active_direction_pushes.clear()
	hazard_resetting = false
	if ball:
		ball.linear_damp = normal_ball_linear_damp
	level_root = Node2D.new()
	level_root.name = "Level"
	level_root.z_index = -1
	add_child(level_root)

	var level: Dictionary = LEVELS[level_index]
	_create_floor()
	_create_bounds()
	_create_hole(level.hole)
	_create_hazards(level)

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


func _create_hazards(level: Dictionary) -> void:
	for hazard in level.hazards:
		match hazard.type:
			"sand":
				_create_sand_tile(hazard.pos, hazard.size)
			"water":
				_create_water_tile(hazard.pos, hazard.size)
			"direction":
				_create_direction_tile(hazard.pos, hazard.size, hazard.direction.normalized())


func _create_sand_tile(pos: Vector2, size: Vector2) -> void:
	var area := _create_hazard_area("Sand", pos, size, Color(0.78, 0.62, 0.36, 0.95))
	area.body_entered.connect(_on_sand_body_entered)
	area.body_exited.connect(_on_sand_body_exited)


func _create_water_tile(pos: Vector2, size: Vector2) -> void:
	var area := _create_hazard_area("Water", pos, size, Color(0.35, 0.72, 0.95, 0.9))
	area.body_entered.connect(_on_water_body_entered.bind(pos))


func _create_direction_tile(pos: Vector2, size: Vector2, direction: Vector2) -> void:
	var area := _create_hazard_area("Direction", pos, size, Color(0.52, 0.72, 0.62, 0.9))
	area.set_meta("direction", direction)
	area.body_entered.connect(_on_direction_body_entered.bind(area))
	area.body_exited.connect(_on_direction_body_exited.bind(area))

	var arrow := Line2D.new()
	arrow.width = 5.0
	arrow.default_color = Color(0.08, 0.18, 0.12, 0.95)
	arrow.points = PackedVector2Array([-direction * 24.0, direction * 24.0])
	area.add_child(arrow)

	var head := Polygon2D.new()
	head.position = direction * 24.0
	head.rotation = direction.angle()
	head.polygon = PackedVector2Array([
		Vector2(12.0, 0.0),
		Vector2(-8.0, -7.0),
		Vector2(-8.0, 7.0)
	])
	head.color = Color(0.08, 0.18, 0.12, 0.95)
	area.add_child(head)


func _create_hazard_area(name: String, pos: Vector2, size: Vector2, color: Color) -> Area2D:
	var area := Area2D.new()
	area.name = name
	area.position = pos
	level_root.add_child(area)

	var visual := Polygon2D.new()
	visual.polygon = _rectangle_polygon(size)
	visual.color = color
	area.add_child(visual)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)

	return area


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


func _on_sand_body_entered(body: Node2D) -> void:
	if body != ball or hazard_resetting:
		return

	active_sand_tiles += 1
	ball.linear_velocity *= SAND_ENTRY_SPEED_SCALE
	ball.linear_damp = SAND_DAMP


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
	ball.sink_for_reset(water_position)
	await ball.hazard_sink_finished
	var level: Dictionary = LEVELS[level_index]
	ball.reset_to(level.start)
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


func _center_camera_on_ball() -> void:
	if camera and ball:
		camera.global_position = ball.global_position


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
