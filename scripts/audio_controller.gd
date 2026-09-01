class_name GameAudioController
extends Node

signal cue_requested(cue: StringName)
signal music_state_changed(state: StringName)
signal music_transition_completed(state: StringName)

const THEME_STREAMS := {
	&"menu": preload("res://assets/audio/theme_menu.wav"),
	&"meadow": preload("res://assets/audio/theme_meadow.wav"),
	&"desert": preload("res://assets/audio/theme_desert.wav"),
	&"autumn": preload("res://assets/audio/theme_autumn.wav"),
	&"snow": preload("res://assets/audio/theme_snow.wav"),
	&"swamp": preload("res://assets/audio/theme_swamp.wav"),
	&"volcanic": preload("res://assets/audio/theme_volcanic.wav"),
}
const BIOME_THEME_KEYS: Array[StringName] = [
	&"meadow", &"desert", &"autumn", &"snow", &"swamp", &"volcanic",
]
const AMBIENCE_STREAMS := {
	&"meadow": preload("res://assets/audio/ambience_meadow.wav"),
	&"desert": preload("res://assets/audio/ambience_desert.wav"),
	&"autumn": preload("res://assets/audio/ambience_autumn.wav"),
	&"snow": preload("res://assets/audio/ambience_snow.wav"),
	&"swamp": preload("res://assets/audio/ambience_swamp.wav"),
	&"volcanic": preload("res://assets/audio/ambience_volcanic.wav"),
}
const HIGH_SPEED_SWOOSH_STREAM := preload("res://assets/audio/high_speed_swoosh.wav")
const SAND_STREAM := preload("res://assets/audio/terrain_impact.wav")
const BOOST_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/boost_pad_slow.wav"),
	preload("res://assets/audio/boost_pad_med.wav"),
	preload("res://assets/audio/boost_pad_fast.wav"),
]
const FAILURE_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/fail_sound_1.wav"),
	preload("res://assets/audio/fail_sound_2.wav"),
]
const SFX_STREAMS := {
	&"ui_hover": preload("res://assets/audio/ui_hover.wav"),
	&"ui_click": preload("res://assets/audio/ui_click.wav"),
	&"purchase": preload("res://assets/audio/purchase.wav"),
	&"error": preload("res://assets/audio/ui_error.wav"),
	&"golf_strike": preload("res://assets/audio/golf_strike.wav"),
	&"terrain_impact": SAND_STREAM,
	&"water": preload("res://assets/audio/water.wav"),
	&"lava": preload("res://assets/audio/lava.wav"),
	&"ice_impact": preload("res://assets/audio/ice_impact.wav"),
	&"wall_impact": preload("res://assets/audio/wall_impact.wav"),
	&"cup_sink": preload("res://assets/audio/cup_sink.wav"),
	&"hole_completion": preload("res://assets/audio/hole_completion.wav"),
	&"biome_transition": preload("res://assets/audio/biome_transition.wav"),
	&"final_run_completion": preload("res://assets/audio/final_run_completion.wav"),
	&"boost_low": BOOST_STREAMS[0],
	&"boost_medium": BOOST_STREAMS[1],
	&"boost_high": BOOST_STREAMS[2],
	&"failure_1": FAILURE_STREAMS[0],
	&"failure_2": FAILURE_STREAMS[1],
}

const SFX_POOL_SIZE := 10
const MUSIC_CROSSFADE_DURATION := 0.8
const MUSIC_VOLUME_DB := -5.0
const AMBIENCE_VOLUME_DB := -18.0
const SILENT_VOLUME_DB := -60.0
const SWOOSH_START_SPEED := 520.0
const SWOOSH_FULL_SPEED := 1100.0
const UI_REPEAT_GUARD_MSEC := 35
const CUE_COOLDOWN_MSEC := {
	&"error": 180,
	&"terrain_impact": 120,
	&"water": 350,
	&"lava": 350,
	&"ice_impact": 220,
	&"wall_impact": 120,
	&"cup_sink": 350,
	&"hole_completion": 500,
	&"biome_transition": 500,
	&"final_run_completion": 1200,
	&"boost_low": 180,
	&"boost_medium": 180,
	&"boost_high": 180,
}
const FAILURE_REPEAT_GUARD_MSEC := 900

