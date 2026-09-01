extends GutTest

const BiomeDatabase := preload("res://scripts/biome_database.gd")
const ReleaseHUDScript := preload("res://scripts/release_hud.gd")
const ShopManagerScript := preload("res://scripts/shop_manager.gd")
const ShopPresentationScript := preload("res://scripts/shop_presentation.gd")
const TransitionPresentationScript := preload("res://scripts/transition_presentation.gd")
const TrajectoryRendererScript := preload("res://scripts/trajectory_renderer.gd")


func test_release_hud_prioritizes_player_state_and_active_curses() -> void:
	var root := Node.new()
	add_child_autofree(root)
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	var hud = ReleaseHUDScript.new()
	hud.setup(canvas)
	hud.update_display({
		"biome_name": "Snow",
		"biome_number": 4,
		"hole_number": 11,
		"hole_total": 18,
		"strokes": 3,
		"par": 4,
		"time": "0:42.5",
		"coins": 7,
		"bonuses": ["Power +25%"],
		"curses": ["Small cup · 2 holes"],
	})
	hud.update_shot(0.35, "127 deg")
	await wait_process_frames(1)

	assert_true(hud.biome_label.text.contains("SNOW"))
	assert_true(hud.hole_label.text.contains("11 / 18"))
	assert_true(hud.strokes_label.text.contains("3 / PAR 4"))
	assert_true(hud.timer_label.text.contains("0:42.5"))
	assert_true(hud.coins_label.text.contains("7"))
	assert_true(hud.bonus_label.text.contains("Power +25%"))
	assert_true(hud.curse_label.text.contains("!! ACTIVE CURSES / PENALTIES"))
	assert_true(hud.curse_label.text.contains("Small cup"))
	assert_true(hud.shot_label.text.contains("35%"))
	assert_gt(hud.strokes_label.size.x, 100.0)
	assert_gt(hud.timer_label.size.x, 100.0)
	assert_gt(hud.coins_label.size.x, 100.0)


func test_shop_presentation_adds_benefit_curse_and_purchase_hierarchy() -> void:
	var root := Node.new()
	add_child_autofree(root)
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	var shop = ShopManagerScript.new()
	root.add_child(shop)
	shop.create_overlay(canvas)
	var presentation = ShopPresentationScript.new()
	presentation.setup(shop)

	assert_eq(shop.shop_title_label.text, "THE CLUBHOUSE SHOP")
	for button in shop.shop_card_buttons:
		assert_not_null(button.get_node_or_null("Presentation/BenefitStrip"))
		assert_not_null(button.get_node_or_null("Presentation/CurseStrip"))
		assert_not_null(button.get_node_or_null("Presentation/PurchasedBadge"))


func test_biome_and_final_transitions_use_distinct_identity_treatments() -> void:
	var root := Control.new()
	add_child_autofree(root)
	var overlay := PanelContainer.new()
	root.add_child(overlay)
	var title := Label.new()
	var body := Label.new()
	overlay.add_child(title)
	overlay.add_child(body)
	var presentation = TransitionPresentationScript.new()
	presentation.setup(overlay, title, body)
	presentation.show_biome(BiomeDatabase.get_profiles()[5], 6, 6)
	await wait_process_frames(1)

	assert_true(presentation.identity_label.text.contains("VOLCANIC"))
	assert_true(presentation.identity_label.text.contains("6 / 6"))
	assert_ne(presentation.accent_band.get_parent(), overlay, "PanelContainer must not expand the accent band to full screen.")
	assert_lte(presentation.accent_band.size.y, 10.0)
	var biome_accent: Color = presentation.accent_band.color
	presentation.show_final()
	assert_eq(presentation.identity_label.text, "COURSE COMPLETE  ·  ALL SIX BIOMES")
	assert_ne(presentation.accent_band.color, biome_accent)


func test_trajectory_renderer_consumes_prediction_data_and_adapts_for_snow() -> void:
	var renderer = TrajectoryRendererScript.new()
	add_child_autofree(renderer)
	var snow = BiomeDatabase.get_profiles()[3]
	renderer.configure_level({
		"terrain_palette": snow.terrain_palette,
		"background_palette": snow.background_palette,
	})
	var points := PackedVector2Array([Vector2(10.0, 0.0), Vector2(24.0, 0.0), Vector2(40.0, 1.0)])
	renderer.set_prediction(points, 0.12)

	assert_eq(renderer.prediction_points, points)
	assert_true(renderer.visible)
	assert_lt(renderer.primary_color.get_luminance(), 0.3)
	assert_gt(renderer.backing_color.get_luminance(), 0.7)
	renderer.clear_prediction()
	assert_false(renderer.visible)
