class_name TransitionPresentation
extends Node

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const UIIconScript := preload("res://scripts/ui/ui_icon.gd")
const UIBackdropScript := preload("res://scripts/ui/ui_backdrop.gd")
const HoleHistorySelectorScript := preload("res://scripts/ui/hole_history_selector.gd")
const CoursePostcardScript := preload("res://scripts/ui/course_postcard.gd")

var overlay: PanelContainer
var title_label: Label
var body_label: Label
var chrome: Control
var backdrop: UIBackdrop
var accent_band: ColorRect
var identity_label: Label
var eyebrow_label: Label
var hero_icon_stage: PanelContainer
var hero_icon: UIIcon
var detail_panel: PanelContainer
var visual_details: VBoxContainer
var safe_area: MarginContainer
var layout_container: HBoxContainer
var hero_column: VBoxContainer
var detail_margin: MarginContainer
var history_selector: HoleHistorySelector
var _intro_tween: Tween
var _history_tween: Tween
var _hole_result_active := false


func setup(new_overlay: PanelContainer, new_title: Label, new_body: Label) -> void:
	overlay = new_overlay
	title_label = new_title
	body_label = new_body
	name = "TransitionPresentation"
	overlay.add_child(self)

	chrome = Control.new()
	chrome.name = "TransitionChrome"
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(chrome)
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.move_child(chrome, 0)

	backdrop = UIBackdropScript.new()
	backdrop.name = "Backdrop"
	backdrop.configure(&"biome", UIStyleScript.FOCUS, UIStyleScript.INK_DEEP)
	chrome.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	accent_band = ColorRect.new()
	accent_band.name = "BiomeAccentBand"
	accent_band.set_anchors_preset(Control.PRESET_TOP_WIDE)
	accent_band.offset_bottom = 7.0
	accent_band.color = UIStyleScript.FOCUS
	accent_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.add_child(accent_band)

	_resolve_production_nodes()
	if not overlay.resized.is_connected(_apply_responsive_layout):
		overlay.resized.connect(_apply_responsive_layout)
	show_generic()
	call_deferred("_apply_responsive_layout")


func show_run_start(seed_value: int) -> void:
	_set_treatment(
		UIStyleScript.GOLD,
		&"seed",
		"YOUR COURSE IS DEALT",
		"18 HOLES. MAKE THEM COUNT.",
		&"results"
	)
	_add_icon_stat(&"seed", "SEED", str(seed_value), UIStyleScript.GOLD)
	_play_intro(UIStyleScript.GOLD)


func show_biome(profile: Variant, biome_number: int, biome_total: int = 6) -> void:
	if not overlay:
		return
	var background: Color = profile.background_palette.get("primary", UIStyleScript.INK_DEEP)
	var accent: Color = profile.background_palette.get("accent", UIStyleScript.GOLD)
	var base := UIStyleScript.INK_DEEP.lerp(background, 0.16)
	_set_treatment(
		accent,
		UIStyleScript.biome_icon(String(profile.display_name)),
		"BIOME %02d / %02d" % [biome_number, biome_total],
		"THREE HOLES  /  A CHANGE OF SCENERY",
		&"biome",
		base
	)
	_add_biome_motif(String(profile.display_name), accent)
	backdrop.biome_id = profile.id
	_play_intro(accent)


func show_hole_result(
	score_to_par: int,
	forced: bool,
	biome_name: String,
	hole_number: int,
	hole_total: int,
	data: Dictionary = {}
) -> void:
	var result_entry := data.duplicate(true)
	result_entry["hole_number"] = hole_number
	result_entry["biome_name"] = biome_name
	result_entry["forced"] = forced
	result_entry["score_to_par"] = score_to_par
	var rating: Dictionary = data.get("rating", {})
	result_entry["stars"] = int(rating.get("stars", data.get("stars", 1)))
	result_entry["golf_result"] = String(rating.get("golf_result", data.get("golf_result", "STROKE LIMIT" if forced else "HOLE COMPLETE")))
	result_entry["performance"] = String(rating.get("performance", data.get("performance", "ROUND COMPLETE")))
	var accent := _rating_accent(int(result_entry.stars))
	_set_treatment(
		accent,
		&"star",
		"%s  •  HOLE %02d / %02d" % [biome_name.to_upper(), hole_number, hole_total],
		"%s  •  %d-STAR PERFORMANCE" % [String(result_entry.performance), int(result_entry.stars)],
		&"results"
	)
	title_label.text = String(result_entry.golf_result)
	_hole_result_active = true
	backdrop.biome_id = UIStyleScript.biome_icon(biome_name)
	_apply_responsive_layout()
	if history_selector:
		history_selector.visible = true
		var history: Array = data.get("history", [result_entry])
		if history.is_empty():
			history = [result_entry]
		history_selector.set_history(history, int(data.get("current_hole", hole_number)), hole_total)
	_render_hole_result(result_entry)
	_play_intro(accent)


