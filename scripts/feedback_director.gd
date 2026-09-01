class_name FeedbackDirector
extends Node2D

signal sound_requested(cue: StringName, intensity: float)
signal feedback_played(kind: StringName)

@export_category("Shot Feedback")
@export_range(0.01, 0.5, 0.01) var strike_flash_duration := 0.16
@export_range(0.0, 20.0, 0.5) var camera_impulse_strength := 7.0
@export_range(0.01, 0.5, 0.01) var camera_impulse_duration := 0.2
@export_range(1.0, 12.0, 0.5) var trail_width := 5.0
@export_range(2.0, 40.0, 1.0) var trail_sample_distance := 12.0
@export_range(4, 40, 1) var trail_max_points := 18
@export_range(0.05, 1.0, 0.01) var trail_fade_duration := 0.28

@export_category("Movement Feedback")
@export_range(10.0, 300.0, 5.0) var rolling_feedback_interval := 70.0
@export_range(0.05, 0.6, 0.01) var rolling_feedback_duration := 0.22
@export_range(0.05, 0.6, 0.01) var stopping_feedback_duration := 0.2
@export_range(4, 24, 1) var stopping_confetti_count := 12

@export_category("Impact Feedback")
@export_range(0.0, 1.0, 0.01) var wall_shake_threshold := 0.16
@export_range(1.0, 1800.0, 10.0) var wall_impact_reference_speed := 700.0
@export_range(0.0, 12.0, 0.25) var wall_shake_max_strength := 6.0
@export_range(0.05, 0.5, 0.01) var wall_shake_duration := 0.18

@export_category("Terrain Feedback")
@export_range(0.05, 1.0, 0.01) var terrain_burst_duration := 0.34
@export_range(0.25, 2.0, 0.05) var terrain_burst_intensity := 0.8

@export_category("Cup Feedback")
@export_range(0.01, 1.0, 0.01) var cup_effect_duration := 0.45
@export_range(0.0, 1.0, 0.01) var completion_pause_duration := 0.14
@export_range(1.0, 1.15, 0.005) var cup_camera_zoom := 1.045

@export_category("Progression Feedback")
@export_range(0.05, 1.5, 0.01) var biome_transition_duration := 0.42
@export_range(0.0, 0.6, 0.01) var biome_transition_intensity := 0.18
@export_range(0.05, 2.0, 0.01) var ending_transition_duration := 0.72
@export_range(0.0, 0.8, 0.01) var ending_transition_intensity := 0.34

const OFF_WHITE := Color("f4f0e6")
const GOLD := Color("e2b84b")
const DANGER := Color("d9534f")

var ball: RigidBody2D
var camera: Camera2D
var transient_root: Node2D
var trail: Line2D
var screen_flash: ColorRect
var active_terrain_palette: Dictionary = {}
var active_background_palette: Dictionary = {}
var active_biome_id: StringName = &"meadow"
var last_feedback_kind: StringName = &""

var _trail_points := PackedVector2Array()
var _last_trail_point := Vector2.ZERO
var _rolling_distance := 0.0
var _camera_tween: Tween
var _trail_tween: Tween
var _screen_tween: Tween
var _ball_tween: Tween
var _base_camera_zoom := Vector2.ONE


func setup(new_ball: RigidBody2D, new_camera: Camera2D, overlay_layer: CanvasLayer) -> void:
	ball = new_ball
	camera = new_camera
	_base_camera_zoom = camera.zoom

	transient_root = Node2D.new()
	transient_root.name = "TransientFeedback"
	add_child(transient_root)

	trail = Line2D.new()
	trail.name = "BallTrail"
	trail.width = trail_width
	trail.default_color = Color(OFF_WHITE, 0.38)
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.visible = false
	add_child(trail)

	screen_flash = ColorRect.new()
	screen_flash.name = "FeedbackScreenFlash"
	screen_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_flash.color = Color(OFF_WHITE, 0.0)
	screen_flash.visible = false
	overlay_layer.add_child(screen_flash)


func configure_level(level: Dictionary) -> void:
	active_terrain_palette = level.get("terrain_palette", {}).duplicate(true)
	active_background_palette = level.get("background_palette", {}).duplicate(true)
	active_biome_id = StringName(level.get("biome_id", &"meadow"))


func reset_feedback() -> void:
	_kill_tweens()
	_clear_transients()
	_clear_trail()
	if camera:
		camera.offset = Vector2.ZERO
		camera.zoom = _base_camera_zoom
	if ball and ball.has_node("BallArt"):
		ball.get_node("BallArt").scale = Vector2.ONE
	if screen_flash:
		screen_flash.visible = false
		screen_flash.color.a = 0.0
	last_feedback_kind = &""


