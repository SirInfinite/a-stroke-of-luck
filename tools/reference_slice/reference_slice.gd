extends "res://tools/pixel_sample/pixel_sample.gd"
## Visible manual approval scene by default. Automation requires an explicit flag.

var previous := false
var density := 48
var biome_id: StringName = &"meadow"
var shop_difficulty: StringName = &"easy"
var water_events := 0
var hazard_capture_pending := false
var review_hint: Label
var validation: Array[Dictionary] = []
var performance_samples: Array[Dictionary] = []
var capture_manual_proof := false

func _ready() -> void:
	baseline = false
	output_dir = "res://artifacts/reference_review/implemented"
	for argument in OS.get_cmdline_user_args():
		if argument == "--previous": previous = true
		if argument == "--sample-proof": capture_manual_proof = true
		if argument == "--sample-record": automate = true
		if argument == "--sample-gallery": gallery_mode = true
		if argument == "--sample-checks": checks_mode = true
		if argument == "--sample-track-b": initial_candidate = 1
		if argument == "--chunky": density = 32
		if argument == "--volcanic": biome_id = &"volcanic"
		if argument.begins_with("--sample-output="): output_dir = argument.trim_prefix("--sample-output=")
		if argument.begins_with("--sample-size="):
			var parts := argument.trim_prefix("--sample-size=").split("x")
			desired_size = Vector2i(int(parts[0]), int(parts[1]))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	main = MainScene.instantiate()
	main.get_node("FeedbackDirector").set_script(preload("res://tools/pixel_correction/arcade_feedback.gd") if previous else preload("res://tools/reference_slice/reference_feedback.gd"))
	if not previous: main.get_node("FeedbackDirector").density = density
	main.get_node("AudioController").set_script(load("res://tools/reference_slice/audio/reference_audio.gd"))
	main.get_node("AudioController").candidate = initial_candidate
	add_child(main)
	main.game_settings.resolution = desired_size
	main.game_settings.fullscreen = false
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = desired_size
	get_window().title = "A Stroke of Luck — " + ("Previous correction" if previous else "Reference presentation slice")
	if automate or gallery_mode:
		get_viewport().gui_disable_input = true
		main.ball.set_process_input(false)
	if not Engine.get_write_movie_path().is_empty():
		main.audio_controller.playback_enabled = true
		main.audio_controller.music_state = &""
		main.audio_controller.set_music_state(&"menu", true)
		for bus_name in [&"Master", &"Music", &"SFX"]:
			var bus := AudioServer.get_bus_index(bus_name)
			AudioServer.set_bus_mute(bus, false)
			AudioServer.set_bus_volume_db(bus, 0.0)
	main.ball.shot_started.connect(func(at: Vector2, direction: Vector2, power: float): _event("shot", {"position": at, "direction": direction, "power": power}))
	main.ball.ball_stopped.connect(func(at: Vector2): _event("stop", {"position": at}))
	main.ball.wall_impact.connect(func(strength: float, at: Vector2): _event("wall", {"position": at, "strength": strength}))
	main.level_builder.reset_hazard_body_entered.connect(func(_body: Node2D, at: Vector2, kind: StringName): _event("hazard", {"position": at, "kind": kind}))
	main.ball.sink_animation_finished.connect(func(): _event("sink", {}))
	main.shop_manager.card_bought.connect(func(card: CardDefinition): _event("purchase", {"card": card.id, "price": card.price}))
	main.audio_controller.cue_requested.connect(func(cue: StringName): _event("audio", {"cue": cue}))
	skin = preload("res://tools/pixel_correction/arcade_skin.gd").new() if previous else preload("res://tools/reference_slice/slice_skin.gd").new()
	add_child(skin)
	skin.setup(main)
	if not previous: skin.set_density(density)
	main.menu_play_button.pressed.disconnect(main._on_menu_play_pressed)
	main.menu_play_button.pressed.connect(_start_hole)
	main.menu_play_button.text = "PLAY SAMPLE"
	main.shop_manager.continued.disconnect(main._on_shop_continued)
	main.shop_manager.continued.connect(_on_sample_shop_continued)
	if gallery_mode: _run_gallery.call_deferred()
	elif automate: _run_recording.call_deferred()
	elif checks_mode: _run_checks.call_deferred()
	else:
		_review_controls()
		if capture_manual_proof: _manual_proof.call_deferred()
	print("[REFERENCE SLICE] manual=%s previous=%s density=%s audio=%s" % [not (automate or gallery_mode or checks_mode), previous, density, AudioServer.get_driver_name()])

func _manual_proof() -> void:
	await _frames(60)
	await _capture("manual_title")
	print("[MANUAL PROOF] window_visible=%s gui_input=%s music_active=%s; remains open for normal input" % [get_window().visible, not get_viewport().gui_disable_input, main.audio_controller.music_players.any(func(player): return player.playing)])

