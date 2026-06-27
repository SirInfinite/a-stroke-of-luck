class_name ShopManager
extends Node

signal card_bought(card: Dictionary)
signal continued

const CardDatabase := preload("res://scripts/card_database.gd")

const SHOP_CARD_COUNT := 3
const SHOP_BOUNCE_START_OFFSET := Vector2(0.0, 150.0)
const SHOP_BOUNCE_OVERSHOOT_OFFSET := Vector2(0.0, -34.0)
const SHOP_BOUNCE_RISE_DURATION := 0.2
const SHOP_BOUNCE_SETTLE_DURATION := 0.45

var shop_overlay: Control
var shop_tokens_label: Label
var shop_status_label: Label
var shop_card_buttons: Array[Button] = []
var current_shop_cards: Array[Dictionary] = []
var shop_visits := 0
var shop_intro_tween: Tween
var tokens := 0


func create_overlay(parent: CanvasLayer) -> void:
	shop_overlay = PanelContainer.new()
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

	var title := Label.new()
	title.text = "Clubhouse Shop"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	layout.add_child(title)

	shop_tokens_label = Label.new()
	shop_tokens_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_tokens_label.add_theme_font_size_override("font_size", 20)
	layout.add_child(shop_tokens_label)

	var cards_row := HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 14)
	layout.add_child(cards_row)

	for i in range(SHOP_CARD_COUNT):
		var button := Button.new()
		button.custom_minimum_size = Vector2(220, 210)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_shop_card_pressed.bind(i))
		cards_row.add_child(button)
		shop_card_buttons.append(button)

	shop_status_label = Label.new()
	shop_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_status_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(shop_status_label)

	var continue_button := Button.new()
	continue_button.text = "Continue to Next Hole"
	continue_button.custom_minimum_size = Vector2(260, 46)
	continue_button.pressed.connect(_on_shop_continue_pressed)
	layout.add_child(continue_button)


func show_shop(next_level_index: int, token_count: int, level_count: int) -> void:
	tokens = token_count
	current_shop_cards.clear()
	var shop_cards := CardDatabase.get_cards()
	for i in range(SHOP_CARD_COUNT):
		var card_index := (shop_visits * 2 + i) % shop_cards.size()
		current_shop_cards.append(shop_cards[card_index])

	shop_visits += 1
	shop_status_label.text = "Buy any cards you can afford, or continue to hole %d." % [next_level_index % level_count + 1]
	shop_overlay.visible = true
	_play_shop_intro_animation()
	_refresh_shop()


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
	shop_tokens_label.text = "Tokens: %d" % tokens

	for i in range(shop_card_buttons.size()):
		var button := shop_card_buttons[i]
		var card := current_shop_cards[i]
		var cost: int = card.cost
		button.text = "%s\nCost: %d tokens\n\nPower: %s\nDownside: %s" % [
			card.name,
			cost,
			card.upside,
			card.downside
		]
		button.disabled = tokens < cost


func _on_shop_card_pressed(card_index: int) -> void:
	if card_index < 0 or card_index >= current_shop_cards.size():
		return

	var card := current_shop_cards[card_index]
	var cost: int = card.cost
	if tokens < cost:
		shop_status_label.text = "Not enough tokens for %s." % card.name
		return

	tokens -= cost
	card_bought.emit(card)
	shop_status_label.text = "Bought %s." % card.name
	_refresh_shop()


func _on_shop_continue_pressed() -> void:
	if shop_intro_tween:
		shop_intro_tween.kill()
		shop_intro_tween = null
	shop_overlay.position = Vector2.ZERO
	shop_overlay.modulate = Color.WHITE
	shop_overlay.visible = false
	continued.emit()
