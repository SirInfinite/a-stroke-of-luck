class_name GameplayHazard
extends Area2D

signal hazard_body_entered(body: Node2D, hazard: GameplayHazard)
signal hazard_body_exited(body: Node2D, hazard: GameplayHazard)
signal hazard_triggered(hazard_type: StringName, intensity: float, position: Vector2)
signal bounce_pad_triggered(strength: float, pad_type: StringName, position: Vector2)

const BOUNCE_PAD_GROUP := &"bounce_pad_hazard"
const MIN_BOUNCE_SPEED := 650.0
const MAX_BOUNCE_SPEED := 1450.0
const DEFAULT_BOUNCE_SPEED_MULTIPLIER := 1.15
const DEFAULT_RETRIGGER_COOLDOWN := 0.22
const DEFAULT_EXIT_SEPARATION_MARGIN := 2.0

var hazard_type: StringName = &"unknown"
var elevation := 0
var intensity := 1.0
var deterministic_seed := 1
@export_range(650.0, 1450.0, 10.0) var minimum_exit_speed := MIN_BOUNCE_SPEED
@export_range(0.75, 1.35, 0.01) var bounce_speed_multiplier := DEFAULT_BOUNCE_SPEED_MULTIPLIER
@export_range(650.0, 1450.0, 10.0) var maximum_exit_speed := MAX_BOUNCE_SPEED
@export_range(0.05, 1.0, 0.01) var retrigger_cooldown := DEFAULT_RETRIGGER_COOLDOWN
var bounce_radius := 0.0
@export_range(0.5, 8.0, 0.5) var exit_separation_margin := DEFAULT_EXIT_SEPARATION_MARGIN
var direction := Vector2.ZERO
var _trigger_count := 0
var _body_cooldowns: Dictionary = {}
var _inside_bodies: Dictionary = {}


func configure(definition: Dictionary) -> void:
	hazard_type = StringName(String(definition.get("type", "unknown")))
	elevation = clampi(int(definition.get("elevation", 0)), -1, 1)
	intensity = maxf(float(definition.get("intensity", 1.0)), 0.0)
	deterministic_seed = maxi(absi(int(definition.get("seed", 1))), 1)
	maximum_exit_speed = clampf(
		float(definition.get("maximum_exit_speed", MAX_BOUNCE_SPEED)),
		MIN_BOUNCE_SPEED,
		MAX_BOUNCE_SPEED
	)
	minimum_exit_speed = clampf(
		float(definition.get("minimum_exit_speed", MIN_BOUNCE_SPEED)),
		MIN_BOUNCE_SPEED,
		maximum_exit_speed
	)
	bounce_speed_multiplier = clampf(
		float(definition.get("speed_multiplier", DEFAULT_BOUNCE_SPEED_MULTIPLIER)),
		0.75,
		1.35
	)
	retrigger_cooldown = maxf(
		float(definition.get("retrigger_cooldown", DEFAULT_RETRIGGER_COOLDOWN)),
		0.05
	)
	bounce_radius = maxf(minf(
		float(Vector2(definition.get("size", Vector2.ZERO)).x),
		float(Vector2(definition.get("size", Vector2.ZERO)).y)
	) * 0.5, 0.0)
	exit_separation_margin = clampf(
		float(definition.get("exit_separation_margin", DEFAULT_EXIT_SEPARATION_MARGIN)),
		0.5,
		8.0
	)
	direction = Vector2(definition.get("direction", Vector2.ZERO)).normalized()
	set_meta(&"hazard_type", hazard_type)
	set_meta(&"elevation", elevation)
	if not direction.is_zero_approx():
		set_meta(&"direction", direction)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	if hazard_type == &"bounce_pad":
		add_to_group(BOUNCE_PAD_GROUP)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	for body_id in _body_cooldowns.keys():
		var remaining := float(_body_cooldowns[body_id]) - delta
		if remaining <= 0.0:
			_body_cooldowns.erase(body_id)
		else:
			_body_cooldowns[body_id] = remaining


func reset_state() -> void:
	_trigger_count = 0
	_body_cooldowns.clear()
	for body in _inside_bodies.values():
		if is_instance_valid(body) and body.has_method("exit_ice_surface"):
			body.exit_ice_surface(get_instance_id())
	_inside_bodies.clear()


func get_telegraph_data() -> Dictionary:
	return {
		"type": hazard_type,
		"position": global_position,
		"elevation": elevation,
		"dangerous": hazard_type in [&"water", &"lava", &"bounce_pad"],
		"timing": {},
	}


