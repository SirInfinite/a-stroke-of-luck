extends GutTest

const CardDatabase := preload("res://scripts/card_database.gd")
const CardEffectResolver := preload("res://scripts/card_effect_resolver.gd")
const ActiveCardCurseScript := preload("res://scripts/active_card_curse.gd")


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
		"trajectory": false,
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
			covered.trajectory = covered.trajectory or effects.trajectory_dot_delta != 0
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


func _card_by_name(card_name: String) -> CardDefinition:
	for card in CardDatabase.get_cards():
		if card.name == card_name:
			return card
	return null