func play_shot_feedback(position: Vector2, direction: Vector2, power: float) -> void:
	var intensity := clampf(power, 0.2, 1.0)
	last_feedback_kind = &"shot"
	_start_trail(position)
	_spawn_ring(position, OFF_WHITE, 12.0, 30.0 + 12.0 * intensity, strike_flash_duration, 4.0)
	_spawn_radial_burst(position, OFF_WHITE, 6, 14.0 + 9.0 * intensity, strike_flash_duration)
	_play_ball_punch(0.86, strike_flash_duration)
	_play_camera_impulse(direction, camera_impulse_strength * intensity, camera_impulse_duration)
	sound_requested.emit(&"golf_strike", intensity)
	feedback_played.emit(last_feedback_kind)


func play_stop_feedback(position: Vector2 = Vector2.ZERO) -> void:
	if not ball or not ball.visible:
		return
	var feedback_position := ball.global_position if position == Vector2.ZERO else position
	last_feedback_kind = &"stop"
	_spawn_confetti(feedback_position, GOLD, stopping_confetti_count, stopping_feedback_duration * 1.8)
	_fade_trail()
	feedback_played.emit(last_feedback_kind)


func play_wall_impact(strength: float, position: Vector2) -> void:
	var normalized_strength := clampf(
		strength if strength <= 1.0 else strength / wall_impact_reference_speed,
		0.0,
		1.0
	)
	if normalized_strength < wall_shake_threshold:
		return
	last_feedback_kind = &"wall_impact"
	_spawn_radial_burst(position, OFF_WHITE, 5, 20.0 + normalized_strength * 18.0, wall_shake_duration)
	_play_camera_shake(normalized_strength)
	feedback_played.emit(last_feedback_kind)


func play_hazard_feedback(hazard_type: StringName, intensity: float, position: Vector2) -> void:
	var bounded_intensity := clampf(intensity, 0.15, 1.0)
	last_feedback_kind = hazard_type
	match hazard_type:
		&"bounce_pad":
			_spawn_ring(position, active_background_palette.get("accent", GOLD), 10.0, 34.0 + bounded_intensity * 18.0, terrain_burst_duration, 4.0)
			_spawn_radial_burst(position, OFF_WHITE, 8, 24.0 + bounded_intensity * 20.0, terrain_burst_duration)
		&"falling_ice":
			_spawn_ice_shards(position, _terrain_feedback_color(&"ice"), 7, terrain_burst_duration)
		&"rotating_lava_rod", &"rotating_fire_rod", &"fireball", &"lava":
			_spawn_radial_burst(position, _terrain_feedback_detail_color(&"lava", DANGER), 10, 32.0 + bounded_intensity * 20.0, terrain_burst_duration)
		_:
			_spawn_puffs(position, DANGER, 6, terrain_burst_duration)
	feedback_played.emit(last_feedback_kind)


func play_terrain_feedback(terrain_kind: StringName, position: Vector2) -> void:
	last_feedback_kind = terrain_kind
	var base_color := _terrain_feedback_color(terrain_kind)
	var detail_color := _terrain_feedback_detail_color(terrain_kind, base_color)
	match terrain_kind:
		&"water":
			_spawn_ring(position, detail_color, 12.0, 46.0 * terrain_burst_intensity, terrain_burst_duration, 4.0)
			_spawn_droplets(position, detail_color, 7, terrain_burst_duration)
			sound_requested.emit(&"water", terrain_burst_intensity)
		&"rough":
			_spawn_tufts(position, detail_color, 6, terrain_burst_duration)
		&"sand":
			_spawn_puffs(position, detail_color, 7, terrain_burst_duration)
		&"direction":
			_spawn_wind_lines(position, detail_color, terrain_burst_duration)
		_:
			_spawn_puffs(position, detail_color, 5, terrain_burst_duration)
	if terrain_kind != &"water":
		sound_requested.emit(&"terrain_impact", terrain_burst_intensity)
	feedback_played.emit(last_feedback_kind)


func play_cup_feedback(position: Vector2, is_final_hole: bool) -> void:
	last_feedback_kind = &"final_cup" if is_final_hole else &"cup"
	var color := GOLD if is_final_hole else OFF_WHITE
	_spawn_ring(position, color, 54.0, 18.0, cup_effect_duration, 5.0)
	_spawn_radial_burst(position, color, 12 if is_final_hole else 8, 54.0 if is_final_hole else 36.0, cup_effect_duration)
	_play_cup_camera_emphasis(is_final_hole)
	if is_final_hole:
		_play_screen_flash(GOLD, biome_transition_intensity + 0.08, cup_effect_duration)
	sound_requested.emit(&"cup_sink", 1.0 if is_final_hole else 0.8)
	feedback_played.emit(last_feedback_kind)