func show_run_results(data: Dictionary = {}) -> void:
	_set_treatment(
		UIStyleScript.GOLD,
		&"trophy",
		"ALL SIX BIOMES CLEARED",
		"18 FLAGS DOWN. THAT ONE IS YOURS.",
		&"results"
	)
	_add_stat_strip([
		{"icon": &"score_good", "label": "RUN GRADE", "value": str(data.get("grade", "—")), "accent": UIStyleScript.GOLD},
		{"icon": &"par", "label": "TO PAR", "value": str(data.get("score", "—")), "accent": UIStyleScript.FOCUS},
		{"icon": &"strokes", "label": "STROKES / PAR", "value": "%s / %s" % [str(data.get("strokes", "—")), str(data.get("par", "—"))], "accent": UIStyleScript.PAPER},
	])
	_add_stat_strip([
		{"icon": &"timer", "label": "TOTAL TIME", "value": str(data.get("time", "—")), "accent": UIStyleScript.PAPER},
		{"icon": &"coin", "label": "COINS", "value": str(data.get("coins", 0)), "accent": UIStyleScript.GOLD},
		{"icon": &"seed", "label": "SEED", "value": str(data.get("seed", "—")), "accent": UIStyleScript.PAPER_MUTED},
	])
	_add_biome_progress()
	_add_card_collection(data.get("cards", []))
	_play_intro(UIStyleScript.GOLD)


func show_ending() -> void:
	_set_treatment(
		UIStyleScript.GOLD,
		&"trophy",
		"A STROKE OF LUCK",
		"GOOD GOLF. QUESTIONABLE DECISIONS.",
		&"results"
	)
	_add_biome_progress()
	_play_intro(UIStyleScript.GOLD)


func show_final() -> void:
	show_run_results()


func show_generic() -> void:
	if not overlay:
		return
	_set_treatment(
		UIStyleScript.FOCUS,
		&"hole",
		"A STROKE OF LUCK",
		"GOLF  •  LUCK  •  CONSEQUENCES",
		&"biome"
	)
	reset_presentation()


func reset_presentation() -> void:
	if _intro_tween:
		_intro_tween.kill()
		_intro_tween = null
	if _history_tween:
		_history_tween.kill()
		_history_tween = null
	for item in [title_label, hero_icon_stage, detail_panel, eyebrow_label, visual_details]:
		if item:
			item.modulate = Color.WHITE
			item.scale = Vector2.ONE
	if visual_details:
		for item in visual_details.get_children():
			if item is Control: item.modulate = Color.WHITE
	if eyebrow_label:
		eyebrow_label.position.y = 0.0


