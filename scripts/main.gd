extends Node2D

signal shop_finished

const BALL_SCENE := preload("res://scenes/golf_ball.tscn")

const GRID_CELL_SIZE := 100.0
const WALL_THICKNESS := 30.0
const CHECKER_SIZE := 50.0
const GREEN_DARK := Color(0.232, 0.554, 0.248, 1.0)
const GREEN_DARKER := Color(0.161, 0.447, 0.201, 1.0)
const BORDER_BROWN := Color(0.34, 0.19, 0.09)
const STARTING_TOKENS := 2
const SAND_DAMP := 12.0
const SAND_ENTRY_SPEED_SCALE := 0.35
const DIRECTION_PUSH_FORCE := 950.0
const SHOP_CARD_COUNT := 3
const SHOP_BOUNCE_START_OFFSET := Vector2(0.0, 150.0)
const SHOP_BOUNCE_OVERSHOOT_OFFSET := Vector2(0.0, -34.0)
const SHOP_BOUNCE_RISE_DURATION := 0.2
const SHOP_BOUNCE_SETTLE_DURATION := 0.45

const SHOP_CARDS := [
	{
		"name": "Overdrive Driver",
		"cost": 3,
		"upside": "+25% shot power",
		"downside": "-15% aim pull distance",
		"effects": {"impulse": 0.25, "drag": -0.15}
	},
	{
		"name": "Rangefinder Lens",
		"cost": 2,
		"upside": "+4 trajectory dots",
		"downside": "-10% shot power",
		"effects": {"trajectory": 4, "impulse": -0.1}
	},
	{
		"name": "Sand Cleats",
		"cost": 2,
		"upside": "Sand slows 35% less",
		"downside": "Direction pads push 25% harder",
		"effects": {"sand": -0.35, "direction": 0.25}
	},
	{
		"name": "Heavy Core",
		"cost": 2,
		"upside": "+20% aim pull distance",
		"downside": "+15% sand slowdown",
		"effects": {"drag": 0.2, "sand": 0.15}
	},
	{
		"name": "Lucky Putter",
		"cost": 3,
		"upside": "+1 token reward after each hole",
		"downside": "-2 trajectory dots",
		"effects": {"reward": 1, "trajectory": -2}
	}
]

const LEVELS := [
	{
		"map": [
			"..........",
			"..........",
			"..........",
			"..........",
			"..........",
			".........."
		],
		"start_cell": Vector2i(1, 3),
		"hole_cell": Vector2i(8, 3),
		"par": 2,
		"hazards": [],
		"obstacles": []
	},
	{
		"map": [
			"..........",
			"..........",
			"..........",
			"..........",
			"..........",
			".........."
		],
		"start_cell": Vector2i(1, 1),
		"hole_cell": Vector2i(8, 4),
		"par": 3,
		"hazards": [
			{"type": "sand", "pos": Vector2(-180.0, -40.0), "size": Vector2(160.0, 120.0)}
		],
		"obstacles": [
			{"pos": Vector2(0.0, 0.0), "size": Vector2(45.0, 320.0)}
		]
	},
	{
		"map": [
			"  ######  ",
			" ######## ",
			"##########",
			"##########",
			" ######## ",
			"  ######  "
		],
		"start_cell": Vector2i(1, 4),
		"hole_cell": Vector2i(8, 1),
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
		"map": [
			"######    ",
			"######    ",
			"##########",
			"##########",
			"    ######",
			"    ######"
		],
		"start_cell": Vector2i(0, 2),
		"hole_cell": Vector2i(9, 3),
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
		"map": [
			"#####     ",
			"#######   ",
			"  ########",
			"  ########",
			"   #######",
			"     #####"
		],
		"start_cell": Vector2i(0, 0),
		"hole_cell": Vector2i(9, 5),
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
var cards_label: Label
var power_meter: ProgressBar
var loading_next_level := false
var shop_overlay: Control
var shop_tokens_label: Label
var shop_status_label: Label
var shop_card_buttons: Array[Button] = []
var current_shop_cards: Array[Dictionary] = []
var shop_visits := 0
var shop_intro_tween: Tween
var impulse_modifier := 1.0
var drag_modifier := 1.0
var trajectory_dot_bonus := 0
var sand_damp_modifier := 1.0
var direction_push_modifier := 1.0
var reward_bonus := 0
var owned_cards: Array[String] = []


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
		ball.apply_central_force(direction * DIRECTION_PUSH_FORCE * direction_push_modifier)


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
	cards_label = _create_hud_label(hud)

	var power_label := _create_hud_label(hud)
	power_label.text = "Power"

	power_meter = ProgressBar.new()
	power_meter.min_value = 0.0
	power_meter.max_value = 100.0
	power_meter.value = 0.0
	power_meter.show_percentage = true
	power_meter.custom_minimum_size = Vector2(220, 18)
	hud.add_child(power_meter)

	_create_shop_overlay(canvas_layer)
	_center_camera_on_ball()


func _load_level(next_index: int) -> void:
	loading_next_level = false
	if level_root:
		level_root.queue_free()

	level_index = next_index % LEVELS.size()
	strokes = 0
	level_elapsed = 0.0
	_clear_hazard_effects()
	level_root = Node2D.new()
	level_root.name = "Level"
	level_root.z_index = -1
	add_child(level_root)

	var level: Dictionary = LEVELS[level_index]
	_create_course(level)
	var start_position := _level_point(level, "start", "start_cell")
	var hole_position := _level_point(level, "hole", "hole_cell")
	_create_hole(hole_position)
	_create_hazards(level)

	for obstacle in level.obstacles:
		_create_box(obstacle.pos, obstacle.size, Color(0.45, 0.5, 0.55))

	ball.reset_to(start_position)
	_update_status()


func _create_course(level: Dictionary) -> void:
	_create_floor(level)
	_create_bounds(level)


func _create_floor(level: Dictionary) -> void:
	var body := StaticBody2D.new()
	body.name = "Green"
	body.collision_layer = 2
	body.collision_mask = 1
	level_root.add_child(body)

	for cell in _playable_cells(level):
		var cell_center := _cell_to_world(level, cell)

		var visual := Polygon2D.new()
		visual.position = cell_center
		visual.polygon = _rectangle_polygon(Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE))
		visual.color = GREEN_DARK if (cell.x + cell.y) % 2 == 0 else GREEN_DARKER
		body.add_child(visual)

		var collision := CollisionShape2D.new()
		collision.position = cell_center
		var shape := RectangleShape2D.new()
		shape.size = Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE)
		collision.shape = shape
		body.add_child(collision)


