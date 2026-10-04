extends Node
## Sample-only skin. Reads and styles live game controls; never owns gameplay.

const Art := preload("res://tools/reference_slice/ui/ui_assets.gd")
const ButtonFace := preload("res://tools/reference_slice/ui/button_face.gd")
const PowerFace := preload("res://tools/reference_slice/ui/reference_power.gd")
const APPROVED_LOGO := preload("res://assets/pixel_sample/ui/wordmark.png")

var main
var fx_layer: CanvasLayer
var _last_phase := -1
var _last_appearance: StringName
var _identity_frame: StyleBox
var _selected_id: StringName
var _last_purchased: StringName
var _shop_body: HBoxContainer
var _detail_side: PanelContainer
var _detail_strip: PanelContainer
var _details: Array[Dictionary] = []
var _rail: HBoxContainer
var _last_owned := ""
var _settle_frames := 0
var _result_settle_frames := 0
var _effects: Array[Control] = []
var _hover_tweens: Dictionary = {}

func setup(owner_main) -> void:
	main = owner_main
	fx_layer = CanvasLayer.new()
	fx_layer.name = "ReferenceUIFeedback"
	fx_layer.layer = 25
	add_child(fx_layer)
	main.main_menu_logo.self_modulate.a = 0.0
	var logo := Art.picture(APPROVED_LOGO)
	logo.name = "ApprovedWordmark"
	main.main_menu_logo.add_child(logo)
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# TitleAttractMode, its parallax and pause visibility remain Main's property.
	main.shop_manager.hover_scale = 1.0
	main.shop_manager.purchase_pulse_scale = 1.0
	main.shop_manager.coin_pulse_scale = 1.025
	main.shop_manager.curse_flash_intensity = 0.0
	main.shop_manager.card_bought.connect(_card_bought)
	main.shop_manager.feedback_requested.connect(_purchase_feedback)
	if main.transition_presentation.history_selector:
		main.transition_presentation.history_selector.selection_changed.connect(func(_entry): _style_results.call_deferred())
	_style_title()
	_style_hud()
	_style_utility.call_deferred()
	for screen in [main.settings_screen, main.run_setup_screen]:
		if screen:
			screen.visibility_changed.connect(_utility_opened.bind(screen))
	for button in main.run_setup_screen.find_children("*", "Button", true, false):
		button.pressed.connect(_utility_opened.bind(main.run_setup_screen))
	main.run_setup_screen.seed_input.text_changed.connect(func(_text): _utility_opened(main.run_setup_screen))
	_settle_frames = 3
	if main.power_meter:
		main.power_meter.self_modulate.a = 0.0
		var meter := PowerFace.new()
		meter.source = main.power_meter
		meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		main.power_meter.add_child(meter)
		meter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func apply_hole() -> void:
	_style_hud()
	_update_item_rail(true)

func _process(_delta: float) -> void:
	if not main: return
	if _last_appearance != main.game_settings.ui_appearance:
		_last_appearance = main.game_settings.ui_appearance
		_style_title()
		_style_hud()
		_style_utility()
		if main.shop_manager.shop_overlay.visible: apply_shop()
		if main.interstitial_overlay.visible: _style_results()
	if _identity_frame and main.release_hud.identity_panel.get_theme_stylebox("panel") != _identity_frame:
		main.release_hud.identity_panel.add_theme_stylebox_override("panel", _identity_frame)
	if not main.release_hud.overview_button.get_theme_stylebox("normal").get_meta(&"reference_ui", false):
		_button(main.release_hud.overview_button, false, 24)
	if _settle_frames > 0:
		_settle_frames -= 1
		if main.shop_manager.shop_overlay.visible: apply_shop(false)
	if _result_settle_frames > 0:
		_result_settle_frames -= 1
		if main.interstitial_overlay.visible: _style_results(false)
	var seed_ticket = main.release_hud.seed_ticket
	var seed_ink: Color = Art.INK if _light() else Art.PALE
	if seed_ticket.copied_remaining > 0.0:
		seed_ink = Color("315c42") if _light() else Art.BENEFIT
	if seed_ticket.value_label.get_theme_color("font_color") != seed_ink:
		seed_ticket.value_label.add_theme_color_override("font_color",seed_ink)
	var phase: int = main.run_state.phase
	if phase != _last_phase:
		_last_phase = phase
		if phase == RunState.Phase.SHOP: apply_shop.call_deferred()
		if main.interstitial_overlay.visible: _style_results.call_deferred()
		if phase != RunState.Phase.SHOP: _clear_feedback()
		_update_item_rail(true)
	if main.main_menu_overlay.visible and not _effects.is_empty(): _clear_feedback()
	_update_item_rail()

