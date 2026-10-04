extends Node2D
## Rendered, real-player lifecycle audit. Does not approve subjective audio quality.

const MainScene := preload("res://scenes/main.tscn")
const OUTPUT := "user://structural_audio_overhaul_20260906"
var output_directory := OUTPUT
var main
var checks := 0
var failures: Array[String] = []
var stages: Array[Dictionary] = []
var cues: Array[StringName] = []
var review_complete := false
var peak_db := -100.0
var max_music_voices := 0
var max_ambience_voices := 0
var recorder := AudioEffectRecord.new()


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-root="):
			output_directory = argument.trim_prefix("--output-root=")
	DirAccess.make_dir_recursive_absolute(output_directory)
	main = MainScene.instantiate()
	add_child(main)
	main.set_process(false)
	# Reproducible runtime mix, without saving over the player's preferences.
	GameSettings.new().apply_runtime(false)
	main.audio_controller.cue_requested.connect(func(cue: StringName): cues.append(cue))
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recorder)
	recorder.set_recording_active(true)
	_run.call_deferred()


func _process(_delta: float) -> void:
	if not is_instance_valid(main):
		return
	max_music_voices = maxi(max_music_voices, _playing(main.audio_controller.music_players))
	max_ambience_voices = maxi(max_ambience_voices, _playing(main.audio_controller.ambience_players))
	peak_db = maxf(peak_db, maxf(AudioServer.get_bus_peak_volume_left_db(0, 0), AudioServer.get_bus_peak_volume_right_db(0, 0)))


