extends RigidBody2D

const TrajectoryPredictorScript := preload("res://scripts/trajectory_predictor.gd")
const CourseVisualFactory := preload("res://scripts/course_visual_factory.gd")
const TrajectoryRendererScript := preload("res://scripts/trajectory_renderer.gd")
const Motion := preload("res://scripts/ball_motion.gd")
const PowerColors := preload("res://scripts/ui/power_palette.gd")

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
var external_controlled := false
var opponent_ring: Line2D
var keyboard_active := false
var keyboard_direction := Vector2.RIGHT
var keyboard_power := 0.35
var impulse_multiplier := 1.0
var drag_multiplier := 1.0
var trajectory_dot_bonus := 0
var roll_damping_multiplier := 1.0
var base_linear_damp := -1.0
var base_keyboard_power_speed := -1.0
var base_keyboard_turn_speed := -1.0
var trajectory_preview_enabled := true
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
var _previous_physics_position := Vector2.ZERO
var _sink_generation := 0
var _wall_sweep_origin := Vector2.ZERO
var _wall_sweep_elevation := 0
var wall_sweep_corrections := 0
var _wall_step_velocity := Vector2.ZERO
var _reset_pending := false
var _reset_transform := Transform2D.IDENTITY
var _forecast_surfaces: Array[Dictionary] = []
var _forecast_sand_damping := 0.0
var _forecast_sand_entry_scale := 1.0


func _ready() -> void:
	base_linear_damp = linear_damp
	base_keyboard_power_speed = keyboard_power_speed
	base_keyboard_turn_speed = keyboard_turn_speed
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_physical_body_entered)
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
	_previous_physics_position = global_position
	_wall_sweep_origin = global_position


