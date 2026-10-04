extends GutTest

const CardDatabase := preload("res://scripts/card_database.gd")
const CardEffectResolver := preload("res://scripts/card_effect_resolver.gd")
const ActiveCardCurseScript := preload("res://scripts/active_card_curse.gd")
const DifficultyDatabase := preload("res://scripts/difficulty_database.gd")
const UICardScript := preload("res://scripts/ui/ui_card.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")


func test_release_pool_has_eight_typed_functional_tradeoff_cards() -> void:
	var cards: Array[CardDefinition] = CardDatabase.get_cards()
	assert_eq(cards.size(), 8)

	var ids := {}
	var names := {}
	for card in cards:
		assert_true(card is CardDefinition)
		assert_true(card.is_valid(), "%s must be a complete typed definition." % card.name)
		assert_false(ids.has(card.id), "Card ids must be unique.")
		assert_false(names.has(card.name), "Card names must be unique.")
		ids[card.id] = true
		names[card.name] = true
		assert_eq(card.curse_duration_holes, 3)


func test_release_pool_covers_every_required_reusable_effect_category() -> void:
	var covered := {
		"shot_power": false,
		"roll_friction": false,
		"power_control": false,
		"terrain_mitigation": false,
		"economy": false,
		"generation_hazard": false,
		"risk_reward": false,
	}
	for card in CardDatabase.get_cards():
		for effects in [card.bonus_effects, card.curse_effects]:
			covered.shot_power = covered.shot_power or not is_zero_approx(effects.shot_power_delta)
			covered.roll_friction = covered.roll_friction or not is_zero_approx(effects.roll_damping_delta)
			assert_eq(effects.trajectory_dot_delta, 0, "Trajectory is standard and may not be card-gated.")
			covered.power_control = covered.power_control or not is_zero_approx(effects.power_control_delta)
			covered.terrain_mitigation = covered.terrain_mitigation or not is_zero_approx(effects.terrain_mitigation_delta) or not is_zero_approx(effects.direction_mitigation_delta)
			covered.economy = covered.economy or effects.coin_reward_delta != 0
			covered.generation_hazard = covered.generation_hazard or effects.hazard_count_delta != 0
		covered.risk_reward = covered.risk_reward or (
			card.bonus_effects.birdie_reward_delta > 0
			and card.curse_effects.cup_radius_scale_delta < 0.0
		)

	for category in covered:
		assert_true(covered[category], "Missing required effect category: %s" % category)


func test_resolver_separates_persistent_bonus_from_temporary_curse_and_stacks() -> void:
	var overdrive := _card_by_name("Overdrive Driver")
	var owned: Array[CardDefinition] = [overdrive, overdrive]
	var active_curses: Array[ActiveCardCurse] = [
		ActiveCardCurseScript.new(overdrive),
		ActiveCardCurseScript.new(overdrive),
	]

	var with_curses: CardEffectSet = CardEffectResolver.resolve(owned, active_curses)
	assert_almost_eq(with_curses.shot_power_delta, 0.5, 0.001)
	assert_almost_eq(with_curses.power_control_delta, -0.3, 0.001)

	active_curses.clear()
	var bonuses_only: CardEffectSet = CardEffectResolver.resolve(owned, active_curses)
	assert_almost_eq(bonuses_only.shot_power_delta, 0.5, 0.001)
	assert_almost_eq(bonuses_only.power_control_delta, 0.0, 0.001)


func test_release_clamps_keep_extreme_stacks_playable() -> void:
	var overdrive := _card_by_name("Overdrive Driver")
	var owned: Array[CardDefinition] = []
	var active_curses: Array[ActiveCardCurse] = []
	for _copy_index in range(20):
		owned.append(overdrive)
		active_curses.append(ActiveCardCurseScript.new(overdrive))

	var resolved: CardEffectSet = CardEffectResolver.resolve(owned, active_curses)
	assert_almost_eq(resolved.shot_power_delta, 1.5, 0.001)
	assert_almost_eq(resolved.power_control_delta, -0.65, 0.001)


