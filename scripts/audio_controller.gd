class_name GameAudioController
extends Node

signal cue_requested(cue: StringName)

const MUSIC_STREAM := preload("res://assets/audio/ambience_loop.wav")
const ROLL_STREAM := preload("res://assets/audio/ball_roll.wav")
const SFX_STREAMS := {
	&"ui_hover": preload("res://assets/audio/ui_hover.wav"),
	&"ui_click": preload("res://assets/audio/ui_click.wav"),
	&"purchase": preload("res://assets/audio/purchase.wav"),
	&"error": preload("res://assets/audio/ui_error.wav"),
	&"golf_strike": preload("res://assets/audio/golf_strike.wav"),
	&"terrain_impact": preload("res://assets/audio/terrain_impact.wav"),
	&"water": preload("res://assets/audio/water.wav"),
	&"cup_sink": preload("res://assets/audio/cup_sink.wav"),
	&"hole_completion": preload("res://assets/audio/hole_completion.wav"),
	&"biome_transition": preload("res://assets/audio/biome_transition.wav"),
	&"final_run_completion": preload("res://assets/audio/final_run_completion.wav"),
}

const SFX_POOL_SIZE := 8
const ROLL_START_SPEED := 24.0
const ROLL_FULL_SPEED := 900.0
const UI_REPEAT_GUARD_MSEC := 35
const BIOME_MUSIC_PITCH := [0.97, 1.0, 0.985, 1.015, 0.95, 1.025]
const CUE_COOLDOWN_MSEC := {
	&"error": 180,
	&"terrain_impact": 120,
	&"water": 350,
	&"cup_sink": 350,
	&"hole_completion": 500,
	&"biome_transition": 500,
	&"final_run_completion": 1200,
}

var music_player: AudioStreamPlayer
var roll_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var next_sfx_player := 0
var last_ui_time_msec := -UI_REPEAT_GUARD_MSEC
var playback_enabled := false
var last_cue_time_msec: Dictionary = {}


func _ready() -> void:
	playback_enabled = DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() != "Dummy"
	music_player = _create_player("MusicBed", &"Music")
	music_player.stream = MUSIC_STREAM
	_enable_loop(MUSIC_STREAM)
	music_player.volume_db = -3.0
	if playback_enabled:
		music_player.play()

	roll_player = _create_player("BallRoll", &"SFX")
	roll_player.stream = ROLL_STREAM
	_enable_loop(ROLL_STREAM)
	roll_player.volume_db = -30.0

	for index in range(SFX_POOL_SIZE):
		sfx_players.append(_create_player("SFXVoice%d" % (index + 1), &"SFX"))

	get_tree().node_added.connect(_on_node_added)
	call_deferred("_hook_existing_buttons")


func _exit_tree() -> void:
	if music_player:
		music_player.stop()
		music_player.stream = null
	if roll_player:
		roll_player.stop()
		roll_player.stream = null
	for player in sfx_players:
		player.stop()
		player.stream = null


func set_biome(biome_index: int) -> void:
	if not music_player:
		return
	var safe_index := clampi(biome_index, 0, BIOME_MUSIC_PITCH.size() - 1)
	music_player.pitch_scale = BIOME_MUSIC_PITCH[safe_index]


func update_ball_roll(speed: float, active: bool) -> void:
	if not roll_player:
		return
	var should_play := active and speed >= ROLL_START_SPEED
	if not should_play:
		if roll_player.playing:
			roll_player.stop()
		return

	var speed_ratio := clampf((speed - ROLL_START_SPEED) / (ROLL_FULL_SPEED - ROLL_START_SPEED), 0.0, 1.0)
	roll_player.volume_db = lerpf(-27.0, -9.0, sqrt(speed_ratio))
	roll_player.pitch_scale = lerpf(0.72, 1.28, speed_ratio)
	if playback_enabled and not roll_player.playing:
		roll_player.play()


func play_purchase() -> void:
	_play_sfx(&"purchase", -1.0)


func play_error() -> void:
	_play_sfx(&"error", -4.0)


func play_golf_strike(power: float) -> void:
	_play_sfx(&"golf_strike", lerpf(-5.0, 0.0, clampf(power, 0.0, 1.0)), lerpf(0.9, 1.08, power))


func play_terrain_impact(terrain: StringName = &"terrain") -> void:
	var pitch := 0.82 if terrain == &"sand" else 1.0
	_play_sfx(&"terrain_impact", -3.0, pitch)


func play_water() -> void:
	_play_sfx(&"water", -1.5)


func play_cup_sink() -> void:
	_play_sfx(&"cup_sink", -1.0)


func play_hole_completion() -> void:
	_play_sfx(&"hole_completion", -2.0)


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
			_play_sfx(&"water", lerpf(-6.0, -1.5, safe_intensity))
		&"cup_sink":
			play_cup_sink()
		&"hole_completion":
			play_hole_completion()
		&"biome_transition":
			_play_sfx(&"biome_transition", -3.0)
		&"final_run_completion":
			play_final_run_completion()


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
