class_name UIValueTicket
extends PanelContainer
## Reusable label / recessed value control. Only the inner value is interactive.
var heading: Label
var value_button: Button
var value_label: Label
var _value_tween: Tween

func _init() -> void:
	custom_minimum_size = Vector2(280, 52)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_stylebox_override("panel", UIStyle.pixel_frame("panel",2))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	heading = Label.new()
	heading.text = "Seed"
	heading.custom_minimum_size.x = 65
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIStyle.apply_display(heading, 22, UIStyle.PAPER)
	row.add_child(heading)
	value_button = Button.new()
	value_button.name = "ValueButton"
	value_button.custom_minimum_size = Vector2(196, 44)
	value_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in ["normal", "hover", "pressed", "disabled"]:
		value_button.add_theme_stylebox_override(state, UIStyle.pixel_frame("card" if state == "normal" else state,2))
	value_button.add_theme_stylebox_override("focus", UIStyle.pixel_frame("focus",2))
	row.add_child(value_button)
	value_label = Label.new()
	value_label.name = "Value"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIStyle.apply_ui(value_label, 21, UIStyle.PAPER, true)
	value_button.add_child(value_label)
	value_button.resized.connect(_fit_value)
	_fit_value.call_deferred()

func _fit_value() -> void:
	# Initial labels have a font minimum before their button has a laid-out size.
	# Refit against the real well so that minimum never becomes a bottom offset.
	value_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	value_label.offset_left = 0.0
	value_label.offset_top = 0.0
	value_label.offset_right = 0.0
	value_label.offset_bottom = 0.0

func show_value(value: String, color := UIStyle.PAPER, animate := true, direction := 0) -> void:
	value_button.accessibility_name = "%s %s" % [heading.text, value]
	if _value_tween:
		_value_tween.kill()
	if not is_inside_tree() or not animate or not UIStyle.motion_enabled(self):
		_set_value(value, color)
		return
	_value_tween = create_tween()
	_value_tween.tween_property(value_label, "modulate:a", 0.0, 0.07)
	_value_tween.tween_callback(func() -> void:
		_set_value(value, color)
		value_label.modulate.a = 0.0
		value_label.position.y = float(direction) * 14.0)
	_value_tween.tween_property(value_label, "modulate:a", 1.0, 0.12)
	_value_tween.parallel().tween_property(value_label, "position:y", 0.0, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _set_value(value: String, color: Color) -> void:
	value_label.text = value
	value_label.add_theme_color_override("font_color", color)
	value_label.modulate.a = 1.0
	value_label.position.y = 0.0
