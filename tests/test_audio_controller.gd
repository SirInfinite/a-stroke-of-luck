extends GutTest

const AudioControllerScript := preload("res://scripts/audio_controller.gd")
const ShopManagerScript := preload("res://scripts/shop_manager.gd")
const OWNER_SUPPLIED_SHA256 := {
	"res://assets/audio/boost_pad_slow.wav": "2ebf220b4d1b9cedd3e2a42af1739e105c14f1877e1bddb80145124a61f38cc1",
	"res://assets/audio/boost_pad_med.wav": "2915a27ba866acbad3ed8ccfc2488a6ae5cece5aea1f06bb584e33fc3d25e996",
	"res://assets/audio/boost_pad_fast.wav": "c872e472f03c01380daab3686fce0ff8d5047819bcc9fe1d0b396b7fc8876b12",
	"res://assets/audio/fail_sound_1.wav": "7a41c6a80596db9ae26e44dae5498905bedab6a77889eca963ac2a14aa50da1b",
	"res://assets/audio/fail_sound_2.wav": "f5d2ac2b046e7f9277dde0dcd55e341e7177d0c792bf5740f94fd80ba46e8292",
}


func test_audio_assets_and_required_buses_are_available() -> void:
	assert_ne(AudioServer.get_bus_index(&"Master"), -1)
	assert_ne(AudioServer.get_bus_index(&"Music"), -1)
	assert_ne(AudioServer.get_bus_index(&"SFX"), -1)
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(&"Music")), &"Master")
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(&"SFX")), &"Master")
	assert_gt(AudioServer.get_bus_effect_count(AudioServer.get_bus_index(&"Master")), 0)
	assert_true(AudioServer.get_bus_effect(AudioServer.get_bus_index(&"Master"), 0) is AudioEffectLimiter)
	assert_eq(AudioControllerScript.THEME_STREAMS.size(), 8)
	assert_eq(AudioControllerScript.AMBIENCE_STREAMS.size(), 6)
	var theme_paths: Dictionary = {}
	for theme in AudioControllerScript.THEME_STREAMS:
		var theme_stream: AudioStream = AudioControllerScript.THEME_STREAMS[theme]
		assert_not_null(theme_stream, "Missing theme for %s." % theme)
		assert_gte(theme_stream.get_length(), 30.0, "%s must be a substantive long-form musical loop." % theme)
		theme_paths[theme_stream.resource_path] = true
	assert_eq(theme_paths.size(), 8, "Every music state must use a distinct stream.")
	for ambience in AudioControllerScript.AMBIENCE_STREAMS:
		var ambience_stream: AudioStream = AudioControllerScript.AMBIENCE_STREAMS[ambience]
		assert_not_null(ambience_stream, "Missing ambience for %s." % ambience)
		assert_gte(ambience_stream.get_length(), 8.0)
	for cue in AudioControllerScript.SFX_STREAMS:
		assert_not_null(AudioControllerScript.SFX_STREAMS[cue], "Missing audio stream for %s." % cue)


func test_owner_supplied_wavs_remain_byte_exact() -> void:
	for path in OWNER_SUPPLIED_SHA256:
		assert_eq(FileAccess.get_sha256(path), OWNER_SUPPLIED_SHA256[path], "%s was unexpectedly replaced." % path)


func test_audio_players_route_to_music_and_sfx_buses() -> void:
	var audio = AudioControllerScript.new()
	add_child_autofree(audio)
	await wait_process_frames(1)

	assert_eq(audio.music_players.size(), 2)
	assert_eq(audio.ambience_players.size(), 2)
	for player in audio.music_players + audio.ambience_players:
		assert_eq(player.bus, &"Music")
	assert_eq(audio.swoosh_player.bus, &"SFX")
	assert_eq(audio.sfx_players.size(), audio.SFX_POOL_SIZE)
	for player in audio.sfx_players:
		assert_eq(player.bus, &"SFX")


func test_music_state_keeps_only_target_theme_and_ambience_active() -> void:
	var audio = AudioControllerScript.new()
	add_child_autofree(audio)
	await wait_process_frames(1)

	assert_eq(audio.music_state, &"menu")
	assert_eq(_assigned_stream_count(audio.music_players), 1)
	assert_eq(_assigned_stream_count(audio.ambience_players), 0)
	audio.play_tutorial_music()
	assert_eq(audio.music_state, &"tutorial")
	assert_same(audio.music_players[audio.active_music_player_index].stream, AudioControllerScript.THEME_STREAMS[&"tutorial"])
	assert_eq(_assigned_stream_count(audio.ambience_players), 0)
	audio.set_biome(3)
	assert_eq(audio.music_state, &"snow")
	assert_eq(_assigned_stream_count(audio.music_players), 1)
	assert_eq(_assigned_stream_count(audio.ambience_players), 1)
	assert_same(audio.music_players[audio.active_music_player_index].stream, AudioControllerScript.THEME_STREAMS[&"snow"])
	assert_same(audio.ambience_players[audio.active_ambience_player_index].stream, AudioControllerScript.AMBIENCE_STREAMS[&"snow"])
	audio.set_biome(5)
	assert_eq(audio.music_state, &"volcanic")
	assert_eq(_assigned_stream_count(audio.music_players), 1)
	assert_eq(_assigned_stream_count(audio.ambience_players), 1)
	audio.play_results_music()
	assert_eq(audio.music_state, &"menu")
	assert_eq(_assigned_stream_count(audio.music_players), 1)
	assert_eq(_assigned_stream_count(audio.ambience_players), 0)


