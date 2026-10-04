class_name CardRarityProfile
extends RefCounted

const IDS: Array[StringName] = [&"common", &"rare", &"epic", &"legendary"]
const PROFILES := {
	&"common": {"benefit": 1.0, "curse": 1.0, "cost": 1.0, "duration_extra": 0, "relief": 0.0, "color": Color("718776")},
	&"rare": {"benefit": 1.5, "curse": 1.35, "cost": 1.75, "duration_extra": 0, "relief": 0.35, "color": Color("378db5")},
	&"epic": {"benefit": 2.25, "curse": 1.8, "cost": 2.75, "duration_extra": 1, "relief": 0.65, "color": Color("9660b8")},
	&"legendary": {"benefit": 3.25, "curse": 2.5, "cost": 4.5, "duration_extra": 2, "relief": 0.88, "color": Color("b77822")},
}
const OFFER_WEIGHTS := {
	&"easy": [78.0, 18.0, 3.5, 0.5],
	&"normal": [70.0, 23.0, 6.0, 1.0],
	&"hard": [62.0, 27.0, 9.0, 2.0],
}

static func roll(rng: RandomNumberGenerator, difficulty: StringName = &"normal") -> StringName:
	var weights: Array = OFFER_WEIGHTS.get(difficulty, OFFER_WEIGHTS[&"normal"])
	var selection := rng.randf() * 100.0
	for index in range(IDS.size()):
		selection -= float(weights[index])
		if selection < 0.0:
			return IDS[index]
	return IDS[-1]

static func create(base: CardDefinition, rarity: StringName) -> CardDefinition:
	var profile: Dictionary = PROFILES.get(rarity, PROFILES[&"common"])
	var tier := maxi(IDS.find(rarity), 0)
	var bonus := _scale(base.bonus_effects, float(profile.benefit), tier, float(profile.relief), true)
	var curse := _scale(base.curse_effects, float(profile.curse), tier, 0.0, false)
	var result := CardDefinition.new(base.id, base.name, ceili(base.price * float(profile.cost)),
		base.bonus_description if tier == 0 else CardDefinition.describe_effects(bonus, base.bonus_description),
		CardDefinition.describe_effects(curse, base.curse_description), base.stacking_description,
		bonus, curse, base.curse_duration_holes + int(profile.duration_extra))
	result.rarity = IDS[tier]
	return result

static func _scale(source: CardEffectSet, multiplier: float, tier: int, relief: float, benefit: bool) -> CardEffectSet:
	var result := CardEffectSet.new()
	for field in ["shot_power_delta", "roll_damping_delta", "power_control_delta", "terrain_mitigation_delta", "direction_mitigation_delta", "cup_radius_scale_delta"]:
		var original := float(source.get(field))
		var value := original * multiplier
		# Relief has an asymptote, not 100% immunity. Preserve tier distinctions.
		if benefit and field in ["terrain_mitigation_delta", "direction_mitigation_delta"] and original > 0.0:
			value = lerpf(original, 0.75, relief)
		result.set(field, value)
	for field in ["trajectory_dot_delta", "coin_reward_delta", "birdie_reward_delta"]:
		var original := int(source.get(field))
		result.set(field, signi(original) * ceili(absf(original) * multiplier))
	# A categorical extra guard advances by whole meaningful placements.
	result.hazard_count_delta = mini(source.hazard_count_delta + tier, 4) if source.hazard_count_delta > 0 else 0
	result.hazard_type = source.hazard_type
	result.clamp_for_release()
	return result
