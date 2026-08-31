extends GutTest

const ShopManagerScript := preload("res://scripts/shop_manager.gd")


func test_shop_has_four_unique_seeded_offers() -> void:
	var shop = _spawn_shop()
	shop.show_shop(3, 20, 18, 424242)
	var first_ids := _offer_ids(shop)

	assert_eq(first_ids.size(), 4)
	assert_eq(_unique_count(first_ids), 4)
	for button in shop.shop_card_buttons:
		assert_true(button.text.contains("BONUS — RUN"))
		assert_true(button.text.contains("CURSE — NEXT 3 HOLES"))
		assert_true(button.text.contains("STACKS"))

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
	shop._on_shop_card_pressed(1)
	var tokens_after_two: int = shop.tokens
	shop._on_shop_card_pressed(2)

	assert_eq(shop.purchases_this_visit, 2)
	assert_eq(shop.tokens, tokens_after_two)
	for button in shop.shop_card_buttons:
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
	var button: Button = shop.shop_card_buttons[0]

	shop._on_card_hovered(button)
	await wait_process_frames(2)
	assert_gt(button.scale.x, 1.0)
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
