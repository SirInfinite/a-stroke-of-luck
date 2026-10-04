extends GutTest

const MAIN := preload("res://scenes/main.tscn")


func test_title_parallax_uses_logical_mouse_events_and_respects_reduced_motion() -> void:
	var attract := TitleAttractMode.new()
	add_child_autofree(attract)
	attract.set_process(false)
	attract.set_anchors_preset(Control.PRESET_TOP_LEFT)
	attract.size = Vector2(1920, 1080)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(1800, 900)
	attract._input(motion)
	attract._process(0.1)
	assert_gt(attract.parallax.x, 1.0)
	assert_lt(attract.parallax.x, 28.0, "Ease toward the target, not a snap")
	attract.set_reduced_motion(true)
	attract._process(1.0)
	assert_eq(attract.parallax, Vector2.ZERO)


func test_settings_descriptions_only_follow_hover_or_control_focus() -> void:
	var main = MAIN.instantiate()
	add_child_autofree(main)
	var screen: SettingsScreen = main.settings_screen
	assert_eq(screen.master_mute.get_parent().get_node("MuteLabel").text, "MUTE")
	screen.open()
	await wait_process_frames(3)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(-1000, -1000)
	screen._input(motion)
	screen._process(0.016)
	assert_eq(screen.help_label.text, "")
	motion.position = screen.vsync_toggle.get_global_rect().get_center()
	screen._input(motion)
	screen._process(0.016)
	assert_eq(screen.help_label.text, SettingsScreen.DESCRIPTIONS.VSYNC)
	motion.position = Vector2(-1000, -1000)
	screen._input(motion)
	screen.vsync_toggle.grab_focus()
	screen._process(0.016)
	assert_eq(screen.help_label.text, SettingsScreen.DESCRIPTIONS.VSYNC)
	screen.close_button.grab_focus()
	screen._process(0.016)
	assert_eq(screen.help_label.text, "")


func test_toggle_has_equal_boxes_correct_text_and_silent_sync() -> void:
	var toggle := UIToggle.new()
	add_child_autofree(toggle)
	assert_eq(toggle.text, "Off")
	var off_size := toggle.get_combined_minimum_size()
	toggle.button_pressed = true
	assert_eq(toggle.text, "On")
	assert_eq(toggle.get_combined_minimum_size(), off_size)
	assert_eq(toggle.get_theme_stylebox("normal").get_minimum_size(), toggle.get_theme_stylebox("pressed").get_minimum_size())
	assert_eq(toggle.get_theme_stylebox("hover").get_minimum_size(), toggle.get_theme_stylebox("hover_pressed").get_minimum_size())
	toggle.set_pressed_no_signal(false)
	await wait_process_frames(2)
	assert_eq(toggle.text, "Off")
	assert_eq(toggle.get_theme_color("font_color"), toggle.get_theme_color("font_pressed_color"))


func test_seed_ticket_fades_hover_copy_feedback_and_restores_actual_seed() -> void:
	var ticket := SeedTicket.new()
	add_child_autofree(ticket)
	ticket.set_seed(2147483647)
	assert_eq(ticket.heading.text, "Seed")
	assert_eq(ticket.value_label.text, "2147483647")
	watch_signals(ticket)
	ticket.set_hovered(true)
	await wait_seconds(0.24)
	assert_eq(ticket.value_label.text, "Copy")
	ticket.value_button.pressed.emit()
	assert_signal_emitted_with_parameters(ticket, "copy_requested", [2147483647])
	ticket.show_copied()
	await wait_seconds(0.24)
	assert_eq(ticket.value_label.text, "Seed copied!")
	assert_eq(ticket.value_label.get_theme_color("font_color"), UIStyle.BONUS)
	await wait_seconds(1.2)
	assert_eq(ticket.value_label.text, "2147483647", "Even a stationary hovering cursor sees the seed again")
	ticket.show_copied()
	ticket.set_seed(42)
	assert_eq(ticket.value_label.text, "42", "New run cancels stale copy feedback")