func _create_ball_art() -> void:
	for child in ball_art.get_children():
		child.free()

	# Ball-only art: LevelBuilder owns the single stationary tee beneath it.
	# Match the collider diameter without moving the authoritative body/origin.
	var sprite := Sprite2D.new()
	sprite.name = "BallSprite"
	sprite.texture = preload("res://assets/world/objects/ball.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * get_collision_radius() * 2.0 / sprite.texture.get_width()
	ball_art.add_child(sprite)


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
	if external_controlled or sunk or simulation_paused:
		return

	if event.is_action_pressed("shoot") or event.is_action_pressed("ui_accept"):
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
	var current_physics_position := global_position
	if not simulation_paused and not sunk and not _reset_pending:
		for mover in get_tree().get_nodes_in_group(&"pendulum_contacts"):
			if mover.get_world_2d() == get_world_2d():
				if mover.try_swept_contact(self, _previous_physics_position, current_physics_position):
					break
	if simulation_paused or not shot_in_progress:
		_previous_physics_position = current_physics_position
		return
	_process_bounce_pad_sweep(_previous_physics_position, current_physics_position)
	_previous_physics_position = global_position

	if _is_stopped():
		stopped_frames += 1
	else:
		stopped_frames = 0

	if stopped_frames >= stopped_frames_required:
		_finish_shot()


func _on_physical_body_entered(body: Node) -> void:
	# Native CCD can stop at contact without overlapping the hazard's Area2D.
	# Both paths report through the same latched semantic event.
	if body is MovingHazard and body.hazard_type == &"pendulum":
		body.register_body_contact(self)


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
	_wall_sweep_origin = global_position
	_wall_sweep_elevation = current_elevation
	_wall_step_velocity = linear_velocity + impulse / mass
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


func apply_player_settings(show_trajectory: bool, aim_sensitivity: float) -> void:
	trajectory_preview_enabled = show_trajectory
	var bounded_sensitivity := clampf(aim_sensitivity, 0.5, 2.0)
	if base_keyboard_turn_speed >= 0.0:
		keyboard_turn_speed = base_keyboard_turn_speed * bounded_sensitivity
	if base_keyboard_power_speed >= 0.0:
		keyboard_power_speed = base_keyboard_power_speed * bounded_sensitivity
	if not trajectory_preview_enabled:
		trajectory_prediction_changed.emit({})


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
	cancel_sink_animation()
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
	_reset_transform = global_transform
	_reset_pending = true
	sleeping = false
	_previous_physics_position = global_position
	_wall_sweep_origin = global_position
	_wall_sweep_elevation = new_elevation
	_wall_step_velocity = Vector2.ZERO
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


func redirect_from_bounce_pad(
	outgoing_velocity: Vector2,
	pad_center := Vector2.ZERO,
	exit_distance := 0.0
) -> bool:
	if simulation_paused or sunk or not shot_in_progress or outgoing_velocity.is_zero_approx():
		return false
	if exit_distance > 0.0:
		var exit_target := pad_center + outgoing_velocity.normalized() * exit_distance
		var separation := Motion.sweep(get_rid(), global_transform, exit_target - global_position, 1.0)
		global_position = separation.position
	linear_velocity = outgoing_velocity
	_wall_step_velocity = outgoing_velocity
	angular_velocity = 0.0
	sleeping = false
	stopped_frames = 0
	_previous_physics_position = global_position
	_wall_sweep_origin = global_position
	return true


func get_motion_speed() -> float:
	return linear_velocity.length()


func get_collision_radius() -> float:
	if not collision_shape or not collision_shape.shape is CircleShape2D:
		return BALL_VISUAL_RADIUS
	var circle := collision_shape.shape as CircleShape2D
	return circle.radius * maxf(absf(global_scale.x), absf(global_scale.y))


func is_motion_active() -> bool:
	return shot_in_progress and not sunk and not simulation_paused


func _process_bounce_pad_sweep(segment_start: Vector2, segment_end: Vector2) -> bool:
	if segment_start.is_equal_approx(segment_end):
		return false
	var closest_pad: Node = null
	var closest_fraction := INF
	for candidate in get_tree().get_nodes_in_group(GameplayHazard.BOUNCE_PAD_GROUP):
		var pad := candidate as Node
		if not pad or not pad.has_method("swept_intersection_fraction"):
			continue
		var hit_fraction := float(pad.call(
			"swept_intersection_fraction",
			self,
			segment_start,
			segment_end
		))
		if hit_fraction < 0.0 or hit_fraction >= closest_fraction:
			continue
		closest_fraction = hit_fraction
		closest_pad = pad
	if not closest_pad:
		return false
	return bool(closest_pad.call("try_swept_bounce", self, segment_start, segment_end))


func sink_to(hole_position: Vector2) -> void:
	cancel_sink_animation()
	call_deferred("_apply_sink_to", hole_position, _sink_generation)


func sink_for_reset(hazard_position: Vector2) -> void:
	cancel_sink_animation()
	call_deferred("_apply_hazard_sink", hazard_position, _sink_generation)


func cancel_sink_animation() -> void:
	# Invalidate deferred starts as well as a tween that is already running.
	# Main owns outcome cancellation; the ball owns its animation lifetime.
	_sink_generation += 1
	if _active_transition_tween and _active_transition_tween.is_valid():
		_active_transition_tween.kill()
	_active_transition_tween = null


func _create_gameplay_transition_tween() -> Tween:
	_active_transition_tween = create_tween()
	if simulation_paused:
		_active_transition_tween.pause()
	return _active_transition_tween


func _apply_sink_to(hole_position: Vector2, generation: int) -> void:
	if generation != _sink_generation:
		return
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
	tween.finished.connect(_finish_sink_animation.bind(generation, false), CONNECT_ONE_SHOT)


func _apply_hazard_sink(hazard_position: Vector2, generation: int) -> void:
	if generation != _sink_generation:
		return
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
	tween.finished.connect(_finish_sink_animation.bind(generation, true), CONNECT_ONE_SHOT)


func _finish_sink_animation(generation: int, is_hazard: bool) -> void:
	if generation != _sink_generation:
		return
	_active_transition_tween = null
	visible = false
	if is_hazard:
		hazard_sink_finished.emit()
	else:
		sink_animation_finished.emit()


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
	if external_controlled:
		return
	if can_shoot() and global_position.distance_to(get_global_mouse_position()) <= drag_pick_radius:
		selected = true
		keyboard_active = false


func _handle_keyboard_aim(delta: float) -> void:
	if external_controlled:
		return
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
	var power_color := PowerColors.color_at(power)

	aim_line.global_position = Vector2.ZERO
	aim_line.points = PackedVector2Array([global_position, global_position + power_line])
	aim_line_backing.global_position = Vector2.ZERO
	aim_line_backing.points = aim_line.points
	power_gradient.set_color(0, PowerColors.LOW)
	power_gradient.set_color(1, power_color)
	aim_line.visible = not power_line.is_zero_approx()
	aim_line_backing.visible = aim_line.visible

	_emit_trajectory_prediction(impulse, power)


func _emit_trajectory_prediction(impulse: Vector2, power: float) -> void:
	if impulse.is_zero_approx() or not trajectory_preview_enabled:
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
	_forecast_surfaces.clear()
	for hazard: Dictionary in level.get("hazards", []):
		if hazard.get("type", "") in ["sand", "ice"]:
			_forecast_surfaces.append({"type": hazard.type, "rect": Rect2(hazard.pos - hazard.size * 0.5, hazard.size), "elevation": int(hazard.get("elevation", 0)), "intensity": float(hazard.get("intensity", 0.22))})
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
		linear_damp + (float(ProjectSettings.get_setting("physics/2d/default_linear_damp", 0.1)) if linear_damp_mode == DAMP_MODE_COMBINE else 0.0),
		stopped_speed,
		trajectory_dot_spacing,
		trajectory_min_dot_count,
		_effective_trajectory_dot_count(),
		(Engine.time_scale if external_controlled else 1.0) / float(Engine.physics_ticks_per_second),
		maxf(trajectory_max_prediction_time, 60.0),
		RID(), # Player aid is deliberately straight-only, not a bank solver.
		stopped_frames_required,
		physics_material_override.bounce if physics_material_override else 0.0,
		physics_material_override.friction if physics_material_override else 1.0,
		{"surfaces": _forecast_surfaces, "normal_damp": get_normal_linear_damp(), "sand_damp": _forecast_sand_damping,
		"sand_entry_scale": _forecast_sand_entry_scale, "radius": get_collision_radius(), "elevation": current_elevation,
		"world_damp": float(ProjectSettings.get_setting("physics/2d/default_linear_damp", 0.1)) if linear_damp_mode == DAMP_MODE_COMBINE else 0.0} if not _forecast_surfaces.is_empty() else {}
	)

