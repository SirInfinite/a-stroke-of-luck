extends RefCounted
## Development diagnostics. Geometry/contact opportunity is not playability or fun.
const Validator := preload("res://scripts/level_validator.gd")
const Motifs := preload("res://scripts/course_motifs.gd")
const Generator := preload("res://scripts/hole_generator.gd")

static func measure(level: Dictionary) -> Dictionary:
	var cells := Validator._playable_cells(level)
	var occupancy := Validator.placement_occupancy(level)
	var threats := {}
	var footprints: Array[Dictionary] = []
	var affected := {}
	var corridor_samples := {}
	var threatened_samples := {}
	var centerline_samples := {}
	var threatened_centerline := {}
	var independent_by_type := {}
	for group in ["hazards", "obstacles", "moving_hazards"]:
		for index in Array(level.get(group, [])).size():
			var item: Dictionary = level[group][index]
			var identity := str(item.get("cluster_id", "%s_%d" % [group, index]))
			threats[identity] = true
			if not independent_by_type.has(item.type):
				independent_by_type[item.type] = {}
			independent_by_type[item.type][identity] = true
			var surfaces := Validator._definition_surfaces(level, item)
			footprints.append({"id": identity, "type": item.type, "role": item.get("placement_role", ""), "surfaces": surfaces, "elevation": item.get("elevation", 0)})
	# Baseline comparisons use the generator's declared ground corridors. The
	# benchmark additionally publishes layered centerlines below, separately.
	for index in Array(level.get("shot_corridors", [])).size():
		var corridor: Dictionary = level.shot_corridors[index]
		var from := Vector2i(corridor.from_cell)
		var to := Vector2i(corridor.to_cell)
		var direction := (to - from).sign()
		var side := Vector2i(-direction.y, direction.x)
		var elevation := int(corridor.get("elevation", 0))
		for cell in Motifs.line(from, to):
			var center := Vector3i(cell.x, cell.y, elevation)
			centerline_samples[center] = true
			if occupancy.has(center):
				threatened_centerline[center] = true
			for lateral in range(-int(corridor.width) / 2, int(corridor.width) / 2 + 1):
				var shifted := cell + side * lateral
				var surface := Vector3i(shifted.x, shifted.y, elevation)
				corridor_samples[surface] = true
				if occupancy.has(surface):
					threatened_samples[surface] = true
					affected[index] = true
	var surface_count := 0
	var geometry: Array = []
	for cell in cells:
		for elevation in Validator.cell_elevations(level, cell):
			surface_count += 1
			geometry.append([cell.x, cell.y, elevation])
	var recovery := {}
	for zone in level.get("shot_zones", []):
		for cell in zone.cells:
			recovery[Vector3i(cell.x, cell.y, int(zone.get("elevation", 0)))] = true
	var clear_recovery := recovery.keys().filter(func(s: Vector3i) -> bool: return not occupancy.has(s))
	var relevant := {}
	for footprint in footprints:
		for surface in footprint.surfaces:
			if corridor_samples.has(surface):
				relevant[footprint.id] = true
	var layered_routes: Array[Dictionary] = []
	for route in level.get("benchmark_routes", []):
		var hit := 0
		for cell in route.cells:
			if occupancy.has(cell):
				hit += 1
		layered_routes.append({"role": route.role, "cells": route.cells.size(), "affected_cells": hit, "width_px": route.width_px})
	for type in independent_by_type:
		independent_by_type[type] = independent_by_type[type].size()
	var tunnels := 0
	var tunnel_cells := 0
	for structure in level.get("elevation_structures", []):
		if structure.type == "overpass":
			tunnels += 1
			tunnel_cells += structure.cells.size()
	var corridors: Array = level.get("shot_corridors", [])
	return {
		"seed": level.get("run_seed", 0), "hole": level.get("overall_hole_number", 1),
		"difficulty": level.get("run_difficulty_id", "normal"), "biome": level.get("biome_id", "meadow"),
		"stage": ["early", "middle", "late"][clampi((int(level.get("overall_hole_number", 1)) - 1) / 6, 0, 2)],
		"idea": level.get("course_idea", "authored"), "motifs": level.get("selected_motifs", []),
		"width_cells": String(level.map[0]).length(), "height_cells": level.map.size(),
		"playable_cells": cells.size(), "surfaces": surface_count,
		"route_length_px": maxi(Array(level.get("main_route_cells", [])).size() - 1, 0) * 100,
		"corridor_lengths_px": corridors.map(func(c: Dictionary) -> int: return (absi(c.from_cell.x - c.to_cell.x) + absi(c.from_cell.y - c.to_cell.y)) * 100),
		"corridor_widths_px": corridors.map(func(c: Dictionary) -> int: return int(c.width) * 100),
		"independent_threats": threats.size(), "occupied_surfaces": occupancy.size(),
		"independent_by_type": independent_by_type, "route_relevant_threats": relevant.size(), "layered_routes": layered_routes,
		"footprints": footprints, "threats_per_100_surfaces": threats.size() * 100.0 / maxi(surface_count, 1),
		"corridors": corridors.size(), "affected_corridors": affected.size(),
		"corridor_surface_fraction": threatened_samples.size() / float(maxi(corridor_samples.size(), 1)),
		"centerline_surface_fraction": threatened_centerline.size() / float(maxi(centerline_samples.size(), 1)),
		"movers": Array(level.get("moving_hazards", [])).size(), "recovery_surfaces": recovery.size(),
		"clear_recovery_surfaces": clear_recovery.size(),
		"alternatives": Array(level.get("branches", [])).filter(func(b: Dictionary) -> bool: return b.kind != "dead_end").size(),
		"dead_ends": Array(level.get("branches", [])).filter(func(b: Dictionary) -> bool: return b.kind == "dead_end").size(),
		"elevation": not Array(level.get("elevation_transitions", [])).is_empty(), "underpasses": tunnels, "covered_cells": tunnel_cells,
		"valid": Validator.validate_level(level, 0, false), "fallback": level.get("used_fallback", false),
		"rejections": level.get("candidate_rejection_count", 0), "retries": level.get("generation_retry_count", 0),
		"quality_rejections": level.get("candidate_quality_rejection_count", 0), "selected_attempt": level.get("generation_attempt", 0),
		"candidates": level.get("candidate_count_considered", 0), "geometry_cells": geometry,
		"structural_signature": structural_signature(level), "start_cell": [level.start_cell.x, level.start_cell.y, int(level.get("start_elevation", 0))], "hole_cell": [level.hole_cell.x, level.hole_cell.y, int(level.get("hole_elevation", 0))],
		"old_proximity_fraction": Generator.quality_metrics(level).get("route_relevant_ratio", 0),
	}