func _resolve_production_nodes() -> void:
	eyebrow_label = overlay.get_node_or_null("SafeArea/Layout/HeroColumn/Eyebrow") as Label
	hero_icon_stage = overlay.get_node_or_null("SafeArea/Layout/HeroColumn/HeroIconStage") as PanelContainer
	identity_label = overlay.get_node_or_null("SafeArea/Layout/HeroColumn/Identity") as Label
	detail_panel = overlay.get_node_or_null("SafeArea/Layout/DetailPanel") as PanelContainer
	visual_details = overlay.get_node_or_null("SafeArea/Layout/DetailPanel/DetailMargin/DetailLayout/VisualDetails") as VBoxContainer
	safe_area = overlay.get_node_or_null("SafeArea") as MarginContainer
	layout_container = overlay.get_node_or_null("SafeArea/Layout") as HBoxContainer
	hero_column = overlay.get_node_or_null("SafeArea/Layout/HeroColumn") as VBoxContainer
	detail_margin = overlay.get_node_or_null("SafeArea/Layout/DetailPanel/DetailMargin") as MarginContainer

	if not eyebrow_label:
		eyebrow_label = Label.new()
		eyebrow_label.name = "FallbackEyebrow"
		eyebrow_label.visible = false
		chrome.add_child(eyebrow_label)
	if not identity_label:
		identity_label = Label.new()
		identity_label.name = "BiomeIdentity"
		identity_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		identity_label.offset_left = 28.0
		identity_label.offset_top = -64.0
		identity_label.offset_right = -28.0
		identity_label.offset_bottom = -22.0
		identity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chrome.add_child(identity_label)
	if not hero_icon_stage:
		hero_icon_stage = PanelContainer.new()
		hero_icon_stage.name = "FallbackHeroIconStage"
		hero_icon_stage.visible = false
		chrome.add_child(hero_icon_stage)
	if hero_column:
		hero_column.set_meta(&"keep_ui_ink", true)
		history_selector = HoleHistorySelectorScript.new()
		history_selector.visible = false
		history_selector.selection_changed.connect(_on_history_selection_changed)
		hero_column.add_child(history_selector)
		hero_column.move_child(title_label, 1)

	hero_icon = hero_icon_stage.get_node_or_null("Icon") as UIIcon
	if not hero_icon:
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hero_icon_stage.add_child(center)
		hero_icon = CoursePostcardScript.new()
		hero_icon.name = "Icon"
		hero_icon.custom_minimum_size = Vector2(208.0, 208.0)
		center.add_child(hero_icon)

	UIStyleScript.apply_ui(eyebrow_label, 20, UIStyleScript.GOLD, true)
	UIStyleScript.apply_ui(identity_label, 20, UIStyleScript.PAPER_MUTED, true)
	UIStyleScript.apply_display(title_label, 50, UIStyleScript.PAPER)
	UIStyleScript.apply_ui(body_label, 21, UIStyleScript.PAPER)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _set_treatment(
	accent: Color,
	icon_name: StringName,
	eyebrow: String,
	identity: String,
	backdrop_mode: StringName,
	base := UIStyleScript.INK_DEEP
) -> void:
	_hole_result_active = false
	_clear_visual_details()
	if history_selector:
		history_selector.visible = false
	accent_band.color = accent
	backdrop.configure(backdrop_mode, accent, base)
	overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	eyebrow_label.text = eyebrow
	identity_label.text = identity
	UIStyleScript.apply_display(title_label, 50, UIStyleScript.PAPER)
	UIStyleScript.apply_ui(body_label, 21, UIStyleScript.PAPER)
	hero_icon.configure(icon_name, UIStyleScript.PAPER, accent)
	hero_icon_stage.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	hero_icon_stage.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hero_icon.custom_minimum_size = Vector2(432, 248) if CoursePostcardScript.LAND.has(icon_name) else Vector2(112, 112)
	if detail_panel:
		detail_panel.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("panel",6))
		detail_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		body_label.custom_minimum_size.y = 70.0
	_apply_responsive_layout()


func _clear_visual_details() -> void:
	if not visual_details:
		return
	for child in visual_details.get_children():
		visual_details.remove_child(child)
		child.free()


