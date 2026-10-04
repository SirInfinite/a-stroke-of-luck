extends GutTest

const Generator := preload("res://scripts/hole_generator.gd")
const Motifs := preload("res://scripts/course_motifs.gd")
const Grammar := preload("res://scripts/course_grammar.gd")
const Quality := preload("res://scripts/course_quality.gd")
const Biomes := preload("res://scripts/biome_database.gd")
const Difficulty := preload("res://scripts/difficulty_database.gd")
const Validator := preload("res://scripts/level_validator.gd")
const Builder := preload("res://scripts/level_builder.gd")

func _hole(index := 4, seed_value := 7919, difficulty := &"normal", effects: Dictionary = {}) -> Dictionary:
	var options := Difficulty.get_profile(difficulty).generation_options()
	options.merge(effects, true)
	return Generator.generate_hole(Biomes.get_profiles()[index / 3], seed_value, index / 3, index % 3, 8, options)

func test_motif_library_is_bounded_and_spatially_transformable() -> void:
	assert_gte(Motifs.IDS.size(), 15)
	assert_lte(Motifs.IDS.size(), 30)
	var point := Vector2i(3, 1)
	assert_eq(Motifs.transform(point, 4, false), point)
	assert_ne(Motifs.transform(point, 1, false), point)
	assert_ne(Motifs.transform(point, 0, true), point)
	assert_ne(Motifs.anchors("dogleg", 0, 1), Motifs.anchors("dogleg", 2, 1))

func test_route_first_contract_provides_shot_sections_and_clear_recovery() -> void:
	for index in range(18):
		var level := _hole(index)
		assert_eq(int(level.grammar_version), Grammar.VERSION)
		assert_false(level.shot_corridors.is_empty())
		assert_gte(level.shot_zones.size(), 2)
		assert_gte(level.main_route_cells.size(), 2)
		assert_eq(level.design_route_cells[0], level.start_cell)
		assert_eq(level.design_route_cells[-1], level.hole_cell)
		assert_true(Validator.generation_errors(level).is_empty())
		assert_true(Validator.validate_level(level, index))

func test_replay_includes_difficulty_and_curses_without_global_rng() -> void:
	for difficulty in [&"easy", &"normal", &"hard"]:
		for effect in ["direction", "water", "blocker"]:
			var options := {"added_hazard_count": 4, "preferred_hazard_type": effect, "modifier_seed": 913}
			var first := _hole(14, 5341, difficulty, options)
			for _call in range(4):
				randf()
			var replay := _hole(14, 5341, difficulty, options)
			assert_eq(first, replay)
			assert_eq(first.card_hazard_count, 4)
			assert_true(Validator.validate_level(first, 14))

func test_zero_effects_do_not_change_layout_randomness() -> void:
	var base := _hole()
	var zero := _hole(4, 7919, &"normal", {"added_hazard_count": 0, "preferred_hazard_type": "none", "modifier_seed": 999})
	assert_eq(base.map, zero.map)
	assert_eq(base.hazards, zero.hazards)
	assert_eq(base.candidate_scores, zero.candidate_scores)

func test_candidate_diagnostics_report_real_rejections_not_unselected_valid_holes() -> void:
	var selected := _hole(17)
	var valid_count := 0
	var below_floor := 0
	var best := -1.0
	var first_best := -1
	for candidate: Dictionary in selected.candidate_scores:
		if not candidate.valid:
			continue
		valid_count += 1
		below_floor += 1 if candidate.score < Generator.MINIMUM_QUALITY_SCORE else 0
		if float(candidate.score) > best:
			best = float(candidate.score)
			first_best = int(candidate.candidate)
	assert_eq(valid_count, selected.candidate_valid_count)
	assert_eq(below_floor, selected.candidate_quality_rejection_count)
	assert_eq(selected.quality_score, best)
	assert_eq(int(selected.generation_attempt), first_best + 1)

