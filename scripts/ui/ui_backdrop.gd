class_name UIBackdrop
extends Control
## Shared scenic backdrop; decoration never changes gameplay or random streams.

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
@export var mode: StringName = &"menu":
	set(value):
		mode = value
		queue_redraw()
@export var accent := UIStyleScript.FOCUS
@export var base_color := UIStyleScript.INK
@export var header_color := Color("101916")
var appearance: StringName = &"dark"
var biome_id: StringName = &"meadow":
	set(value):
		biome_id = value
		if is_inside_tree(): _load_art()
var _art: Texture2D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_art()

func configure(new_mode: StringName, new_accent: Color, new_base := UIStyleScript.INK) -> UIBackdrop:
	mode = new_mode
	accent = new_accent
	base_color = new_base
	return self

func _load_art() -> void:
	var path := "res://assets/world/backgrounds/%s.png" % biome_id
	_art = load(path) as Texture2D if ResourceLoader.exists(path) else null
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if size.x <= 0.0 or size.y <= 0.0: return
	draw_rect(rect, base_color)
	if _art:
		var fit := maxf(size.x / _art.get_width(), size.y / _art.get_height())
		var extent := _art.get_size() * fit
		draw_texture_rect(_art, Rect2((size - extent) * 0.5, extent), false)
	var opacity := 0.50 if mode in [&"menu", &"results"] else 0.36
	draw_rect(rect, Color(0.025, 0.05, 0.07, opacity))