func _capture(label: String) -> void:
	await super._capture(label)
	performance_samples.append({"capture": label, "process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, "physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, "static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC), "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "audio_players": main.audio_controller.sfx_players.size()})

func _start_hole() -> void:
	main._hide_main_menu()
	main._hide_interstitial()
	main.run_state.tutorial_mode = false
	main._reset_run_state(Fixture.SEED)
	main.run_state.difficulty_profile = DifficultyDatabase.get_profile(shop_difficulty)
	main.run_state.phase = RunState.Phase.RUN_START
	main.run_state.tokens = 12
	var fixture: Dictionary = Fixture.create()
	if biome_id == &"volcanic":
		var profile = BiomeDatabase.get_profiles()[5]
		fixture["biome_id"] = &"volcanic"
		fixture["biome_name"] = "Volcanic"
		fixture["biome_index"] = 5
		for key in ["terrain_palette", "background_palette", "decoration_identifiers", "ambience"]:
			fixture[key] = profile.get(key)
	# The extra identities exercise native Normal/Hard capacities, not new rules.
	fixture["shop_cards"] = ["Overdrive Driver", "Sand Cleats", "Coin Magnet", "Rangefinder Lens", "Heavy Core", "Lucky Putter"]
	for index in 18: main.run_state.normal_levels.append(fixture.duplicate(true))
	main.run_state.levels = main.run_state.normal_levels.duplicate(true)
	main._load_level(2)
	var before := _physics_snapshot()
	skin.apply_hole()
	physics_unchanged = physics_unchanged and before == _physics_snapshot()
	_event("hole_loaded", {"seed": Fixture.SEED, "biome": biome_id, "density": density})
	_update_hint()

func _review_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	review_hint = Label.new()
	review_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	review_hint.add_theme_font_size_override("font_size", 17)
	review_hint.add_theme_color_override("font_color", Color("fff1dc"))
	review_hint.add_theme_color_override("font_outline_color", Color("111a21"))
	review_hint.add_theme_constant_override("outline_size", 5)
	layer.add_child(review_hint)
	review_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	review_hint.offset_left = 22
	review_hint.offset_top = -27
	_update_hint()

func _update_hint() -> void:
	if not review_hint: return
	review_hint.text = "%s  ·  F5 Meadow  F6 Volcanic  F7 Shop  F8 Title  F9 Density %d  F10 %s shop  ·  1/2 audio A/B" % ["PREVIOUS" if previous else "STYLE REVIEW", density, String(shop_difficulty).to_upper()]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or automate or gallery_mode or checks_mode: return
	match event.keycode:
		KEY_F5:
			biome_id = &"meadow"
			_start_hole()
		KEY_F6:
			biome_id = &"volcanic"
			_start_hole()
		KEY_F7: _show_sample_shop()
		KEY_F8:
			main.run_state.phase = RunState.Phase.MAIN_MENU
			main._show_main_menu()
		KEY_F9:
			density = 32 if density == 48 else 48
			if not previous:
				skin.set_density(density)
				main.feedback_director.density = density
			_update_hint()
		KEY_F10:
			shop_difficulty = &"normal" if shop_difficulty == &"easy" else (&"hard" if shop_difficulty == &"normal" else &"easy")
			_start_hole()
			_show_sample_shop()
		KEY_1, KEY_2:
			main.audio_controller.select_candidate(0 if event.keycode == KEY_1 else 1)
		_: return
	get_viewport().set_input_as_handled()

func _event(kind: String, data: Dictionary) -> void:
	super._event(kind, data)
	if kind == "hazard" and data.get("kind") == &"water": water_events += 1
	if kind == "hazard" and automate and not hazard_capture_pending:
		hazard_capture_pending = true
		_capture.call_deferred("03c_hazard_contact")

func _physics_snapshot() -> Array:
	var result: Array = []
	for node in main.level_builder.level_root.find_children("*", "", true, false):
		if node is CollisionObject2D:
			result.append([String(node.get_path()), node.transform, node.collision_layer, node.collision_mask])
		elif node is CollisionShape2D:
			var shape_data: Variant = null
			if node.shape is RectangleShape2D: shape_data = node.shape.size
			elif node.shape is CircleShape2D: shape_data = node.shape.radius
			elif node.shape is CapsuleShape2D: shape_data = Vector2(node.shape.radius, node.shape.height)
			result.append([String(node.get_path()), node.transform, node.disabled, shape_data])
	return result

