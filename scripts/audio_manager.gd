class_name AudioManager
extends Node

# Place audio files in res://assets/audio/ with these names, or update SFX_PATHS.
# Suggested formats: .wav for short low-latency effects, .ogg for compressed effects.
const SFX_PATHS := {
	"shot": "res://assets/audio/shot.wav",
	"wall_hit": "res://assets/audio/wall_hit.wav",
	"hole_sink": "res://assets/audio/hole_sink.wav",
	"water_reset": "res://assets/audio/water_reset.wav",
	"card_purchase": "res://assets/audio/card_purchase.wav",
	"shop_open": "res://assets/audio/shop_open.wav",
	"ui_click": "res://assets/audio/ui_click.wav"
}

var sfx_cache: Dictionary = {}


func play_sfx(sfx_name: String) -> void:
	var stream := _get_sfx_stream(sfx_name)
	if not stream:
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func _get_sfx_stream(sfx_name: String) -> AudioStream:
	if sfx_cache.has(sfx_name):
		return sfx_cache[sfx_name]

	if not SFX_PATHS.has(sfx_name):
		push_warning("Unknown sound effect: %s" % sfx_name)
		return null

	var path: String = SFX_PATHS[sfx_name]
	if not ResourceLoader.exists(path):
		push_warning("Missing sound effect file for %s at %s" % [sfx_name, path])
		return null

	var stream := load(path) as AudioStream
	if not stream:
		push_warning("Sound effect file is not an AudioStream: %s" % path)
		return null

	sfx_cache[sfx_name] = stream
	return stream