func _render_hole_result(entry: Dictionary) -> void:
	_clear_visual_details()
	var stars := clampi(int(entry.get("stars", 1)), 1, 5)
	var accent := _rating_accent(stars)
	var score_to_par := int(entry.get("score_to_par", int(entry.get("strokes", 0)) - int(entry.get("par", 0))))
	_add_star_banner(stars, String(entry.get("performance", "ROUND COMPLETE")), accent)
	_add_stat_strip([
		{"icon": &"strokes", "label": "STROKES", "value": str(entry.get("strokes", "—")), "accent": UIStyleScript.PAPER},
		{"icon": &"par", "label": "PAR", "value": str(entry.get("par", "—")), "accent": UIStyleScript.FOCUS},
		{"icon": &"score_good" if score_to_par <= 0 else &"score_bad", "label": "TO PAR", "value": _format_signed(score_to_par), "accent": accent},
	])
	_add_stat_strip([
		{"icon": &"timer", "label": "TIME", "value": str(entry.get("time", "—")), "accent": UIStyleScript.PAPER},
		{"icon": &"coin", "label": "REWARD", "value": "+%s" % str(entry.get("earned", 0)), "accent": UIStyleScript.GOLD},
		{"icon": &"coins", "label": "WALLET", "value": str(entry.get("wallet", 0)), "accent": UIStyleScript.GOLD},
	])


func _add_star_banner(stars: int, performance: String, accent: Color) -> void:
	if not visual_details:
		return
	var panel := PanelContainer.new()
	panel.name = "StarRating"
	panel.custom_minimum_size.y = 72.0 if _is_compact() else 86.0
	panel.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("card",6))
	visual_details.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	margin.add_child(row)
	for star_index in range(5):
		var star := UIIconScript.new()
		star.name = "RatingStar%d" % (star_index + 1)
		star.custom_minimum_size = Vector2.ONE * (42.0 if _is_compact() else 55.0)
		star.configure(&"star", accent if star_index < stars else Color(UIStyleScript.PAPER_MUTED, 0.5))
		star.modulate = Color.WHITE if star_index < stars else Color(1.0, 1.0, 1.0, 0.36)
		row.add_child(star)
	var label := Label.new()
	label.text = performance
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyleScript.apply_ui(label, 18 if _is_compact() else 20, accent, true)
	row.add_child(label)


func _on_history_selection_changed(entry: Dictionary) -> void:
	if entry.is_empty():
		return
	var biome_name := String(entry.get("biome_name", "UNKNOWN"))
	var hole_number := int(entry.get("hole_number", 1))
	var stars := int(entry.get("stars", 1))
	var accent := _rating_accent(stars)
	eyebrow_label.text = "%s  •  HOLE %02d / %02d" % [biome_name.to_upper(), hole_number, history_selector.hole_total]
	identity_label.text = "%s  •  %d-STAR PERFORMANCE" % [String(entry.get("performance", "ROUND COMPLETE")), stars]
	title_label.text = String(entry.get("golf_result", "HOLE COMPLETE"))
	backdrop.biome_id = UIStyleScript.biome_icon(biome_name)
	hero_icon.configure(&"star", UIStyleScript.PAPER, accent)
	accent_band.color = accent
	_render_hole_result(entry)
	if _history_tween:
		_history_tween.kill()
	if not UIStyleScript.motion_enabled(overlay):
		return
	eyebrow_label.position.y = 12.0
	eyebrow_label.modulate = Color(1.0, 1.0, 1.0, 0.18)
	_history_tween = create_tween().set_parallel(true)
	_history_tween.tween_property(eyebrow_label, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_history_tween.tween_property(eyebrow_label, "modulate", Color.WHITE, 0.14)
	_history_tween.tween_property(visual_details, "modulate", Color.WHITE, 0.16).from(Color(1.0, 1.0, 1.0, 0.45))


func _rating_accent(stars: int) -> Color:
	match clampi(stars, 1, 5):
		5:
			return UIStyleScript.BONUS
		4:
			return UIStyleScript.FOCUS
		3:
			return UIStyleScript.GOLD
		2:
			return Color("e58a4d")
		_:
			return UIStyleScript.CURSE


func _add_icon_stat(icon_name: StringName, heading: String, value: String, accent: Color) -> void:
	if not visual_details:
		return
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 72.0
	panel.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("card", 4))
	visual_details.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var icon := UIIconScript.new()
	icon.custom_minimum_size = Vector2(46.0, 46.0)
	icon.configure(icon_name, UIStyleScript.PAPER, accent)
	row.add_child(icon)
	var heading_label := Label.new()
	heading_label.text = heading
	heading_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyleScript.apply_ui(heading_label, 14, UIStyleScript.PAPER_MUTED, true)
	row.add_child(heading_label)
	var value_label := Label.new()
	value_label.text = value
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyleScript.apply_display(value_label, 31, accent)
	row.add_child(value_label)


