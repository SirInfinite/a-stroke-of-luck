extends RigidBody2D

signal shot_finished
signal sink_animation_finished

@export var max_impulse := 900.0
@export var power_scale := 4.5
@export var max_drag_distance := 180.0
@export var drag_pick_radius := 18.0
@export var trajectory_dot_count := 12
@export var trajectory_dot_spacing := 18.0
@export var trajectory_dot_radius := 2.5
@export var stopped_speed := 5.0
@export var stopped_angular_speed := 0.1
@export var stopped_frames_required := 8
@export var keyboard_turn_speed := 3.5
@export var keyboard_power_speed := 0.75
@export_range(0.0, 1.0) var keyboard_starting_power := 0.35
@export var sink_animation_duration := 0.35

@onready var aim_line: Line2D = $AimLine
@onready var trajectory_preview: Node2D = $TrajectoryPreview
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const POWER_LOW_COLOR := Color(1.0, 0.94, 0.18, 0.9)
const POWER_HIGH_COLOR := Color(1.0, 0.12, 0.05, 0.95)
const TRAJECTORY_COLOR := Color(1.0, 1.0, 1.0, 0.72)

var selected := false
var sunk := false
var power_gradient: Gradient
var shot_in_progress := false
var stopped_frames := 0
var keyboard_active := false
var keyboard_direction := Vector2.RIGHT
var keyboard_power := 0.35


func _ready() -> void:
	keyboard_power = keyboard_starting_power
	power_gradient = Gradient.new()
	power_gradient.set_color(0, POWER_LOW_COLOR)
	power_gradient.set_color(1, POWER_LOW_COLOR)
	aim_line.gradient = power_gradient
	aim_line.set_as_top_level(true)
	trajectory_preview.set_as_top_level(true)
	_create_trajectory_preview()


func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("left_mb"):
		_select_if_mouse_is_on_ball()


func _input(event: InputEvent) -> void:
	if sunk:
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
	_handle_keyboard_aim(delta)
	_update_previews()


func _physics_process(_delta: float) -> void:
	if not shot_in_progress:
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
	apply_central_impulse(impulse)


func reset_to(new_position: Vector2) -> void:
	selected = false
	sunk = false
	shot_in_progress = false
	stopped_frames = 0
	keyboard_active = false
	freeze = false
	visible = true
	scale = Vector2.ONE
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	position = new_position
	collision_shape.set_deferred("disabled", false)
	_hide_previews()


func sink_to(hole_position: Vector2) -> void:
	call_deferred("_apply_sink_to", hole_position)


func _apply_sink_to(hole_position: Vector2) -> void:
	if shot_in_progress:
		_finish_shot()

	selected = false
	sunk = true
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	collision_shape.set_deferred("disabled", true)
	_hide_previews()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", hole_position, sink_animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ZERO, sink_animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished

	visible = false
	sink_animation_finished.emit()


func can_shoot() -> bool:
	return not sunk and not shot_in_progress and _is_stopped()


func get_aim_power() -> float:
	if selected:
		return clampf(_shot_impulse().length() / max_impulse, 0.0, 1.0)
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
	return (drag.limit_length(max_drag_distance) * power_scale).limit_length(max_impulse)


func _keyboard_shot_impulse() -> Vector2:
	return keyboard_direction * keyboard_power * max_impulse


func _drag_vector() -> Vector2:
	return (get_global_mouse_position() - global_position).limit_length(max_drag_distance)


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
		keyboard_power = clampf(keyboard_power + power_input * keyboard_power_speed * delta, 0.0, 1.0)
		keyboard_active = true


func _update_previews() -> void:
	if selected:
		_update_shot_previews(_drag_vector(), _shot_impulse())
	elif keyboard_active and can_shoot():
		_update_shot_previews(-keyboard_direction * keyboard_power * max_drag_distance, _keyboard_shot_impulse())
	else:
		_hide_previews()


func _update_shot_previews(power_line: Vector2, impulse: Vector2) -> void:
	var power: float = clampf(impulse.length() / max_impulse, 0.0, 1.0)
	var power_color := POWER_LOW_COLOR.lerp(POWER_HIGH_COLOR, power)

	aim_line.global_position = Vector2.ZERO
	aim_line.points = PackedVector2Array([global_position, global_position + power_line])
	power_gradient.set_color(0, POWER_LOW_COLOR)
	power_gradient.set_color(1, power_color)
	aim_line.visible = not power_line.is_zero_approx()

	_update_trajectory_preview(impulse, power)


func _create_trajectory_preview() -> void:
	for i in range(trajectory_dot_count):
		var dot := Polygon2D.new()
		dot.name = "Dot%d" % [i + 1]
		dot.polygon = _circle_polygon(trajectory_dot_radius)
		dot.color = TRAJECTORY_COLOR
		trajectory_preview.add_child(dot)

	var arrow_head := Polygon2D.new()
	arrow_head.name = "ArrowHead"
	arrow_head.polygon = PackedVector2Array([
		Vector2(10.0, 0.0),
		Vector2(-6.0, -5.0),
		Vector2(-6.0, 5.0)
	])
	arrow_head.color = TRAJECTORY_COLOR
	trajectory_preview.add_child(arrow_head)


func _update_trajectory_preview(impulse: Vector2, power: float) -> void:
	if impulse.is_zero_approx():
		trajectory_preview.visible = false
		return

	var direction := impulse.normalized()
	var visible_dots: int = max(2, int(round(lerpf(3.0, float(trajectory_dot_count), power))))
	trajectory_preview.global_position = Vector2.ZERO
	trajectory_preview.visible = true

	for i in range(trajectory_dot_count):
		var dot := trajectory_preview.get_node("Dot%d" % [i + 1]) as Polygon2D
		dot.visible = i < visible_dots
		dot.position = global_position + direction * trajectory_dot_spacing * float(i + 1)
		dot.scale = Vector2.ONE * lerp(0.75, 1.25, power)

	var arrow_head := trajectory_preview.get_node("ArrowHead") as Polygon2D
	arrow_head.visible = true
	arrow_head.position = global_position + direction * trajectory_dot_spacing * float(visible_dots + 1)
	arrow_head.rotation = direction.angle()
	arrow_head.scale = Vector2.ONE * lerp(0.8, 1.15, power)


func _hide_previews() -> void:
	aim_line.visible = false
	trajectory_preview.visible = false


func _is_stopped() -> bool:
	return linear_velocity.length() <= stopped_speed and absf(angular_velocity) <= stopped_angular_speed


func _finish_shot() -> void:
	shot_in_progress = false
	stopped_frames = 0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = true
	shot_finished.emit()


func _circle_polygon(radius: float, segments := 12) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
