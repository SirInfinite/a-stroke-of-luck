class_name HoleHistorySelector
extends UIValueTicket

signal selection_changed(entry: Dictionary)
var history: Array[Dictionary] = []
var current_hole := 1
var hole_total := 18
var selected_hole := 1
var expanded := false
var toggle_button: Button
var previous_label: Label
var next_label: Label


func _init() -> void:
	super()
	name = "HoleHistorySelector"
	heading.text = "Hole"
	custom_minimum_size = Vector2(330, 118)
	value_button.custom_minimum_size.y = 110
	toggle_button = value_button
	UIStyle.apply_display(value_label, 30, UIStyle.PAPER)
	previous_label = _preview(-1)
	next_label = _preview(1)
	value_button.mouse_entered.connect(set_expanded.bind(true))
	value_button.mouse_exited.connect(set_expanded.bind(false))
	value_button.focus_entered.connect(set_expanded.bind(true))
	value_button.focus_exited.connect(set_expanded.bind(false))
	value_button.pressed.connect(func() -> void: set_expanded(not expanded))
	value_button.gui_input.connect(_gui_input)
	value_button.tooltip_text = "Scroll to review played holes. Arrow keys also work."
	_refresh(false)


func _preview(direction: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIStyle.apply_display(label, 21, UIStyle.PAPER_MUTED)
	value_button.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if direction < 0 else Control.PRESET_BOTTOM_WIDE)
	label.offset_top = 5 if direction < 0 else -32
	label.offset_bottom = 32 if direction < 0 else -5
	label.modulate.a = 0.42
	return label


func set_history(new_history: Array, new_current_hole: int, new_hole_total: int) -> void:
	history.clear()
	for value in new_history:
		if value is Dictionary:
			history.append(value.duplicate(true))
	history.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _hole_number(a) < _hole_number(b))
	current_hole = maxi(new_current_hole, 1)
	hole_total = maxi(new_hole_total, current_hole)
	selected_hole = current_hole if can_select_hole(current_hole) else _last_played_hole()
	expanded = false
	_refresh(false)


func can_select_hole(number: int) -> bool:
	return number > 0 and number <= current_hole and not entry_for_hole(number).is_empty()


func entry_for_hole(number: int) -> Dictionary:
	for entry in history:
		if _hole_number(entry) == number:
			return entry.duplicate(true)
	return {}


func select_hole(number: int, emit_change := true) -> bool:
	if not can_select_hole(number):
		return false
	if selected_hole == number:
		return true
	var direction := signi(number - selected_hole)
	selected_hole = number
	_refresh(true, direction)
	if emit_change:
		selection_changed.emit(entry_for_hole(selected_hole))
	return true


func set_expanded(value: bool) -> void:
	expanded = value
	_refresh_previews()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			set_expanded(true)
			_step_selection(-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		if event.is_action(&"ui_up") or event.is_action(&"ui_down"):
			set_expanded(true)
			_step_selection(-1 if event.is_action(&"ui_up") else 1)
			get_viewport().set_input_as_handled()


func _step_selection(direction: int) -> void:
	var target := selected_hole + direction
	while target >= 1 and target <= current_hole:
		if can_select_hole(target):
			select_hole(target)
			return
		target += direction


func _refresh(animate: bool, direction := 0) -> void:
	show_value("%02d/%02d" % [selected_hole, hole_total], UIStyle.PAPER, animate, direction)
	_refresh_previews()


func _refresh_previews() -> void:
	for pair in [[previous_label, -1], [next_label, 1]]:
		var label: Label = pair[0]
		var target := selected_hole + int(pair[1])
		label.text = "%02d/%02d" % [target, hole_total] if can_select_hole(target) else ""
		label.visible = expanded and not label.text.is_empty()


func _last_played_hole() -> int:
	var result := 1
	for entry in history:
		if _hole_number(entry) <= current_hole:
			result = maxi(result, _hole_number(entry))
	return result


func _hole_number(entry: Dictionary) -> int:
	return int(entry.get("hole_number", entry.get("hole", 0)))