func _run_recording() -> void:
	await _frames(90)
	await _capture("01_title")
	biome_id = &"meadow"
	_start_hole()
	await _frames(90)
	main.camera.toggle_overview()
	await _frames(45)
	await _capture("02_hole")
	main.camera.toggle_overview()
	await _frames(45)
	_aim(Vector2.LEFT, 0.45)
	await _frames(45)
	await _capture("03_aim")
	_strike(Vector2.LEFT, 0.45)
	await _frames(310)
	_aim(Vector2(0.4, -1), 0.28)
	await _frames(45)
	_strike(Vector2(0.4, -1), 0.28)
	await _frames(390)
	_aim(Vector2.RIGHT, 0.75)
	await _frames(45)
	_strike(Vector2.RIGHT, 0.75)
	await _frames(360)
	await _capture("04_results")
	_check(main.run_phase == RunState.Phase.HOLE_RESULTS, "Real three-shot sequence resolves hole")
	if main.run_phase != RunState.Phase.HOLE_RESULTS:
		_finish_report()
		return
	main._on_interstitial_continue_pressed()
	skin.apply_shop()
	await _frames(80)
	await _capture("05_shop")
	var card: UICard = main.shop_manager.shop_card_buttons[0]
	var second_card: UICard = main.shop_manager.shop_card_buttons[1]
	if previous: second_card.grab_focus()
	else: second_card.card_layout.get_node("ReferenceBuy").grab_focus()
	await _frames(12)
	await _capture("05b_details")
	var before_wallet: int = main.run_state.tokens
	if previous: card.grab_focus()
	else: card.card_layout.get_node("ReferenceBuy").grab_focus()
	card.pressed.emit()
	await _frames(12)
	await _capture("06_purchase")
	await _frames(65)
	_check(main.run_state.tokens < before_wallet, "Purchase uses native wallet transaction")
	await _capture("07_purchased")
	biome_id = &"volcanic"
	_start_hole()
	await _frames(90)
	main.camera.toggle_overview()
	await _frames(35)
	await _capture("08_volcanic")
	main.camera.toggle_overview()
	await _frames(35)
	# Live surface shot, aimed around the blocker toward the native water pool.
	_strike(Vector2(500, -400), 0.58)
	await _frames(360)
	await _capture("09_surface")
	_check(water_events > 0, "Actual surface shot reaches native water hazard")
	_finish_report()

func _run_gallery() -> void:
	await _frames(40)
	await _capture("01_title")
	for biome in [&"meadow", &"volcanic"]:
		biome_id = biome
		_start_hole()
		await _frames(45)
		main.camera.toggle_overview()
		await _frames(35)
		await _capture("02_" + String(biome) + "_" + str(density))
	biome_id = &"meadow"
	for difficulty in [&"easy", &"normal", &"hard"]:
		shop_difficulty = difficulty
		_start_hole()
		_show_sample_shop()
		await _frames(45)
		await _capture("05_shop_" + String(difficulty))
		_check(main.shop_manager.shop_card_buttons.filter(func(c): return c.visible).size() == main.run_state.difficulty_profile.shop_offer_count, "Native offer count " + String(difficulty))
	main.game_settings.ui_appearance = &"light"
	main._apply_player_settings()
	skin.apply_shop()
	await _frames(10)
	await _capture("06_shop_light")
	main.game_settings.ui_appearance = &"dark"
	main._apply_player_settings()
	main.shop_manager.shop_overlay.hide()
	main.run_state.phase = RunState.Phase.MAIN_MENU
	main._show_main_menu()
	main.settings_screen.open(false)
	await _frames(15)
	await _capture("07_settings")
	main.settings_screen.close()
	main.run_setup_screen.open()
	await _frames(15)
	await _capture("08_run_setup")
	main.run_setup_screen.close()
	_finish_report()

