extends Node2D

const BiomeDatabase := preload("res://scripts/biome_database.gd")
const HoleGenerator := preload("res://scripts/hole_generator.gd")
const LevelBuilderScript := preload("res://scripts/level_builder.gd")
const ReleaseHUDScript := preload("res://scripts/release_hud.gd")
const ShopManagerScript := preload("res://scripts/shop_manager.gd")
const ShopPresentationScript := preload("res://scripts/shop_presentation.gd")
const TrajectoryRendererScript := preload("res://scripts/trajectory_renderer.gd")
const TransitionPresentationScript := preload("res://scripts/transition_presentation.gd")

const SHOWCASE_SEED := 8675309

var profiles: Array = []
var generated_levels: Array[Dictionary] = []
var level_builder
var level_root: Node2D
var camera: Camera2D
var hud_canvas: CanvasLayer
var release_hud
var trajectory_renderer: Node2D
var shop_manager
var shop_overlay: PanelContainer
var results_overlay: PanelContainer
var state_index := 0


func _ready() -> void:
	profiles = BiomeDatabase.get_profiles()
	generated_levels = HoleGenerator.generate_run(profiles, SHOWCASE_SEED)
	camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)
	level_builder = LevelBuilderScript.new()
	add_child(level_builder)
	hud_canvas = CanvasLayer.new()
	hud_canvas.name = "PresentationCanvas"
	add_child(hud_canvas)
	release_hud = ReleaseHUDScript.new()
	release_hud.setup(hud_canvas)
	_show_state()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		state_index = mini(state_index + 1, 8)
		_show_state()
		get_viewport().set_input_as_handled()


func _show_state() -> void:
	_clear_state()
	if state_index <= 5:
		_show_biome(state_index, state_index * 3 + 2)
	elif state_index == 6:
		_show_elevation_example()
	elif state_index == 7:
		_show_shop()
	else:
		_show_results()


func _show_biome(biome_index: int, level_index: int) -> void:
	var profile = profiles[biome_index]
	var level: Dictionary = generated_levels[level_index]
	level_root = level_builder.build_level(level, self)
	_frame_level(level)
	release_hud.set_hud_visible(true)
	release_hud.update_display({
		"biome_name": profile.display_name,
		"biome_number": biome_index + 1,
		"biome_total": 6,
		"hole_number": level_index + 1,
		"hole_total": 18,
		"strokes": biome_index + 1,
		"par": int(level.par),
		"time": "1:%02d" % (biome_index * 7 + 4),
		"coins": 8 + biome_index,
		"bonuses": ["Controlled Power +15%"],
		"curses": ["Crosswind · 2 holes"],
	})
	release_hud.update_shot(0.18 if biome_index == 3 else 0.42, "24 deg")
	if biome_index == 3:
		_add_snow_trajectory(level)


func _show_elevation_example() -> void:
	var level_index := _overpass_level_index()
	var level: Dictionary = generated_levels[level_index]
	var profile_index := level_index / 3
	level_root = level_builder.build_level(level, self)
	_frame_level(level)
	release_hud.set_hud_visible(true)
	release_hud.update_display({
		"biome_name": "%s · OVERPASS" % profiles[profile_index].display_name,
		"biome_number": profile_index + 1,
		"biome_total": 6,
		"hole_number": level_index + 1,
		"hole_total": 18,
		"strokes": 3,
		"par": int(level.par),
		"time": "2:14",
		"coins": 13,
		"bonuses": ["Sand Control"],
		"curses": ["Moving Hazards +1"],
	})
	release_hud.update_shot(0.46, "31 deg")


func _add_snow_trajectory(level: Dictionary) -> void:
	trajectory_renderer = TrajectoryRendererScript.new()
	trajectory_renderer.name = "TrajectoryShowcase"
	add_child(trajectory_renderer)
	trajectory_renderer.configure_level(level)
	var start: Vector2 = level_builder.level_point(level, "start", "start_cell")
	var finish: Vector2 = level_builder.level_point(level, "hole", "hole_cell")
	var points := PackedVector2Array()
	for point_index in range(11):
		var amount := float(point_index + 1) / 12.0
		points.append(start.lerp(finish, amount) + Vector2(0.0, sin(amount * PI) * 34.0))
	trajectory_renderer.set_prediction(points, 0.18)


func _show_shop() -> void:
	release_hud.set_hud_visible(false)
	shop_manager = ShopManagerScript.new()
	add_child(shop_manager)
	shop_manager.create_overlay(hud_canvas)
	shop_overlay = shop_manager.shop_overlay
	var presentation = ShopPresentationScript.new()
	presentation.setup(shop_manager)
	var forced_cards: Array[String] = []
	shop_manager.show_shop(3, 12, 18, SHOWCASE_SEED, forced_cards, "Snow · Biome 4/6")


func _show_results() -> void:
	release_hud.set_hud_visible(false)
	results_overlay = PanelContainer.new()
	results_overlay.name = "RunResultsShowcase"
	results_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_canvas.add_child(results_overlay)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 560)
	margin.add_theme_constant_override("margin_top", 250)
	margin.add_theme_constant_override("margin_right", 560)
	margin.add_theme_constant_override("margin_bottom", 250)
	results_overlay.add_child(margin)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 28)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "RUN RESULTS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	var body := Label.new()
	body.text = "All 18 holes complete.\n\nTotal strokes  61     Total par  58     Score  +3\nPlay time  27:18     Grade  B+     Coins  14\n\nSix biomes conquered. A new seed awaits."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(body)
	var continue_button := Button.new()
	continue_button.text = "NEW RUN"
	continue_button.custom_minimum_size = Vector2(360.0, 52.0)
	layout.add_child(continue_button)
	var presentation = TransitionPresentationScript.new()
	presentation.setup(results_overlay, title, body)
	presentation.show_final()


func _frame_level(level: Dictionary) -> void:
	var start: Vector2 = level_builder.level_point(level, "start", "start_cell")
	var finish: Vector2 = level_builder.level_point(level, "hole", "hole_cell")
	camera.global_position = start.lerp(finish, 0.5)
	camera.zoom = Vector2(0.82, 0.82)


func _overpass_level_index() -> int:
	for level_index in range(3, generated_levels.size()):
		for structure in generated_levels[level_index].get("elevation_structures", []):
			if String(structure.get("type", "")) == "overpass":
				return level_index
	return 17


func _clear_state() -> void:
	if is_instance_valid(level_root):
		level_root.free()
	level_root = null
	if is_instance_valid(trajectory_renderer):
		trajectory_renderer.free()
	trajectory_renderer = null
	if is_instance_valid(shop_manager):
		shop_manager.free()
	shop_manager = null
	if is_instance_valid(shop_overlay):
		shop_overlay.free()
	shop_overlay = null
	if is_instance_valid(results_overlay):
		results_overlay.free()
	results_overlay = null