var music_players: Array[AudioStreamPlayer] = []
var ambience_players: Array[AudioStreamPlayer] = []
var active_music_player_index := 0
var active_ambience_player_index := 0
var music_state: StringName = &""
var music_transition_generation := 0
var ambience_transition_generation := 0
var music_tween: Tween
var ambience_tween: Tween
var swoosh_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var next_sfx_player := 0
var last_ui_time_msec := -UI_REPEAT_GUARD_MSEC
var playback_enabled := false
var last_cue_time_msec: Dictionary = {}
var last_failure_time_msec := -FAILURE_REPEAT_GUARD_MSEC


func _ready() -> void:
	playback_enabled = DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() != "Dummy"
	for index in range(2):
		music_players.append(_create_player("MusicVoice%d" % (index + 1), &"Music"))
		ambience_players.append(_create_player("AmbienceVoice%d" % (index + 1), &"Music"))

	swoosh_player = _create_player("HighSpeedSwoosh", &"SFX")
	swoosh_player.stream = HIGH_SPEED_SWOOSH_STREAM
	_enable_loop(HIGH_SPEED_SWOOSH_STREAM)
	swoosh_player.volume_db = SILENT_VOLUME_DB

	for index in range(SFX_POOL_SIZE):
		sfx_players.append(_create_player("SFXVoice%d" % (index + 1), &"SFX"))

	set_music_state(&"menu", true)
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_hook_existing_buttons")


func _exit_tree() -> void:
	stop_all_audio()
	for player in music_players + ambience_players + sfx_players:
		player.stream = null
	if swoosh_player:
		swoosh_player.stream = null


func set_music_state(next_state: StringName, immediate := false) -> void:
	if not THEME_STREAMS.has(next_state) or music_players.size() < 2:
		return
	if music_state == next_state:
		return

	music_transition_generation += 1
	var generation := music_transition_generation
	var outgoing_index := active_music_player_index
	var incoming_index := 1 - outgoing_index
	var outgoing := music_players[outgoing_index]
	var incoming := music_players[incoming_index]
	if music_tween and music_tween.is_valid():
		music_tween.kill()

	incoming.stop()
	incoming.stream = THEME_STREAMS[next_state]
	_enable_loop(incoming.stream)
	incoming.pitch_scale = 1.0
	incoming.volume_db = MUSIC_VOLUME_DB if immediate or not playback_enabled else SILENT_VOLUME_DB
	active_music_player_index = incoming_index
	music_state = next_state
	music_state_changed.emit(next_state)
	_set_ambience_state(next_state, immediate)

	if not playback_enabled:
		outgoing.stop()
		outgoing.stream = null
		music_transition_completed.emit(next_state)
		return

	incoming.play()
	if immediate or not outgoing.playing:
		outgoing.stop()
		outgoing.stream = null
		incoming.volume_db = MUSIC_VOLUME_DB
		music_transition_completed.emit(next_state)
		return

	music_tween = create_tween().set_parallel(true)
	music_tween.tween_property(incoming, "volume_db", MUSIC_VOLUME_DB, MUSIC_CROSSFADE_DURATION)
	music_tween.tween_property(outgoing, "volume_db", SILENT_VOLUME_DB, MUSIC_CROSSFADE_DURATION)
	music_tween.finished.connect(_finish_music_transition.bind(generation, outgoing_index, next_state))


func play_menu_music() -> void:
	set_music_state(&"menu")


func play_results_music() -> void:
	set_music_state(&"menu")


func set_biome(biome_index: int) -> void:
	var safe_index := clampi(biome_index, 0, BIOME_THEME_KEYS.size() - 1)
	set_music_state(BIOME_THEME_KEYS[safe_index])


func update_ball_roll(speed: float, active: bool) -> void:
	if not swoosh_player:
		return
	var should_play := active and speed >= SWOOSH_START_SPEED
	if not should_play:
		if swoosh_player.playing:
			swoosh_player.stop()
		return

	var speed_ratio := clampf((speed - SWOOSH_START_SPEED) / (SWOOSH_FULL_SPEED - SWOOSH_START_SPEED), 0.0, 1.0)
	swoosh_player.volume_db = lerpf(-25.0, -12.0, sqrt(speed_ratio))
	swoosh_player.pitch_scale = lerpf(0.88, 1.16, speed_ratio)
	if playback_enabled and not swoosh_player.playing:
		swoosh_player.play()


