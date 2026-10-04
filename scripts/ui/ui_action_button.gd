class_name UIActionButton
extends Button

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const UIIconScript := preload("res://scripts/ui/ui_icon.gd")

var action_icon: UIIcon
var variant: StringName = &"secondary"
var _motion_tween: Tween
var show_icon := true:
	set(value):
		show_icon = value
		if action_icon: action_icon.visible = value
		if is_inside_tree(): _style_action()
var frameless := false
var display_size := 30:
	set(value):
		display_size = value
		if is_inside_tree(): _style_action()


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(260.0, 58.0)
	clip_contents = false
	text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_constant_override("icon_max_width", 28)

	action_icon = UIIconScript.new()
	action_icon.name = "ActionIcon"
	action_icon.custom_minimum_size = Vector2(30.0, 30.0)
	action_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_icon.visible = show_icon
	add_child(action_icon)

	resized.connect(_layout_icon)
	focus_entered.connect(_on_hovered)
	focus_exited.connect(_on_unhovered)
	mouse_entered.connect(_on_hovered)
	mouse_exited.connect(_on_unhovered)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	_layout_icon()


func configure(label_text: String, icon_name: StringName, button_variant: StringName = &"secondary") -> UIActionButton:
	text = label_text
	variant = button_variant
	UIStyleScript.apply_button(self, variant)
	_style_action()
	if not action_icon:
		call_deferred("_configure_icon", icon_name)
	else:
		_configure_icon(icon_name)
	return self


func _style_action() -> void:
	set_meta(&"keep_ui_ink", variant == &"primary" or variant == &"danger")
	for state in ["normal", "hover", "pressed", "disabled"]:
		var kind: String = state if state != "normal" else "primary" if variant == &"primary" else "curse" if variant == &"danger" else "panel"
		var style := UIStyleScript.pixel_frame(kind, 8)
		style.content_margin_left = 52.0 if show_icon else 24.0
		style.content_margin_right = 24.0
		add_theme_stylebox_override(state, style)
		if frameless:
			var clear := StyleBoxEmpty.new()
			clear.content_margin_left = 8
			clear.content_margin_right = 8
			add_theme_stylebox_override(state, clear)
	add_theme_stylebox_override("focus", UIStyleScript.pixel_frame("focus", 8))
	add_theme_font_override("font", UIStyleScript.UI_BOLD_FONT)
	add_theme_font_size_override("font_size", roundi(display_size * 1.2))
	var ink := UIStyleScript.GOLD if variant == &"primary" else UIStyleScript.PAPER
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(state, ink)
	add_theme_color_override("font_disabled_color", Color("83958f"))
	add_theme_color_override("font_outline_color", UIStyleScript.INK)
	add_theme_constant_override("outline_size", 5 if display_size >= 48 else 3 if display_size >= 28 else 1)


func _configure_icon(icon_name: StringName) -> void:
	if not action_icon:
		return
	var icon_tint := UIStyleScript.GOLD if variant == &"primary" else UIStyleScript.PAPER
	var icon_accent := UIStyleScript.GOLD if variant != &"danger" else UIStyleScript.CURSE
	action_icon.configure(icon_name, icon_tint, icon_accent)


func _layout_icon() -> void:
	if not action_icon:
		return
	var icon_size := minf(32.0, maxf(size.y - 20.0, 22.0))
	action_icon.position = Vector2(20.0, (size.y - icon_size) * 0.5)
	action_icon.size = Vector2.ONE * icon_size
	action_icon.queue_redraw()
	queue_redraw()


func _draw() -> void:
	if action_icon:
		action_icon.modulate.a = 0.5 if disabled else 1.0


func _on_hovered() -> void:
	if disabled:
		return
	_play_motion(Vector2(1.012, 1.012), 0.09)


func _on_unhovered() -> void:
	_play_motion(Vector2.ONE, 0.1)


func _on_button_down() -> void:
	if disabled:
		return
	_play_motion(Vector2(0.985, 0.97), 0.055)


func _on_button_up() -> void:
	if disabled:
		return
	_play_motion(Vector2(1.012, 1.012), 0.08)


func _play_motion(target_scale: Vector2, duration: float) -> void:
	if _motion_tween:
		_motion_tween.kill()
	if not UIStyleScript.motion_enabled(self):
		scale = Vector2.ONE
		return
	pivot_offset = Vector2(size.x * 0.5, size.y * 0.5)
	_motion_tween = create_tween()
	_motion_tween.tween_property(self, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
