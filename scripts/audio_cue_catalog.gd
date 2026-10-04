class_name AudioCueCatalog
extends RefCounted
## Asset identity and tuning only. No playback, scene discovery or run state.

const THEME_STREAMS := {
	&"menu": preload("res://assets/audio/theme_menu.wav"),
	&"tutorial": preload("res://assets/audio/theme_tutorial.wav"),
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
	&"purchase": preload("res://assets/audio/purchase_coins.wav"),
	&"crowd_success": preload("res://assets/audio/crowd_success.wav"),
	&"crowd_failure": preload("res://assets/audio/crowd_failure.wav"),
	&"curse": preload("res://assets/audio/curse.wav"),
	&"card_stack": preload("res://assets/audio/card_stack.wav"),
	&"ui_back": preload("res://assets/audio/ui_back.wav"),
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
# Leave room for overlapping physical impacts and the two supplied failure cues.
# Settings remain user gain; this is the authored mix before those bus controls.
const SFX_VOLUME_DB := -8.0
const MUSIC_CROSSFADE_DURATION := 0.8
const MUSIC_VOLUME_DB := -11.0
const AMBIENCE_VOLUME_DB := -24.0
const SILENT_VOLUME_DB := -60.0
const SWOOSH_START_SPEED := 520.0
const SWOOSH_FULL_SPEED := 1100.0
# Builder reports launch speed / maximum speed. The 650 px/s minimum is
# already ~0.45 at the normal 1450 cap, so a 0.34 low cutoff is unreachable.
const BOOST_MEDIUM_THRESHOLD := 0.60
const BOOST_HIGH_THRESHOLD := 0.82
const UI_REPEAT_GUARD_MSEC := 35
const CUE_COOLDOWN_MSEC := {
	&"crowd_success": 900,
	&"crowd_failure": 900,
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
