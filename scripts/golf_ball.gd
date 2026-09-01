extends RigidBody2D

const TrajectoryPredictorScript := preload("res://scripts/trajectory_predictor.gd")
const CourseVisualFactory := preload("res://scripts/course_visual_factory.gd")
const TrajectoryRendererScript := preload("res://scripts/trajectory_renderer.gd")

signal shot_finished
signal shot_started(position: Vector2, direction: Vector2, power: float)
signal ball_stopped(position: Vector2)
signal wall_impact(strength: float, position: Vector2)
signal trajectory_prediction_changed(prediction: Dictionary)
signal tee_left(position: Vector2, elevation: int)
signal elevation_changed(previous_elevation: int, elevation: int, position: Vector2)
signal sink_animation_finished
signal hazard_sink_finished

@export var max_impulse := 900.0
@export var max_drag_distance := 180.0
@export var drag_pick_radius := 18.0
@export var trajectory_dot_count := 12
@export var trajectory_dot_spacing := 18.0
@export var trajectory_min_dot_count := 2
@export var trajectory_max_prediction_time := 8.0
@export var stopped_speed := 5.0
@export var stopped_angular_speed := 0.1
@export var stopped_frames_required := 8
@export var keyboard_turn_speed := 3.5
@export var keyboard_power_speed := 0.75
@export_range(0.0, 1.0) var keyboard_starting_power := 0.35
@export var sink_animation_duration := 0.35
@export_range(0.01, 1.0, 0.01) var ice_damping_scale := 0.22
@export var wall_impact_min_speed := 90.0
@export var wall_impact_full_speed := 900.0
@export var wall_impact_cooldown := 0.12

@onready var aim_line: Line2D = $AimLine
@onready var aim_line_backing: Line2D = $AimLineBacking
@onready var trajectory_renderer: Node2D = $TrajectoryRenderer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ball_art: Node2D = $BallArt

const POWER_LOW_COLOR := Color("f4f0e6", 0.94)
const POWER_HIGH_COLOR := Color("f06b4f", 0.98)
const BALL_OUTLINE_COLOR := Color("252a2c")
const BALL_VISUAL_RADIUS := 12.4
const BALL_OUTLINE_RADIUS := 13.5
const DIMPLE_RADIUS := 0.9
const DIMPLE_GRID_SPACING := 3.05
const ELEVATION_Z_STRIDE := 8
const ELEVATION_Z_OFFSET := 1
const BALL_Z_OFFSET := 3

var selected := false
var sunk := false
var power_gradient: Gradient
var shot_in_progress := false
var stopped_frames := 0
var keyboard_active := false
var keyboard_direction := Vector2.RIGHT
var keyboard_power := 0.35
var impulse_multiplier := 1.0
var drag_multiplier := 1.0
var trajectory_dot_bonus := 0
var roll_damping_multiplier := 1.0
var base_linear_damp := -1.0
var base_keyboard_power_speed := -1.0
var input_enabled := true
var simulation_paused := false
var current_elevation := 0
var on_tee := true
var _paused_linear_velocity := Vector2.ZERO
var _paused_angular_velocity := 0.0
var _paused_sleeping := false
var _paused_was_frozen := false
var _paused_process_mode := Node.PROCESS_MODE_INHERIT
var _active_transition_tween: Tween
var _active_ice_sources: Dictionary = {}
var _last_wall_impact_time_msec := -1000000
var _trajectory_primary_color := POWER_LOW_COLOR
var _trajectory_backing_color := Color(0.145, 0.165, 0.173, 0.58)


func _ready() -> void:
	base_linear_damp = linear_damp
	base_keyboard_power_speed = keyboard_power_speed
	contact_monitor = true
	max_contacts_reported = 8
	_update_elevation_collision_mask()
	_create_ball_art()
	keyboard_power = keyboard_starting_power
	power_gradient = Gradient.new()
	power_gradient.set_color(0, POWER_LOW_COLOR)
	power_gradient.set_color(1, POWER_LOW_COLOR)
	aim_line.gradient = power_gradient
	aim_line.set_as_top_level(true)
	aim_line_backing.set_as_top_level(true)
	trajectory_prediction_changed.connect(trajectory_renderer.set_prediction_data)


