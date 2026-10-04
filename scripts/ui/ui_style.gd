class_name UIStyle
extends RefCounted

## One approved family for every player-facing text role, including fallback-free
## ordinary copy. The names remain stable for existing component callers.
const DISPLAY_FONT: Font = preload("res://assets/fonts/Jersey10/Jersey10-Regular.ttf")
const DISPLAY_SEMIBOLD_FONT: Font = DISPLAY_FONT
const UI_FONT: Font = DISPLAY_FONT
const UI_BOLD_FONT: Font = DISPLAY_FONT
const PAUSE_BLUR_SHADER: Shader = preload("res://assets/pause_blur.gdshader")

const INK := Color("111b27")
const INK_DEEP := Color("101920")
const INK_SOFT := Color("1c2b2f")
const RECESSED := Color("101917")
const PAPER := Color("fff0cf")
const PAPER_MUTED := Color("c5cbb7")
const GOLD := Color("ffe34d")
const GOLD_DARK := Color("a86f24")
const BONUS := Color("b2e1bb")
const BONUS_DARK := Color("173f2b")
const CURSE := Color("ffb4ab")
const CURSE_DARK := Color("4b1d2b")
const STACK := Color("59bfff")
const STACK_DARK := Color("163c59")
const FOCUS := Color("7de0c2")
const SHADOW := Color(0.015, 0.025, 0.022, 0.68)
const PAPER_EDGE := Color("b8ac87")
const PAPER_INK := Color("263d35")
const PAPER_SECONDARY := Color("566457")
static var _frame_textures: Dictionary = {}


static func _static_init() -> void:
	# English production copy is audited against this font's cmap. Missing
	# decorative symbols use icon controls or ASCII, never an unrelated OS font.
	(DISPLAY_FONT as FontFile).allow_system_fallback = false


static func pixel_frame(kind := "panel", content := 8.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _frame_texture(kind)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 10.0)
		style.set_content_margin(side, content)
	style.set_meta(&"pixel_frame", kind)
	return style


static func _frame_texture(kind: String) -> Texture2D:
	if not _frame_textures.has(kind):
		_frame_textures[kind] = load("res://assets/ui/panels/%s.png" % kind)
	return _frame_textures[kind]


static func disclosure_band(ink: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK_DEEP, 0.58)
	style.border_color = Color(ink, 0.64)
	style.border_width_left = 3
	return style


static func frame_appearance(source: StyleBoxTexture, appearance: StringName) -> StyleBoxTexture:
	if appearance != &"light" or not source.has_meta(&"pixel_frame"):
		return source
	var style := source.duplicate() as StyleBoxTexture
	var kind: String = source.get_meta(&"pixel_frame")
	if kind == "focus": return style
	style.texture = _frame_texture("light_card" if kind in ["card", "hover", "pressed", "disabled"] else "light")
	if kind == "hover": style.modulate_color = Color(1.0, 0.96, 0.84)
	if kind == "pressed": style.modulate_color = Color(0.88, 0.86, 0.77)
	if kind == "disabled": style.modulate_color = Color(0.84, 0.84, 0.8)
	return style


static func text_size(requested: int) -> int:
	# Jersey's compact cap height needs this deliberate role scale.
	return maxi(24, roundi(requested * 1.3))


static func icon_ink(id: StringName, requested: Color) -> Color:
	# Explicit ink (for example on a gold price tag) takes precedence. Default
	# foreground receives the same semantics everywhere the symbol is reused.
	if requested != PAPER:
		return requested
	match id:
		&"coin", &"reward", &"trophy", &"star", &"bounce_pad": return GOLD
		&"benefit": return BONUS
		&"curse": return CURSE
		&"stack": return STACK
		&"warning", &"oob", &"risk": return GOLD
		&"meadow", &"desert", &"autumn", &"snow", &"swamp", &"volcanic": return biome_accent(String(id))
	return requested

## Light uses scorecard stock, green-black ink and pastel semantic wells.
## Gold price chips and authored illustration colors retain their identity.
static func appearance_color(source: Color, role: StringName, appearance: StringName) -> Color:
	if appearance != &"light" or source.a < 0.01:
		return source
	var color := source
	if role == &"shadow":
		return Color("263d3526")
	if role == &"background":
		if source.is_equal_approx(RECESSED):
			color = Color("d5d1c1")
		elif source.get_luminance() < 0.36:
			color = Color("f3eedc")
			if source.r > source.g * 1.3:
				color = Color("f4dce0")
			elif source.b > source.r * 1.4:
				color = Color("dce9ef")
			elif source.g > source.r * 1.6:
				color = Color("d8eadb")
	elif role == &"foreground":
		if source.get_luminance() > 0.6 and source.s < 0.3:
			color = PAPER_INK
		elif source.get_luminance() > 0.38 and source.s < 0.25:
			color = PAPER_SECONDARY
		elif source.get_luminance() > 0.28:
			color = source.darkened(0.48)
	elif role == &"border" and source.get_luminance() > 0.4:
		color = source.darkened(0.35)
	color.a = source.a
	return color

