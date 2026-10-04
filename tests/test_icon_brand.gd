extends GutTest

const Catalog := preload("res://scripts/ui/icon_catalog.gd")
const Icon := preload("res://scripts/ui/ui_icon.gd")
const Style := preload("res://scripts/ui/ui_style.gd")
const Logo := preload("res://scripts/ui/ui_logo.gd")
const Illustration := preload("res://scripts/ui/card_illustration.gd")
const ThemeAsset := preload("res://assets/release_theme.tres")


func test_all_icon_tiers_load_have_transparency_and_unclipped_bounds() -> void:
	var seen := {}
	for id: StringName in Catalog.IDS:
		assert_false(seen.has(id), "Duplicate canonical ID: " + String(id))
		seen[id] = true
		for small in [false, true]:
			var texture := Catalog.texture(id, small)
			assert_not_null(texture, Catalog.asset_path(id, small))
			if not texture:
				continue
			var image := texture.get_image()
			var extent := 80 if Catalog.has_card_art(id) else 64 if small else 256
			assert_eq(image.get_size(), Vector2i(extent, extent))
			var bounds := image.get_used_rect()
			assert_true(bounds.has_area(), "Empty glyph: " + String(id))
			assert_true(Rect2i(1, 1, extent - 2, extent - 2).encloses(bounds), "Clipped stroke: " + String(id))
			assert_lt(image.get_pixel(0, 0).a, 0.01, "No baked background: " + String(id))


func test_aliases_resolve_once_and_different_meanings_do_not_share_geometry() -> void:
	for alias: StringName in Catalog.ALIASES:
		var target: StringName = Catalog.ALIASES[alias]
		assert_true(target in Catalog.IDS)
		assert_false(Catalog.ALIASES.has(target), "No alias chains")
		assert_eq(Catalog.asset_path(alias), Catalog.asset_path(target))
	for pair in [["sand", "sand_cleats"], ["ice", "snow"], ["lava", "volcanic"], ["back", "continue"], ["seed", "randomize"], ["curse", "warning"]]:
		assert_ne(Catalog.asset_path(pair[0]), Catalog.asset_path(pair[1]))
	var signatures := {}
	for id: StringName in Catalog.IDS:
		var source := FileAccess.get_sha256(Catalog.asset_path(id))
		assert_false(signatures.has(source), "Redundant canonical geometry: " + String(id))
		signatures[source] = id
	assert_false(Catalog.has_icon(&"not_a_symbol"))
	assert_eq(Catalog.asset_path(&"not_a_symbol"), Catalog.asset_path(&"missing"))


func test_required_families_and_card_categories_are_complete() -> void:
	for id: StringName in [&"hole", &"stroke", &"par", &"timer", &"coin", &"benefit", &"curse", &"stack", &"warning", &"oob", &"settings", &"display", &"audio", &"controls", &"accessibility", &"dark", &"light", &"back", &"continue", &"copy", &"seed"]:
		assert_true(Catalog.has_icon(id), String(id))
	for biome in BiomeDatabase.get_profiles():
		assert_true(Catalog.has_icon(Style.biome_icon(biome.display_name)))
	for id: StringName in [&"water", &"sand", &"ice", &"lava", &"bounce_pad", &"pendulum", &"falling_ice", &"blocker"]:
		assert_true(Catalog.has_icon(id), String(id))
	for card in CardDatabase.get_cards() + CardDatabase.get_tutorial_cards():
		assert_true(Catalog.has_icon(Style.card_icon(card.id)), String(card.id))
	for rarity: StringName in CardRarityProfile.IDS:
		assert_true(Catalog.has_icon(StringName("rarity_" + String(rarity))))


func test_small_variant_tracks_rendered_not_only_logical_size() -> void:
	assert_true(Icon.small_tier_for(16))
	assert_true(Icon.small_tier_for(32))
	assert_false(Icon.small_tier_for(48))
	assert_true(Icon.small_tier_for(38, 1280.0 / 1920.0))
	assert_false(Icon.small_tier_for(38, 2560.0 / 1920.0))