func _create_ball_art() -> void:
	for child in ball_art.get_children():
		child.free()

	_add_ball_circle(BALL_OUTLINE_RADIUS + 1.4, Color(0.02, 0.025, 0.03, 0.36), Vector2(3.0, 4.0))
	_add_ball_circle(BALL_OUTLINE_RADIUS, BALL_OUTLINE_COLOR)
	_add_ball_circle(BALL_VISUAL_RADIUS, Color("eef1f2"))
	_add_ball_circle(11.2, Color(0.52, 0.58, 0.62, 0.16), Vector2(1.8, 2.1))
	_add_ball_circle(8.8, Color(1.0, 1.0, 1.0, 0.28), Vector2(-2.6, -2.8))
	_add_ball_circle(4.6, Color(1.0, 1.0, 1.0, 0.25), Vector2(-4.5, -4.2))
	_add_honeycomb_dimples()


func _add_ball_circle(radius: float, color: Color, offset := Vector2.ZERO) -> void:
	var circle := Polygon2D.new()
	circle.position = offset
	circle.polygon = _circle_polygon(radius, 48)
	circle.color = color
	ball_art.add_child(circle)


func _add_honeycomb_dimples() -> void:
	var row_spacing := DIMPLE_GRID_SPACING * sqrt(3.0) * 0.5
	var row_index := 0
	var y := -BALL_VISUAL_RADIUS + DIMPLE_GRID_SPACING

	while y <= BALL_VISUAL_RADIUS - DIMPLE_GRID_SPACING:
		var x_offset := 0.0 if row_index % 2 == 0 else DIMPLE_GRID_SPACING * 0.5
		var x := -BALL_VISUAL_RADIUS + DIMPLE_GRID_SPACING + x_offset

		while x <= BALL_VISUAL_RADIUS - DIMPLE_GRID_SPACING:
			var dimple_position := Vector2(x, y)
			if dimple_position.length() <= BALL_VISUAL_RADIUS - DIMPLE_RADIUS - 0.35:
				_add_dimple(dimple_position)
			x += DIMPLE_GRID_SPACING

		y += row_spacing
		row_index += 1


func _add_dimple(dimple_position: Vector2) -> void:
	var dimple := Polygon2D.new()
	dimple.position = dimple_position
	dimple.polygon = _rounded_hex_polygon(DIMPLE_RADIUS)
	dimple.color = Color(0.48, 0.53, 0.57, 0.72)
	ball_art.add_child(dimple)


func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("left_mb"):
		_select_if_mouse_is_on_ball()


func _input(event: InputEvent) -> void:
	if sunk or simulation_paused:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if keyboard_active:
				shoot(_keyboard_shot_impulse())
				_hide_previews()

	if event.is_action_pressed("left_mb"):
		_select_if_mouse_is_on_ball()

	if event.is_action_released("left_mb"):
		if selected:
			shoot(_shot_impulse())

		selected = false
		_hide_previews()


func _process(delta: float) -> void:
	if simulation_paused:
		_hide_previews()
		return
	_handle_keyboard_aim(delta)
	_update_previews()


func _physics_process(_delta: float) -> void:
	if simulation_paused or not shot_in_progress:
		return

	if _is_stopped():
		stopped_frames += 1
	else:
		stopped_frames = 0

	if stopped_frames >= stopped_frames_required:
		_finish_shot()


func shoot(impulse: Vector2) -> void:
	if impulse.is_zero_approx() or not can_shoot():
		return

	shot_in_progress = true
	stopped_frames = 0
	sleeping = false
	if on_tee:
		on_tee = false
		tee_left.emit(global_position, current_elevation)
	shot_started.emit(
		global_position,
		impulse.normalized(),
		clampf(impulse.length() / maxf(_effective_max_impulse(), 1.0), 0.0, 1.0)
	)
	apply_central_impulse(impulse)


func apply_card_modifiers(
	new_impulse_multiplier: float,
	new_drag_multiplier: float,
	new_trajectory_dot_bonus: int,
	new_roll_damping_multiplier := 1.0
) -> void:
	impulse_multiplier = maxf(new_impulse_multiplier, 0.2)
	drag_multiplier = maxf(new_drag_multiplier, 0.35)
	trajectory_dot_bonus = maxi(new_trajectory_dot_bonus, -trajectory_dot_count + 2)
	roll_damping_multiplier = maxf(new_roll_damping_multiplier, 0.35)
	_refresh_surface_damping()


