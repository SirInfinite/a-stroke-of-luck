class_name TransitionPresentation
extends Node

const OFF_WHITE := Color("f4f0e6")
const GOLD := Color("e2b84b")

var overlay: PanelContainer
var title_label: Label
var body_label: Label
var chrome: Control
var accent_band: ColorRect
var identity_label: Label
var _intro_tween: Tween


func setup(new_overlay: PanelContainer, new_title: Label, new_body: Label) -> void:
	overlay = new_overlay
	title_label = new_title
	body_label = new_body
	name = "TransitionPresentation"
	overlay.add_child(self)

	chrome = Control.new()
	chrome.name = "TransitionChrome"
	chrome.set_anchors_preset(Control.PRESET_FULL_RECT)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(chrome)
	overlay.move_child(chrome, 0)

	accent_band = ColorRect.new()
	accent_band.name = "BiomeAccentBand"
	accent_band.set_anchors_preset(Control.PRESET_TOP_WIDE)
	accent_band.offset_bottom = 9.0
	accent_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(accent_band)

	identity_label = Label.new()
	identity_label.name = "BiomeIdentity"
	identity_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	identity_label.offset_left = 28.0
	identity_label.offset_top = -64.0
	identity_label.offset_right = -28.0
	identity_label.offset_bottom = -22.0
	identity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	identity_label.add_theme_font_size_override("font_size", 16)
	identity_label.add_theme_color_override("font_color", Color(OFF_WHITE, 0.68))
	identity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(identity_label)


func show_biome(profile: Variant, biome_number: int, biome_total: int = 6) -> void:
	if not overlay:
		return
	var background: Color = profile.background_palette.get("primary", Color("17221f"))
	var accent: Color = profile.background_palette.get("accent", GOLD)
	overlay.add_theme_stylebox_override("panel", _panel_style(Color(background, 0.98), Color(accent, 0.66)))
	accent_band.color = accent
	title_label.add_theme_color_override("font_color", OFF_WHITE)
	title_label.add_theme_font_size_override("font_size", 42)
	body_label.add_theme_color_override("font_color", Color(OFF_WHITE, 0.9))
	identity_label.text = "%s  ·  BIOME %d / %d" % [String(profile.display_name).to_upper(), biome_number, biome_total]
	_play_intro(accent)


func show_final() -> void:
	if not overlay:
		return
	overlay.add_theme_stylebox_override("panel", _panel_style(Color("161b19", 0.99), Color(GOLD, 0.9)))
	accent_band.color = GOLD
	title_label.add_theme_color_override("font_color", GOLD)
	title_label.add_theme_font_size_override("font_size", 46)
	identity_label.text = "COURSE COMPLETE  ·  ALL SIX BIOMES"
	_play_intro(GOLD)


func show_generic() -> void:
	if not overlay:
		return
	overlay.add_theme_stylebox_override("panel", _panel_style(Color("17221f", 0.98), Color(OFF_WHITE, 0.22)))
	accent_band.color = Color(OFF_WHITE, 0.18)
	title_label.add_theme_color_override("font_color", OFF_WHITE)
	title_label.add_theme_font_size_override("font_size", 38)
	body_label.add_theme_color_override("font_color", Color(OFF_WHITE, 0.9))
	identity_label.text = ""
	reset_presentation()


func reset_presentation() -> void:
	if _intro_tween:
		_intro_tween.kill()
		_intro_tween = null
	if overlay:
		overlay.modulate = Color.WHITE
		overlay.scale = Vector2.ONE


func _play_intro(accent: Color) -> void:
	if _intro_tween:
		_intro_tween.kill()
	overlay.pivot_offset = overlay.size * 0.5
	overlay.modulate = Color(accent.lightened(0.18), 0.0)
	overlay.scale = Vector2(0.985, 0.985)
	_intro_tween = create_tween().set_parallel(true)
	_intro_tween.tween_property(overlay, "modulate", Color.WHITE, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(overlay, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.01, 0.015, 0.02, 0.58)
	style.shadow_size = 12
	return style