static func structural_signature(level: Dictionary) -> String:
	# Includes route endpoints and ramp connections; excludes palette, hazard type,
	# seed, placement order and metadata. All eight square-grid symmetries normalize.
	var variants: Array[String] = []
	var cells := Validator._playable_cells(level)
	for turn in 4:
		for mirror in [false, true]:
			var minimum := Vector2i(100000, 100000)
			for cell in cells:
				minimum = minimum.min(Motifs.transform(cell, turn, mirror))
			var tokens: Array[String] = []
			for cell in cells:
				var point := Motifs.transform(cell, turn, mirror) - minimum
				for elevation in Validator.cell_elevations(level, cell):
					tokens.append("%d,%d,%d" % [point.x, point.y, elevation])
			for name in ["start_cell", "hole_cell"]:
				var point := Motifs.transform(level[name], turn, mirror) - minimum
				tokens.append("%s:%d,%d" % [name, point.x, point.y])
				var endpoint_layer := int(level.get("start_elevation" if name == "start_cell" else "hole_elevation", 0))
				# Zero is the implicit default, preserving existing flat signatures.
				if endpoint_layer != 0:
					tokens.append("%s_layer:%d" % [name, endpoint_layer])
			for ramp in level.get("elevation_transitions", []):
				var first := Motifs.transform(ramp.from_cell, turn, mirror) - minimum
				var second := Motifs.transform(ramp.to_cell, turn, mirror) - minimum
				var ends: Array[String] = ["%d,%d,%d" % [first.x, first.y, ramp.from_elevation], "%d,%d,%d" % [second.x, second.y, ramp.to_elevation]]
				ends.sort()
				tokens.append("ramp:" + ">".join(ends))
			tokens.sort()
			variants.append(";".join(tokens))
	variants.sort()
	return variants[0].sha256_text()
