class_name AIShotPlanner
extends RefCounted
## Bounded search over legal angle/power pairs. No live state mutation.
const AIM_TIME := 0.8
const FINALIST_COUNT := 8
var diagnostics: Dictionary = {}


func plan(model: AICourseModel, origin: Vector2, elevation: int, profile: AIDifficultyProfile, seed_value: int) -> Dictionary:
	var started := Time.get_ticks_usec()
	var power_error := profile.power_error / maxf(float(model.params.get("power_control", 1.0)), 0.35)
	var candidates: Array[Dictionary] = []
	var angles: Array[float] = []
	var targets := model.targets(origin, elevation)
	for target in targets:
		var angle := origin.angle_to_point(target)
		angles.append(angle)
		if profile.rank > 1:
			angles.append(angle - 0.12)
			angles.append(angle + 0.12)
	# Full circle enables recovery/backward setups and ordinary wall banking.
	for index in profile.angle_samples:
		angles.append(origin.angle_to_point(model.cup) + TAU * index / profile.angle_samples)
	var seen := {}
	var count := 0
	for angle in angles:
		var direction := Vector2.RIGHT.rotated(angle)
		var powers: Array[float] = []
		for index in profile.power_samples:
			powers.append(lerpf(0.12, 1.0, float(index) / maxf(profile.power_samples - 1, 1)))
		for target in targets:
			if absf(angle_difference(angle, origin.angle_to_point(target))) < 0.02:
				# Inverse of ordinary damped travel gives a useful approach seed;
				# every candidate is still tested through the full course forecast.
				var control := (origin.distance_to(target) * (float(model.params.normal_damp) + float(model.params.world_damp)) + float(model.params.stop_speed)) * float(model.params.mass) / float(model.params.max_impulse)
				if profile.approach_precision > 0.0:
					control = snappedf(control, profile.approach_precision)
				powers.append(clampf(control, 0.015, 1.0))
		for power in powers:
			var key := Vector2i(roundi(wrapf(angle, 0.0, TAU) * 10000.0), roundi(power * 10000.0))
			if seen.has(key):
				continue
			seen[key] = true
			var forecast := model.predict(origin, elevation, direction, power, AIM_TIME)
			count += 1
			candidates.append({"direction": direction, "power": power, "wait": 0.0,
				"forecast": forecast, "score": _score(model, forecast, power, origin, elevation, profile)})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.score) > float(b.score))
	# Refine finalists at the real fixed timestep, including observed timing.
	var finalists: Array[Dictionary] = []
	for index in mini(FINALIST_COUNT, candidates.size()):
		var candidate := candidates[index]
		for timing in (profile.timing_samples if not model.movers.is_empty() else 1):
			var wait := timing * 0.3
			var forecast := model.predict(origin, elevation, candidate.direction, float(candidate.power), AIM_TIME + wait, 1.0 / 60.0)
			count += 1
			var scored := _score(model, forecast, float(candidate.power), origin, elevation, profile) - wait * 4.0
			finalists.append({"direction": candidate.direction, "power": candidate.power, "wait": wait, "forecast": forecast, "score": scored})
	finalists.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.score) > float(b.score))
	if profile.rank == 5:
		# A small local polish finds fine bank/landing angles between grid samples.
		# Eighteen extra queries maximum; no physics privileges or unbounded search.
		for candidate in finalists.slice(0, 2):
			for angle_offset in [-0.025, 0.0, 0.025]:
				for power_scale in [0.88, 1.0, 1.12]:
					var direction: Vector2 = Vector2(candidate.direction).rotated(angle_offset)
					var power := clampf(float(candidate.power) * power_scale, 0.015, 1.0)
					var forecast := model.predict(origin, elevation, direction, power, AIM_TIME + float(candidate.wait), 1.0 / 60.0)
					count += 1
					finalists.append({"direction": direction, "power": power, "wait": candidate.wait, "forecast": forecast,
						"score": _score(model, forecast, power, origin, elevation, profile) - float(candidate.wait) * 4.0})
		finalists.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.score) > float(b.score))
	# Only a few promising landing positions get a coarse second-shot probe.
	for index in mini(profile.lookahead_count, finalists.size()):
		var candidate := finalists[index]
		if candidate.forecast.reset or candidate.forecast.sunk:
			continue
		var landing: Vector2 = candidate.forecast.endpoint
		var layer := int(candidate.forecast.elevation)
		var best_next := -INF
		for target in model.targets(landing, layer).slice(0, 3):
			for power in [0.25, 0.55, 0.85]:
				var forecast := model.predict(landing, layer, landing.direction_to(target), power, AIM_TIME * 2.0 + float(candidate.forecast.duration))
				count += 1
				best_next = maxf(best_next, _score(model, forecast, power, landing, layer, profile))
		candidate.score += clampf(best_next, -600.0, 900.0) * 0.18
	finalists.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.score) > float(b.score))
	# Good golfers leave a margin for execution error. Probe a small, fixed
	# error envelope, NOT the future RNG draw. A perfect nominal cup line is
	# not a safe win when a plausible miss lands in water or a moving gate.
	if profile.rank >= 3:
		for candidate in finalists.slice(0, 6):
			for side in [-1.0, 1.0]:
				var direction: Vector2 = Vector2(candidate.direction).rotated(side * profile.aim_error * 0.8)
				var power := clampf(float(candidate.power) * (1.0 + side * power_error * 0.8), 0.015, 1.0)
				var miss := model.predict(origin, elevation, direction, power, AIM_TIME + float(candidate.wait), 1.0 / 60.0)
				count += 1
				if miss.reset or not miss.complete:
					candidate.score = minf(float(candidate.score), _score(model, miss, power, origin, elevation, profile))
		finalists = finalists.slice(0, 6)
		finalists.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.score) > float(b.score))
	var choice: Dictionary = finalists[0].duplicate(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = maxi(absi(seed_value), 1)
	choice.direction = Vector2(choice.direction).rotated(rng.randf_range(-profile.aim_error, profile.aim_error))
	choice.power = clampf(float(choice.power) * (1.0 + rng.randf_range(-power_error, power_error)), 0.015, 1.0)
	# Errors are applied to decisions, never to the golf rules.
	choice["candidate_count"] = count
	choice["decision_ms"] = (Time.get_ticks_usec() - started) / 1000.0
	diagnostics = {"profile": profile.id, "candidate_count": count, "score": choice.score,
		"power": choice.power, "angle": Vector2(choice.direction).angle(),
		"predicted_endpoint": choice.forecast.endpoint, "decision_ms": choice.decision_ms,
		"bank": int(choice.forecast.bounces) > 0, "pads": choice.forecast.pads}
	return choice


func _score(model: AICourseModel, forecast: Dictionary, power: float, origin: Vector2, elevation: int, profile: AIDifficultyProfile) -> float:
	if forecast.sunk and not forecast.reset:
		return 100000.0 - power * 100.0 - float(forecast.duration) * 5.0
	var remaining := model.remaining_distance(forecast.endpoint, int(forecast.elevation))
	var progress := model.remaining_distance(origin, elevation) - remaining
	var score := progress - remaining * 0.25 - 12.0
	score -= profile.risk_penalty * (1.0 if forecast.reset else float(forecast.danger))
	if not forecast.complete:
		score -= 2000.0
	if origin.distance_to(forecast.endpoint) < 24.0:
		score -= 160.0
	score += power * profile.power_bias
	return score
