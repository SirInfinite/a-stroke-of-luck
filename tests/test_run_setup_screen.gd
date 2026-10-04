extends GutTest

const DifficultyDatabaseScript := preload("res://scripts/difficulty_database.gd")
const GameSettingsScript := preload("res://scripts/game_settings.gd")
const RunSetupScreenScript := preload("res://scripts/ui/run_setup_screen.gd")
const SeedCodecScript := preload("res://scripts/seed_codec.gd")


func test_run_setup_exposes_all_profiles_and_restores_last_choice() -> void:
	var screen = _spawn_screen(&"hard")
	screen.open()

	assert_true(screen.visible)
	assert_eq(screen.selected_difficulty_id, &"hard")
	assert_eq(screen.difficulty_buttons.size(), 3)
	assert_true(bool(screen.difficulty_buttons[&"hard"].get_meta(&"selected")))
	assert_false(bool(screen.difficulty_buttons[&"normal"].get_meta(&"selected")))
	assert_eq(screen.selected_profile().shop_offer_count, 6)
	assert_eq(screen.selected_profile().max_purchases, 5)
	assert_true(screen.difficulty_buttons[&"easy"].tooltip_text.contains("2 PICKS"))
	assert_true(screen.difficulty_buttons[&"normal"].tooltip_text.contains("5 OFFERS"))
	assert_true(screen.difficulty_buttons[&"hard"].tooltip_text.contains("BRUTAL CURSES"))
	for button in screen.difficulty_buttons.values():
		var summaries: Array[Node] = button.find_children("*", "Label", true, false)
		assert_eq(summaries.size(), 3, "Each difficulty has visible title, rules summary and selection label.")
		assert_false((summaries[1] as Label).text.is_empty())


func test_blank_seed_starts_a_random_run_without_changing_seed_parsing() -> void:
	var screen = _spawn_screen(&"normal")
	watch_signals(screen)
	screen.open()
	screen.settings = null
	screen.seed_input.text = ""
	screen.select_difficulty(&"easy")
	screen._on_start_pressed()

	assert_signal_emitted_with_parameters(screen, "start_requested", [0, &"easy"])
	assert_false(screen.visible)


func test_entered_seed_and_difficulty_are_forwarded_exactly() -> void:
	var screen = _spawn_screen(&"normal")
	watch_signals(screen)
	screen.open()
	screen.settings = null
	screen.seed_input.text = " 486271 "
	screen.select_difficulty(&"hard")
	screen._on_start_pressed()

	assert_signal_emitted_with_parameters(screen, "start_requested", [486271, &"hard"])


func test_invalid_seed_blocks_start_and_randomize_produces_a_valid_seed() -> void:
	var screen = _spawn_screen(&"normal")
	watch_signals(screen)
	screen.open()
	screen.seed_input.text = "not luck"
	screen._on_start_pressed()
	assert_signal_not_emitted(screen, "start_requested")
	assert_true(screen.seed_status_label.text.contains("NUMBERS"))

	screen._on_randomize_pressed()
	var parsed := SeedCodecScript.parse_seed(screen.seed_input.text)
	assert_true(parsed.valid)
	assert_gt(int(parsed.value), 0)


func test_start_persists_selected_difficulty_when_settings_are_available() -> void:
	var screen = _spawn_screen(&"easy")
	var save_path := "user://test_run_setup_settings.cfg"
	screen.settings_save_path = save_path
	screen.open()
	screen.select_difficulty(&"hard")
	screen.seed_input.text = "117"
	screen._on_start_pressed()

	assert_eq(screen.settings.last_difficulty, &"hard")
	var loaded = GameSettingsScript.new()
	assert_eq(loaded.load_from(save_path), OK)
	assert_eq(loaded.last_difficulty, &"hard")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func _spawn_screen(last_difficulty: StringName):
	var root := Node.new()
	add_child_autofree(root)
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	var settings = GameSettingsScript.new()
	settings.last_difficulty = DifficultyDatabaseScript.get_profile(last_difficulty).id
	var screen = RunSetupScreenScript.new()
	screen.setup(canvas, settings)
	return screen
