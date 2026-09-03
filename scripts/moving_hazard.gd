class_name MovingHazard
extends AnimatableBody2D

signal hazard_triggered(hazard_type: StringName, intensity: float, position: Vector2)
signal body_hit(body: Node2D, hazard_type: StringName, position: Vector2)
signal telegraph_started(data: Dictionary)
signal active_state_changed(active: bool)

const MIN_PERIOD := 0.6
const FALL_ARMED := &"armed"
const FALL_DROPPING := &"dropping"
const FALL_LANDED := &"landed"

var hazard_type: StringName = &"pendulum"
var elevation := 0
var intensity := 1.0
var origin := Vector2.ZERO
var period := 2.4
var phase := 0.0
var elapsed := 0.0
var swing_angle := 0.9
var travel_radius := 72.0
var angular_speed := 1.8
var telegraph_duration := 0.7
var active_duration := 0.65
var cooldown_duration := 1.1
var drop_distance := 120.0
var active := true
var detector: Area2D
var collision_shape: CollisionShape2D
var detector_shape: CollisionShape2D
var _last_cycle_index := -1
var fall_state: StringName = FALL_ARMED
var fall_elapsed := 0.0
var visual_node: Node2D
var _fall_crush_pending := false
var _fall_trigger_body_ref: WeakRef


func configure(definition: Dictionary) -> void:
	hazard_type = StringName(String(definition.get("type", "pendulum")))
	elevation = clampi(int(definition.get("elevation", 0)), -1, 1)
	intensity = maxf(float(definition.get("intensity", 1.0)), 0.0)
	origin = Vector2(definition.get("pos", Vector2.ZERO))
	period = maxf(float(definition.get("period", 2.4)), MIN_PERIOD)
	phase = wrapf(float(definition.get("phase", 0.0)), 0.0, 1.0)
	swing_angle = clampf(float(definition.get("swing_angle", 0.9)), 0.15, 1.45)
	travel_radius = maxf(float(definition.get("travel_radius", 72.0)), 0.0)
	angular_speed = float(definition.get("angular_speed", 1.8))
	telegraph_duration = maxf(float(definition.get("telegraph_duration", 0.7)), 0.15)
	active_duration = maxf(float(definition.get("active_duration", 0.65)), 0.15)
	cooldown_duration = maxf(float(definition.get("cooldown_duration", 1.1)), 0.15)
	drop_distance = maxf(float(definition.get("drop_distance", 120.0)), 20.0)
	set_meta(&"collision_kind", &"moving_hazard")
	set_meta(&"hazard_type", hazard_type)
	set_meta(&"elevation", elevation)
	reset_state()


func setup_collision(size: Vector2, circular := false) -> void:
	collision_shape = CollisionShape2D.new()
	if circular:
		var circle := CircleShape2D.new()
		circle.radius = maxf(minf(size.x, size.y) * 0.5, 8.0)
		collision_shape.shape = circle
	else:
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(maxf(size.x, 8.0), maxf(size.y, 8.0))
		collision_shape.shape = rectangle
	add_child(collision_shape)

	detector = Area2D.new()
	detector.name = "HazardDetector"
	detector.collision_layer = 0
	detector.collision_mask = 1
	detector.monitoring = true
	detector.body_entered.connect(_on_detector_body_entered)
	add_child(detector)

	detector_shape = CollisionShape2D.new()
	detector_shape.shape = collision_shape.shape.duplicate()
	detector.add_child(detector_shape)
	_apply_collision_state()


func set_visual_node(node: Node2D) -> void:
	visual_node = node
	_apply_falling_visual_state()


func _ready() -> void:
	collision_layer = _collision_layer_for_elevation(elevation)
	collision_mask = 1
	sync_to_physics = true
	_apply_motion_state(0.0)


func _physics_process(delta: float) -> void:
	advance_cycle(delta)


func advance_cycle(delta: float) -> void:
	if hazard_type == &"falling_ice":
		if fall_state == FALL_DROPPING:
			fall_elapsed += maxf(delta, 0.0)
	else:
		elapsed += maxf(delta, 0.0)
	_apply_motion_state(delta)


func reset_state() -> void:
	elapsed = phase * _cycle_duration()
	_last_cycle_index = -1
	fall_elapsed = 0.0
	fall_state = FALL_ARMED
	_fall_crush_pending = false
	_fall_trigger_body_ref = null
	active = hazard_type != &"falling_ice"
	position = origin
	rotation = 0.0
	_apply_motion_state(0.0)
	_apply_collision_state()
	_apply_falling_visual_state()


func get_telegraph_data() -> Dictionary:
	var path_points := PackedVector2Array()
	match hazard_type:
		&"pendulum":
			path_points = PackedVector2Array([
				origin + Vector2.DOWN.rotated(-swing_angle) * travel_radius,
				origin + Vector2.DOWN * travel_radius,
				origin + Vector2.DOWN.rotated(swing_angle) * travel_radius,
			])
		&"rotating_fire_rod":
			path_points = PackedVector2Array([origin])
		&"falling_ice":
			path_points = PackedVector2Array([origin])
	return {
		"type": hazard_type,
		"position": origin,
		"elevation": elevation,
		"path_points": path_points,
		"period": _cycle_duration(),
		"telegraph_duration": telegraph_duration if hazard_type == &"falling_ice" else 0.0,
		"active_duration": active_duration if hazard_type == &"falling_ice" else _cycle_duration(),
		"dangerous": true,
	}


