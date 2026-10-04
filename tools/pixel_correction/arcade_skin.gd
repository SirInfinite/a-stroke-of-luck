extends "res://tools/pixel_sample/sample_skin.gd"
## Second presentation candidate. The previous skin remains independently usable.

const Pixel := preload("res://tools/pixel_correction/arcade_assets.gd")
const ArcadeWorld := preload("res://tools/pixel_correction/arcade_world.gd")
const ArcadePower := preload("res://tools/pixel_correction/arcade_power.gd")
var hover_tweens: Dictionary = {}
var identity_material: StyleBoxTexture

func setup(owner_main) -> void:
	super.setup(owner_main)
	for child in main.main_menu_overlay.get_children():
		if child is TextureRect:
			child.texture = Pixel.texture("ui/background")
	# The inherited logo remains its original, approved texture and dimensions.
	main.menu_action_panel.add_theme_stylebox_override("panel", Pixel.box("felt"))
	for button in [main.menu_play_button, main.menu_resume_button, main.menu_tutorial_button, main.menu_skip_button, main.menu_settings_button, main.menu_quit_button, main.menu_button]:
		Pixel.button(button, button == main.menu_play_button)
	_style_hud()
	var meter: PowerMeter = main.power_meter
	if meter:
		meter.self_modulate.a = 0.0
		var blocks := ArcadePower.new()
		blocks.source = meter
		blocks.mouse_filter = Control.MOUSE_FILTER_IGNORE
		meter.add_child(blocks)
		blocks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func apply_hole() -> void:
	if is_instance_valid(world): world.queue_free()
	world = ArcadeWorld.new()
	main.level_builder.level_root.add_child(world)
	world.setup(main)
	_style_hud()

func _process(delta: float) -> void:
	var appearance_changed: bool = main and last_appearance != main.game_settings.ui_appearance
	super._process(delta)
	# ReleaseHUD updates its biome frame and overview control as live state changes.
	# Restore only sample material; its state, text and input remain authoritative.
	if identity_material and main.release_hud.identity_panel.get_theme_stylebox("panel") != identity_material:
		main.release_hud.identity_panel.add_theme_stylebox_override("panel", identity_material)
	if not main.release_hud.overview_button.get_theme_stylebox("normal").get_meta(&"arcade_material", false):
		Pixel.button(main.release_hud.overview_button, true)
	if appearance_changed:
		main.menu_action_panel.add_theme_stylebox_override("panel", Pixel.box("scorepaper" if last_appearance == &"light" else "felt"))

func _style_hud() -> void:
	super._style_hud()
	var hud = main.release_hud
	var light: bool = main.game_settings.ui_appearance == &"light"
	for panel in [hud.identity_panel, hud.score_panel, hud.effects_panel]:
		_own_material_ink(panel)
		panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		panel.add_theme_stylebox_override("panel", Pixel.box("scorepaper" if light else "felt"))
	identity_material = hud.identity_panel.get_theme_stylebox("panel")
	for label in [hud.biome_label, hud.hole_label, hud.strokes_label, hud.par_label, hud.timer_label, hud.coins_label, hud.bonus_label, hud.curse_label, hud.shot_label, hud.shot_power_label]:
		_own_material_ink(label)
		label.add_theme_font_override("font", Pixel.FONT)
		label.add_theme_color_override("font_color", Pixel.INK if light and label in [hud.biome_label, hud.strokes_label, hud.par_label, hud.timer_label, hud.coins_label] else Pixel.PAPER)
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.add_theme_color_override("font_shadow_color", Color("152432") if not light else Color.TRANSPARENT)
	# The supplied references give numerical feedback an unmistakable ink edge.
	# Keep this inside the existing HUD footprint so the ball stays the focus.
	for label in [hud.strokes_label, hud.timer_label, hud.coins_label]:
		label.add_theme_constant_override("outline_size", 2 if not light else 0)
		label.add_theme_color_override("font_outline_color", Pixel.INK)
	_replace_pixel_icon(hud.biome_icon, Pixel.texture("props/flowers"))
	for node in hud.effects_panel.find_children("*", "PanelContainer", true, false):
		if node.name == "BonusBand": node.add_theme_stylebox_override("panel", Pixel.box("benefit"))
		if node.name == "CurseBand": node.add_theme_stylebox_override("panel", Pixel.box("curse"))
	for icon in hud.effects_panel.find_children("*", "UIIcon", true, false):
		_replace_pixel_icon(icon, Pixel.symbol("curse" if String(icon.get_path()).contains("Curse") else "benefit"))
	hud.get_node("ShotReadout").add_theme_stylebox_override("panel", Pixel.box("felt"))
	Pixel.button(hud.overview_button, true)
	_own_material_ink(hud.overview_button)
	Pixel.button(main.menu_button)
	_own_material_ink(main.menu_button)