const RADIUS_SMALL := 8
const RADIUS_MEDIUM := 14
const RADIUS_LARGE := 22
const BORDER_THIN := 2
const BORDER_BOLD := 4
const SPACE_XS := 6
const SPACE_SM := 10
const SPACE_MD := 16
const SPACE_LG := 24
const SPACE_XL := 36

const BIOME_ACCENTS := {
	"meadow": Color("71d37b"),
	"desert": Color("efb75e"),
	"autumn": Color("df7a4a"),
	"snow": Color("9de5f2"),
	"swamp": Color("77c79d"),
	"volcanic": Color("f16b49"),
	"tutorial": Color("7de0c2"),
}


static func panel_style(
	background: Color,
	border: Color = Color.TRANSPARENT,
	radius: int = RADIUS_MEDIUM,
	border_width: int = BORDER_THIN,
	shadow_size: int = 8,
	content_margin: float = 0.0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(mini(radius, 3))
	style.corner_detail = 1
	style.shadow_color = SHADOW
	style.shadow_size = mini(shadow_size, 3)
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style


static func pause_blur_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = PAUSE_BLUR_SHADER
	return material


## Clipped corners for signage, tickets and fixtures; cards keep rounded stock.
static func ticket_style(background: Color, border: Color, cut := 12, border_width := 2, shadow_size := 5) -> StyleBoxFlat:
	var style := panel_style(background, border, cut, border_width, shadow_size)
	style.corner_detail = 1
	style.shadow_offset = Vector2(0.0, 4.0)
	return style


static func paper_style() -> StyleBoxFlat:
	var style := ticket_style(PAPER, PAPER_EDGE, 14, 2, 10)
	style.border_width_bottom = 6
	return style


static func motion_enabled(node: Node) -> bool:
	var owner_node := node
	while owner_node:
		if owner_node.has_meta(&"reduced_motion"):
			return not bool(owner_node.get_meta(&"reduced_motion"))
		owner_node = owner_node.get_parent()
	return true


static func apply_display(label: Label, size_px: int, color: Color = PAPER) -> Label:
	label.add_theme_font_override("font", DISPLAY_FONT)
	label.add_theme_font_size_override("font_size", roundi(size_px * 1.2))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", SHADOW)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", (4 if size_px >= 44 else 3) if color.get_luminance() > 0.45 and size_px >= 28 else 0)
	label.add_theme_constant_override("shadow_offset_x", 2 if color.get_luminance() > 0.45 else 0)
	label.add_theme_constant_override("shadow_offset_y", 3 if color.get_luminance() > 0.45 else 0)
	return label


static func apply_ui(label: Label, size_px: int, color: Color = PAPER, _bold := false) -> Label:
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", text_size(size_px))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("outline_size", 0)
	return label


static func apply_button(button: Button, variant: StringName = &"secondary") -> Button:
	match variant:
		&"primary":
			button.theme_type_variation = &"PrimaryButton"
		&"danger":
			button.theme_type_variation = &"DangerButton"
		&"quiet":
			button.theme_type_variation = &"QuietButton"
		_:
			button.theme_type_variation = &"SecondaryButton"
	button.focus_mode = Control.FOCUS_ALL
	return button


static func biome_accent(biome_name: String) -> Color:
	var key := biome_name.to_lower()
	for biome_key in BIOME_ACCENTS:
		if key.contains(String(biome_key)):
			return BIOME_ACCENTS[biome_key]
	return FOCUS


static func biome_icon(biome_name: String) -> StringName:
	var key := biome_name.to_lower()
	for biome_key in BIOME_ACCENTS:
		if key.contains(String(biome_key)):
			return StringName(biome_key)
	return &"biome"


static func card_icon(card_id: StringName) -> StringName:
	var aliases := {
		&"tutorial_training_driver": &"overdrive_driver",
		&"tutorial_sand_shoes": &"sand_cleats",
		&"tutorial_pocket_change": &"coin_magnet",
		&"tutorial_steady_grip": &"rangefinder_lens",
	}
	return aliases.get(card_id, card_id)


static func card_category(card_id: StringName) -> String:
	match card_icon(card_id):
		&"overdrive_driver", &"power_club":
			return "POWER"
		&"rangefinder_lens", &"gust_guard":
			return "CONTROL"
		&"sand_cleats":
			return "TERRAIN"
		&"heavy_core":
			return "ROLL"
		&"lucky_putter", &"coin_magnet":
			return "LUCK"
	return "GEAR"


static func card_accent(card_id: StringName) -> Color:
	match card_icon(card_id):
		&"overdrive_driver", &"power_club":
			return Color("f0a84f")
		&"rangefinder_lens", &"gust_guard":
			return Color("72bce7")
		&"sand_cleats":
			return Color("d9b56e")
		&"heavy_core":
			return Color("a9a9c5")
		&"lucky_putter", &"coin_magnet":
			return GOLD
	return FOCUS


static func compact_sentence(text: String) -> String:
	var compact := text.strip_edges()
	if compact.ends_with("."):
		compact = compact.left(-1)
	compact = compact.replace("One extra direction zone is generated on each of the next 3 holes", "Adds 1 direction zone for 3 holes")
	compact = compact.replace("for the next 3 holes", "for 3 holes")
	compact = compact.replace("The cup is", "Cup is")
	return compact
