class_name CourseMotifs
extends RefCounted

## Spatial vocabulary, not finished holes. Segments are stretched, reflected and
## rotated before the corridor, shot zones and challenge slots are constructed.
const IDS := [
	"guarded_lane", "bank_corner", "dogleg", "s_curve", "switchback",
	"water_gate", "sand_choke", "ice_runout", "offset_blocker", "staggered_slalom",
	"pendulum_gate", "falling_ice_gate", "rotating_gate", "bounce_bank",
	"split_route", "risky_shortcut", "recovery_pocket", "dead_end_bait",
	"raised_bridge", "recessed_cut", "short_tunnel",
	"open_green", "guarded_green", "angled_green", "sand_approach", "water_approach",
]

const BIOME_DESIGNS := {
	&"meadow": {"ideas": ["guarded_lane", "dogleg", "bank_corner"], "terrain": "water", "branch": 0.22, "elevation": 0.0},
	&"desert": {"ideas": ["guarded_lane", "bank_corner", "switchback"], "terrain": "sand", "branch": 0.3, "elevation": 0.08},
	&"autumn": {"ideas": ["dogleg", "s_curve", "switchback"], "terrain": "water", "branch": 0.4, "elevation": 0.14},
	&"snow": {"ideas": ["bank_corner", "dogleg", "switchback"], "terrain": "ice", "branch": 0.25, "elevation": 0.22},
	&"swamp": {"ideas": ["dogleg", "switchback", "s_curve"], "terrain": "water", "branch": 0.5, "elevation": 0.12},
	&"volcanic": {"ideas": ["bank_corner", "switchback", "s_curve"], "terrain": "lava", "branch": 0.45, "elevation": 0.32},
}

# Coordinates are forward/sideways relative to the challenge. They never span
# the full lane: the opposite shoulder remains a safe, visible recovery route.
const CLUSTERS := [
	[Vector2i(0, 0)],
	[Vector2i(0, 0), Vector2i(0, -1)],
	[Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1)],
	[Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0)],
	[Vector2i(0, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(1, 0)],
	[Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, -1), Vector2i(0, -1)],
]

static func design_for(biome: StringName) -> Dictionary:
	return Dictionary(BIOME_DESIGNS.get(biome, BIOME_DESIGNS[&"meadow"])).duplicate(true)

static func anchors(idea: String, stretch: int, arc: int) -> Array[Vector2i]:
	var a := 7 + stretch
	var b := 6 + stretch
	match idea:
		"bank_corner":
			return [Vector2i.ZERO, Vector2i(a + 2, 0), Vector2i(a + 2, b)]
		"dogleg":
			return [Vector2i.ZERO, Vector2i(a, 0), Vector2i(a, b), Vector2i(a + 6, b)]
		"s_curve":
			return [Vector2i.ZERO, Vector2i(a, 0), Vector2i(a, b), Vector2i(a + 6, b), Vector2i(a + 6, 0), Vector2i(a + 12, 0)]
		"switchback":
			return [Vector2i.ZERO, Vector2i(a + 4, 0), Vector2i(a + 4, b + 2), Vector2i(1, b + 2)]
		_:
			return [Vector2i.ZERO, Vector2i(12 + stretch + arc * 2, 0)]

static func transform(cell: Vector2i, quarter_turns: int, mirror: bool) -> Vector2i:
	var result := Vector2i(cell.x, -cell.y if mirror else cell.y)
	for _turn in range(posmod(quarter_turns, 4)):
		result = Vector2i(-result.y, result.x)
	return result

static func line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = [from]
	var cell := from
	while cell != to:
		if cell.x != to.x:
			cell.x += signi(to.x - cell.x)
		else:
			cell.y += signi(to.y - cell.y)
		result.append(cell)
	return result

static func square(center: Vector2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			result.append(Vector2i(x, y))
	return result