func _style_results() -> void:
	super._style_results()
	main.interstitial_overlay.get_node("SafeArea/Layout/DetailPanel").add_theme_stylebox_override("panel", Pixel.box("felt"))
	Pixel.button(main.interstitial_continue_button, true)
	Pixel.button(main.interstitial_menu_button)

func apply_shop(settle := true) -> void:
	super.apply_shop(settle)
	if main.run_state.tutorial_mode: return
	var shop = main.shop_manager
	shop.shop_overlay.add_theme_stylebox_override("panel", Pixel.box("scorepaper" if main.game_settings.ui_appearance == &"light" else "felt"))
	Pixel.button(shop.continue_button, true)
	var wallet_row: Control = shop.shop_tokens_label.get_parent().get_parent()
	for icon in wallet_row.get_children():
		if icon is UIIcon: _replace_pixel_icon(icon, Pixel.texture("props/coin"))
	var wallet_panel: PanelContainer = wallet_row.get_parent().get_parent()
	_own_material_ink(wallet_panel)
	wallet_panel.add_theme_stylebox_override("panel", Pixel.box("felt"))
	for label in [shop.shop_tokens_label, shop.shop_purchase_label]:
		_own_material_ink(label)
		label.add_theme_color_override("font_color", Pixel.GOLD if label == shop.shop_tokens_label else Pixel.PAPER)
	var header: Control = shop.shop_title_label.get_parent().get_parent()
	var title_stage: PanelContainer = header.get_child(0)
	_own_material_ink(title_stage)
	title_stage.add_theme_stylebox_override("panel", Pixel.box("teal_button"))
	for icon in title_stage.find_children("*", "UIIcon", true, false):
		_replace_pixel_icon(icon, Pixel.texture("props/bag"))

