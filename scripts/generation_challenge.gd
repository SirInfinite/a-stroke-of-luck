class_name GenerationChallenge
extends RefCounted
## Resolved once per hole. Difficulty, run stage and the local biome arc are
## separate axes; safety reservations and validator limits never shrink.

const TIERS := {
	&"easy": {"clusters": 1, "blockers": 0, "moving": [0.08, 0.22, 0.48], "branch": 0.35, "elevation": 0.18, "stretch": 0, "growth": 0.0},
	&"normal": {"clusters": 2, "blockers": 0, "moving": [0.32, 0.65, 0.88], "branch": 0.85, "elevation": 0.8, "stretch": 0, "growth": 0.22},
	&"hard": {"clusters": 3, "blockers": 1, "moving": [0.65, 0.9, 1.0], "branch": 1.4, "elevation": 1.35, "stretch": 1, "growth": 0.4},
}

static func resolve(difficulty: StringName, biome_index: int, arc: int, biome_design: Dictionary, options: Dictionary) -> Dictionary:
	var tier: Dictionary = TIERS.get(difficulty, TIERS[&"normal"])
	var easy := difficulty == &"easy"
	var hard := difficulty == &"hard"
	var stage := clampi(biome_index / 2, 0, 2)
	var progress := clampf(float(biome_index * 3 + arc) / 17.0, 0.0, 1.0)
	var clusters := int(tier.clusters) + (1 if easy and stage > 0 else 0 if easy else stage) + (1 if arc == 2 or hard and arc == 1 else 0)
	var blockers := int(tier.blockers) + (1 if arc > 0 and not easy else 0) + (stage if hard else 1 if stage == 2 and not easy else 0)
	if easy and stage > 0 and arc == 2:
		blockers = 1
	return {
		"difficulty": difficulty, "overall_hole": biome_index * 3 + arc + 1,
		"stage": ["early", "mid", "late"][stage], "arc": arc, "progress": progress,
		"terrain_clusters": clusters, "blockers": blockers,
		"moving_chance": minf(float(tier.moving[arc]) + progress * (0.05 if easy else 0.12), 1.0),
		"second_moving_chance": 0.55 if hard and stage == 2 and arc > 0 else 0.0,
		"max_moving": 2 if hard and stage == 2 and arc > 0 else 1,
		"branch_chance": clampf(float(biome_design.branch) * float(tier.branch) * lerpf(0.65, 1.2, progress), 0.0, 0.8),
		"elevation_chance": float(biome_design.elevation) * float(tier.elevation) * lerpf(0.4, 1.1, progress) * (0.25 if arc == 0 else 1.0),
		"crossing_chance": 0.38 if hard and stage == 2 and arc == 2 else 0.16 if not easy and stage > 0 and arc == 2 else 0.0,
		"dead_end_chance": 0.06 if easy else 0.16 if not hard else 0.23,
		"stretch": int(tier.stretch) + (1 if stage == 2 and not easy else 0),
		"cluster_growth": float(tier.growth) + progress * (0.12 if easy else 0.24),
		"guard_shoulder": easy and arc == 0, "recovery_radius": 2 if easy else 1,
		"curse_count": clampi(int(options.get("added_hazard_count", 0)), 0, 4),
	}

static func cluster_shape(profile: Dictionary, roll: float) -> int:
	# Single guards stay useful; broad guards become more likely, not universal.
	var shaped := clampf(roll + float(profile.cluster_growth) * (1.0 - roll), 0.0, 0.999)
	return 0 if shaped < 0.4 else 1 if shaped < 0.69 else 2 if shaped < 0.83 else 3 if shaped < 0.92 else 4 if shaped < 0.98 else 5
