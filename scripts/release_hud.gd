class_name ReleaseHUD
extends Control

signal seed_copy_requested(seed_value: int)
signal course_overview_requested
signal secondary_controls_moved(top: float)

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const UIIconScript := preload("res://scripts/ui/ui_icon.gd")

var biome_label: Label
var hole_label: Label
var strokes_label: Label
var par_label: Label
var timer_label: Label
var coins_label: Label
var bonus_label: Label
var curse_label: Label
var shot_label: Label
var shot_power_label: Label
var shot_power_meter: ProgressBar
var curse_panel: PanelContainer
var oob_panel: PanelContainer
var oob_countdown_label: Label
var seed_button: Button
var seed_ticket: SeedTicket
var stroke_warning: Label
var stroke_warning_icon: UIIcon
var overview_button: UIActionButton
var shot_aim_icon: UIIcon
var shot_power_icon: UIIcon
var _overview_key_label := "Tab"

var identity_panel: PanelContainer
var score_panel: PanelContainer
var effects_panel: PanelContainer
var biome_icon: UIIcon
var _value_tweens: Dictionary = {}
var _last_strokes := -1
var _last_coins := -1
var _last_curse_text := ""
var _last_oob_second := -1
var _current_seed := 1
var equipment_rail: HBoxContainer
var _equipment_signature := ""


