class_name CourseGrammar
extends RefCounted

const Motifs := preload("res://scripts/course_motifs.gd")
const Hazards := preload("res://scripts/gameplay_hazard.gd")
const Validator := preload("res://scripts/level_validator.gd")
const Profiles := preload("res://scripts/biome_hazard_profiles.gd")
const Challenge := preload("res://scripts/generation_challenge.gd")
const VERSION := 3
const CELL := 100.0

var rng := RandomNumberGenerator.new()
var playable := {}
var primary_cells := {}
var levels := {}
var protected := {}
var occupied := {}
var anchors: Array[Vector2i] = []
var design_route: Array[Vector2i] = []
var slots: Array[Dictionary] = []
var zones: Array[Dictionary] = []
var branches: Array[Dictionary] = []
var structures: Array[Dictionary] = []
var transitions: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var obstacles: Array[Dictionary] = []
var moving: Array[Dictionary] = []
var motifs: Array[String] = []
var rows: Array[String] = []
var easy := false
var hard := false
var arc := 0
var biome := &"meadow"
var design := {}
var rotation := 0
var mirrored := false
var offset := Vector2i.ZERO
var lane_radius := 1
var plan := {}
var challenge := {}

static func compose(profile, seed_value: int, biome_index: int, hole_index: int, attempt: int, options: Dictionary) -> Dictionary:
	var grammar := CourseGrammar.new()
	return grammar._compose(profile, seed_value, biome_index, hole_index, attempt, options)

