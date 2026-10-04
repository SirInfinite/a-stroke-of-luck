extends GameAudioController
## Approval-slice presentation adapter. Native events/settings remain authoritative.
## Two provisional compositions, not an approved eight-track soundtrack.

const CANDIDATES: Array[AudioStream] = [
	preload("res://assets/reference_slice/audio/a_sunlit_circuit.ogg"),
	preload("res://assets/reference_slice/audio/b_amber_canopy.ogg"),
]
const CANDIDATE_LABELS := ["A · Sunlit Circuit", "B · Amber Canopy"]
const MATERIALS := {
	&"golf_strike": preload("res://assets/reference_slice/audio/strike.ogg"),
	&"wall_impact": preload("res://assets/reference_slice/audio/wall.ogg"),
	&"slice_pendulum": preload("res://assets/reference_slice/audio/pendulum.ogg"),
	&"cup_sink": preload("res://assets/reference_slice/audio/cup.ogg"),
	&"hole_completion": preload("res://assets/reference_slice/audio/success.ogg"),
	&"ui_hover": preload("res://assets/reference_slice/audio/hover.ogg"),
	&"ui_click": preload("res://assets/reference_slice/audio/select.ogg"),
	&"ui_back": preload("res://assets/reference_slice/audio/back.ogg"),
}
const AUDITION_MUSIC_OFFSET_DB := 6.0
const CURSE_ACKNOWLEDGEMENT_DELAY := 0.16
const MATERIAL_REPEAT_GUARDS := {&"golf_strike": 35, &"ui_click": 70, &"ui_back": 70, &"slice_pendulum": 120}

var candidate := 0
var purchase_generation := 0


func candidate_label() -> String:
	return CANDIDATE_LABELS[candidate]


func select_candidate(index: int) -> void:
	var next_candidate := clampi(index, 0, CANDIDATES.size() - 1)
	if next_candidate == candidate and music_state != &"":
		return
	candidate = next_candidate
	var next_state := music_state if music_state != &"" else &"menu"
	set_music_state(next_state)


func set_music_state(next_state: StringName, immediate := false) -> void:
	if music_players.size() < 2:
		return
	if not THEME_STREAMS.has(next_state):
		return
	var previous_state := music_state
	var selected_stream := CANDIDATES[candidate]
	if music_state != &"" and music_players[active_music_player_index].stream == selected_stream:
		# The audition continues through title/course/results without restarting its
		# introduction; biome ambience still follows the real native state.
		if previous_state != next_state:
			stop_movement_audio()
			music_state = next_state
			_set_ambience_state(next_state, immediate)
			music_state_changed.emit(next_state)
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
	incoming.stream = selected_stream
	if selected_stream is AudioStreamOggVorbis:
		(selected_stream as AudioStreamOggVorbis).loop = true
	incoming.pitch_scale = 1.0
	incoming.volume_db = SILENT_VOLUME_DB
	music_levels[incoming_index] = 0.0
	active_music_player_index = incoming_index
	music_state = next_state
	if previous_state != next_state:
		_set_ambience_state(next_state, immediate)
	music_state_changed.emit(next_state)
	if not playback_enabled:
		outgoing.stop()
		outgoing.stream = null
		music_levels = Vector2.ZERO
		music_levels[incoming_index] = 1.0
		music_transition_completed.emit(next_state)
		return
	incoming.play()
	if immediate or not outgoing.playing:
		outgoing.stop()
		outgoing.stream = null
		music_levels = Vector2.ZERO
		music_levels[incoming_index] = 1.0
		incoming.volume_db = MUSIC_VOLUME_DB + AUDITION_MUSIC_OFFSET_DB
		music_transition_completed.emit(next_state)
		return
	var target := Vector2.ZERO
	target[incoming_index] = 1.0
	music_tween = create_tween()
	music_tween.tween_property(self, "music_levels", target, MUSIC_CROSSFADE_DURATION).set_trans(Tween.TRANS_SINE)
	music_tween.finished.connect(_finish_music_transition.bind(generation, outgoing_index, next_state))


func _finish_music_transition(generation: int, outgoing_index: int, _state: StringName) -> void:
	if generation != music_transition_generation:
		return
	var outgoing := music_players[outgoing_index]
	outgoing.stop()
	outgoing.stream = null
	# Native context can change while the same audition crossfades. Report the
	# latest context rather than the state that began this cosmetic A/B change.
	music_transition_completed.emit(music_state)


func _process(delta: float) -> void:
	super._process(delta)
	# Authored −19 LUFS files use a −5 dB gameplay target, then native pause/duck
	# trim and the owner's persistent Music/Master bus controls. No bus rewrite.
	for player in music_players:
		player.volume_db += AUDITION_MUSIC_OFFSET_DB


func play_hazard_triggered(kind: StringName, intensity := 1.0) -> void:
	if kind == &"pendulum":
		_play_sfx(&"slice_pendulum", lerpf(-9.0, -2.5, clampf(intensity, 0.0, 1.0)))
	else:
		super.play_hazard_triggered(kind, intensity)


func play_card_acquired(stacked: bool) -> void:
	play_purchase()
	var generation := purchase_generation
	await get_tree().create_timer(CURSE_ACKNOWLEDGEMENT_DELAY).timeout
	if generation == purchase_generation and is_inside_tree():
		_play_sfx(&"card_stack" if stacked else &"curse", -12.0)


func play_failure() -> void:
	# The native controller stops its own positive streams. Include this adapter's
	# two substituted positive streams before preserving both supplied fail layers.
	for player in sfx_players:
		if player.stream in [MATERIALS[&"cup_sink"], MATERIALS[&"hole_completion"]]:
			player.stop()
	super.play_failure()


func stop_transient_audio() -> void:
	purchase_generation += 1
	super.stop_transient_audio()


func _play_sfx(cue: StringName, volume_db := 0.0, pitch_scale := 1.0) -> void:
	if not MATERIALS.has(cue):
		super._play_sfx(cue, volume_db, pitch_scale)
		return
	if sfx_players.is_empty():
		return
	var now := Time.get_ticks_msec()
	var cooldown := int(CUE_COOLDOWN_MSEC.get(cue, MATERIAL_REPEAT_GUARDS.get(cue, 0)))
	if cooldown > 0 and now - int(last_cue_time_msec.get(cue, -cooldown)) < cooldown:
		return
	if cue in [&"cup_sink", &"hole_completion"] and now - last_failure_time_msec < FAILURE_REPEAT_GUARD_MSEC:
		return
	last_cue_time_msec[cue] = now
	cue_requested.emit(cue)
	if not playback_enabled:
		return
	var player := _available_sfx_player()
	player.stream = MATERIALS[cue]
	player.volume_db = Catalog.SFX_VOLUME_DB + volume_db
	player.pitch_scale = pitch_scale
	if cue in [&"golf_strike", &"wall_impact", &"ui_hover"]:
		variation_index += 1
		player.volume_db += [-0.4, 0.0, -0.7, -0.2][variation_index % 4]
		player.pitch_scale *= [1.0, 0.996, 1.004, 1.002][variation_index % 4]
	player.play()