func test_direct_line_and_bank_geometry_are_measured_independently_of_hazard_labels() -> void:
	var level := _hole(6)
	var metrics := Generator.quality_metrics(level)
	assert_true(metrics.direct_line_blocked_by_geometry)
	assert_gte(metrics.bank_opportunities, 1)
	assert_false(metrics.trivial_direct_line)
	for hazard in level.hazards:
		hazard.placement_role = "irrelevant_label"
	assert_eq(Generator.quality_metrics(level).route_relevant_ratio, metrics.route_relevant_ratio)

func test_quality_rejects_empty_or_off_route_pressure() -> void:
	var coherent := _hole(7)
	var empty := coherent.duplicate(true)
	empty.hazards = []
	empty.obstacles = []
	empty.moving_hazards = []
	assert_gt(Generator.score_candidate(coherent).score, Generator.score_candidate(empty).score)
	var displaced := coherent.duplicate(true)
	for hazard in displaced.hazards:
		hazard.pos += Vector2(900, 900)
	assert_lt(Generator.quality_metrics(displaced).route_relevant_ratio, Generator.quality_metrics(coherent).route_relevant_ratio)

func test_validator_does_not_trust_reservations_or_route_metadata() -> void:
	var level := _hole()
	level.placement_reservations = []
	level.recovery_reservations = []
	level.main_route_cells = []
	assert_false(Validator.validate_level(level, 4, false))
	level = _hole()
	level.obstacles.append(level.hazards[0].duplicate(true))
	level.obstacles[-1].type = "blocker"
	assert_false(Validator.validate_level(level, 4, false))

func test_validator_detects_stranded_free_surface_even_when_cup_is_reachable() -> void:
	var level := _hole(6)
	var empty := Vector2i(-1, -1)
	for y in range(level.map.size()):
		for x in range(String(level.map[y]).length()):
			var cell := Vector2i(x, y)
			if level.map[y][x] == " " and [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].all(func(direction: Vector2i) -> bool: return not Validator._is_playable_cell(level, cell + direction)):
				empty = cell
	assert_ne(empty, Vector2i(-1, -1))
	if empty.x < 0:
		return
	level.map[empty.y][empty.x] = "#"
	level.elevation_cells.append({"cell": empty, "levels": [0]})
	assert_false(Validator.validate_level(level, 6, false))
	assert_has(Validator.generation_errors(level), "unrecoverable pocket or disconnected elevation surface")

func test_validator_checks_tee_cup_and_recovery_footprints() -> void:
	for endpoint in ["start_cell", "hole_cell"]:
		var level := _hole()
		var hazard: Dictionary = level.hazards[0].duplicate(true)
		hazard.pos = Generator._cell_to_world(Generator._string_rows(level.map), Vector2i(level[endpoint]) + Vector2i(1, 1))
		level.hazards.append(hazard)
		assert_false(Validator.validate_level(level, 4, false))

func test_validator_checks_actual_cluster_shape_and_size() -> void:
	var level := _hole()
	level.hazards[0].cluster_size = 99
	assert_false(Validator.validate_level(level, 4, false))
	level = _hole()
	level.hazards[0].size = Vector2(300, 100)
	assert_false(Validator.validate_level(level, 4, false))

func test_motion_reservation_covers_pendulum_below_anchor_and_rotating_rod() -> void:
	var level := {"map": [".....", ".....", ".....", ".....", "....."]}
	var pendulum := {"type": "pendulum", "pos": Vector2.ZERO, "size": Vector2(38, 38), "travel_radius": 90.0, "swing_angle": 0.9}
	var footprint := Validator._definition_surfaces(level, pendulum)
	assert_has(footprint, Vector3i(2, 3, 0))
	var rod := {"type": "rotating_fire_rod", "pos": Vector2.ZERO, "size": Vector2(150, 20)}
	assert_has(Validator._definition_surfaces(level, rod), Vector3i(2, 1, 0))