func setup(parent: CanvasLayer) -> void:
	name = "ReleaseHUD"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var safe_margin := MarginContainer.new()
	safe_margin.name = "SafeArea"
	safe_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	safe_margin.offset_bottom = 152.0
	safe_margin.add_theme_constant_override("margin_left", 14)
	safe_margin.add_theme_constant_override("margin_top", 14)
	safe_margin.add_theme_constant_override("margin_right", 14)
	safe_margin.add_theme_constant_override("margin_bottom", 10)
	add_child(safe_margin)
	safe_margin.resized.connect(_layout_secondary_controls)

	var top_row := HBoxContainer.new()
	top_row.name = "TopRow"
	top_row.add_theme_constant_override("separation", 12)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_margin.add_child(top_row)

	identity_panel = _create_panel(top_row, "IdentityCluster", Vector2(330.0, 128.0), 0.84)
	var identity_margin := _panel_margin(identity_panel, 12, 10)
	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 11)
	identity_margin.add_child(identity_row)
	var biome_icon_stage := PanelContainer.new()
	biome_icon_stage.custom_minimum_size = Vector2(64.0, 64.0)
	biome_icon_stage.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("card", 4))
	identity_row.add_child(biome_icon_stage)
	var biome_icon_center := CenterContainer.new()
	biome_icon_stage.add_child(biome_icon_center)
	biome_icon = UIIconScript.new()
	biome_icon.name = "BiomeIcon"
	biome_icon.custom_minimum_size = Vector2(48.0, 48.0)
	biome_icon_center.add_child(biome_icon)
	var identity_copy := VBoxContainer.new()
	identity_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	identity_copy.add_theme_constant_override("separation", -1)
	identity_row.add_child(identity_copy)
	biome_label = _create_label(identity_copy, "BiomeName", 32, UIStyleScript.PAPER, true, true)
	biome_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var hole_backing := PanelContainer.new()
	hole_backing.name = "HoleBacking"
	hole_backing.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("card", 2))
	identity_copy.add_child(hole_backing)
	var hole_margin := MarginContainer.new()
	hole_margin.add_theme_constant_override("margin_left", 8)
	hole_margin.add_theme_constant_override("margin_right", 8)
	hole_margin.add_theme_constant_override("margin_top", 1)
	hole_margin.add_theme_constant_override("margin_bottom", 1)
	hole_backing.add_child(hole_margin)
	hole_label = _create_label(hole_margin, "HoleProgress", 24, UIStyleScript.PAPER, true, true)
	seed_ticket = SeedTicket.new()
	identity_copy.add_child(seed_ticket)
	seed_button = seed_ticket.value_button
	seed_ticket.copy_requested.connect(func(value: int) -> void: seed_copy_requested.emit(value))

	score_panel = _create_panel(top_row, "ScoreCluster", Vector2(520.0, 128.0), 1.12)
	score_panel.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("panel",4))
	var score_margin := _panel_margin(score_panel, 12, 8)
	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.add_theme_constant_override("separation", 8)
	score_margin.add_child(score_row)
	var stroke_stat := _create_stat(score_row, "StrokeStat", &"strokes", "STROKES", true)
	strokes_label = stroke_stat.get_node("Copy/Value") as Label
	par_label = stroke_stat.get_node("Copy/Detail") as Label
	var timer_stat := _create_stat(score_row, "TimerStat", &"timer", "TIME")
	timer_label = timer_stat.get_node("Copy/Value") as Label
	var coin_stat := _create_stat(score_row, "CoinStat", &"coin", "COINS")
	coins_label = coin_stat.get_node("Copy/Value") as Label
	coins_label.add_theme_color_override("font_color", UIStyleScript.GOLD)

	effects_panel = _create_panel(top_row, "EffectCluster", Vector2(480.0, 128.0), 1.18)
	var effects_margin := _panel_margin(effects_panel, 9, 7)
	var effects_column := VBoxContainer.new()
	effects_column.add_theme_constant_override("separation", 5)
	equipment_rail = HBoxContainer.new()
	equipment_rail.name = "EquipmentRail"
	equipment_rail.custom_minimum_size.y = 30
	equipment_rail.add_theme_constant_override("separation",8)
	effects_column.add_child(equipment_rail)
	effects_margin.add_child(effects_column)
	var bonus_panel := _create_effect_row(effects_column, "BonusBand", &"bonus", UIStyleScript.BONUS, UIStyleScript.BONUS_DARK)
	bonus_label = bonus_panel.get_node("Margin/Row/Label") as Label
	curse_panel = _create_effect_row(effects_column, "CurseBand", &"curse", UIStyleScript.CURSE, UIStyleScript.CURSE_DARK)
	curse_label = curse_panel.get_node("Margin/Row/Label") as Label

	var shot_panel := PanelContainer.new()
	shot_panel.name = "ShotReadout"
	shot_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	shot_panel.offset_left = -290.0
	shot_panel.offset_top = -112.0
	shot_panel.offset_right = 290.0
	shot_panel.offset_bottom = -66.0
	shot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shot_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shot_panel.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("panel", 4))
	add_child(shot_panel)
	var shot_margin := _panel_margin(shot_panel, 12, 8)
	var shot_row := HBoxContainer.new()
	shot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	shot_row.add_theme_constant_override("separation", 13)
	shot_margin.add_child(shot_row)
	var aim_icon := UIIconScript.new()
	shot_aim_icon = aim_icon
	aim_icon.custom_minimum_size = Vector2(29.0, 29.0)
	aim_icon.configure(&"control", UIStyleScript.PAPER, UIStyleScript.FOCUS)
	shot_row.add_child(aim_icon)
	shot_label = _create_label(shot_row, "AimValue", 21, UIStyleScript.PAPER, true)
	shot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var power_icon := UIIconScript.new()
	shot_power_icon = power_icon
	power_icon.custom_minimum_size = Vector2(29.0, 29.0)
	power_icon.configure(&"power", UIStyleScript.PAPER, UIStyleScript.GOLD)
	shot_row.add_child(power_icon)
	shot_power_label = _create_label(shot_row, "PowerValue", 20, UIStyleScript.GOLD, true, true)
	shot_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shot_power_label.custom_minimum_size.x = 66.0
	shot_power_meter = ProgressBar.new()
	shot_power_meter.name = "PowerMeter"
	shot_power_meter.custom_minimum_size = Vector2(86, 12)
	shot_power_meter.visible = false # The full native power gauge directly below owns the visual.
	shot_power_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shot_power_meter.show_percentage = false
	shot_power_meter.max_value = 1.0
	shot_row.add_child(shot_power_meter)
	stroke_warning = Label.new()
	stroke_warning.name = "StrokeLimitWarning"
	stroke_warning.set_anchors_preset(Control.PRESET_CENTER_TOP)
	stroke_warning.offset_left = -150
	stroke_warning.offset_right = 150
	stroke_warning.offset_top = 156
	stroke_warning.offset_bottom = 190
	stroke_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyleScript.apply_ui(stroke_warning, 21, UIStyleScript.GOLD, true)
	stroke_warning.add_theme_stylebox_override("normal", UIStyleScript.pixel_frame("primary", 4))
	stroke_warning.set_meta(&"keep_ui_ink", true)
	stroke_warning.visible = false
	add_child(stroke_warning)
	stroke_warning_icon = UIIconScript.new()
	stroke_warning_icon.name = "WarningIcon"
	stroke_warning_icon.custom_minimum_size = Vector2(24, 24)
	stroke_warning.add_child(stroke_warning_icon)
	stroke_warning_icon.position = Vector2(10, 5)
	stroke_warning_icon.size = Vector2(24, 24)

	oob_panel = PanelContainer.new()
	oob_panel.name = "OutOfBoundsWarning"
	oob_panel.visible = false
	oob_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	oob_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	oob_panel.offset_left = -230.0
	oob_panel.offset_top = 162.0
	oob_panel.offset_right = 230.0
	oob_panel.offset_bottom = 240.0
	oob_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	oob_panel.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("curse", 4))
	oob_panel.set_meta(&"keep_ui_ink", true)
	add_child(oob_panel)
	var oob_margin := _panel_margin(oob_panel, 14, 8)
	var oob_row := HBoxContainer.new()
	oob_row.alignment = BoxContainer.ALIGNMENT_CENTER
	oob_row.add_theme_constant_override("separation", 13)
	oob_margin.add_child(oob_row)
	var oob_icon := UIIconScript.new()
	oob_icon.custom_minimum_size = Vector2(42.0, 42.0)
	oob_icon.configure(&"oob", UIStyleScript.PAPER, UIStyleScript.CURSE)
	oob_row.add_child(oob_icon)
	var oob_copy := VBoxContainer.new()
	oob_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	oob_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	oob_copy.add_theme_constant_override("separation", -2)
	oob_row.add_child(oob_copy)
	var oob_heading := _create_label(oob_copy, "Heading", 18, UIStyleScript.PAPER, true, true)
	oob_heading.text = "OUT OF BOUNDS"
	oob_countdown_label = _create_label(oob_copy, "Countdown", 15, UIStyleScript.CURSE.lightened(0.28), true)
	oob_countdown_label.text = "RETURNING IN 3…"

	overview_button = UIActionButton.new()
	overview_button.name = "CourseOverviewButton"
	overview_button.custom_minimum_size = Vector2(214, 52)
	add_child(overview_button)
	overview_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	overview_button.offset_left = -380
	overview_button.offset_right = -164
	overview_button.offset_top = 164
	overview_button.offset_bottom = 216
	overview_button.toggle_mode = true
	overview_button.pressed.connect(func() -> void: course_overview_requested.emit())
	set_overview_state(false, _overview_key_label)
	_layout_secondary_controls.call_deferred()


