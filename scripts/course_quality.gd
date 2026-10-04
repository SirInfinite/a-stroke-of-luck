class_name CourseQuality
extends RefCounted

const Validator := preload("res://scripts/level_validator.gd")

## Cheap geometry only. This is a design heuristic, never a claim that a hole
## is fun or a substitute for physical/human playtesting.
static func metrics(level: Dictionary) -> Dictionary:
	var playable := {}
	for y in range(level.map.size()):
		for x in range(String(level.map[y]).length()):
			if level.map[y][x] != " ":
				playable[Vector2i(x, y)] = true
	var corridors: Array = level.get("shot_corridors", [])
	var placement_count := 0
	var relevant := 0
	var direct_hits := 0
	var roles := {}
	var clusters := {}
	var occupancy := Validator.placement_occupancy(level)
	var start := Vector2(level.start_cell)
	var finish := Vector2(level.hole_cell)
	for collection in ["hazards", "obstacles", "moving_hazards"]:
		for definition: Dictionary in level.get(collection, []):
			placement_count += 1
			var surfaces := Validator._definition_surfaces(level, definition)
			var interacts := false
			var direct := false
			for surface in surfaces:
				var point := Vector2(surface.x, surface.y)
				direct = direct or _distance_to_segment(point, start, finish) <= 0.55
				for corridor: Dictionary in corridors:
					# A broad, plausible shot envelope, not distance to a winding BFS.
					if _distance_to_segment(point, Vector2(corridor.from_cell), Vector2(corridor.to_cell)) <= 1.05:
						interacts = true
						break
			if interacts:
				relevant += 1
			if direct:
				direct_hits += 1
			roles[String(definition.get("placement_role", "unassigned"))] = true
			var cluster := String(definition.get("cluster_id", "%s%d" % [collection, placement_count]))
			if collection == "hazards":
				clusters[cluster] = int(clusters.get(cluster, 0)) + 1
	var direct_blocked_by_wall := not _line_clear(start, finish, playable, {})
	var direct_clear := _line_clear(start, finish, playable, occupancy)
	var clear_zones := 0
	for zone: Dictionary in level.get("shot_zones", []):
		var clear := true
		for cell: Vector2i in zone.cells:
			clear = clear and playable.has(cell) and not occupancy.has(Vector3i(cell.x, cell.y, int(zone.get("elevation", 0))))
		if clear:
			clear_zones += 1
	var route: Array = level.get("main_route_cells", [])
	var contiguous: bool = route.size() > 1 and route[0] == level.start_cell and route[-1] == level.hole_cell
	var turns := 0
	for index in range(1, route.size()):
		var delta: Vector2i = Vector2i(route[index]) - Vector2i(route[index - 1])
		contiguous = contiguous and absi(delta.x) + absi(delta.y) == 1
		if index > 1 and delta != Vector2i(route[index - 1]) - Vector2i(route[index - 2]):
			turns += 1
	var bank_corners := 0
	for index in range(1, corridors.size()):
		var first: Dictionary = corridors[index - 1]
		var second: Dictionary = corridors[index]
		if first.to_cell == second.from_cell and (Vector2i(first.to_cell) - Vector2i(first.from_cell)).sign() != (Vector2i(second.to_cell) - Vector2i(second.from_cell)).sign():
			bank_corners += 1
	var narrow := 0
	var unused := 0
	for cell: Vector2i in playable:
		var neighbors := 0
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			neighbors += 1 if playable.has(cell + direction) else 0
		if neighbors < 2:
			narrow += 1
		var distance := INF
		for corridor: Dictionary in corridors:
			distance = minf(distance, _distance_to_segment(Vector2(cell), Vector2(corridor.from_cell), Vector2(corridor.to_cell)))
		if distance > 2.5:
			unused += 1
	var cluster_sizes: Array[int] = []
	for value in clusters.values():
		cluster_sizes.append(int(value))
	cluster_sizes.sort()
	var density := float(occupancy.size()) / maxf(playable.size(), 1)
	var unguarded_shortcuts := 0
	for branch: Dictionary in level.get("branches", []):
		if branch.kind != "shortcut" or bool(branch.get("elevated", false)):
			continue
		var pressured := false
		for surface in occupancy:
			if _distance_to_segment(Vector2(surface.x, surface.y), Vector2(branch.entry_cell), Vector2(branch.exit_cell)) <= 0.55:
				pressured = true
		if not pressured:
			unguarded_shortcuts += 1
	return {
		"terrain_count": level.get("hazards", []).size(), "blocker_count": level.get("obstacles", []).size(),
		"placement_count": placement_count, "route_relevant_count": relevant,
		"route_relevant_ratio": float(relevant) / maxf(placement_count, 1),
		"direct_line_interactions": direct_hits, "direct_line_blocked_by_geometry": direct_blocked_by_wall,
		"trivial_direct_line": direct_clear, "challenge_role_count": roles.size(),
		"hazard_cluster_sizes": cluster_sizes, "route_turn_count": turns,
		"bank_opportunities": bank_corners, "clear_recovery_zones": clear_zones,
		"shot_section_count": corridors.size(), "route_contiguous": contiguous,
		"playable_cells": playable.size(), "unused_area_ratio": float(unused) / maxf(playable.size(), 1),
		"narrow_cells": narrow, "occupied_ratio": density,
		"minimum_shot_estimate": _shot_estimate(route, playable, occupancy),
		"branch_count": level.get("branches", []).size(), "moving_count": level.get("moving_hazards", []).size(),
		"elevation_feature_count": level.get("elevation_structures", []).size(),
		"unguarded_shortcuts": unguarded_shortcuts,
	}

