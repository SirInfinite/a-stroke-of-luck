extends GutTest

const LevelBuilderScript := preload("res://scripts/level_builder.gd")
const LevelValidatorScript := preload("res://scripts/level_validator.gd")


func test_validator_rejects_every_missing_builder_field() -> void:
	var valid_level := _minimal_level()
	for field_name in LevelValidatorScript.required_builder_fields():
		var missing := valid_level.duplicate(true)
		missing.erase(field_name)
		assert_false(
			LevelValidatorScript.validate_level(missing, 0),
			"Missing builder field %s must be rejected." % field_name
		)


func test_validator_rejects_invalid_fields_builder_would_dereference() -> void:
	var cases: Array[Dictionary] = []

	var missing_hazard_position := _minimal_level()
	missing_hazard_position.hazards = [{"type": "sand", "size": Vector2(100.0, 100.0)}]
	cases.append(missing_hazard_position)

	var missing_direction := _minimal_level()
	missing_direction.hazards = [{"type": "direction", "pos": Vector2.ZERO, "size": Vector2(100.0, 100.0)}]
	cases.append(missing_direction)

	var invalid_moving_period := _minimal_level()
	invalid_moving_period.moving_hazards = [{
		"type": "pendulum",
		"pos": Vector2.ZERO,
		"size": Vector2(40.0, 40.0),
		"period": 0.0,
		"phase": 0.0,
		"blocks_main_route": false,
	}]
	cases.append(invalid_moving_period)

	var invalid_palette := _minimal_level()
	invalid_palette.terrain_palette = {"fairway_a": "green"}
	cases.append(invalid_palette)

	var invalid_decorations := _minimal_level()
	invalid_decorations.decoration_identifiers = [42]
	cases.append(invalid_decorations)

	var missing_elevation_surface := _minimal_level()
	missing_elevation_surface.elevation_cells = [
		{"cell": Vector2i(0, 0), "levels": [0]},
	]
	cases.append(missing_elevation_surface)

	for case_index in range(cases.size()):
		assert_false(
			LevelValidatorScript.validate_level(cases[case_index], case_index),
			"Malformed builder case %d must fail validation." % (case_index + 1)
		)


func test_validator_accepts_flat_legacy_contract_and_builder_consumes_it() -> void:
	var level := _minimal_level()
	level.visual_rough_cells = [Vector2i(0, 0)]
	assert_true(LevelValidatorScript.validate_level(level, 0))

	var host := Node2D.new()
	add_child_autofree(host)
	var builder = LevelBuilderScript.new()
	host.add_child(builder)
	var built = builder.build_level(level, host)
	assert_not_null(built)
	assert_eq(builder.elevation_lookup.size(), 2)
	assert_eq(built.find_children("Hazard_rough", "Area2D", true, false).size(), 0)
	assert_eq(built.find_children("Elevation_0_0_0", "Node2D", true, false).size(), 1)


func test_rough_and_red_out_are_not_valid_mechanical_hazards() -> void:
	for removed_type in ["rough", "out"]:
		var level := _minimal_level()
		level.hazards = [{
			"type": removed_type,
			"pos": Vector2(-50.0, 0.0),
			"size": Vector2(100.0, 100.0),
		}]
		assert_false(LevelValidatorScript.validate_level(level, 0))


func test_validator_requires_explicit_valid_elevation_transitions() -> void:
	var level := _minimal_level()
	level.elevation_cells = [
		{"cell": Vector2i(0, 0), "levels": [0]},
		{"cell": Vector2i(1, 0), "levels": [1]},
	]
	assert_false(LevelValidatorScript.validate_level(level, 0))

	level.elevation_transitions = [{
		"type": "ramp",
		"from_cell": Vector2i(0, 0),
		"to_cell": Vector2i(1, 0),
		"from_elevation": 0,
		"to_elevation": 1,
	}]
	level.start_elevation = 0
	level.hole_elevation = 1
	assert_true(LevelValidatorScript.validate_level(level, 0))


func _minimal_level() -> Dictionary:
	return {
		"map": [".."],
		"start_cell": Vector2i(0, 0),
		"hole_cell": Vector2i(1, 0),
		"par": 2,
		"hazards": [],
		"obstacles": [],
	}
