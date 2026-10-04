extends RefCounted
## Presentation resources for the opt-in reference slice only.

const ROOT := "res://assets/reference_slice/ui/"
const PIXEL_FONT := preload("res://assets/reference_slice/ui/fonts/Jersey10-Regular.ttf")
const COPY_FONT := preload("res://assets/fonts/AtkinsonHyperlegible-Bold.otf")
const PALE := Color("fff0cf")
const GOLD := Color("ffe34d")
const MUTE := Color("c5cbb7")
const INK := Color("111b27")
const BENEFIT := Color("b2e1bb")
const CURSE := Color("ffb4ab")
static var _textures: Dictionary = {}
static var _display_font: FontVariation

static func display_font() -> Font:
	if not _display_font:
		_display_font = FontVariation.new()
		_display_font.base_font = PIXEL_FONT
	return _display_font

static func texture(relative_path: String) -> Texture2D:
	if not _textures.has(relative_path):
		_textures[relative_path] = load(ROOT + relative_path + ".png")
	return _textures[relative_path] as Texture2D

static func item(card_id: StringName, small := false) -> Texture2D:
	var relative_path := "items/" + String(card_id) + ("_icon" if small else "")
	if not ResourceLoader.exists(ROOT + relative_path + ".png"):
		return null
	return texture(relative_path)

static func picture(image: Texture2D) -> TextureRect:
	var result := TextureRect.new()
	result.texture = image
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func frame(kind := "panel", tint := Color.WHITE, content := 12.0) -> StyleBoxTexture:
	var result := StyleBoxTexture.new()
	result.texture = texture("frames/" + kind)
	result.modulate_color = tint
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		result.set_texture_margin(side, 10.0)
		result.set_content_margin(side, content)
	result.set_meta(&"reference_ui", true)
	return result

static func ink(label: Label, size: int, color := PALE, display := true) -> void:
	label.set_meta(&"reference_type_size", size)
	label.set_meta(&"reference_type_color", color)
	label.set_meta(&"reference_type_display", display)
	label.add_theme_font_override("font", display_font() if display else COPY_FONT)
	label.add_theme_font_size_override("font_size", roundi(size*1.2) if display else size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 4 if display and size >= 30 and color != INK else 0)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT if color == INK else Color("091018"))
	label.add_theme_constant_override("shadow_offset_x", 2 if display and color != INK else 0)
	label.add_theme_constant_override("shadow_offset_y", 3 if display and color != INK else 0)

static func button(button_node: Button, primary := false, size := 30, light := false) -> void:
	button_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button_node.add_theme_font_override("font", display_font())
	button_node.add_theme_font_size_override("font_size", roundi(size*1.2))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var kind: String = "light" if light and state == "normal" else ("primary" if primary and state == "normal" else ("panel" if state == "normal" else state))
		button_node.add_theme_stylebox_override(state, frame(kind, Color.WHITE, 10.0))
	button_node.add_theme_stylebox_override("focus", frame("focus", Color.WHITE, 10.0))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button_node.add_theme_color_override(state, INK if light and not primary else (GOLD if primary else PALE))
	button_node.add_theme_color_override("font_disabled_color", Color("829592"))
	button_node.add_theme_color_override("font_outline_color", INK)
	button_node.add_theme_constant_override("outline_size", 4 if size >= 28 else 2)
	button_node.add_theme_color_override("font_shadow_color", Color("060d16"))
	button_node.add_theme_constant_override("shadow_offset_x", 2)
	button_node.add_theme_constant_override("shadow_offset_y", 3)
	button_node.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	if button_node is UIActionButton and button_node.action_icon:
		button_node.action_icon.hide()