static func score(level: Dictionary) -> Dictionary:
	var m := metrics(level)
	var arc := int(level.get("hole_index", 0))
	var hard := StringName(level.get("run_difficulty_id", &"normal")) == &"hard"
	var challenge: Dictionary = level.get("generation_challenge", {})
	var target := int(level.get("challenge_budget", 2 + arc)) + int(challenge.get("curse_count", 0))
	var guard_sections := int(m.hazard_cluster_sizes.size()) + int(m.blocker_count) + int(m.moving_count)
	var breakdown := {
		"route_clarity": 10.0 if bool(m.route_contiguous) else 0.0,
		"shot_interaction": 20.0 * float(m.route_relevant_ratio),
		"shot_rhythm": clampf(15.0 - absf(float(m.minimum_shot_estimate) - float(2 + arc)) * 2.0, 0.0, 15.0),
		"direct_line_pressure": 15.0 if not bool(m.trivial_direct_line) else 4.0 if arc == 0 and not hard else 0.0,
		"recovery": 15.0 * float(m.clear_recovery_zones) / maxf(level.get("shot_zones", []).size(), 1),
		"challenge_fit": clampf(10.0 - maxf(float(target - guard_sections), 0.0) * 1.5, 0.0, 10.0),
		"bank_and_choice": 8.0 if int(m.bank_opportunities) > 0 else 3.0,
		"composition": clampf(7.0 - float(m.unused_area_ratio) * 24.0 - float(m.narrow_cells) * 2.0, 0.0, 7.0),
		"penalties": -maxf(float(m.occupied_ratio) - 0.22, 0.0) * 60.0 - maxf(float(m.moving_count) - float(challenge.get("max_moving", 1)), 0.0) * 8.0 - maxf(float(m.elevation_feature_count) - 1.0, 0.0) * 2.0 - float(m.unguarded_shortcuts) * 8.0 - (20.0 if int(m.placement_count) == 0 else 0.0),
	}
	var total := 0.0
	for value in breakdown.values():
		total += float(value)
	return {"score": snappedf(clampf(total, 0, 100), 0.01), "breakdown": breakdown, "metrics": m}

static func _distance_to_segment(point: Vector2, from: Vector2, to: Vector2) -> float:
	var delta := to - from
	if delta.is_zero_approx():
		return point.distance_to(from)
	return point.distance_to(from + delta * clampf((point - from).dot(delta) / delta.length_squared(), 0, 1))

static func _line_clear(from: Vector2, to: Vector2, playable: Dictionary, occupancy: Dictionary) -> bool:
	var steps := maxi(ceili(from.distance_to(to) * 5.0), 1)
	for index in range(steps + 1):
		var point := from.lerp(to, float(index) / steps)
		var cell := Vector2i(point.round())
		if not playable.has(cell) or occupancy.has(Vector3i(cell.x, cell.y, 0)):
			return false
	return true

static func _shot_estimate(route: Array, playable: Dictionary, occupancy: Dictionary) -> int:
	if route.size() < 2:
		return 99
	var shots := 0
	var current := 0
	while current < route.size() - 1:
		var next := current + 1
		for index in range(current + 2, route.size()):
			if Vector2(route[current]).distance_to(Vector2(route[index])) > 10.0:
				break
			if _line_clear(Vector2(route[current]), Vector2(route[index]), playable, occupancy):
				next = index
		current = next
		shots += 1
	return shots
