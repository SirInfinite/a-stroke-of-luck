class_name CardDefinition
extends RefCounted

var id: StringName
var rarity: StringName = &"common"
var name: String
var price: int
var bonus_description: String
var curse_description: String
var stacking_description: String
var bonus_effects: CardEffectSet
var curse_effects: CardEffectSet
var curse_duration_holes: int


func _init(
	card_id: StringName,
	card_name: String,
	card_price: int,
	card_bonus_description: String,
	card_curse_description: String,
	card_stacking_description: String,
	card_bonus_effects: CardEffectSet,
	card_curse_effects: CardEffectSet,
	card_curse_duration_holes := 3
) -> void:
	id = card_id
	name = card_name
	price = card_price
	bonus_description = card_bonus_description
	curse_description = card_curse_description
	stacking_description = card_stacking_description
	bonus_effects = card_bonus_effects
	curse_effects = card_curse_effects
	curse_duration_holes = card_curse_duration_holes


func is_valid() -> bool:
	return (
		not id.is_empty()
		and not name.is_empty()
		and price > 0
		and not bonus_description.is_empty()
		and not curse_description.is_empty()
		and not stacking_description.is_empty()
		and bonus_effects != null
		and not bonus_effects.is_empty()
		and curse_effects != null
		and not curse_effects.is_empty()
		and curse_duration_holes > 0
		and rarity in [&"common", &"rare", &"epic", &"legendary"]
	)


func curse_description_for_multiplier(multiplier: float) -> String:
	var effects := curse_effects.scaled(multiplier)
	return describe_effects(effects, curse_description)


static func describe_effects(effects: CardEffectSet, fallback: String) -> String:
	if not is_zero_approx(effects.shot_power_delta):
		return "%s%d%% shot power." % ["+" if effects.shot_power_delta > 0.0 else "-", roundi(absf(effects.shot_power_delta) * 100.0)]
	if not is_zero_approx(effects.roll_damping_delta):
		return "Roll resistance %d%% %s." % [roundi(absf(effects.roll_damping_delta) * 100.0), "higher" if effects.roll_damping_delta > 0.0 else "lower"]
	if effects.trajectory_dot_delta != 0:
		return "%s%d aim dots." % ["+" if effects.trajectory_dot_delta > 0 else "", effects.trajectory_dot_delta]
	if not is_zero_approx(effects.power_control_delta):
		return "Power meter is %d%% %s precise." % [roundi(absf(effects.power_control_delta) * 100.0), "more" if effects.power_control_delta > 0.0 else "less"]
	if not is_zero_approx(effects.terrain_mitigation_delta):
		return "Sand slows %d%% %s." % [roundi(absf(effects.terrain_mitigation_delta) * 100.0), "less" if effects.terrain_mitigation_delta > 0.0 else "more"]
	if not is_zero_approx(effects.direction_mitigation_delta):
		return "Direction zones push %d%% %s." % [roundi(absf(effects.direction_mitigation_delta) * 100.0), "less" if effects.direction_mitigation_delta > 0.0 else "harder"]
	if effects.hazard_count_delta != 0:
		var hazard_name := String(effects.hazard_type).replace("_", " ")
		return "+%d %s%s each hole." % [effects.hazard_count_delta, hazard_name, "" if effects.hazard_count_delta == 1 else "s"]
	if not is_zero_approx(effects.cup_radius_scale_delta):
		return "Cup is %d%% %s." % [roundi(absf(effects.cup_radius_scale_delta) * 100.0), "larger" if effects.cup_radius_scale_delta > 0.0 else "smaller"]
	if effects.birdie_reward_delta != 0:
		return "Birdie or better: +%d coins." % effects.birdie_reward_delta
	if effects.coin_reward_delta != 0:
		return "+%d coins after each hole." % effects.coin_reward_delta
	return fallback