func _compose(profile, seed_value: int, biome_index: int, hole_index: int, attempt: int, options: Dictionary) -> Dictionary:
	biome = profile.id
	arc = hole_index
	easy = StringName(options.get("difficulty_id", &"normal")) == &"easy"
	hard = StringName(options.get("difficulty_id", &"normal")) == &"hard"
	design = Motifs.design_for(biome)
	challenge = Challenge.resolve(StringName(options.get("difficulty_id", &"normal")), biome_index, arc, design, options)
	var identity := "%d/%d/%d/%s/v%d" % [seed_value, biome_index, arc, options.get("difficulty_id", &"normal"), VERSION]
	var idea_rng := RandomNumberGenerator.new()
	idea_rng.seed = identity.hash()
	var ideas: Array = design.ideas
	var idea := String(ideas[idea_rng.randi_range(0, ideas.size() - 1)])
	if arc == 0:
		idea = "dogleg" if biome in [&"autumn", &"swamp"] else "bank_corner"
		if biome == &"desert" and idea_rng.randf() < 0.5:
			idea = "guarded_lane"
	if arc == 0 and biome == &"meadow":
		idea = "guarded_lane" if idea_rng.randf() < 0.55 else "bank_corner"
	if easy and idea == "s_curve":
		idea = "dogleg"
	if arc == 2 and idea == "bank_corner":
		idea = "dogleg"
	var elevation_chance := float(challenge.elevation_chance)
	var elevated := idea_rng.randf() < elevation_chance
	var branch_chance := float(challenge.branch_chance)
	var branch_kind := ""
	if elevated or (arc > 0 and idea_rng.randf() < branch_chance):
		idea = "switchback"
		branch_kind = "shortcut" if hard or biome == &"swamp" else "alternate"
	elif arc > 0 and idea_rng.randf() < float(challenge.dead_end_chance):
		branch_kind = "dead_end"
	# Candidate variation cannot silently replace the selected course idea with
	# whichever topology accumulates the most quality points.
	var effect_signature := ""
	if int(options.get("added_hazard_count", 0)) > 0:
		effect_signature = "/%d/%s/%d" % [clampi(int(options.added_hazard_count), 0, 4), options.get("preferred_hazard_type", "direction"), options.get("modifier_seed", 0)]
	rng.seed = (identity + "/%d" % attempt + effect_signature).hash()
	var parameters: Dictionary = profile.generator_difficulty
	var stretch := rng.randi_range(0, clampi(int(parameters.get("section_stretch", 1)), 0, 3))
	stretch += int(challenge.stretch)
	rotation = rng.randi_range(0, 1) * 2
	if idea == "bank_corner" and rng.randf() < 0.3:
		rotation = 1
	mirrored = rng.randi_range(0, 1) == 1
	lane_radius = clampi(int(parameters.get("lane_radius_easy" if easy else "lane_radius_hard" if hard else "lane_radius_normal", 2 if easy else 1)), 1, 2)
	var raw_anchors := Motifs.anchors(idea, stretch, arc)
	for cell in raw_anchors:
		anchors.append(_transform(cell))
	for index in range(anchors.size() - 1):
		var segment := Motifs.line(anchors[index], anchors[index + 1])
		for cell in segment:
			_carve(cell, lane_radius)
			if design_route.is_empty() or design_route[-1] != cell:
				design_route.append(cell)
		var direction := (anchors[index + 1] - anchors[index]).sign()
		for position_index in range(3, segment.size() - 3, 3):
			slots.append({"cell": segment[position_index], "direction": direction, "segment": index, "role": "lane_pressure"})
		if segment.size() >= 7 and not slots.any(func(slot: Dictionary) -> bool: return slot.segment == index):
			slots.append({"cell": segment[segment.size() / 2], "direction": direction, "segment": index, "role": "lane_pressure"})
	motifs.append(idea)
	for index in range(anchors.size()):
		var role := "tee" if index == 0 else "cup" if index == anchors.size() - 1 else "recovery"
		_add_zone(anchors[index], role, maxi(int(challenge.recovery_radius), clampi(int(parameters.get("recovery_radius", 1)), 1, 2)))
	if anchors.size() > 2:
		motifs.append("recovery_pocket")
	primary_cells = playable.duplicate()
	if branch_kind == "dead_end":
		_add_dead_end(raw_anchors)
	elif not branch_kind.is_empty():
		_add_shortcut(raw_anchors, branch_kind, elevated, idea_rng.randf() < float(challenge.crossing_chance))
	_normalize()
	plan = {"map": rows, "hazards": hazards, "obstacles": obstacles, "moving_hazards": moving}
	var target_clusters := int(challenge.terrain_clusters)
	_place_terrain(String(design.terrain), "sand_choke" if biome == &"desert" else "ice_runout" if biome == &"snow" else "water_gate")
	var moving_type := Profiles.moving_hazard_for(biome, arc)
	if not moving_type.is_empty() and idea_rng.randf() < float(challenge.moving_chance):
		_place_moving(moving_type)
	if not moving_type.is_empty() and idea_rng.randf() < float(challenge.second_moving_chance):
		_place_moving(moving_type)
	# Reserve physical blockers before filling spare slots with terrain guards.
	var blocker_count := int(challenge.blockers)
	for index in range(blocker_count):
		_place_blocker(index)
	for index in range(1, target_clusters):
		var terrain := String(design.terrain)
		if index == 1 and biome in [&"desert", &"snow"]:
			terrain = "water"
		_place_terrain(terrain, "sand_approach" if terrain == "sand" else "water_approach" if terrain in ["water", "lava"] else "ice_runout", index == target_clusters - 1)
	if arc > 0 and rng.randf() < (0.7 if biome == &"desert" else 0.32):
		_place_bounce()
	var curse_count := 0
	for index in range(int(challenge.curse_count)):
		if _place_curse(String(options.get("preferred_hazard_type", "direction")), index):
			curse_count += 1
	var elevation_cells: Array[Dictionary] = []
	for cell in _ordered(playable):
		elevation_cells.append({"cell": cell, "levels": levels.get(cell, [0])})
	plan.merge({
		"start_cell": anchors[0], "hole_cell": anchors[-1], "start_elevation": 0, "hole_elevation": 0,
		"par": 3 if arc == 0 else 4, "cup_radius": 32.0 - float(arc) * 4.0,
		"tee": {"cell": anchors[0], "elevation": 0}, "branches": branches,
		"elevation_cells": elevation_cells, "elevation_transitions": transitions, "elevation_structures": structures,
		"design_route_cells": design_route, "shot_zones": zones, "shot_corridors": _corridors(),
		"primary_corridor_cells": _ordered(primary_cells),
		"main_route_cells": _safe_route(anchors[0], anchors[-1]), "visual_rough_cells": [],
		"selected_motifs": motifs, "course_idea": idea, "grammar_version": VERSION,
		"biome_arc": ["introduce", "develop", "climax"][arc], "challenge_budget": target_clusters + blocker_count,
		"generation_challenge": challenge.duplicate(true),
		"lane_width_cells": lane_radius * 2 + 1, "card_hazard_count": curse_count,
		"generation_options": options.duplicate(true), "placement_reservations": _ordered_surfaces(occupied),
		"recovery_reservations": _ordered(protected), "generation_identity": identity,
	}, true)
	var approach := "open_green" if arc == 0 else "angled_green" if anchors.size() > 2 else "guarded_green"
	if not motifs.has(approach):
		motifs.append(approach)
	return plan

