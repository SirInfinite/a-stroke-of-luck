extends Node2D

const BiomeDatabase := preload("res://scripts/biome_database.gd")
const DifficultyDatabase := preload("res://scripts/difficulty_database.gd")
const HoleGenerator := preload("res://scripts/hole_generator.gd")
const LevelBuilderScript := preload("res://scripts/level_builder.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

const REVIEW_SEED := 7919
const LAST_CASE_INDEX := 7

var case_index := 0
var level_builder
var level_root: Node2D
var camera: Camera2D
var case_label: Label


func _ready() -> void:
	camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)
	level_builder = LevelBuilderScript.new()
	add_child(level_builder)
	_create_case_label()
	_show_case()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		case_index = mini(case_index + 1, LAST_CASE_INDEX)
		_show_case()
		get_viewport().set_input_as_handled()


func _show_case() -> void:
	if is_instance_valid(level_root):
		level_root.free()
	var fixture := _case_fixture(case_index)
	var options := DifficultyDatabase.get_profile(fixture.difficulty).generation_options()
	options.merge(fixture.get("effects", {}))
	var index := int(fixture.hole) - 1
	var seed_value := int(fixture.get("seed", REVIEW_SEED))
	var level := HoleGenerator.generate_hole(BiomeDatabase.get_profiles()[index / 3], seed_value, index / 3, index % 3, 8, options)
	assert(level.selected_motifs.has(fixture.motif), "Generation showcase fixture no longer demonstrates its named motif.")
	level_root = level_builder.build_level(level, self)
	level_builder.set_active_elevation(int(fixture.active_elevation))
	camera.global_position = Vector2(0, -30)
	camera.zoom = Vector2.ONE * minf(1.0, minf(1640.0 / (level.map[0].length() * 100.0 + 120.0), 820.0 / (level.map.size() * 100.0 + 120.0)))
	var metrics := HoleGenerator.quality_metrics(level)
	case_label.text = "%s  •  SEED %d  •  %s HOLE %02d  •  SCORE %.1f  •  ROUTE-RELEVANT %d/%d" % [
		String(fixture.label),
		seed_value,
		String(fixture.difficulty).to_upper(),
		int(fixture.hole),
		float(level.quality_score),
		int(metrics.route_relevant_count),
		int(metrics.placement_count),
	]


func _case_fixture(index: int) -> Dictionary:
	var fixtures := [
		{"label": "OPENING WATER / BANK", "motif": "bank_corner", "difficulty": &"easy", "hole": 1, "active_elevation": 0},
		{"label": "BOUNCE BANK / RECOVERABLE BAIT", "motif": "bounce_bank", "difficulty": &"easy", "hole": 2, "active_elevation": 0},
		{"label": "PENDULUM GATE", "motif": "pendulum_gate", "difficulty": &"easy", "hole": 3, "active_elevation": 0},
		{"label": "SAND APPROACH", "motif": "sand_approach", "difficulty": &"easy", "hole": 6, "active_elevation": 0},
		{"label": "RECESSED OPTIONAL ROUTE", "motif": "recessed_cut", "difficulty": &"easy", "hole": 8, "active_elevation": -1},
		{"label": "SHORT TUNNEL / LOWER ROUTE", "motif": "short_tunnel", "seed": 55433, "difficulty": &"hard", "hole": 18, "active_elevation": 0, "effects": {"added_hazard_count": 2, "preferred_hazard_type": "blocker", "modifier_seed": 733103}},
		{"label": "SHORT OVERPASS / UPPER ROUTE", "motif": "short_tunnel", "seed": 55433, "difficulty": &"hard", "hole": 18, "active_elevation": 1, "effects": {"added_hazard_count": 2, "preferred_hazard_type": "blocker", "modifier_seed": 733103}},
		{"label": "VOLCANIC HARD CLIMAX", "motif": "rotating_gate", "difficulty": &"hard", "hole": 18, "active_elevation": 0},
	]
	return fixtures[clampi(index, 0, fixtures.size() - 1)]


func _create_case_label() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ReviewCanvas"
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.name = "CasePanel"
	panel.position = Vector2(28.0, 24.0)
	panel.custom_minimum_size = Vector2(970.0, 54.0)
	panel.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color(UIStyleScript.INK_DEEP, 0.94), UIStyleScript.GOLD, 12, 2, 5))
	canvas.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	case_label = Label.new()
	case_label.name = "CaseLabel"
	UIStyleScript.apply_ui(case_label, 15, UIStyleScript.PAPER, true)
	margin.add_child(case_label)
