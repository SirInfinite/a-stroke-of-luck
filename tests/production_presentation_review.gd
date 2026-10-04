extends SceneTree
## Scripted evidence from the real default scene and generated production holes.
## Never loaded by production; no fixture geometry or presentation replacement.

var main
var output := "res://artifacts/production_visual/runtime"
var dimensions := Vector2i(1920, 1080)
var record_motion := false
var movie_frame := 0
var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var fonts := {}
var missing_glyphs := {}
var performance: Array[Dictionary] = []

func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		elif argument.begins_with("--size="):
			var parts := argument.trim_prefix("--size=").split("x")
			dimensions = Vector2i(int(parts[0]), int(parts[1]))
		elif argument == "--record-motion":
			record_motion = true
	_run.call_deferred()

func _run() -> void:
	root.size = dimensions
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	if record_motion:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.path_join("frames")))
	var entrypoint: String = ProjectSettings.get_setting("application/run/main_scene")
	main = load(entrypoint).instantiate()
	root.add_child(main)
	current_scene = main
	await _capture("01_normal_title")
	main._on_menu_play_pressed()
	await _capture("02_mode_select")
	main.vs_controller._select_mode(false)
	main.run_setup_screen.seed_input.text = "8675309"
	await _capture("03_run_setup")
	main._start_normal_run(8675309)
	await _capture("04_run_intro")
	main._on_interstitial_continue_pressed()
	await _capture("05_biome_intro")
	main._on_interstitial_continue_pressed()
	await _frames(4)
	_check(main.run_state.levels.size() == 18, "normal generated run has 18 holes")
	_check_tee(true, "first introductory hole")
	await _capture("06_first_hole_tee")
	for biome_index in range(6):
		main._load_level(biome_index * 3 + 2)
		await _frames(4)
		var biome: String = main.run_state.levels[main.run_state.level_index].get("biome_id", "unknown")
		var label := "%02d_%s" % [biome_index + 10, biome]
		_check_tee(true, label + " initial")
		await _capture(label + "_tee")
		var ambience = main.level_root.get_node("BiomeAmbience")
		var original_anchors: int = hash(ambience.static_details)
		var original_transform: Transform2D = ambience.global_transform
		var start: Vector2 = main.ball.global_position
		var direction: Vector2 = (main.level_builder.level_point(main.run_state.levels[main.run_state.level_index], "hole", "hole_cell") - start).normalized()
		main.ball.shoot(direction * main.ball.max_impulse)
		await _frames(3)
		_check_tee(false, label + " after shot")
		await _capture(label + "_after_shot")
		await _travel(72)
		_check(ambience.global_transform == original_transform, label + " nearby scenery stays in world space")
		_check(hash(ambience.static_details) == original_anchors, label + " anchors do not regenerate during travel")
		main._toggle_course_overview()
		await _travel(30)
		await _capture(label + "_overview")
		main._toggle_course_overview()
		await _travel(30)
		await _capture(label + "_return")
		main._reset_current_level()
		await _frames(4)
		_check_tee(true, label + " reset")
		await _capture(label + "_reset")
		performance.append({"biome": biome, "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "memory": Performance.get_monitor(Performance.MEMORY_STATIC), "process_seconds": Performance.get_monitor(Performance.TIME_PROCESS)})
	main._show_main_menu()
	await _capture("20_pause_current_course")
	main._on_menu_settings_pressed()
	for tab_index in range(main.settings_screen.tabs.get_tab_count()):
		main.settings_screen.tabs.current_tab = tab_index
		await _capture("21_settings_%d" % tab_index)
	main.settings_screen.close()
	main._hide_main_menu()
	main.run_state.tokens = 30 # Presentation purchase coverage, not a production reward.
	for difficulty in [&"easy", &"normal", &"hard"]:
		main.run_state.difficulty_profile = DifficultyDatabase.get_profile(difficulty)
		main.run_state.phase = RunState.Phase.HOLE_RESULTS
		main._show_shop(3)
		await _capture("22_shop_%s" % difficulty)
		var selected: Control = main.shop_manager.shop_card_buttons[1]
		selected.grab_focus()
		await _capture("23_shop_%s_focus" % difficulty)
		var wallet: int = main.run_state.tokens
		var price: int = main.shop_manager.current_shop_cards[0].price
		main.shop_manager.shop_card_buttons[0].pressed.emit()
		await _capture("24_shop_%s_purchase" % difficulty)
		_check(main.run_state.tokens == wallet - price, "%s purchase debits authoritative price once" % difficulty)
	main.shop_manager.shop_overlay.hide()
	main._start_tutorial()
	await _frames(4)
	_check_tee(true, "tutorial start")
	await _capture("25_tutorial")
	main._start_tutorial()
	await _frames(4)
	_check_tee(true, "tutorial restart")
	main._return_from_tutorial()
	await _capture("26_tutorial_return")
	main._start_normal_run(8675309, &"woods")
	main._load_level(0)
	await _frames(4)
	_check_tee(true, "VS player start")
	await _capture("27_vs_player")
	main._complete_current_hole(false, false)
	await _frames(8)
	_check_tee(true, "VS opponent reset")
	await _capture("28_vs_opponent")
	main.vs_controller.cancel()
	main._start_normal_run(8675309)
	main._load_level(1)
	await _frames(4)
	_check_tee(true, "New Run and next hole")
	await _capture("29_new_run")
	_check(missing_glyphs.is_empty(), "all rendered ordinary copy has approved glyphs")
	var report := {"checks": checks, "failures": failures, "captures": captures, "font_resources": fonts.keys(), "missing_glyphs": missing_glyphs, "performance_samples": performance, "movie_frames": movie_frame, "entrypoint": entrypoint, "size": str(dimensions), "evidence_kind": "scripted actual production scene; not human playtest"}
	var file := FileAccess.open(output.path_join("report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("PRODUCTION_PRESENTATION_REVIEW: %d checks, %d failures, %d captures" % [checks, failures.size(), captures.size()])
	main.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _check_tee(expected_visible: bool, context: String) -> void:
	var markers: Array[Node] = main.level_root.find_children("TeeStartMarker", "", true, false)
	_check(markers.size() == 1, context + ": exactly one tee owner")
	_check(main.level_builder.tee_marker.visible == expected_visible, context + ": native tee lifecycle")
	if expected_visible:
		_check(main.level_builder.tee_marker.global_position.distance_to(main.ball.global_position) < 0.1, context + ": ball and tee aligned")
	_check(main.ball.ball_art.find_children("*Tee*", "", true, false).is_empty(), context + ": no ball-owned tee")

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error("PRODUCTION_REVIEW_FAIL: " + message)

func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func _travel(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame
		if record_motion and frame % 2 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("frames/travel_%04d.png" % movie_frame))
			movie_frame += 1

func _capture(label: String) -> void:
	await _frames(24)
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	rendered.save_png(output.path_join(label + ".png"))
	if label.begins_with("22_shop"):
		for card in main.shop_manager.shop_card_buttons:
			if not card.is_visible_in_tree():
				continue
			var art: Control = card.centerpiece_icon
			var rect: Rect2 = art.get_global_rect()
			var scale_to_pixels := Vector2(rendered.get_size()) / root.get_visible_rect().size
			var colors := {}
			for x in range(1, 10):
				for y in range(1, 10):
					var point := (rect.position + rect.size * Vector2(x, y) / 10.0) * scale_to_pixels
					colors[rendered.get_pixel(clampi(int(point.x), 0, rendered.get_width() - 1), clampi(int(point.y), 0, rendered.get_height() - 1)).to_html()] = true
			_check(colors.size() > 8, "%s/%s rendered illustration is populated, not an empty texture" % [label, card.card_id])
	captures.append(label)
	_audit_fonts(main)

func _audit_fonts(node: Node) -> void:
	if node is Control and node.is_visible_in_tree():
		var copy := ""
		var font: Font
		if node is Label or node is Button or node is LineEdit:
			copy = node.text
			font = node.get_theme_font("font")
		elif node is RichTextLabel:
			copy = node.get_parsed_text()
			font = node.get_theme_font("normal_font")
		if font and not copy.is_empty():
			var base_font := font
			while base_font is FontVariation:
				base_font = base_font.base_font
			fonts[base_font.resource_path] = true
			_check(base_font.resource_path.contains("Jersey10"), "%s uses approved font" % node.get_path())
			for character in copy:
				if character.unicode_at(0) > 32 and not font.has_char(character.unicode_at(0)):
					missing_glyphs[character] = str(node.get_path())
	for child in node.get_children():
		_audit_fonts(child)
