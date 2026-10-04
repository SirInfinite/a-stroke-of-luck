extends Node2D
## Approval sandbox composed around the actual Main. No production entrypoint changes.

const MainScene := preload("res://scenes/main.tscn")
const Fixture := preload("res://tools/pixel_sample/sample_level.gd")

var main
var baseline := true
var automate := false
var output_dir := "res://artifacts/pixel_sample/baseline"
var frame := 0
var events: Array[Dictionary] = []
var desired_size := Vector2i(1920, 1080)
var captures := 0
var skin: Node
var checks_mode := false
var gallery_mode := false
var physics_unchanged := true
var initial_candidate := 0

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--sample-after": baseline = false
		if argument == "--sample-record": automate = true
		if argument == "--sample-checks": checks_mode = true
		if argument == "--sample-gallery": gallery_mode = true
		if argument == "--sample-track-b": initial_candidate = 1
		if argument.begins_with("--sample-output="): output_dir = argument.trim_prefix("--sample-output=")
		if argument.begins_with("--sample-size="):
			var parts := argument.trim_prefix("--sample-size=").split("x")
			desired_size = Vector2i(int(parts[0]), int(parts[1]))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	main = MainScene.instantiate()
	if not baseline:
		main.get_node("FeedbackDirector").set_script(_feedback_script())
		main.get_node("AudioController").set_script(preload("res://tools/pixel_sample/sample_audio.gd"))
		main.get_node("AudioController").candidate = initial_candidate
	add_child(main)
	# Movie Maker deliberately uses Dummy while still mixing the movie's PCM.
	# Override only this review process; never persist audio settings.
	if not Engine.get_write_movie_path().is_empty():
		main.audio_controller.playback_enabled = true
		main.audio_controller.music_state = &""
		main.audio_controller.set_music_state(&"menu", true)
		for bus_name in [&"Master", &"Music", &"SFX"]:
			var bus := AudioServer.get_bus_index(bus_name)
			AudioServer.set_bus_mute(bus, false)
			AudioServer.set_bus_volume_db(bus, 0.0)
		print("[PIXEL SAMPLE] Offline reference mix: all buses 0 dB, unmuted; settings not saved.")
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = desired_size
	get_window().title = "A Stroke of Luck — presentation sample"
	if automate or gallery_mode:
		# Only scripted fixture inputs belong in evidence. Ambient desktop cursor
		# hover/focus must not add unrelated sounds while a movie is rendering.
		get_viewport().gui_disable_input = true
		main.ball.set_process_input(false)
	main.ball.shot_started.connect(func(at: Vector2, direction: Vector2, power: float): _event("shot", {"position": at, "direction": direction, "power": power}))
	main.ball.ball_stopped.connect(func(at: Vector2): _event("stop", {"position": at}))
	main.ball.wall_impact.connect(func(strength: float, at: Vector2): _event("wall", {"position": at, "strength": strength}))
	main.level_builder.reset_hazard_body_entered.connect(func(_body: Node2D, at: Vector2, kind: StringName): _event("hazard", {"position": at, "kind": kind}))
	main.ball.sink_animation_finished.connect(func(): _event("sink", {}))
	main.shop_manager.card_bought.connect(func(card: CardDefinition): _event("purchase", {"card": card.id, "price": card.price}))
	main.audio_controller.cue_requested.connect(func(cue: StringName): _event("audio", {"cue": cue}))
	if not baseline and ResourceLoader.exists("res://tools/pixel_sample/sample_skin.gd"):
		skin = _make_skin()
		add_child(skin)
		skin.setup(main)
	if gallery_mode:
		_run_gallery.call_deferred()
	elif checks_mode:
		var checks := preload("res://tools/pixel_sample/sample_checks.gd").new()
		add_child(checks)
		checks.run.call_deferred(self)
	elif automate:
		_run_recording.call_deferred()
	main.menu_play_button.pressed.disconnect(main._on_menu_play_pressed)
	main.menu_play_button.pressed.connect(_start_hole)
	main.menu_play_button.text = "PLAY SAMPLE"
	main.shop_manager.continued.disconnect(main._on_shop_continued)
	main.shop_manager.continued.connect(_on_sample_shop_continued)
	if not automate and not gallery_mode and not checks_mode: _review_controls()
	print("[PIXEL SAMPLE] baseline=%s automate=%s" % [baseline, automate])

func _physics_process(_delta: float) -> void:
	frame += 1

func _make_skin() -> Node:
	return preload("res://tools/pixel_sample/sample_skin.gd").new()

func _feedback_script() -> Script:
	return preload("res://tools/pixel_sample/sample_feedback.gd")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or automate: return
	if event.keycode == KEY_F5:
		_start_hole()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F7:
		_show_sample_shop()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F8:
		main._show_main_menu()
		get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_1, KEY_2] and not baseline:
		main.audio_controller.select_candidate(0 if event.keycode == KEY_1 else 1)
		get_viewport().set_input_as_handled()