func _light() -> bool:
	return main.game_settings.ui_appearance == &"light"

func _own(control: Control) -> void:
	if not control or not main.ui_appearance: return
	var id := control.get_instance_id()
	var callback: Callable = main.ui_appearance._queue_refresh.bind(id)
	if control.theme_changed.is_connected(callback): control.theme_changed.disconnect(callback)
	main.ui_appearance._forget(id)

func _label(label: Label, size: int, color := Art.PALE, display := true) -> void:
	_own(label)
	Art.ink(label, size, color, display)

func _panel(panel: Control, kind := "panel", content := 12.0) -> void:
	_own(panel)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_theme_stylebox_override("panel", Art.frame(kind, Color.WHITE, content))

func _button(button: Button, primary := false, font_size := 30, allow_light := false) -> void:
	if not button: return
	_own(button)
	Art.button(button, primary, font_size, allow_light and _light())
	if button is CheckButton or button is CheckBox or button is OptionButton: return
	button.self_modulate.a = 0.0
	var face: Control = button.get_node_or_null("ReferenceFace")
	if not face:
		face = ButtonFace.new()
		face.name = "ReferenceFace"
		face.source = button
		button.add_child(face)
		button.move_child(face, 0)
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.queue_redraw()

func _style_title() -> void:
	_panel(main.menu_action_panel, "panel", 14.0)
	main.menu_action_panel.get_theme_stylebox("panel").modulate_color.a = 0.84
	for button in [main.menu_play_button, main.menu_resume_button, main.menu_tutorial_button, main.menu_skip_button, main.menu_settings_button, main.menu_quit_button]:
		if button: _button(button, button in [main.menu_play_button, main.menu_resume_button], 48 if button in [main.menu_play_button, main.menu_resume_button] else 38)
	_button(main.menu_button, false, 26)

func _style_hud() -> void:
	var hud = main.release_hud
	for panel in [hud.identity_panel, hud.score_panel, hud.effects_panel]:
		_panel(panel, "light" if _light() else "panel", 4.0)
	_identity_frame = hud.identity_panel.get_theme_stylebox("panel")
	var foreground := Art.INK if _light() else Art.PALE
	_label(hud.biome_label, 32, foreground)
	_label(hud.hole_label, 26, foreground)
	_label(hud.strokes_label, 66, foreground)
	_label(hud.par_label, 26, foreground)
	_label(hud.timer_label, 40, foreground)
	_label(hud.coins_label, 60, Color("765823") if _light() else Art.GOLD)
	for heading in hud.score_panel.find_children("Heading", "Label", true, false):
		_label(heading, 20, foreground, false)
	for icon in hud.score_panel.find_children("*", "UIIcon", true, false): icon.hide()
	hud.biome_icon.get_parent().get_parent().hide()
	_panel(hud.seed_ticket, "light_card" if _light() else "card", 2.0)
	_label(hud.seed_ticket.heading, 20, foreground)
	_label(hud.seed_ticket.value_label, 20, foreground, false)
	_button(hud.seed_button, false, 20, true)
	hud.seed_ticket.value_label.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_FULL_RECT)
	for band in hud.effects_panel.find_children("*Band", "PanelContainer", true, false):
		_panel(band, "curse" if band == hud.curse_panel else "benefit", 2.0)
		band.custom_minimum_size.y = 32
		var margin: MarginContainer = band.get_node("Margin")
		margin.add_theme_constant_override("margin_top", 2)
		margin.add_theme_constant_override("margin_bottom", 2)
	for icon in hud.effects_panel.find_children("*", "UIIcon", true, false): icon.hide()
	_label(hud.bonus_label, 18, Art.BENEFIT, false)
	_label(hud.curse_label, 18, Art.CURSE, false)
	_label(hud.shot_label, 24)
	_label(hud.shot_power_label, 25, Art.GOLD)
	_label(hud.stroke_warning, 26, Art.GOLD)
	_panel(hud.get_node("ShotReadout"), "panel", 3.0)
	_button(hud.overview_button, false, 24)
	_button(main.menu_button, false, 26)
	if not _rail:
		_rail = HBoxContainer.new()
		_rail.name = "ReferenceItemRail"
		_rail.custom_minimum_size.y = 30
		_rail.add_theme_constant_override("separation", 8)
		_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var column: Control = hud.bonus_label.get_parent().get_parent().get_parent().get_parent()
		column.add_child(_rail)
		column.move_child(_rail, 0)
	_update_item_rail(true)