func _layout_secondary_controls() -> void:
	if not overview_button:
		return
	# Text and equipment establish the header height. Keep controls outside its
	# actual bounds at every viewport scale instead of assuming a fixed top.
	var safe := get_node("SafeArea") as Control
	var top: float = safe.get_rect().end.y + 8.0
	overview_button.offset_top = top
	overview_button.offset_bottom = top + 52.0
	stroke_warning.offset_top = top
	stroke_warning.offset_bottom = top + 38.0
	oob_panel.offset_top = top
	oob_panel.offset_bottom = top + 78.0
	secondary_controls_moved.emit(top)


func update_display(state: Dictionary) -> void:
	if not biome_label:
		return
	overview_button.disabled = not bool(state.get("can_overview", true))
	var biome_name := String(state.get("biome_name", "Tutorial"))
	var accent := UIStyleScript.biome_accent(biome_name)
	biome_label.text = biome_name.to_upper()
	hole_label.text = "HOLE %02d / %02d" % [int(state.get("hole_number", 1)), int(state.get("hole_total", 18))]
	_current_seed = maxi(int(state.get("seed", 1)), 1)
	seed_ticket.set_seed(_current_seed)
	biome_icon.configure(UIStyleScript.biome_icon(biome_name), UIStyleScript.PAPER, accent)
	_update_equipment(state.get("owned_card_definitions", []))

	var strokes := int(state.get("strokes", 0))
	var coins := int(state.get("coins", 0))
	strokes_label.text = "%02d" % strokes
	par_label.text = "PAR %d" % int(state.get("par", 0))
	var remaining := int(state.get("remaining_shots", -1))
	stroke_warning.text = "FINAL SHOT" if remaining == 1 else "2 SHOTS LEFT" if remaining == 2 else ""
	stroke_warning.visible = remaining in [1, 2] and not oob_panel.visible
	stroke_warning.add_theme_color_override("font_color", UIStyleScript.CURSE if remaining == 1 else UIStyleScript.GOLD)
	stroke_warning_icon.configure(&"warning", UIStyleScript.CURSE if remaining == 1 else UIStyleScript.GOLD)
	timer_label.text = String(state.get("time", "0:00.0"))
	coins_label.text = "%02d" % coins
	if _last_strokes >= 0 and strokes != _last_strokes:
		_pulse(strokes_label, UIStyleScript.PAPER)
	if _last_coins >= 0 and coins != _last_coins:
		_pulse(coins_label, UIStyleScript.GOLD)
	_last_strokes = strokes
	_last_coins = coins

	var bonus_full := _summary(state.get("bonuses", []), "NO ACTIVE BONUS", 1)
	bonus_label.text = "BONUS  •  %s" % bonus_full
	bonus_label.tooltip_text = _summary(state.get("bonuses", []), "No active bonuses", 99)
	var curse_full := _summary(state.get("curses", []), "NO ACTIVE CURSE", 1)
	curse_label.text = "CURSE  •  %s" % curse_full
	curse_label.tooltip_text = _summary(state.get("curses", []), "No active curses", 99)
	var has_curse := curse_full != "NO ACTIVE CURSE"
	curse_panel.modulate = Color.WHITE if has_curse else Color(1.0, 1.0, 1.0, 0.63)
	if has_curse and curse_label.text != _last_curse_text:
		_pulse(curse_panel, UIStyleScript.CURSE)
	_last_curse_text = curse_label.text