func _review_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	var hint := Label.new()
	hint.text = "PRESENTATION SAMPLE   ·   F5 retry hole   ·   F7 shop   ·   F8 title   ·   1 / 2 soundtrack A / B" if not baseline else "ORIGINAL PRESENTATION   ·   F5 retry hole   ·   F7 shop   ·   F8 title"
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("fff1dc"))
	hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	hint.add_theme_constant_override("shadow_offset_y", 2)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hint)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left = 25
	hint.offset_top = -45 if not baseline else -26
	if not baseline:
		var credit := Label.new()
		credit.text = "Music: Peppers Funk / Rocker Chicks — Jason Shaw · audionautix.com · CC BY 4.0 · 1 / 2 selects or replays"
		credit.add_theme_font_size_override("font_size", 14)
		credit.add_theme_color_override("font_color", Color("fff1dc"))
		credit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(credit)
		credit.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		credit.offset_left = 25
		credit.offset_top = -23

func _start_hole() -> void:
	main._hide_main_menu()
	main._hide_interstitial()
	main.run_state.tutorial_mode = false
	main._reset_run_state(Fixture.SEED)
	main.run_state.difficulty_profile = DifficultyDatabase.get_profile(&"easy")
	main.run_state.phase = RunState.Phase.RUN_START
	main.run_state.tokens = 12 # Approval wallet; production starting balance is unchanged.
	for index in 18:
		main.run_state.normal_levels.append(Fixture.create())
	main.run_state.levels = main.run_state.normal_levels.duplicate(true)
	main._load_level(2)
	var before := _physics_snapshot()
	if skin: skin.apply_hole()
	physics_unchanged = physics_unchanged and before == _physics_snapshot()
	_event("hole_loaded", {"seed": Fixture.SEED})

func _show_sample_shop() -> void:
	if main.run_state.levels.is_empty() or main.run_state.tutorial_mode or main.run_state.levels[main.run_state.level_index].get("hole_name", "") != "THE OLD SWING":
		_start_hole()
	main._hide_main_menu()
	main._hide_interstitial()
	main.ball.set_input_enabled(false)
	main.run_state.phase = RunState.Phase.HOLE_RESULTS
	main._show_shop(3)
	if skin: skin.apply_shop()

func _on_sample_shop_continued() -> void:
	if main.run_state.tutorial_mode: main._on_shop_continued()
	else: _start_hole()

func _aim(direction: Vector2, power: float) -> void:
	main.ball.keyboard_direction = direction.normalized()
	main.ball.keyboard_power = power
	main.ball.keyboard_active = true

func _strike(direction: Vector2, power: float) -> void:
	var accepted: bool = main.ball.shoot_normalized(direction, power)
	_event("input", {"accepted": accepted, "direction": direction, "power": power})

func _run_recording() -> void:
	await _frames(90)
	await _capture("01_title")
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
	_event("bank_stop", {"position": main.ball.position})
	_aim(Vector2(0.4, -1), 0.28)
	await _frames(45)
	_strike(Vector2(0.4, -1), 0.28)
	await _frames(330)
	_event("hazard_stop", {"position": main.ball.position})
	await _frames(60)
	_aim(Vector2.RIGHT, 0.75)
	await _frames(45)
	_strike(Vector2.RIGHT, 0.75)
	await _frames(360)
	_event("approach_stop", {"position": main.ball.position, "phase": main.run_phase})
	await _capture("04_outcome")
	if main.run_phase == RunState.Phase.HOLE_RESULTS:
		main._on_interstitial_continue_pressed()
	else:
		push_error("Sample replay did not reach actual hole results.")
		get_tree().quit(1)
		return
	if skin: skin.apply_shop()
	await _frames(80)
	await _capture("05_shop")
	main.shop_manager.shop_card_buttons[0].pressed.emit()
	await _frames(10)
	await _capture("06_purchase_contact")
	await _frames(60)
	await _capture("07_purchased")
	await _frames(90)
	var report := {"baseline": baseline, "frames": frame, "events": events, "captures": captures, "size": desired_size, "physics_unchanged": physics_unchanged}
	FileAccess.open(output_dir.path_join("events.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("[PIXEL SAMPLE] DONE " + JSON.stringify(report))
	main.audio_controller.stop_all_audio()
	await _frames(6)
	get_tree().quit()

func _physics_snapshot() -> Array:
	var result: Array = []
	for node in main.level_builder.level_root.find_children("*", "", true, false):
		if node is CollisionShape2D:
			result.append([node.get_path(), node.transform, node.disabled, node.shape.get_class(), node.shape.get_rect()])
		elif node is CollisionObject2D:
			result.append([node.get_path(), node.transform, node.collision_layer, node.collision_mask])
	return result

func _run_gallery() -> void:
	await _frames(35)
	await _capture("01_title")
	_start_hole()
	await _frames(45)
	main.camera.toggle_overview()
	await _frames(35)
	await _capture("02_hole")
	_show_sample_shop()
	await _frames(40)
	await _capture("05_shop")
	main.game_settings.ui_appearance = &"light"
	main._apply_player_settings()
	if skin: skin.apply_shop()
	await _frames(5)
	await _capture("09_shop_light")
	main.audio_controller.stop_all_audio()
	await _frames(6)
	print("[SAMPLE GALLERY] captures=%d physics_unchanged=%s" % [captures, physics_unchanged])
	get_tree().quit(0 if physics_unchanged and captures == 4 else 1)

func _frames(count: int) -> void:
	for index in count: await get_tree().physics_frame

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(output_dir.path_join(label + ".png"))
	if error == OK: captures += 1

func _event(kind: String, data: Dictionary) -> void:
	data["event"] = kind
	data["frame"] = frame
	events.append(data)
	print("[SAMPLE EVENT] " + JSON.stringify(data))