func _add_biome_motif(biome_name: String, accent: Color) -> void:
	if not visual_details:
		return
	var motif := HBoxContainer.new()
	motif.name = "BiomeMotif"
	motif.alignment = BoxContainer.ALIGNMENT_CENTER
	motif.add_theme_constant_override("separation", 12)
	visual_details.add_child(motif)
	for icon_name in [UIStyleScript.biome_icon(biome_name), &"hole", &"card"]:
		var icon := UIIconScript.new()
		icon.custom_minimum_size = Vector2(56.0, 56.0)
		var ink := UIStyleScript.biome_accent(biome_name) if icon_name == UIStyleScript.biome_icon(biome_name) else UIStyleScript.PAPER
		icon.configure(icon_name, ink, accent)
		motif.add_child(icon)


func _add_biome_progress() -> void:
	if not visual_details:
		return
	var heading := Label.new()
	heading.text = "SIX BIOMES, SIGNED OFF"
	UIStyleScript.apply_ui(heading, 16, UIStyleScript.PAPER_MUTED, true)
	visual_details.add_child(heading)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	visual_details.add_child(row)
	for biome_name in ["Meadow", "Desert", "Autumn", "Snow", "Swamp", "Volcanic"]:
		var stage := PanelContainer.new()
		stage.custom_minimum_size = Vector2.ONE * (54.0 if _is_compact() else 66.0)
		stage.tooltip_text = biome_name + " • completed"
		var accent := UIStyleScript.biome_accent(biome_name)
		stage.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("card", 4))
		row.add_child(stage)
		var center := CenterContainer.new()
		stage.add_child(center)
		var icon := UIIconScript.new()
		icon.custom_minimum_size = Vector2.ONE * (30.0 if _is_compact() else 37.0)
		icon.configure(UIStyleScript.biome_icon(biome_name), UIStyleScript.PAPER, accent)
		center.add_child(icon)


func _add_card_collection(cards: Variant) -> void:
	if not visual_details or not (cards is Array) or cards.is_empty():
		return
	var heading := Label.new()
	heading.text = "BAG BUILT THIS RUN"
	UIStyleScript.apply_ui(heading, 16, UIStyleScript.PAPER_MUTED, true)
	visual_details.add_child(heading)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	visual_details.add_child(row)
	var counts := {}
	for card in cards:
		counts[card.id] = int(counts.get(card.id, 0)) + 1
	var seen: Array[StringName] = []
	for card in cards:
		if card.id in seen:
			continue
		seen.append(card.id)
		var chip := HBoxContainer.new()
		row.add_child(chip)
		var icon := UIIconScript.new()
		icon.custom_minimum_size = Vector2.ONE * 28.0
		icon.tooltip_text = String(card.name)
		icon.configure(UIStyleScript.card_icon(card.id), UIStyleScript.PAPER, UIStyleScript.card_accent(card.id))
		chip.add_child(icon)
		var name_tag := Label.new()
		name_tag.text = "%s ×%d" % [card.name, int(counts[card.id])]
		UIStyleScript.apply_ui(name_tag, 18, UIStyleScript.PAPER, true)
		chip.add_child(name_tag)


func _add_stat_strip(items: Array) -> void:
	if not visual_details or items.is_empty():
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	visual_details.add_child(row)
	for item_value in items:
		var item := item_value as Dictionary
		var accent: Color = item.get("accent", UIStyleScript.PAPER)
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(138.0, 122.0)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("card",6))
		row.add_child(panel)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 8 if _is_compact() else 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 8 if _is_compact() else 10)
		panel.add_child(margin)
		var content := HBoxContainer.new()
		content.add_theme_constant_override("separation", 7)
		margin.add_child(content)
		var icon := UIIconScript.new()
		icon.custom_minimum_size = Vector2.ONE * (33.0 if _is_compact() else 41.0)
		icon.configure(item.get("icon", &"hole"), UIStyleScript.PAPER_INK, accent.darkened(0.2))
		icon.visible = false
		content.add_child(icon)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		copy.add_theme_constant_override("separation", -4)
		content.add_child(copy)
		var heading := Label.new()
		heading.text = str(item.get("label", "STAT"))
		heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		UIStyleScript.apply_ui(heading, 18, UIStyleScript.PAPER_MUTED, true)
		copy.add_child(heading)
		var value := Label.new()
		value.text = str(item.get("value", "—"))
		var role := String(item.get("label", ""))
		value.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		var value_size := 32 if role in ["SEED", "STROKES / PAR", "TOTAL TIME"] else 74 if role in ["STROKES", "REWARD", "TO PAR"] else 54
		UIStyleScript.apply_display(value, value_size, UIStyleScript.GOLD if role in ["REWARD", "WALLET", "COINS"] else UIStyleScript.PAPER)
		copy.add_child(value)