func _run_checks() -> void:
	await _frames(30)
	_start_hole()
	await _frames(30)
	_check(main.ball.input_enabled, "Manual golf input remains available")
	_check(physics_unchanged, "World adapter preserves collider snapshot")
	var before := _physics_snapshot()
	if not previous:
		skin.set_density(32)
		skin.set_density(48)
	_check(before == _physics_snapshot(), "Density changes preserve physics")
	main.camera.toggle_overview()
	await _frames(30)
	_check(main.camera.is_overview_active(), "Course overview remains available")
	main.camera.toggle_overview()
	await _frames(30)
	var start: Vector2 = main.ball.global_position
	var screen: Vector2 = main.ball.get_global_transform_with_canvas().origin
	_check((main.ball.get_canvas_transform().affine_inverse() * screen).distance_to(start) < 0.01, "Pointer-to-world projection preserved at current scale")
	_aim(Vector2.RIGHT, 0.2)
	await _frames(2)
	_check(main.ball.aim_line.visible, "Native aim is visible")
	var key := InputEventKey.new()
	key.keycode = main.game_settings.shoot_keycode
	key.pressed = true
	get_viewport().push_input(key)
	await _frames(2)
	_check(main.ball.shot_in_progress, "Configured keyboard input releases actual shot")
	key.pressed = false
	get_viewport().push_input(key)
	await _frames(280)
	_check(main.ball.can_shoot(), "Actual shot returns to ready")
	main._show_main_menu()
	await _frames(5)
	_check(not main.title_attract_mode.visible and main.menu_pause_dim.visible, "Pause shows frozen course and hides title backdrop")
	await _capture("check_pause")
	main._hide_main_menu()
	for difficulty in [&"easy", &"normal", &"hard"]:
		shop_difficulty = difficulty
		_start_hole()
		_show_sample_shop()
		await _frames(45)
		var shop = main.shop_manager
		_check(shop.current_offer_count == main.run_state.difficulty_profile.shop_offer_count, "Offer capacity " + String(difficulty))
		_check(shop.current_max_purchases == main.run_state.difficulty_profile.max_purchases, "Purchase cap " + String(difficulty))
		for card in shop.shop_card_buttons:
			if not card.visible: continue
			var rect: Rect2 = card.get_global_rect()
			_check(main.get_viewport_rect().encloses(rect), "Card bounds " + String(difficulty) + "/" + String(card.card_id))
			_check(card.benefit_panel.is_visible_in_tree() and card.curse_panel.is_visible_in_tree(), "Both tradeoffs visible " + String(card.card_id))
		if not previous:
			var second_offer: UICard = shop.shop_card_buttons[1]
			second_offer.card_layout.get_node("ReferenceBuy").grab_focus()
			await _frames(2)
			_check(skin.ui._selected_id == second_offer.card_id, "Keyboard focus changes selected equipment " + String(difficulty))
			_check(skin.ui._details[0].title.text == shop.current_shop_cards[1].name, "Selected details show real focused offer " + String(difficulty))
		var before_cues: int = events.filter(func(e): return e.get("cue") == &"purchase").size()
		var wallet: int = main.run_state.tokens
		var price: int = shop.current_shop_cards[0].price
		shop.shop_card_buttons[0].pressed.emit()
		await _frames(55)
		_check(main.run_state.tokens == wallet - price, "Exact native purchase deduction " + String(difficulty))
		_check(events.filter(func(e): return e.get("cue") == &"purchase").size() == before_cues + 1, "One accepted purchase cue " + String(difficulty))
		shop.shop_card_buttons[0].pressed.emit()
		await _frames(5)
		_check(main.run_state.tokens == wallet - price, "Rejected repeat leaves wallet unchanged " + String(difficulty))
	main.game_settings.reduced_motion = true
	main._apply_player_settings()
	_start_hole()
	await _frames(15)
	main.feedback_director.play_shot_feedback(main.ball.position, Vector2.RIGHT, 1.0)
	await _frames(2)
	_check(main.camera.offset == Vector2.ZERO, "Reduced motion suppresses cosmetic shake")
	for index in 12:
		main.feedback_director.play_wall_impact(0.8, main.ball.position)
		main.feedback_director.play_hazard_feedback(&"pendulum", 1.0, main.ball.position)
		await _frames(25)
	await _frames(50)
	_check(main.feedback_director.transient_root.get_child_count() == 0, "Repeated event visuals recover without leaks")
	main.audio_controller.select_candidate(1)
	await _frames(60)
	_check(main.audio_controller.music_players.size() == 2, "Audition switching keeps bounded music pool")
	main._start_tutorial()
	await _frames(10)
	_check(main.run_state.tutorial_mode, "Native tutorial remains available")
	main._return_from_tutorial()
	await _frames(10)
	_check(not main.run_state.tutorial_mode and main.run_phase == RunState.Phase.MAIN_MENU, "Native tutorial return clears state")
	_start_hole()
	await _frames(10)
	_check(not main.run_state.tutorial_mode, "Sample restart clears tutorial state")
	_finish_report()

func _check(passed: bool, label: String) -> void:
	validation.append({"passed": passed, "label": label})
	if not passed: push_error("[REFERENCE CHECK] " + label)

func _finish_report() -> void:
	_check(physics_unchanged, "All adapter applications preserve collider snapshots")
	var report := {"previous": previous, "density": density, "frames": frame, "events": events, "checks": validation, "captures": captures, "size": desired_size, "water_events": water_events, "physics_unchanged": physics_unchanged, "performance": performance_samples}
	FileAccess.open(output_dir.path_join("events.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	main.audio_controller.stop_all_audio()
	await _frames(6)
	print("[REFERENCE SLICE] DONE captures=%s checks=%s physics=%s" % [captures, validation.size(), physics_unchanged])
	get_tree().quit(1 if validation.any(func(item): return not item.passed) else 0)