func _update_item_rail(force := false) -> void:
	if not _rail: return
	var key := str(main.run_state.owned_cards)
	if not force and key == _last_owned: return
	_last_owned = key
	for child in _rail.get_children():
		_rail.remove_child(child)
		child.queue_free()
	var counts: Dictionary = {}
	for card: CardDefinition in main.run_state.owned_card_definitions:
		counts[card.id] = int(counts.get(card.id, 0)) + 1
	if counts.is_empty():
		var empty := Label.new()
		empty.text = "EQUIPMENT  /  NO ITEMS"
		_rail.add_child(empty)
		_label(empty, 19, Art.INK if _light() else Art.MUTE, false)
		return
	for card_id in counts:
		var image := Art.item(card_id, true)
		if not image: continue
		var slot := HBoxContainer.new()
		slot.add_theme_constant_override("separation", 1)
		slot.tooltip_text = String(card_id).replace("_", " ").capitalize() + " ×" + str(counts[card_id])
		slot.mouse_filter = Control.MOUSE_FILTER_PASS
		_rail.add_child(slot)
		var illustration := Art.picture(image)
		illustration.custom_minimum_size = Vector2(32,32)
		slot.add_child(illustration)
		var count := Label.new()
		count.text = "×" + str(counts[card_id])
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(count)
		_label(count, 18, Art.INK if _light() else Art.PALE)

func apply_shop(settle := true) -> void:
	if not main or main.run_state.tutorial_mode: return
	if settle: _settle_frames = 3
	var shop = main.shop_manager
	_own(shop.shop_overlay)
	var wash := StyleBoxFlat.new()
	wash.bg_color = Color(0.025,0.06,0.08,0.57)
	shop.shop_overlay.add_theme_stylebox_override("panel", wash)
	var backdrop: CanvasItem = shop.shop_overlay.get_node_or_null("ShopBackdrop")
	if backdrop: backdrop.hide()
	_build_shop_layout()
	var side_details: bool = shop.current_offer_count <= 4
	_detail_side.visible = side_details
	_detail_strip.visible = not side_details
	shop.shop_card_rows[1].hide()
	shop.shop_card_rows[0].size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop.shop_card_rows[0].add_theme_constant_override("separation", 12)
	for index in range(shop.shop_card_slots.size()):
		var slot: Control = shop.shop_card_slots[index]
		if slot.get_parent() != shop.shop_card_rows[0]: slot.reparent(shop.shop_card_rows[0])
		slot.visible = index < shop.current_offer_count
		slot.custom_minimum_size = Vector2(220, 676)
		slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var card: UICard = shop.shop_card_buttons[index]
		if card.visible and slot.visible: _style_card(card)
	var header: Control = shop.shop_title_label.get_parent().get_parent()
	header.get_child(0).hide()
	_label(shop.shop_title_label, 47)
	_label(shop.shop_tokens_label, 42, Art.GOLD)
	_label(shop.shop_purchase_label, 19, Art.PALE, false)
	_label(shop.shop_destination_label, 20, Art.PALE, false)
	_label(shop.shop_status_label, 25)
	_label(shop.shop_curse_status_label, 18, Art.CURSE, false)
	_panel(shop.shop_tokens_label.get_parent().get_parent().get_parent().get_parent(), "panel", 4.0)
	for icon in shop.shop_tokens_label.get_parent().get_parent().get_children():
		if icon is UIIcon: _replace_icon(icon,Art.texture("icons/coin"))
	_button(shop.continue_button, true, 34)
	if _selected_id.is_empty() or not _definition(_selected_id):
		if not shop.current_shop_cards.is_empty(): _selected_id = shop.current_shop_cards[0].id
	_show_details(_selected_id)

