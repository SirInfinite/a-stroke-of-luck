class_name ShopManager
extends Node

signal card_bought(card: CardDefinition)
signal continued
signal feedback_requested(kind: StringName)

const CardDatabase := preload("res://scripts/card_database.gd")
const Rarities := preload("res://scripts/card_rarity_profile.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const UIIconScript := preload("res://scripts/ui/ui_icon.gd")
const UIBackdropScript := preload("res://scripts/ui/ui_backdrop.gd")
const UIActionButtonScript := preload("res://scripts/ui/ui_action_button.gd")
const UICardScript := preload("res://scripts/ui/ui_card.gd")

const MIN_SHOP_CARD_COUNT := 4
const MAX_SHOP_CARD_COUNT := 6
const DEFAULT_SHOP_CARD_COUNT := 4
const DEFAULT_MAX_PURCHASES_PER_VISIT := 2
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
var shop_card_slots: Array[Control] = []
var shop_card_rows: Array[HBoxContainer] = []
var continue_button: Button
var curse_warning_flash: ColorRect
var current_shop_cards: Array[CardDefinition] = []
var shop_visits := 0
var shop_intro_tween: Tween
var _run_state: RunState
var _standalone_tokens := 0
var tokens: int:
	get: return _run_state.tokens if _run_state else _standalone_tokens
	set(value):
		if _run_state:
			_run_state.tokens = value
		else:
			_standalone_tokens = value
var purchases_this_visit := 0
var minimum_purchases_this_visit := 0
var purchased_card_indices: Array[int] = []
var owned_card_ids: Array[StringName] = []
var current_offer_count := DEFAULT_SHOP_CARD_COUNT
var current_max_purchases := DEFAULT_MAX_PURCHASES_PER_VISIT
var current_curse_strength_multiplier := 1.0
var shared_course_mode := false
var _card_feedback_tweens: Dictionary = {}
var _coin_feedback_tween: Tween
var _curse_feedback_tween: Tween
var presentation: Node


func bind_run_state(state: RunState) -> void:
	_run_state = state


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
	wallet_icon.configure(&"coin", UIStyleScript.GOLD, UIStyleScript.GOLD)
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

	var body := HBoxContainer.new()
	body.name = "ShopBody"
	body.add_theme_constant_override("separation", 22)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	var cards_layout := VBoxContainer.new()
	cards_layout.name = "CardRows"
	cards_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_layout.add_theme_constant_override("separation", 10)
	cards_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(cards_layout)
	for row_index in range(2):
		var cards_row := HBoxContainer.new()
		cards_row.name = "CardRow%d" % (row_index + 1)
		cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
		cards_row.size_flags_vertical = Control.SIZE_FILL
		cards_row.add_theme_constant_override("separation", 16)
		cards_layout.add_child(cards_row)
		shop_card_rows.append(cards_row)

	for i in range(MAX_SHOP_CARD_COUNT):
		var card_slot := Control.new()
		card_slot.name = "CardSlot%d" % (i + 1)
		card_slot.custom_minimum_size = Vector2(242.0, 438.0)
		card_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_slot.size_flags_stretch_ratio = 1.0
		shop_card_rows[0].add_child(card_slot)
		shop_card_slots.append(card_slot)

		var button := UICardScript.new()
		button.name = "CardButton%d" % (i + 1)
		card_slot.add_child(button)
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# A card's initial minimum height can exceed an unlaid-out slot and
		# become a persistent bottom offset. Refit after container layout.
		card_slot.resized.connect(button.set_anchors_and_offsets_preset.bind(Control.PRESET_FULL_RECT))
		button.pressed.connect(_on_shop_card_pressed.bind(i))
		button.mouse_entered.connect(_on_card_hovered.bind(button))
		button.mouse_exited.connect(_on_card_unhovered.bind(button))
		button.focus_entered.connect(_on_card_hovered.bind(button))
		button.focus_exited.connect(_on_card_unhovered.bind(button))
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
	existing_card_ids: Array[StringName] = [],
	offer_count := DEFAULT_SHOP_CARD_COUNT,
	max_purchases := DEFAULT_MAX_PURCHASES_PER_VISIT,
	curse_strength_multiplier := 1.0
) -> void:
	current_offer_count = clampi(offer_count, MIN_SHOP_CARD_COUNT, MAX_SHOP_CARD_COUNT)
	current_max_purchases = clampi(max_purchases, 1, current_offer_count)
	current_curse_strength_multiplier = clampf(curse_strength_multiplier, 1.0, 1.75)
	tokens = token_count
	purchases_this_visit = 0
	minimum_purchases_this_visit = clampi(minimum_purchases, 0, current_max_purchases)
	purchased_card_indices.clear()
	owned_card_ids = existing_card_ids.duplicate()
	current_shop_cards.clear()
	var shop_cards: Array[CardDefinition] = explicit_card_pool.duplicate() if not explicit_card_pool.is_empty() else CardDatabase.get_cards()
	var available_cards: Array[CardDefinition] = shop_cards.duplicate()
	for card_name in forced_card_names:
		var forced_card := _card_by_name(card_name, available_cards)
		if forced_card != null and current_shop_cards.size() < current_offer_count:
			current_shop_cards.append(forced_card)
			available_cards.erase(forced_card)

	var rng := RandomNumberGenerator.new()
	rng.seed = _shop_offer_seed(offer_seed, next_level_index, shop_visits)
	while current_shop_cards.size() < current_offer_count and not available_cards.is_empty():
		var random_index := rng.randi_range(0, available_cards.size() - 1)
		current_shop_cards.append(available_cards.pop_at(random_index))
	if explicit_card_pool.is_empty():
		# Separate stream: rarity draws never perturb the base-card selection order.
		var rarity_rng := RandomNumberGenerator.new()
		rarity_rng.seed = ("rarity/v1/%d" % _shop_offer_seed(offer_seed, next_level_index, shop_visits)).hash()
		var difficulty := _run_state.difficulty_profile.id if _run_state and _run_state.difficulty_profile else &"normal"
		for index in range(current_shop_cards.size()):
			current_shop_cards[index] = Rarities.create(current_shop_cards[index], Rarities.roll(rarity_rng, difficulty))

	shop_visits += 1
	var fallback_destination := "Hole %d/%d" % [next_level_index % level_count + 1, level_count]
	shop_destination_label.text = "NEXT TEE  •  %s" % [next_destination if next_destination != "" else fallback_destination]
	shop_overlay.visible = true
	_configure_card_layout()
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
	_standalone_tokens = 0
	purchases_this_visit = 0
	minimum_purchases_this_visit = 0
	purchased_card_indices.clear()
	owned_card_ids.clear()
	current_shop_cards.clear()
	current_offer_count = DEFAULT_SHOP_CARD_COUNT
	current_max_purchases = DEFAULT_MAX_PURCHASES_PER_VISIT
	current_curse_strength_multiplier = 1.0
	if shop_overlay:
		shop_overlay.visible = false
		shop_overlay.position = Vector2.ZERO
		shop_overlay.modulate = Color.WHITE