func _create_bounds(level: Dictionary) -> void:
	var directions := [
		{"cell": Vector2i(0, -1), "offset": Vector2(0.0, -GRID_CELL_SIZE / 2.0 - WALL_THICKNESS / 2.0), "size": Vector2(GRID_CELL_SIZE + WALL_THICKNESS * 2.0, WALL_THICKNESS)},
		{"cell": Vector2i(1, 0), "offset": Vector2(GRID_CELL_SIZE / 2.0 + WALL_THICKNESS / 2.0, 0.0), "size": Vector2(WALL_THICKNESS, GRID_CELL_SIZE + WALL_THICKNESS * 2.0)},
		{"cell": Vector2i(0, 1), "offset": Vector2(0.0, GRID_CELL_SIZE / 2.0 + WALL_THICKNESS / 2.0), "size": Vector2(GRID_CELL_SIZE + WALL_THICKNESS * 2.0, WALL_THICKNESS)},
		{"cell": Vector2i(-1, 0), "offset": Vector2(-GRID_CELL_SIZE / 2.0 - WALL_THICKNESS / 2.0, 0.0), "size": Vector2(WALL_THICKNESS, GRID_CELL_SIZE + WALL_THICKNESS * 2.0)}
	]

	for cell in _playable_cells(level):
		for direction in directions:
			var neighbor: Vector2i = cell + direction.cell
			if not _is_playable_cell(level, neighbor):
				_create_box(_cell_to_world(level, cell) + direction.offset, direction.size, BORDER_BROWN)


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


func _on_hole_body_entered(body: Node2D) -> void:
	if loading_next_level:
		return

	if body == ball:
		loading_next_level = true
		var level: Dictionary = LEVELS[level_index]
		ball.sink_to(_level_point(level, "hole", "hole_cell"))
		tokens += _token_reward_for_score(strokes + 1, level.par)
		await ball.sink_animation_finished
		_show_shop(level_index + 1)
		await shop_finished
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
	ball.sink_for_reset(water_position)
	await ball.hazard_sink_finished
	var level: Dictionary = LEVELS[level_index]
	ball.reset_to(_level_point(level, "start", "start_cell"))
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
	_clear_hazard_effects()
	ball.reset_to(_level_point(level, "start", "start_cell"))
	strokes = 0
	level_elapsed = 0.0
	_update_status()


func _clear_hazard_effects() -> void:
	active_sand_tiles = 0
	active_direction_pushes.clear()
	hazard_resetting = false
	if ball:
		ball.linear_damp = normal_ball_linear_damp


func _update_status() -> void:
	var level: Dictionary = LEVELS[level_index]
	hole_label.text = "Hole: %d/%d" % [level_index + 1, LEVELS.size()]
	stroke_label.text = "Strokes: %d  Total: %d" % [strokes, total_strokes]
	par_label.text = "Par: %d" % level.par
	timer_label.text = "Timer: %s" % _format_time(level_elapsed)
	tokens_label.text = "Tokens: %d" % tokens
	obstacles_label.text = "Obstacles: %s" % _obstacle_summary(level)
	cards_label.text = "Cards: %s" % _cards_summary()
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


