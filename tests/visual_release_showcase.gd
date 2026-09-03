extends Node2D

const BiomeDatabase := preload("res://scripts/biome_database.gd")
const HoleGenerator := preload("res://scripts/hole_generator.gd")
const LevelBuilderScript := preload("res://scripts/level_builder.gd")
const ReleaseHUDScript := preload("res://scripts/release_hud.gd")
const ShopManagerScript := preload("res://scripts/shop_manager.gd")
const ShopPresentationScript := preload("res://scripts/shop_presentation.gd")
const TrajectoryRendererScript := preload("res://scripts/trajectory_renderer.gd")
const TransitionPresentationScript := preload("res://scripts/transition_presentation.gd")
const CardDatabase := preload("res://scripts/card_database.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const UIActionButtonScript := preload("res://scripts/ui/ui_action_button.gd")
const RELEASE_THEME := preload("res://assets/release_theme.tres")

const SHOWCASE_SEED := 8675309
const LAST_SHOWCASE_STATE := 18

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
	release_hud.theme = RELEASE_THEME
	_show_state()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		state_index = mini(state_index + 1, LAST_SHOWCASE_STATE)
		_show_state()
		get_viewport().set_input_as_handled()


func _show_state() -> void:
	_clear_state()
	if state_index <= 5:
		_show_biome(state_index, state_index * 3 + 2)
	elif state_index <= 8:
		_show_elevation_example(state_index - 7)
	elif state_index == 9:
		_show_hazard(&"falling_ice", false)
	elif state_index == 10:
		_show_hazard(&"falling_ice", true)
	elif state_index == 11:
		_show_hazard(&"pendulum", false)
	elif state_index == 12:
		_show_shop()
	elif state_index == 13:
		_show_hole_results(1)
	elif state_index == 14:
		_show_hole_results(3)
	elif state_index == 15:
		_show_hole_results(5)
	elif state_index == 16:
		_show_history_result(13)
	elif state_index == 17:
		_show_history_result(5)
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
		"seed": SHOWCASE_SEED,
		"bonuses": ["Controlled Power +15%"],
		"curses": ["Crosswind · 2 holes"],
	})
	release_hud.update_shot(0.18 if biome_index == 3 else 0.42, "24 deg")
	if biome_index == 3:
		_add_snow_trajectory(level)


func _show_elevation_example(active_layer: int) -> void:
	var level_index := _overpass_level_index()
	var level: Dictionary = generated_levels[level_index]
	var profile_index := floori(float(level_index) / 3.0)
	level_root = level_builder.build_level(level, self)
	level_builder.set_active_elevation(active_layer)
	_frame_level(level)
	release_hud.set_hud_visible(true)
	release_hud.update_display({
		"biome_name": profiles[profile_index].display_name,
		"biome_number": profile_index + 1,
		"biome_total": 6,
		"hole_number": level_index + 1,
		"hole_total": 18,
		"strokes": 3,
		"par": int(level.par),
		"time": "2:14",
		"coins": 13,
		"seed": SHOWCASE_SEED,
		"bonuses": ["ACTIVE ELEVATION  %+d" % active_layer],
		"curses": ["OVERPASS READABILITY"],
	})
	release_hud.update_shot(0.46, "31 deg")


