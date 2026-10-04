extends RefCounted
## Reviewed raster exports, shared only by the approval scene.

const ROOT := "res://assets/pixel_sample/"
const FONT := preload("res://assets/pixel_sample/fonts/PixelifySans.ttf")
static var textures: Dictionary = {}

static func texture(path: String) -> Texture2D:
	if not textures.has(path): textures[path] = load(ROOT + path + ".png")
	return textures[path] as Texture2D

static func sprite(path: String, at := Vector2.ZERO, dimensions := Vector2.ZERO) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = texture(path)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.position = at
	if dimensions != Vector2.ZERO: result.scale = dimensions / result.texture.get_size()
	return result

static func picture(path: String) -> TextureRect:
	var result := TextureRect.new()
	result.texture = texture(path)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func box(path: String, tint := Color.WHITE) -> StyleBoxTexture:
	var result := StyleBoxTexture.new()
	result.texture = texture("ui/" + path)
	result.modulate_color = tint
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		result.set_texture_margin(side, 12)
		result.set_content_margin(side, 12)
	result.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	result.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return result

static func button(control: Button, primary := false) -> void:
	if not control: return
	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	control.add_theme_font_override("font", FONT)
	control.add_theme_font_size_override("font_size", 26)
	var material := "gold_button" if primary else "teal_button"
	control.add_theme_stylebox_override("normal", box(material))
	control.add_theme_stylebox_override("hover", box(material, Color(1.15, 1.15, 1.1)))
	control.add_theme_stylebox_override("pressed", box(material, Color(0.78, 0.8, 0.84)))
	control.add_theme_stylebox_override("disabled", box(material, Color(0.55, 0.6, 0.63)))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		control.add_theme_color_override(state, Color("201f30") if primary else Color("fff1cf"))
	control.add_theme_color_override("font_disabled_color", Color("d0c5b4"))
	if control is UIActionButton and control.action_icon:
		control.action_icon.hide()