func _build_shop_layout() -> void:
	if _shop_body: return
	var layout: VBoxContainer = main.shop_manager.shop_overlay.get_node("SafeArea/ShopLayout")
	var rows: VBoxContainer = layout.get_node("CardRows")
	_shop_body = HBoxContainer.new()
	_shop_body.name = "ReferenceBody"
	_shop_body.add_theme_constant_override("separation", 22)
	_shop_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_shop_body)
	layout.move_child(_shop_body, 1)
	_detail_side = _build_details(false)
	_detail_side.custom_minimum_size.x = 320
	_shop_body.add_child(_detail_side)
	rows.reparent(_shop_body)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	_detail_strip = _build_details(true)
	layout.add_child(_detail_strip)
	layout.move_child(_detail_strip, 2)
	_detail_strip.hide()

func _build_details(horizontal: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "SelectedItemStrip" if horizontal else "SelectedItemDetails"
	_panel(panel, "panel", 16.0)
	var row: BoxContainer = HBoxContainer.new() if horizontal else VBoxContainer.new()
	row.add_theme_constant_override("separation", 14 if horizontal else 16)
	panel.add_child(row)
	var art := Art.picture(null)
	art.custom_minimum_size = Vector2(100,100) if horizontal else Vector2(0,186)
	row.add_child(art)
	var title_group := VBoxContainer.new()
	title_group.custom_minimum_size.x = 250 if horizontal else 0
	title_group.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(title_group)
	var eyebrow := Label.new()
	eyebrow.text = "SELECTED EQUIPMENT"
	title_group.add_child(eyebrow)
	_label(eyebrow, 19, Art.MUTE, false)
	var title := Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_group.add_child(title)
	_label(title, 30 if horizontal else 38)
	var benefit := Label.new()
	benefit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	benefit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(benefit)
	_label(benefit, 23, Art.BENEFIT, false)
	var curse := Label.new()
	curse.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	curse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(curse)
	_label(curse, 23, Art.CURSE, false)
	var stacking := Label.new()
	stacking.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stacking.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stacking)
	_label(stacking, 20, Art.MUTE, false)
	if not horizontal:
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		var hint := Label.new()
		hint.text = "HOVER OR FOCUS\nTO INSPECT GEAR"
		row.add_child(hint)
		_label(hint, 19, Art.MUTE, false)
	_details.append({"art":art,"title":title,"benefit":benefit,"curse":curse,"stacking":stacking,"horizontal":horizontal})
	return panel

func _definition(card_id: StringName) -> CardDefinition:
	for definition: CardDefinition in main.shop_manager.current_shop_cards:
		if definition.id == card_id: return definition
	return null

func _show_details(card_id: StringName) -> void:
	var definition := _definition(card_id)
	if not definition: return
	_selected_id = card_id
	for detail in _details:
		detail.art.texture = Art.item(card_id)
		detail.title.text = definition.name
		detail.benefit.text = "BENEFIT / RUN\n" + definition.bonus_description
		detail.curse.text = "CURSE / %d HOLES\n%s" % [definition.curse_duration_holes, definition.curse_description_for_multiplier(main.shop_manager.current_curse_strength_multiplier)]
		detail.stacking.text = definition.stacking_description
	# Newly added sample controls may initially be watched by UIAppearance's
	# deferred registration. Reclaim their explicit ink after that registration.
	for panel in [_detail_side,_detail_strip]:
		for label in panel.find_children("*","Label",true,false):
			_label(label,int(label.get_meta(&"reference_type_size",20)),label.get_meta(&"reference_type_color",Art.PALE),bool(label.get_meta(&"reference_type_display",false)))

