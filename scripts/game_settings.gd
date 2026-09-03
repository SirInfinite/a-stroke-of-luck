class_name GameSettings
extends RefCounted

const SAVE_PATH := "user://settings.cfg"
const DEFAULT_RESOLUTION := Vector2i(1920, 1080)
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

var fullscreen := false
var resolution := DEFAULT_RESOLUTION
var vsync_enabled := true
var screen_shake_intensity := 1.0
var visual_effects_intensity := 1.0
var master_volume := 1.0
var music_volume := 0.72
var sfx_volume := 0.9
var master_muted := false
var music_muted := false
var sfx_muted := false
var shoot_keycode := KEY_SPACE
var reset_keycode := KEY_R
var aim_sensitivity := 1.0
var trajectory_visible := true
var reduced_motion := false


func reset_to_defaults() -> void:
	fullscreen = false
	resolution = DEFAULT_RESOLUTION
	vsync_enabled = true
	screen_shake_intensity = 1.0
	visual_effects_intensity = 1.0
	master_volume = 1.0
	music_volume = 0.72
	sfx_volume = 0.9
	master_muted = false
	music_muted = false
	sfx_muted = false
	shoot_keycode = KEY_SPACE
	reset_keycode = KEY_R
	aim_sensitivity = 1.0
	trajectory_visible = true
	reduced_motion = false


func load_from(path := SAVE_PATH) -> Error:
	var config := ConfigFile.new()
	var error := config.load(path)
	if error != OK:
		_validate()
		return error
	fullscreen = bool(config.get_value("video", "fullscreen", fullscreen))
	resolution = Vector2i(config.get_value("video", "resolution", resolution))
	vsync_enabled = bool(config.get_value("video", "vsync", vsync_enabled))
	screen_shake_intensity = float(config.get_value("video", "screen_shake", screen_shake_intensity))
	visual_effects_intensity = float(config.get_value("video", "visual_effects", visual_effects_intensity))
	master_volume = float(config.get_value("audio", "master_volume", master_volume))
	music_volume = float(config.get_value("audio", "music_volume", music_volume))
	sfx_volume = float(config.get_value("audio", "sfx_volume", sfx_volume))
	master_muted = bool(config.get_value("audio", "master_muted", master_muted))
	music_muted = bool(config.get_value("audio", "music_muted", music_muted))
	sfx_muted = bool(config.get_value("audio", "sfx_muted", sfx_muted))
	shoot_keycode = int(config.get_value("controls", "shoot_keycode", shoot_keycode))
	reset_keycode = int(config.get_value("controls", "reset_keycode", reset_keycode))
	aim_sensitivity = float(config.get_value("controls", "aim_sensitivity", aim_sensitivity))
	trajectory_visible = bool(config.get_value("accessibility", "trajectory_visible", trajectory_visible))
	reduced_motion = bool(config.get_value("accessibility", "reduced_motion", reduced_motion))
	_validate()
	return OK


func save_to(path := SAVE_PATH) -> Error:
	_validate()
	var config := ConfigFile.new()
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "resolution", resolution)
	config.set_value("video", "vsync", vsync_enabled)
	config.set_value("video", "screen_shake", screen_shake_intensity)
	config.set_value("video", "visual_effects", visual_effects_intensity)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "master_muted", master_muted)
	config.set_value("audio", "music_muted", music_muted)
	config.set_value("audio", "sfx_muted", sfx_muted)
	config.set_value("controls", "shoot_keycode", shoot_keycode)
	config.set_value("controls", "reset_keycode", reset_keycode)
	config.set_value("controls", "aim_sensitivity", aim_sensitivity)
	config.set_value("accessibility", "trajectory_visible", trajectory_visible)
	config.set_value("accessibility", "reduced_motion", reduced_motion)
	return config.save(path)


func apply_runtime(include_display := true) -> void:
	_validate()
	if include_display and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		)
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
		)
		if not fullscreen:
			DisplayServer.window_set_size(resolution)
			DisplayServer.window_set_position(
				(DisplayServer.screen_get_size() - resolution) / 2
			)
	_apply_audio_bus(&"Master", master_volume, master_muted)
	_apply_audio_bus(&"Music", music_volume, music_muted)
	_apply_audio_bus(&"SFX", sfx_volume, sfx_muted)
	_apply_key_binding(&"shoot", shoot_keycode)
	_apply_key_binding(&"reset_level", reset_keycode)


func _validate() -> void:
	if not RESOLUTIONS.has(resolution):
		resolution = DEFAULT_RESOLUTION
	screen_shake_intensity = clampf(screen_shake_intensity, 0.0, 1.0)
	visual_effects_intensity = clampf(visual_effects_intensity, 0.0, 1.0)
	master_volume = clampf(master_volume, 0.0, 1.0)
	music_volume = clampf(music_volume, 0.0, 1.0)
	sfx_volume = clampf(sfx_volume, 0.0, 1.0)
	aim_sensitivity = clampf(aim_sensitivity, 0.5, 2.0)
	if shoot_keycode <= 0:
		shoot_keycode = KEY_SPACE
	if reset_keycode <= 0:
		reset_keycode = KEY_R


func _apply_audio_bus(bus_name: StringName, linear_volume: float, muted: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear_volume, 0.0001)))
	AudioServer.set_bus_mute(bus_index, muted)


func _apply_key_binding(action: StringName, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var key_event := InputEventKey.new()
	key_event.keycode = keycode as Key
	InputMap.action_add_event(action, key_event)