func test_difficulty_profiles_scale_curses_without_scaling_bonuses() -> void:
	var profiles := DifficultyDatabase.get_profiles()
	assert_eq(profiles.size(), 3)
	assert_eq([profiles[0].shop_offer_count, profiles[1].shop_offer_count, profiles[2].shop_offer_count], [4, 5, 6])
	assert_eq([profiles[0].max_purchases, profiles[1].max_purchases, profiles[2].max_purchases], [2, 3, 5])
	assert_eq([profiles[0].curse_strength_multiplier, profiles[1].curse_strength_multiplier, profiles[2].curse_strength_multiplier], [1.0, 1.25, 1.6])

	var overdrive := _card_by_name("Overdrive Driver")
	var owned: Array[CardDefinition] = [overdrive]
	var curses: Array[ActiveCardCurse] = [ActiveCardCurseScript.new(overdrive)]
	var easy := CardEffectResolver.resolve(owned, curses, profiles[0].curse_strength_multiplier)
	var normal := CardEffectResolver.resolve(owned, curses, profiles[1].curse_strength_multiplier)
	var hard := CardEffectResolver.resolve(owned, curses, profiles[2].curse_strength_multiplier)
	assert_almost_eq(easy.shot_power_delta, 0.25, 0.001)
	assert_almost_eq(normal.shot_power_delta, 0.25, 0.001)
	assert_almost_eq(hard.shot_power_delta, 0.25, 0.001)
	assert_almost_eq(easy.power_control_delta, -0.15, 0.001)
	assert_almost_eq(normal.power_control_delta, -0.1875, 0.001)
	assert_almost_eq(hard.power_control_delta, -0.24, 0.001)
	assert_eq(overdrive.curse_description_for_multiplier(1.0), "Power meter is 15% less precise.")
	assert_eq(overdrive.curse_description_for_multiplier(1.6), "Power meter is 24% less precise.")


func test_all_card_copy_is_short_human_facing_and_wraps_at_one_consistent_size() -> void:
	var cards: Array[CardDefinition] = CardDatabase.get_cards()
	cards.append_array(CardDatabase.get_tutorial_cards())
	var longest_card: CardDefinition = cards[0]
	var longest_copy_length := 0
	var forbidden_terms := ["multiplier", "modifier", "impulse velocity", "oscillation frequency", "applies a"]
	for card in cards:
		for copy in [card.bonus_description, card.curse_description, card.stacking_description]:
			assert_false(copy.is_empty())
			assert_lte(copy.length(), 72, "%s copy should remain scannable." % card.name)
			for term in forbidden_terms:
				assert_false(copy.to_lower().contains(term), "%s uses internal language: %s" % [card.name, term])
		var combined_length := card.bonus_description.length() + card.curse_description_for_multiplier(1.6).length() + card.stacking_description.length()
		if combined_length > longest_copy_length:
			longest_copy_length = combined_length
			longest_card = card

	var card_view = UICardScript.new()
	add_child_autofree(card_view)
	card_view.configure_card(longest_card, true, false, 9, 1.6)
	card_view.set_compact_layout(true)
	await wait_process_frames(2)
	for description in [card_view.benefit_description, card_view.curse_description, card_view.stack_label]:
		assert_eq(description.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
		assert_eq(description.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING)
		assert_eq(description.get_theme_font("font"), UIStyleScript.UI_FONT, "All card copy uses the approved shared family.")
	assert_eq(UIStyleScript.UI_FONT.resource_path, "res://assets/fonts/Jersey10/Jersey10-Regular.ttf")
	assert_eq(card_view.benefit_description.get_theme_font_size("font_size"), UIStyleScript.text_size(22))
	assert_eq(card_view.curse_description.get_theme_font_size("font_size"), UIStyleScript.text_size(22))
	assert_gte(card_view.benefit_description.get_visible_line_count(), card_view.benefit_description.get_line_count())
	assert_gte(card_view.curse_description.get_visible_line_count(), card_view.curse_description.get_line_count())


func _card_by_name(card_name: String) -> CardDefinition:
	for card in CardDatabase.get_cards():
		if card.name == card_name:
			return card
	return null
