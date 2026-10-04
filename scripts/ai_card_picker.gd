class_name AICardPicker
extends RefCounted


static func choose(shop: ShopManager, match_state: VsMatchState) -> Array[CardDefinition]:
	var selected: Array[CardDefinition] = []
	for pick in shop.current_max_purchases:
		var best := -1
		var best_value := 0.0
		for index in shop.current_shop_cards.size():
			var card := shop.current_shop_cards[index]
			if shop.purchased_card_indices.has(index) or card.price > shop.tokens:
				continue
			var value := value_for(card, match_state)
			if value > best_value:
				best_value = value
				best = index
		if best < 0 or not shop.try_purchase_card(best):
			break
		selected.append(shop.current_shop_cards[best])
	return selected


static func value_for(card: CardDefinition, match_state: VsMatchState) -> float:
	var bonus := card.bonus_effects
	var curse := card.curse_effects.scaled(match_state.opponent.difficulty_profile.curse_strength_multiplier)
	var value := bonus.shot_power_delta * (2.0 + match_state.profile.power_bias / 50.0)
	value += bonus.terrain_mitigation_delta * 3.0 + bonus.direction_mitigation_delta * 2.0
	value += bonus.coin_reward_delta * 1.5 + bonus.birdie_reward_delta
	value += bonus.trajectory_dot_delta * 0.025 + bonus.power_control_delta * 0.2
	value += maxf(-bonus.roll_damping_delta, 0.0)
	var private_cost := absf(curse.shot_power_delta) * 2.0 + absf(curse.roll_damping_delta)
	private_cost += maxf(-curse.terrain_mitigation_delta, 0.0) * 2.0 + absf(curse.power_control_delta) * 0.2
	# Course risk is borne by BOTH golfers. It is not charged as a private curse:
	# precise opponents tolerate a small shared cup; beginners avoid that deal.
	var before := MatchCourseRules.resolve(match_state.player, match_state.opponent)
	var after := MatchCourseRules.resolve(match_state.player, match_state.opponent, card)
	var course_cost := (int(after.added_hazard_count) - int(before.added_hazard_count)) * (0.18 if match_state.profile.rank >= 3 else 0.32)
	course_cost += (float(before.cup_radius_scale) - float(after.cup_radius_scale)) * (0.4 if match_state.profile.rank >= 4 else 1.5)
	var owned := 0
	for existing in match_state.opponent.owned_card_definitions:
		owned += int(existing.id == card.id)
	return value / (1.0 + owned * 0.3) - private_cost - course_cost - card.price * 0.035
