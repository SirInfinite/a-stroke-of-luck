extends "res://tools/pixel_sample/sample_feedback.gd"
## Existing semantic timing and audio, with crisp replacement sprite clusters.

const Pixel := preload("res://tools/pixel_correction/arcade_assets.gd")

func _stamp(asset: String, at: Vector2, extent: float, duration: float, angle := 0.0) -> Sprite2D:
	if visual_effects_scale <= 0.01 or transient_root.get_child_count() >= 20: return null
	var sprite := Pixel.sprite("props/" + asset, at.round(), Vector2.ONE * extent)
	sprite.rotation = snappedf(angle, PI / 4.0)
	sprite.modulate.a = visual_effects_scale
	transient_root.add_child(sprite)
	# Hold a clear pose, then remove it in one frame; no drifting smoke or glow.
	var tween := sprite.create_tween()
	tween.tween_interval(duration * 0.7)
	tween.tween_callback(func(): sprite.modulate.a *= 0.5)
	tween.tween_interval(duration * 0.3)
	tween.tween_callback(sprite.queue_free)
	return sprite
