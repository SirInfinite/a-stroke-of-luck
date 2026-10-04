extends Node
## Engine-driven assertions complement, and do not replace, human play/listening.

var harness
var main
var assertions: Array[Dictionary] = []

func run(sample) -> void:
	harness = sample
	main = harness.main
	harness._show_sample_shop()
	await harness._frames(2)
	check(main.run_state.phase == RunState.Phase.SHOP and main.shop_manager.shop_overlay.visible, "Direct shop shortcut from a fresh title initializes the sample fixture")
	harness._start_hole()
	await harness._frames(45)
	check(harness.physics_unchanged, "Visual adapters preserve collision objects, transforms, layers and shapes")
	check(main.level_builder.active_level.hole_name == "THE OLD SWING", "Actual fixture passed validation without authored fallback")
	var start: Vector2 = main.ball.global_position
	var screen: Vector2 = main.ball.get_global_transform_with_canvas().origin
	# Window.get_mouse_position reads the OS cursor, not injected mouse events.
	# Native desktop automation is unavailable; do not call this a mouse playtest.
	check((main.ball.get_canvas_transform().affine_inverse() * screen).distance_to(start) < 0.01, "Course/screen projection round-trip at current camera is exact")
	var drag_screen: Vector2 = main.ball.get_canvas_transform() * (start + Vector2(-90, 0))
	var course_drag: Vector2 = main.ball.get_canvas_transform().affine_inverse() * drag_screen
	check((start - course_drag).normalized().dot(Vector2.RIGHT) > 0.999, "Projected horizontal drag maps back to a horizontal course vector")
	harness._aim(Vector2.RIGHT, 0.2)
	await harness._frames(2)
	check(main.ball.aim_line.visible, "Native aiming preview is visible")
	var prediction: Dictionary = main.ball.get_trajectory_prediction(main.ball._keyboard_shot_impulse())
	check(not prediction.points.is_empty(), "Native straight-distance forecast is populated")
	main.camera.toggle_overview()
	await harness._frames(35)
	check(not main.ball.selected and not main.ball.keyboard_active, "Overview cancels both aiming modes")
	_release(drag_screen)
	await harness._frames(2)
	check(not main.ball.shot_in_progress, "Mouse release after overview cannot fire")
	main.camera.toggle_overview()
	await harness._frames(35)
	harness._aim(Vector2.RIGHT, 0.2)
	var key := InputEventKey.new()
	key.keycode = main.game_settings.shoot_keycode
	key.pressed = true
	get_viewport().push_input(key)
	await harness._frames(2)
	check(main.ball.shot_in_progress, "Configured keyboard key commits a real shot")
	key.pressed = false
	get_viewport().push_input(key)
	await harness._frames(250)
	check(main.ball.can_shoot(), "Shot returns to ready without a presentation wait")
	for index in 20:
		main.feedback_director.play_shot_feedback(start, Vector2.RIGHT, 0.6)
		main.feedback_director.play_wall_impact(0.5, start)
		main.feedback_director.play_hazard_feedback(&"pendulum", 1.0, start)
		main.feedback_director.play_stop_feedback(start)
		await harness._frames(45)
	check(main.feedback_director.transient_root.get_child_count() == 0, "Twenty feedback cycles leave no transient sprites")
	check(main.camera.offset.length() < 0.01, "Camera impact offset fully recovers")
	var purchases_before := _cue_count(&"purchase")
	for index in 20:
		main.run_state.tokens = 100
		harness._show_sample_shop()
		await harness._frames(2)
		main.shop_manager.shop_card_buttons[0].pressed.emit()
		await harness._frames(50)
	check(_cue_count(&"purchase") - purchases_before == 20, "Twenty accepted purchases emit twenty purchase cues")
	check(harness.skin.fx_layer.get_child_count() == 0, "Twenty purchases leave no coins or acknowledgement stamps")
	var before_duplicate := _cue_count(&"purchase")
	main.shop_manager.shop_card_buttons[0].pressed.emit()
	await harness._frames(20)
	check(_cue_count(&"purchase") == before_duplicate, "Rejected duplicate cannot emit a purchase cue")
	main.game_settings.reduced_motion = true
	main._apply_player_settings()
	harness._start_hole()
	await harness._frames(15)
	main.feedback_director.play_shot_feedback(main.ball.position, Vector2.RIGHT, 1.0)
	await harness._frames(2)
	check(main.camera.offset == Vector2.ZERO, "Reduced motion suppresses shot shake")
	main.run_state.tokens = 100
	harness._show_sample_shop()
	await harness._frames(4)
	main.shop_manager.shop_card_buttons[0].pressed.emit()
	await harness._frames(1)
	check(harness.skin.fx_layer.find_children("*", "TextureRect", true, false).is_empty(), "Reduced motion suppresses flying coins")
	await harness._frames(55)
	await harness._capture("08_reduced_motion_shop")
	for appearance in [&"dark", &"light"]:
		main.game_settings.ui_appearance = appearance
		main._apply_player_settings()
		harness.skin.apply_shop()
		await harness._frames(3)
		_check_shop_layout()
		await harness._capture("09_shop_" + appearance)
	# A partial asset family must not replace an unillustrated tutorial offer.
	var native_card := UICard.new()
	add_child(native_card)
	native_card.configure_card(CardDatabase.get_cards()[3], true, false)
	harness.skin._card(native_card)
	check(native_card.centerpiece_icon.visible and not native_card.has_meta(&"sample_illustration"), "Unillustrated cards retain native art without missing-resource loads")
	native_card.queue_free()
	var destination: String = main.shop_manager.shop_destination_label.text
	main.shop_manager.shop_destination_label.text = "Tutorial destination sentinel"
	main.run_state.tutorial_mode = true
	harness.skin.apply_shop()
	check(main.shop_manager.shop_destination_label.text == "Tutorial destination sentinel", "Sample skin preserves tutorial shop wording")
	main.shop_manager.shop_destination_label.text = destination
	harness._start_hole()
	check(not main.run_state.tutorial_mode, "Retrying sample after tutorial clears tutorial mode")
	main.audio_controller.select_candidate(1)
	await harness._frames(60)
	check(main.audio_controller.active_music_player_index in [0, 1], "Candidate selection retains the existing two-voice music routing")
	main.audio_controller.stop_all_audio()
	await harness._frames(6)
	var failed := assertions.filter(func(item): return not item.passed).size()
	var report := {"assertions": assertions, "failed": failed, "size": harness.desired_size, "input": "Godot keyboard viewport events and mathematical projection checks", "not_run": ["Native mouse drag/release: desktop helper unavailable; Window ignores injected mouse position", "Subjective repeated-use satisfaction and audio listening"]}
	FileAccess.open(harness.output_dir.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("[SAMPLE CHECKS] " + JSON.stringify(report))
	get_tree().quit(0 if failed == 0 else 1)

func _release(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = at
	event.global_position = at
	event.pressed = false
	get_viewport().push_input(event, true)

func _cue_count(cue: StringName) -> int:
	return harness.events.filter(func(event): return event.event == "audio" and event.cue == cue).size()

func _check_shop_layout() -> void:
	for offer in main.shop_manager.shop_card_buttons:
		if not offer.visible: continue
		check(get_viewport().get_visible_rect().encloses(offer.get_global_rect()), "Card %s fits viewport" % offer.card_id)
		for label in [offer.benefit_description, offer.curse_description, offer.stack_label, offer.name_label]:
			check(label.get_line_count() <= label.get_visible_line_count(), "%s / %s has no clipped lines" % [offer.card_id, label.name])
		for label in [offer.benefit_description, offer.curse_description]:
			check(label.get_theme_color("font_color").get_luminance() > 0.6, "%s effect ink remains bright on authored dark material" % offer.card_id)

func check(passed: bool, label: String) -> void:
	assertions.append({"passed": passed, "check": label})
	if not passed: push_error("Sample check failed: " + label)
