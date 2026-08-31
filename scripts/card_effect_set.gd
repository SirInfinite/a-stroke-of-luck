class_name CardEffectSet
extends RefCounted

enum Kind {
	SHOT_POWER,
	ROLL_DAMPING,
	TRAJECTORY_DOTS,
	POWER_CONTROL,
	TERRAIN_MITIGATION,
	DIRECTION_MITIGATION,
	COIN_REWARD,
	BIRDIE_REWARD,
	HAZARD_COUNT,
	CUP_RADIUS_SCALE,
}

var shot_power_delta := 0.0
var roll_damping_delta := 0.0
var trajectory_dot_delta := 0
var power_control_delta := 0.0
var terrain_mitigation_delta := 0.0
var direction_mitigation_delta := 0.0
var coin_reward_delta := 0
var birdie_reward_delta := 0
var hazard_count_delta := 0
var hazard_type: StringName = &""
var cup_radius_scale_delta := 0.0


static func single(effect_kind: int, amount: float, detail: StringName = &"") -> CardEffectSet:
	var effects := CardEffectSet.new()
	match effect_kind:
		Kind.SHOT_POWER:
			effects.shot_power_delta = amount
		Kind.ROLL_DAMPING:
			effects.roll_damping_delta = amount
		Kind.TRAJECTORY_DOTS:
			effects.trajectory_dot_delta = roundi(amount)
		Kind.POWER_CONTROL:
			effects.power_control_delta = amount
		Kind.TERRAIN_MITIGATION:
			effects.terrain_mitigation_delta = amount
		Kind.DIRECTION_MITIGATION:
			effects.direction_mitigation_delta = amount
		Kind.COIN_REWARD:
			effects.coin_reward_delta = roundi(amount)
		Kind.BIRDIE_REWARD:
			effects.birdie_reward_delta = roundi(amount)
		Kind.HAZARD_COUNT:
			effects.hazard_count_delta = roundi(amount)
			effects.hazard_type = detail
		Kind.CUP_RADIUS_SCALE:
			effects.cup_radius_scale_delta = amount
		_:
			push_error("Unsupported card effect kind %d." % effect_kind)
	return effects


func add_from(other: CardEffectSet) -> void:
	shot_power_delta += other.shot_power_delta
	roll_damping_delta += other.roll_damping_delta
	trajectory_dot_delta += other.trajectory_dot_delta
	power_control_delta += other.power_control_delta
	terrain_mitigation_delta += other.terrain_mitigation_delta
	direction_mitigation_delta += other.direction_mitigation_delta
	coin_reward_delta += other.coin_reward_delta
	birdie_reward_delta += other.birdie_reward_delta
	hazard_count_delta += other.hazard_count_delta
	if other.hazard_count_delta != 0 and not other.hazard_type.is_empty():
		hazard_type = other.hazard_type
	cup_radius_scale_delta += other.cup_radius_scale_delta


func clamp_for_release() -> void:
	shot_power_delta = clampf(shot_power_delta, -0.65, 1.5)
	roll_damping_delta = clampf(roll_damping_delta, -0.65, 1.5)
	trajectory_dot_delta = clampi(trajectory_dot_delta, -10, 24)
	power_control_delta = clampf(power_control_delta, -0.65, 1.5)
	terrain_mitigation_delta = clampf(terrain_mitigation_delta, -0.5, 0.75)
	direction_mitigation_delta = clampf(direction_mitigation_delta, -0.5, 0.75)
	coin_reward_delta = clampi(coin_reward_delta, 0, 8)
	birdie_reward_delta = clampi(birdie_reward_delta, 0, 8)
	hazard_count_delta = clampi(hazard_count_delta, 0, 4)
	cup_radius_scale_delta = clampf(cup_radius_scale_delta, -0.45, 0.5)


func is_empty() -> bool:
	return (
		is_zero_approx(shot_power_delta)
		and is_zero_approx(roll_damping_delta)
		and trajectory_dot_delta == 0
		and is_zero_approx(power_control_delta)
		and is_zero_approx(terrain_mitigation_delta)
		and is_zero_approx(direction_mitigation_delta)
		and coin_reward_delta == 0
		and birdie_reward_delta == 0
		and hazard_count_delta == 0
		and is_zero_approx(cup_radius_scale_delta)
	)
