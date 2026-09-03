class_name UIStyle
extends RefCounted

const DISPLAY_FONT: Font = preload("res://assets/fonts/Fredoka-Bold.ttf")
const DISPLAY_SEMIBOLD_FONT: Font = preload("res://assets/fonts/Fredoka-SemiBold.ttf")
const UI_FONT: Font = preload("res://assets/fonts/AtkinsonHyperlegible-Regular.otf")
const UI_BOLD_FONT: Font = preload("res://assets/fonts/AtkinsonHyperlegible-Bold.otf")

const INK := Color("17201e")
const INK_DEEP := Color("0d1513")
const INK_SOFT := Color("24302c")
const PAPER := Color("f6f1df")
const PAPER_MUTED := Color("c8c8b9")
const GOLD := Color("edbf45")
const GOLD_DARK := Color("a86f24")
const BONUS := Color("48c678")
const BONUS_DARK := Color("173f2b")
const CURSE := Color("e15468")
const CURSE_DARK := Color("4b1d2b")
const STACK := Color("59bfff")
const STACK_DARK := Color("163c59")
const FOCUS := Color("7de0c2")
const SHADOW := Color(0.015, 0.025, 0.022, 0.68)

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
	style.set_corner_radius_all(radius)
	style.shadow_color = SHADOW
	style.shadow_size = shadow_size
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style


static func apply_display(label: Label, size_px: int, color: Color = PAPER) -> Label:
	label.add_theme_font_override("font", DISPLAY_FONT)
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 4)
	return label


static func apply_ui(label: Label, size_px: int, color: Color = PAPER, bold := false) -> Label:
	label.add_theme_font_override("font", UI_BOLD_FONT if bold else UI_FONT)
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
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
