extends GutTest

const AudioControllerScript := preload("res://scripts/audio_controller.gd")
const ShopManagerScript := preload("res://scripts/shop_manager.gd")


func test_audio_assets_and_required_buses_are_available() -> void:
	assert_ne(AudioServer.get_bus_index(&"Master"), -1)
	assert_ne(AudioServer.get_bus_index(&"Music"), -1)
	assert_ne(AudioServer.get_bus_index(&"SFX"), -1)
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(&"Music")), &"Master")
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(&"SFX")), &"Master")
	assert_not_null(load("res://assets/audio/ambience_loop.wav"))
	assert_not_null(load("res://assets/audio/ball_roll.wav"))
	for cue in AudioControllerScript.SFX_STREAMS:
		assert_not_null(AudioControllerScript.SFX_STREAMS[cue], "Missing audio stream for %s." % cue)


func test_audio_players_route_to_music_and_sfx_buses() -> void:
	var audio = AudioControllerScript.new()
	add_child_autofree(audio)
	await wait_process_frames(1)

	assert_eq(audio.music_player.bus, &"Music")
	assert_eq(audio.roll_player.bus, &"SFX")
	assert_eq(audio.sfx_players.size(), audio.SFX_POOL_SIZE)
	for player in audio.sfx_players:
		assert_eq(player.bus, &"SFX")


func test_roll_player_tracks_motion_threshold() -> void:
	var audio = AudioControllerScript.new()
	add_child_autofree(audio)
	await wait_process_frames(1)

	audio.update_ball_roll(audio.ROLL_START_SPEED + 100.0, true)
	assert_gt(audio.roll_player.volume_db, -27.0)
	assert_eq(audio.roll_player.playing, audio.playback_enabled)
	audio.update_ball_roll(0.0, true)
	assert_false(audio.roll_player.playing)
	audio.update_ball_roll(audio.ROLL_START_SPEED + 100.0, false)
	assert_false(audio.roll_player.playing)


func test_repeated_one_shot_cues_are_debounced() -> void:
	var audio = AudioControllerScript.new()
	add_child_autofree(audio)
	await wait_process_frames(1)
	watch_signals(audio)

	audio.play_water()
	audio.play_water()

	assert_signal_emit_count(audio, "cue_requested", 1)


func test_special_action_buttons_do_not_layer_generic_click_audio() -> void:
	var audio = AudioControllerScript.new()
	add_child_autofree(audio)
	var purchase_button := Button.new()
	purchase_button.set_meta(&"suppress_ui_click_audio", true)
	add_child_autofree(purchase_button)
	await wait_process_frames(2)
	watch_signals(audio)

	purchase_button.pressed.emit()

	assert_signal_not_emitted(audio, "cue_requested")


func test_shop_purchase_requests_exactly_one_purchase_cue() -> void:
	var root := Node.new()
	add_child_autofree(root)
	var audio = AudioControllerScript.new()
	root.add_child(audio)
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	var shop = ShopManagerScript.new()
	root.add_child(shop)
	shop.feedback_requested.connect(func(kind: StringName):
		if kind == &"purchase":
			audio.play_purchase()
		elif kind == &"error":
			audio.play_error()
	)
	shop.create_overlay(canvas)
	shop.show_shop(3, 99, 18, 424242)
	await wait_process_frames(2)
	watch_signals(audio)

	shop.shop_card_buttons[0].pressed.emit()

	assert_signal_emit_count(audio, "cue_requested", 1)
	assert_signal_emitted_with_parameters(audio, "cue_requested", [&"purchase"])
