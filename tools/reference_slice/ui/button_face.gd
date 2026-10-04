extends Control
## Redraws a native button without changing its focus, signals or hit area.
## Native Button remains the sole input owner; this child is paint only.

var source: Button
var _last_state := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(_delta: float) -> void:
	if not is_instance_valid(source): return
	var state := "%s|%s|%s|%s|%s|%s" % [source.text, source.disabled, source.is_hovered(), source.has_focus(), source.button_pressed, source.size]
	if _last_state != state:
		_last_state = state
		queue_redraw()

func _draw() -> void:
	if not is_instance_valid(source) or size.x <= 0.0: return
	var state := "disabled" if source.disabled else "pressed" if source.button_pressed else "hover" if source.is_hovered() else "normal"
	draw_style_box(source.get_theme_stylebox(state), Rect2(Vector2.ZERO, size))
	if source.has_focus():
		draw_style_box(source.get_theme_stylebox("focus"), Rect2(Vector2(-3,-3), size+Vector2(6,6)))
	if source.text.is_empty(): return
	var font := source.get_theme_font("font")
	var font_size := source.get_theme_font_size("font_size")
	var extent := font.get_string_size(source.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var at := Vector2(roundf((size.x-extent.x)*0.5), roundf((size.y-font.get_height(font_size))*0.5+font.get_ascent(font_size)))
	var color_name := "font_disabled_color" if source.disabled else "font_hover_color" if source.is_hovered() else "font_color"
	var outline := source.get_theme_constant("outline_size")
	draw_string(font, at+Vector2(2,3), source.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, source.get_theme_color("font_shadow_color"))
	if outline > 0:
		draw_string_outline(font, at, source.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, outline, source.get_theme_color("font_outline_color"))
	draw_string(font, at, source.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, source.get_theme_color(color_name))
