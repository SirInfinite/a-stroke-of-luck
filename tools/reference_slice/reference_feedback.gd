extends "res://tools/pixel_sample/sample_feedback.gd"
## Four-pose original raster accents, driven only by existing resolved events.

var density := 48
var textures: Dictionary = {}

func _texture(path: String) -> Texture2D:
	if not textures.has(path): textures[path] = load(path)
	return textures[path]

func _stamp(asset: String, at: Vector2, extent: float, duration: float, angle := 0.0) -> Sprite2D:
	if visual_effects_scale <= 0.01 or transient_root.get_child_count() >= 20: return null
	var folder := "res://assets/reference_slice/world/d%d/" % density
	var path := folder + "props/coin.png" if asset == "coin" else folder + "fx/%s_0.png" % asset
	var sprite := Sprite2D.new()
	sprite.texture = _texture(path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = at
	sprite.rotation = angle
	sprite.scale = Vector2.ONE * extent / maxf(sprite.texture.get_width(), sprite.texture.get_height())
	sprite.modulate.a = visual_effects_scale
	transient_root.add_child(sprite)
	var tween := sprite.create_tween()
	if asset == "coin":
		tween.tween_interval(duration * 0.6)
		tween.tween_property(sprite, "modulate:a", 0.0, duration * 0.4)
	else:
		for index in range(1, 4):
			tween.tween_interval(duration / 4.0)
			tween.tween_callback(_advance_frame.bind(sprite, folder + "fx/%s_%d.png" % [asset, index]))
		tween.tween_interval(duration / 4.0)
	tween.tween_callback(sprite.queue_free)
	return sprite

func _advance_frame(sprite: Sprite2D, path: String) -> void:
	if is_instance_valid(sprite): sprite.texture = _texture(path)

func play_terrain_feedback(kind: StringName, at: Vector2) -> void:
	last_feedback_kind = kind
	var puff := _stamp("water" if kind == &"water" else "dust", at, 44.0, 0.24)
	if puff and kind == &"lava": puff.modulate = Color("ff9861")
	feedback_played.emit(kind)

func play_cup_feedback(at: Vector2, final_hole: bool) -> void:
	last_feedback_kind = &"final_cup" if final_hole else &"cup"
	var glint := _stamp("strike", at + Vector2(0, -12), 52.0, 0.22)
	if glint: glint.modulate = Color("fff0a6")
	# Cup emphasis has no decorative coin count. Native resolved results display
	# the actual reward afterwards, independently of this transient animation.
	_play_cup_camera_emphasis(final_hole)
	feedback_played.emit(last_feedback_kind)

func play_hazard_feedback(kind: StringName, intensity: float, at: Vector2) -> void:
	last_feedback_kind = kind
	var material := "water" if kind == &"water" else "dust"
	var puff := _stamp(material, at + Vector2(0, 6), 64.0, 0.28)
	if puff and kind == &"lava": puff.modulate = Color("ff9861")
	if kind != &"water":
		var accent := _stamp("strike", at, 52.0, 0.13)
		if accent: accent.modulate = Color("ffe29a") if kind == &"bounce_pad" else Color("dddfce")
	_play_camera_impulse(Vector2.UP, minf(5.0 * intensity, 5.0), 0.16)
	_fade_trail()
	feedback_played.emit(kind)
