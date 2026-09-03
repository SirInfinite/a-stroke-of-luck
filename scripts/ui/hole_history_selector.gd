class_name HoleHistorySelector
extends PanelContainer

signal selection_changed(entry: Dictionary)

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
var history: Array[Dictionary] = []
var current_hole := 1
var hole_total := 18
var selected_hole := 1
var expanded := false

var toggle_button: Button
var reel: VBoxContainer
var row_buttons: Array[Button] = []
var _reel_tween: Tween


func _init() -> void:
	name = "HoleHistorySelector"
	custom_minimum_size = Vector2(330.0, 58.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	add_theme_stylebox_override(
		"panel",
		UIStyleScript.panel_style(Color(UIStyleScript.INK_DEEP, 0.93), Color(UIStyleScript.PAPER, 0.24), 14, 2, 5)
	)
	_build()


func set_history(new_history: Array, new_current_hole: int, new_hole_total: int) -> void:
	history.clear()
	for entry_value in new_history:
		if entry_value is Dictionary:
			history.append((entry_value as Dictionary).duplicate(true))
	history.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _hole_number(a) < _hole_number(b))
	current_hole = maxi(new_current_hole, 1)
	hole_total = maxi(new_hole_total, current_hole)
	selected_hole = current_hole if can_select_hole(current_hole) else _last_played_hole()
	expanded = false
	_refresh()


func can_select_hole(hole_number: int) -> bool:
	if hole_number <= 0 or hole_number > current_hole:
		return false
	return not entry_for_hole(hole_number).is_empty()


func entry_for_hole(hole_number: int) -> Dictionary:
	for entry in history:
		if _hole_number(entry) == hole_number:
			return entry.duplicate(true)
	return {}


func select_hole(hole_number: int, emit_change := true) -> bool:
	if not can_select_hole(hole_number):
		return false
	if selected_hole == hole_number:
		return true
	selected_hole = hole_number
	_refresh_reel(true)
	if emit_change:
		selection_changed.emit(entry_for_hole(selected_hole))
	return true


func set_expanded(value: bool) -> void:
	expanded = value
	_refresh()
	if expanded:
		grab_focus()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	margin.add_child(layout)

	toggle_button = Button.new()
	toggle_button.name = "HistoryToggle"
	toggle_button.custom_minimum_size.y = 44.0
	toggle_button.focus_mode = Control.FOCUS_ALL
	toggle_button.add_theme_font_override("font", UIStyleScript.DISPLAY_SEMIBOLD_FONT)
	toggle_button.add_theme_font_size_override("font_size", 22)
	toggle_button.add_theme_color_override("font_color", UIStyleScript.PAPER)
	toggle_button.add_theme_color_override("font_hover_color", UIStyleScript.GOLD)
	toggle_button.add_theme_stylebox_override("normal", UIStyleScript.panel_style(Color("090d0c", 0.72), Color(UIStyleScript.PAPER, 0.14), 9, 1, 0))
	toggle_button.add_theme_stylebox_override("hover", UIStyleScript.panel_style(Color(UIStyleScript.INK_SOFT, 0.94), UIStyleScript.GOLD, 9, 2, 0))
	toggle_button.add_theme_stylebox_override("focus", UIStyleScript.panel_style(Color(UIStyleScript.INK_SOFT, 0.94), UIStyleScript.FOCUS, 9, 3, 0))
	toggle_button.pressed.connect(func() -> void: set_expanded(not expanded))
	layout.add_child(toggle_button)

	reel = VBoxContainer.new()
	reel.name = "NumberReel"
	reel.add_theme_constant_override("separation", 2)
	reel.visible = false
	layout.add_child(reel)
	for row_index in range(5):
		var button := Button.new()
		button.name = "ReelRow%d" % row_index
		button.custom_minimum_size.y = 32.0 if row_index != 2 else 42.0
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_override("font", UIStyleScript.DISPLAY_SEMIBOLD_FONT)
		button.add_theme_font_size_override("font_size", 17 if row_index != 2 else 24)
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", UIStyleScript.panel_style(Color(UIStyleScript.INK_SOFT, 0.8), Color(UIStyleScript.GOLD, 0.5), 7, 1, 0))
		button.pressed.connect(_on_reel_row_pressed.bind(row_index))
		reel.add_child(button)
		row_buttons.append(button)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_expanded(true)
			_step_selection(-1)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_expanded(true)
			_step_selection(1)
			accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if not has_focus() or not event.pressed or event.echo:
		return
	if event.is_action(&"ui_accept"):
		set_expanded(not expanded)
		get_viewport().set_input_as_handled()
	elif event.is_action(&"ui_up"):
		set_expanded(true)
		_step_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action(&"ui_down"):
		set_expanded(true)
		_step_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action(&"ui_cancel") and expanded:
		set_expanded(false)
		get_viewport().set_input_as_handled()


func _step_selection(direction: int) -> void:
	var target := selected_hole + direction
	while target >= 1 and target <= hole_total:
		if can_select_hole(target):
			select_hole(target)
			return
		if direction > 0 and target > current_hole:
			return
		target += direction


func _on_reel_row_pressed(row_index: int) -> void:
	var target := selected_hole + row_index - 2
	select_hole(target)


func _refresh() -> void:
	custom_minimum_size.y = 232.0 if expanded else 58.0
	reel.visible = expanded
	toggle_button.text = "HOLE  %02d / %02d    %s" % [selected_hole, hole_total, "▲" if expanded else "▼"]
	_refresh_reel(false)


func _refresh_reel(animate: bool) -> void:
	for row_index in range(row_buttons.size()):
		var button := row_buttons[row_index]
		var offset := row_index - 2
		var target_hole := selected_hole + offset
		var valid_number := target_hole >= 1 and target_hole <= hole_total
		var selectable := valid_number and can_select_hole(target_hole)
		button.disabled = not selectable
		if not valid_number:
			button.text = ""
		elif target_hole > current_hole:
			button.text = "%02d     LOCKED" % target_hole
		elif selectable:
			button.text = "›    %02d    ‹" % target_hole if offset == 0 else "%02d" % target_hole
		else:
			button.text = "%02d     —" % target_hole
		button.add_theme_color_override("font_color", UIStyleScript.GOLD if offset == 0 else UIStyleScript.PAPER_MUTED)
		button.add_theme_color_override("font_disabled_color", Color(UIStyleScript.PAPER_MUTED, 0.32))
	toggle_button.text = "HOLE  %02d / %02d    %s" % [selected_hole, hole_total, "▲" if expanded else "▼"]
	if animate and reel and expanded:
		if _reel_tween:
			_reel_tween.kill()
		reel.modulate = Color(1.0, 1.0, 1.0, 0.45)
		_reel_tween = create_tween()
		_reel_tween.tween_property(reel, "modulate", Color.WHITE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _last_played_hole() -> int:
	var result := 1
	for entry in history:
		result = maxi(result, _hole_number(entry))
	return result


func _hole_number(entry: Dictionary) -> int:
	return int(entry.get("hole_number", entry.get("hole", 0)))