func update_shot(power: float, aim_text: String) -> void:
	if not shot_label:
		return
	if overview_button.button_pressed:
		shot_label.text = "COURSE OVERVIEW"
		shot_label.tooltip_text = "Inspect the course. Return to Ball View to aim."
		shot_power_label.text = _overview_key_label.to_upper()
		shot_power_meter.value = 0.0
		shot_power_label.add_theme_color_override("font_color", UIStyleScript.GOLD)
		return
	shot_label.text = "AIM  %s" % ("READY" if aim_text == "none" else aim_text)
	shot_label.tooltip_text = TrajectoryPredictor.ASSUMPTIONS
	shot_power_label.text = "%d%%" % roundi(clampf(power, 0.0, 1.0) * 100.0)
	shot_power_meter.value = clampf(power, 0.0, 1.0)
	shot_power_label.add_theme_color_override("font_color", PowerPalette.color_at(power))


func set_overview_state(active: bool, key_label: String) -> void:
	_overview_key_label = key_label
	overview_button.set_pressed_no_signal(active)
	overview_button.configure("OVERVIEW", &"hole", &"primary" if active else &"quiet")
	# Shared button styling restores FOCUS_ALL; apply this after every restyle
	# so a HUD click cannot make Shoot/Enter activate overview a second time.
	overview_button.focus_mode = Control.FOCUS_NONE
	overview_button.display_size = 24
	overview_button.tooltip_text = "Course Overview — %s\n%s" % [key_label, "Active · toggle to return to Ball View" if active else "Fit the playable course · toggle to inspect"]
	shot_aim_icon.configure(&"hole" if active else &"control", UIStyleScript.PAPER, UIStyleScript.FOCUS)
	shot_power_icon.configure(&"back" if active else &"power", UIStyleScript.PAPER, UIStyleScript.GOLD)
	shot_power_meter.visible = false


