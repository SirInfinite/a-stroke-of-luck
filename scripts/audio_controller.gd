class_name GameAudioController
extends Node

signal cue_requested(cue: StringName)
signal music_state_changed(state: StringName)
signal music_transition_completed(state: StringName)

const Catalog := preload("res://scripts/audio_cue_catalog.gd")
const THEME_STREAMS = Catalog.THEME_STREAMS
const BIOME_THEME_KEYS = Catalog.BIOME_THEME_KEYS
const AMBIENCE_STREAMS = Catalog.AMBIENCE_STREAMS
const HIGH_SPEED_SWOOSH_STREAM = Catalog.HIGH_SPEED_SWOOSH_STREAM
const SAND_STREAM = Catalog.SAND_STREAM
const BOOST_STREAMS = Catalog.BOOST_STREAMS
const FAILURE_STREAMS = Catalog.FAILURE_STREAMS
const SFX_STREAMS = Catalog.SFX_STREAMS
const SFX_POOL_SIZE = Catalog.SFX_POOL_SIZE
const MUSIC_CROSSFADE_DURATION = Catalog.MUSIC_CROSSFADE_DURATION
const MUSIC_VOLUME_DB = Catalog.MUSIC_VOLUME_DB
const AMBIENCE_VOLUME_DB = Catalog.AMBIENCE_VOLUME_DB
const SILENT_VOLUME_DB = Catalog.SILENT_VOLUME_DB
const SWOOSH_START_SPEED = Catalog.SWOOSH_START_SPEED
const SWOOSH_FULL_SPEED = Catalog.SWOOSH_FULL_SPEED
const UI_REPEAT_GUARD_MSEC = Catalog.UI_REPEAT_GUARD_MSEC
const CUE_COOLDOWN_MSEC = Catalog.CUE_COOLDOWN_MSEC
const FAILURE_REPEAT_GUARD_MSEC = Catalog.FAILURE_REPEAT_GUARD_MSEC

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
var ui_root: Node
var _hooked_buttons: Array[WeakRef] = []
var movement_target := 0.0
var movement_intensity := 0.0
var music_levels := Vector2.ZERO
var music_trim_db := 0.0
var duck_remaining := 0.0
var gameplay_paused := false
var variation_index := 0


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


func _exit_tree() -> void:
	_unbind_ui()
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
	stop_movement_audio()

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
	music_levels[incoming_index] = 0.0
	active_music_player_index = incoming_index
	music_state = next_state
	music_state_changed.emit(next_state)
	_set_ambience_state(next_state, immediate)

	if not playback_enabled:
		outgoing.stop()
		outgoing.stream = null
		music_levels[outgoing_index] = 0.0
		music_levels[incoming_index] = 1.0
		music_transition_completed.emit(next_state)
		return

	incoming.play()
	if immediate or not outgoing.playing:
		outgoing.stop()
		outgoing.stream = null
		incoming.volume_db = MUSIC_VOLUME_DB
		music_levels[outgoing_index] = 0.0
		music_levels[incoming_index] = 1.0
		music_transition_completed.emit(next_state)
		return

	var target := Vector2.ZERO
	target[incoming_index] = 1.0
	music_tween = create_tween()
	music_tween.tween_property(self, "music_levels", target, MUSIC_CROSSFADE_DURATION).set_trans(Tween.TRANS_SINE)
	music_tween.finished.connect(_finish_music_transition.bind(generation, outgoing_index, next_state))


func play_menu_music() -> void:
	set_music_state(&"menu")


func play_tutorial_music() -> void:
	set_music_state(&"tutorial")


func play_results_music() -> void:
	set_music_state(&"menu")


func set_biome(biome_index: int) -> void:
	var safe_index := clampi(biome_index, 0, BIOME_THEME_KEYS.size() - 1)
	set_music_state(BIOME_THEME_KEYS[safe_index])


func update_ball_roll(speed: float, active: bool) -> void:
	if not active or gameplay_paused:
		stop_movement_audio()
		return
	movement_target = movement_amount(speed)