func play_progression_feedback(kind: StringName, color: Color) -> void:
	last_feedback_kind = kind
	match kind:
		&"biome_transition":
			_play_screen_flash(color, biome_transition_intensity, biome_transition_duration)
			sound_requested.emit(&"biome_transition", 0.75)
		&"final_completion":
			_play_screen_flash(GOLD, ending_transition_intensity, biome_transition_duration * 1.25)
			_spawn_radial_burst(camera.global_position if camera else Vector2.ZERO, GOLD, 16, 110.0, cup_effect_duration * 1.4)
			sound_requested.emit(&"final_run_completion", 1.0)
		&"ending_transition":
			_play_screen_flash(color, ending_transition_intensity, ending_transition_duration)
	feedback_played.emit(last_feedback_kind)


func _process(_delta: float) -> void:
	if not ball or not trail or not ball.shot_in_progress:
		return
	var current_position := ball.global_position
	var segment_distance := current_position.distance_to(_last_trail_point)
	if segment_distance < trail_sample_distance:
		return
	_rolling_distance += segment_distance
	_last_trail_point = current_position
	_trail_points.append(current_position)
	while _trail_points.size() > trail_max_points:
		_trail_points.remove_at(0)
	trail.points = _trail_points
	if _rolling_distance >= rolling_feedback_interval:
		_rolling_distance = 0.0
		_spawn_roll_tick(current_position, ball.linear_velocity.normalized())


func _start_trail(position: Vector2) -> void:
	if _trail_tween:
		_trail_tween.kill()
		_trail_tween = null
	_trail_points = PackedVector2Array([position])
	_last_trail_point = position
	_rolling_distance = 0.0
	trail.points = _trail_points
	trail.modulate = Color.WHITE
	trail.visible = true


