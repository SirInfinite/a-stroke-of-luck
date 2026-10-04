extends "res://scripts/ui/ui_icon.gd"
## Scenery shares the course's actual biome art. Result symbols stay freestanding.

const LAND := {&"meadow":true, &"desert":true, &"autumn":true, &"snow":true, &"swamp":true, &"volcanic":true}
var _land_textures: Dictionary = {}

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0: return
	if not LAND.has(icon_name):
		super._draw()
		return
	if not _land_textures.has(icon_name):
		var path := "res://assets/world/backgrounds/%s.png" % icon_name
		_land_textures[icon_name] = load(path) if ResourceLoader.exists(path) else null
	var art: Texture2D = _land_textures[icon_name]
	if not art: return
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var fit := minf(size.x / art.get_width(), size.y / art.get_height())
	var extent := art.get_size() * fit
	draw_texture_rect(art, Rect2((size - extent) * 0.5, extent), false)