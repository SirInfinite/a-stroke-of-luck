class_name MatchCourseRules
extends RefCounted
## VS-only boundary. Solo continues to use CardEffectResolver unchanged.
## Every new effect kind must declare a scope here before it can enter VS.
const COURSE_KINDS := [CardEffectSet.Kind.HAZARD_COUNT, CardEffectSet.Kind.CUP_RADIUS_SCALE]
const PERSONAL_KINDS := [CardEffectSet.Kind.SHOT_POWER, CardEffectSet.Kind.ROLL_DAMPING,
	CardEffectSet.Kind.TRAJECTORY_DOTS, CardEffectSet.Kind.POWER_CONTROL,
	CardEffectSet.Kind.TERRAIN_MITIGATION, CardEffectSet.Kind.DIRECTION_MITIGATION,
	CardEffectSet.Kind.COIN_REWARD, CardEffectSet.Kind.BIRDIE_REWARD]


static func affects_course(effects: CardEffectSet) -> bool:
	return effects != null and (effects.hazard_count_delta != 0 or not is_zero_approx(effects.cup_radius_scale_delta))


static func resolve(first: RunState, second: RunState, prospective_second_card: CardDefinition = null) -> Dictionary:
	assert(COURSE_KINDS.size() + PERSONAL_KINDS.size() == CardEffectSet.Kind.size(), "Classify new card effects for VS before use.")
	var contributions: Array[Vector2] = []
	var hazard_types: Dictionary = {}
	for owner_state in [first, second]:
		var multiplier: float = owner_state.difficulty_profile.curse_strength_multiplier if owner_state.difficulty_profile else 1.0
		for card in owner_state.owned_card_definitions:
			_collect(card.bonus_effects, 1.0, contributions, hazard_types)
		for curse in owner_state.active_card_curses:
			if curse.remaining_holes > 0:
				_collect(curse.card.curse_effects, multiplier, contributions, hazard_types)
	if prospective_second_card:
		# Read-only shop evaluation: price and ownership still belong to ShopManager.
		_collect(prospective_second_card.bonus_effects, 1.0, contributions, hazard_types)
		_collect(prospective_second_card.curse_effects, second.difficulty_profile.curse_strength_multiplier if second.difficulty_profile else 1.0, contributions, hazard_types)
	# Stable summation, independent of owner and purchase ordering.
	contributions.sort()
	var combined := CardEffectSet.new()
	for contribution in contributions:
		combined.hazard_count_delta += roundi(contribution.x)
		combined.cup_radius_scale_delta += contribution.y
	combined.clamp_for_release()
	var types: Array = hazard_types.keys()
	types.sort_custom(func(a: StringName, b: StringName) -> bool:
		return hazard_types[a] > hazard_types[b] if hazard_types[a] != hazard_types[b] else String(a) < String(b))
	# The current generation contract has one preferred curse hazard type.
	# All shipped placement curses use direction; mixed future types choose the
	# strongest contribution, lexical tie-break, while stacking the count.
	return {"added_hazard_count": combined.hazard_count_delta,
		"preferred_hazard_type": types[0] if not types.is_empty() else &"direction",
		"cup_radius_scale": 1.0 + combined.cup_radius_scale_delta}


static func _collect(effects: CardEffectSet, multiplier: float, contributions: Array[Vector2], types: Dictionary) -> void:
	var scaled := CardEffectSet.new()
	scaled.add_scaled_from(effects, multiplier)
	contributions.append(Vector2(scaled.hazard_count_delta, scaled.cup_radius_scale_delta))
	if scaled.hazard_count_delta > 0:
		var kind := scaled.hazard_type if not scaled.hazard_type.is_empty() else &"direction"
		types[kind] = int(types.get(kind, 0)) + scaled.hazard_count_delta
