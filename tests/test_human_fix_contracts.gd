extends GutTest

func test_remaining_shot_warning_is_derived_and_updates_after_refund() -> void:
	var canvas := CanvasLayer.new()
	add_child_autofree(canvas)
	var hud := ReleaseHUD.new()
	hud.setup(canvas)
	var state := RunState.new()
	state.phase = RunState.Phase.HOLE_PLAY
	for index in range(5):
		state.record_accepted_shot()
		state.invalidate_shot_refund()
	hud.update_display({"remaining_shots": state.remaining_shots(3)})
	assert_eq(hud.stroke_warning.text, "2 SHOTS LEFT")
	var ticket := state.record_accepted_shot()
	hud.update_display({"remaining_shots": state.remaining_shots(3)})
	assert_eq(hud.stroke_warning.text, "FINAL SHOT")
	assert_true(state.refund_out_of_bounds_shot(ticket))
	hud.update_display({"remaining_shots": state.remaining_shots(3)})
	assert_eq(hud.stroke_warning.text, "2 SHOTS LEFT")
	hud.update_display({"remaining_shots": 3})
	assert_false(hud.stroke_warning.visible)

func test_appearance_defaults_persists_and_rejects_unknown_values() -> void:
	var settings := GameSettings.new()
	assert_eq(settings.ui_appearance, &"dark")
	settings.ui_appearance = &"light"
	var path := "user://human_playtest_fix_20260906/test_appearance.cfg"
	assert_eq(settings.save_to(path), OK)
	var restored := GameSettings.new()
	assert_eq(restored.load_from(path), OK)
	assert_eq(restored.ui_appearance, &"light")
	restored.ui_appearance = &"invalid"
	restored.apply_runtime(false)
	assert_eq(restored.ui_appearance, &"dark")

func test_appearance_is_ui_scoped_lossless_and_updates_new_controls() -> void:
	var canvas := CanvasLayer.new()
	add_child_autofree(canvas)
	var panel := PanelContainer.new()
	panel.theme = preload("res://assets/release_theme.tres")
	panel.add_theme_stylebox_override("panel", UIStyle.panel_style(UIStyle.INK, UIStyle.GOLD))
	canvas.add_child(panel)
	var label := Label.new()
	panel.add_child(label)
	UIStyle.apply_ui(label, 22)
	var adapter := UIAppearance.new()
	add_child_autofree(adapter)
	adapter.setup(canvas, panel.theme)
	await wait_process_frames(2)
	adapter.apply_mode(&"light")
	assert_gt(panel.get_theme_stylebox("panel").bg_color.get_luminance(), 0.7)
	assert_eq(label.get_theme_color("font_color"), UIStyle.PAPER_INK)
	for index in range(3):
		adapter.apply_mode(&"dark")
		assert_eq(label.get_theme_color("font_color"), UIStyle.PAPER)
		assert_eq(panel.get_theme_stylebox("panel").bg_color, UIStyle.INK)
		adapter.apply_mode(&"light")
	var late := Label.new()
	UIStyle.apply_ui(late, 22)
	panel.add_child(late)
	await wait_process_frames(3)
	assert_eq(late.get_theme_color("font_color"), UIStyle.PAPER_INK)
	UIStyle.apply_ui(late, 22, UIStyle.CURSE)
	await wait_process_frames(2)
	assert_eq(late.get_theme_color("font_color"), UIStyle.appearance_color(UIStyle.CURSE, &"foreground", &"light"))

func test_refund_ticket_is_exactly_once_and_never_refunds_a_penalty() -> void:
	var state := RunState.new()
	state.phase = RunState.Phase.HOLE_PLAY
	var first := state.record_accepted_shot()
	state.invalidate_shot_refund()
	assert_false(state.refund_out_of_bounds_shot(first), "A completed normal shot counts")
	var second := state.record_accepted_shot()
	assert_true(state.refund_out_of_bounds_shot(second))
	assert_false(state.refund_out_of_bounds_shot(second))
	assert_eq(state.strokes, 1)
	assert_eq(state.stats.total_strokes, 1)
	var third := state.record_accepted_shot()
	state.invalidate_shot_refund()
	state.record_stroke()
	assert_false(state.refund_out_of_bounds_shot(third), "Water/lava/crush retain shot and penalty")
	assert_eq(state.strokes, 3)
	assert_eq(state.stats.total_strokes, 3)
	state.reset(12)
	assert_false(state.refund_out_of_bounds_shot(third))
	assert_eq(state.strokes, 0)
	assert_eq(state.remaining_shots(3), 7)

func test_rarity_is_gameplay_with_safe_category_aware_scaling() -> void:
	for base in CardDatabase.get_cards():
		var previous_price := 0
		var previous_duration := 0
		for rarity in CardRarityProfile.IDS:
			var card := CardRarityProfile.create(base, rarity)
			assert_true(card.is_valid())
			assert_eq(card.id, base.id, "Copies still stack by stable identity")
			assert_gt(card.price, previous_price)
			assert_gte(card.curse_duration_holes, previous_duration)
			assert_lte(card.curse_effects.scaled(1.6).hazard_count_delta, 4)
			assert_gte(card.curse_effects.scaled(1.6).cup_radius_scale_delta, -0.45)
			assert_gte(card.curse_effects.scaled(1.6).shot_power_delta, -0.65)
			assert_ne(card.bonus_effects, base.bonus_effects, "An offer owns its effects")
			previous_price = card.price
			previous_duration = card.curse_duration_holes
		var common := CardRarityProfile.create(base, &"common")
		var legendary := CardRarityProfile.create(base, &"legendary")
		assert_ne(common.bonus_description, legendary.bonus_description)
		assert_ne(common.curse_description, legendary.curse_description)
		assert_eq(base.rarity, &"common", "The shared catalog was not mutated")

func test_rarity_distribution_is_seeded_and_legendary_is_rare() -> void:
	for difficulty in [&"easy", &"normal", &"hard"]:
		var first := RandomNumberGenerator.new()
		var second := RandomNumberGenerator.new()
		first.seed = 7331
		second.seed = 7331
		var counts := {&"common": 0, &"rare": 0, &"epic": 0, &"legendary": 0}
		for index in range(10000):
			var rarity := CardRarityProfile.roll(first, difficulty)
			assert_eq(rarity, CardRarityProfile.roll(second, difficulty))
			counts[rarity] += 1
		assert_gt(counts.common, counts.rare)
		assert_gt(counts.rare, counts.epic)
		assert_gt(counts.epic, counts.legendary)
		assert_gt(counts.legendary, 0)
		assert_lt(counts.legendary, 300)

func test_ice_collision_is_one_tile_even_for_a_legacy_caller() -> void:
	var hazard := MovingHazard.new()
	add_child_autofree(hazard)
	for size in [Vector2(24, 24), Vector2(100, 100), Vector2(180, 180)]:
		hazard.configure({"type": "falling_ice", "pos": Vector2.ZERO})
		hazard.setup_collision(size)
		assert_eq(hazard.collision_shape.shape.size, Vector2(100, 100))
		assert_eq(hazard.detector_shape.shape.size, Vector2(100, 100))
