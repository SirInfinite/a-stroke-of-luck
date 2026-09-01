class_name ShopManager
extends Node

signal card_bought(card: CardDefinition)
signal continued
signal feedback_requested(kind: StringName)

const CardDatabase := preload("res://scripts/card_database.gd")

const SHOP_CARD_COUNT := 4
const MAX_PURCHASES_PER_VISIT := 2
const SHOP_BOUNCE_START_OFFSET := Vector2(0.0, 150.0)
const SHOP_BOUNCE_OVERSHOOT_OFFSET := Vector2(0.0, -34.0)
const SHOP_BOUNCE_RISE_DURATION := 0.2
const SHOP_BOUNCE_SETTLE_DURATION := 0.45

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
var shop_destination_label: Label
var shop_status_label: Label
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
var _card_feedback_tweens: Dictionary = {}
var _coin_feedback_tween: Tween
var _curse_feedback_tween: Tween


func create_overlay(parent: CanvasLayer) -> void:
	shop_overlay = PanelContainer.new()
	shop_overlay.name = "ShopScreen"
	shop_overlay.visible = false
	shop_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(shop_overlay)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 40)
	shop_overlay.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	shop_title_label = Label.new()
	shop_title_label.text = "Shop"
	shop_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_title_label.add_theme_font_size_override("font_size", 34)
	layout.add_child(shop_title_label)

	shop_tokens_label = Label.new()
	shop_tokens_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_tokens_label.add_theme_font_size_override("font_size", 20)
	layout.add_child(shop_tokens_label)

	shop_destination_label = Label.new()
	shop_destination_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_destination_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(shop_destination_label)

	var cards_row := HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 14)
	layout.add_child(cards_row)

	for i in range(SHOP_CARD_COUNT):
		var card_slot := Control.new()
		card_slot.name = "CardSlot%d" % (i + 1)
		card_slot.custom_minimum_size = Vector2(220, 390)
		cards_row.add_child(card_slot)

		var button := Button.new()
		button.name = "CardButton%d" % (i + 1)
		button.custom_minimum_size = Vector2(220, 390)
		card_slot.add_child(button)
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_theme_font_size_override("font_size", 16)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.set_meta(&"suppress_ui_click_audio", true)
		button.pressed.connect(_on_shop_card_pressed.bind(i))
		button.mouse_entered.connect(_on_card_hovered.bind(button))
		button.mouse_exited.connect(_on_card_unhovered.bind(button))
		shop_card_buttons.append(button)

	shop_status_label = Label.new()
	shop_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_status_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(shop_status_label)

	continue_button = Button.new()
	continue_button.text = "Skip / Continue"
	continue_button.custom_minimum_size = Vector2(260, 46)
	continue_button.pressed.connect(_on_shop_continue_pressed)
	layout.add_child(continue_button)

	curse_warning_flash = ColorRect.new()
	curse_warning_flash.name = "CurseWarningFlash"
	curse_warning_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	curse_warning_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curse_warning_flash.color = Color(0.85, 0.16, 0.13, 0.0)
	curse_warning_flash.visible = false
	shop_overlay.add_child(curse_warning_flash)


func show_shop(
	next_level_index: int,
	token_count: int,
	level_count: int,
	offer_seed: int,
	forced_card_names: Array[String] = [],
	next_destination: String = "",
	explicit_card_pool: Array[CardDefinition] = [],
	minimum_purchases: int = 0
) -> void:
	tokens = token_count
	purchases_this_visit = 0
	minimum_purchases_this_visit = clampi(minimum_purchases, 0, MAX_PURCHASES_PER_VISIT)
	purchased_card_indices.clear()
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
	shop_destination_label.text = "Next: %s" % [next_destination if next_destination != "" else fallback_destination]
	shop_status_label.text = (
		"Choose at least %d card%s to continue." % [minimum_purchases_this_visit, "" if minimum_purchases_this_visit == 1 else "s"]
		if minimum_purchases_this_visit > 0
		else "Choose up to two cards, or use Skip / Continue."
	)
	shop_overlay.visible = true
	_play_shop_intro_animation()
	_refresh_shop()
	continue_button.grab_focus()