func _fade_trail() -> void:
	if not trail or not trail.visible:
		return
	if _trail_tween:
		_trail_tween.kill()
	_trail_tween = create_tween()
	_trail_tween.tween_property(trail, "modulate:a", 0.0, trail_fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_trail_tween.tween_callback(_clear_trail)


func _clear_trail() -> void:
	_trail_points = PackedVector2Array()
	if trail:
		trail.points = _trail_points
		trail.modulate = Color.WHITE
		trail.visible = false


func _spawn_roll_tick(position: Vector2, direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	var tick := Line2D.new()
	tick.name = "RollingTick"
	tick.position = position
	tick.width = 2.0
	tick.default_color = Color(OFF_WHITE, 0.3)
	tick.begin_cap_mode = Line2D.LINE_CAP_ROUND
	tick.end_cap_mode = Line2D.LINE_CAP_ROUND
	var side := direction.orthogonal() * 6.0
	tick.points = PackedVector2Array([-side, side])
	transient_root.add_child(tick)
	_fade_and_free(tick, rolling_feedback_duration, Vector2.ONE * 1.35)


func _spawn_ring(position: Vector2, color: Color, start_radius: float, end_radius: float, duration: float, width: float) -> void:
	var ring := Line2D.new()
	ring.name = "FeedbackRing"
	ring.position = position
	ring.width = width
	ring.default_color = Color(color, 0.78)
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	var points := PackedVector2Array()
	for i in range(25):
		var angle := TAU * float(i) / 24.0
		points.append(Vector2(cos(angle), sin(angle)) * start_radius)
	ring.points = points
	transient_root.add_child(ring)
	_fade_and_free(ring, duration, Vector2.ONE * (end_radius / maxf(start_radius, 1.0)))


func _spawn_radial_burst(position: Vector2, color: Color, ray_count: int, radius: float, duration: float) -> void:
	var burst := Node2D.new()
	burst.name = "RadialBurst"
	burst.position = position
	for i in range(ray_count):
		var angle := TAU * float(i) / float(ray_count)
		var direction := Vector2(cos(angle), sin(angle))
		var ray := Line2D.new()
		ray.width = 2.5
		ray.default_color = Color(color, 0.68)
		ray.begin_cap_mode = Line2D.LINE_CAP_ROUND
		ray.end_cap_mode = Line2D.LINE_CAP_ROUND
		ray.points = PackedVector2Array([direction * radius * 0.35, direction * radius])
		burst.add_child(ray)
	transient_root.add_child(burst)
	_fade_and_free(burst, duration, Vector2.ONE * 1.18)


func _spawn_puffs(position: Vector2, color: Color, puff_count: int, duration: float) -> void:
	for i in range(puff_count):
		var angle := TAU * float(i) / float(puff_count)
		var direction := Vector2(cos(angle), sin(angle))
		var puff := Polygon2D.new()
		puff.name = "TerrainPuff"
		puff.position = position + direction * 10.0
		puff.polygon = _circle_polygon(3.5 + float(i % 3), 12)
		puff.color = Color(color, 0.58)
		transient_root.add_child(puff)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(puff, "position", puff.position + direction * (15.0 + float(i % 2) * 5.0), duration)
		tween.tween_property(puff, "modulate:a", 0.0, duration)
		tween.tween_property(puff, "scale", Vector2.ONE * 1.7, duration)
		tween.chain().tween_callback(puff.queue_free)


func _spawn_droplets(position: Vector2, color: Color, drop_count: int, duration: float) -> void:
	for i in range(drop_count):
		var angle := -PI + PI * float(i) / float(maxi(drop_count - 1, 1))
		var direction := Vector2(cos(angle), sin(angle) - 0.25).normalized()
		var drop := Polygon2D.new()
		drop.name = "WaterDroplet"
		drop.position = position
		drop.polygon = _circle_polygon(2.5 + float(i % 2), 10)
		drop.color = Color(color, 0.75)
		transient_root.add_child(drop)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(drop, "position", position + direction * (24.0 + float(i % 3) * 6.0), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(drop, "modulate:a", 0.0, duration)
		tween.chain().tween_callback(drop.queue_free)


func _spawn_confetti(position: Vector2, color: Color, piece_count: int, duration: float) -> void:
	for i in range(piece_count):
		var angle := TAU * float(i) / float(piece_count) + float(i % 3) * 0.11
		var direction := Vector2(cos(angle), sin(angle))
		var piece := Polygon2D.new()
		piece.name = "StopConfetti"
		piece.set_meta(&"feedback_kind", &"stop_confetti")
		piece.position = position
		piece.rotation = angle
		piece.polygon = PackedVector2Array([
			Vector2(-2.5, -4.5), Vector2(2.5, -4.5),
			Vector2(2.5, 4.5), Vector2(-2.5, 4.5),
		])
		piece.color = color.lightened(0.12 * float(i % 3))
		transient_root.add_child(piece)
		var travel := 25.0 + float(i % 4) * 6.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(piece, "position", position + direction * travel, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, "rotation", piece.rotation + PI * (0.8 + float(i % 2) * 0.45), duration)
		tween.tween_property(piece, "modulate:a", 0.0, duration).set_delay(duration * 0.28)
		tween.chain().tween_callback(piece.queue_free)


func _spawn_ice_shards(position: Vector2, color: Color, shard_count: int, duration: float) -> void:
	for i in range(shard_count):
		var angle := TAU * float(i) / float(shard_count)
		var direction := Vector2(cos(angle), sin(angle))
		var shard := Polygon2D.new()
		shard.name = "IceShard"
		shard.position = position
		shard.rotation = angle
		shard.polygon = PackedVector2Array([Vector2(-3.0, 4.0), Vector2.ZERO, Vector2(3.0, 4.0), Vector2(0.0, -7.0)])
		shard.color = Color(color, 0.74)
		transient_root.add_child(shard)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(shard, "position", position + direction * (22.0 + float(i % 3) * 7.0), duration)
		tween.tween_property(shard, "modulate:a", 0.0, duration)
		tween.chain().tween_callback(shard.queue_free)


func _spawn_tufts(position: Vector2, color: Color, tuft_count: int, duration: float) -> void:
	var tufts := Node2D.new()
	tufts.name = "RoughTufts"
	tufts.position = position
	for i in range(tuft_count):
		var x := lerpf(-22.0, 22.0, float(i) / float(maxi(tuft_count - 1, 1)))
		var tuft := Line2D.new()
		tuft.width = 2.2
		tuft.default_color = Color(color, 0.7)
		tuft.points = PackedVector2Array([Vector2(x - 4.0, 8.0), Vector2(x, -9.0 - float(i % 2) * 4.0), Vector2(x + 4.0, 8.0)])
		tufts.add_child(tuft)
	transient_root.add_child(tufts)
	_fade_and_free(tufts, duration, Vector2(1.12, 1.35))


func _spawn_wind_lines(position: Vector2, color: Color, duration: float) -> void:
	var wind := Node2D.new()
	wind.name = "DirectionFeedback"
	wind.position = position
	for i in range(3):
		var line := Line2D.new()
		line.width = 2.0
		line.default_color = Color(color, 0.54)
		line.points = PackedVector2Array([Vector2(-24.0, -10.0 + i * 10.0), Vector2(24.0, -10.0 + i * 10.0)])
		wind.add_child(line)
	transient_root.add_child(wind)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(wind, "position:x", 18.0, duration).as_relative()
	tween.tween_property(wind, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(wind.queue_free)


func _fade_and_free(item: CanvasItem, duration: float, target_scale: Vector2) -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(item, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if item is Node2D:
		tween.tween_property(item, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(item.queue_free)


func _play_ball_punch(target_scale: float, duration: float) -> void:
	if not ball or not ball.has_node("BallArt"):
		return
	if _ball_tween:
		_ball_tween.kill()
	var ball_art := ball.get_node("BallArt") as Node2D
	ball_art.scale = Vector2.ONE
	_ball_tween = create_tween()
	_ball_tween.tween_property(ball_art, "scale", Vector2.ONE * target_scale, duration * 0.32)
	_ball_tween.tween_property(ball_art, "scale", Vector2.ONE, duration * 0.68).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_camera_impulse(direction: Vector2, strength: float, duration: float) -> void:
	if not camera or direction.is_zero_approx():
		return
	if _camera_tween:
		_camera_tween.kill()
	camera.offset = -direction.normalized() * strength
	_camera_tween = create_tween()
	_camera_tween.tween_property(camera, "offset", Vector2.ZERO, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_camera_shake(normalized_strength: float) -> void:
	if not camera:
		return
	if _camera_tween:
		_camera_tween.kill()
	camera.offset = Vector2.ZERO
	var amplitude := clampf(normalized_strength * wall_shake_max_strength, 0.0, wall_shake_max_strength)
	var segment_duration := wall_shake_duration / 4.0
	_camera_tween = create_tween()
	_camera_tween.tween_property(camera, "offset", Vector2(amplitude, -amplitude * 0.45), segment_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(camera, "offset", Vector2(-amplitude * 0.65, amplitude * 0.32), segment_duration)
	_camera_tween.tween_property(camera, "offset", Vector2(amplitude * 0.28, -amplitude * 0.18), segment_duration)
	_camera_tween.tween_property(camera, "offset", Vector2.ZERO, segment_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_cup_camera_emphasis(is_final_hole: bool) -> void:
	if not camera:
		return
	if _camera_tween:
		_camera_tween.kill()
	camera.offset = Vector2.ZERO
	camera.zoom = _base_camera_zoom
	var emphasis := cup_camera_zoom + (0.025 if is_final_hole else 0.0)
	_camera_tween = create_tween()
	_camera_tween.tween_property(camera, "zoom", _base_camera_zoom * emphasis, cup_effect_duration * 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(camera, "zoom", _base_camera_zoom, cup_effect_duration * 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _play_screen_flash(color: Color, intensity: float, duration: float) -> void:
	if not screen_flash:
		return
	if _screen_tween:
		_screen_tween.kill()
	screen_flash.color = Color(color, 0.0)
	screen_flash.visible = true
	_screen_tween = create_tween()
	_screen_tween.tween_property(screen_flash, "color:a", intensity, duration * 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_screen_tween.tween_property(screen_flash, "color:a", 0.0, duration * 0.66).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_screen_tween.tween_callback(func(): screen_flash.visible = false)


func _terrain_feedback_color(terrain_kind: StringName) -> Color:
	return active_terrain_palette.get(String(terrain_kind), {
		"sand": Color("d9bc78"),
		"rough": Color("3f7d44"),
		"water": Color("4fa6d8"),
		"ice": Color("9ed5e4"),
		"lava": Color("d9522f"),
		"direction": Color("79b88b"),
	}.get(String(terrain_kind), OFF_WHITE))


func _terrain_feedback_detail_color(terrain_kind: StringName, fallback: Color) -> Color:
	return active_terrain_palette.get("%s_detail" % String(terrain_kind), fallback.lightened(0.28))


func _clear_transients() -> void:
	if not transient_root:
		return
	for child in transient_root.get_children():
		child.queue_free()


func _kill_tweens() -> void:
	for tween in [_camera_tween, _trail_tween, _screen_tween, _ball_tween]:
		if tween:
			tween.kill()
	_camera_tween = null
	_trail_tween = null
	_screen_tween = null
	_ball_tween = null


func _circle_polygon(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
