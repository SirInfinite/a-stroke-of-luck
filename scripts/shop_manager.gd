class_name ShopManager
extends Node

signal card_bought(card: CardDefinition)
signal continued
signal feedback_requested(kind: StringName)

const CardDatabase := preload("res://scripts/card_database.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const UIIconScript := preload("res://scripts/ui/ui_icon.gd")
const UIBackdropScript := preload("res://scripts/ui/ui_backdrop.gd")
const UIActionButtonScript := preload("res://scripts/ui/ui_action_button.gd")
const UICardScript := preload("res://scripts/ui/ui_card.gd")

const SHOP_CARD_COUNT := 4
const MAX_PURCHASES_PER_VISIT := 2
@export_category("Shop Feedback")
@export_range(1.0, 1.08, 0.005) var hover_scale := 1.025
@export_range(0.01, 0.3, 0.01) var hover_duration := 0.08
@export_range(1.0, 1.12, 0.005) var purchase_pulse_scale := 1.05
@export_range(0.05, 0.6, 0.01) var purchase_pulse_duration := 0.28
@export_range(1.0, 1.2, 0.01) var coin_pulse_scale := 1.08
@export_range(0.05, 0.7, 0.01) var coin_feedback_duration := 0.3
@export_range(0.0, 0.5, 0.01) var curse_flash_intensity := 0.2
@export_range(0.05, 0.7, 0.01) var curse_flash_duration := 0.34

var shop_overlay: Control
var shop_title_label: Label
var shop_tokens_label: Label
var shop_purchase_label: Label
var shop_destination_label: Label
var shop_status_label: Label
var shop_curse_status_label: Label
var shop_card_buttons: Array[Button] = []
var continue_button: Button
var curse_warning_flash: ColorRect
var current_shop_cards: Array[CardDefinition] = []
var shop_visits := 0
var shop_intro_tween: Tween
var tokens := 0
var purchases_this_visit := 0
var minimum_purchases_this_visit := 0
var purchased_card_indices: Array[int] = []
var owned_card_ids: Array[StringName] = []
var _card_feedback_tweens: Dictionary = {}
var _coin_feedback_tween: Tween
var _curse_feedback_tween: Tween


func create_overlay(parent: CanvasLayer) -> void:
	shop_overlay = PanelContainer.new()
	shop_overlay.name = "ShopScreen"
	shop_overlay.visible = false
	shop_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(shop_overlay)
	shop_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var backdrop := UIBackdropScript.new()
	backdrop.name = "ShopBackdrop"
	backdrop.configure(&"shop", UIStyleScript.GOLD, UIStyleScript.INK_DEEP)
	shop_overlay.add_child(backdrop)

	var margin := MarginContainer.new()
	margin.name = "SafeArea"
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 22)
	shop_overlay.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "ShopLayout"
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.name = "ShopHeader"
	header.custom_minimum_size.y = 86.0
	header.add_theme_constant_override("separation", 18)
	layout.add_child(header)

	var title_icon_stage := PanelContainer.new()
	title_icon_stage.custom_minimum_size = Vector2(68.0, 68.0)
	title_icon_stage.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color("254c3e"), UIStyleScript.GOLD, 16, 3, 7))
	header.add_child(title_icon_stage)
	var title_icon_center := CenterContainer.new()
	title_icon_stage.add_child(title_icon_center)
	var title_icon := UIIconScript.new()
	title_icon.custom_minimum_size = Vector2(49.0, 49.0)
	title_icon.configure(&"shop", UIStyleScript.PAPER, UIStyleScript.GOLD)
	title_icon_center.add_child(title_icon)

	var title_copy := VBoxContainer.new()
	title_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	title_copy.add_theme_constant_override("separation", -3)
	header.add_child(title_copy)
	var eyebrow := Label.new()
	eyebrow.text = "GEAR  •  GAMBLE  •  GO LOW"
	UIStyleScript.apply_ui(eyebrow, 13, UIStyleScript.GOLD, true)
	title_copy.add_child(eyebrow)
	shop_title_label = Label.new()
	shop_title_label.text = "THE LUCKY CLUBHOUSE"
	UIStyleScript.apply_display(shop_title_label, 38, UIStyleScript.PAPER)
	title_copy.add_child(shop_title_label)

	var wallet_panel := PanelContainer.new()
	wallet_panel.custom_minimum_size = Vector2(270.0, 68.0)
	wallet_panel.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color("191f1d"), Color(UIStyleScript.GOLD, 0.72), 14, 2, 6))
	header.add_child(wallet_panel)
	var wallet_margin := MarginContainer.new()
	wallet_margin.add_theme_constant_override("margin_left", 13)
	wallet_margin.add_theme_constant_override("margin_top", 8)
	wallet_margin.add_theme_constant_override("margin_right", 13)
	wallet_margin.add_theme_constant_override("margin_bottom", 8)
	wallet_panel.add_child(wallet_margin)
	var wallet_row := HBoxContainer.new()
	wallet_row.add_theme_constant_override("separation", 9)
	wallet_margin.add_child(wallet_row)
	var wallet_icon := UIIconScript.new()
	wallet_icon.custom_minimum_size = Vector2(38.0, 38.0)
	wallet_icon.configure(&"coin", UIStyleScript.INK_DEEP, UIStyleScript.GOLD)
	wallet_row.add_child(wallet_icon)
	var wallet_copy := VBoxContainer.new()
	wallet_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wallet_copy.add_theme_constant_override("separation", -4)
	wallet_row.add_child(wallet_copy)
	shop_tokens_label = Label.new()
	UIStyleScript.apply_display(shop_tokens_label, 27, UIStyleScript.GOLD)
	wallet_copy.add_child(shop_tokens_label)
	shop_purchase_label = Label.new()
	UIStyleScript.apply_ui(shop_purchase_label, 12, UIStyleScript.PAPER_MUTED, true)
	wallet_copy.add_child(shop_purchase_label)

	shop_destination_label = Label.new()
	shop_destination_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shop_destination_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shop_destination_label.custom_minimum_size.x = 240.0
	UIStyleScript.apply_ui(shop_destination_label, 15, UIStyleScript.PAPER_MUTED, true)
	header.add_child(shop_destination_label)

	var cards_row := HBoxContainer.new()
	cards_row.name = "CardRow"
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_row.add_theme_constant_override("separation", 16)
	layout.add_child(cards_row)

	for i in range(SHOP_CARD_COUNT):
		var card_slot := Control.new()
		card_slot.name = "CardSlot%d" % (i + 1)
		card_slot.custom_minimum_size = Vector2(242.0, 438.0)
		card_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_slot.size_flags_stretch_ratio = 1.0
		cards_row.add_child(card_slot)

		var button := UICardScript.new()
		button.name = "CardButton%d" % (i + 1)
		card_slot.add_child(button)
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.pressed.connect(_on_shop_card_pressed.bind(i))
		button.mouse_entered.connect(_on_card_hovered.bind(button))
		button.mouse_exited.connect(_on_card_unhovered.bind(button))
		shop_card_buttons.append(button)

	var footer := HBoxContainer.new()
	footer.name = "ShopFooter"
	footer.custom_minimum_size.y = 66.0
	footer.add_theme_constant_override("separation", 18)
	layout.add_child(footer)
	shop_status_label = Label.new()
	shop_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyleScript.apply_display(shop_status_label, 22, UIStyleScript.PAPER)
	footer.add_child(shop_status_label)
	shop_curse_status_label = Label.new()
	shop_curse_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyleScript.apply_ui(shop_curse_status_label, 18, UIStyleScript.CURSE, true)
	footer.add_child(shop_curse_status_label)

	continue_button = UIActionButtonScript.new()
	continue_button.custom_minimum_size = Vector2(280.0, 58.0)
	continue_button.pressed.connect(_on_shop_continue_pressed)
	footer.add_child(continue_button)
	continue_button.configure("CONTINUE", &"continue", &"primary")

	curse_warning_flash = ColorRect.new()
	curse_warning_flash.name = "CurseWarningFlash"
	curse_warning_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curse_warning_flash.color = Color(0.85, 0.16, 0.13, 0.0)
	curse_warning_flash.visible = false
	shop_overlay.add_child(curse_warning_flash)
	curse_warning_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func show_shop(
	next_level_index: int,
	token_count: int,
	level_count: int,
	offer_seed: int,
	forced_card_names: Array[String] = [],
	next_destination: String = "",
	explicit_card_pool: Array[CardDefinition] = [],
	minimum_purchases: int = 0,
	existing_card_ids: Array[StringName] = []
) -> void:
	tokens = token_count
	purchases_this_visit = 0
	minimum_purchases_this_visit = clampi(minimum_purchases, 0, MAX_PURCHASES_PER_VISIT)
	purchased_card_indices.clear()
	owned_card_ids = existing_card_ids.duplicate()
	current_shop_cards.clear()
	var shop_cards: Array[CardDefinition] = explicit_card_pool.duplicate() if not explicit_card_pool.is_empty() else CardDatabase.get_cards()
	var available_cards: Array[CardDefinition] = shop_cards.duplicate()
	for card_name in forced_card_names:
		var forced_card := _card_by_name(card_name, available_cards)
		if forced_card != null and current_shop_cards.size() < SHOP_CARD_COUNT:
			current_shop_cards.append(forced_card)
			available_cards.erase(forced_card)

	var rng := RandomNumberGenerator.new()
	rng.seed = _shop_offer_seed(offer_seed, next_level_index, shop_visits)
	while current_shop_cards.size() < SHOP_CARD_COUNT and not available_cards.is_empty():
		var random_index := rng.randi_range(0, available_cards.size() - 1)
		current_shop_cards.append(available_cards.pop_at(random_index))

	shop_visits += 1
	var fallback_destination := "Hole %d/%d" % [next_level_index % level_count + 1, level_count]
	shop_destination_label.text = "NEXT TEE  •  %s" % [next_destination if next_destination != "" else fallback_destination]
	shop_overlay.visible = true
	_play_shop_intro_animation()
	_refresh_shop()
	_fit_overlay_to_viewport()
	call_deferred("_fit_overlay_to_viewport")
	call_deferred("_focus_first_choice")