func reset_for_new_run() -> void:
	_reset_feedback_state()
	shop_visits = 0
	tokens = 0
	purchases_this_visit = 0
	minimum_purchases_this_visit = 0
	purchased_card_indices.clear()
	current_shop_cards.clear()
	if shop_overlay:
		shop_overlay.visible = false
		shop_overlay.position = Vector2.ZERO
		shop_overlay.modulate = Color.WHITE


func _play_shop_intro_animation() -> void:
	if shop_intro_tween:
		shop_intro_tween.kill()

	shop_overlay.position = SHOP_BOUNCE_START_OFFSET
	shop_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)

	shop_intro_tween = create_tween()
	shop_intro_tween.tween_property(shop_overlay, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	shop_intro_tween.parallel().tween_property(shop_overlay, "position", SHOP_BOUNCE_OVERSHOOT_OFFSET, SHOP_BOUNCE_RISE_DURATION).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	shop_intro_tween.chain().tween_property(shop_overlay, "position", Vector2.ZERO, SHOP_BOUNCE_SETTLE_DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _refresh_shop() -> void:
	shop_tokens_label.text = "Coins: %d   Purchases: %d/%d" % [tokens, purchases_this_visit, MAX_PURCHASES_PER_VISIT]
	if continue_button:
		continue_button.disabled = purchases_this_visit < minimum_purchases_this_visit
		continue_button.text = "Buy %d More to Continue" % (minimum_purchases_this_visit - purchases_this_visit) if continue_button.disabled else "Skip / Continue"

	for i in range(shop_card_buttons.size()):
		var button := shop_card_buttons[i]
		if i >= current_shop_cards.size():
			button.visible = false
			continue
		button.visible = true
		var card := current_shop_cards[i]
		var cost := card.price
		var purchase_status := "\n\nPURCHASED" if purchased_card_indices.has(i) else ""
		button.text = "%s\nCost: %d coins\n\nBONUS — RUN\n%s\n\nCURSE — NEXT 3 HOLES\n%s\n\nSTACKS\n%s%s" % [
			card.name,
			cost,
			card.bonus_description,
			card.curse_description,
			card.stacking_description,
			purchase_status
		]
		button.disabled = tokens < cost or purchased_card_indices.has(i) or purchases_this_visit >= MAX_PURCHASES_PER_VISIT


func _on_shop_card_pressed(card_index: int) -> void:
	if card_index < 0 or card_index >= current_shop_cards.size():
		feedback_requested.emit(&"error")
		return
	if purchased_card_indices.has(card_index) or purchases_this_visit >= MAX_PURCHASES_PER_VISIT:
		shop_status_label.text = "This shop allows at most two distinct purchases."
		feedback_requested.emit(&"error")
		return

	var card := current_shop_cards[card_index]
	var cost := card.price
	if tokens < cost:
		shop_status_label.text = "Not enough coins for %s." % card.name
		feedback_requested.emit(&"error")
		return

	tokens -= cost
	purchases_this_visit += 1
	purchased_card_indices.append(card_index)
	card_bought.emit(card)
	shop_status_label.text = "Bought %s: run bonus active; 3-hole curse accepted. %d purchase%s remaining." % [
		card.name,
		MAX_PURCHASES_PER_VISIT - purchases_this_visit,
		"" if MAX_PURCHASES_PER_VISIT - purchases_this_visit == 1 else "s"
	]
	_refresh_shop()
	_play_purchase_feedback(card_index)
	feedback_requested.emit(&"purchase")


func _on_shop_continue_pressed() -> void:
	if purchases_this_visit < minimum_purchases_this_visit:
		shop_status_label.text = "Purchase at least %d card%s before continuing." % [
			minimum_purchases_this_visit,
			"" if minimum_purchases_this_visit == 1 else "s",
		]
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