func test_icons_are_passive_and_respect_explicit_badge_size() -> void:
	var icon := Icon.new()
	icon.custom_minimum_size = Vector2(18, 18)
	add_child_autofree(icon)
	assert_eq(icon.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(icon.custom_minimum_size, Vector2(18, 18))
	icon.configure(&"bonus")
	assert_eq(icon.icon_color, Style.BONUS)
	icon.configure(&"coin", Style.INK_DEEP)
	assert_eq(icon.icon_color, Style.INK_DEEP, "Gold price tags require explicit dark ink")


func test_dynamic_icon_reconfigure_reparent_and_theme_switch_are_lossless() -> void:
	var canvas := CanvasLayer.new()
	add_child_autofree(canvas)
	var root := Control.new()
	root.theme = ThemeAsset
	canvas.add_child(root)
	var icon := Icon.new()
	root.add_child(icon)
	icon.configure(&"bonus")
	var adapter := UIAppearance.new()
	add_child_autofree(adapter)
	adapter.setup(canvas, ThemeAsset)
	await wait_process_frames(3)
	for iteration in range(3):
		adapter.apply_mode(&"light")
		assert_eq(icon.icon_color, Style.appearance_color(Style.BONUS, &"foreground", &"light"))
		icon.configure(&"curse")
		await wait_process_frames(2)
		assert_eq(icon.icon_color, Style.appearance_color(Style.CURSE, &"foreground", &"light"))
		root.remove_child(icon)
		root.add_child(icon)
		await wait_process_frames(3)
		assert_eq(icon.palette_changed.get_connections().size(), 1, "Reparent must not duplicate adapter connection")
		adapter.apply_mode(&"dark")
		# Reparented controls must retain their canonical, not already-mapped, ink.
		assert_eq(icon.icon_color, Style.CURSE)
		icon.configure(&"bonus")
		await wait_process_frames(2)


func test_logo_and_collectible_ink_have_explicit_theme_policy() -> void:
	var canvas := CanvasLayer.new()
	add_child_autofree(canvas)
	var logo := Logo.new()
	canvas.add_child(logo)
	var art := Illustration.new()
	art.configure(&"power_club", Style.PAPER, Style.GOLD)
	canvas.add_child(art)
	var adapter := UIAppearance.new()
	add_child_autofree(adapter)
	adapter.setup(canvas, ThemeAsset)
	await wait_process_frames(2)
	adapter.apply_mode(&"light")
	assert_eq(logo.appearance, &"dark", "The actual scenic title background is not a light UI surface")
	logo.theme_aware = true
	adapter.apply_mode(&"light")
	assert_eq(logo.appearance, &"light", "Printed light surfaces explicitly opt into dark logo ink")
	assert_eq(art.icon_color, Style.PAPER, "Dark printed fields keep their light equipment ink")
	assert_eq(art.accent_color, Style.GOLD)
	assert_eq(Logo.WORDMARK.resource_path, Logo.WORDMARK_LIGHT.resource_path, "Approved raster logo never changes lettering or paint with UI mode.")
	assert_eq(FileAccess.get_sha256(Logo.WORDMARK.resource_path), FileAccess.get_sha256("res://assets/pixel_sample/ui/wordmark.png"), "Production logo is the unchanged approved export.")
	adapter.apply_mode(&"dark")
	assert_eq(logo.appearance, &"dark")


func test_native_theme_selection_marks_remain_readable_in_light_mode() -> void:
	var canvas := CanvasLayer.new()
	add_child_autofree(canvas)
	var panel := Control.new()
	panel.theme = ThemeAsset
	canvas.add_child(panel)
	var adapter := UIAppearance.new()
	add_child_autofree(adapter)
	adapter.setup(canvas, ThemeAsset)
	await wait_process_frames(2)
	adapter.apply_mode(&"light")
	var checked := panel.theme.get_icon("radio_checked", "PopupMenu").get_image()
	assert_gt(checked.get_pixel(8, 8).a, 0.5)
	assert_lt(checked.get_pixel(8, 8).get_luminance(), 0.3)
	adapter.apply_mode(&"dark")
	var original := panel.theme.get_icon("radio_checked", "PopupMenu").get_image()
	assert_gt(original.get_pixel(8, 8).get_luminance(), 0.8)


func test_all_rarity_cards_preserve_disclosure_and_authoritative_values() -> void:
	for rarity: StringName in CardRarityProfile.IDS:
		var definition := CardRarityProfile.create(CardDatabase.get_cards()[0], rarity)
		var price := definition.price
		var benefit := definition.bonus_description
		var card := UICard.new()
		add_child_autofree(card)
		card.configure_card(definition, true, false, 2)
		assert_eq(card.rarity_icon.icon_name, StringName("rarity_" + String(rarity)))
		assert_eq(card.category_label.text, String(rarity).to_upper())
		assert_eq(card.price_label.text, str(price))
		assert_eq(definition.price, price)
		assert_eq(definition.bonus_description, benefit)
		assert_false(card.benefit_description.text.is_empty())
		assert_false(card.curse_description.text.is_empty())
		assert_true(card.stack_label.text.contains("×2"))


func test_native_theme_glyphs_and_app_assets_load() -> void:
	assert_eq(ThemeAsset.get_icon("arrow", "OptionButton").get_size(), Vector2(16, 16))
	assert_eq(ThemeAsset.get_icon("radio_checked", "PopupMenu").get_size(), Vector2(16, 16))
	for size_value: int in [16, 32, 48, 128, 256]:
		var texture := load("res://assets/ui/brand/app_icon_%d.png" % size_value) as Texture2D
		assert_not_null(texture)
		assert_eq(texture.get_size(), Vector2.ONE * size_value)
	var icon: Texture2D = load(ProjectSettings.get_setting("application/config/icon"))
	assert_not_null(icon)
	var ico := FileAccess.get_file_as_bytes("res://assets/ui/brand/app_icon.ico")
	assert_eq(ico.decode_u16(2), 1)
	assert_eq(ico.decode_u16(4), 5)
	for index in range(5):
		var entry := 6 + index * 16
		var count := ico.decode_u32(entry + 8)
		var offset := ico.decode_u32(entry + 12)
		var image := Image.new()
		assert_eq(image.load_png_from_buffer(ico.slice(offset, offset + count)), OK)
		assert_eq(image.get_width(), [16, 32, 48, 128, 256][index])


func test_warning_and_navigation_keep_their_meaning() -> void:
	var canvas := CanvasLayer.new()
	add_child_autofree(canvas)
	var hud := ReleaseHUD.new()
	hud.setup(canvas)
	hud.update_display({"remaining_shots": 1})
	assert_eq(hud.stroke_warning_icon.icon_name, &"warning")
	assert_eq(hud.stroke_warning.text, "FINAL SHOT")
	hud.show_out_of_bounds(2)
	assert_false(hud.stroke_warning.visible)
	assert_true(hud.oob_panel.visible)
	await wait_process_frames(3)
	for label: Label in hud.oob_countdown_label.get_parent().get_children():
		var text_width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		assert_gte(label.size.x, text_width, "OOB symbol must not squeeze away its explanation")
	var history := HoleHistorySelector.new()
	add_child_autofree(history)
	history.set_history([{"hole_number": 1}, {"hole_number": 2}], 2, 18)
	history.set_expanded(false)
	assert_eq(history.heading.text, "Hole")
	assert_false(history.previous_label.visible)
	history.set_expanded(true)
	assert_eq(history.previous_label.text, "01/18")
	assert_true(history.previous_label.visible)
	assert_false(history.next_label.visible, "Future holes never become a preview")


func test_results_rating_and_biome_motif_have_surface_appropriate_ink() -> void:
	var canvas := CanvasLayer.new()
	add_child_autofree(canvas)
	var overlay := PanelContainer.new()
	overlay.theme = ThemeAsset
	canvas.add_child(overlay)
	var title := Label.new()
	var body := Label.new()
	overlay.add_child(title)
	overlay.add_child(body)
	var presentation := TransitionPresentation.new()
	presentation.setup(overlay, title, body)
	# The production composition supplies this slot; standalone transition
	# fixtures provide the same narrow presentation boundary.
	presentation.visual_details = VBoxContainer.new()
	overlay.add_child(presentation.visual_details)
	var adapter := UIAppearance.new()
	add_child_autofree(adapter)
	adapter.setup(canvas, ThemeAsset)
	for appearance: StringName in [&"dark", &"light"]:
		adapter.apply_mode(appearance)
		for earned in [1, 3, 5]:
			presentation.show_hole_result(0, false, "Meadow", 1, 18, {"stars": earned})
			await wait_process_frames(3)
			var stars := presentation.visual_details.find_children("RatingStar*", "Control", true, false)
			assert_eq(stars.size(), 5)
			for index in stars.size():
				var visible_alpha: float = stars[index].icon_color.a * stars[index].modulate.a
				if index < earned:
					assert_gt(visible_alpha, 0.9, "Earned stars are not faint unused slots")
				else:
					assert_lt(visible_alpha, 0.3, "Unearned slots remain visibly secondary")
		for biome in BiomeDatabase.get_profiles():
			presentation.show_biome(biome, 1)
			await wait_process_frames(3)
			var row := presentation.visual_details.get_node("BiomeMotif")
			assert_eq(row.get_child_count(), 3)
			for icon: UIIcon in row.get_children():
				if appearance == &"light":
					assert_lt(icon.icon_color.get_luminance(), 0.55, "No ivory-on-ivory intro glyph")
				else:
					assert_gt(icon.icon_color.get_luminance(), 0.4, "Dark scenic panels retain bright readable motif ink")
