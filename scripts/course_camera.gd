class_name CourseCamera
extends Camera2D
## Owns framing and zoom. Impact feedback may use offset, never position/zoom.

signal state_changed(state: State)

enum State { BALL_FOLLOW, COURSE_OVERVIEW }

@export_range(0.5, 2.0, 0.05) var gameplay_zoom := 1.25
@export_range(0.25, 0.5, 0.01) var transition_duration := 0.35
@export_range(8.0, 60.0, 1.0) var follow_speed := 28.0
@export_range(0.0, 80.0, 1.0) var max_follow_lag_pixels := 36.0
@export_range(16.0, 160.0, 4.0) var overview_padding := 64.0

var state: State = State.BALL_FOLLOW
var ball: Node2D
var playable_bounds := Rect2()
var usable_viewport := Rect2()
var reduced_motion := false
var _follow_position := Vector2.ZERO
var _transition_from_position := Vector2.ZERO
var _transition_from_zoom := 1.0
var _transition_elapsed := 1.0
var _framing_zoom := 1.0
var _cup_emphasis := 1.0
var _cup_tween: Tween


func setup(target: Node2D) -> void:
	ball = target
	position_smoothing_enabled = false # One smoothing owner, including transitions.
	process_priority = 100 # Follow after the ball's presentation update.
	usable_viewport = get_viewport_rect()
	reset_for_hole(Rect2())


func reset_for_hole(bounds: Rect2) -> void:
	playable_bounds = bounds
	return_to_ball(true)


func set_usable_viewport(rect: Rect2) -> void:
	if rect == usable_viewport or not rect.has_area():
		return
	usable_viewport = rect
	if state == State.COURSE_OVERVIEW:
		_begin_transition()


func toggle_overview() -> void:
	if not playable_bounds.has_area():
		return
	_clear_cup_emphasis()
	state = State.COURSE_OVERVIEW if state == State.BALL_FOLLOW else State.BALL_FOLLOW
	_begin_transition()
	state_changed.emit(state)


func return_to_ball(immediate := false) -> void:
	var changed := state != State.BALL_FOLLOW
	state = State.BALL_FOLLOW
	_clear_cup_emphasis()
	if immediate:
		_follow_position = ball.global_position if is_instance_valid(ball) else Vector2.ZERO
		global_position = _follow_position
		_framing_zoom = gameplay_zoom
		zoom = Vector2.ONE * gameplay_zoom
		offset = Vector2.ZERO
		_transition_elapsed = transition_duration
		force_update_scroll()
	elif changed:
		_begin_transition()
	if changed:
		state_changed.emit(state)


func is_overview_active() -> bool:
	return state == State.COURSE_OVERVIEW


func overview_frame() -> Dictionary:
	return fit_bounds(playable_bounds.grow(overview_padding), get_viewport_rect().size, usable_viewport, gameplay_zoom)


static func fit_bounds(bounds: Rect2, viewport_size: Vector2, safe_rect: Rect2, max_zoom: float) -> Dictionary:
	# No minimum zoom clamp: even the largest valid course must fit.
	var extent := bounds.size.max(Vector2.ONE)
	var available := safe_rect.size.max(Vector2.ONE)
	var fit_zoom := minf(max_zoom, minf(available.x / extent.x, available.y / extent.y))
	fit_zoom = maxf(fit_zoom, 0.000001)
	var center := bounds.get_center() + (viewport_size * 0.5 - safe_rect.get_center()) / fit_zoom
	return {"center": center, "zoom": fit_zoom}


func play_cup_emphasis(multiplier: float, duration: float) -> void:
	if reduced_motion or is_overview_active():
		return
	_clear_cup_emphasis()
	_cup_tween = create_tween()
	_cup_tween.tween_property(self, "_cup_emphasis", multiplier, duration * 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_cup_tween.tween_property(self, "_cup_emphasis", 1.0, duration * 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _process(delta: float) -> void:
	if not is_instance_valid(ball):
		return
	# Camera transitions run in real seconds even at VS watch/skip speed.
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	var target := ball.global_position
	_follow_position = _follow_position.lerp(target, 1.0 - exp(-follow_speed * real_delta))
	var lag := 0.0 if reduced_motion else max_follow_lag_pixels / gameplay_zoom
	_follow_position = target + (_follow_position - target).limit_length(lag)
	var target_position := _follow_position
	var target_zoom := gameplay_zoom
	if is_overview_active():
		var frame := overview_frame()
		target_position = frame.center
		target_zoom = frame.zoom
	var duration := minf(transition_duration, 0.15) if reduced_motion else transition_duration
	_transition_elapsed += real_delta
	var weight := smoothstep(0.0, duration, _transition_elapsed)
	global_position = _transition_from_position.lerp(target_position, weight)
	_framing_zoom = lerpf(_transition_from_zoom, target_zoom, weight)
	zoom = Vector2.ONE * _framing_zoom * _cup_emphasis
	force_update_scroll()


func _begin_transition() -> void:
	_transition_from_position = global_position
	_transition_from_zoom = _framing_zoom
	_transition_elapsed = 0.0


func _clear_cup_emphasis() -> void:
	if _cup_tween:
		_cup_tween.kill()
		_cup_tween = null
	_cup_emphasis = 1.0
