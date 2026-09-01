extends GutTest

const TutorialDatabaseScript := preload("res://scripts/tutorial_database.gd")
const LevelValidatorScript := preload("res://scripts/level_validator.gd")


func test_tutorial_teaches_current_game_in_release_order() -> void:
	var levels := TutorialDatabaseScript.get_levels()
	assert_eq(levels.size(), 6)
	assert_eq(_lesson_names(levels), [
		"aim_power_trajectory",
		"sand",
		"water_reset",
		"blocker_and_moving_hazard",
		"shop_tradeoff",
		"card_tradeoff_continue",
	])

	for level_index in range(levels.size()):
		assert_true(LevelValidatorScript.validate_level(levels[level_index], level_index))
		for hazard in levels[level_index].hazards:
			assert_false(String(hazard.type) in ["rough", "out"])

	var first_events := _step_events(levels[0])
	assert_eq(first_events.slice(0, 3), [&"aim_started", &"power_adjusted", &"shot_taken"])
	assert_true(bool(levels[4].open_shop))
	assert_eq(int(levels[4].minimum_shop_purchases), 1)
	assert_eq(Array(levels[5].required_events), [&"card_benefit_active", &"card_curse_active", &"shot_taken"])
	assert_eq(_step_events(levels[5]).slice(0, 3), [&"aim_started", &"power_adjusted", &"shot_taken"])


func test_tutorial_pool_is_deterministic_simple_and_trajectory_independent() -> void:
	var first: Array[CardDefinition] = TutorialDatabaseScript.get_tutorial_cards()
	var second: Array[CardDefinition] = TutorialDatabaseScript.get_tutorial_cards()
	assert_eq(first.size(), 4)
	assert_eq(_card_ids(first), _card_ids(second))

	for card in first:
		assert_true(card.is_valid())
		assert_eq(card.price, 1)
		assert_eq(card.bonus_effects.trajectory_dot_delta, 0)
		assert_eq(card.curse_effects.trajectory_dot_delta, 0)


func _lesson_names(levels: Array[Dictionary]) -> Array[String]:
	var names: Array[String] = []
	for level in levels:
		names.append(String(level.lesson))
	return names


func _step_events(level: Dictionary) -> Array[StringName]:
	var events: Array[StringName] = []
	for step in level.steps:
		events.append(StringName(step.event))
	return events


func _card_ids(cards: Array[CardDefinition]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card in cards:
		ids.append(card.id)
	return ids