func _play_shop_intro_animation() -> void:
	if shop_intro_tween:
		shop_intro_tween.kill()

	shop_overlay.position = Vector2.ZERO
	if not UIStyleScript.motion_enabled(shop_overlay):
		shop_overlay.modulate = Color.WHITE
		for card_button in shop_card_buttons:
			card_button.scale = Vector2.ONE
			card_button.position = Vector2.ZERO
			card_button.modulate = Color.WHITE
		return
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
	shop_purchase_label.text = "PURCHASES  %d / %d" % [purchases_this_visit, current_max_purchases]
	var picks_left := current_max_purchases - purchases_this_visit
	shop_status_label.text = "PICK UP TO %s" % _count_word(picks_left)
	if minimum_purchases_this_visit > purchases_this_visit:
		shop_status_label.text = "PICK %s TO CONTINUE" % _count_word(minimum_purchases_this_visit - purchases_this_visit)
	shop_curse_status_label.text = "" if purchases_this_visit == 0 else ("CURSE SELECTED" if purchases_this_visit == 1 else "CURSES SELECTED")
	if continue_button:
		continue_button.disabled = purchases_this_visit < minimum_purchases_this_visit
		continue_button.text = "BUY %d MORE" % (minimum_purchases_this_visit - purchases_this_visit) if continue_button.disabled else "CONTINUE"

	for i in range(shop_card_buttons.size()):
		var button := shop_card_buttons[i]
		if i >= current_shop_cards.size():
			button.visible = false
			button.disabled = true
			continue
		button.visible = true
		var card := current_shop_cards[i]
		var cost := card.price
		var was_purchased := purchased_card_indices.has(i)
		var purchase_limit_reached := purchases_this_visit >= current_max_purchases and not was_purchased
		button.disabled = tokens < cost or was_purchased or purchase_limit_reached
		var card_view := button as UICard
		if card_view:
			card_view.configure_card(
				card,
				tokens >= cost,
				was_purchased,
				owned_card_ids.count(card.id),
				current_curse_strength_multiplier,
				shared_course_mode
			)
			card_view.set_card_state(tokens >= cost, was_purchased, purchase_limit_reached)
	if presentation:
		presentation.refresh_offers()