func _apply_motion_state(_delta: float) -> void:
	match hazard_type:
		&"pendulum":
			var cycle_progress := fposmod(elapsed, period) / period
			var angle := sin(cycle_progress * TAU) * swing_angle
			position = origin + Vector2.DOWN.rotated(angle) * travel_radius
			rotation = angle
			_set_active(true)
		&"rotating_fire_rod":
			position = origin
			rotation = elapsed * angular_speed
			_set_active(true)
		&"falling_ice":
			_update_falling_ice()
		_:
			position = origin
			_set_active(true)


func _update_falling_ice() -> void:
	position = origin
	rotation = 0.0
	if fall_state != FALL_DROPPING:
		_apply_collision_state()
		_apply_falling_visual_state()
		return

	var fall_progress := clampf(fall_elapsed / telegraph_duration, 0.0, 1.0)
	var eased_progress := 1.0 - pow(1.0 - fall_progress, 3.0)
	var local_offset := Vector2(0.0, -drop_distance * (1.0 - eased_progress))
	if collision_shape:
		collision_shape.position = local_offset
	if visual_node:
		visual_node.position = local_offset
		visual_node.visible = true
	if fall_progress >= 1.0:
		_land_falling_ice()


func _set_active(next_active: bool) -> void:
	if active != next_active:
		active = next_active
		active_state_changed.emit(active)
	if collision_shape:
		collision_shape.set_deferred("disabled", not active)
	if detector_shape and hazard_type != &"falling_ice":
		detector_shape.set_deferred("disabled", not active)


func _on_detector_body_entered(body: Node2D) -> void:
	if not _body_matches_elevation(body):
		return
	if hazard_type == &"falling_ice":
		if fall_state == FALL_ARMED:
			_trigger_falling_ice(body)
		return
	if not active:
		return
	body_hit.emit(body, hazard_type, global_position)


func _trigger_falling_ice(trigger_body: Node2D) -> void:
	if fall_state != FALL_ARMED:
		return
	fall_state = FALL_DROPPING
	fall_elapsed = 0.0
	_fall_trigger_body_ref = weakref(trigger_body)
	telegraph_started.emit(get_telegraph_data())
	_apply_collision_state()
	_apply_falling_visual_state()


func _land_falling_ice() -> void:
	if fall_state != FALL_DROPPING:
		return
	fall_state = FALL_LANDED
	fall_elapsed = telegraph_duration
	_fall_crush_pending = true
	_set_active(true)
	_apply_collision_state()
	_apply_falling_visual_state()
	hazard_triggered.emit(hazard_type, intensity, global_position)
	call_deferred("_resolve_falling_ice_crush")


func _resolve_falling_ice_crush() -> void:
	_fall_crush_pending = false
	if fall_state != FALL_LANDED or not detector:
		return
	var hit_body: Node2D
	if _fall_trigger_body_ref:
		var trigger_body := _fall_trigger_body_ref.get_ref() as Node2D
		if trigger_body and _body_matches_elevation(trigger_body) and _body_is_inside_landing_footprint(trigger_body):
			hit_body = trigger_body
	for body in detector.get_overlapping_bodies():
		if hit_body == null and body is Node2D and _body_matches_elevation(body) and _body_is_inside_landing_footprint(body):
			hit_body = body
			break
	if hit_body:
		body_hit.emit(hit_body, hazard_type, global_position)
	_fall_trigger_body_ref = null
	if detector_shape:
		detector_shape.set_deferred("disabled", true)


func _body_is_inside_landing_footprint(body: Node2D) -> bool:
	if not collision_shape or not collision_shape.shape:
		return false
	var local_position := to_local(body.global_position)
	if collision_shape.shape is RectangleShape2D:
		var half_size := (collision_shape.shape as RectangleShape2D).size * 0.5
		return absf(local_position.x) <= half_size.x and absf(local_position.y) <= half_size.y
	if collision_shape.shape is CircleShape2D:
		return local_position.length() <= (collision_shape.shape as CircleShape2D).radius
	return false


func _apply_collision_state() -> void:
	if hazard_type != &"falling_ice":
		if collision_shape:
			collision_shape.set_deferred("disabled", not active)
		if detector_shape:
			detector_shape.set_deferred("disabled", not active)
		return
	var landed := fall_state == FALL_LANDED
	if collision_shape:
		collision_shape.position = Vector2.ZERO if landed else Vector2(0.0, -drop_distance)
		collision_shape.set_deferred("disabled", not landed)
	if detector_shape:
		detector_shape.set_deferred("disabled", fall_state == FALL_LANDED and not _fall_crush_pending)


func _apply_falling_visual_state() -> void:
	if hazard_type != &"falling_ice" or not visual_node:
		return
	match fall_state:
		FALL_ARMED:
			visual_node.visible = false
			visual_node.position = Vector2(0.0, -drop_distance)
		FALL_DROPPING:
			visual_node.visible = true
			visual_node.position = Vector2(0.0, -drop_distance)
		FALL_LANDED:
			visual_node.visible = true
			visual_node.position = Vector2.ZERO


func _body_matches_elevation(body: Node2D) -> bool:
	if "current_elevation" not in body:
		return elevation == 0
	return int(body.current_elevation) == elevation


func _cycle_duration() -> float:
	if hazard_type == &"falling_ice":
		return telegraph_duration
	if hazard_type == &"rotating_fire_rod":
		return TAU / maxf(absf(angular_speed), 0.1)
	return period


static func _collision_layer_for_elevation(value: int) -> int:
	match clampi(value, -1, 1):
		-1:
			return 1 << 4
		0:
			return 1 << 5
		_:
			return 1 << 6
