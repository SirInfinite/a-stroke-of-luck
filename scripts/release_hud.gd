class_name ReleaseHUD
extends Control

const OFF_WHITE := Color("f4f0e6")
const CHARCOAL := Color("252a2c")
const GOLD := Color("e2b84b")
const BONUS := Color("43b96b")
const CURSE := Color("d9534f")

var biome_label: Label
var hole_label: Label
var strokes_label: Label
var timer_label: Label
var coins_label: Label
var bonus_label: Label
var curse_label: Label
var shot_label: Label
var curse_panel: PanelContainer


func setup(parent: CanvasLayer) -> void:
	name = "ReleaseHUD"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(self)

	var identity_panel := _create_panel(Vector2(16.0, 16.0), Vector2(430.0, 82.0), Color(CHARCOAL, 0.88), Color(OFF_WHITE, 0.18))
	var identity := _panel_layout(identity_panel)
	biome_label = _create_label(identity, 24, OFF_WHITE)
	hole_label = _create_label(identity, 17, Color(OFF_WHITE, 0.82))

	var score_panel := _create_panel(Vector2(520.0, 16.0), Vector2(658.0, 82.0), Color(CHARCOAL, 0.9), Color(GOLD, 0.42))
	var score_layout := HBoxContainer.new()
	score_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	score_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	score_layout.add_theme_constant_override("separation", 24)
	_panel_margin(score_panel).add_child(score_layout)
	strokes_label = _create_label(score_layout, 22, OFF_WHITE)
	timer_label = _create_label(score_layout, 20, OFF_WHITE)
	coins_label = _create_label(score_layout, 20, GOLD)
	for score_item in [strokes_label, timer_label, coins_label]:
		score_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		score_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_item.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING

	var bonus_panel := _create_panel(Vector2(1260.0, 16.0), Vector2(644.0, 64.0), Color(CHARCOAL, 0.88), Color(BONUS, 0.45))
	bonus_label = _create_label(_panel_layout(bonus_panel), 16, Color(OFF_WHITE, 0.94))
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	curse_panel = _create_panel(Vector2(1260.0, 88.0), Vector2(644.0, 68.0), Color("351d20", 0.94), Color(CURSE, 0.82))
	curse_label = _create_label(_panel_layout(curse_panel), 17, OFF_WHITE)
	curse_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var shot_panel := _create_panel(Vector2(720.0, 1000.0), Vector2(480.0, 58.0), Color(CHARCOAL, 0.82), Color(OFF_WHITE, 0.18))
	shot_label = _create_label(_panel_layout(shot_panel), 17, OFF_WHITE)
	shot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func update_display(state: Dictionary) -> void:
	if not biome_label:
		return
	var biome_name := String(state.get("biome_name", "Tutorial"))
	var biome_number := int(state.get("biome_number", 0))
	var biome_total := int(state.get("biome_total", 6))
	biome_label.text = biome_name.to_upper()
	if biome_number > 0:
		biome_label.text += "  ·  BIOME %d/%d" % [biome_number, biome_total]
	hole_label.text = "HOLE %d / %d" % [int(state.get("hole_number", 1)), int(state.get("hole_total", 18))]
	strokes_label.text = "STROKES  %d / PAR %d" % [int(state.get("strokes", 0)), int(state.get("par", 0))]
	timer_label.text = "TIME  %s" % String(state.get("time", "0:00.0"))
	coins_label.text = "COINS  %d" % int(state.get("coins", 0))
	bonus_label.text = "+ ACTIVE BONUSES  %s" % _summary(state.get("bonuses", []), "None")
	var curse_summary := _summary(state.get("curses", []), "None")
	curse_label.text = "!! ACTIVE CURSES / PENALTIES  %s" % curse_summary
	curse_panel.modulate = Color.WHITE if curse_summary != "None" else Color(1.0, 1.0, 1.0, 0.72)


func update_shot(power: float, aim_text: String) -> void:
	if not shot_label:
		return
	shot_label.text = "AIM  %s    POWER  %d%%" % [aim_text, roundi(clampf(power, 0.0, 1.0) * 100.0)]


func set_hud_visible(visible_state: bool) -> void:
	visible = visible_state


func _summary(value: Variant, fallback: String) -> String:
	if value is Array:
		if value.is_empty():
			return fallback
		var parts := PackedStringArray()
		for item in value:
			parts.append(String(item))
		return "  ·  ".join(parts)
	var text := String(value).strip_edges()
	return fallback if text.is_empty() else text


func _create_panel(position: Vector2, panel_size: Vector2, background: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = panel_size
	panel.custom_minimum_size = panel_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(background, border))
	add_child(panel)
	var margin := MarginContainer.new()
	margin.name = "ContentMargin"
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)
	return panel


func _panel_margin(panel: PanelContainer) -> MarginContainer:
	return panel.get_node("ContentMargin") as MarginContainer


func _panel_layout(panel: PanelContainer) -> VBoxContainer:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 2)
	_panel_margin(panel).add_child(layout)
	return layout


func _create_label(parent: Control, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.025, 0.03, 0.68))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(label)
	return label


func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.02, 0.025, 0.03, 0.36)
	style.shadow_size = 5
	return style