func _apply_responsive_layout() -> void:
	if not overlay:
		return
	var compact := _is_compact()
	if safe_area:
		var horizontal_margin := 48 if compact else 108
		var vertical_margin := 28 if compact else 84
		safe_area.add_theme_constant_override("margin_left", horizontal_margin)
		safe_area.add_theme_constant_override("margin_top", vertical_margin)
		safe_area.add_theme_constant_override("margin_right", horizontal_margin)
		safe_area.add_theme_constant_override("margin_bottom", vertical_margin)
	if layout_container:
		layout_container.add_theme_constant_override("separation", 34 if compact else 64)
	if hero_column:
		hero_column.custom_minimum_size.x = 320.0 if compact else 410.0
	if history_selector:
		history_selector.custom_minimum_size.x = 286.0 if compact else 330.0
	if hero_icon_stage:
		hero_icon_stage.custom_minimum_size = Vector2.ONE * 112.0
	if detail_panel:
		detail_panel.custom_minimum_size.x = 480.0 if compact else 520.0
	if detail_margin:
		var horizontal_detail := 20 if compact else 30
		var vertical_detail := 18 if compact else 28
		detail_margin.add_theme_constant_override("margin_left", horizontal_detail)
		detail_margin.add_theme_constant_override("margin_top", vertical_detail)
		detail_margin.add_theme_constant_override("margin_right", horizontal_detail)
		detail_margin.add_theme_constant_override("margin_bottom", vertical_detail)
	UIStyleScript.apply_display(title_label, 100 if _hole_result_active else 76, UIStyleScript.PAPER)
	UIStyleScript.apply_ui(body_label, 22 if compact else 25, UIStyleScript.PAPER)


func _is_compact() -> bool:
	return overlay != null and (overlay.size.x <= 1366.0 or overlay.size.y <= 780.0)


func _play_intro(accent: Color) -> void:
	if _intro_tween:
		_intro_tween.kill()
	if not UIStyleScript.motion_enabled(overlay):
		reset_presentation()
		return
	var animated_items: Array[Control] = []
	for item in [hero_icon_stage, title_label, detail_panel]:
		if item:
			animated_items.append(item)
	for item in animated_items:
		item.pivot_offset = item.size * 0.5
		# Keep custom-drawn art in the render path while its new layout settles.
		item.modulate = Color(accent.lightened(0.12), 0.01)
		item.scale = Vector2(0.97, 0.97)
	_intro_tween = create_tween().set_parallel(true)
	for index in animated_items.size():
		var item := animated_items[index]
		# Present already-resolved information in readable beats. This tween
		# never awards currency, advances the hole or changes a result.
		var delay := index * 0.14
		_intro_tween.tween_property(item, "modulate", Color.WHITE, 0.18).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_intro_tween.tween_property(item, "scale", Vector2.ONE, 0.22).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _hole_result_active and visual_details:
		for index in visual_details.get_child_count():
			var row := visual_details.get_child(index) as Control
			row.modulate.a = 0.25
			_intro_tween.tween_property(row, "modulate:a", 1.0, 0.18).set_delay(0.18 + index * 0.15)
	_intro_tween.finished.connect(hero_icon.queue_redraw, CONNECT_ONE_SHOT)


func _format_signed(value: int) -> String:
	if value == 0:
		return "EVEN"
	return "%+d" % value
