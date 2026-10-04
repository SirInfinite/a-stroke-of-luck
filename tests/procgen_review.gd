extends Node2D

## Development-only actual LevelBuilder contact sheet source. No production hooks.
const Generator := preload("res://scripts/hole_generator.gd")
const Biomes := preload("res://scripts/biome_database.gd")
const Difficulties := preload("res://scripts/difficulty_database.gd")
const Builder := preload("res://scripts/level_builder.gd")

func _ready() -> void:
	var stage := "after"
	var output_override := ""
	var corpus_path := "user://procgen_overhaul_20260906/corpus.json"
	for argument in OS.get_cmdline_user_args():
		if argument == "--before":
			stage = "before"
		if argument.begins_with("--output-root="):
			output_override = argument.trim_prefix("--output-root=")
		if argument.begins_with("--corpus="):
			corpus_path = argument.trim_prefix("--corpus=")
	var output := output_override if not output_override.is_empty() else "user://procgen_overhaul_20260906/" + stage
	DirAccess.make_dir_recursive_absolute(output)
	var camera := Camera2D.new()
	add_child(camera)
	var builder := Builder.new()
	add_child(builder)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var label := Label.new()
	label.position = Vector2(28, 20)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(label)
	var count := 0
	for seed_value in [7919, 8675309]:
		for difficulty in Difficulties.get_profiles():
			var levels := Generator.generate_run(Biomes.get_profiles(), seed_value, difficulty.generation_options())
			for index in range(levels.size()):
				var level: Dictionary = levels[index]
				if not await _capture(builder, camera, label, level, "%s/%d_%s_%02d.png" % [output, seed_value, difficulty.id, index + 1], stage.to_upper()):
					get_tree().quit(1)
					return
				count += 1
	if stage == "after":
		if not FileAccess.file_exists(corpus_path):
			push_error("Run procgen_corpus.gd first to select actual feature-bearing examples.")
			get_tree().quit(1)
			return
		var corpus: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(corpus_path))
		for key: String in corpus.examples:
			var fixture: Dictionary = corpus.examples[key]
			var index := int(fixture.hole) - 1
			var options := Difficulties.get_profile(fixture.difficulty).generation_options()
			options.merge({"added_hazard_count": int(fixture.count), "preferred_hazard_type": fixture.curse, "modifier_seed": int(fixture.get("modifier_seed", int(fixture.seed) / 7919 * 104729))})
			var level := Generator.generate_hole(Biomes.get_profiles()[index / 3], int(fixture.seed), index / 3, index % 3, 8, options)
			var layers: Array = [0, 1] if key == "short_tunnel" else [-1] if key == "recessed_cut" else [1] if key == "raised_bridge" else [0]
			for layer in layers:
				if not await _capture(builder, camera, label, level, "%s/feature_%s_layer%d.png" % [output, key, layer], "%s | %s x%d" % [key, fixture.curse, fixture.count], layer):
					get_tree().quit(1)
					return
				count += 1
	print("PROCGEN_RENDER_PASS screenshots=%d directory=%s" % [count, output])
	get_tree().quit()

func _capture(builder: LevelBuilder, camera: Camera2D, label: Label, level: Dictionary, path: String, title: String, layer := 0) -> bool:
	var root := builder.build_level(level, self)
	if root == null:
		return false
	builder.set_active_elevation(layer)
	camera.position = Vector2(0, -30)
	camera.zoom = Vector2.ONE * minf(1.0, minf(1640.0 / (level.map[0].length() * 100.0 + 120.0), 820.0 / (level.map.size() * 100.0 + 120.0)))
	label.text = "%s | %s | seed %d | hole %02d | %s | score %.2f | layer %d\n%s" % [title, level.run_difficulty_name, level.run_seed, level.overall_hole_number, level.biome_name, level.quality_score, layer, ", ".join(level.get("selected_motifs", []))]
	for _frame in range(3):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(path)
	root.free()
	return error == OK
