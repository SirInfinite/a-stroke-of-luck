class_name TutorialManager
extends Node

signal skip_requested

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const UIIconScript := preload("res://scripts/ui/ui_icon.gd")
const UIActionButtonScript := preload("res://scripts/ui/ui_action_button.gd")

class Highlight:
	extends Node2D

	var target_position := Vector2.ZERO
	var radius := 46.0
	var pulse := 0.0

	func _process(delta: float) -> void:
		pulse = fmod(pulse + delta * 2.4, TAU)
		queue_redraw()

	func point_at(world_position: Vector2, new_radius := 46.0) -> void:
		target_position = world_position
		radius = new_radius
		global_position = world_position
		visible = true
		queue_redraw()

	func clear() -> void:
		visible = false

	func _draw() -> void:
		var pulse_radius := radius + sin(pulse) * 5.0
		draw_arc(Vector2.ZERO, pulse_radius, 0.0, TAU, 48, Color(1.0, 0.92, 0.24, 0.95), 4.0)
		draw_arc(Vector2.ZERO, pulse_radius + 10.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.32), 2.0)
		var arrow_start := Vector2(-90.0, -70.0)
		var arrow_end := Vector2(-32.0, -24.0)
		draw_line(arrow_start, arrow_end, Color(1.0, 0.92, 0.24, 0.95), 5.0)
		draw_colored_polygon(PackedVector2Array([
			arrow_end,
			arrow_end + Vector2(-18.0, -2.0),
			arrow_end + Vector2(-6.0, -17.0)
		]), Color(1.0, 0.92, 0.24, 0.95))

const SAVE_PATH := "user://tutorial_complete.cfg"

var main: Node
var canvas_layer: CanvasLayer
var hint_panel: PanelContainer
var hint_label: Label
var hint_icon: UIIcon
var lesson_label: Label
var skip_button: Button
var highlight := Highlight.new()
var current_level: Dictionary = {}
var current_level_index := 0
var level_count := 0
var completed_events := {}
var current_step_index := 0
var last_aim_active := false
var last_aim_power := 0.0
var last_shot_active := false
var blocker_text := ""
var blocker_timer := 0.0
var _last_presented_hint := ""
var _hint_tween: Tween


static func is_tutorial_complete() -> bool:
	var config := ConfigFile.new()
	return config.load(SAVE_PATH) == OK and bool(config.get_value("tutorial", "complete", false))


static func mark_tutorial_complete() -> void:
	var config := ConfigFile.new()
	config.set_value("tutorial", "complete", true)
	config.save(SAVE_PATH)


func setup(new_main: Node, new_canvas_layer: CanvasLayer) -> void:
	main = new_main
	canvas_layer = new_canvas_layer
	highlight.z_index = 200
	main.add_child(highlight)
	_create_overlay()


func set_level(level: Dictionary, index: int, count: int) -> void:
	current_level = level
	current_level_index = index
	level_count = count
	completed_events.clear()
	current_step_index = 0
	last_aim_active = false
	last_aim_power = 0.0
	last_shot_active = false
	blocker_text = ""
	blocker_timer = 0.0
	_mark_active_card_lessons()
	_update_hint()


func notify_event(event_name: StringName) -> void:
	completed_events[event_name] = true
	if event_name == &"hole_completed":
		_update_hint()
		return
	_advance_completed_steps()
	_update_hint()


func can_complete_level() -> bool:
	for event_name in current_level.get("required_events", []):
		if not completed_events.has(event_name):
			return false
	return true


func show_blocker() -> void:
	var missing := _first_missing_required_event()
	blocker_text = _blocker_text_for_event(missing)
	blocker_timer = 2.2
	_update_hint()


func set_visible_enabled(enabled: bool) -> void:
	if hint_panel:
		hint_panel.visible = enabled
	if skip_button:
		skip_button.visible = enabled
	if not enabled:
		highlight.clear()