func _transform(cell: Vector2i) -> Vector2i:
	return Motifs.transform(cell, rotation, mirrored)

func _carve(center: Vector2i, radius: int) -> void:
	for cell in Motifs.square(center, radius):
		playable[cell] = true

func _add_zone(cell: Vector2i, role: String, radius: int) -> void:
	_carve(cell, radius)
	var cells := Motifs.square(cell, 1)
	for zone_cell in cells:
		protected[zone_cell] = true
	zones.append({"cell": cell, "cells": cells, "role": role, "elevation": 0})

func _add_dead_end(_raw_anchors: Array[Vector2i]) -> void:
	var entry := Vector2i(4, 0)
	var end := Vector2i(4, -4)
	var cells: Array[Vector2i] = []
	for cell in Motifs.line(entry, end):
		var world_cell := _transform(cell)
		cells.append(world_cell)
		_carve(world_cell, 1)
	_add_zone(_transform(end), "dead_end_recovery", 1)
	branches.append({"kind": "dead_end", "cells": cells, "entry_cell": cells[0], "escape_cell": cells[0], "exit_cell": null, "temptation": "overshoot_bank"})
	protected[cells[0]] = true
	motifs.append("dead_end_bait")

func _add_shortcut(raw_anchors: Array[Vector2i], kind: String, elevated: bool, crossing: bool) -> void:
	var bottom := raw_anchors[-1].y
	var entry := Vector2i(4, 0)
	var exit_cell := Vector2i(4, bottom)
	var cells: Array[Vector2i] = []
	for cell in Motifs.line(entry, exit_cell):
		cells.append(_transform(cell))
		_carve(_transform(cell), 1)
	branches.append({"kind": kind, "cells": cells, "entry_cell": cells[0], "escape_cell": cells[0], "exit_cell": cells[-1], "temptation": "shorter_tighter_line", "elevated": elevated})
	protected[cells[0]] = true
	protected[cells[-1]] = true
	motifs.append("risky_shortcut" if kind == "shortcut" else "split_route")
	if not elevated:
		slots.append({"cell": _transform(Vector2i(4, bottom / 2)), "direction": _transform(Vector2i.DOWN), "segment": -1, "role": "shortcut_guard"})
		return
	var elevation := -1 if biome in [&"autumn", &"swamp"] or rng.randf() < 0.3 else 1
	var elevated_cells: Array[Vector2i] = []
	# Three-cell-wide platform; the optional short crossing pinches to two.
	for y in range(2, bottom - 1):
		for x in range(3, 6):
			var cell := _transform(Vector2i(x, y))
			levels[cell] = [elevation]
			elevated_cells.append(cell)
	for x in range(3, 6):
		for endpoint in [1, bottom - 2]:
			var from_cell := _transform(Vector2i(x, endpoint))
			var to_cell := _transform(Vector2i(x, endpoint + 1))
			transitions.append({"type": "ramp", "from_cell": from_cell, "to_cell": to_cell, "from_elevation": 0 if endpoint == 1 else elevation, "to_elevation": elevation if endpoint == 1 else 0, "width": CELL})
			protected[from_cell] = true
			protected[to_cell] = true
	structures.append({"type": "lower_area" if elevation < 0 else "bridge", "cells": elevated_cells, "elevation": elevation})
	motifs.append("recessed_cut" if elevation < 0 else "raised_bridge")
	if crossing and elevation > 0:
		# Crossing is perpendicular to a deliberately two-cell pinch in the deck.
		# The lower route reconnects; it is not a decorative blind underground spur.
		var y := bottom / 2
		var removed := _transform(Vector2i(5, y))
		levels[removed] = [0]
		elevated_cells.erase(removed)
		var tunnel: Array[Vector2i] = []
		for x in range(0, raw_anchors[1].x + 1):
			var cell := _transform(Vector2i(x, y))
			playable[cell] = true
			if x in [3, 4]:
				levels[cell] = [0, 1]
				tunnel.append(cell)
		for cell in Motifs.line(Vector2i.ZERO, Vector2i(0, y)):
			_carve(_transform(cell), 1)
		structures.append({"type": "overpass", "cells": tunnel, "elevation": 1, "lower_elevation": 0, "tunnel_length": 2})
		motifs.append("short_tunnel")

