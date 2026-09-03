class_name UIActionButton
extends Button

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const UIIconScript := preload("res://scripts/ui/ui_icon.gd")

var action_icon: UIIcon
var variant: StringName = &"secondary"
var _motion_tween: Tween


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(260.0, 58.0)
	clip_contents = false
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_theme_constant_override("icon_max_width", 28)

	action_icon = UIIconScript.new()
	action_icon.name = "ActionIcon"
	action_icon.custom_minimum_size = Vector2(30.0, 30.0)
	action_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(action_icon)

	resized.connect(_layout_icon)
	mouse_entered.connect(_on_hovered)
	mouse_exited.connect(_on_unhovered)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	_layout_icon()


func configure(label_text: String, icon_name: StringName, button_variant: StringName = &"secondary") -> UIActionButton:
	text = label_text
	variant = button_variant
	UIStyleScript.apply_button(self, variant)
	if not action_icon:
		call_deferred("_configure_icon", icon_name)
	else:
		_configure_icon(icon_name)
	return self


func _configure_icon(icon_name: StringName) -> void:
	if not action_icon:
		return
	var icon_tint := UIStyleScript.INK_DEEP if variant == &"primary" else UIStyleScript.PAPER
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
	if size.x <= 0.0:
		return
	var accent_color := UIStyleScript.GOLD
	if variant == &"danger":
		accent_color = UIStyleScript.CURSE
	elif variant == &"quiet":
		accent_color = Color(UIStyleScript.PAPER, 0.38)
	var left_points := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(9.0, 0.0),
		Vector2(17.0, size.y * 0.5),
		Vector2(9.0, size.y),
		Vector2(0.0, size.y),
	])
	draw_colored_polygon(left_points, Color(accent_color, 0.92))
	if variant == &"primary":
		draw_colored_polygon(PackedVector2Array([
			Vector2(size.x - 34.0, size.y * 0.36),
			Vector2(size.x - 19.0, size.y * 0.5),
			Vector2(size.x - 34.0, size.y * 0.64),
		]), Color(UIStyleScript.INK_DEEP, 0.72))


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
	pivot_offset = Vector2(size.x * 0.5, size.y * 0.5)
	_motion_tween = create_tween()
	_motion_tween.tween_property(self, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