static func deterministic_bounce_velocity(
	incoming_velocity: Vector2,
	seed_value: int,
	trigger_index: int,
	speed_multiplier := DEFAULT_BOUNCE_SPEED_MULTIPLIER,
	minimum_speed := MIN_BOUNCE_SPEED,
	maximum_speed := MAX_BOUNCE_SPEED
) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = maxi(absi(seed_value + (trigger_index + 1) * 104729), 1)
	var outgoing_direction := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
	var bounded_maximum := clampf(maximum_speed, MIN_BOUNCE_SPEED, MAX_BOUNCE_SPEED)
	var bounded_minimum := clampf(minimum_speed, MIN_BOUNCE_SPEED, bounded_maximum)
	var outgoing_speed := clampf(
		incoming_velocity.length() * clampf(speed_multiplier, 0.75, 1.35),
		bounded_minimum,
		bounded_maximum
	)
	return outgoing_direction * outgoing_speed


static func swept_circle_intersection_fraction(
	segment_start: Vector2,
	segment_end: Vector2,
	circle_center: Vector2,
	combined_radius: float
) -> float:
	var radius := maxf(combined_radius, 0.0)
	var from_center := segment_start - circle_center
	var radius_squared := radius * radius
	if from_center.length_squared() <= radius_squared:
		return -1.0

	var motion := segment_end - segment_start
	var motion_squared := motion.length_squared()
	if motion_squared <= 0.000001:
		return -1.0

	var projection := from_center.dot(motion)
	var discriminant := projection * projection - motion_squared * (from_center.length_squared() - radius_squared)
	if discriminant < 0.0:
		return -1.0

	var hit_fraction := (-projection - sqrt(discriminant)) / motion_squared
	if hit_fraction < 0.0 or hit_fraction > 1.0:
		return -1.0
	return hit_fraction


func swept_intersection_fraction(body: Node2D, segment_start: Vector2, segment_end: Vector2) -> float:
	if hazard_type != &"bounce_pad" or not _body_matches_elevation(body):
		return -1.0
	var body_id := body.get_instance_id()
	if _body_cooldowns.has(body_id):
		return -1.0
	if body.has_method("is_motion_active") and not bool(body.call("is_motion_active")):
		return -1.0
	var body_radius := 0.0
	if body.has_method("get_collision_radius"):
		body_radius = maxf(float(body.call("get_collision_radius")), 0.0)
	return swept_circle_intersection_fraction(
		segment_start,
		segment_end,
		global_position,
		bounce_radius + body_radius
	)


func try_swept_bounce(body: Node2D, segment_start: Vector2, segment_end: Vector2) -> bool:
	if swept_intersection_fraction(body, segment_start, segment_end) < 0.0:
		return false
	return _trigger_bounce_pad(body)


func _on_body_entered(body: Node2D) -> void:
	if not _body_matches_elevation(body):
		return

	var body_id := body.get_instance_id()
	_inside_bodies[body_id] = body
	if hazard_type == &"ice" and body.has_method("enter_ice_surface"):
		body.enter_ice_surface(get_instance_id(), clampf(intensity, 0.05, 1.0))

	hazard_body_entered.emit(body, self)
	if hazard_type == &"bounce_pad":
		_trigger_bounce_pad(body)
	else:
		hazard_triggered.emit(hazard_type, intensity, global_position)


func _on_body_exited(body: Node2D) -> void:
	var body_id := body.get_instance_id()
	if not _inside_bodies.has(body_id):
		return
	_inside_bodies.erase(body_id)
	if hazard_type == &"ice" and body.has_method("exit_ice_surface"):
		body.exit_ice_surface(get_instance_id())
	hazard_body_exited.emit(body, self)


func _trigger_bounce_pad(body: Node2D) -> bool:
	var body_id := body.get_instance_id()
	if _body_cooldowns.has(body_id):
		return false
	if not body.has_method("redirect_from_bounce_pad") or not "linear_velocity" in body:
		return false

	var incoming_velocity: Vector2 = body.linear_velocity
	var outgoing_velocity := deterministic_bounce_velocity(
		incoming_velocity,
		deterministic_seed,
		_trigger_count,
		bounce_speed_multiplier,
		minimum_exit_speed,
		maximum_exit_speed
	)
	var body_radius := 0.0
	if body.has_method("get_collision_radius"):
		body_radius = maxf(float(body.call("get_collision_radius")), 0.0)
	var exit_distance := bounce_radius + body_radius + exit_separation_margin
	if not bool(body.call("redirect_from_bounce_pad", outgoing_velocity, global_position, exit_distance)):
		return false

	_trigger_count += 1
	_body_cooldowns[body_id] = retrigger_cooldown

	var strength := clampf(outgoing_velocity.length() / maximum_exit_speed, 0.0, 1.0)
	bounce_pad_triggered.emit(strength, &"random", global_position)
	hazard_triggered.emit(&"bounce_pad", strength, global_position)
	return true


func _body_matches_elevation(body: Node2D) -> bool:
	if "current_elevation" not in body:
		return elevation == 0
	return int(body.current_elevation) == elevation