func _normalize() -> void:
	var minimum := Vector2i(999, 999)
	var maximum := Vector2i(-999, -999)
	for cell: Vector2i in playable:
		minimum = minimum.min(cell)
		maximum = maximum.max(cell)
	offset = -minimum
	var shifted := {}
	var shifted_levels := {}
	var shifted_protected := {}
	var shifted_primary := {}
	for cell: Vector2i in playable:
		shifted[cell + offset] = true
	for cell: Vector2i in levels:
		shifted_levels[cell + offset] = levels[cell]
	for cell: Vector2i in protected:
		shifted_protected[cell + offset] = true
	for cell: Vector2i in primary_cells:
		shifted_primary[cell + offset] = true
	playable = shifted
	levels = shifted_levels
	protected = shifted_protected
	primary_cells = shifted_primary
	_shift_cells(anchors)
	_shift_cells(design_route)
	for slot in slots:
		slot.cell += offset
	for zone in zones:
		zone.cell += offset
		_shift_cells(zone.cells)
	for branch in branches:
		_shift_cells(branch.cells)
		branch.entry_cell += offset
		branch.escape_cell += offset
		if branch.exit_cell != null:
			branch.exit_cell += offset
	for structure in structures:
		_shift_cells(structure.cells)
	for transition in transitions:
		transition.from_cell += offset
		transition.to_cell += offset
	var dimensions := maximum - minimum + Vector2i.ONE
	for y in range(dimensions.y):
		var row := ""
		for x in range(dimensions.x):
			row += "#" if playable.has(Vector2i(x, y)) else " "
		rows.append(row)

func _shift_cells(cells: Array) -> void:
	for index in range(cells.size()):
		cells[index] = Vector2i(cells[index]) + offset

func _world(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5) - Vector2(rows[0].length(), rows.size()) * 0.5) * CELL

func _eligible(cell: Vector2i) -> bool:
	return playable.has(cell) and not protected.has(cell) and levels.get(cell, [0]).has(0) and not occupied.has(Vector3i(cell.x, cell.y, 0))

func _choose_slot(approach := false) -> Dictionary:
	var choices: Array[Dictionary] = []
	for slot in slots:
		if _eligible(slot.cell) and _has_challenge_spacing(slot.cell):
			choices.append(slot)
	if choices.is_empty():
		return {}
	if approach:
		choices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return Vector2(a.cell).distance_squared_to(anchors[-1]) < Vector2(b.cell).distance_squared_to(anchors[-1]))
		return choices[0]
	return choices[rng.randi_range(0, choices.size() - 1)]

func _has_challenge_spacing(cell: Vector2i) -> bool:
	for surface: Vector3i in occupied:
		if surface.z == 0 and absi(surface.x - cell.x) + absi(surface.y - cell.y) <= 1:
			return false
	return true

func _base_hazard(type: String, cell: Vector2i) -> Dictionary:
	return {"type": type, "pos": _world(cell), "size": Vector2.ONE * CELL, "elevation": 0, "intensity": 0.22 if type == "ice" else 1.0, "seed": maxi(rng.randi(), 1)}

