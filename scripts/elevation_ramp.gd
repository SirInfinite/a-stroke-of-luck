class_name ElevationRamp
extends Area2D

signal elevation_transitioned(body: Node2D, from_elevation: int, to_elevation: int)

var from_position := Vector2.ZERO
var to_position := Vector2.ZERO
var from_elevation := 0
var to_elevation := 1
var ramp_width := 72.0
var _tracked_bodies: Dictionary = {}


func configure(
	new_from_position: Vector2,
	new_to_position: Vector2,
	new_from_elevation: int,
	new_to_elevation: int,
	new_ramp_width := 72.0
) -> void:
	from_position = new_from_position
	to_position = new_to_position
	from_elevation = clampi(new_from_elevation, -1, 1)
	to_elevation = clampi(new_to_elevation, -1, 1)
	ramp_width = maxf(new_ramp_width, 24.0)
	position = (from_position + to_position) * 0.5
	rotation = (to_position - from_position).angle()
	set_meta(&"from_elevation", from_elevation)
	set_meta(&"to_elevation", to_elevation)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(maxf(from_position.distance_to(to_position), 24.0), ramp_width)
	collision.shape = shape
	add_child(collision)


func _physics_process(_delta: float) -> void:
	for body_id in _tracked_bodies.keys():
		var body = _tracked_bodies[body_id]
		if not is_instance_valid(body):
			_tracked_bodies.erase(body_id)
			continue
		_update_body_elevation(body)


func get_presentation_data() -> Dictionary:
	return {
		"type": &"ramp",
		"from_position": from_position,
		"to_position": to_position,
		"from_elevation": from_elevation,
		"to_elevation": to_elevation,
		"width": ramp_width,
	}


static func elevation_for_progress(progress: float, low_elevation: int, high_elevation: int) -> int:
	return low_elevation if progress < 0.5 else high_elevation


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("set_current_elevation"):
		return
	var body_elevation := int(body.current_elevation) if "current_elevation" in body else 0
	if body_elevation not in [from_elevation, to_elevation]:
		return
	_tracked_bodies[body.get_instance_id()] = body
	_update_body_elevation(body)


func _on_body_exited(body: Node2D) -> void:
	if not _tracked_bodies.has(body.get_instance_id()):
		return
	_update_body_elevation(body)
	_tracked_bodies.erase(body.get_instance_id())


func _update_body_elevation(body: Node2D) -> void:
	var ramp_vector := to_position - from_position
	var length_squared := ramp_vector.length_squared()
	if length_squared <= 0.001:
		return
	var progress := clampf((body.global_position - from_position).dot(ramp_vector) / length_squared, 0.0, 1.0)
	var target_elevation := elevation_for_progress(progress, from_elevation, to_elevation)
	var previous_elevation := int(body.current_elevation)
	if previous_elevation == target_elevation:
		return
	body.set_current_elevation(target_elevation)
	elevation_transitioned.emit(body, previous_elevation, target_elevation)
