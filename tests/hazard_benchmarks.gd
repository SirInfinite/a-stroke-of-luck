extends RefCounted
## Authored encounter experiments, deliberately outside production generation.
## Uses the existing grammar's cell construction and the full generated validator.
const Grammar := preload("res://scripts/course_grammar.gd")
const Motifs := preload("res://scripts/course_motifs.gd")
const Metrics := preload("res://tests/hazard_course_metrics.gd")
const IDS := ["A1", "A2", "A3", "B1", "B2", "B3", "C1", "C2", "C3"]
const NAMES := ["Bell Bank", "Long Fuse", "Hook Return", "Crosswind Fork", "Offset Sluice", "Late Fork", "Return Under", "Low Bow", "Offset Weave"]
const SEEDS := [910101, 910102, 910103, 910201, 910202, 910203, 910301, 910302, 910303]
const SAMPLE_VERSION := 2
const ARC_PERIOD_SCALES := [1.08, 1.0, 0.94]

var grammar := Grammar.new()
var corridors: Array[Dictionary] = []
var placements: Array[Dictionary] = []
var extra_routes: Array[Dictionary] = []
var setup_cell := Vector2i.ZERO
var notes := {}
var index := 0
var difficulty := &"normal"

static func build(id: String, tier: StringName = &"normal") -> Dictionary:
	var fixture := new()
	fixture.index = IDS.find(id.to_upper())
	if fixture.index < 0 or tier not in [&"easy", &"normal", &"hard"]:
		return {}
	fixture.difficulty = tier
	return fixture._build()

func _build() -> Dictionary:
	match index / 3:
		0: _bank(index % 3)
		1: _split(index % 3)
		2: _loop(index % 3)
	_direction_correction()
	grammar.primary_cells = grammar.playable.duplicate()
	# The authored primary route is ground-only. Optional decks are validated
	# through the position/elevation graph, never by their screen-space crossing.
	for cell: Vector2i in grammar.levels:
		if not Array(grammar.levels[cell]).has(0):
			grammar.primary_cells.erase(cell)
	grammar._normalize()
	var level := {"map": grammar.rows, "hazards": grammar.hazards, "obstacles": grammar.obstacles, "moving_hazards": grammar.moving}
	for placement in placements:
		var cell: Vector2i = placement.cell + grammar.offset
		var definition: Dictionary = placement.definition.duplicate(true)
		definition["pos"] = grammar._world(cell) + Vector2(definition.get("offset", Vector2.ZERO))
		definition.erase("offset")
		definition["id"] = "%s/v%d/%s/%d,%d" % [IDS[index], SAMPLE_VERSION, definition.get("cluster_id", "mechanism_%d" % grammar.moving.size() if definition.type == "pendulum" else "bank_%d" % grammar.obstacles.size()), cell.x, cell.y]
		definition["interaction"] = _interaction_for(definition)
		var target: Array[Dictionary] = grammar.moving if definition.type == "pendulum" else grammar.obstacles if definition.type == "blocker" else grammar.hazards
		target.append(definition)
		for surface in LevelValidator._definition_surfaces(level, definition):
			grammar.occupied[surface] = true
	var elevations: Array[Dictionary] = []
	for cell in Grammar._ordered(grammar.playable):
		elevations.append({"cell": cell, "levels": grammar.levels.get(cell, [0])})
	for corridor in corridors:
		corridor.from_cell += grammar.offset
		corridor.to_cell += grammar.offset
	for route in extra_routes:
		for n in route.cells.size():
			route.cells[n] += Vector3i(grammar.offset.x, grammar.offset.y, 0)
	level.merge({
		"start_cell": grammar.anchors[0], "hole_cell": grammar.anchors[-1], "par": 3 if index == 0 else 4,
		"start_elevation": 0, "hole_elevation": 0, "cup_radius": 28.0,
		"tee": {"cell": grammar.anchors[0], "elevation": 0}, "main_route_cells": grammar._safe_route(grammar.anchors[0], grammar.anchors[-1]),
		"primary_corridor_cells": Grammar._ordered(grammar.primary_cells), "design_route_cells": grammar.design_route,
		"shot_corridors": corridors, "shot_zones": grammar.zones, "branches": grammar.branches,
		"elevation_cells": elevations, "elevation_transitions": grammar.transitions, "elevation_structures": grammar.structures,
		"recovery_reservations": Grammar._ordered(grammar.protected), "placement_reservations": Grammar._ordered_surfaces(grammar.occupied),
		"grammar_version": Grammar.VERSION, "generation_options": {}, "card_hazard_count": 0, "visual_rough_cells": [],
		"course_idea": ["bank_corner", "split_route", "loop"][index / 3], "selected_motifs": grammar.motifs,
		"lane_width_cells": 3, "challenge_budget": placements.size(), "biome_arc": "benchmark",
		"benchmark_id": IDS[index], "benchmark_name": NAMES[index], "benchmark_notes": notes,
		"benchmark_version": SAMPLE_VERSION, "generation_identity": "%s/v%d/%s" % [IDS[index], SAMPLE_VERSION, difficulty],
		"benchmark_routes": extra_routes, "benchmark_setup_cell": setup_cell + grammar.offset,
	}, true)
	var biome_index := 0 if index < 3 else 1 if index < 6 else 2
	HoleGenerator._apply_profile_metadata(level, BiomeDatabase.get_profiles()[biome_index], SEEDS[index], biome_index, index % 3, 1, false, DifficultyDatabase.get_profile(difficulty).generation_options())
	level["generation_challenge"] = GenerationChallenge.resolve(difficulty, biome_index, index % 3, Motifs.design_for(level.biome_id), {})
	level["sample_course_modifiers"] = {"added_hazard_count": 0, "cup_scale": 1.0}
	level["quality_score"] = HoleGenerator.score_candidate(level).score
	level["candidate_scores"] = []
	level["fallback_reason"] = ""
	level["benchmark_signature"] = Metrics.structural_signature(level)
	return level