func _place_terrain(type: String, motif: String, approach := false) -> void:
	var slot := _choose_slot(approach)
	if slot.is_empty():
		return
	var shape_index := Challenge.cluster_shape(challenge, rng.randf())
	var shape: Array = Motifs.CLUSTERS[shape_index]
	var direction: Vector2i = slot.direction
	var perpendicular := Vector2i(-direction.y, direction.x) * (-1 if rng.randf() < 0.5 else 1)
	var cells: Array[Vector2i] = []
	for local: Vector2i in shape:
		var cell: Vector2i = slot.cell + direction * local.x + perpendicular * (local.y + (1 if bool(challenge.guard_shoulder) and slot.role != "shortcut_guard" else 0))
		if not _eligible(cell) or not _has_challenge_spacing(cell):
			continue
		if not cells.is_empty() and not cells.any(func(other: Vector2i) -> bool: return absi(other.x - cell.x) + absi(other.y - cell.y) == 1):
			continue
		cells.append(cell)
	var cluster := "%s_%d" % [type, hazards.size()]
	var accepted: Array[Dictionary] = []
	var accepted_cells: Array[Vector2i] = []
	for cell in cells:
		if not accepted_cells.is_empty() and not accepted_cells.any(func(other: Vector2i) -> bool: return absi(other.x - cell.x) + absi(other.y - cell.y) == 1):
			continue
		var definition := _base_hazard(type, cell)
		definition.merge({"cluster_id": cluster, "cluster_size": cells.size(), "placement_role": "approach_guard" if approach else slot.role, "motif": motif})
		if _accept(definition, hazards):
			accepted.append(definition)
			accepted_cells.append(cell)
	for definition in accepted:
		definition.cluster_size = accepted.size()
	if not accepted.is_empty() and not motifs.has(motif):
		motifs.append(motif)

func _place_blocker(index: int) -> void:
	var slot := _choose_slot(index == 0 and arc > 0)
	if slot.is_empty():
		return
	if index > 0:
		var direction: Vector2i = slot.direction
		var stagger: Vector2i = slot.cell + Vector2i(-direction.y, direction.x) * (-1 if index % 2 == 0 else 1)
		if _eligible(stagger):
			slot = slot.duplicate()
			slot.cell = stagger
	var definition := {"type": "blocker", "pos": _world(slot.cell), "size": Vector2(42, 86) if slot.direction.x != 0 else Vector2(86, 42), "elevation": 0, "placement_role": "bank_guard" if index == 0 else "staggered_guard"}
	if not _accept(definition, obstacles):
		return
	var motif := "offset_blocker" if index == 0 else "staggered_slalom"
	if not motifs.has(motif):
		motifs.append(motif)

func _place_moving(type: String) -> void:
	var slot := _choose_slot()
	if slot.is_empty():
		return
	var definition := {"type": type, "pos": _world(slot.cell), "size": Vector2(38, 38), "elevation": 0, "period": 3.0 if easy else 2.8 if not hard else 2.5, "phase": rng.randf(), "intensity": 0.8, "blocks_main_route": false, "placement_role": "timing_gate"}
	match type:
		"pendulum":
			definition.merge({"travel_radius": 56.0, "swing_angle": 0.9})
			# The runtime pendulum swings BELOW its anchor, not about its center.
			definition.pos -= Vector2(0, 56)
		"falling_ice":
			definition.merge({"size": Vector2(CELL, CELL), "telegraph_duration": 0.95 if easy else 0.85, "active_duration": 0.55, "cooldown_duration": 1.15, "drop_distance": 110.0}, true)
		"rotating_fire_rod":
			definition.merge({"size": Vector2(82, 20), "angular_speed": 1.45 if easy else 1.65})
	if _accept(definition, moving):
		var motif := "pendulum_gate" if type == "pendulum" else "falling_ice_gate" if type == "falling_ice" else "rotating_gate"
		if not motifs.has(motif):
			motifs.append(motif)

