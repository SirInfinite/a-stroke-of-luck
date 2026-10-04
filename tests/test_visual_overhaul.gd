extends GutTest

const Style := preload("res://scripts/ui/ui_style.gd")
const ThemeResource := preload("res://assets/release_theme.tres")
const Cards := preload("res://scripts/card_database.gd")
const CardView := preload("res://scripts/ui/ui_card.gd")
const ActionButton := preload("res://scripts/ui/ui_action_button.gd")
const Factory := preload("res://scripts/course_visual_factory.gd")
const MainScene := preload("res://scenes/main.tscn")


func test_type_and_surface_language_has_distinct_reusable_roles() -> void:
	assert_eq(Style.DISPLAY_FONT, Style.UI_FONT, "Approved Jersey family now owns both roles.")
	assert_gt(ThemeResource.get_font_size("font_size", &"DisplayLabel"), ThemeResource.default_font_size, "Display hierarchy is retained within the approved family.")
	var paper := Style.paper_style()
	var ticket := Style.ticket_style(Style.CURSE_DARK, Style.CURSE)
	assert_eq(paper.bg_color, Style.PAPER)
	assert_eq(ticket.corner_detail, 1)
	assert_ne(paper.bg_color, ticket.bg_color)
	assert_gt(paper.border_width_bottom, paper.border_width_top)
	for type_name in [&"LineEdit", &"TabContainer", &"OptionButton", &"PopupMenu"]:
		assert_true(ThemeResource.has_font("font", type_name), "%s must not fall back to the engine font." % type_name)
	assert_not_null(ThemeResource.get_icon("grabber", &"HSlider"))
	assert_not_null(ThemeResource.get_icon("checked", &"CheckButton"))


func test_every_card_discloses_scaled_curse_and_stacks_without_mutating_definition() -> void:
	var view = CardView.new()
	add_child_autofree(view)
	for card in Cards.get_cards():
		var original_price: int = card.price
		var original_curse: String = card.curse_description
		view.configure_card(card, false, false, 12, 1.6)
		view.set_compact_layout(true)
		assert_eq(view.name_label.text.nocasecmp_to(card.name), 0, "The complete card name remains visible in the approved type treatment.")
		assert_eq(view.benefit_description.text, Style.compact_sentence(card.bonus_description))
		assert_eq(view.curse_description.text, Style.compact_sentence(card.curse_description_for_multiplier(1.6)))
		assert_eq(view.benefit_description.get_theme_font_size("font_size"), view.curse_description.get_theme_font_size("font_size"))
		assert_gte(view.curse_description.get_theme_font_size("font_size"), 22)
		assert_true(view.stack_label.text.contains("×12"))
		assert_true(view.unavailable_badge.visible)
		assert_eq(view.card_layout.modulate, Color.WHITE, "Affordability must not fade the disclosure.")
		assert_eq(card.price, original_price)
		assert_eq(card.curse_description, original_curse)


func test_reduced_motion_is_inherited_by_reusable_ui() -> void:
	var holder := Node.new()
	add_child_autofree(holder)
	holder.set_meta(&"reduced_motion", true)
	var button = ActionButton.new()
	holder.add_child(button)
	button.configure("PLAY", &"hole", &"primary")
	assert_false(Style.motion_enabled(button))
	button._on_hovered()
	await wait_process_frames(2)
	assert_eq(button.scale, Vector2.ONE)
	holder.set_meta(&"reduced_motion", false)
	assert_true(Style.motion_enabled(button))


func test_hazard_joins_and_launch_energy_are_presentation_only() -> void:
	var water := Factory.create_hazard_visual("water", Vector2(100,100), Color.BLUE, Color.WHITE, Color.BLACK, {"left": true})
	assert_true(water.get_meta(&"visual_connections").left)
	assert_eq(water.find_children("*", "CollisionObject2D", true, false).size(), 0)
	assert_eq(water.get_node("HazardSurface").kind, "water")
	assert_not_null(water.get_node("HazardSurface").body.texture, "The animated surface owns a real material texture.")
	water.free()
	var pad := Factory.create_hazard_visual("bounce_pad", Vector2(84,84), Color.BLUE, Color.WHITE, Color.BLACK)
	assert_eq(pad.get_node("HazardSurface").kind, "bounce_pad")
	assert_eq(pad.get_meta(&"visual_footprint"), Vector2(84, 84), "Pixel launch art keeps the hazard footprint.")
	assert_eq(pad.find_children("*", "CollisionObject2D", true, false).size(), 0)
	pad.free()


func test_overview_fits_between_hud_and_shot_controls_and_cup_returns_to_ball_zoom() -> void:
	var main = MainScene.instantiate()
	add_child_autofree(main)
	main._start_normal_run(8675309)
	for level_index in [0, 5, 11, 17]:
		main._load_level(level_index)
		await wait_process_frames(2)
		assert_eq(main.camera.zoom, Vector2.ONE * main.camera.gameplay_zoom)
		assert_true(main.ball.input_enabled)
		main._toggle_course_overview()
		await wait_seconds(0.4)
		var bounds: Rect2 = main.level_builder.get_playable_bounds()
		var screen_bounds: Rect2 = main.get_viewport().get_canvas_transform() * bounds
		assert_true(main.camera.usable_viewport.grow(1.0).encloses(screen_bounds))
		assert_false(main.ball.input_enabled)
		main._set_run_phase(RunState.Phase.HOLE_RESOLVING)
		main.feedback_director.reduced_motion = false
		main.feedback_director.play_cup_feedback(main.ball.global_position, false)
		await wait_seconds(0.55)
		main.feedback_director.reset_feedback()
		assert_false(main.camera.is_overview_active())
		assert_eq(main.camera.zoom, Vector2.ONE * main.camera.gameplay_zoom, "Cup feedback returns to the fixed gameplay zoom.")