func stop_transient_audio() -> void:
	if swoosh_player:
		swoosh_player.stop()
	for player in sfx_players:
		player.stop()
		player.stream = null


func stop_all_audio() -> void:
	stop_transient_audio()
	if music_tween and music_tween.is_valid():
		music_tween.kill()
	if ambience_tween and ambience_tween.is_valid():
		ambience_tween.kill()
	for player in music_players + ambience_players:
		player.stop()


func play_purchase() -> void:
	_play_sfx(&"purchase", -1.0)


func play_error() -> void:
	_play_sfx(&"error", -4.0)


func play_golf_strike(power: float) -> void:
	var safe_power := clampf(power, 0.0, 1.0)
	_play_sfx(&"golf_strike", lerpf(-5.0, 0.0, safe_power), lerpf(0.94, 1.05, safe_power))


func play_terrain_impact(terrain: StringName = &"terrain") -> void:
	var pitch := 0.82 if terrain == &"sand" else 1.0
	_play_sfx(&"terrain_impact", -3.0, pitch)


func play_water() -> void:
	_play_sfx(&"water", -1.5)


func play_cup_sink() -> void:
	_play_sfx(&"cup_sink", -1.0)


func play_hole_completion() -> void:
	play_hole_outcome(true)


func play_hole_outcome(success: bool, _reason: StringName = &"") -> void:
	if success:
		_play_sfx(&"hole_completion", -2.0)
	else:
		play_failure()


func play_failure() -> void:
	var now := Time.get_ticks_msec()
	if now - last_failure_time_msec < FAILURE_REPEAT_GUARD_MSEC:
		return
	last_failure_time_msec = now
	_play_sfx(&"failure_1", -5.0)
	_play_sfx(&"failure_2", -5.0)


func play_boost_pad(strength: float) -> void:
	var safe_strength := maxf(strength, 0.0)
	if safe_strength < 0.34:
		_play_sfx(&"boost_low", -3.0)
	elif safe_strength < 0.67:
		_play_sfx(&"boost_medium", -2.0)
	else:
		_play_sfx(&"boost_high", -1.0)


func play_hazard_triggered(hazard_type: StringName, intensity := 1.0) -> void:
	var safe_intensity := clampf(intensity, 0.0, 1.0)
	match hazard_type:
		&"water":
			_play_sfx(&"water", lerpf(-6.0, -1.5, safe_intensity))
		&"lava", &"rotating_fire_rod", &"fireball":
			_play_sfx(&"lava", lerpf(-7.0, -2.0, safe_intensity))
		&"ice", &"falling_ice":
			_play_sfx(&"ice_impact", lerpf(-8.0, -2.5, safe_intensity))
		&"bounce_pad", &"boost_pad":
			pass # Dedicated bounce_pad_triggered wiring owns the supplied boost cue.
		&"wall", &"blocker", &"pendulum":
			_play_sfx(&"wall_impact", lerpf(-9.0, -2.5, safe_intensity))
		&"sand":
			_play_sfx(&"terrain_impact", lerpf(-8.0, -2.0, safe_intensity))


func play_biome_transition(biome_index: int) -> void:
	set_biome(biome_index)
	_play_sfx(&"biome_transition", -3.0, lerpf(0.95, 1.05, float(clampi(biome_index, 0, 5)) / 5.0))


func play_final_run_completion() -> void:
	_play_sfx(&"final_run_completion", 0.0)


func play_feedback(cue: StringName, intensity := 1.0) -> void:
	var safe_intensity := clampf(intensity, 0.0, 1.0)
	match cue:
		&"golf_strike":
			play_golf_strike(safe_intensity)
		&"terrain_impact":
			_play_sfx(&"terrain_impact", lerpf(-7.0, -2.0, safe_intensity))
		&"water":
			play_water()
		&"cup_sink":
			play_cup_sink()
		&"hole_completion":
			play_hole_outcome(true)
		&"hole_failure":
			play_hole_outcome(false)
		&"boost_pad":
			play_boost_pad(safe_intensity)
		&"biome_transition":
			_play_sfx(&"biome_transition", -3.0)
		&"final_run_completion":
			play_final_run_completion()