func _route(points: Array[Vector2i], width := 3, primary := false, name := "alternate") -> void:
	var cells: Array[Vector2i] = []
	for n in range(points.size() - 1):
		var segment := Motifs.line(points[n], points[n + 1])
		for cell in segment:
			grammar._carve(cell, width / 2)
			if cells.is_empty() or cells[-1] != cell:
				cells.append(cell)
		corridors.append({"from_cell": points[n], "to_cell": points[n + 1], "width": width, "optional": not primary, "role": name})
	if primary:
		grammar.anchors = points.duplicate()
		grammar.design_route = cells
		grammar._add_zone(points[0], "tee", 1)
		grammar._add_zone(points[-1], "cup", 1)
	else:
		grammar.branches.append({"kind": name if name in ["shortcut", "dead_end"] else "alternate", "cells": cells, "entry_cell": cells[0], "escape_cell": cells[0], "exit_cell": null if name == "dead_end" else cells[-1]})
	var surfaces: Array[Vector3i] = []
	for cell in cells:
		surfaces.append(Vector3i(cell.x, cell.y, 0))
	extra_routes.append({"role": name, "cells": surfaces, "width_px": width * 100})

func _rect(first: Vector2i, last: Vector2i, elevation := 0) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var cell := Vector2i(x, y)
			grammar.playable[cell] = true
			if elevation != 0:
				grammar.levels[cell] = [elevation]
			cells.append(cell)
	return cells

func _zone(cell: Vector2i, role := "recovery") -> void:
	grammar._add_zone(cell, role, 1)

func _surface(type: String, cells: Array[Vector2i], role: String, direction := Vector2.ZERO, elevation := 0) -> void:
	var identity := "%s_%d" % [type, placements.size()]
	for cell in cells:
		placements.append({"cell": cell, "definition": {"type": type, "size": Vector2(100, 100), "elevation": elevation, "direction": direction, "intensity": 0.22 if type == "ice" else 1.0, "cluster_id": identity, "cluster_size": cells.size(), "placement_role": role, "seed": SEEDS[index]}})