func test_history_reel_scrolls_only_played_holes_and_owns_snapshots() -> void:
	var selector := HoleHistorySelector.new()
	add_child_autofree(selector)
	var history: Array = [{"hole_number": 1, "strokes": 3}, {"hole_number": 2, "strokes": 4}, {"hole_number": 3, "strokes": 2}, {"hole_number": 4, "strokes": 1}]
	selector.set_history(history, 3, 18)
	selector.select_hole(2)
	selector.set_expanded(true)
	await wait_seconds(0.24)
	assert_eq(selector.value_label.text, "02/18")
	assert_eq(selector.previous_label.text, "01/18")
	assert_eq(selector.next_label.text, "03/18")
	assert_false(selector.select_hole(4), "No access to a future fixture entry")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	selector.value_button.gui_input.emit(wheel)
	assert_eq(selector.selected_hole, 3)
	assert_false(selector.next_label.visible)
	selector.entry_for_hole(1).strokes = 99
	assert_eq(history[0].strokes, 3)
	assert_eq(selector.entry_for_hole(1).strokes, 3)


func test_light_ticket_retains_a_darker_inner_well() -> void:
	var outer := UIStyle.appearance_color(UIStyle.INK_SOFT, &"background", &"light")
	var inner := UIStyle.appearance_color(UIStyle.RECESSED, &"background", &"light")
	assert_lt(inner.get_luminance(), outer.get_luminance())
	var contrast := (inner.srgb_to_linear().get_luminance() + 0.05) / (UIStyle.PAPER_INK.srgb_to_linear().get_luminance() + 0.05)
	assert_gt(contrast, 4.5)
	assert_eq(UIStyle.appearance_color(UIStyle.RECESSED, &"background", &"dark"), UIStyle.RECESSED)


func test_rarity_ink_labels_and_frames_remain_readable_when_disabled() -> void:
	var stocks := {}
	var symbols := {}
	for rarity in CardRarityProfile.IDS:
		var card := UICard.new()
		add_child_autofree(card)
		card.disabled = true # ShopManager is the authoritative eligibility owner.
		card.configure_card(CardRarityProfile.create(CardDatabase.get_cards()[0], rarity), false, false)
		var normal := card.get_theme_stylebox("normal") as StyleBoxTexture
		var unavailable := card.get_theme_stylebox("disabled") as StyleBoxTexture
		assert_not_null(normal)
		assert_not_null(unavailable)
		assert_eq(normal.get_minimum_size(), unavailable.get_minimum_size(), "Disabled state preserves layout")
		assert_ne(normal.texture, unavailable.texture, "Unavailable cards have a distinct pixel frame")
		stocks[card.accent] = true
		symbols[card.rarity_icon.icon_name] = true
		assert_eq(card.category_label.text, String(rarity).to_upper(), "Rarity remains explicit without relying on color")
		assert_eq(card.card_layout.modulate, Color.WHITE, "Disabled art must not dim essential copy")
		assert_true(card.buy_button.disabled)
		assert_false(card.benefit_description.text.is_empty())
		assert_false(card.curse_description.text.is_empty())
	assert_eq(stocks.size(), 4)
	assert_eq(symbols.size(), 4)


func test_tutorial_bands_and_colors_use_real_meadow_surfaces() -> void:
	var levels := TutorialDatabase.get_levels()
	var meadow: BiomeProfile = BiomeDatabase.get_profiles()[0]
	for index in [1, 2]:
		assert_eq(levels[index].terrain_palette, meadow.terrain_palette)
		assert_eq(levels[index].hazards[0].size, Vector2(100, 600))
		assert_true(LevelValidator.validate_level(levels[index], index))
	var holder := Node2D.new()
	add_child_autofree(holder)
	var builder := LevelBuilder.new()
	holder.add_child(builder)
	builder.build_level(levels[2], holder)
	builder.open_tutorial_water_lane(levels[2])
	await wait_process_frames(2)
	assert_eq(levels[2].hazards[0].size, Vector2(100, 200))
	assert_eq(TutorialDatabase.get_levels()[2].hazards[0].size, Vector2(100, 600), "A new tutorial restores the mandatory band")
	var waters: Array[GameplayHazard] = []
	for node in builder.level_root.get_children():
		if node is GameplayHazard and node.hazard_type == &"water":
			waters.append(node)
	assert_eq(waters.size(), 1)
	var footprint := Vector2.ZERO
	for child in waters[0].get_children():
		if child is CollisionShape2D:
			footprint = child.shape.size
	assert_eq(footprint, Vector2(100, 200))


