extends GutTest

const ShopManagerScript := preload("res://scripts/shop_manager.gd")
const TutorialDatabaseScript := preload("res://scripts/tutorial_database.gd")
const ShopPresentationScript := preload("res://scripts/shop_presentation.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")


func test_shop_has_four_unique_seeded_offers() -> void:
	var shop = _spawn_shop()
	shop.show_shop(3, 20, 18, 424242)
	var first_ids := _offer_ids(shop)

	assert_eq(first_ids.size(), 4)
	assert_eq(_unique_count(first_ids), 4)
	for button_index in range(shop.current_shop_cards.size()):
		var card_view := shop.shop_card_buttons[button_index] as UICard
		assert_not_null(card_view)
		assert_eq(card_view.card_id, shop.current_shop_cards[button_index].id)
		assert_false(card_view.benefit_description.text.is_empty())
		assert_false(card_view.curse_description.text.is_empty())
		assert_true(card_view.stack_label.text.contains("STACKS"))
		assert_true(card_view.stack_label.text.contains("×0"))
		assert_not_null(card_view.stack_panel)
	assert_eq(shop.shop_status_label.text, "PICK UP TO TWO")
	assert_eq(shop.shop_curse_status_label.text, "")

	shop.reset_for_new_run()
	shop.show_shop(3, 20, 18, 424242)
	assert_eq(_offer_ids(shop), first_ids)

	shop.reset_for_new_run()
	shop.show_shop(3, 20, 18, 424243)
	assert_ne(_offer_ids(shop), first_ids)


func test_unaffordable_offers_are_disabled_but_skip_always_works() -> void:
	var shop = _spawn_shop()
	watch_signals(shop)
	shop.show_shop(3, 0, 18, 1234)

	for button in shop.shop_card_buttons:
		if not button.visible:
			continue
		assert_true(button.disabled)
	shop._on_shop_card_pressed(0)
	assert_signal_emitted_with_parameters(shop, "feedback_requested", [&"error"])
	assert_false(shop.continue_button.disabled)
	shop._on_shop_continue_pressed()
	assert_signal_emitted(shop, "continued")


func test_shop_accepts_at_most_two_purchases() -> void:
	var shop = _spawn_shop()
	shop.show_shop(3, 99, 18, 999)

	shop._on_shop_card_pressed(0)
	assert_eq(shop.shop_status_label.text, "PICK UP TO ONE")
	assert_eq(shop.shop_curse_status_label.text, "CURSE SELECTED")
	shop._on_shop_card_pressed(1)
	var tokens_after_two: int = shop.tokens
	shop._on_shop_card_pressed(2)

	assert_eq(shop.purchases_this_visit, 2)
	assert_eq(shop.tokens, tokens_after_two)
	assert_eq(shop.shop_status_label.text, "PICK UP TO ZERO")
	assert_eq(shop.shop_curse_status_label.text, "CURSES SELECTED")
	for button in shop.shop_card_buttons:
		if not button.visible:
			continue
		assert_true(button.disabled)
	assert_false(shop.continue_button.disabled)


func test_purchase_plays_card_coin_and_curse_feedback() -> void:
	var shop = _spawn_shop()
	watch_signals(shop)
	shop.show_shop(3, 99, 18, 999)

	shop._on_shop_card_pressed(0)

	assert_signal_emitted_with_parameters(shop, "feedback_requested", [&"purchase"])
	assert_true(shop.curse_warning_flash.visible)
	assert_eq(shop.shop_tokens_label.modulate, Color("e2b84b"))
	assert_gt(shop.shop_card_buttons[0].scale.x, 0.0)


func test_affordable_card_hover_scales_and_resets() -> void:
	var shop = _spawn_shop()
	shop.show_shop(3, 99, 18, 999)
	# Containers reset child scale when first arranging newly visible controls.
	# Exercise the hover on the settled shop, as a player sees it, while keeping
	# the existing duration, target and tolerance assertions unchanged.
	await get_tree().process_frame
	await get_tree().process_frame
	var button: Button = null
	for candidate in shop.shop_card_buttons:
		if not candidate.disabled:
			button = candidate
			break
	assert_not_null(button, "The seeded shop must contain an affordable card for the hover test.")
	if button == null:
		return

	shop._on_card_hovered(button)
	await wait_seconds(shop.hover_duration + 0.03)
	assert_almost_eq(button.scale.x, shop.hover_scale, 0.005)
	shop._on_card_unhovered(button)
	await wait_seconds(shop.hover_duration + 0.03)
	assert_almost_eq(button.scale.x, 1.0, 0.01)


func test_forced_tutorial_cards_fill_to_four_without_blocking_continue() -> void:
	var shop = _spawn_shop()
	var forced: Array[String] = ["Overdrive Driver", "Rangefinder Lens", "Heavy Core"]
	shop.show_shop(1, 3, 10, 77, forced)

	assert_eq(shop.current_shop_cards.size(), 4)
	assert_eq(shop.current_shop_cards[0].name, forced[0])
	assert_eq(shop.current_shop_cards[1].name, forced[1])
	assert_eq(shop.current_shop_cards[2].name, forced[2])
	assert_false(shop.continue_button.disabled)