func _place_bounce() -> void:
	var slot := _choose_slot()
	if slot.is_empty():
		return
	var definition := _base_hazard("bounce_pad", slot.cell)
	definition.merge({"size": Vector2(78, 78), "minimum_exit_speed": Hazards.MIN_BOUNCE_SPEED, "speed_multiplier": Hazards.DEFAULT_BOUNCE_SPEED_MULTIPLIER, "maximum_exit_speed": Hazards.MAX_BOUNCE_SPEED, "retrigger_cooldown": Hazards.DEFAULT_RETRIGGER_COOLDOWN, "placement_role": "bank_launch", "cluster_id": "bounce_%d" % hazards.size(), "cluster_size": 1})
	# Keep the existing seeded random bounce rule. Select a seed whose FIRST
	# launch feeds the onward lane; later launches still use the same RNG rule.
	for _choice in range(96):
		definition.seed = maxi(rng.randi(), 1)
		var velocity := Hazards.deterministic_bounce_velocity(Vector2.RIGHT * 650.0, definition.seed, 0)
		if velocity.normalized().dot(Vector2(slot.direction)) < 0.92:
			continue
		if _clear_exit(definition.pos, velocity.normalized(), slot.cell):
			definition["launch_target"] = definition.pos + velocity.normalized() * 200.0
			if _accept(definition, hazards):
				motifs.append("bounce_bank")
			return

func _clear_exit(origin: Vector2, direction: Vector2, own_cell: Vector2i) -> bool:
	for distance in [60.0, 100.0, 150.0, 200.0]:
		var point: Vector2 = origin + direction * float(distance)
		var cell := Vector2i((point / CELL + Vector2(rows[0].length(), rows.size()) * 0.5).floor())
		if cell != own_cell and (not playable.has(cell) or not levels.get(cell, [0]).has(0) or occupied.has(Vector3i(cell.x, cell.y, 0))):
			return false
	return true

func _place_curse(type: String, index: int) -> bool:
	if not type in ["water", "lava", "sand", "ice", "direction", "blocker"]:
		type = "direction"
	var grow_formation := type in ["water", "lava", "sand", "ice"] and rng.randf() < 0.5
	var choices: Array[Dictionary] = []
	for corridor: Dictionary in _corridors():
		var from: Vector2i = corridor.from_cell
		var to: Vector2i = corridor.to_cell
		var direction := (to - from).sign()
		for center in Motifs.line(from, to):
			for side in [0, -1, 1]:
				var cell: Vector2i = center + Vector2i(-direction.y, direction.x) * int(side)
				if not _eligible(cell):
					continue
				var neighbors := _neighboring_formation(type, cell)
				if neighbors.size() >= 5:
					continue
				var nearest := 999
				for surface: Vector3i in occupied:
					nearest = mini(nearest, absi(surface.x - cell.x) + absi(surface.y - cell.y))
				var growth_bonus := 10.0 if grow_formation and not neighbors.is_empty() else 0.0
				choices.append({"cell": cell, "direction": direction, "priority": minf(nearest, 3) * 4.0 - absf(side) * 2.0 + growth_bonus + rng.randf()})
	choices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.priority) > float(b.priority))
	for choice in choices:
		var definition := _base_hazard(type, choice.cell)
		definition.merge({"cluster_id": "curse_%d" % index, "cluster_size": 1, "placement_role": "curse_lane_guard", "curse_added": true})
		if type == "direction":
			var direction: Vector2i = choice.direction
			definition["direction"] = Vector2(-direction.y, direction.x)
		if type == "blocker":
			definition.size = Vector2(48, 76)
		var target: Array[Dictionary] = obstacles if type == "blocker" else hazards
		if not _accept(definition, target):
			continue
		if _all_clear_surfaces_recoverable() and not _safe_route(anchors[0], anchors[-1]).is_empty() and _existing_launches_clear():
			# A terrain curse can extend an existing guard into one connected
			# formation. Never accidentally join several guards into a large blob.
			var neighbors := _neighboring_formation(type, choice.cell)
			if not neighbors.is_empty():
				var cluster_id: String = neighbors[0].cluster_id
				for member: Dictionary in neighbors:
					member.cluster_id = cluster_id
					member.cluster_size = neighbors.size()
			return true
		target.pop_back()
		for surface in Validator._definition_surfaces(plan, definition):
			occupied.erase(surface)
	return false

