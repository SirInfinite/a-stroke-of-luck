class_name HoleRating
extends RefCounted


static func rate(strokes: int, par: int, completion_seconds: float, forced := false) -> Dictionary:
	var safe_par := maxi(par, 1)
	var safe_strokes := maxi(strokes, 1)
	var score_to_par := safe_strokes - safe_par
	var expected_time := expected_completion_seconds(safe_par)
	var time_ratio := maxf(completion_seconds, 0.0) / expected_time
	var stars := _stroke_stars(score_to_par, forced)

	if not forced:
		if score_to_par <= -2:
			if time_ratio > 1.5:
				stars = mini(stars, 4)
		elif score_to_par == -1:
			if time_ratio <= 0.75:
				stars = 5
			elif time_ratio > 1.5:
				stars = 3
		elif score_to_par == 0:
			if time_ratio > 1.45:
				stars = 3
		elif score_to_par == 1 and time_ratio > 1.5:
			stars = 2

	stars = clampi(stars, 1, 5)
	return {
		"stars": stars,
		"golf_result": golf_result_name(score_to_par, forced),
		"performance": ["", "ROUGH ROUND", "NEEDS WORK", "SOLID", "EXCELLENT", "EXCEPTIONAL"][stars],
		"score_to_par": score_to_par,
		"expected_time": expected_time,
		"time_ratio": snappedf(time_ratio, 0.001),
	}


static func expected_completion_seconds(par: int) -> float:
	return 22.0 + float(maxi(par, 1)) * 14.0


static func golf_result_name(score_to_par: int, forced := false) -> String:
	if forced:
		return "STROKE LIMIT"
	match score_to_par:
		-3:
			return "ALBATROSS"
		-2:
			return "EAGLE"
		-1:
			return "BIRDIE"
		0:
			return "PAR"
		1:
			return "BOGEY"
		2:
			return "DOUBLE BOGEY"
		_:
			return "UNDER PAR" if score_to_par < -3 else "TRIPLE BOGEY+"


static func _stroke_stars(score_to_par: int, forced: bool) -> int:
	if forced:
		return 1
	if score_to_par <= -2:
		return 5
	if score_to_par <= 0:
		return 4
	if score_to_par == 1:
		return 3
	if score_to_par == 2:
		return 2
	return 1
