extends GutTest

const RunStatsScript := preload("res://scripts/run_stats.gd")


func test_reset_restores_current_baseline_values() -> void:
	var stats: RunStats = RunStatsScript.new()
	stats.record_stroke()
	stats.final_score_relative_to_par = 3
	stats.record_card_bought("Overdrive Driver")
	stats.record_hazard_entered("sand")
	stats.record_hazard_entered("water")
	stats.record_hazard_entered("direction")
	stats.record_hazard_entered("future_hazard")
	stats.record_water_reset()
	stats.record_manual_reset()
	stats.update_time(12.5)

	stats.reset()

	assert_eq(stats.total_strokes, 0)
	assert_eq(stats.final_score_relative_to_par, 0)
	assert_true(stats.cards_bought.is_empty())
	assert_eq(stats.hazards_entered, {
		"sand": 0,
		"water": 0,
		"direction": 0
	})
	assert_eq(stats.water_resets, 0)
	assert_eq(stats.manual_resets, 0)
	assert_eq(stats.total_run_time, 0.0)
