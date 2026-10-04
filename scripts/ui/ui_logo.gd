class_name UILogo
extends Control
## Owner-approved art. The original source/export stay byte-for-byte unchanged.

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const WORDMARK := preload("res://assets/brand/approved_wordmark.png")
const WORDMARK_LIGHT := WORDMARK

@export var compact := false
@export var show_tagline := false
# Main's scenic title background stays dark in both UI modes. Opt into theme
# ink only when this reusable wordmark is placed on an actual UI-colored sheet.
@export var theme_aware := false
var appearance: StringName = &"dark":
	set(value):
		appearance = value
		if tagline_label:
			tagline_label.add_theme_color_override("font_color", UIStyleScript.appearance_color(UIStyleScript.PAPER, &"foreground", value))
		queue_redraw()

var title_label: Label
var tagline_label: Label
var _entrance_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(680.0, 390.0) if not compact else Vector2(490.0, 260.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Keep Main's existing text handle, and a readable name for accessibility.
	title_label = Label.new()
	title_label.text = "A STROKE OF LUCK"
	title_label.visible = false
	add_child(title_label)
	accessibility_name = title_label.text
	tagline_label = Label.new()
	tagline_label.text = "GOLF WITH CONSEQUENCES."
	UIStyleScript.apply_ui(tagline_label, 18, UIStyleScript.PAPER, true)
	tagline_label.visible = show_tagline
	add_child(tagline_label)
	resized.connect(_layout_art)
	_layout_art()


func _draw() -> void:
	var source_size := WORDMARK.get_size()
	var fit := minf(size.x / source_size.x, size.y / source_size.y)
	var extent := source_size * fit
	draw_texture_rect(WORDMARK, Rect2((size - extent) * 0.5, extent), false)


func apply_appearance(mode: StringName) -> void:
	appearance = mode if theme_aware else &"dark"


func play_entrance() -> void:
	if _entrance_tween:
		_entrance_tween.kill()
	if not UIStyleScript.motion_enabled(self):
		modulate.a = 1.0
		scale = Vector2.ONE
		return
	modulate.a = 0.0
	pivot_offset = size * 0.5
	scale = Vector2(0.965, 0.965)
	_entrance_tween = create_tween().set_parallel(true)
	_entrance_tween.tween_property(self, "modulate:a", 1.0, 0.24)
	_entrance_tween.tween_property(self, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _layout_art() -> void:
	if tagline_label:
		var unit := minf(size.x / 790.0, size.y / 390.0)
		tagline_label.position = Vector2(20, 365) * unit
	queue_redraw()
