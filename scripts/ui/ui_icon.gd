class_name UIIcon
extends Control
## One background-free glyph family. Geometry is authored in build_brand_assets.py;
## this control owns only size-tier selection, optical centering and semantic ink.

signal palette_changed

const Catalog := preload("res://scripts/ui/icon_catalog.gd")
const Style := preload("res://scripts/ui/ui_style.gd")
const SMALL_MAX := 32.0

var _canonical_ink := Style.PAPER
var _painting_ink := false

@export var icon_name: StringName = &"hole":
	set(value):
		icon_name = value
		queue_redraw()
@export var icon_color := Style.PAPER:
	set(value):
		icon_color = value
		if not _painting_ink:
			_canonical_ink = value
			palette_changed.emit()
		queue_redraw()
@export var accent_color := Style.GOLD:
	set(value):
		accent_color = value
		queue_redraw()

var _glyph_cache: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Explicit small badges may be 16px; containers remain responsible for layout.
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(24.0, 24.0)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)
	queue_redraw()


func configure(new_icon_name: StringName, new_color: Color = Style.PAPER, new_accent: Color = Style.GOLD) -> UIIcon:
	icon_name = new_icon_name
	icon_color = Style.icon_ink(Catalog.canonical(new_icon_name), new_color)
	accent_color = new_accent
	return self


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	draw_glyph(icon_name, Rect2(Vector2.ZERO, size), icon_color)


func apply_appearance(mode: StringName) -> void:
	# Canonical ink belongs to the glyph, so detach/reparent cannot accidentally
	# promote a light-mode tint into the next dark-mode source color.
	_painting_ink = true
	icon_color = Style.appearance_color(_canonical_ink, &"foreground", mode)
	_painting_ink = false


func draw_glyph(id: StringName, bounds: Rect2, ink: Color, force_regular := false) -> void:
	var extent := minf(bounds.size.x, bounds.size.y)
	if extent <= 0.0:
		return
	var render_scale := get_viewport().get_stretch_transform().get_scale()
	var path := Catalog.asset_path(id, small_tier_for(extent, minf(render_scale.x, render_scale.y)) and not force_regular)
	if not _glyph_cache.has(path):
		_glyph_cache[path] = load(path) as Texture2D
	var glyph: Texture2D = _glyph_cache[path]
	if glyph:
		var position := bounds.position + (bounds.size - Vector2.ONE * extent) * 0.5
		var authored_color: bool = Catalog.has_card_art(id)
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if authored_color else CanvasItem.TEXTURE_FILTER_LINEAR
		draw_texture_rect(glyph, Rect2(position, Vector2.ONE * extent), false, Color.WHITE if authored_color else ink)


static func small_tier_for(logical_extent: float, render_scale := 1.0) -> bool:
	return logical_extent * render_scale <= SMALL_MAX