func _swing(cell: Vector2i, radius := 100.0, elevation := 0) -> void:
	var period := 4.2 if difficulty == &"easy" else 3.2 if difficulty == &"normal" else 2.6
	period *= float(ARC_PERIOD_SCALES[index % 3])
	var diameter := 60.0 if difficulty == &"easy" else 76.0 if difficulty == &"normal" else 88.0
	# C1's short deck has one compact mechanism below its covered crossing.
	var compact := elevation == 1 and index == 6
	if compact:
		radius = 70.0
		diameter = 60.0
	placements.append({"cell": cell, "definition": {"type": "pendulum", "size": Vector2.ONE * diameter, "offset": Vector2(0, -radius + (20.0 if compact else 0.0)), "travel_radius": radius, "swing_angle": 0.9, "period": period, "phase": 0.0, "elevation": elevation, "intensity": 1.0, "blocks_main_route": false, "placement_role": "timed_shortcut_guard"}})

func _block(cell: Vector2i, size: Vector2, role: String, elevation := 0) -> void:
	placements.append({"cell": cell, "definition": {"type": "blocker", "size": size, "elevation": elevation, "placement_role": role}})

func _interaction_for(definition: Dictionary) -> Dictionary:
	var data := {"shot_or_route": String(definition.placement_role).replace("_", " "), "recovery": notes.recovery}
	match String(definition.type):
		"pendulum":
			data.merge({"observe": "Anchor, moving mass, direction and reversal; watch a full repeatable cycle.", "execution_skill": "Release across the moving mass as it clears the chosen line; bank or use the other shoulder to trade distance for safety.", "failure": "Contact returns to the tee with one normal hazard penalty; the accepted shot stays charged."})
		"direction":
			data.merge({"observe": "Arrow direction, length of the force band, pocket mouth and clear side shoulder.", "execution_skill": "Choose entry angle and enough speed to carry the force band, or avoid it using the fork.", "failure": "A weak entry drifts into the bounded pocket and costs a recovery shot; the force itself adds no penalty."})
		"water":
			data.merge({"observe": "The visible water footprint at the ball's elevation, especially beyond a fast landing.", "execution_skill": "Keep the shot or bank clear of the guard and control the landing distance.", "failure": "Water returns to the tee with one normal hazard penalty; this is not an OOB refund."})
		"sand":
			data.merge({"observe": "The sand's location before a rail, pocket or approach.", "execution_skill": "Use it to brake a fast arrival, or avoid its footprint when carrying farther.", "failure": "Stopping short spends position and possibly another stroke; sand never resets the ball."})
		"blocker":
			data.merge({"observe": "The solid rebound face, its ends, and the landing angle beyond it.", "execution_skill": "Choose a bank angle or clear shoulder; restitution reduces the outgoing speed.", "failure": "A poor rebound leaves a harder approach or enters a nearby visible hazard."})
	return data