func get_course_view_rect() -> Rect2:
	# Reserve the real HUD layout, including warnings, rather than assume a
	# physical resolution. Keep a small side gutter around playable geometry.
	var top := maxf(get_node("SafeArea").get_global_rect().end.y, overview_button.get_global_rect().end.y) + 24.0
	for warning in [stroke_warning, oob_panel]:
		if warning.visible:
			top = maxf(top, warning.get_global_rect().end.y + 24.0)
	var bottom: float = get_node("ShotReadout").get_global_rect().position.y - 24.0
	return Rect2(Vector2(96, top), Vector2(maxf(size.x - 128, 1), maxf(bottom - top, 1)))


func set_hud_visible(visible_state: bool) -> void:
	visible = visible_state

func set_tutorial_concepts(concepts: Dictionary) -> void:
	var score_visible := bool(concepts.get("score", true))
	var coins_visible := bool(concepts.get("coins", true))
	strokes_label.get_parent().get_parent().visible = score_visible
	timer_label.get_parent().get_parent().visible = score_visible
	coins_label.get_parent().get_parent().visible = coins_visible
	score_panel.visible = score_visible or coins_visible
	effects_panel.visible = bool(concepts.get("effects", true))
	seed_ticket.visible = concepts.is_empty()
	identity_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if concepts.is_empty() else Control.SIZE_SHRINK_BEGIN
	score_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if concepts.is_empty() else Control.SIZE_SHRINK_BEGIN


func show_out_of_bounds(seconds_remaining: int) -> void:
	if not oob_panel:
		return
	var bounded_seconds := clampi(seconds_remaining, 1, 3)
	oob_panel.visible = true
	stroke_warning.visible = false
	oob_countdown_label.text = "RETURNING IN %d…" % bounded_seconds
	if bounded_seconds != _last_oob_second:
		_pulse(oob_panel, UIStyleScript.CURSE)
	_last_oob_second = bounded_seconds


func hide_out_of_bounds() -> void:
	if oob_panel:
		oob_panel.visible = false
		oob_panel.scale = Vector2.ONE
		oob_panel.modulate = Color.WHITE
	_last_oob_second = -1


func show_seed_copied() -> void:
	seed_ticket.show_copied()


func _update_equipment(definitions: Array) -> void:
	var counts: Dictionary = {}
	var names: Dictionary = {}
	for card: CardDefinition in definitions:
		counts[card.id] = int(counts.get(card.id,0)) + 1
		names[card.id] = card.name
	var signature := str(counts)
	if signature == _equipment_signature: return
	_equipment_signature = signature
	for child in equipment_rail.get_children():
		equipment_rail.remove_child(child)
		child.queue_free()
	if counts.is_empty():
		var empty := _create_label(equipment_rail,"EmptyEquipment",17,UIStyleScript.PAPER_MUTED,true)
		empty.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		empty.text = "EQUIPMENT / NO ITEMS"
		return
	for id in counts:
		var slot := HBoxContainer.new()
		slot.add_theme_constant_override("separation",1)
		slot.tooltip_text = "%s ×%d" % [names[id],counts[id]]
		equipment_rail.add_child(slot)
		var art := preload("res://scripts/ui/card_illustration.gd").new()
		art.custom_minimum_size = Vector2(32,32)
		art.configure(UIStyleScript.card_icon(id))
		slot.add_child(art)
		var count := _create_label(slot,"Count",16,UIStyleScript.PAPER,true)
		count.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		count.text = "×%d" % counts[id]