func _fit_overlay_to_viewport() -> void:
	if shop_overlay:
		shop_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _focus_first_choice() -> void:
	for button in shop_card_buttons:
		if button.visible and not button.disabled:
			button.grab_focus()
			return
	if continue_button:
		continue_button.grab_focus()


func reset_for_new_run() -> void:
	_reset_feedback_state()
	shop_visits = 0
	tokens = 0
	purchases_this_visit = 0
	minimum_purchases_this_visit = 0
	purchased_card_indices.clear()
	owned_card_ids.clear()
	current_shop_cards.clear()
	if shop_overlay:
		shop_overlay.visible = false
		shop_overlay.position = Vector2.ZERO
		shop_overlay.modulate = Color.WHITE


func _play_shop_intro_animation() -> void:
	if shop_intro_tween:
		shop_intro_tween.kill()

	shop_overlay.position = Vector2.ZERO
	shop_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	shop_intro_tween = create_tween().set_parallel(true)
	shop_intro_tween.tween_property(shop_overlay, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for card_index in range(shop_card_buttons.size()):
		var card_button := shop_card_buttons[card_index]
		card_button.scale = Vector2.ONE
		card_button.position = Vector2(0.0, 12.0)
		card_button.modulate = Color(1.0, 1.0, 1.0, 0.0)
		shop_intro_tween.tween_property(card_button, "position", Vector2.ZERO, 0.24).set_delay(0.035 * card_index).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		shop_intro_tween.tween_property(card_button, "modulate", Color.WHITE, 0.16).set_delay(0.035 * card_index)


func _refresh_shop() -> void:
	shop_tokens_label.text = "%02d COINS" % tokens
	shop_purchase_label.text = "PURCHASES  %d / %d" % [purchases_this_visit, MAX_PURCHASES_PER_VISIT]
	var picks_left := MAX_PURCHASES_PER_VISIT - purchases_this_visit
	shop_status_label.text = "PICK UP TO %s" % ["ZERO", "ONE", "TWO"][picks_left]
	if minimum_purchases_this_visit > purchases_this_visit:
		shop_status_label.text = "PICK %s TO CONTINUE" % ["ZERO", "ONE", "TWO"][minimum_purchases_this_visit - purchases_this_visit]
	shop_curse_status_label.text = "" if purchases_this_visit == 0 else ("CURSE SELECTED" if purchases_this_visit == 1 else "CURSES SELECTED")
	if continue_button:
		continue_button.disabled = purchases_this_visit < minimum_purchases_this_visit
		continue_button.text = "BUY %d MORE" % (minimum_purchases_this_visit - purchases_this_visit) if continue_button.disabled else "CONTINUE"

	for i in range(shop_card_buttons.size()):
		var button := shop_card_buttons[i]
		if i >= current_shop_cards.size():
			button.visible = false
			continue
		button.visible = true
		var card := current_shop_cards[i]
		var cost := card.price
		var was_purchased := purchased_card_indices.has(i)
		var purchase_limit_reached := purchases_this_visit >= MAX_PURCHASES_PER_VISIT and not was_purchased
		button.disabled = tokens < cost or was_purchased or purchase_limit_reached
		var card_view := button as UICard
		if card_view:
			card_view.configure_card(card, tokens >= cost, was_purchased, owned_card_ids.count(card.id))
			card_view.set_card_state(tokens >= cost, was_purchased, purchase_limit_reached)


func _on_shop_card_pressed(card_index: int) -> void:
	if card_index < 0 or card_index >= current_shop_cards.size():
		feedback_requested.emit(&"error")
		return
	if purchased_card_indices.has(card_index) or purchases_this_visit >= MAX_PURCHASES_PER_VISIT:
		feedback_requested.emit(&"error")
		return

	var card := current_shop_cards[card_index]
	var cost := card.price
	if tokens < cost:
		feedback_requested.emit(&"error")
		return

	tokens -= cost
	purchases_this_visit += 1
	purchased_card_indices.append(card_index)
	owned_card_ids.append(card.id)
	card_bought.emit(card)
	_refresh_shop()
	_play_purchase_feedback(card_index)
	feedback_requested.emit(&"purchase")


func _on_shop_continue_pressed() -> void:
	if purchases_this_visit < minimum_purchases_this_visit:
		feedback_requested.emit(&"error")
		return
	_reset_feedback_state()
	shop_overlay.position = Vector2.ZERO
	shop_overlay.modulate = Color.WHITE
	shop_overlay.visible = false
	continued.emit()


func _on_card_hovered(button: Button) -> void:
	if button.disabled:
		return
	_play_card_scale(button, Vector2.ONE * hover_scale, hover_duration)


func _on_card_unhovered(button: Button) -> void:
	_play_card_scale(button, Vector2.ONE, hover_duration)


func _play_card_scale(button: Button, target_scale: Vector2, duration: float) -> void:
	if _card_feedback_tweens.has(button):
		var active_tween := _card_feedback_tweens[button] as Tween
		if active_tween:
			active_tween.kill()
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	_card_feedback_tweens[button] = tween
	tween.tween_property(button, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_purchase_feedback(card_index: int) -> void:
	if card_index >= 0 and card_index < shop_card_buttons.size():
		var button := shop_card_buttons[card_index]
		button.pivot_offset = button.size * 0.5
		if _card_feedback_tweens.has(button):
			var active_tween := _card_feedback_tweens[button] as Tween
			if active_tween:
				active_tween.kill()
		var card_tween := create_tween()
		_card_feedback_tweens[button] = card_tween
		card_tween.tween_property(button, "scale", Vector2.ONE * purchase_pulse_scale, purchase_pulse_duration * 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card_tween.tween_property(button, "scale", Vector2.ONE, purchase_pulse_duration * 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if _coin_feedback_tween:
		_coin_feedback_tween.kill()
	shop_tokens_label.pivot_offset = shop_tokens_label.size * 0.5
	shop_tokens_label.scale = Vector2.ONE
	shop_tokens_label.modulate = Color("e2b84b")
	_coin_feedback_tween = create_tween().set_parallel(true)
	_coin_feedback_tween.tween_property(shop_tokens_label, "scale", Vector2.ONE * coin_pulse_scale, coin_feedback_duration * 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_coin_feedback_tween.tween_property(shop_tokens_label, "modulate", Color.WHITE, coin_feedback_duration)
	_coin_feedback_tween.chain().tween_property(shop_tokens_label, "scale", Vector2.ONE, coin_feedback_duration * 0.55)

	if _curse_feedback_tween:
		_curse_feedback_tween.kill()
	curse_warning_flash.visible = true
	curse_warning_flash.color.a = 0.0
	_curse_feedback_tween = create_tween()
	_curse_feedback_tween.tween_property(curse_warning_flash, "color:a", curse_flash_intensity, curse_flash_duration * 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_curse_feedback_tween.tween_property(curse_warning_flash, "color:a", 0.0, curse_flash_duration * 0.68).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_curse_feedback_tween.tween_callback(func(): curse_warning_flash.visible = false)


func _reset_feedback_state() -> void:
	if shop_intro_tween:
		shop_intro_tween.kill()
		shop_intro_tween = null
	if _coin_feedback_tween:
		_coin_feedback_tween.kill()
		_coin_feedback_tween = null
	if _curse_feedback_tween:
		_curse_feedback_tween.kill()
		_curse_feedback_tween = null
	for tween in _card_feedback_tweens.values():
		if tween:
			tween.kill()
	_card_feedback_tweens.clear()
	for button in shop_card_buttons:
		button.scale = Vector2.ONE
		button.position = Vector2.ZERO
		button.modulate = Color.WHITE
	if shop_tokens_label:
		shop_tokens_label.scale = Vector2.ONE
		shop_tokens_label.modulate = Color.WHITE
	if curse_warning_flash:
		curse_warning_flash.visible = false
		curse_warning_flash.color.a = 0.0


func _card_by_name(card_name: String, cards: Array[CardDefinition]) -> CardDefinition:
	for card in cards:
		if card.name == card_name:
			return card
	return null


func _shop_offer_seed(offer_seed: int, next_level_index: int, visit_index: int) -> int:
	return maxi(absi(offer_seed + (next_level_index + 1) * 10007 + (visit_index + 1) * 1000003), 1)