func test_bounce_pad_runway_is_independently_validated() -> void:
	var saw_pad := false
	for seed_value in range(1, 9):
		var level := _hole(5, seed_value * 7919)
		for pad: Dictionary in level.hazards:
			if pad.type != "bounce_pad":
				continue
			saw_pad = true
			assert_true(Validator.generation_errors(level).is_empty())
			var broken := level.duplicate(true)
			var cell := Generator._world_to_cell(level, pad.launch_target)
			broken.obstacles.append({"type": "blocker", "pos": Generator._cell_to_world(Generator._string_rows(level.map), cell), "size": Vector2(60, 60)})
			assert_has(Validator.generation_errors(broken), "bounce pad has no safe initial launch runway")
	assert_true(saw_pad)

func test_difficulty_changes_width_and_pressure_not_physics() -> void:
	var easy_moving := 0
	var hard_moving := 0
	for index in range(18):
		var easy := _hole(index, 7919, &"easy")
		var hard := _hole(index, 7919, &"hard")
		assert_gt(easy.lane_width_cells, hard.lane_width_cells)
		assert_gte(hard.lane_width_cells, 3)
		assert_gte(hard.challenge_budget, easy.challenge_budget)
		easy_moving += easy.moving_hazards.size()
		hard_moving += hard.moving_hazards.size()
	assert_gt(hard_moving, easy_moving)

func test_all_fallback_indices_and_biomes_remain_valid() -> void:
	for index in range(18):
		for seed_value in [1, 31676, 8675309]:
			var fallback := Generator.generate_hole(Biomes.get_profiles()[index / 3], seed_value, index / 3, index % 3, 0)
			assert_true(Validator.validate_level(fallback, index), "fallback hole %d seed %d" % [index + 1, seed_value])
			assert_eq(fallback.fallback_reason, "candidate_budget_zero")

func test_forced_fallback_keeps_requested_curse_types_and_replay() -> void:
	for index in range(18):
		for effect in ["direction", "water", "blocker"]:
			var options := Difficulty.get_profile(&"hard").generation_options()
			options.merge({"added_hazard_count": 4, "preferred_hazard_type": effect, "modifier_seed": 104729})
			var fallback := Generator.generate_hole(Biomes.get_profiles()[index / 3], 7919, index / 3, index % 3, 0, options)
			assert_true(Validator.validate_level(fallback, index), "%s fallback hole %d" % [effect, index + 1])
			assert_eq(fallback.card_hazard_count, 4)
			assert_eq(fallback, Generator.generate_hole(Biomes.get_profiles()[index / 3], 7919, index / 3, index % 3, 0, options))
			var additions := 0
			for collection in ["hazards", "obstacles"]:
				for definition: Dictionary in fallback[collection]:
					if bool(definition.get("curse_added", false)):
						additions += 1
						assert_eq(String(definition.type), effect)
			assert_eq(additions, 4)

func test_validator_rejects_nonfinite_or_unbounded_footprints_without_iterating_them() -> void:
	for position in [Vector2(INF, 0), Vector2(NAN, 0), Vector2(1e20, 0)]:
		var level := _hole()
		level.hazards[0].pos = position
		assert_false(Validator.validate_level(level, 4, false))
	for radius in [INF, NAN, 1e20, Vector2.ONE]:
		var level := _hole(8)
		assert_false(level.moving_hazards.is_empty())
		level.moving_hazards[0].travel_radius = radius
		assert_false(Validator.validate_level(level, 8, false))

func test_validator_checks_generation_schema_without_trusting_width_labels() -> void:
	for field in ["shot_corridors", "primary_corridor_cells", "design_route_cells"]:
		var missing := _hole()
		missing.erase(field)
		assert_false(Validator.validate_level(missing, 4, false), field)
	var narrow := _hole()
	narrow.shot_corridors[0].width = 5
	assert_false(Validator.validate_level(narrow, 4, false))
	var malformed := _hole()
	malformed.shot_zones[0].cells.fill(malformed.start_cell)
	assert_false(Validator.validate_level(malformed, 4, false))

