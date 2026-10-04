extends Node2D
## Render-only review fixture: exercises the real Main screens without saving settings.

const MainScene := preload("res://scenes/main.tscn")
const Cards := preload("res://scripts/card_database.gd")
const Difficulties := preload("res://scripts/difficulty_database.gd")
const Rating := preload("res://scripts/hole_rating.gd")
const SAFE_SEED := 8675309
const EVIDENCE_ROOT := "user://visual_overhaul_20260906/after"

var main
var review_complete := false
var layout_failures := 0
var capture_count := 0
var layout_checks := 0
var output_directory := ""
var findings: Array[String] = []
var captures: Array[String] = []
var rendered_fonts := {}


func _ready() -> void:
	main = MainScene.instantiate()
	main.name = "Main"
	add_child(main)
	var window_size := get_window().size
	var evidence_root := EVIDENCE_ROOT
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--appearance="):
			main.game_settings.ui_appearance = StringName(argument.trim_prefix("--appearance="))
			main._apply_player_settings()
		if argument.begins_with("--output-root="):
			evidence_root = argument.trim_prefix("--output-root=")
	output_directory = "%s/%dx%d" % [evidence_root, window_size.x, window_size.y]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory))
	_run_review.call_deferred()


func _run_review() -> void:
	await _capture("01_title", main.main_menu_overlay)
	main._on_menu_settings_pressed()
	for tab_index in range(main.settings_screen.tabs.get_tab_count()):
		main.settings_screen.tabs.current_tab = tab_index
		await _capture("02_settings_%d" % tab_index, main.settings_screen)
	main.settings_screen.close()
	main._on_menu_play_pressed()
	main.vs_controller._select_mode(false)
	main.run_setup_screen.select_difficulty(&"hard")
	await _capture("03_run_setup", main.run_setup_screen)
	main.run_setup_screen.close()
	main._start_tutorial()
	await _capture("04_tutorial", main.tutorial_manager.hint_panel)
	_check_hud()
	_check_separate(main.tutorial_manager.hint_panel, main.release_hud.get_node("ShotReadout"), "Tutorial / shot controls")
	# The longest authored instruction must remain inside its paper container.
	var longest := ""
	for lesson in main.tutorial_levels:
		for step in lesson.get("steps", []):
			if String(step.get("text", "")).length() > longest.length():
				longest = String(step.text)
	main.tutorial_manager.blocker_text = longest
	main.tutorial_manager.blocker_timer = 30.0
	main.tutorial_manager._update_hint()
	await _capture("05_tutorial_long_copy", main.tutorial_manager.hint_panel)
	main._show_main_menu()
	await _capture("06_pause", main.main_menu_overlay)
	main.run_state.difficulty_profile = Difficulties.get_profile(&"hard")
	main._start_normal_run(SAFE_SEED)
	await _capture("07_run_intro", main.interstitial_overlay)
	for biome_index in range(6):
		# Arrange isolated presentation states; lifecycle legality is tested separately.
		main.run_state.phase = RunState.Phase.RUN_START
		main.run_state.level_index = biome_index * 3
		main._show_biome_intro()
		await _capture("08_biome_intro_%d" % biome_index, main.interstitial_overlay)
		main._load_level(biome_index * 3 + 2)
		await _capture("09_gameplay_%d" % biome_index, main.release_hud)
		_check_hud()
	main.run_state.tokens = 24
	for difficulty_id in [&"easy", &"normal", &"hard"]:
		main.run_state.difficulty_profile = Difficulties.get_profile(difficulty_id)
		main.run_state.phase = RunState.Phase.HOLE_RESULTS
		main._show_shop(3)
		await _capture("10_shop_%s" % difficulty_id, main.shop_manager.shop_overlay)
		_check_cards()
	main.shop_manager.shop_card_buttons[0].pressed.emit()
	await _capture("11_shop_purchased", main.shop_manager.shop_overlay)
	_check_cards()
	main.shop_manager.tokens = 0
	main.shop_manager._refresh_shop()
	await _capture("12_shop_unaffordable", main.shop_manager.shop_overlay)
	_check_cards()
	main.shop_manager.shop_overlay.visible = false
	# Maximum distinct bag stresses wrap and final collection without changing game data.
	for card in Cards.get_cards():
		main.run_state.owned_card_definitions.append(card)
		main.run_state.owned_cards.append(card.name)
	main.run_state.level_index = 15
	main._show_biome_intro()
	await _capture("13_biome_full_bag", main.interstitial_overlay)
	main._load_level(12)
	for previous_hole in range(1, 13):
		main.run_stats.record_hole_result({
			"hole_number": previous_hole, "biome_name": "Snow" if previous_hole > 9 else "Meadow",
			"strokes": 4, "par": 4, "stars": 4, "golf_result": "PAR", "performance": "EXCELLENT",
			"time": "01:05", "earned": 2, "wallet": 14, "score_to_par": 0,
		})
	for score_delta in [3, 1, -2]:
		main.run_state.strokes = int(main.run_state.levels[main.run_state.level_index].par) + score_delta
		main.run_state.level_elapsed = 48.0
		main.run_state.last_hole_rating = Rating.rate(main.run_state.strokes, int(main.run_state.levels[main.run_state.level_index].par), main.run_state.level_elapsed)
		main.run_state.last_hole_reward = 3 if score_delta < 0 else 0
		main.run_stats.record_hole_result({
			"hole_number": 13, "biome_name": "Swamp", "strokes": main.run_state.strokes,
			"par": int(main.run_state.levels[main.run_state.level_index].par), "stars": main.run_state.last_hole_rating.stars,
			"golf_result": main.run_state.last_hole_rating.golf_result, "performance": main.run_state.last_hole_rating.performance,
			"time": "00:48", "earned": main.run_state.last_hole_reward, "wallet": main.run_state.tokens, "score_to_par": score_delta,
		})
		main.run_state.phase = RunState.Phase.HOLE_RESOLVING
		main._show_hole_results()
		await _capture("14_result_%d_star" % int(main.run_state.last_hole_rating.stars), main.interstitial_overlay)
	main.transition_presentation.history_selector.set_expanded(true)
	main.transition_presentation.history_selector.select_hole(5)
	await _capture("15_hole_history", main.interstitial_overlay)
	main.run_state.total_strokes = main._total_par() + 3
	main.run_stats.total_strokes = main.run_state.total_strokes
	main.run_stats.total_run_time = 1638.0
	# Keep the longest valid seed complete on the final printed scorecard.
	main.run_state.run_seed = 2147483647
	main._show_run_results()
	await _capture("16_run_results", main.interstitial_overlay)
	main._show_ending()
	await _capture("17_ending", main.interstitial_overlay)
	var report := {
		"window_size": get_window().size, "logical_size": get_viewport_rect().size,
		"captures": captures, "capture_count": capture_count,
		"layout_checks": layout_checks, "layout_failures": layout_failures, "findings": findings,
		"rendered_fonts": rendered_fonts.keys(),
	}
	var file := FileAccess.open(output_directory.path_join("layout_report.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
	print("[VISUAL REVIEW] %d captures / %d layout checks / %d failures" % [capture_count, layout_checks, layout_failures])
	review_complete = true


func _capture(capture_name: String, screen: Control) -> void:
	await get_tree().create_timer(0.65).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_check_tree(screen, capture_name)
	_check_fonts(main, capture_name)
	var capture := get_viewport().get_texture().get_image()
	if capture_name in ["16_run_results", "17_ending"]:
		_check_trophy_ink(capture, capture_name)
	var capture_path := output_directory.path_join(capture_name + ".png")
	var error := capture.save_png(capture_path)
	_check(error == OK, "Screenshot save: " + capture_name)
	if error == OK:
		capture_count += 1
		captures.append(capture_path)


func _check_trophy_ink(capture: Image, context: String) -> void:
	# Bounds/opacity alone do not prove a custom-drawn control actually rendered.
	var art_rect: Rect2 = main.transition_presentation.hero_icon.get_global_rect()
	var pixel_scale := Vector2(capture.get_size()) / get_viewport_rect().size
	var bright_samples := 0
	for row in range(1, 10):
		for column in range(1, 10):
			var sample := (art_rect.position + art_rect.size * Vector2(column, row) / 10.0) * pixel_scale
			var x := clampi(roundi(sample.x), 0, capture.get_width() - 1)
			var y := clampi(roundi(sample.y), 0, capture.get_height() - 1)
			var pixel := capture.get_pixel(x, y)
			if (pixel.r + pixel.g + pixel.b) / 3.0 > 0.38:
				bright_samples += 1
	_check(bright_samples >= 12, "%s trophy art is blank (%d ink samples)" % [context, bright_samples])


func _check_tree(node: Node, context: String) -> void:
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return
	if node is Label or node is BaseButton or node is LineEdit:
		var control := node as Control
		_check(get_viewport_rect().grow(2.0).encloses(control.get_global_rect()), "%s offscreen: %s" % [context, node.get_path()])
		if node is Label and not (node as Label).text.is_empty():
			var label := node as Label
			if label.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING:
				_check(label.get_visible_line_count() >= label.get_line_count(), "%s clipped lines: %s" % [context, node.get_path()])
		if node is Button and not (node as Button).text.is_empty() and not node is UICard:
			var button := node as Button
			var font := button.get_theme_font("font")
			var width := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
			var margins := button.get_theme_stylebox("normal").get_minimum_size().x
			_check(width + margins <= button.size.x + 2.0, "%s ellipsized action: %s" % [context, button.text])
	for child in node.get_children():
		_check_tree(child, context)


func _check_fonts(node: Node, context: String) -> void:
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	var copy := ""
	var font: Font
	if node is Label or node is Button or node is LineEdit:
		copy = node.text
		font = node.get_theme_font("font")
	elif node is RichTextLabel:
		copy = node.get_parsed_text()
		font = node.get_theme_font("normal_font")
	if font and not copy.is_empty():
		var base_font := font
		while base_font is FontVariation:
			base_font = base_font.base_font
		rendered_fonts[base_font.resource_path] = true
		_check(base_font.resource_path.contains("Jersey10"), "%s legacy font: %s" % [context, node.get_path()])
		var missing := ""
		for character in copy:
			if character.unicode_at(0) > 32 and not font.has_char(character.unicode_at(0)) and not missing.contains(character):
				missing += character
		_check(missing.is_empty(), "%s missing glyphs %s: %s" % [context, missing, node.get_path()])
	for child in node.get_children():
		_check_fonts(child, context)


func _check_hud() -> void:
	_check_separate(main.release_hud.identity_panel, main.release_hud.score_panel, "HUD identity / score")
	_check_separate(main.release_hud.score_panel, main.release_hud.effects_panel, "HUD score / effects")
	_check_separate(main.release_hud.effects_panel, main.menu_button, "HUD effects / menu")


func _check_cards() -> void:
	for card in main.shop_manager.shop_card_buttons:
		if not card.is_visible_in_tree():
			continue
		var content := card.get_node("CardContentMargin") as Control
		_check(card.get_global_rect().grow(2.0).encloses(content.get_global_rect()), "Card contents escape stock: " + card.name)
		for text_label in [card.benefit_description, card.curse_description, card.stack_label]:
			_check(card.get_global_rect().encloses(text_label.get_global_rect()), "Card disclosure outside card: " + text_label.text)
			_check(text_label.get_visible_line_count() >= text_label.get_line_count(), "Card disclosure clipped: " + text_label.text)


func _check_separate(first: Control, second: Control, context: String) -> void:
	if not first.is_visible_in_tree() or not second.is_visible_in_tree():
		return # Tutorial concepts intentionally hidden before their introduction.
	_check(not first.get_global_rect().intersects(second.get_global_rect()), context)


func _check(passed: bool, description: String) -> void:
	layout_checks += 1
	if not passed:
		layout_failures += 1
		findings.append(description)
		print("[VISUAL LAYOUT FAIL] " + description)
