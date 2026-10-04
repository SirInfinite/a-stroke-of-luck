extends GutTest
## Cross-system contracts for the approved production presentation.

const Main := preload("res://scenes/main.tscn")
const Style := preload("res://scripts/ui/ui_style.gd")
const ThemeResource := preload("res://assets/release_theme.tres")

func test_approved_typography_is_shared_and_covers_game_copy() -> void:
	assert_eq(Style.DISPLAY_FONT, Style.UI_FONT, "Display and copy use the approved family; hierarchy is size/ink.")
	assert_eq(Style.UI_FONT, Style.UI_BOLD_FONT)
	assert_true(Style.UI_FONT.resource_path.contains("Jersey10"))
	for character in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,:;!?%+-/=()[]#'\"&•×−–—…°":
		assert_true(Style.UI_FONT.has_char(character.unicode_at(0)), "Approved font covers '%s'." % character)
	for control_type in [&"Label", &"Button", &"LineEdit", &"TabContainer", &"OptionButton", &"PopupMenu", &"CheckButton"]:
		assert_eq(ThemeResource.get_font("font", control_type), Style.UI_FONT, "%s inherits approved family" % control_type)

func test_one_stationary_tee_survives_reset_next_hole_and_tutorial_restart() -> void:
	var main = Main.instantiate()
	add_child_autofree(main)
	main._start_normal_run(8675309)
	main._load_level(0)
	await wait_physics_frames(3)
	_assert_one_aligned_tee(main, true)
	var tee_position: Vector2 = main.level_builder.tee_marker.global_position
	main.ball.shoot(Vector2.RIGHT * 450)
	await wait_physics_frames(3)
	assert_eq(main.run_state.strokes, 1, "Visual tee consumes no extra stroke.")
	_assert_one_aligned_tee(main, false)
	assert_eq(main.level_builder.tee_marker.global_position, tee_position, "Tee never follows the ball.")
	main._reset_current_level()
	await wait_physics_frames(3)
	_assert_one_aligned_tee(main, true)
	assert_eq(main.run_state.strokes, 1, "Visual reset preserves the accepted stroke.")
	main._load_level(1)
	await wait_physics_frames(3)
	_assert_one_aligned_tee(main, true)
	main._start_tutorial()
	await wait_physics_frames(3)
	_assert_one_aligned_tee(main, true)
	main._start_tutorial()
	await wait_physics_frames(3)
	_assert_one_aligned_tee(main, true)

func test_vs_turn_reset_uses_the_existing_single_tee_owner() -> void:
	var main = Main.instantiate()
	add_child_autofree(main)
	main._start_normal_run(8675309, &"woods")
	main._load_level(0)
	await wait_physics_frames(3)
	_assert_one_aligned_tee(main, true)
	main.ball.shoot(Vector2.RIGHT * 300)
	await wait_physics_frames(3)
	_assert_one_aligned_tee(main, false)
	main.vs_controller._begin_opponent_turn()
	await wait_physics_frames(3)
	_assert_one_aligned_tee(main, true)
	assert_true(main.vs_controller.is_ai_turn())
	main.vs_controller.cancel()

func _assert_one_aligned_tee(main: Node, expected_visible: bool) -> void:
	assert_eq(main.level_root.find_children("TeeStartMarker", "", true, false).size(), 1, "Exactly one tee presentation owner per hole.")
	assert_eq(main.level_builder.tee_marker.visible, expected_visible)
	assert_eq(main.ball.ball_art.find_children("*Tee*", "", true, false).size(), 0, "The ball never draws its own tee.")
	if expected_visible:
		assert_lt(main.level_builder.tee_marker.global_position.distance_to(main.ball.global_position), 0.1, "Tee and physical ball share the start position.")