func _neighboring_formation(type: String, cell: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if type not in ["water", "lava", "sand", "ice"]:
		return result
	var ids := {}
	for hazard in hazards:
		if hazard.type != type:
			continue
		var other := Vector2i((Vector2(hazard.pos) / CELL + Vector2(rows[0].length(), rows.size()) * 0.5).floor())
		if absi(other.x - cell.x) + absi(other.y - cell.y) <= 1:
			ids[hazard.cluster_id] = true
	for hazard in hazards:
		if ids.has(hazard.get("cluster_id", "")):
			result.append(hazard)
	return result

func _all_clear_surfaces_recoverable() -> bool:
	var lookup := {}
	var count := 0
	for cell: Vector2i in playable:
		lookup[cell] = levels.get(cell, [0])
		count += lookup[cell].size()
	var context := {"start_cell": anchors[0], "elevation_transitions": transitions}
	var reachable := Validator._reachable_clear_surfaces(context, lookup, occupied)
	return reachable.size() + occupied.size() == count

func _existing_launches_clear() -> bool:
	for pad: Dictionary in hazards:
		if pad.type != "bounce_pad":
			continue
		var direction := Hazards.deterministic_bounce_velocity(Vector2.RIGHT * 650, int(pad.seed), 0).normalized()
		var cell := Vector2i((Vector2(pad.pos) / CELL + Vector2(rows[0].length(), rows.size()) * 0.5).floor())
		if not _clear_exit(pad.pos, direction, cell):
			return false
	return true

func _accept(definition: Dictionary, target: Array[Dictionary]) -> bool:
	var footprints := Validator._definition_surfaces(plan, definition)
	if footprints.is_empty():
		return false
	for surface in footprints:
		if not _eligible(Vector2i(surface.x, surface.y)):
			return false
	for surface in footprints:
		occupied[surface] = true
	# High-pressure combinations may individually fit yet seal a lane together.
	# Keep a recoverable corridor after EACH reservation, including base hazards;
	# curses are not the only placements that need this safety contract.
	if _safe_route(anchors[0], anchors[-1]).is_empty() or not _all_clear_surfaces_recoverable():
		for surface in footprints:
			occupied.erase(surface)
		return false
	target.append(definition)
	return true

func _safe_route(start: Vector2i, finish: Vector2i) -> Array[Vector2i]:
	var frontier: Array[Vector2i] = [start]
	var previous := {start: start}
	var cursor := 0
	while cursor < frontier.size():
		var cell := frontier[cursor]
		cursor += 1
		if cell == finish:
			var path: Array[Vector2i] = [finish]
			while path[-1] != start:
				path.append(previous[path[-1]])
			path.reverse()
			return path
		for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var next: Vector2i = cell + direction
			if previous.has(next) or not primary_cells.has(next) or not levels.get(next, [0]).has(0) or occupied.has(Vector3i(next.x, next.y, 0)):
				continue
			previous[next] = cell
			frontier.append(next)
	return []

func _corridors() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(anchors.size() - 1):
		result.append({"from_cell": anchors[index], "to_cell": anchors[index + 1], "width": lane_radius * 2 + 1})
	for branch in branches:
		if branch.exit_cell != null:
			result.append({"from_cell": branch.entry_cell, "to_cell": branch.exit_cell, "width": 3, "optional": true})
	return result

static func _ordered(lookup: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in lookup:
		cells.append(cell)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return cells

static func _ordered_surfaces(lookup: Dictionary) -> Array[Vector3i]:
	var surfaces: Array[Vector3i] = []
	for surface: Vector3i in lookup:
		surfaces.append(surface)
	surfaces.sort_custom(func(a: Vector3i, b: Vector3i) -> bool: return a.z < b.z or (a.z == b.z and (a.y < b.y or (a.y == b.y and a.x < b.x))))
	return surfaces