func test_real_tutorial_water_contact_opens_a_lane_only_after_reset() -> void:
	var main = MAIN.instantiate()
	add_child_autofree(main)
	main._start_tutorial()
	main._load_level(2)
	await wait_physics_frames(3)
	assert_true(main.ball.shoot_normalized(Vector2.RIGHT, 1.0))
	for frame in range(240):
		await wait_physics_frames(1)
		if main.tutorial_manager.completed_events.has(&"entered_water") and not main.hazard_resetting:
			break
	assert_true(main.tutorial_manager.completed_events.has(&"entered_water"))
	assert_false(main.hazard_resetting)
	assert_eq(main.run_state.levels[2].hazards[0].size, Vector2(100, 200))
	assert_eq(main.run_state.strokes, 2, "Accepted shot and normal water penalty still count")
	await wait_physics_frames(3)
	assert_almost_eq(main.ball.position, Vector2(-350, 50), Vector2.ONE)


func test_tutorial_hud_reveal_and_return_to_menu() -> void:
	var main = MAIN.instantiate()
	add_child_autofree(main)
	main._start_tutorial()
	assert_false(main.release_hud.score_panel.visible)
	assert_false(main.release_hud.effects_panel.visible)
	assert_false(main.release_hud.seed_ticket.visible)
	main.tutorial_manager.notify_event(&"shot_taken")
	main._update_status()
	assert_true(main.release_hud.score_panel.visible)
	assert_false(main.release_hud.coins_label.is_visible_in_tree())
	main._load_level(4)
	assert_true(main.release_hud.coins_label.is_visible_in_tree())
	assert_false(main.release_hud.effects_panel.visible)
	main.tutorial_manager.notify_event(&"shop_opened")
	main._update_status()
	assert_true(main.release_hud.effects_panel.visible)
	main._return_from_tutorial()
	await wait_process_frames(3)
	assert_eq(main.get_run_phase_name(), "MAIN_MENU")
	assert_false(main.run_state.tutorial_mode)
	assert_true(main.main_menu_overlay.visible)
	assert_false(main.tutorial_manager.hint_panel.visible)
	assert_false(main.ball.input_enabled)
	assert_true(main.run_state.levels.is_empty(), "Completing tutorial must not generate a real run")
	main._start_normal_run(424242)
	main._load_level(0)
	assert_true(main.release_hud.effects_panel.visible)
	assert_true(main.release_hud.seed_ticket.visible)


func test_biome_groups_are_seeded_and_safely_outside_course_bounds() -> void:
	for biome in BiomeDatabase.get_profiles():
		var first := BiomeAmbience.new()
		var second := BiomeAmbience.new()
		first.configure(biome.ambience, Color.WHITE, Color.WHITE, Vector2(1000, 600), Vector2(7600, 4600), 424242)
		second.configure(biome.ambience, Color.WHITE, Color.WHITE, Vector2(1000, 600), Vector2(7600, 4600), 424242)
		assert_eq(first.landscape, second.landscape)
		assert_eq(first.static_details, second.static_details)
		for group in first.landscape:
			assert_false(Rect2(Vector2(-565, -365), Vector2(1130, 730)).has_point(group.position))
		first.free()
		second.free()


