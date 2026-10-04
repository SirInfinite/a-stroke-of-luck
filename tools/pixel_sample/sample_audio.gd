extends GameAudioController
## Candidate compositions and physical material accents, approval scene only.

const CANDIDATES := [preload("res://assets/pixel_sample/audio/a_pepper_funk.ogg"), preload("res://assets/pixel_sample/audio/b_rocker_chicks.ogg")]
const MATERIALS := {
	&"golf_strike": preload("res://assets/pixel_sample/audio/strike.ogg"),
	&"wall_impact": preload("res://assets/pixel_sample/audio/wall.ogg"),
	&"sample_stone": preload("res://assets/pixel_sample/audio/stone.ogg")}
var candidate := 0
var purchase_generation := 0

func set_music_state(next_state: StringName, immediate := false) -> void:
	if music_players.size() < 2: return
	# Continue the composition across title/course/results; no repeated intro.
	if music_state != &"" and music_players[active_music_player_index].stream == CANDIDATES[candidate]:
		music_state = next_state
		return
	music_transition_generation += 1
	var outgoing_index := active_music_player_index
	var incoming_index := 1 - outgoing_index
	var incoming := music_players[incoming_index]
	if music_tween: music_tween.kill()
	incoming.stop()
	incoming.stream = CANDIDATES[candidate]
	incoming.pitch_scale = 1.0
	incoming.volume_db = -80.0
	active_music_player_index = incoming_index
	music_state = next_state
	music_state_changed.emit(next_state)
	if playback_enabled: incoming.play()
	var target := Vector2.ZERO
	target[incoming_index] = 1.0
	if immediate or not music_players[outgoing_index].playing:
		music_levels = target
		_finish_music_transition(music_transition_generation, outgoing_index, next_state)
	else:
		music_tween = create_tween()
		music_tween.tween_property(self, "music_levels", target, 0.8).set_trans(Tween.TRANS_SINE)
		music_tween.finished.connect(_finish_music_transition.bind(music_transition_generation, outgoing_index, next_state))

func select_candidate(index: int) -> void:
	candidate = clampi(index, 0, 1)
	if not music_players[active_music_player_index].playing: music_state = &""
	set_music_state(&"sample")

func _process(delta: float) -> void:
	super._process(delta)
	# Sources measured/normalized to -18 LUFS; reference background gain is -4 dB.
	for player in music_players: player.volume_db += 7.0

func play_hazard_triggered(kind: StringName, intensity := 1.0) -> void:
	if kind == &"pendulum": _play_sfx(&"sample_stone", -2.0)
	else: super.play_hazard_triggered(kind, intensity)

func play_card_acquired(stacked: bool) -> void:
	play_purchase()
	var generation := purchase_generation
	await get_tree().create_timer(0.24).timeout
	if generation == purchase_generation:
		_play_sfx(&"card_stack" if stacked else &"curse", -12.0)

func stop_transient_audio() -> void:
	purchase_generation += 1
	super.stop_transient_audio()

func _play_sfx(cue: StringName, volume_db := 0.0, pitch_scale := 1.0) -> void:
	if not MATERIALS.has(cue):
		super._play_sfx(cue, volume_db, pitch_scale)
		return
	var now := Time.get_ticks_msec()
	var cooldown := int(CUE_COOLDOWN_MSEC.get(cue, 80))
	if now - int(last_cue_time_msec.get(cue, -cooldown)) < cooldown: return
	last_cue_time_msec[cue] = now
	cue_requested.emit(cue)
	if not playback_enabled: return
	var player := _available_sfx_player()
	player.stream = MATERIALS[cue]
	player.volume_db = Catalog.SFX_VOLUME_DB + volume_db
	player.pitch_scale = pitch_scale
	player.play()