static func movement_amount(speed: float) -> float:
	if not is_finite(speed):
		return 0.0
	return smoothstep(SWOOSH_START_SPEED, SWOOSH_FULL_SPEED, speed)


func stop_movement_audio() -> void:
	movement_target = 0.0
	movement_intensity = 0.0
	if swoosh_player:
		swoosh_player.stop()
		swoosh_player.volume_db = SILENT_VOLUME_DB


func set_gameplay_paused(paused: bool) -> void:
	gameplay_paused = paused
	if paused:
		stop_movement_audio()


func _process(delta: float) -> void:
	movement_intensity = lerpf(movement_intensity, movement_target, 1.0 - exp(-delta * 9.0))
	if swoosh_player:
		if movement_intensity < 0.001:
			swoosh_player.stop()
			swoosh_player.volume_db = SILENT_VOLUME_DB
		else:
			swoosh_player.volume_db = -16.0 + linear_to_db(movement_intensity)
			swoosh_player.pitch_scale = 1.0
			if playback_enabled and not swoosh_player.playing:
				swoosh_player.play()
	duck_remaining = maxf(0.0, duck_remaining - delta)
	var target_trim := -7.0 if duck_remaining > 0.0 else (-3.0 if gameplay_paused else 0.0)
	music_trim_db = move_toward(music_trim_db, target_trim, delta * (35.0 if target_trim < music_trim_db else 10.0))
	for index in range(music_players.size()):
		music_players[index].volume_db = MUSIC_VOLUME_DB + music_trim_db + linear_to_db(maxf(music_levels[index], 0.001))


func stop_transient_audio() -> void:
	stop_movement_audio()
	duck_remaining = 0.0
	last_cue_time_msec.clear()
	last_failure_time_msec = -FAILURE_REPEAT_GUARD_MSEC
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
		player.stream = null
	music_transition_generation += 1
	ambience_transition_generation += 1
	music_state = &""
	music_levels = Vector2.ZERO
	music_trim_db = 0.0
	gameplay_paused = false


func play_purchase() -> void:
	_play_sfx(&"purchase", -1.0)
	duck_remaining = maxf(duck_remaining, 0.4)


func play_card_acquired(stacked: bool) -> void:
	# One accepted purchase, with an intentionally quieter dark paper accent.
	play_purchase()
	_play_sfx(&"card_stack" if stacked else &"curse", -12.0)


func play_error() -> void:
	_play_sfx(&"error", -4.0)


func play_golf_strike(power: float) -> void:
	var safe_power := clampf(power, 0.0, 1.0)
	_play_sfx(&"golf_strike", lerpf(-5.0, 0.0, safe_power), lerpf(0.99, 1.01, safe_power))


func play_terrain_impact(terrain: StringName = &"terrain") -> void:
	if terrain in [&"sand", &"terrain"]:
		_play_sfx(&"terrain_impact", -3.0)
	else:
		play_hazard_triggered(terrain)


func play_wall_impact(strength: float) -> void:
	_play_sfx(&"wall_impact", lerpf(-20.0, -3.0, clampf(strength, 0.0, 1.0)))


func play_water() -> void:
	_play_sfx(&"water", -1.5)


func play_cup_sink() -> void:
	_play_sfx(&"cup_sink", -1.0)


func play_hole_completion() -> void:
	play_hole_outcome(true)


func play_hole_outcome(success: bool, _reason: StringName = &"") -> void:
	if success:
		_play_sfx(&"hole_completion", -2.0)
		_play_sfx(&"crowd_success", -7.0)
	else:
		play_failure()


func play_failure() -> void:
	var now := Time.get_ticks_msec()
	if now - last_failure_time_msec < FAILURE_REPEAT_GUARD_MSEC:
		return
	last_failure_time_msec = now
	stop_movement_audio()
	duck_remaining = 1.5
	# Failure takes priority over a still-ringing positive outcome.
	for player in sfx_players:
		if player.stream in [SFX_STREAMS[&"cup_sink"], SFX_STREAMS[&"hole_completion"], SFX_STREAMS[&"crowd_success"]]:
			player.stop()
	_play_sfx(&"failure_1", -5.0)
	_play_sfx(&"failure_2", -5.0)
	_play_sfx(&"crowd_failure", -7.0)