func _level_point(level: Dictionary, world_key: String, cell_key: String) -> Vector2:
	if level.has(cell_key):
		return _cell_to_world(level, level[cell_key])
	return level.get(world_key, Vector2.ZERO)


func _playable_cells(level: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var rows: Array = level.map
	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var cell := Vector2i(x, y)
			if _is_playable_cell(level, cell):
				cells.append(cell)
	return cells


func _is_playable_cell(level: Dictionary, cell: Vector2i) -> bool:
	var rows: Array = level.map
	if cell.y < 0 or cell.y >= rows.size():
		return false

	var row: String = rows[cell.y]
	if cell.x < 0 or cell.x >= row.length():
		return false

	return row[cell.x] != " "


func _cell_to_world(level: Dictionary, cell: Vector2i) -> Vector2:
	var rows: Array = level.map
	var columns := 0
	for row in rows:
		columns = maxi(columns, String(row).length())

	var map_size := Vector2(float(columns), float(rows.size())) * GRID_CELL_SIZE
	var top_left := -map_size / 2.0
	return top_left + Vector2(float(cell.x) + 0.5, float(cell.y) + 0.5) * GRID_CELL_SIZE


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


func _create_shop_overlay(parent: CanvasLayer) -> void:
	shop_overlay = PanelContainer.new()
	shop_overlay.visible = false
	shop_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(shop_overlay)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 40)
	shop_overlay.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Clubhouse Shop"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	layout.add_child(title)

	shop_tokens_label = Label.new()
	shop_tokens_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_tokens_label.add_theme_font_size_override("font_size", 20)
	layout.add_child(shop_tokens_label)

	var cards_row := HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 14)
	layout.add_child(cards_row)

	for i in range(SHOP_CARD_COUNT):
		var button := Button.new()
		button.custom_minimum_size = Vector2(220, 210)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_shop_card_pressed.bind(i))
		cards_row.add_child(button)
		shop_card_buttons.append(button)

	shop_status_label = Label.new()
	shop_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_status_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(shop_status_label)

	var continue_button := Button.new()
	continue_button.text = "Continue to Next Hole"
	continue_button.custom_minimum_size = Vector2(260, 46)
	continue_button.pressed.connect(_on_shop_continue_pressed)
	layout.add_child(continue_button)


func _show_shop(next_level_index: int) -> void:
	current_shop_cards.clear()
	for i in range(SHOP_CARD_COUNT):
		var card_index := (shop_visits * 2 + i) % SHOP_CARDS.size()
		current_shop_cards.append(SHOP_CARDS[card_index])

	shop_visits += 1
	shop_status_label.text = "Buy any cards you can afford, or continue to hole %d." % [next_level_index % LEVELS.size() + 1]
	shop_overlay.visible = true
	_play_shop_intro_animation()
	_refresh_shop()


func _play_shop_intro_animation() -> void:
	if shop_intro_tween:
		shop_intro_tween.kill()

	shop_overlay.position = SHOP_BOUNCE_START_OFFSET
	shop_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)

	shop_intro_tween = create_tween()
	shop_intro_tween.tween_property(shop_overlay, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	shop_intro_tween.parallel().tween_property(shop_overlay, "position", SHOP_BOUNCE_OVERSHOOT_OFFSET, SHOP_BOUNCE_RISE_DURATION).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	shop_intro_tween.chain().tween_property(shop_overlay, "position", Vector2.ZERO, SHOP_BOUNCE_SETTLE_DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _refresh_shop() -> void:
	shop_tokens_label.text = "Tokens: %d" % tokens

	for i in range(shop_card_buttons.size()):
		var button := shop_card_buttons[i]
		var card := current_shop_cards[i]
		var cost: int = card.cost
		button.text = "%s\nCost: %d tokens\n\nPower: %s\nDownside: %s" % [
			card.name,
			cost,
			card.upside,
			card.downside
		]
		button.disabled = tokens < cost

	_update_status()


func _on_shop_card_pressed(card_index: int) -> void:
	if card_index < 0 or card_index >= current_shop_cards.size():
		return

	var card := current_shop_cards[card_index]
	var cost: int = card.cost
	if tokens < cost:
		shop_status_label.text = "Not enough tokens for %s." % card.name
		return

	tokens -= cost
	_apply_card(card)
	shop_status_label.text = "Bought %s." % card.name
	_refresh_shop()


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


func _on_shop_continue_pressed() -> void:
	if shop_intro_tween:
		shop_intro_tween.kill()
		shop_intro_tween = null
	shop_overlay.position = Vector2.ZERO
	shop_overlay.modulate = Color.WHITE
	shop_overlay.visible = false
	shop_finished.emit()


func _cards_summary() -> String:
	if owned_cards.is_empty():
		return "None"
	if owned_cards.size() <= 2:
		return ", ".join(owned_cards)
	return "%d owned" % owned_cards.size()


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