func _show_hazard(hazard_type: StringName, landed: bool) -> void:
	var level_index := 9 if hazard_type == &"falling_ice" else 2
	var level: Dictionary = generated_levels[level_index]
	var profile_index := floori(float(level_index) / 3.0)
	level_root = level_builder.build_level(level, self)
	var hazard := level_root.get_node_or_null("MovingHazard_%s" % String(hazard_type)) as MovingHazard
	if hazard and hazard_type == &"falling_ice" and landed:
		hazard.call("_trigger_falling_ice")
		hazard.call("_land_falling_ice")
	if hazard:
		level_builder.set_active_elevation(hazard.elevation)
		camera.global_position = hazard.global_position
		camera.zoom = Vector2(1.08, 1.08)
	else:
		_frame_level(level)
	release_hud.set_hud_visible(true)
	release_hud.update_display({
		"biome_name": profiles[profile_index].display_name,
		"biome_number": profile_index + 1,
		"biome_total": 6,
		"hole_number": level_index + 1,
		"hole_total": 18,
		"strokes": 2,
		"par": int(level.par),
		"time": "1:12",
		"coins": 11,
		"seed": SHOWCASE_SEED,
		"bonuses": ["LANDED WALL" if landed else "FAIR TELEGRAPH"],
		"curses": ["FALLING ICE" if hazard_type == &"falling_ice" else "SPIKY PENDULUM"],
	})
	release_hud.update_shot(0.36, "18 deg")


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
	shop_overlay.theme = RELEASE_THEME
	var presentation = ShopPresentationScript.new()
	presentation.setup(shop_manager)
	var forced_cards: Array[String] = ["Sand Cleats", "Overdrive Driver", "Lucky Putter", "Gust Guard"]
	var explicit_cards: Array[CardDefinition] = []
	var existing_card_ids: Array[StringName] = [&"sand_cleats", &"sand_cleats"]
	shop_manager.show_shop(3, 12, 18, SHOWCASE_SEED, forced_cards, "Snow · Biome 4/6", explicit_cards, 0, existing_card_ids)


func _show_hole_results(stars: int) -> void:
	release_hud.set_hud_visible(false)
	var fixture := _rating_fixture(stars)
	var screen := _create_transition_screen(
		"HoleResults%dStar" % stars,
		String(fixture.golf_result),
		"ACTIVE CURSE  •  Crosswind · 1 hole",
		"CONTINUE"
	)
	var presentation = TransitionPresentationScript.new()
	presentation.setup(screen.overlay, screen.title, screen.body)
	presentation.show_hole_result(int(fixture.score_to_par), false, "Snow", 12, 18, {
		"strokes": fixture.strokes,
		"par": fixture.par,
		"time": fixture.time,
		"earned": fixture.earned,
		"wallet": 13,
		"rating": fixture,
	})


func _show_history_result(selected_hole: int) -> void:
	release_hud.set_hud_visible(false)
	var history := _history_fixture()
	var current: Dictionary = history[12]
	var screen := _create_transition_screen(
		"HoleHistoryShowcase",
		String(current.golf_result),
		"SCROLL OR USE ARROWS TO REVIEW PLAYED HOLES",
		"CONTINUE"
	)
	var presentation = TransitionPresentationScript.new()
	presentation.setup(screen.overlay, screen.title, screen.body)
	presentation.show_hole_result(int(current.score_to_par), false, String(current.biome_name), 13, 18, {
		"strokes": current.strokes,
		"par": current.par,
		"time": current.time,
		"earned": current.earned,
		"wallet": current.wallet,
		"rating": {
			"stars": current.stars,
			"golf_result": current.golf_result,
			"performance": current.performance,
		},
		"history": history,
		"current_hole": 13,
	})
	presentation.history_selector.set_expanded(true)
	presentation.history_selector.select_hole(selected_hole)


func _rating_fixture(stars: int) -> Dictionary:
	match stars:
		5:
			return {
				"stars": 5,
				"golf_result": "EAGLE",
				"performance": "EXCEPTIONAL",
				"strokes": 2,
				"par": 4,
				"score_to_par": -2,
				"time": "0:48",
				"earned": 4,
			}
		3:
			return {
				"stars": 3,
				"golf_result": "PAR",
				"performance": "SOLID",
				"strokes": 4,
				"par": 4,
				"score_to_par": 0,
				"time": "1:35",
				"earned": 2,
			}
		_:
			return {
				"stars": 1,
				"golf_result": "TRIPLE BOGEY",
				"performance": "ROUGH ROUND",
				"strokes": 7,
				"par": 4,
				"score_to_par": 3,
				"time": "3:20",
				"earned": 1,
			}