func _process(delta: float) -> void:
	if current_level.is_empty() or not main or not main.ball:
		return

	if blocker_timer > 0.0:
		blocker_timer -= delta
		if blocker_timer <= 0.0:
			blocker_text = ""
			_update_hint()

	var aim_active: bool = main.ball.has_active_aim()
	if aim_active and not last_aim_active:
		notify_event(&"aim_started")
		notify_event(&"trajectory_previewed")
	var aim_power: float = main.ball.get_aim_power()
	if aim_active and last_aim_active and absf(aim_power - last_aim_power) >= 0.04:
		notify_event(&"power_adjusted")
	last_aim_power = aim_power
	last_aim_active = aim_active

	var shot_active: bool = main.ball.shot_in_progress
	if shot_active and not last_shot_active:
		notify_event(&"shot_taken")
	last_shot_active = shot_active

	_update_highlight_position()


func _create_overlay() -> void:
	hint_panel = PanelContainer.new()
	hint_panel.name = "TutorialCoach"
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(hint_panel)
	hint_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hint_panel.offset_left = -365.0
	hint_panel.offset_top = 122.0
	hint_panel.offset_right = 365.0
	hint_panel.offset_bottom = 230.0
	hint_panel.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color(UIStyleScript.INK_DEEP, 0.94), Color(UIStyleScript.FOCUS, 0.78), 15, 3, 9))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 13)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 9)
	hint_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var icon_stage := PanelContainer.new()
	icon_stage.custom_minimum_size = Vector2(58.0, 58.0)
	icon_stage.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color("234239"), UIStyleScript.FOCUS, 12, 2, 3))
	row.add_child(icon_stage)
	var icon_center := CenterContainer.new()
	icon_stage.add_child(icon_center)
	hint_icon = UIIconScript.new()
	hint_icon.custom_minimum_size = Vector2(42.0, 42.0)
	hint_icon.configure(&"tutorial", UIStyleScript.PAPER, UIStyleScript.FOCUS)
	icon_center.add_child(hint_icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", -2)
	row.add_child(copy)
	lesson_label = Label.new()
	lesson_label.text = "PRACTICE ROUND"
	UIStyleScript.apply_ui(lesson_label, 11, UIStyleScript.FOCUS, true)
	copy.add_child(lesson_label)
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.custom_minimum_size.y = 44.0
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	UIStyleScript.apply_ui(hint_label, 18, UIStyleScript.PAPER, true)
	copy.add_child(hint_label)

	skip_button = UIActionButtonScript.new()
	skip_button.name = "SkipTutorialButton"
	skip_button.custom_minimum_size = Vector2(188.0, 52.0)
	canvas_layer.add_child(skip_button)
	skip_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_button.offset_left = -202.0
	skip_button.offset_top = -72.0
	skip_button.offset_right = -14.0
	skip_button.offset_bottom = -14.0
	skip_button.pressed.connect(func() -> void: skip_requested.emit())
	(skip_button as UIActionButton).configure("SKIP", &"continue", &"quiet")


func _advance_completed_steps() -> void:
	var steps: Array = current_level.get("steps", [])
	while current_step_index < steps.size():
		var step: Dictionary = steps[current_step_index]
		if not completed_events.has(step.get("event", "")):
			break
		current_step_index += 1


func _update_hint() -> void:
	if blocker_text != "":
		hint_label.text = blocker_text
		hint_panel.visible = true
		_update_hint_presentation()
		return

	var steps: Array = current_level.get("steps", [])
	_advance_completed_steps()
	if current_step_index >= steps.size():
		hint_panel.visible = false
		highlight.clear()
		return

	var step: Dictionary = steps[current_step_index]
	hint_label.text = String(step.get("text", ""))
	hint_panel.visible = hint_label.text != ""
	_update_hint_presentation()
	_update_highlight_position()


func _update_hint_presentation() -> void:
	if not hint_panel or not hint_panel.visible:
		return
	lesson_label.text = "PRACTICE %d / %d  •  STEP %d" % [current_level_index + 1, maxi(level_count, 1), current_step_index + 1]
	var icon_name := &"tutorial"
	var step := _current_step()
	var target := String(step.get("target", ""))
	var event_name := String(step.get("event", ""))
	if target == "ball":
		icon_name = &"control"
	elif target == "hole":
		icon_name = &"hole"
	elif target == "shop":
		icon_name = &"shop"
	elif event_name.contains("sand"):
		icon_name = &"sand"
	elif event_name.contains("water"):
		icon_name = &"water"
	elif event_name.contains("curse"):
		icon_name = &"curse"
	elif event_name.contains("benefit"):
		icon_name = &"bonus"
	hint_icon.configure(icon_name, UIStyleScript.PAPER, UIStyleScript.FOCUS)
	if hint_label.text == _last_presented_hint:
		return
	_last_presented_hint = hint_label.text
	if _hint_tween:
		_hint_tween.kill()
	hint_panel.pivot_offset = hint_panel.size * 0.5
	hint_panel.scale = Vector2(0.985, 0.985)
	hint_panel.modulate = Color(UIStyleScript.FOCUS, 0.62)
	_hint_tween = create_tween().set_parallel(true)
	_hint_tween.tween_property(hint_panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hint_tween.tween_property(hint_panel, "modulate", Color.WHITE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _update_highlight_position() -> void:
	var step := _current_step()
	if step.is_empty():
		highlight.clear()
		return

	var target := String(step.get("target", ""))
	if target == "shop":
		highlight.clear()
		return

	var target_position := _target_position(target)
	highlight.point_at(target_position, _target_radius(target))


func _current_step() -> Dictionary:
	var steps: Array = current_level.get("steps", [])
	if current_step_index < 0 or current_step_index >= steps.size():
		return {}
	return steps[current_step_index]


func _target_position(target: String) -> Vector2:
	match target:
		"ball":
			return main.ball.global_position
		"hole":
			return main.level_builder.level_point(current_level, "hole", "hole_cell")
		_:
			if target.begins_with("hazard:"):
				var index := int(target.get_slice(":", 1))
				var hazards: Array = current_level.get("hazards", [])
				if index >= 0 and index < hazards.size():
					return hazards[index].pos
	return main.ball.global_position


func _target_radius(target: String) -> float:
	if target.begins_with("hazard:"):
		var index := int(target.get_slice(":", 1))
		var hazards: Array = current_level.get("hazards", [])
		if index >= 0 and index < hazards.size():
			var size: Vector2 = hazards[index].size
			return maxf(size.x, size.y) * 0.55
	if target == "hole":
		return float(current_level.get("cup_radius", 28.0)) + 26.0
	return 46.0


func _first_missing_required_event() -> String:
	for event_name in current_level.get("required_events", []):
		if not completed_events.has(event_name):
			return String(event_name)
	return ""


func _mark_active_card_lessons() -> void:
	if not main:
		return
	var owned_cards = main.get("owned_card_definitions")
	if owned_cards is Array and not owned_cards.is_empty():
		completed_events[&"card_benefit_active"] = true
	var active_curses = main.get("active_card_curses")
	if active_curses is Array and not active_curses.is_empty():
		completed_events[&"card_curse_active"] = true


func _blocker_text_for_event(event_name: String) -> String:
	match event_name:
		"aim_started":
			return "Aim from the ball before finishing."
		"shot_taken":
			return "Take a shot before finishing."
		"entered_sand":
			return "Touch the sand first."
		"entered_water":
			return "Hit the water once to see the penalty."
		"entered_direction":
			return "Cross the wind pad first."
		"card_benefit_active":
			return "Buy one tutorial card before continuing."
		"card_curse_active":
			return "Accept the tutorial card's disclosed curse before continuing."
	return "Complete the highlighted lesson first."