func _style_card(card: UICard) -> void:
	_own(card)
	card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.custom_minimum_size = Vector2(220,676)
	card.name_label.custom_minimum_size.y = 68
	card.centerpiece_panel.custom_minimum_size.y = 144
	card.centerpiece_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.benefit_panel.custom_minimum_size.y = 100
	card.curse_panel.custom_minimum_size.y = 100
	card.stack_panel.custom_minimum_size.y = 36
	card.card_layout.add_theme_constant_override("separation", 6)
	var content: MarginContainer = card.get_node("CardContentMargin")
	for edge in ["left","right","top","bottom"]: content.add_theme_constant_override("margin_"+edge, 12)
	_button(card, false, 30)
	var rarity := _rarity_color(card.category_label.text)
	for state in ["normal","hover","pressed","disabled"]:
		var kind: String = "light_card" if _light() and state == "normal" else ("card" if state == "normal" else state)
		card.add_theme_stylebox_override(state, Art.frame(kind, Color.WHITE, 8.0))
	# Rarity is readable text plus a slim accent, never a large dyed art field.
	card.category_icon.hide()
	card.rarity_icon.hide()
	_label(card.category_label, 22, rarity.darkened(0.50) if _light() else rarity)
	if _light(): card.category_label.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
	var rarity_rule: ColorRect = card.get_node_or_null("ReferenceRarityRim")
	if not rarity_rule:
		rarity_rule = ColorRect.new()
		rarity_rule.name = "ReferenceRarityRim"
		rarity_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(rarity_rule)
		rarity_rule.set_anchors_preset(Control.PRESET_TOP_WIDE)
		rarity_rule.offset_left = 10
		rarity_rule.offset_right = -10
		rarity_rule.offset_top = 3
		rarity_rule.offset_bottom = 6
	rarity_rule.color = rarity
	_label(card.name_label, 34, Art.INK if _light() else Art.PALE)
	var definition := _definition(card.card_id)
	if definition: card.name_label.text = definition.name
	card.name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(card.price_label, 28, Art.GOLD)
	_label(card.stack_label, 19, Art.INK if _light() else Art.MUTE, false)
	_own(card.centerpiece_panel)
	card.centerpiece_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	_panel(card.benefit_panel, "benefit", 2.0)
	_panel(card.curse_panel, "curse", 2.0)
	_panel(card.stack_panel, "light_card" if _light() else "card", 1.0)
	_panel(card.card_layout.get_node("Header/PriceBadge"), "panel", 2.0)
	for panel in [card.benefit_panel,card.curse_panel]:
		var heading: Label = panel.get_node("Margin/Row/Copy/Heading")
		_label(heading, 20, Art.BENEFIT if panel == card.benefit_panel else Art.CURSE, false)
		var description: Label = panel.get_node("Margin/Row/Copy/Description")
		_label(description, 23, Art.PALE, false)
	for icon in card.find_children("*", "UIIcon", true, false):
		if icon != card.centerpiece_icon: icon.hide()
	card.centerpiece_icon.hide()
	var illustration: TextureRect = card.centerpiece_icon.get_parent().get_node_or_null("ReferenceIllustration")
	if not illustration:
		illustration = Art.picture(Art.item(card.card_id))
		illustration.name = "ReferenceIllustration"
		card.centerpiece_icon.get_parent().add_child(illustration)
	illustration.texture = Art.item(card.card_id)
	illustration.modulate.a = 0.64 if card.purchased else 1.0
	var buy: Button = card.card_layout.get_node_or_null("ReferenceBuy")
	if not buy:
		buy = Button.new()
		buy.name = "ReferenceBuy"
		buy.custom_minimum_size.y = 52
		buy.set_meta(&"suppress_ui_click_audio",true)
		buy.pressed.connect(func():
			if not card.disabled: card.pressed.emit())
		card.card_layout.add_child(buy)
		for control in [card,buy]:
			control.mouse_entered.connect(_select_card.bind(card, true))
			control.focus_entered.connect(_select_card.bind(card, true))
			control.mouse_exited.connect(_select_card.bind(card, false))
			control.focus_exited.connect(_select_card.bind(card, false))
		card.tree_exiting.connect(func(): _hover_tweens.erase(card.get_instance_id()))
	_button(buy, true, 42)
	buy.disabled = card.disabled
	buy.text = "BOUGHT" if card.purchased else "BUY  " + card.price_label.text
	if card.disabled and not card.purchased: buy.text = "SOLD OUT" if card.affordable else "NEED COINS"
	# The full text stays on the card even when its native purchase gate disables it.
	for badge in [card.purchased_badge,card.unavailable_badge]:
		_own(badge)
		badge.add_theme_stylebox_override("normal", Art.frame("panel",Color.WHITE,4.0))
		_label(badge, 23, Art.GOLD if badge == card.purchased_badge else Art.PALE)
	card.get_node("ReferenceFace").queue_redraw()