func _direction_correction() -> void:
	# Purposeful additions to the existing motifs. No production selection path
	# imports this catalog. Keep one primary idea and a clear exit from each trap.
	match index:
		0:
			_block(Vector2i(5, 1), Vector2(160, 36), "bank_face_below_swing")
			_surface("sand", [Vector2i(4, 2)], "controlled_bank_landing")
			_surface("water", [Vector2i(10, 0)], "outer_bank_overshoot")
			notes.decision = "Bank past the water onto the short rail, or time a direct crossing of the larger swinging stone. Use the sand to hold the inner landing."
			notes.variation = "Compact elbow: low bank face, inside sand stop and a broad outside recovery bay."
		1:
			_rect(Vector2i(10, 1), Vector2i(12, 3))
			_block(Vector2i(10, 1), Vector2(72, 72), "offset_bank_rail")
			_surface("water", [Vector2i(7, 2)], "punishes_short_elbow_entry")
			_swing(Vector2i(12, 4), 85.0)
			placements[-1].definition.phase = 0.5
			notes.decision = "Carry the first bank, recover in the elbow, then time the second stone before the east-facing cup. The lower rail bypass costs an extra angle."
			notes.variation = "Long inlet and offset exit, two opposed-phase mechanisms separated by a safe setup elbow."
		2:
			_route([Vector2i(3, 1), Vector2i(3, 3), Vector2i(7, 3)], 3, false, "protected_bank")
			_zone(Vector2i(4, 3))
			_block(Vector2i(7, -1), Vector2(160, 38), "bank_face_at_hook_entry")
			_surface("water", [Vector2i(4, 5)], "guards_return_approach")
			_surface("water", [Vector2i(10, 0)], "outer_bay_overshoot")
			notes.decision = "Rebound into the exposed swing chamber or take the inside dogleg. Arrive below the stone before reversing toward the cup."
			notes.variation = "Hook return with a new inside dogleg, two rebound faces and an outside catch."
		3:
			_swing(Vector2i(9, 0), 85.0)
			_block(Vector2i(7, -4), Vector2(180, 38), "sheltered_rebound_choice")
			_surface("water", [Vector2i(12, -2)], "sheltered_route_overshoot")
			notes.decision = "Carry the gust above the pocket and time its guarded exit, or bank around the sheltered upper loop."
		4:
			_swing(Vector2i(10, 1), 100.0)
			_block(Vector2i(8, -4), Vector2(180, 38), "sheltered_rebound_choice")
			_surface("water", [Vector2i(13, 0)], "guards_upper_reconnection")
			notes.decision = "Use the three-tile gust to bend into the offset exit, timing the stone beyond it. The upper route trades distance for a protected bank."
			notes.skill = "Carry the broad force band at a controlled angle, then cross the stone as it clears the offset exit."
		5:
			_swing(Vector2i(11, 0), 85.0)
			_block(Vector2i(10, 6), Vector2(180, 38), "lower_loop_bank")
			_surface("water", [Vector2i(14, 2)], "guards_lower_reconnection")
			notes.decision = "Choose the long southern bank loop or carry the upward gust past a timed exit. A slow entry feeds the hooked pocket."
		6:
			_swing(Vector2i(10, 0), 85.0)
			_block(Vector2i(9, 4), Vector2(72, 72), "underpass_exit_bank")
			_surface("water", [Vector2i(12, 5)], "outer_drop_overshoot")
		7:
			_swing(Vector2i(8, 0), 85.0)
			_surface("water", [Vector2i(10, 4)], "outer_loop_overshoot")
			_block(Vector2i(7, 7), Vector2(72, 38), "return_bank")
			notes.decision = "Take the recessed force-fed cut and its sand bay, or time the stone on the outer loop. The low route offers an earlier return angle."
		8:
			_swing(Vector2i(9, 0), 100.0)
			_surface("water", [Vector2i(12, 6)], "guards_lower_landing")
			_block(Vector2i(9, 10), Vector2(72, 72), "offset_return_bank")
			notes.variation = "Longer loop with an offset return, upper and outer timing threats, and a guarded lower landing after the clear tunnel."
	if difficulty == &"hard":
		var guard_cells := [Vector2i(4, -1), Vector2i(4, -1), Vector2i(2, 0), Vector2i(6, -5), Vector2i(5, -5), Vector2i(8, 5), Vector2i(3, 0), Vector2i(8, 6), Vector2i(6, 0)]
		if index == 0:
			_block(Vector2i(4, 0), Vector2(60, 60), "hard_bank_nose")
		else:
			_surface("water", [guard_cells[index]], "hard_exposed_shoulder")