func _run() -> void:
	_check(main.audio_controller.playback_enabled, "Real audio driver enabled; Dummy is not playback evidence")
	await _stage("menu", &"menu")
	var player: AudioStreamPlayer = main.audio_controller.music_players[main.audio_controller.active_music_player_index]
	var position_before := player.get_playback_position()
	main._on_menu_settings_pressed()
	await get_tree().create_timer(0.3).timeout
	main.settings_screen.close()
	_check(player.get_playback_position() > position_before, "Settings does not restart the menu track")
	main._start_tutorial()
	await _stage("tutorial", &"tutorial")
	main._show_main_menu()
	await _stage("tutorial_pause", &"tutorial")
	main._start_normal_run(424242)
	await _stage("new_round", &"menu")
	main._on_interstitial_continue_pressed()
	main._on_interstitial_continue_pressed()
	for biome in range(6):
		# Use the real loader for isolated biome snapshots, not a simulated round.
		main._load_level(biome * 3)
		main.audio_controller.set_biome(biome)
		await _stage("biome_%d" % biome, GameAudioController.BIOME_THEME_KEYS[biome])
		main._on_ball_shot_started(main.ball.global_position, Vector2.RIGHT, 0.65)
		main._on_ball_wall_impact(0.7, main.ball.global_position)
		await get_tree().create_timer(0.25).timeout
		main.audio_controller.play_terrain_impact([&"sand", &"water", &"ice", &"lava"][biome % 4])
		await get_tree().create_timer(0.35).timeout
	main.audio_controller.update_ball_roll(1400.0, true)
	await get_tree().create_timer(0.3).timeout
	_check(main.audio_controller.swoosh_player.playing, "High speed plays the noise swoosh")
	var music_before_pause: int = main.audio_controller.music_transition_generation
	main._show_main_menu()
	_check(not main.audio_controller.swoosh_player.playing, "Pause stops movement audio")
	await get_tree().create_timer(0.3).timeout
	main._hide_main_menu()
	_check(main.audio_controller.music_transition_generation == music_before_pause, "Resume preserves music playhead")
	for strength in [0.45, 0.7, 1.0]:
		main.audio_controller.play_boost_pad(strength)
		await get_tree().create_timer(0.7).timeout
	main._reset_current_level()
	_check(main.audio_controller.sfx_players.all(func(p): return not p.playing and p.stream == null), "Reset clears all transient voices")
	cues.clear()
	main._complete_current_hole(false, false)
	await _stage("hole_success", &"volcanic")
	_check(cues.count(&"crowd_success") == 1 and not cues.has(&"crowd_failure"), "Success has one applause and no disappointed crowd")
	main.run_state.tokens = 99
	main._show_shop(3)
	cues.clear()
	main.shop_manager.shop_card_buttons[0].pressed.emit()
	await _stage("shop_purchase", &"volcanic")
	_check(cues.count(&"purchase") == 1 and not cues.has(&"ui_click"), "Purchase has no generic duplicate click")
	_check(main.shop_manager.shop_card_slots[0].get_global_rect().grow(1.0).encloses(main.shop_manager.shop_card_buttons[0].get_global_rect()), "Purchased card remains inside its layout slot")
	main.run_state.tokens = 0
	cues.clear()
	main.shop_manager._on_shop_card_pressed(1)
	_check(cues.has(&"error") and not cues.has(&"purchase"), "Rejected purchase has no kaching")
	main.shop_manager._on_shop_continue_pressed()
	main._on_interstitial_continue_pressed()
	main.run_state.strokes = int(main.run_state.levels[main.run_state.level_index].par) + 4
	cues.clear()
	main._complete_current_hole(false, true)
	await _stage("failure", GameAudioController.BIOME_THEME_KEYS[main.run_state.biome_index])
	_check(cues.count(&"failure_1") == 1 and cues.count(&"failure_2") == 1, "Both supplied failure layers play")
	_check(not cues.has(&"hole_completion") and not cues.has(&"cup_sink") and not cues.has(&"crowd_success"), "Failure has no success audio")
	_check(cues.count(&"crowd_failure") == 1, "Failure has one disappointed crowd")
	main._show_run_results()
	await _stage("run_results", &"menu")
	main._show_ending()
	await _stage("ending", &"menu")
	main._start_normal_run(1717)
	await _stage("second_round", &"menu")
	main._show_main_menu()
	await _stage("return_to_menu", &"menu")
	# Interrupt crossfades faster than their duration; latest request must win.
	for theme in GameAudioController.BIOME_THEME_KEYS:
		main.audio_controller.set_music_state(theme)
		await get_tree().create_timer(0.12).timeout
	main.audio_controller.play_menu_music()
	await _stage("rapid_transition_cleanup", &"menu")
	_check(max_music_voices <= 2 and max_ambience_voices <= 2, "Crossfade pools remain bounded")
	_check(peak_db > -70.0 and peak_db < -2.0, "Real mixed output has headroom without reaching the master limiter")
	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	_check(recording != null and recording.get_length() > 20.0, "Master recording contains the playback tour")
	if recording:
		_check(recording.save_to_wav(output_directory.path_join("audio_lifecycle_mix.wav")) == OK, "Save listening evidence")
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	var report := {"checks": checks, "failures": failures, "audio_driver": AudioServer.get_driver_name(), "peak_db": peak_db, "max_music_voices": max_music_voices, "max_ambience_voices": max_ambience_voices, "stages": stages, "human_listening": "NOT PERFORMED"}
	var file := FileAccess.open(output_directory.path_join("audio_lifecycle_report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	main.audio_controller.stop_all_audio()
	print("[AUDIO LIFECYCLE] %d checks / %d failures / %.2f dBFS peak / %s" % [checks, failures.size(), peak_db, AudioServer.get_driver_name()])
	review_complete = true
	if OS.get_cmdline_user_args().has("--quit-on-complete"):
		get_tree().quit(0 if failures.is_empty() else 1)


func _stage(label: String, expected: StringName) -> void:
	await get_tree().create_timer(1.05).timeout
	var audio: GameAudioController = main.audio_controller
	_check(audio.music_state == expected, label + ": correct track")
	_check(_playing(audio.music_players) == 1, label + ": only target music playing")
	_check(audio.music_players.filter(func(p): return p.stream != null).size() == 1, label + ": no stale track")
	var expected_ambience := 1 if GameAudioController.AMBIENCE_STREAMS.has(expected) else 0
	_check(_playing(audio.ambience_players) == expected_ambience, label + ": correct ambience voices")
	stages.append({"stage": label, "music": expected, "music_voices": _playing(audio.music_players), "ambience_voices": _playing(audio.ambience_players)})
	if label in ["tutorial", "shop_purchase", "failure", "ending"]:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output_directory.path_join(label + ".png"))


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _playing(players: Array[AudioStreamPlayer]) -> int:
	return players.filter(func(p): return p.playing).size()
