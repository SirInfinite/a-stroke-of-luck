extends Node2D

## Explicit development scene only. Never instanced by Main or the release UI.
const Generator := preload("res://scripts/hole_generator.gd")
const Biomes := preload("res://scripts/biome_database.gd")
const Difficulties := preload("res://scripts/difficulty_database.gd")
const Builder := preload("res://scripts/level_builder.gd")

var review_seed := 7919
var hole := 18
var difficulty := 1
var curse := "direction"
var curse_count := 0
var modifier_seed := 0
var overlay_visible := true
var active_elevation := 0
var level: Dictionary = {}
var builder: LevelBuilder
var course: Node2D
var camera: Camera2D
var label: Label
var benchmark_mode := false

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--benchmarks" or argument.begins_with("--benchmark="):
			benchmark_mode = true
			var host := preload("res://tests/hazard_benchmark_play.gd").new()
			add_child(host)
			return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			review_seed = maxi(int(argument.get_slice("=", 1)), 1)
		elif argument.begins_with("--hole="):
			hole = clampi(int(argument.get_slice("=", 1)), 1, 18)
		elif argument.begins_with("--difficulty="):
			difficulty = maxi(["easy", "normal", "hard"].find(argument.get_slice("=", 1)), 0)
		elif argument.begins_with("--curse="):
			curse = argument.get_slice("=", 1)
		elif argument.begins_with("--count="):
			curse_count = clampi(int(argument.get_slice("=", 1)), 0, 4)
		elif argument.begins_with("--modifier-seed="):
			modifier_seed = int(argument.get_slice("=", 1))
	camera = Camera2D.new()
	add_child(camera)
	builder = Builder.new()
	add_child(builder)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	label = Label.new()
	label.position = Vector2(20, 14)
	label.size.x = 1870
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(label)
	_show_hole()

func _input(event: InputEvent) -> void:
	if benchmark_mode:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_RIGHT: hole = hole % 18 + 1
		KEY_LEFT: hole = posmod(hole - 2, 18) + 1
		KEY_N: review_seed += 7919
		KEY_D: difficulty = (difficulty + 1) % 3
		KEY_C: curse_count = (curse_count + 1) % 5
		KEY_E: active_elevation = posmod(active_elevation + 2, 3) - 1
		KEY_TAB:
			overlay_visible = not overlay_visible
			queue_redraw()
			return
		_: return
	_show_hole()

func _show_hole() -> void:
	if is_instance_valid(course):
		course.free()
	var options: Dictionary = Difficulties.get_profiles()[difficulty].generation_options()
	if curse_count > 0:
		options.merge({"added_hazard_count": curse_count, "preferred_hazard_type": curse, "modifier_seed": modifier_seed if modifier_seed != 0 else review_seed + hole * 104729})
	level = Generator.generate_hole(Biomes.get_profiles()[(hole - 1) / 3], review_seed, (hole - 1) / 3, (hole - 1) % 3, 8, options)
	course = builder.build_level(level, self)
	builder.set_active_elevation(active_elevation)
	camera.zoom = Vector2.ONE * minf(1.0, minf(1600.0 / (level.map[0].length() * 100.0 + 120.0), 740.0 / (level.map.size() * 100.0 + 120.0)))
	camera.position = Vector2(0, -90.0 / camera.zoom.x)
	var scores: Array[String] = []
	for candidate: Dictionary in level.candidate_scores:
		scores.append("%d:%.1f" % [candidate.candidate, candidate.score] if candidate.valid else "%d:REJECT %s" % [candidate.candidate, ", ".join(candidate.reasons)])
	label.text = "DEV GENERATOR | seed %d | %s %d/3 | %s | curse %s x%d | layer %d\n%s\nscore %.2f | candidates %s\nfallback: %s\nLEFT/RIGHT hole   N seed   D difficulty   C curse count   E layer   TAB overlay\nGold: safe primary route   White: shot sections   Coral: occupied surfaces   Green: recovery" % [review_seed, level.biome_name, (hole - 1) % 3 + 1, options.difficulty_name, curse, curse_count, active_elevation, ", ".join(level.get("selected_motifs", [])), level.quality_score, " / ".join(scores), level.fallback_reason]
	queue_redraw()

func _draw() -> void:
	if not overlay_visible or level.is_empty():
		return
	for surface in level.get("placement_reservations", []):
		draw_rect(Rect2(_point(Vector2i(surface.x, surface.y)) - Vector2(44, 44), Vector2(88, 88)), Color(1, 0.25, 0.2, 0.35))
	for zone in level.get("shot_zones", []):
		for cell in zone.cells:
			draw_rect(Rect2(_point(cell) - Vector2(45, 45), Vector2(90, 90)), Color(0.25, 1, 0.6, 0.2))
	for corridor in level.get("shot_corridors", []):
		draw_dashed_line(_point(corridor.from_cell), _point(corridor.to_cell), Color(1, 1, 1, 0.65), 4, 16)
	var route: Array = level.get("main_route_cells", [])
	for index in range(1, route.size()):
		draw_line(_point(route[index - 1]), _point(route[index]), Color(1, 0.76, 0.2, 0.85), 5, true)

func _point(cell: Vector2i) -> Vector2:
	return Generator._cell_to_world(Generator._string_rows(level.map), cell)