func configure_prediction_terrain(sand_damping: float, sand_entry_scale: float) -> void:
	_forecast_sand_damping = sand_damping
	_forecast_sand_entry_scale = sand_entry_scale


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


func set_external_control(enabled: bool, accent := Color.WHITE) -> void:
	external_controlled = enabled
	keyboard_active = false
	selected = false
	if not opponent_ring:
		opponent_ring = Line2D.new()
		opponent_ring.name = "OpponentRing"
		opponent_ring.width = 2.5
		for index in 33:
			opponent_ring.add_point(Vector2.RIGHT.rotated(TAU * index / 32.0) * 16.0)
		ball_art.add_child(opponent_ring)
	opponent_ring.default_color = accent
	opponent_ring.visible = enabled


func set_external_aim(direction: Vector2, power: float) -> void:
	if external_controlled and can_shoot():
		keyboard_direction = direction.normalized()
		keyboard_power = clampf(power, 0.0, 1.0)
		keyboard_active = true


func shoot_normalized(direction: Vector2, power: float) -> bool:
	if not can_shoot() or not direction.is_finite() or direction.is_zero_approx() or not is_finite(power) or power <= 0.0:
		return false
	shoot(direction.normalized() * clampf(power, 0.0, 1.0) * _effective_max_impulse())
	return true