func test_explicit_tutorial_pool_requires_one_purchase_before_continue() -> void:
	var shop = _spawn_shop()
	watch_signals(shop)
	var tutorial_cards: Array[CardDefinition] = TutorialDatabaseScript.get_tutorial_cards()
	var forced_names: Array[String] = TutorialDatabaseScript.tutorial_card_names()
	shop.show_shop(5, 4, 6, 77, forced_names, "Tutorial Hole 6/6", tutorial_cards, 1)

	assert_eq(_offer_ids(shop), _card_ids(tutorial_cards))
	assert_true(shop.continue_button.disabled)
	shop._on_shop_continue_pressed()
	assert_signal_not_emitted(shop, "continued")
	assert_signal_emitted_with_parameters(shop, "feedback_requested", [&"error"])

	shop._on_shop_card_pressed(0)
	assert_eq(shop.purchases_this_visit, 1)
	assert_false(shop.continue_button.disabled)
	shop._on_shop_continue_pressed()
	assert_signal_emitted(shop, "continued")


func test_easy_normal_and_hard_shop_profiles_use_4_5_6_offers_and_2_3_5_picks() -> void:
	var no_forced_cards: Array[String] = []
	var no_explicit_cards: Array[CardDefinition] = []
	var no_owned_cards: Array[StringName] = []
	var expectations := [
		{"offers": 4, "picks": 2, "multiplier": 1.0, "message": "PICK UP TO TWO"},
		{"offers": 5, "picks": 3, "multiplier": 1.25, "message": "PICK UP TO THREE"},
		{"offers": 6, "picks": 5, "multiplier": 1.6, "message": "PICK UP TO FIVE"},
	]
	for expectation in expectations:
		var shop = _spawn_shop()
		var presentation := ShopPresentationScript.new()
		presentation.setup(shop)
		shop.show_shop(
			3, 99, 18, 8844, no_forced_cards, "", no_explicit_cards, 0, no_owned_cards,
			expectation.offers, expectation.picks, expectation.multiplier
		)
		await wait_process_frames(2)
		assert_eq(shop.current_shop_cards.size(), expectation.offers)
		assert_eq(shop.current_max_purchases, expectation.picks)
		assert_eq(shop.shop_status_label.text, expectation.message)
		assert_eq(_visible_button_count(shop), expectation.offers)
		assert_true(shop.shop_card_rows[0].visible, "Every difficulty uses the native single-row card composition.")
		assert_false(shop.shop_card_rows[1].visible)
		assert_eq(shop.shop_card_rows[0].get_child_count(), 6, "All six reusable slots stay in the primary row.")
		assert_eq(shop.shop_card_rows[1].get_child_count(), 0)
		assert_eq(presentation.detail_side.visible, expectation.offers == 4)
		assert_eq(presentation.detail_strip.visible, expectation.offers > 4)
		assert_eq(shop.shop_card_rows[0].get_parent(), shop.shop_overlay.get_node("SafeArea/ShopLayout/ShopBody/CardRows"))
		var previous_rect := Rect2()
		for slot_index in range(shop.shop_card_slots.size()):
			var slot: Control = shop.shop_card_slots[slot_index]
			assert_eq(slot.get_parent(), shop.shop_card_rows[0])
			assert_eq(slot.visible, slot_index < expectation.offers)
			if not slot.visible:
				continue
			var card_rect: Rect2 = shop.shop_card_buttons[slot_index].get_global_rect()
			if slot_index > 0:
				assert_almost_eq(card_rect.position.y, previous_rect.position.y, 0.1)
				assert_gte(card_rect.position.x, previous_rect.end.x, "Visible offers must occupy separate columns.")
			previous_rect = card_rect
		for purchase_index in range(expectation.picks):
			shop._on_shop_card_pressed(purchase_index)
		assert_eq(shop.purchases_this_visit, expectation.picks)
		assert_eq(shop.shop_status_label.text, "PICK UP TO ZERO")
		var tokens_at_cap: int = shop.tokens
		shop._on_shop_card_pressed(expectation.picks)
		assert_eq(shop.purchases_this_visit, expectation.picks)
		assert_eq(shop.tokens, tokens_at_cap, "The new row layout cannot bypass the purchase cap.")


func test_card_copy_uses_one_large_wrapping_font_in_every_shop_layout() -> void:
	var no_forced_cards: Array[String] = []
	var no_explicit_cards: Array[CardDefinition] = []
	var no_owned_cards: Array[StringName] = []
	for offer_count in [4, 5, 6]:
		var shop = _spawn_shop()
		shop.show_shop(3, 99, 18, 9911, no_forced_cards, "", no_explicit_cards, 0, no_owned_cards, offer_count, mini(offer_count - 2, 5), 1.6)
		await wait_process_frames(2)
		for button_index in range(shop.current_shop_cards.size()):
			var card_view := shop.shop_card_buttons[button_index] as UICard
			for description: Label in [card_view.benefit_description, card_view.curse_description]:
				assert_eq(description.get_theme_font("font"), UIStyleScript.UI_FONT)
				assert_eq(description.get_theme_font_size("font_size"), UIStyleScript.text_size(22), "Copy keeps one shared size across all offers and difficulties.")
				assert_eq(description.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
				assert_eq(description.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING)
				assert_false(description.text.is_empty())
				assert_gte(description.get_visible_line_count(), description.get_line_count(), "Every benefit and curse remains fully visible before purchase.")


func _spawn_shop():
	var root := Node.new()
	add_child_autofree(root)
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	var shop = ShopManagerScript.new()
	root.add_child(shop)
	shop.create_overlay(canvas)
	return shop


func _offer_ids(shop) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card in shop.current_shop_cards:
		ids.append(card.id)
	return ids


func _unique_count(values: Array[StringName]) -> int:
	var unique := {}
	for value in values:
		unique[value] = true
	return unique.size()


func _card_ids(cards: Array[CardDefinition]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card in cards:
		ids.append(card.id)
	return ids


func _visible_button_count(shop) -> int:
	var count := 0
	for button in shop.shop_card_buttons:
		if button.visible:
			count += 1
	return count