func get_normal_linear_damp() -> float:
	var normal_damp := linear_damp if base_linear_damp < 0.0 else base_linear_damp
	return normal_damp * roll_damping_multiplier


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not input_enabled:
		selected = false
		keyboard_active = false
		_hide_previews()


func set_gameplay_simulation_paused(paused: bool) -> void:
	if simulation_paused == paused:
		return

	if paused:
		_paused_linear_velocity = linear_velocity
		_paused_angular_velocity = angular_velocity
		_paused_sleeping = sleeping
		_paused_was_frozen = freeze
		_paused_process_mode = process_mode
		simulation_paused = true
		if _active_transition_tween and _active_transition_tween.is_valid():
			_active_transition_tween.pause()
		selected = false
		keyboard_active = false
		freeze = true
		process_mode = Node.PROCESS_MODE_DISABLED
		_hide_previews()
		return

	simulation_paused = false
	process_mode = _paused_process_mode
	if _active_transition_tween and _active_transition_tween.is_valid():
		_active_transition_tween.play()
	if sunk:
		return
	freeze = _paused_was_frozen
	if not freeze:
		linear_velocity = _paused_linear_velocity
		angular_velocity = _paused_angular_velocity
		sleeping = _paused_sleeping


func reset_to(new_position: Vector2, new_elevation := 0, place_on_tee := true) -> void:
	selected = false
	sunk = false
	shot_in_progress = false
	stopped_frames = 0
	keyboard_active = false
	freeze = simulation_paused
	visible = true
	scale = Vector2.ONE
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	position = new_position
	on_tee = place_on_tee
	set_current_elevation(new_elevation)
	_active_ice_sources.clear()
	_refresh_surface_damping()
	collision_shape.set_deferred("disabled", false)
	_hide_previews()
	_paused_linear_velocity = Vector2.ZERO
	_paused_angular_velocity = 0.0
	_paused_sleeping = true
	_paused_was_frozen = false


func set_current_elevation(new_elevation: int) -> void:
	var bounded_elevation := clampi(new_elevation, -1, 1)
	if current_elevation == bounded_elevation:
		_update_elevation_collision_mask()
		return
	var previous_elevation := current_elevation
	current_elevation = bounded_elevation
	_update_elevation_collision_mask()
	elevation_changed.emit(previous_elevation, current_elevation, global_position)


func enter_ice_surface(source_id: int, damping_scale := 0.22) -> void:
	_active_ice_sources[source_id] = clampf(damping_scale, 0.01, 1.0)
	_refresh_surface_damping()


func exit_ice_surface(source_id: int) -> void:
	_active_ice_sources.erase(source_id)
	_refresh_surface_damping()


func is_on_ice() -> bool:
	return not _active_ice_sources.is_empty()


func redirect_from_bounce_pad(outgoing_velocity: Vector2) -> bool:
	if simulation_paused or sunk or not shot_in_progress or outgoing_velocity.is_zero_approx():
		return false
	linear_velocity = outgoing_velocity
	angular_velocity = 0.0
	sleeping = false
	stopped_frames = 0
	return true


func get_motion_speed() -> float:
	return linear_velocity.length()


func is_motion_active() -> bool:
	return shot_in_progress and not sunk and not simulation_paused


func sink_to(hole_position: Vector2) -> void:
	call_deferred("_apply_sink_to", hole_position)


func sink_for_reset(hazard_position: Vector2) -> void:
	call_deferred("_apply_hazard_sink", hazard_position)


func _create_gameplay_transition_tween() -> Tween:
	_active_transition_tween = create_tween()
	if simulation_paused:
		_active_transition_tween.pause()
	return _active_transition_tween


func _apply_sink_to(hole_position: Vector2) -> void:
	if shot_in_progress:
		_finish_shot(false)

	selected = false
	sunk = true
	on_tee = false
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	collision_shape.set_deferred("disabled", true)
	_hide_previews()

	var tween := _create_gameplay_transition_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", hole_position, sink_animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ZERO, sink_animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	if _active_transition_tween == tween:
		_active_transition_tween = null

	visible = false
	sink_animation_finished.emit()


func _apply_hazard_sink(hazard_position: Vector2) -> void:
	if shot_in_progress:
		_finish_shot(false)

	selected = false
	sunk = true
	on_tee = false
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	collision_shape.set_deferred("disabled", true)
	_hide_previews()

	var tween := _create_gameplay_transition_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", hazard_position, sink_animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ZERO, sink_animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	if _active_transition_tween == tween:
		_active_transition_tween = null

	visible = false
	hazard_sink_finished.emit()