func _rarity_color(rarity: String) -> Color:
	match rarity.to_lower():
		"rare": return Color("a7d6ed")
		"epic": return Color("d9b1f3")
		"legendary": return Color("ffdc77")
	return Color("d4d1b5")

func _select_card(card: UICard, active: bool) -> void:
	if not is_instance_valid(card): return
	if active: _show_details(card.card_id)
	var art: Control = card.centerpiece_icon.get_parent().get_node_or_null("ReferenceIllustration")
	if not art: return
	var id := card.get_instance_id()
	if _hover_tweens.has(id) and _hover_tweens[id].is_valid(): _hover_tweens[id].kill()
	art.pivot_offset = art.size*0.5
	if main.feedback_director.reduced_motion:
		art.scale = Vector2.ONE
		return
	var tween := art.create_tween()
	tween.tween_property(art,"scale",Vector2.ONE*(1.04 if active else 1.0),0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tweens[id] = tween

func _card_bought(card: CardDefinition) -> void:
	_last_purchased = card.id
	_selected_id = card.id
	_update_item_rail(true)

func _purchase_feedback(kind: StringName) -> void:
	if kind != &"purchase" or main.run_state.tutorial_mode: return
	apply_shop()
	var target: UICard
	for card in main.shop_manager.shop_card_buttons:
		if card.card_id == _last_purchased: target = card
	if not target: return
	var stamp := Label.new()
	stamp.text = "BENEFIT ADDED  /  CURSE ACCEPTED"
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.add_theme_stylebox_override("normal",Art.frame("panel"))
	fx_layer.add_child(stamp)
	_label(stamp,26,Art.GOLD)
	stamp.size = Vector2(630,58)
	stamp.position = Vector2((main.get_viewport_rect().size.x-630)*0.5, main.get_viewport_rect().size.y-164)
	_effects.append(stamp)
	var tween := stamp.create_tween()
	if not main.feedback_director.reduced_motion:
		stamp.modulate.a = 0.0
		stamp.position.y += 8
		tween.tween_property(stamp,"modulate:a",1.0,0.08)
		tween.parallel().tween_property(stamp,"position:y",stamp.position.y-8,0.14)
	tween.tween_interval(0.66)
	tween.tween_property(stamp,"modulate:a",0.0,0.14)
	tween.tween_callback(stamp.queue_free)
	_effects = _effects.filter(func(effect): return is_instance_valid(effect))

func _clear_feedback() -> void:
	for effect in _effects:
		if is_instance_valid(effect): effect.queue_free()
	_effects.clear()

func _style_results(settle := true) -> void:
	if not main.interstitial_overlay: return
	if settle: _result_settle_frames = 3
	var presentation = main.transition_presentation
	if presentation.backdrop: presentation.backdrop.hide()
	var wash := StyleBoxFlat.new()
	wash.bg_color = Color(0.03,0.06,0.08,0.72)
	_own(main.interstitial_overlay)
	main.interstitial_overlay.add_theme_stylebox_override("panel",wash)
	for panel in main.interstitial_overlay.find_children("*","PanelContainer",true,false):
		_panel(panel,"panel",6.0)
	for label in main.interstitial_overlay.find_children("*","Label",true,false):
		var size: int = int(label.get_meta(&"reference_type_size",label.get_theme_font_size("font_size")))
		_label(label,maxi(size,20),Art.PALE,size>=26)
	_label(main.interstitial_title_label,78,Art.PALE)
	main.interstitial_title_label.custom_minimum_size.y = 140
	_label(main.interstitial_body_label,23,Art.PALE,false)
	_button(main.interstitial_continue_button,true,36)
	_button(main.interstitial_menu_button,false,28)
	for button in main.interstitial_overlay.find_children("*","Button",true,false):
		if button not in [main.interstitial_continue_button,main.interstitial_menu_button]: _button(button,false,24)
	if main.run_state.phase == RunState.Phase.HOLE_RESULTS:
		_style_hole_numbers()

func _style_hole_numbers() -> void:
	var presentation = main.transition_presentation
	_label(main.interstitial_title_label,122,Art.PALE)
	main.interstitial_title_label.custom_minimum_size.y = 158
	_label(presentation.eyebrow_label,23,Art.PALE,false)
	_label(presentation.identity_label,22,Art.PALE,false)
	# A small original rating star replaces the previous full vector medallion.
	presentation.hero_icon_stage.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	presentation.hero_icon_stage.custom_minimum_size = Vector2(112,112)
	presentation.hero_icon.custom_minimum_size = Vector2(112,112)
	_replace_icon(presentation.hero_icon,Art.texture("icons/star"))
	presentation.hero_column.move_child(main.interstitial_title_label,1)
	if presentation.history_selector:
		var history = presentation.history_selector
		presentation.hero_column.move_child(history,presentation.hero_column.get_child_count()-1)
		_label(history.heading,22,Art.PALE,false)
		_label(history.value_label,36,Art.PALE)
		_label(history.previous_label,24,Art.MUTE)
		_label(history.next_label,24,Art.MUTE)
	for icon in presentation.visual_details.find_children("*","UIIcon",true,false):
		if String(icon.name).begins_with("RatingStar"):
			_replace_icon(icon,Art.texture("icons/star"))
		else:
			icon.hide()
	for copy in presentation.visual_details.find_children("*","VBoxContainer",true,false):
		if copy.get_child_count() != 2 or not copy.get_child(0) is Label or not copy.get_child(1) is Label: continue
		var heading: Label = copy.get_child(0)
		var value: Label = copy.get_child(1)
		if heading.text not in ["STROKES","PAR","TO PAR","TIME","REWARD","WALLET"]: continue
		_label(heading,21,Art.MUTE,false)
		var prominent: bool = heading.text in ["STROKES","REWARD","WALLET"]
		_label(value,64 if prominent else 54,Art.GOLD if heading.text in ["REWARD","WALLET"] else Art.PALE)
		value.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		var panel: Control = copy.get_parent().get_parent().get_parent()
		panel.custom_minimum_size.y = 122

func _replace_icon(icon: Control, texture: Texture2D) -> void:
	icon.self_modulate.a = 0.0
	var picture: TextureRect = icon.get_node_or_null("ReferenceIcon")
	if not picture:
		picture = Art.picture(texture)
		picture.name = "ReferenceIcon"
		icon.add_child(picture)
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.texture = texture

func _style_utility() -> void:
	# Existing input, toggle states, persistence and descriptions remain native.
	for screen in [main.settings_screen,main.run_setup_screen]:
		if not screen: continue
		for panel in screen.find_children("*","PanelContainer",true,false):
			_panel(panel,"light" if _light() else "panel",8.0)
		for label in screen.find_children("*","Label",true,false):
			var size: int = int(label.get_meta(&"reference_type_size",label.get_theme_font_size("font_size")))
			_label(label,maxi(size,19),Art.INK if _light() else Art.PALE,size>=27)
		for button in screen.find_children("*","Button",true,false):
			_button(button,button is UIActionButton and button.variant==&"primary",26,true)
	var setup_screen = main.run_setup_screen
	for difficulty_id in setup_screen.difficulty_buttons:
		var selected: bool = difficulty_id == setup_screen.selected_difficulty_id
		var button: Button = setup_screen.difficulty_buttons[difficulty_id]
		button.add_theme_stylebox_override("normal",Art.frame("primary" if selected else ("light" if _light() else "panel")))
		button.get_node("ReferenceFace").queue_redraw()
	var parsed: Dictionary = SeedCodec.parse_optional_seed(setup_screen.seed_input.text)
	var status_color := Art.MUTE if setup_screen.seed_input.text.is_empty() else (Art.BENEFIT if bool(parsed.valid) else Art.CURSE)
	_label(setup_screen.seed_status_label,19,Art.INK if _light() and bool(parsed.valid) else status_color,false)
	var field: LineEdit = setup_screen.seed_input
	_own(field)
	field.add_theme_stylebox_override("normal",Art.frame("light_card" if _light() else "card"))
	field.add_theme_stylebox_override("focus",Art.frame("focus"))
	field.add_theme_font_override("font",Art.COPY_FONT)
	field.add_theme_font_size_override("font_size",22)
	field.add_theme_color_override("font_color",Art.INK if _light() else Art.PALE)
	field.add_theme_color_override("font_placeholder_color",Color("786e59") if _light() else Art.MUTE)

func _utility_opened(screen: Control) -> void:
	if screen.visible:
		_style_visible_utility.call_deferred(screen)

func _style_visible_utility(screen: Control) -> void:
	if is_instance_valid(screen) and screen.visible:
		_style_utility()
