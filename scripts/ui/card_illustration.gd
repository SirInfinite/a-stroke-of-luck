extends "res://scripts/ui/ui_icon.gd"
## Complete square equipment sprites shared by offers, details and effect rails.
## Color belongs to the illustration; rarity and state belong to the enclosing UI.
var maximum_extent := 208.0

func _ready() -> void:
	super._ready()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var illustration := Catalog.card_texture(icon_name)
	if not illustration:
		draw_glyph(icon_name, Rect2(Vector2.ZERO, size), icon_color)
		return
	var extent := minf(minf(size.x, size.y), maximum_extent)
	var destination := Rect2((size - Vector2.ONE * extent) * 0.5, Vector2.ONE * extent)
	draw_texture_rect(illustration, destination, false, Color.WHITE)