func can_shoot() -> bool:
	return input_enabled and not simulation_paused and not sunk and not shot_in_progress and _is_stopped()


func get_aim_power() -> float:
	if selected:
		return clampf(_shot_impulse().length() / _effective_max_impulse(), 0.0, 1.0)
	if keyboard_active and can_shoot():
		return keyboard_power
	return 0.0


func get_aim_direction_degrees() -> float:
	var aim_direction := Vector2.ZERO
	if selected:
		aim_direction = _shot_impulse().normalized()
	elif keyboard_active and can_shoot():
		aim_direction = keyboard_direction

	if aim_direction.is_zero_approx():
		return 0.0

	return wrapf(rad_to_deg(aim_direction.angle()), 0.0, 360.0)


func has_active_aim() -> bool:
	return selected or (keyboard_active and can_shoot())


func _shot_impulse() -> Vector2:
	var drag := global_position - get_global_mouse_position()
	var drag_power := drag.limit_length(_effective_max_drag_distance()) / _effective_max_drag_distance()
	return drag_power * _effective_max_impulse()


func _keyboard_shot_impulse() -> Vector2:
	return keyboard_direction * keyboard_power * _effective_max_impulse()


func _drag_vector() -> Vector2:
	return (get_global_mouse_position() - global_position).limit_length(_effective_max_drag_distance())


func _select_if_mouse_is_on_ball() -> void:
	if can_shoot() and global_position.distance_to(get_global_mouse_position()) <= drag_pick_radius:
		selected = true
		keyboard_active = false


func _handle_keyboard_aim(delta: float) -> void:
	if selected or not can_shoot():
		return

	var turn_input := Input.get_axis("ui_left", "ui_right")
	var power_input := Input.get_axis("ui_down", "ui_up")

	if not is_zero_approx(turn_input):
		keyboard_direction = keyboard_direction.rotated(turn_input * keyboard_turn_speed * delta).normalized()
		keyboard_active = true

	if not is_zero_approx(power_input):
		var power_speed := keyboard_power_speed if base_keyboard_power_speed < 0.0 else base_keyboard_power_speed
		keyboard_power = clampf(keyboard_power + power_input * power_speed / drag_multiplier * delta, 0.0, 1.0)
		keyboard_active = true


func _update_previews() -> void:
	if selected:
		_update_shot_previews(_drag_vector(), _shot_impulse())
	elif keyboard_active and can_shoot():
		_update_shot_previews(-keyboard_direction * keyboard_power * _effective_max_drag_distance(), _keyboard_shot_impulse())
	else:
		_hide_previews()


func _update_shot_previews(power_line: Vector2, impulse: Vector2) -> void:
	var power: float = clampf(impulse.length() / _effective_max_impulse(), 0.0, 1.0)
	var power_color := _trajectory_primary_color.lerp(POWER_HIGH_COLOR, power)

	aim_line.global_position = Vector2.ZERO
	aim_line.points = PackedVector2Array([global_position, global_position + power_line])
	aim_line_backing.global_position = Vector2.ZERO
	aim_line_backing.points = aim_line.points
	power_gradient.set_color(0, _trajectory_primary_color)
	power_gradient.set_color(1, power_color)
	aim_line.visible = not power_line.is_zero_approx()
	aim_line_backing.visible = aim_line.visible

	_emit_trajectory_prediction(impulse, power)


func _emit_trajectory_prediction(impulse: Vector2, power: float) -> void:
	if impulse.is_zero_approx():
		trajectory_prediction_changed.emit({})
		return

	var prediction := get_trajectory_prediction(impulse)
	var prediction_points: PackedVector2Array = prediction.points
	prediction["power"] = power
	if prediction_points.is_empty():
		trajectory_prediction_changed.emit(prediction)
		return
	trajectory_prediction_changed.emit(prediction)


func _hide_previews() -> void:
	aim_line.visible = false
	aim_line_backing.visible = false
	trajectory_prediction_changed.emit({})


func configure_level(level: Dictionary) -> void:
	var trajectory_style := CourseVisualFactory.trajectory_style(
		level.get("terrain_palette", {}),
		level.get("background_palette", {})
	)
	var primary: Color = trajectory_style.primary
	var backing: Color = trajectory_style.backing
	_trajectory_primary_color = primary
	_trajectory_backing_color = backing
	power_gradient.set_color(0, primary)
	power_gradient.set_color(1, primary)
	aim_line.default_color = primary
	aim_line_backing.default_color = _trajectory_backing_color
	trajectory_renderer.configure_level(level)