func test_slow_ball_has_no_loop_and_fast_ball_gets_bounded_swoosh() -> void:
	var audio = AudioControllerScript.new()
	add_child_autofree(audio)
	await wait_process_frames(1)

	audio.update_ball_roll(audio.SWOOSH_START_SPEED - 1.0, true)
	assert_false(audio.swoosh_player.playing)
	assert_eq(audio.swoosh_player.volume_db, audio.SILENT_VOLUME_DB)
	audio.update_ball_roll(audio.SWOOSH_START_SPEED + 100.0, true)
	assert_gt(audio.swoosh_player.volume_db, -25.0)
	assert_lte(audio.swoosh_player.volume_db, -12.0)
	assert_eq(audio.swoosh_player.playing, audio.playback_enabled)
	audio.update_ball_roll(0.0, true)
	assert_false(audio.swoosh_player.playing)
	audio.update_ball_roll(audio.SWOOSH_FULL_SPEED, false)
	assert_false(audio.swoosh_player.playing)


func test_boost_strength_maps_all_three_owner_supplied_streams() -> void:
	var audio = AudioControllerScript.new()
	add_child_autofree(audio)
	await wait_process_frames(1)
	watch_signals(audio)

	audio.play_boost_pad(0.2)
	audio.play_boost_pad(0.5)
	audio.play_boost_pad(0.9)

	assert_signal_emit_count(audio, "cue_requested", 3)
	assert_signal_emitted_with_parameters(audio, "cue_requested", [&"boost_low"], 0)
	assert_signal_emitted_with_parameters(audio, "cue_requested", [&"boost_medium"], 1)
	assert_signal_emitted_with_parameters(audio, "cue_requested", [&"boost_high"], 2)
	assert_same(AudioControllerScript.SFX_STREAMS[&"boost_low"], AudioControllerScript.BOOST_STREAMS[0])
	assert_same(AudioControllerScript.SFX_STREAMS[&"boost_medium"], AudioControllerScript.BOOST_STREAMS[1])
	assert_same(AudioControllerScript.SFX_STREAMS[&"boost_high"], AudioControllerScript.BOOST_STREAMS[2])


func test_hazard_semantics_are_distinct_and_generic_bounce_does_not_double_play() -> void:
	var audio = AudioControllerScript.new()
	add_child_autofree(audio)
	await wait_process_frames(1)
	watch_signals(audio)

	audio.play_hazard_triggered(&"bounce_pad", 0.5)
	assert_signal_emit_count(audio, "cue_requested", 0)
	audio.play_boost_pad(0.5)
	audio.play_hazard_triggered(&"water", 1.0)
	audio.play_hazard_triggered(&"lava", 1.0)
	audio.play_hazard_triggered(&"falling_ice", 1.0)
	audio.play_hazard_triggered(&"pendulum", 1.0)

	assert_signal_emit_count(audio, "cue_requested", 5)
	assert_signal_emitted_with_parameters(audio, "cue_requested", [&"boost_medium"], 0)
	assert_signal_emitted_with_parameters(audio, "cue_requested", [&"water"], 1)
	assert_signal_emitted_with_parameters(audio, "cue_requested", [&"lava"], 2)
	assert_signal_emitted_with_parameters(audio, "cue_requested", [&"ice_impact"], 3)
	assert_signal_emitted_with_parameters(audio, "cue_requested", [&"wall_impact"], 4)


func test_failure_outcome_triggers_both_supplied_sounds_without_success_cue() -> void:
	var audio = AudioControllerScript.new()
	add_child_autofree(audio)
	await wait_process_frames(1)
	watch_signals(audio)

	audio.play_hole_outcome(false, &"stroke_ceiling")

	assert_signal_emit_count(audio, "cue_requested", 2)
	assert_signal_emitted_with_parameters(audio, "cue_requested", [&"failure_1"], 0)
	assert_signal_emitted_with_parameters(audio, "cue_requested", [&"failure_2"], 1)


func test_success_outcome_uses_positive_cue_without_failure_sounds() -> void:
	var audio = AudioControllerScript.new()
	add_child_autofree(audio)
	await wait_process_frames(1)
	watch_signals(audio)

	audio.play_hole_outcome(true, &"cup")

	assert_signal_emit_count(audio, "cue_requested", 1)
	assert_signal_emitted_with_parameters(audio, "cue_requested", [&"hole_completion"])


func test_sand_keeps_the_existing_terrain_impact_asset() -> void:
	assert_same(AudioControllerScript.SAND_STREAM, AudioControllerScript.SFX_STREAMS[&"terrain_impact"])
	assert_eq(AudioControllerScript.SAND_STREAM.resource_path, "res://assets/audio/terrain_impact.wav")
	assert_eq(FileAccess.get_sha256("res://assets/audio/terrain_impact.wav"), "2e371ca8e048dd0ebca67bad303a77a4426ee67e933032484bd568427ad66de4")


func test_repeated_one_shot_cues_are_debounced() -> void:
	var audio = AudioControllerScript.new()
	add_child_autofree(audio)
	await wait_process_frames(1)
	watch_signals(audio)

	audio.play_water()
	audio.play_water()

	assert_signal_emit_count(audio, "cue_requested", 1)


func test_reset_stops_motion_and_clears_transient_voices() -> void:
	var audio = AudioControllerScript.new()
	add_child_autofree(audio)
	await wait_process_frames(1)
	audio.sfx_players[0].stream = AudioControllerScript.SFX_STREAMS[&"water"]

	audio.stop_transient_audio()

	assert_false(audio.swoosh_player.playing)
	for player in audio.sfx_players:
		assert_false(player.playing)
		assert_null(player.stream)


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


func _assigned_stream_count(players: Array[AudioStreamPlayer]) -> int:
	var count := 0
	for player in players:
		if player.stream != null:
			count += 1
	return count
