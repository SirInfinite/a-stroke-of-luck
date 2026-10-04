extends FeedbackDirector
## Event-specific presentation; simulation and hazard clocks never slow down.

const Art := preload("res://tools/pixel_sample/sample_assets.gd")

func setup(new_ball: RigidBody2D, new_camera: Camera2D, overlay_layer: CanvasLayer) -> void:
	super.setup(new_ball, new_camera, overlay_layer)
	trail.width = 3.0
	trail.default_color = Color("e8dda2", 0.38)
	trail_max_points = 11

func play_shot_feedback(at: Vector2, direction: Vector2, power: float) -> void:
	last_feedback_kind = &"shot"
	_start_trail(at)
	_stamp("strike", at - direction * 12.0, 30.0 + power * 22.0, 0.13, direction.angle())
	_play_camera_impulse(direction, 3.8 * power, 0.13)
	feedback_played.emit(last_feedback_kind)

func play_stop_feedback(at: Vector2 = Vector2.ZERO) -> void:
	if not ball or not ball.visible: return
	last_feedback_kind = &"stop"
	_stamp("dust", ball.global_position if at == Vector2.ZERO else at, 27, 0.19)
	_fade_trail()
	feedback_played.emit(last_feedback_kind)

func play_wall_impact(strength: float, at: Vector2) -> void:
	if strength < wall_shake_threshold: return
	last_feedback_kind = &"wall_impact"
	_stamp("dust", at, 34.0 + strength * 18.0, 0.24)
	_play_camera_impulse(Vector2.UP, minf(strength, 1.0) * 3.0, 0.12)
	feedback_played.emit(last_feedback_kind)

func play_hazard_feedback(kind: StringName, intensity: float, at: Vector2) -> void:
	last_feedback_kind = kind
	var accent := _stamp("strike", at, 62.0, 0.18)
	if accent: accent.modulate = Color("f29068")
	_stamp("dust", at + Vector2(0, 10), 72.0, 0.32)
	_play_camera_impulse(Vector2.UP, 5.0 * intensity, 0.18)
	_fade_trail()
	feedback_played.emit(kind)

func play_terrain_feedback(kind: StringName, at: Vector2) -> void:
	last_feedback_kind = kind
	var puff := _stamp("dust", at, 42.0, 0.28)
	if puff and kind == &"water": puff.modulate = Color("71c4c1")
	feedback_played.emit(kind)

func play_cup_feedback(at: Vector2, final_hole: bool) -> void:
	last_feedback_kind = &"final_cup" if final_hole else &"cup"
	_stamp("strike", at + Vector2(0, -16), 45, 0.17)
	if not reduced_motion and visual_effects_scale > 0.01:
		for index in 3:
			var coin := _stamp("coin", at, 19, 0.55)
			if not coin: continue
			var tween := coin.create_tween()
			tween.tween_property(coin, "position", at + Vector2((index - 1) * 25, -58), 0.33).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_play_cup_camera_emphasis(final_hole)
	feedback_played.emit(last_feedback_kind)

func _spawn_roll_tick(_at: Vector2, _direction: Vector2) -> void:
	pass

func _stamp(asset: String, at: Vector2, extent: float, duration: float, angle := 0.0) -> Sprite2D:
	if visual_effects_scale <= 0.01: return null
	# Hard cap prevents repeated events accumulating during stress/replay tests.
	if transient_root.get_child_count() >= 20: return null
	var sprite := Art.sprite("props/" + asset, at, Vector2.ONE * extent)
	sprite.rotation = angle
	sprite.modulate.a = visual_effects_scale
	transient_root.add_child(sprite)
	var tween := sprite.create_tween()
	tween.tween_interval(duration * 0.3)
	tween.tween_property(sprite, "modulate:a", 0.0, duration * 0.7)
	tween.tween_callback(sprite.queue_free)
	return sprite