func get_trajectory_prediction(impulse: Vector2) -> Dictionary:
	return TrajectoryPredictorScript.predict(
		global_position,
		impulse,
		mass,
		linear_damp,
		stopped_speed,
		trajectory_dot_spacing,
		trajectory_min_dot_count,
		_effective_trajectory_dot_count(),
		1.0 / float(Engine.physics_ticks_per_second),
		trajectory_max_prediction_time
	)


func get_trajectory_prediction_for_power(direction: Vector2, power: float) -> Dictionary:
	if direction.is_zero_approx():
		return TrajectoryPredictorScript.predict(
			global_position,
			Vector2.ZERO,
			mass,
			linear_damp,
			stopped_speed
		)
	return get_trajectory_prediction(
		direction.normalized() * clampf(power, 0.0, 1.0) * _effective_max_impulse()
	)


func _is_stopped() -> bool:
	return linear_velocity.length() <= stopped_speed and absf(angular_velocity) <= stopped_angular_speed


func _effective_max_impulse() -> float:
	return max_impulse * impulse_multiplier


func _effective_max_drag_distance() -> float:
	return max_drag_distance * drag_multiplier


func _effective_trajectory_dot_count() -> int:
	return maxi(2, trajectory_dot_count + trajectory_dot_bonus)


func _finish_shot(emit_stopped_event := true) -> void:
	shot_in_progress = false
	stopped_frames = 0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = true
	shot_finished.emit()
	if emit_stopped_event:
		ball_stopped.emit(global_position)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if simulation_paused or not shot_in_progress:
		return
	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_wall_impact_time_msec < roundi(wall_impact_cooldown * 1000.0):
		return

	for contact_index in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(contact_index)
		if collider == null or not collider.has_meta(&"collision_kind"):
			continue
		var collision_kind := StringName(collider.get_meta(&"collision_kind"))
		if collision_kind not in [&"boundary", &"blocker"]:
			continue

		var local_normal := state.get_contact_local_normal(contact_index)
		var collider_velocity := state.get_contact_collider_velocity_at_position(contact_index)
		var relative_velocity := state.linear_velocity - collider_velocity
		var impact_speed := absf(relative_velocity.dot(local_normal))
		if impact_speed < wall_impact_min_speed:
			continue

		var strength := clampf(
			inverse_lerp(wall_impact_min_speed, maxf(wall_impact_full_speed, wall_impact_min_speed + 1.0), impact_speed),
			0.0,
			1.0
		)
		var impact_position := to_global(state.get_contact_local_position(contact_index))
		_last_wall_impact_time_msec = now_msec
		wall_impact.emit(strength, impact_position)
		break


func _refresh_surface_damping() -> void:
	var damping := get_normal_linear_damp()
	if not _active_ice_sources.is_empty():
		var active_scale := 1.0
		for source_scale in _active_ice_sources.values():
			active_scale = minf(active_scale, float(source_scale))
		damping *= active_scale
	linear_damp = maxf(damping, 0.01)


func _update_elevation_collision_mask() -> void:
	z_index = (current_elevation + ELEVATION_Z_OFFSET) * ELEVATION_Z_STRIDE + BALL_Z_OFFSET
	match current_elevation:
		-1:
			collision_mask = 1 << 4
		0:
			collision_mask = 1 << 5
		_:
			collision_mask = 1 << 6


func _circle_polygon(radius: float, segments := 12) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _rounded_hex_polygon(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var corner_radius := radius * 0.22
	var vertices: Array[Vector2] = []
	for i in range(6):
		var angle := TAU * float(i) / 6.0 + PI / 6.0
		vertices.append(Vector2(cos(angle), sin(angle)) * radius)

	for i in range(6):
		var previous: Vector2 = vertices[(i + 5) % 6]
		var current: Vector2 = vertices[i]
		var next: Vector2 = vertices[(i + 1) % 6]
		var toward_previous := (previous - current).normalized()
		var toward_next := (next - current).normalized()
		points.append(current + toward_previous * corner_radius)
		points.append(current + (toward_previous + toward_next).normalized() * corner_radius * 0.45)
		points.append(current + toward_next * corner_radius)

	return points
