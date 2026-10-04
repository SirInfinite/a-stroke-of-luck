extends Node2D
## Specialist capture helper. Real Main and fixture; never controls shots.

var main

func _ready() -> void:
	var density := 48
	var biome: StringName = &"meadow"
	var stage := "preview"
	for argument in OS.get_cmdline_user_args():
		if argument == "--world-density=32": density = 32
		if argument == "--world-biome=volcanic": biome = &"volcanic"
		if argument == "--world-stage=refined1": stage = "refined1"
		if argument == "--world-stage=refined2": stage = "refined2"
	main = preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	get_window().size = Vector2i(1280, 720)
	for index in 8: await get_tree().process_frame
	main._hide_main_menu()
	main._hide_interstitial()
	main._reset_run_state(9102026)
	main.run_state.difficulty_profile = DifficultyDatabase.get_profile(&"easy")
	main.run_state.phase = RunState.Phase.RUN_START
	var fixture: Dictionary = preload("res://tools/pixel_sample/sample_level.gd").create()
	fixture.biome_id = biome
	fixture.biome_name = "Volcanic" if biome == &"volcanic" else "Meadow"
	for index in 18: main.run_state.normal_levels.append(fixture.duplicate(true))
	main.run_state.levels = main.run_state.normal_levels.duplicate(true)
	main._load_level(2)
	var physics_before := _physics_snapshot()
	var setup_start := Time.get_ticks_usec()
	var world := preload("res://tools/reference_slice/world/reference_world.gd").new()
	main.level_builder.level_root.add_child(world)
	world.density = density
	world.setup(main)
	var setup_usec := Time.get_ticks_usec() - setup_start
	var physics_after := _physics_snapshot()
	var initial_count: int = main.level_builder.level_root.find_children("*", "", true, false).size()
	for index in 4:
		world.set_density(32 if index % 2 == 0 else 48)
	world.set_density(density)
	var final_count: int = main.level_builder.level_root.find_children("*", "", true, false).size()
	var switch_unchanged := physics_after == _physics_snapshot()
	var canvas := CanvasLayer.new()
	canvas.layer = -20
	add_child(canvas)
	var backdrop := TextureRect.new()
	backdrop.texture = load(world.background_path(biome))
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.camera.toggle_overview()
	for index in 70: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/reference_review/world/%s_%s_%d.png" % [stage, biome, density])
	var report := {"stage": stage, "biome": biome, "density": density,
		"physics_same_after_setup": physics_before == physics_after,
		"physics_same_after_density_switches": switch_unchanged,
		"nodes_before_switches": initial_count, "nodes_after_switches": final_count,
		"world_setup_milliseconds": setup_usec / 1000.0,
		"mass_center_error": world.rigs[0].weight.global_position.distance_to(world.rigs[0].body.global_position),
		"mass_extent_world": world.rigs[0].weight.texture.get_size() * world.rigs[0].weight.scale}
	var elapsed_before: float = world.elapsed
	var hazard_before: float = world.rigs[0].body.elapsed
	main._show_main_menu()
	for index in 12: await get_tree().process_frame
	report["pause_freezes_decoration"] = is_equal_approx(world.elapsed, elapsed_before)
	report["pause_freezes_native_hazard"] = is_equal_approx(world.rigs[0].body.elapsed, hazard_before)
	FileAccess.open("res://artifacts/reference_review/world/%s_%s_%d_checks.json" % [stage, biome, density], FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[WORLD REVIEW] " + JSON.stringify(report))
	main.audio_controller.stop_all_audio()
	get_tree().quit()

func _physics_snapshot() -> Array:
	var result: Array = []
	for node in main.level_builder.level_root.find_children("*", "", true, false):
		if node is CollisionShape2D:
			result.append([str(node.get_path()), node.transform, node.disabled, node.shape.get_class(), node.shape.get_rect()])
		elif node is CollisionObject2D:
			result.append([str(node.get_path()), node.transform, node.collision_layer, node.collision_mask])
	return result