func shot_parameters() -> Dictionary:
	return {"max_impulse": _effective_max_impulse(), "mass": mass,
		"normal_damp": get_normal_linear_damp(), "world_damp": float(ProjectSettings.get_setting("physics/2d/default_linear_damp", 0.1)),
		"sand_damp": _forecast_sand_damping, "sand_entry_scale": _forecast_sand_entry_scale,
		"stop_speed": stopped_speed, "stop_frames": stopped_frames_required,
		"radius": get_collision_radius(), "bounce": physics_material_override.bounce if physics_material_override else 0.0,
		"friction": physics_material_override.friction if physics_material_override else 1.0}


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
	if _reset_pending:
		# A reset requested during physics_frame can otherwise be overwritten by
		# the previous body's server transform. Commit it at the physics boundary.
		state.transform = _reset_transform
		state.linear_velocity = _wall_step_velocity if shot_in_progress else Vector2.ZERO
		state.angular_velocity = 0.0
		_reset_pending = false
		_wall_sweep_origin = state.transform.origin
		_wall_sweep_elevation = current_elevation
		_previous_physics_position = state.transform.origin
		return
	if simulation_paused or not shot_in_progress:
		_wall_sweep_origin = state.transform.origin
		_wall_sweep_elevation = current_elevation
		_wall_step_velocity = state.linear_velocity
		return
	# Sweep the completed step. Native contacts can already have discarded the
	# tangential velocity: reconstruct those from the incoming step, not that
	# distorted result. Moving-body contacts remain native.
	if _wall_sweep_elevation == current_elevation:
		var travelled := state.transform.origin - _wall_sweep_origin
		# A deeply penetrated CCD contact can retain a large solver separation bias
		# on the following tick. That is not velocity/travel earned by the shot.
		var plausible_travel := maxf(_wall_step_velocity.length(), state.linear_velocity.length()) * state.step + get_collision_radius()
		var invalid_separation := travelled.length() > plausible_travel
		if invalid_separation:
			travelled = state.linear_velocity * state.step
		for contact_index in range(state.get_contact_count()):
			var collider = state.get_contact_collider_object(contact_index)
			if collider is StaticBody2D and not collider is AnimatableBody2D:
				travelled = _wall_step_velocity * state.step
				break
		if invalid_separation or travelled.length_squared() > 0.001:
			var swept := Motion.sweep(get_rid(), Transform2D(state.transform.get_rotation(), _wall_sweep_origin), travelled / state.step, state.step,
				physics_material_override.bounce if physics_material_override else 0.0,
				physics_material_override.friction if physics_material_override else 1.0)
			if invalid_separation or not swept.contacts.is_empty():
				var corrected := state.transform
				corrected.origin = swept.position
				state.transform = corrected
				state.linear_velocity = swept.velocity
				wall_sweep_corrections += 1
				if not swept.contacts.is_empty():
					_emit_wall_impact(float(swept.contacts[0].speed), swept.contacts[0].position)
	_wall_sweep_origin = state.transform.origin
	_wall_sweep_elevation = current_elevation
	_wall_step_velocity = state.linear_velocity
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


func _emit_wall_impact(speed: float, at: Vector2) -> void:
	var now := Time.get_ticks_msec()
	if speed < wall_impact_min_speed or now - _last_wall_impact_time_msec < wall_impact_cooldown * 1000.0:
		return
	_last_wall_impact_time_msec = now
	wall_impact.emit(clampf(inverse_lerp(wall_impact_min_speed, wall_impact_full_speed, speed), 0.0, 1.0), at)


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
