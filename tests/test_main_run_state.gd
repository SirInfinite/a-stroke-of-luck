extends GutTest

const MAIN_SCENE := preload("res://scenes/main.tscn")


func test_starting_normal_run_restores_current_baseline() -> void:
	var main = _spawn_normal_main()
	main.level_index = 3
	main.strokes = 4
	main.total_strokes = 11
	main.tokens = 9
	main.level_elapsed = 42.5
	main.reward_bonus = 2
	main.owned_cards.append("Lucky Putter")
	main.run_stats.record_stroke()
	main.run_stats.update_time(42.5)

	main._start_normal_run()
	main.set_process(false)

	assert_eq(main.level_index, 0)
	assert_eq(main.strokes, 0)
	assert_eq(main.total_strokes, 0)
	assert_eq(main.tokens, 2)
	assert_eq(main.level_elapsed, 0.0)
	assert_eq(main.reward_bonus, 0)
	assert_true(main.owned_cards.is_empty())
	assert_eq(main.run_stats.total_strokes, 0)
	assert_eq(main.run_stats.total_run_time, 0.0)


func test_finished_shot_increments_current_stroke_totals_once() -> void:
	var main = _spawn_normal_main()

	main.ball.shot_finished.emit()

	assert_eq(main.strokes, 1)
	assert_eq(main.total_strokes, 1)
	assert_eq(main.run_stats.total_strokes, 1)


func test_hole_completion_awards_and_advances_once() -> void:
	var main = _spawn_normal_main()
	main.ball.sink_animation_duration = 0.0

	main.level_builder.hole_body_entered.emit(main.ball)
	main.level_builder.hole_body_entered.emit(main.ball)

	assert_true(main.loading_next_level)
	assert_eq(main.tokens, 5)
	assert_eq(main.level_index, 0)

	var sink_finished: bool = await wait_for_signal(main.ball.sink_animation_finished, 1.0)
	assert_true(sink_finished)
	await wait_process_frames(1)
	main.shop_manager.continue_button.pressed.emit()
	await wait_process_frames(1)

	assert_eq(main.level_index, 1)
	assert_eq(main.tokens, 5)


func test_manual_current_hole_reset_preserves_cumulative_run_state() -> void:
	var main = _spawn_normal_main()
	main._load_level(2)
	main.tokens = 7
	main.ball.shot_finished.emit()
	main.level_elapsed = 8.5

	main._reset_current_level()

	assert_eq(main.strokes, 0)
	assert_eq(main.level_elapsed, 0.0)
	assert_eq(main.total_strokes, 1)
	assert_eq(main.run_stats.total_strokes, 1)
	assert_eq(main.run_stats.manual_resets, 1)
	assert_eq(main.level_index, 2)
	assert_eq(main.tokens, 7)


func test_run_timing_accumulates_only_outside_level_transition() -> void:
	var main = _spawn_normal_main()

	main._process(1.25)

	assert_eq(main.level_elapsed, 1.25)
	assert_eq(main.run_stats.total_run_time, 1.25)

	main.loading_next_level = true
	main._process(2.0)

	assert_eq(main.level_elapsed, 1.25)
	assert_eq(main.run_stats.total_run_time, 1.25)


func _spawn_normal_main() -> Variant:
	var main = MAIN_SCENE.instantiate()
	add_child_autofree(main)
	main._start_normal_run()
	main.set_process(false)
	return main