func _card(card: UICard) -> void:
	super._card(card)
	var art_name := String(card.card_id).to_lower().replace(" ", "_")
	if art_name not in Pixel.CARD_NAMES: return
	var material := "epic_card" if card.category_label.text == "EPIC" else "card"
	for state in ["normal", "hover", "pressed", "disabled"]:
		card.add_theme_stylebox_override(state, Pixel.box(material, Color(1.05, 1.05, 1.02) if state == "hover" else Color.WHITE))
	card.add_theme_stylebox_override("focus", Pixel.box("focus"))
	for label in [card.name_label, card.category_label, card.price_label, card.stack_label]:
		_own_material_ink(label)
		label.add_theme_color_override("font_color", Pixel.INK)
	card.name_label.add_theme_font_size_override("font_size", 31)
	card.centerpiece_panel.add_theme_stylebox_override("panel", Pixel.box(art_name))
	card.benefit_panel.add_theme_stylebox_override("panel", Pixel.box("benefit"))
	card.curse_panel.add_theme_stylebox_override("panel", Pixel.box("curse"))
	card.stack_panel.add_theme_stylebox_override("panel", Pixel.box("scorepaper"))
	card.card_layout.get_node("Header/PriceBadge").add_theme_stylebox_override("panel", Pixel.box("gold_button"))
	var illustration: TextureRect = card.centerpiece_icon.get_parent().get_node("SampleIllustration")
	illustration.texture = Pixel.texture("cards/" + art_name)
	if card.disabled:
		var id := card.get_instance_id()
		if hover_tweens.has(id) and hover_tweens[id].is_valid(): hover_tweens[id].kill()
		illustration.scale = Vector2.ONE
		illustration.rotation = 0.0
	_replace_pixel_icon(card.category_icon, Pixel.texture("cards/" + art_name))
	_replace_pixel_icon(card.rarity_icon, Pixel.symbol("rarity_epic" if material == "epic_card" else "rarity_common"))
	for icon in card.find_children("*", "UIIcon", true, false):
		if icon.name == "CoinIcon": _replace_pixel_icon(icon, Pixel.texture("props/coin"))
		elif icon.name == "BenefitIcon": _replace_pixel_icon(icon, Pixel.symbol("benefit"))
		elif icon.name == "CurseIcon": _replace_pixel_icon(icon, Pixel.symbol("curse"))
		elif String(icon.name).contains("Stack"): _replace_pixel_icon(icon, Pixel.symbol("stack"))
	var buy: Button = card.card_layout.get_node("SampleBuy")
	Pixel.button(buy, true)
	buy.custom_minimum_size.y = 63
	buy.add_theme_font_size_override("font_size", 30)
	buy.text = "BOUGHT!" if card.purchased else ("BUY  " + card.price_label.text + "  COINS")
	if not card.purchased and card.price_label.text == "1": buy.text = "BUY  1  COIN"
	if card.disabled and not card.purchased:
		buy.text = "SOLD OUT" if card.affordable else "NEED COINS"
	for badge in [card.purchased_badge, card.unavailable_badge]:
		_own_material_ink(badge)
		badge.add_theme_stylebox_override("normal", Pixel.box("gold_button" if badge == card.purchased_badge else "disabled"))
		badge.add_theme_font_override("font", Pixel.FONT)
		badge.add_theme_font_size_override("font_size", 23)
		badge.add_theme_color_override("font_color", Pixel.INK if badge == card.purchased_badge else Pixel.PAPER)
	if not card.has_meta(&"arcade_hover"):
		card.set_meta(&"arcade_hover", true)
		card.mouse_entered.connect(_hover.bind(card, true))
		card.mouse_exited.connect(_hover.bind(card, false))
		card.focus_entered.connect(_hover.bind(card, true))
		card.focus_exited.connect(_hover.bind(card, false))
		buy.mouse_entered.connect(_hover.bind(card, true))
		buy.mouse_exited.connect(_hover.bind(card, false))
		buy.button_down.connect(_press_art.bind(card))
		buy.button_up.connect(_hover.bind(card, true))
		card.tree_exiting.connect(func(): hover_tweens.erase(card.get_instance_id()))

func _hover(card: UICard, active: bool) -> void:
	if not is_instance_valid(card): return
	var illustration: Control = card.centerpiece_icon.get_parent().get_node("SampleIllustration")
	var id := card.get_instance_id()
	if hover_tweens.has(id) and hover_tweens[id].is_valid(): hover_tweens[id].kill()
	if card.disabled or main.feedback_director.reduced_motion:
		illustration.scale = Vector2.ONE
		illustration.rotation = 0.0
		return
	illustration.pivot_offset = illustration.size * 0.5
	var tween := illustration.create_tween().set_parallel(true)
	var target := Vector2(1.035, 1.035) if active else Vector2.ONE
	tween.tween_property(illustration, "scale", target, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(illustration, "rotation", -0.018 if active else 0.0, 0.09)
	hover_tweens[id] = tween

func _press_art(card: UICard) -> void:
	if card.disabled or main.feedback_director.reduced_motion: return
	var illustration: Control = card.centerpiece_icon.get_parent().get_node("SampleIllustration")
	var id := card.get_instance_id()
	if hover_tweens.has(id) and hover_tweens[id].is_valid(): hover_tweens[id].kill()
	illustration.scale = Vector2(0.97, 0.97)
	illustration.rotation = 0.0

func _purchase_feedback(kind: StringName) -> void:
	super._purchase_feedback(kind)
	for effect in fx_layer.get_children():
		if effect is TextureRect: effect.texture = Pixel.texture("props/coin")
		if effect is Label:
			effect.add_theme_stylebox_override("normal", Pixel.box("curse" if effect.text.contains("CURSE") else "benefit"))
			effect.add_theme_color_override("font_color", Pixel.PAPER)

func _replace_pixel_icon(icon: Control, texture: Texture2D) -> void:
	icon.self_modulate = Color(1, 1, 1, 0)
	for child in icon.get_children():
		if child is TextureRect: child.hide()
	var image: TextureRect = icon.get_node_or_null("ArcadeIcon")
	if not image:
		image = TextureRect.new()
		image.name = "ArcadeIcon"
		image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_child(image)
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.texture = texture
	image.show()
