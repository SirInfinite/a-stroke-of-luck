class_name AIDifficultyProfile
extends RefCounted
## Fictional game AI using text names only; no affiliation or endorsement.
const IDS := [&"palmer", &"mickelson", &"mcilroy", &"woods", &"nicklaus"]
var id: StringName
var display_name: String
var short_name: String
var tier: String
var description: String
var rank: int
var accent: Color
var angle_samples: int
var power_samples: int
var aim_error: float
var power_error: float
var risk_penalty: float
var lookahead_count: int
var timing_samples: int
var power_bias: float
var approach_precision: float
var preparation_time: float


static func get_profile(opponent_id: StringName) -> AIDifficultyProfile:
	var index := maxi(IDS.find(opponent_id), 0)
	var profile := AIDifficultyProfile.new()
	profile.id = IDS[index]
	profile.rank = index + 1
	profile.display_name = ["Arnold Palmer", "Phil Mickelson", "Rory McIlroy", "Tiger Woods", "Jack Nicklaus"][index]
	profile.short_name = ["PALMER", "MICKELSON", "McILROY", "WOODS", "NICKLAUS"][index]
	profile.tier = ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT", "LEGEND"][index]
	profile.description = ["Safe lines. Forgiving mistakes.", "A taste for risky banks.", "Powerful when the line is right.", "Balanced. Precise. Patient.", "Every stroke has a purpose."][index]
	profile.accent = [Color("7ccaa5"), Color("e4ac68"), Color("74b8d8"), Color("d88eaa"), Color("e2bd61")][index]
	profile.angle_samples = [8, 12, 24, 32, 40][index]
	profile.power_samples = [3, 4, 6, 7, 8][index]
	profile.aim_error = deg_to_rad([17.0, 9.0, 2.6, 0.8, 0.35][index])
	profile.power_error = [0.34, 0.21, 0.065, 0.022, 0.012][index]
	profile.risk_penalty = [1900.0, 1050.0, 1500.0, 2200.0, 2400.0][index]
	profile.lookahead_count = [0, 0, 2, 3, 4][index]
	profile.timing_samples = [1, 1, 3, 4, 5][index]
	profile.power_bias = [0.0, 10.0, 35.0, 0.0, -5.0][index]
	profile.approach_precision = [0.12, 0.07, 0.0, 0.0, 0.0][index]
	profile.preparation_time = [0.74, 0.70, 0.66, 0.62, 0.60][index]
	return profile