func test_vertical_wall_rails_meet_across_cell_boundaries() -> void:
	var one := CourseVisualFactory.create_connected_wall_visual(Vector2(44, 100), Color.BROWN, {"top": true, "bottom": true}, Vector2(22, 0))
	var two := CourseVisualFactory.create_connected_wall_visual(Vector2(44, 100), Color.BROWN, {"top": true, "bottom": true}, Vector2(22, 100))
	var first = one.get_node("WallSurface")
	var second = two.get_node("WallSurface")
	var rectangles: Array[Rect2] = [Rect2(0, -50, 44, 100), Rect2(0, 50, 44, 100)]
	first.join_walls(rectangles)
	second.join_walls(rectangles)
	assert_eq(first.dimensions, Vector2(44, 100))
	assert_eq(second.dimensions, first.dimensions)
	var first_region: Rect2 = first.image_sprite.region_rect
	var second_region: Rect2 = second.image_sprite.region_rect
	assert_almost_eq(first_region.end.y, second_region.position.y, 0.0001, "World-aligned stone sampling must continue across the cell boundary.")
	assert_eq(first_region.position.x, second_region.position.x)
	assert_eq(first.image_sprite.texture, second.image_sprite.texture)
	assert_true((first_region.size * first.image_sprite.scale).is_equal_approx(Vector2(44, 100)), "The raster cap preserves its native wall rectangle.")
	assert_true(first._occupied(Vector2(22, 50.5)), "The first cap suppresses its interior bottom rim where the next wall begins.")
	assert_true(second._occupied(Vector2(22, 49.5)), "The second cap suppresses its interior top rim where the previous wall ends.")
	assert_false(first._occupied(Vector2(-0.5, 0)), "The exposed outside rail remains visible.")
	assert_false(second._occupied(Vector2(44.5, 100)), "The opposite exposed rail remains visible.")
	one.free()
	two.free()


func test_weak_ai_has_coarser_power_and_larger_but_bounded_errors() -> void:
	var beginner := AIDifficultyProfile.get_profile(&"palmer")
	var intermediate := AIDifficultyProfile.get_profile(&"mickelson")
	var expert := AIDifficultyProfile.get_profile(&"woods")
	assert_gt(beginner.aim_error, expert.aim_error * 12.0)
	assert_gt(intermediate.power_error, expert.power_error * 7.0)
	assert_gt(beginner.approach_precision, intermediate.approach_precision)
	assert_eq(beginner.lookahead_count, 0)
	assert_eq(intermediate.lookahead_count, 0)
	assert_lt(beginner.aim_error, deg_to_rad(22.0), "Still aiming along a plausible line")
	assert_lt(beginner.preparation_time - expert.preparation_time, 0.2)


func test_ai_preparation_moves_aim_not_the_resting_ball() -> void:
	var main = MAIN.instantiate()
	add_child_autofree(main)
	main._start_normal_run(424242, &"woods")
	main._load_level(0)
	var controller: VsMatchController = main.vs_controller
	controller.view.match_bar.set_meta(&"reduced_motion", false)
	controller.set_physics_process(false)
	main._complete_current_hole(false, false)
	await wait_physics_frames(4)
	var origin: Vector2 = main.ball.position
	controller.decision = {"direction": Vector2.RIGHT, "power": 0.7}
	controller._aim_start_angle = -0.22
	controller.think_remaining = controller.match_state.profile.preparation_time
	controller._physics_process(0.1)
	var first := float(main.ball.get_aim_direction_degrees())
	controller._physics_process(0.1)
	var second := float(main.ball.get_aim_direction_degrees())
	assert_gt(absf(first - second), 0.1, "Aim %s -> %s; can_shoot %s; phase %s; remaining %s" % [first, second, main.ball.can_shoot(), main.get_run_phase_name(), controller.think_remaining])
	assert_lt(absf(first - second), 8.0)
	assert_eq(main.ball.position, origin)
	assert_eq(main.run_state.strokes, 0)
	controller.return_to_menu()
	assert_false(main.ball.external_controlled)