func play_boost_pad(strength: float) -> void:
	var safe_strength := maxf(strength, 0.0)
	if safe_strength < Catalog.BOOST_MEDIUM_THRESHOLD:
		_play_sfx(&"boost_low", -3.0)
	elif safe_strength < Catalog.BOOST_HIGH_THRESHOLD:
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
	duck_remaining = 2.2


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
		if immediate or not playback_enabled or not outgoing.playing:
			outgoing.stop()
			outgoing.stream = null
		else:
			ambience_tween = create_tween()
			ambience_tween.tween_property(outgoing, "volume_db", SILENT_VOLUME_DB, MUSIC_CROSSFADE_DURATION)
			ambience_tween.finished.connect(_finish_ambience_transition.bind(generation, outgoing_index))
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
	if cue in [&"cup_sink", &"hole_completion", &"crowd_success"] and now - last_failure_time_msec < FAILURE_REPEAT_GUARD_MSEC:
		return
	cue_requested.emit(cue)
	if not playback_enabled:
		return
	var player := _available_sfx_player()
	player.stream = SFX_STREAMS[cue]
	player.volume_db = Catalog.SFX_VOLUME_DB + volume_db
	player.pitch_scale = pitch_scale
	if cue in [&"golf_strike", &"wall_impact", &"ui_hover"]:
		variation_index += 1
		player.volume_db += [-0.4, 0.0, -0.7, -0.2][variation_index % 4]
		player.pitch_scale *= [1.0, 0.996, 1.004, 1.002][variation_index % 4]
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


func bind_ui(root: Node) -> void:
	# Bind once to this game's UI, never discover buttons in other scenes/tests.
	if ui_root == root:
		return
	_unbind_ui()
	ui_root = root
	if not is_instance_valid(ui_root):
		return
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)
	_hook_buttons_below(ui_root)


func _unbind_ui() -> void:
	for reference in _hooked_buttons:
		var button := reference.get_ref() as Button
		if not is_instance_valid(button):
			continue
		for binding in [[button.mouse_entered, _on_button_hovered.bind(button)], [button.focus_entered, _on_button_hovered.bind(button)], [button.pressed, _on_button_pressed.bind(button)]]:
			var event: Signal = binding[0]
			if event.is_connected(binding[1]):
				event.disconnect(binding[1])
		if int(button.get_meta(&"audio_hooked", 0)) == get_instance_id():
			button.remove_meta(&"audio_hooked")
	_hooked_buttons.clear()
	ui_root = null


func _on_node_added(node: Node) -> void:
	if is_instance_valid(ui_root) and ui_root.is_ancestor_of(node) and node is Button:
		call_deferred("_hook_button", node)


func _hook_buttons_below(node: Node) -> void:
	if node is Button:
		_hook_button(node as Button)
	for child in node.get_children():
		_hook_buttons_below(child)


func _hook_button(button: Button) -> void:
	if not is_instance_valid(button) or int(button.get_meta(&"audio_hooked", 0)) == get_instance_id():
		return
	if not is_instance_valid(ui_root) or not (ui_root == button or ui_root.is_ancestor_of(button)):
		return
	button.set_meta(&"audio_hooked", get_instance_id())
	_hooked_buttons.append(weakref(button))
	button.mouse_entered.connect(_on_button_hovered.bind(button))
	button.focus_entered.connect(_on_button_hovered.bind(button))
	button.pressed.connect(_on_button_pressed.bind(button))


func _on_button_hovered(button: Button) -> void:
	var now := Time.get_ticks_msec()
	if now - last_ui_time_msec < UI_REPEAT_GUARD_MSEC:
		return
	last_ui_time_msec = now
	if not button.disabled and button.is_visible_in_tree():
		_play_sfx(&"ui_hover", -8.0)


func _on_button_pressed(button: Button) -> void:
	if bool(button.get_meta(&"suppress_ui_click_audio", false)):
		return
	var back := String(button.text).contains("BACK") or String(button.name).contains("Close")
	_play_sfx(&"ui_back" if back else &"ui_click", -8.0)