func _set_ambience_state(state: StringName, immediate: bool) -> void:
	if ambience_players.size() < 2:
		return
	ambience_transition_generation += 1
	var generation := ambience_transition_generation
	var outgoing_index := active_ambience_player_index
	var incoming_index := 1 - outgoing_index
	var outgoing := ambience_players[outgoing_index]
	var incoming := ambience_players[incoming_index]
	if ambience_tween and ambience_tween.is_valid():
		ambience_tween.kill()

	active_ambience_player_index = incoming_index
	if not AMBIENCE_STREAMS.has(state):
		incoming.stop()
		incoming.stream = null
		outgoing.stop()
		outgoing.stream = null
		return

	incoming.stop()
	incoming.stream = AMBIENCE_STREAMS[state]
	_enable_loop(incoming.stream)
	incoming.volume_db = AMBIENCE_VOLUME_DB if immediate or not playback_enabled else SILENT_VOLUME_DB
	if not playback_enabled:
		outgoing.stop()
		outgoing.stream = null
		return

	incoming.play()
	if immediate or not outgoing.playing:
		outgoing.stop()
		outgoing.stream = null
		incoming.volume_db = AMBIENCE_VOLUME_DB
		return

	ambience_tween = create_tween().set_parallel(true)
	ambience_tween.tween_property(incoming, "volume_db", AMBIENCE_VOLUME_DB, MUSIC_CROSSFADE_DURATION)
	ambience_tween.tween_property(outgoing, "volume_db", SILENT_VOLUME_DB, MUSIC_CROSSFADE_DURATION)
	ambience_tween.finished.connect(_finish_ambience_transition.bind(generation, outgoing_index))


func _finish_music_transition(generation: int, outgoing_index: int, state: StringName) -> void:
	if generation != music_transition_generation:
		return
	var outgoing := music_players[outgoing_index]
	outgoing.stop()
	outgoing.stream = null
	music_transition_completed.emit(state)


func _finish_ambience_transition(generation: int, outgoing_index: int) -> void:
	if generation != ambience_transition_generation:
		return
	var outgoing := ambience_players[outgoing_index]
	outgoing.stop()
	outgoing.stream = null


func _play_sfx(cue: StringName, volume_db := 0.0, pitch_scale := 1.0) -> void:
	if not SFX_STREAMS.has(cue) or sfx_players.is_empty():
		return
	var now := Time.get_ticks_msec()
	var cooldown := int(CUE_COOLDOWN_MSEC.get(cue, 0))
	if cooldown > 0 and now - int(last_cue_time_msec.get(cue, -cooldown)) < cooldown:
		return
	last_cue_time_msec[cue] = now
	cue_requested.emit(cue)
	if not playback_enabled:
		return
	var player := _available_sfx_player()
	player.stream = SFX_STREAMS[cue]
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func _available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	var player := sfx_players[next_sfx_player]
	next_sfx_player = (next_sfx_player + 1) % sfx_players.size()
	return player


func _create_player(player_name: String, bus_name: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus_name
	add_child(player)
	return player


func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav_stream := stream as AudioStreamWAV
		wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav_stream.loop_begin = 0
		wav_stream.loop_end = roundi(wav_stream.get_length() * float(wav_stream.mix_rate))


func _on_node_added(node: Node) -> void:
	if node is Button:
		call_deferred("_hook_button", node)


func _hook_existing_buttons() -> void:
	_hook_buttons_below(get_tree().root)


func _hook_buttons_below(node: Node) -> void:
	if node is Button:
		_hook_button(node as Button)
	for child in node.get_children():
		_hook_buttons_below(child)


func _hook_button(button: Button) -> void:
	if not is_instance_valid(button) or button.has_meta(&"audio_hooked"):
		return
	button.set_meta(&"audio_hooked", true)
	button.mouse_entered.connect(_on_button_hovered.bind(button))
	button.pressed.connect(_on_button_pressed.bind(button))


func _on_button_hovered(button: Button) -> void:
	var now := Time.get_ticks_msec()
	if now - last_ui_time_msec < UI_REPEAT_GUARD_MSEC:
		return
	last_ui_time_msec = now
	if button.disabled:
		play_error()
	else:
		_play_sfx(&"ui_hover", -8.0)


func _on_button_pressed(button: Button) -> void:
	if bool(button.get_meta(&"suppress_ui_click_audio", false)):
		return
	_play_sfx(&"ui_click", -5.0)