func _summary(value: Variant, fallback: String, limit: int) -> String:
	if value is Array:
		if value.is_empty():
			return fallback
		var parts := PackedStringArray()
		for item_index in range(mini(value.size(), limit)):
			parts.append(String(value[item_index]))
		if value.size() > limit:
			parts.append("+%d MORE" % (value.size() - limit))
		return "  •  ".join(parts)
	var text := String(value).strip_edges()
	return fallback if text.is_empty() else text


func _create_panel(parent: Control, node_name: String, minimum_size: Vector2, stretch_ratio: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.custom_minimum_size = minimum_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = stretch_ratio
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("panel",4))
	parent.add_child(panel)
	return panel


func _panel_margin(panel: PanelContainer, horizontal: int, vertical: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", horizontal)
	margin.add_theme_constant_override("margin_top", vertical)
	margin.add_theme_constant_override("margin_right", horizontal)
	margin.add_theme_constant_override("margin_bottom", vertical)
	panel.add_child(margin)
	return margin


func _create_label(parent: Control, node_name: String, font_size: int, color: Color, bold := false, display := false) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if display:
		UIStyleScript.apply_display(label, font_size, color)
	else:
		UIStyleScript.apply_ui(label, font_size, color, bold)
	parent.add_child(label)
	return label


func _create_stat(parent: Control, node_name: String, icon_name: StringName, heading: String, has_detail := false) -> HBoxContainer:
	var stat := HBoxContainer.new()
	stat.name = node_name
	stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat.add_theme_constant_override("separation", 7)
	stat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(stat)
	var icon := UIIconScript.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(38.0, 38.0)
	icon.configure(icon_name, UIStyleScript.PAPER_MUTED, UIStyleScript.GOLD if icon_name == &"coin" else UIStyleScript.PAPER_MUTED)
	stat.add_child(icon)
	var copy := VBoxContainer.new()
	copy.name = "Copy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", -5)
	stat.add_child(copy)
	var heading_label := _create_label(copy, "Heading", 16, UIStyleScript.PAPER_MUTED, true)
	heading_label.text = heading
	var value_label := _create_label(copy, "Value", 74 if has_detail else 42, UIStyleScript.PAPER, true, true)
	value_label.text = "00"
	var detail_label := _create_label(copy, "Detail", 18, UIStyleScript.PAPER_MUTED, true)
	detail_label.text = "" if not has_detail else "PAR 0"
	detail_label.visible = has_detail
	return stat


func _create_effect_row(parent: Control, node_name: String, icon_name: StringName, semantic_color: Color, _background: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.custom_minimum_size.y = 37.0
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UIStyleScript.disclosure_band(semantic_color))
	panel.set_meta(&"keep_ui_ink",true)
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", 7)
	margin.add_child(row)
	var icon := UIIconScript.new()
	icon.custom_minimum_size = Vector2(23.0, 23.0)
	icon.configure(icon_name, UIStyleScript.PAPER, semantic_color)
	row.add_child(icon)
	var label := _create_label(row, "Label", 20, UIStyleScript.PAPER, true)
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return panel


func _pulse(target: Control, color: Color) -> void:
	if _value_tweens.has(target):
		var previous := _value_tweens[target] as Tween
		if previous:
			previous.kill()
	if not UIStyleScript.motion_enabled(self):
		target.scale = Vector2.ONE
		target.modulate = Color.WHITE
		return
	target.pivot_offset = target.size * 0.5
	target.scale = Vector2.ONE
	target.modulate = color
	var tween := create_tween()
	_value_tweens[target] = tween
	tween.tween_property(target, "scale", Vector2.ONE * (1.025 if target is PanelContainer else 1.07), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(target, "modulate", Color.WHITE, 0.18)
	tween.tween_property(target, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
