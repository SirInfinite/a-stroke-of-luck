class_name UIToggle
extends CheckButton
## One fixed box/icon/text layout in both states, including silent settings sync.

func _init() -> void:
	custom_minimum_size = Vector2(150, 52)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_font_override("font", UIStyle.UI_BOLD_FONT)
	add_theme_font_size_override("font_size", UIStyle.text_size(22))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		add_theme_color_override(state, UIStyle.PAPER)
	for state in ["normal", "pressed", "hover", "hover_pressed", "disabled"]:
		var hovered: bool = state.begins_with("hover")
		add_theme_stylebox_override(state, UIStyle.pixel_frame("hover" if hovered else "panel", 10))
	add_theme_stylebox_override("focus", UIStyle.pixel_frame("focus", 10))
	add_theme_icon_override("checked", preload("res://assets/ui/toggle_on.svg"))
	add_theme_icon_override("unchecked", preload("res://assets/ui/toggle_off.svg"))
	toggled.connect(_sync_label)
	_sync_label(false)

func _process(_delta: float) -> void:
	# set_pressed_no_signal() must update the visible state too.
	_sync_label(button_pressed)

func _sync_label(enabled: bool) -> void:
	text = "On" if enabled else "Off"
	accessibility_name = "On" if enabled else "Off"