func _bank(variant: int) -> void:
	grammar.motifs = ["bank_corner", "pendulum_gate", "recovery_pocket"]
	match variant:
		0:
			_route([Vector2i(0, 0), Vector2i(6, 0), Vector2i(6, 6)], 3, true, "bank_or_timing")
			_rect(Vector2i(3, -2), Vector2i(8, 3))
			_rect(Vector2i(8, 0), Vector2i(10, 4))
			_zone(Vector2i(6, 3))
			_zone(Vector2i(9, 3), "overshoot_recovery")
			_surface("water", [Vector2i(3, 0), Vector2i(3, 1)], "guards_direct_corner")
			_surface("sand", [Vector2i(9, 0)], "catches_long_rebound")
			_swing(Vector2i(6, 0))
			setup_cell = Vector2i(2, -1)
			notes = {"decision": "Bank along the upper rail around the water, or set up closer and time the swinging shortcut.", "skill": "Set up above the water before banking: the rail removes speed. Release the crossing shot as the swing moves away.", "consequence": "Water or pendulum contact resets with the normal penalty. The outer sand pocket catches a long landing.", "recovery": "The right-hand chamber and lower elbow leave another approach to the cup.", "variation": "Compact elbow, broad outer bank and side catch."}
		1:
			_route([Vector2i(0, 0), Vector2i(9, 0), Vector2i(9, 4), Vector2i(16, 4)], 3, true, "long_bank_then_exit")
			_rect(Vector2i(4, -2), Vector2i(11, 2))
			_zone(Vector2i(9, 3))
			_surface("water", [Vector2i(5, 0), Vector2i(5, 1)], "guards_long_sightline")
			_surface("sand", [Vector2i(14, 4)], "catches_fast_cup_approach")
			_swing(Vector2i(8, 0), 120.0)
			setup_cell = Vector2i(4, -1)
			notes = {"decision": "Carry a longer upper bank into the gate, or stop before it and take two controlled turns.", "skill": "Power must survive a longer approach; the east-facing cup rewards a different landing angle.", "consequence": "A short bank leaves a setup stroke; rushed timing costs a reset. Sand catches the fast final approach.", "recovery": "The elbow below the swing is clear and the outer rail remains usable.", "variation": "Long entry, widened north shoulder, extra exit bend and east-facing green."}
		2:
			_route([Vector2i(0, 0), Vector2i(7, 0), Vector2i(7, 6), Vector2i(2, 6)], 3, true, "hook_return")
			_rect(Vector2i(4, -2), Vector2i(9, 3))
			_rect(Vector2i(9, 0), Vector2i(11, 3))
			_zone(Vector2i(10, 2), "overshoot_recovery")
			_zone(Vector2i(7, 5))
			_surface("water", [Vector2i(4, 0)], "guards_corner_cut")
			_surface("sand", [Vector2i(5, 6)], "catches_return_lane")
			_swing(Vector2i(7, 2))
			setup_cell = Vector2i(7, 0)
			notes = {"decision": "Bank into the outer chamber, then cross the swing before doubling back toward the cup.", "skill": "Separate the bank's landing angle from the downward timing shot and the returning finish.", "consequence": "Overpowering enters the outer bay; hitting the swing resets. The return sand costs distance.", "recovery": "The bay opens back onto the elbow; clear ground below the swing lets you aim the return.", "variation": "Hook-shaped return, deep outside bay and reversed cup approach."}

