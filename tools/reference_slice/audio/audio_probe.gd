extends SceneTree
## Automated audio lifecycle probe; never used by the manual playable sample.

const Adapter := preload("res://tools/reference_slice/audio/reference_audio.gd")
var controller: GameAudioController
var failures: Array[String] = []
var checks := 0
var cues: Array[StringName] = []
var completed_states: Array[StringName] = []
var recording: AudioEffectRecord
var bus_snapshot: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("Audio probe: " + label)


func count_playing(players: Array[AudioStreamPlayer]) -> int:
	var count := 0
	for player in players:
		if player.playing:
			count += 1
	return count


func _run() -> void:
	for bus in range(AudioServer.bus_count):
		bus_snapshot.append({"name": AudioServer.get_bus_name(bus), "gain": AudioServer.get_bus_volume_db(bus), "mute": AudioServer.is_bus_mute(bus)})
	controller = Adapter.new()
	root.add_child(controller)
	controller.cue_requested.connect(func(cue: StringName) -> void: cues.append(cue))
	controller.music_transition_completed.connect(func(state: StringName) -> void: completed_states.append(state))
	await process_frame
	expect(AudioServer.get_driver_name() == "WASAPI", "native WASAPI audio driver selected")
	expect(controller.music_players.size() == 2, "two bounded music players")
	expect(controller.ambience_players.size() == 2, "two bounded ambience players")
	expect(controller.sfx_players.size() == 10, "ten bounded SFX voices")
	controller.stop_all_audio()
	# Headless visual rendering is acceptable here, but use the real native audio
	# driver and force playback on so this tests actual player/mixer behavior.
	controller.playback_enabled = AudioServer.get_driver_name() == "WASAPI"
	recording = AudioEffectRecord.new()
	AudioServer.add_bus_effect(0, recording)
	recording.set_recording_active(true)
	controller.set_music_state(&"menu", true)
	await create_timer(.20).timeout
	expect(count_playing(controller.music_players) == 1, "one menu composition playing")
	expect(controller.music_players[controller.active_music_player_index].stream == Adapter.CANDIDATES[0], "candidate A selected")
	var music_player := controller.music_players[controller.active_music_player_index]
	expect((music_player.stream as AudioStreamOggVorbis).loop, "A has native loop enabled")
	music_player.seek(music_player.stream.get_length() - .16)
	await create_timer(.42).timeout
	expect(music_player.playing and music_player.get_playback_position() < 1.0, "A really wraps through loop boundary")
	var position := music_player.get_playback_position()
	controller.set_biome(0)
	await create_timer(.12).timeout
	expect(controller.music_players[controller.active_music_player_index] == music_player, "biome arrival preserves audition voice")
	expect(music_player.get_playback_position() > position, "biome arrival preserves music playhead")
	expect(controller.music_state == &"meadow", "native Meadow state retained")
	controller.update_ball_roll(1200.0, true)
	await create_timer(.10).timeout
	expect(controller.swoosh_player.playing, "high speed movement voice starts")
	controller.set_gameplay_paused(true)
	await create_timer(.12).timeout
	expect(not controller.swoosh_player.playing, "pause stops movement immediately")
	expect(count_playing(controller.music_players) == 1, "pause keeps one music voice")
	expect(controller.music_trim_db < 0.0, "pause trims music")
	controller.set_gameplay_paused(false)
	controller.select_candidate(1)
	await create_timer(.10).timeout
	expect(count_playing(controller.music_players) <= 2, "crossfade bounds music to two voices")
	controller.select_candidate(0)
	await create_timer(.95).timeout
	expect(count_playing(controller.music_players) == 1, "rapid candidate switches settle to one voice")
	expect(controller.music_players[controller.active_music_player_index].stream == Adapter.CANDIDATES[0], "latest candidate wins")
	controller.select_candidate(1)
	controller.set_biome(5)
	await create_timer(.95).timeout
	expect(count_playing(controller.music_players) == 1, "B settles to one music voice")
	expect(completed_states.back() == &"volcanic", "crossfade completion reports latest native biome")
	controller.set_biome(0)
	var b_player := controller.music_players[controller.active_music_player_index]
	expect((b_player.stream as AudioStreamOggVorbis).loop, "B has native loop enabled")
	b_player.seek(b_player.stream.get_length() - .16)
	await create_timer(.42).timeout
	expect(b_player.playing and b_player.get_playback_position() < 1.0, "B really wraps through loop boundary")
	controller.play_golf_strike(.82)
	await create_timer(.20).timeout
	controller.play_wall_impact(.8)
	await create_timer(.24).timeout
	controller.play_hazard_triggered(&"pendulum", 1.0)
	await create_timer(.50).timeout
	controller.play_terrain_impact(&"sand")
	controller.play_boost_pad(.9)
	await create_timer(.25).timeout
	expect(cues.has(&"golf_strike"), "native strike reaches custom material")
	expect(cues.has(&"wall_impact"), "native wall impact reaches custom material")
	expect(cues.has(&"slice_pendulum"), "pendulum has distinct material cue")
	expect(cues.has(&"terrain_impact"), "protected sand still routed")
	expect(cues.has(&"boost_high"), "protected supplied boost still routed")
	cues.clear()
	controller.play_card_acquired(false)
	await create_timer(.22).timeout
	expect(cues.count(&"purchase") == 1, "accepted purchase plays one purchase cue")
	expect(cues.count(&"curse") == 1, "accepted purchase adds one quiet curse acknowledgement")
	expect(cues.count(&"ui_click") == 0, "purchase adds no generic click")
	cues.clear()
	controller.play_card_acquired(true)
	controller.stop_transient_audio()
	await create_timer(.20).timeout
	expect(cues.count(&"card_stack") == 0, "reset cancels pending card accent")
	controller.play_cup_sink()
	controller.play_hole_outcome(true)
	await create_timer(.08).timeout
	controller.play_failure()
	controller.play_cup_sink()
	controller.play_hole_outcome(true)
	expect(cues.count(&"failure_1") == 1 and cues.count(&"failure_2") == 1, "failure retains both protected layers")
	expect(cues.count(&"cup_sink") == 1, "failure suppresses later cup success")
	expect(cues.count(&"hole_completion") == 1, "failure suppresses later completion")
	for player in controller.sfx_players:
		expect(not (player.playing and player.stream in [Adapter.MATERIALS[&"cup_sink"], Adapter.MATERIALS[&"hole_completion"]]), "failure cancels substituted positive voice")
	controller.stop_transient_audio()
	controller.set_biome(5)
	await create_timer(.95).timeout
	expect(controller.music_state == &"volcanic", "native Volcanic state retained")
	expect(count_playing(controller.ambience_players) == 1, "one Volcanic ambience after fade")
	controller.play_menu_music()
	await create_timer(.95).timeout
	expect(count_playing(controller.ambience_players) == 0, "menu clears biome ambience")
	cues.clear()
	for repetition in range(150):
		controller.play_golf_strike(.6)
	expect(controller.sfx_players.size() == 10, "dense events keep pool bounded")
	expect(cues.count(&"golf_strike") == 1, "same-frame strike storm emits one audible transient")
	await create_timer(.18).timeout
	controller.stop_all_audio()
	expect(count_playing(controller.music_players + controller.ambience_players + controller.sfx_players) == 0, "stop all clears every player")
	expect(not controller.swoosh_player.playing, "stop all clears swoosh")
	for player in controller.music_players + controller.ambience_players + controller.sfx_players:
		expect(player.stream == null, "stop all releases streams")
	for bus in range(AudioServer.bus_count):
		expect(AudioServer.get_bus_volume_db(bus) == bus_snapshot[bus]["gain"] and AudioServer.is_bus_mute(bus) == bus_snapshot[bus]["mute"], "preserve owner bus values: " + String(bus_snapshot[bus]["name"]))
	recording.set_recording_active(false)
	var captured := recording.get_recording()
	var capture_path := "res://artifacts/reference_review/audio/native_lifecycle.wav"
	captured.save_to_wav(capture_path)
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	var result := {"checks": checks, "failures": failures, "audio_driver": AudioServer.get_driver_name(), "display": DisplayServer.get_name(), "recording": capture_path, "listening": "Not performed; real mixer/player validation only"}
	var report := FileAccess.open("res://artifacts/reference_review/audio/native_lifecycle.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(result, "\t") + "\n")
	report.close()
	print("REFERENCE_AUDIO_PROBE " + JSON.stringify(result))
	controller.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