func _on_shop_card_pressed(card_index: int) -> void:
	if not shop_overlay or not shop_overlay.visible:
		return
	if not try_purchase_card(card_index):
		feedback_requested.emit(&"error")
		return
	_refresh_shop()
	_play_purchase_feedback(card_index)
	feedback_requested.emit(&"purchase")


func try_purchase_card(card_index: int) -> bool:
	# Shared transaction for UI and AI; presentation is owned by the caller.
	if card_index < 0 or card_index >= current_shop_cards.size():
		return false
	if purchased_card_indices.has(card_index) or purchases_this_visit >= current_max_purchases:
		return false

	var card := current_shop_cards[card_index]
	var cost := card.price
	if tokens < cost:
		return false

	tokens -= cost
	purchases_this_visit += 1
	purchased_card_indices.append(card_index)
	owned_card_ids.append(card.id)
	card_bought.emit(card)
	return true


func _on_shop_continue_pressed() -> void:
	if not shop_overlay or not shop_overlay.visible:
		return
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
	if not UIStyleScript.motion_enabled(shop_overlay):
		button.scale = Vector2.ONE
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	_card_feedback_tweens[button] = tween
	tween.tween_property(button, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_purchase_feedback(card_index: int) -> void:
	if not UIStyleScript.motion_enabled(shop_overlay):
		return
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


func _configure_card_layout() -> void:
	for row_index in range(shop_card_rows.size()):
		shop_card_rows[row_index].visible = row_index == 0
		shop_card_rows[row_index].size_flags_vertical = Control.SIZE_EXPAND_FILL
		shop_card_rows[row_index].add_theme_constant_override("separation", 12)
	for index in range(shop_card_slots.size()):
		var slot := shop_card_slots[index]
		var target_row := shop_card_rows[0]
		if slot.get_parent() != target_row:
			slot.reparent(target_row)
		slot.visible = index < current_offer_count
		slot.custom_minimum_size = Vector2(220.0, 676.0)
		var card_view := shop_card_buttons[index] as UICard
		if card_view:
			card_view.set_compact_layout(false)
	if presentation:
		presentation.refresh_layout()


func _count_word(count: int) -> String:
	var words := ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX"]
	return words[clampi(count, 0, words.size() - 1)]


func _card_by_name(card_name: String, cards: Array[CardDefinition]) -> CardDefinition:
	for card in cards:
		if card.name == card_name:
			return card
	return null


func _shop_offer_seed(offer_seed: int, next_level_index: int, visit_index: int) -> int:
	return maxi(absi(offer_seed + (next_level_index + 1) * 10007 + (visit_index + 1) * 1000003), 1)