func test_terrain_curses_grow_connected_guards_and_must_fulfill_their_count() -> void:
	var saw_growth := false
	for index in [1, 4, 7, 10, 13, 16]:
		var level := _hole(index, 15838, &"hard", {"added_hazard_count": 4, "preferred_hazard_type": "water", "modifier_seed": 209458})
		assert_false(level.used_fallback)
		assert_eq(level.card_hazard_count, 4)
		assert_true(Validator.validate_level(level, index))
		for hazard in level.hazards:
			if bool(hazard.get("curse_added", false)) and hazard.cluster_size > 1:
				saw_growth = true
		level.generation_options.added_hazard_count = 3
		assert_false(Validator.validate_level(level, index, false))
	assert_true(saw_growth)

func test_three_hole_arc_combines_pressure_and_biome_identity() -> void:
	for biome_index in range(6):
		var previous_budget := 0
		for arc_index in range(3):
			var level := _hole(biome_index * 3 + arc_index)
			assert_eq(level.biome_arc, ["introduce", "develop", "climax"][arc_index])
			assert_gt(level.challenge_budget, previous_budget)
			previous_budget = level.challenge_budget
			var terrain := String(Motifs.design_for(level.biome_id).terrain)
			assert_true(level.hazards.any(func(hazard: Dictionary) -> bool: return hazard.type == terrain))

func test_elevation_is_optional_wide_and_actual_short_tunnel_surfaces_are_validated() -> void:
	var tunnel := _find_motif("short_tunnel", 17, &"hard")
	assert_has(tunnel.selected_motifs, "short_tunnel")
	assert_true(Validator.validate_level(tunnel, 17))
	var defaulted := tunnel.duplicate(true)
	defaulted.tee.erase("elevation")
	for structure: Dictionary in defaulted.elevation_structures:
		structure.erase("tunnel_length")
		structure.erase("lower_elevation")
	assert_true(Validator.validate_level(defaulted, 17), "Optional builder defaults must not cause missing-key runtime errors.")
	var found := false
	for structure: Dictionary in tunnel.elevation_structures:
		if structure.type != "overpass":
			continue
		found = true
		assert_lte(structure.cells.size(), 2)
		for cell in structure.cells:
			assert_has(Validator.cell_elevations(tunnel, cell), structure.elevation)
			assert_has(Validator.cell_elevations(tunnel, cell), structure.lower_elevation)
		structure.tunnel_length = 3
	assert_true(found)
	assert_false(Validator.validate_level(tunnel, 17, false))
	var recessed := _find_motif("recessed_cut", 7, &"hard")
	assert_has(recessed.selected_motifs, "recessed_cut")
	assert_true(Validator.validate_level(recessed, 7))
	assert_false(recessed.elevation_transitions.is_empty())
	recessed.elevation_transitions.clear()
	assert_false(Validator.validate_level(recessed, 7, false))

func test_dead_end_keeps_an_escape_and_useful_turnaround() -> void:
	var level := _find_motif("dead_end_bait", 1, &"normal")
	assert_has(level.selected_motifs, "dead_end_bait")
	assert_true(Validator.validate_level(level, 1))
	var branch: Dictionary = level.branches[0]
	branch.escape_cell = Vector2i(-1, -1)
	assert_false(Validator.validate_level(level, 1, false))

func test_generated_ramps_cover_deck_width_and_point_along_the_transition() -> void:
	var holder := Node2D.new()
	add_child_autofree(holder)
	var builder := Builder.new()
	holder.add_child(builder)
	var level := _find_motif("recessed_cut", 7, &"hard")
	var root := builder.build_level(level, holder)
	for index in range(level.elevation_transitions.size()):
		var ramp := root.get_node("ElevationRamp%d" % (index + 1)) as ElevationRamp
		assert_eq(ramp.ramp_width, 100.0)
		assert_false(ramp.has_node("RampVisual/RampAscentMark"), "Lower elevations use geometry, not entrance arrows")
	level.elevation_transitions[0].width = 300.0
	assert_false(Validator.validate_level(level, 7, false))

func _find_motif(motif: String, index: int, difficulty: StringName) -> Dictionary:
	for sample in range(1, 97):
		var level := _hole(index, sample * 7919, difficulty)
		if level.get("selected_motifs", []).has(motif):
			return level
	fail_test("No %s in bounded motif corpus" % motif)
	return {}