func _split(variant: int) -> void:
	grammar.motifs = ["split_route", "direction_fork", "dead_end_bait", "recovery_pocket"]
	match variant:
		0:
			_route([Vector2i(0, 0), Vector2i(4, 0), Vector2i(4, -4), Vector2i(11, -4), Vector2i(11, 0), Vector2i(14, 0)], 3, true, "sheltered_route")
			_route([Vector2i(4, 0), Vector2i(11, 0)], 3, false, "shortcut")
			_route([Vector2i(7, 1), Vector2i(7, 4)], 3, false, "dead_end")
			_zone(Vector2i(7, 4), "dead_end_recovery")
			_surface("direction", [Vector2i(6, 0), Vector2i(7, 0)], "feeds_recoverable_pocket", Vector2.DOWN)
			_surface("water", [Vector2i(10, 1)], "guards_shortcut_landing")
			_surface("sand", [Vector2i(4, -3)], "safe_route_stopping_option")
			setup_cell = Vector2i(4, 0)
			notes = {"decision": "Use the sheltered upper loop or carry the short crosswind line above the pocket.", "skill": "Angle into the gust and use enough speed to cross it without drifting down.", "consequence": "A slow, low entry drifts into a walled pocket and needs a recovery stroke; the landing water still penalizes.", "recovery": "Shoot up the pocket's clear shoulder to leave the force band, or commit to the longer upper route.", "variation": "Early symmetric fork, straight shortcut, broad dead-end catch below."}
		1:
			_route([Vector2i(0, 0), Vector2i(3, 0), Vector2i(3, -4), Vector2i(12, -4), Vector2i(12, 2), Vector2i(15, 2)], 3, true, "sheltered_route")
			_route([Vector2i(3, 0), Vector2i(9, 0), Vector2i(9, 2), Vector2i(12, 2)], 3, false, "shortcut")
			_route([Vector2i(6, 1), Vector2i(6, 5)], 3, false, "dead_end")
			_zone(Vector2i(6, 5), "dead_end_recovery")
			_surface("direction", [Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)], "feeds_recoverable_pocket", Vector2.DOWN)
			_surface("sand", [Vector2i(10, 2)], "brakes_offset_exit")
			_surface("water", [Vector2i(9, -1)], "punishes_wrong_exit_angle")
			setup_cell = Vector2i(3, 0)
			notes = {"decision": "Take the longer high loop or carry the broad gust into the offset exit.", "skill": "A well-positioned full-power shot can use the gust to reach the cup; lower power needs a different angle.", "consequence": "A weak entry feeds the deeper pocket. A miss above the exit bend reaches water.", "recovery": "Angle out through the pocket's clear shoulder; firing straight against the gust can send you back in. Sand can set up the final shot.", "variation": "Wider force section, deep catch and dogleg shortcut with a displaced reconnection."}
		2:
			_route([Vector2i(0, 0), Vector2i(5, 0), Vector2i(5, 6), Vector2i(13, 6), Vector2i(13, 0), Vector2i(16, 0)], 3, true, "sheltered_route")
			_route([Vector2i(5, 0), Vector2i(13, 0)], 3, false, "shortcut")
			_route([Vector2i(9, -1), Vector2i(9, -3), Vector2i(7, -3), Vector2i(7, -5)], 3, false, "dead_end")
			_zone(Vector2i(7, -5), "dead_end_recovery")
			_surface("direction", [Vector2i(8, 0), Vector2i(9, 0)], "feeds_hooked_pocket", Vector2.UP)
			_surface("water", [Vector2i(12, 1)], "guards_fast_landing")
			_surface("sand", [Vector2i(6, 6), Vector2i(7, 6)], "sheltered_setup_catch")
			setup_cell = Vector2i(5, 0)
			notes = {"decision": "Set up before the late fork, then choose the long southern loop or the exposed upper line.", "skill": "The longer inlet changes approach speed. Counter the upward gust without clipping the landing guard.", "consequence": "A weak entry feeds a hooked pocket, leaving a two-angle escape instead of a straight retry.", "recovery": "The pocket's right shoulder leads back to the fork; the lower loop is continuous and has a sand setup catch.", "variation": "Later split, longer bypass, hooked dead end and a changed landing side."}

