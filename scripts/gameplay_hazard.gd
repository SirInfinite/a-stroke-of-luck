class_name GameplayHazard
extends Area2D

signal hazard_body_entered(body: Node2D, hazard: GameplayHazard)
signal hazard_body_exited(body: Node2D, hazard: GameplayHazard)
signal hazard_triggered(hazard_type: StringName, intensity: float, position: Vector2)
signal bounce_pad_triggered(strength: float, pad_type: StringName, position: Vector2)

const MIN_BOUNCE_SPEED := 170.0
const MAX_BOUNCE_SPEED := 1450.0
const DEFAULT_BOUNCE_RETENTION := 0.76
const DEFAULT_RETRIGGER_COOLDOWN := 0.22

var hazard_type: StringName = &"unknown"
var elevation := 0
var intensity := 1.0
var deterministic_seed := 1
var bounce_retention := DEFAULT_BOUNCE_RETENTION
var retrigger_cooldown := DEFAULT_RETRIGGER_COOLDOWN
var direction := Vector2.ZERO
var _trigger_count := 0
var _body_cooldowns: Dictionary = {}
var _inside_bodies: Dictionary = {}


func configure(definition: Dictionary) -> void:
	hazard_type = StringName(String(definition.get("type", "unknown")))
	elevation = clampi(int(definition.get("elevation", 0)), -1, 1)
	intensity = maxf(float(definition.get("intensity", 1.0)), 0.0)
	deterministic_seed = maxi(absi(int(definition.get("seed", 1))), 1)
	bounce_retention = clampf(
		float(definition.get("retention", DEFAULT_BOUNCE_RETENTION)),
		0.35,
		1.1
	)
	retrigger_cooldown = maxf(
		float(definition.get("retrigger_cooldown", DEFAULT_RETRIGGER_COOLDOWN)),
		0.05
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
	retention := DEFAULT_BOUNCE_RETENTION
) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = maxi(absi(seed_value + (trigger_index + 1) * 104729), 1)
	var outgoing_direction := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
	var outgoing_speed := clampf(
		incoming_velocity.length() * clampf(retention, 0.35, 1.1),
		MIN_BOUNCE_SPEED,
		MAX_BOUNCE_SPEED
	)
	return outgoing_direction * outgoing_speed


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


func _trigger_bounce_pad(body: Node2D) -> void:
	var body_id := body.get_instance_id()
	if _body_cooldowns.has(body_id):
		return
	if not body.has_method("redirect_from_bounce_pad") or not "linear_velocity" in body:
		return

	var incoming_velocity: Vector2 = body.linear_velocity
	var outgoing_velocity := deterministic_bounce_velocity(
		incoming_velocity,
		deterministic_seed,
		_trigger_count,
		bounce_retention
	)
	_trigger_count += 1
	_body_cooldowns[body_id] = retrigger_cooldown
	if not body.redirect_from_bounce_pad(outgoing_velocity):
		return

	var strength := clampf(outgoing_velocity.length() / MAX_BOUNCE_SPEED, 0.0, 1.0)
	bounce_pad_triggered.emit(strength, &"random", global_position)
	hazard_triggered.emit(&"bounce_pad", strength, global_position)


func _body_matches_elevation(body: Node2D) -> bool:
	if "current_elevation" not in body:
		return elevation == 0
	return int(body.current_elevation) == elevation