func _history_fixture() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var biome_names := ["Meadow", "Desert", "Autumn", "Snow", "Swamp"]
	for hole_number in range(1, 14):
		var stars := 3 + (hole_number % 3) - 1
		var rating := _rating_fixture(5 if stars >= 4 else (3 if stars == 3 else 1))
		var par := int(rating.par)
		var strokes := int(rating.strokes)
		entries.append({
			"hole_number": hole_number,
			"biome_name": biome_names[floori(float(hole_number - 1) / 3.0)],
			"stars": int(rating.stars),
			"golf_result": String(rating.golf_result),
			"performance": String(rating.performance),
			"strokes": strokes,
			"par": par,
			"score_to_par": strokes - par,
			"time": "%d:%02d" % [1 + hole_number / 9, 8 + hole_number * 3],
			"earned": int(rating.earned),
			"wallet": 4 + hole_number,
		})
	return entries


func _show_results() -> void:
	release_hud.set_hud_visible(false)
	var screen := _create_transition_screen(
		"RunResultsShowcase",
		"COURSE COMPLETE",
		"SIX BIOMES  •  EIGHTEEN FLAGS\nThe course remembers every choice.\n\nBAG  •  Sand Cleats, Overdrive Driver, Gust Guard\nACTIVE CURSES  •  Crosswind · 1 hole",
		"SEE ENDING"
	)
	var cards: Array[CardDefinition] = CardDatabase.get_cards()
	var presentation = TransitionPresentationScript.new()
	presentation.setup(screen.overlay, screen.title, screen.body)
	presentation.show_run_results({
		"grade": "B+",
		"score": "+3",
		"strokes": 61,
		"par": 58,
		"time": "27:18",
		"coins": 14,
		"seed": SHOWCASE_SEED,
		"cards": cards.slice(0, 4),
	})


func _create_transition_screen(screen_name: String, title_text: String, body_text: String, action_text: String) -> Dictionary:
	results_overlay = PanelContainer.new()
	results_overlay.name = screen_name
	hud_canvas.add_child(results_overlay)
	results_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	results_overlay.theme = RELEASE_THEME

	var margin := MarginContainer.new()
	margin.name = "SafeArea"
	margin.add_theme_constant_override("margin_left", 108)
	margin.add_theme_constant_override("margin_top", 84)
	margin.add_theme_constant_override("margin_right", 108)
	margin.add_theme_constant_override("margin_bottom", 84)
	results_overlay.add_child(margin)

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
	UIStyleScript.apply_ui(eyebrow, 14, UIStyleScript.GOLD, true)
	hero_column.add_child(eyebrow)
	var hero_icon_stage := PanelContainer.new()
	hero_icon_stage.name = "HeroIconStage"
	hero_icon_stage.custom_minimum_size = Vector2(174.0, 174.0)
	hero_column.add_child(hero_icon_stage)
	var title := Label.new()
	title.name = "Title"
	title.text = title_text
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.y = 116.0
	UIStyleScript.apply_display(title, 50, UIStyleScript.PAPER)
	hero_column.add_child(title)
	var identity := Label.new()
	identity.name = "Identity"
	identity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyleScript.apply_ui(identity, 14, UIStyleScript.PAPER_MUTED, true)
	hero_column.add_child(identity)

	var detail_panel := PanelContainer.new()
	detail_panel.name = "DetailPanel"
	detail_panel.custom_minimum_size.x = 520.0
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_stretch_ratio = 1.14
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
	var body := Label.new()
	body.name = "Body"
	body.text = body_text
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UIStyleScript.apply_ui(body, 21, UIStyleScript.PAPER)
	detail_layout.add_child(body)
	var visual_details := VBoxContainer.new()
	visual_details.name = "VisualDetails"
	visual_details.add_theme_constant_override("separation", 10)
	detail_layout.add_child(visual_details)
	detail_layout.move_child(visual_details, 0)
	var action := UIActionButtonScript.new()
	action.name = "ActionButton"
	action.custom_minimum_size = Vector2(320.0, 60.0)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_layout.add_child(action)
	action.configure(action_text, &"continue", &"primary")

	return {"overlay": results_overlay, "title": title, "body": body, "action": action}


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