func _loop(variant: int) -> void:
	grammar.motifs = ["loop", "split_route", "recovery_pocket"]
	var far_x := 15 if variant == 2 else 12 if variant == 0 else 10
	var bottom := 10 if variant == 2 else 8 if variant == 0 else 7
	if variant == 2:
		_route([Vector2i(0, 0), Vector2i(far_x, 0), Vector2i(far_x, 6), Vector2i(8, 6), Vector2i(8, bottom), Vector2i(0, bottom)], 3, true, "outer_loop")
	else:
		_route([Vector2i(0, 0), Vector2i(far_x, 0), Vector2i(far_x, bottom), Vector2i(0, bottom)], 3, true, "outer_loop")
	var deck_x := 4 if variant == 1 else 5
	_route([Vector2i(deck_x, 0), Vector2i(deck_x, bottom)], 3, false, "shortcut")
	var elevation := -1 if variant == 1 else 1
	var deck := _rect(Vector2i(deck_x - 1, 2), Vector2i(deck_x + 1, bottom - 2), elevation)
	if variant == 1:
		deck.append_array(_rect(Vector2i(6, 3), Vector2i(7, 5), -1))
	for x in range(deck_x - 1, deck_x + 2):
		grammar.transitions.append({"type": "ramp", "from_cell": Vector2i(x, 1), "to_cell": Vector2i(x, 2), "from_elevation": 0, "to_elevation": elevation, "width": 100.0})
		grammar.transitions.append({"type": "ramp", "from_cell": Vector2i(x, bottom - 2), "to_cell": Vector2i(x, bottom - 1), "from_elevation": elevation, "to_elevation": 0, "width": 100.0})
	grammar.structures.append({"type": "lower_area" if elevation < 0 else "bridge", "cells": deck, "elevation": elevation})
	# Layered shortcuts are described honestly, separately from ground corridors.
	corridors.pop_back()
	extra_routes.pop_back()
	var layered: Array[Vector3i] = []
	for y in range(bottom + 1):
		layered.append(Vector3i(deck_x, y, elevation if y >= 2 and y <= bottom - 2 else 0))
	extra_routes.append({"role": "lower_cut" if elevation < 0 else "exposed_bridge", "cells": layered, "width_px": 300})
	_zone(Vector2i(far_x, bottom if variant != 2 else 4))
	if variant == 1:
		grammar.motifs.append("recessed_cut")
		_surface("direction", [Vector2i(4, 3)], "feeds_lower_run", Vector2.DOWN, -1)
		_surface("sand", [Vector2i(6, 4), Vector2i(7, 4)], "catches_lower_side_bay", Vector2.ZERO, -1)
		_surface("water", [Vector2i(6, 0)], "guards_outer_entry")
		notes = {"decision": "Follow the broad outside loop or take the short recessed cut with a side catch.", "skill": "Control entry to the downward force and stay out of the expanded lower sand bay.", "consequence": "A poor lower entry costs position and another setup shot. The outer water guard still resets.", "recovery": "Both ends of the lower terrace have full-width ramps, and the side bay reconnects to the cut.", "variation": "No covered crossing: recessed terrace, side expansion and a compact outside loop."}
	else:
		grammar.motifs.append("short_tunnel")
		var crossing_y := 5 if variant == 2 else 4
		_route([Vector2i(0, 0), Vector2i(0, crossing_y)], 3, false, "alternate")
		# One-cell-wide lower passage under a two-cell-wide bridge. The covered
		# distance is exactly 200 px; both approaches flare to three cells.
		_rect(Vector2i(0, crossing_y), Vector2i(far_x, crossing_y))
		_rect(Vector2i(0, crossing_y - 1), Vector2i(deck_x - 2, crossing_y + 1))
		_rect(Vector2i(deck_x + 2, crossing_y - 1), Vector2i(far_x, crossing_y + 1))
		var tunnel: Array[Vector2i] = [Vector2i(deck_x - 1, crossing_y), Vector2i(deck_x, crossing_y)]
		for cell in tunnel:
			grammar.levels[cell] = [0, 1]
		var notch := Vector2i(deck_x + 1, crossing_y)
		grammar.levels[notch] = [0]
		deck.erase(notch)
		grammar.structures.append({"type": "overpass", "cells": tunnel, "elevation": 1, "lower_elevation": 0, "tunnel_length": 2})
		var under: Array[Vector3i] = []
		for x in range(far_x + 1):
			under.append(Vector3i(x, crossing_y, 0))
		extra_routes.append({"role": "clear_underpass", "cells": under, "width_px": 100, "covered_length_px": 200})
		_swing(Vector2i(deck_x, bottom - 3), 56.0 if variant == 0 else 100.0, 1)
		_surface("water", [Vector2i(8, 1) if variant == 0 else Vector2i(11, 0)], "guards_exposed_outer_lane")
		_surface("sand", [Vector2i(far_x - 2, crossing_y)], "sets_up_lower_exit")
		notes = {"decision": "Take the short elevated swing route, use the clear lower crossing, or stay on the outside loop.", "skill": "Choose your layer before the crossing; time the visible swing on the exposed bridge.", "consequence": "The bridge swing uses the normal reset penalty. The lower route costs extra turns and its sand catch costs distance.", "recovery": "The underpass contains no hazard; both ends are visible. Ramps reconnect the bridge at ground level.", "variation": "Offset outer return and later crossing with an extra approach bend." if variant == 2 else "Compact return loop, mid-course crossing and a short exposed bridge."}
	setup_cell = Vector2i(deck_x, 0)
