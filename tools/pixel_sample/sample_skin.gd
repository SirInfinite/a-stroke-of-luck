extends Node
## Runtime styling adapter, deliberately not installed in the production scene.

const Art := preload("res://tools/pixel_sample/sample_assets.gd")
const World := preload("res://tools/pixel_sample/sample_world.gd")
var main
var world: Node2D
var fx_layer: CanvasLayer
var last_purchased: StringName
var last_phase := -1
var last_appearance: StringName
var pending_effects: Array[Control] = []
var settle_shop_frames := 0

func setup(owner_main) -> void:
	main = owner_main
	fx_layer = CanvasLayer.new()
	fx_layer.layer = 25
	add_child(fx_layer)
	main.main_menu_logo.self_modulate = Color(1, 1, 1, 0)
	var logo := Art.picture("ui/wordmark")
	main.main_menu_logo.add_child(logo)
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.menu_action_panel.add_theme_stylebox_override("panel", Art.box("felt"))
	main.title_attract_mode.hide()
	var landscape := Art.picture("ui/title_landscape")
	landscape.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	main.main_menu_overlay.add_child(landscape)
	main.main_menu_overlay.move_child(landscape, 0)
	landscape.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for button in [main.menu_play_button, main.menu_resume_button, main.menu_tutorial_button, main.menu_skip_button, main.menu_settings_button, main.menu_quit_button, main.menu_button]:
		if button: _own_material_ink(button)
		Art.button(button, button == main.menu_play_button)
	main.shop_manager.purchase_pulse_scale = 1.0
	main.shop_manager.coin_pulse_scale = 1.0
	main.shop_manager.curse_flash_intensity = 0.0
	main.shop_manager.hover_scale = 1.0
	main.shop_manager.card_bought.connect(func(card: CardDefinition): last_purchased = card.id)
	main.shop_manager.feedback_requested.connect(_purchase_feedback)
	_style_hud()

func apply_hole() -> void:
	if is_instance_valid(world): world.queue_free()
	world = World.new()
	main.level_builder.level_root.add_child(world)
	world.setup(main)
	_style_hud()

func _process(_delta: float) -> void:
	if not main: return
	if settle_shop_frames > 0:
		settle_shop_frames -= 1
		apply_shop(false)
	if main.main_menu_overlay.visible and not pending_effects.is_empty():
		_clear_purchase_effects()
		main.audio_controller.stop_transient_audio()
	if last_appearance != main.game_settings.ui_appearance:
		last_appearance = main.game_settings.ui_appearance
		_style_hud()
		main.menu_action_panel.add_theme_stylebox_override("panel", Art.box("scorepaper" if last_appearance == &"light" else "felt"))
		if main.run_state.phase == RunState.Phase.SHOP: apply_shop()
	var phase: int = main.run_state.phase
	if phase == last_phase: return
	last_phase = phase
	if phase == RunState.Phase.SHOP: apply_shop.call_deferred()
	if phase == RunState.Phase.HOLE_RESULTS: _style_results.call_deferred()
	if phase != RunState.Phase.SHOP:
		_clear_purchase_effects()

func _clear_purchase_effects() -> void:
	for effect in pending_effects:
		if is_instance_valid(effect): effect.queue_free()
	pending_effects.clear()

func _style_hud() -> void:
	var hud = main.release_hud
	var light: bool = main.game_settings.ui_appearance == &"light"
	var ink := Color("21372f") if light else Color("fff1cf")
	for panel in [hud.identity_panel, hud.score_panel, hud.effects_panel]:
		panel.add_theme_stylebox_override("panel", Art.box("scorepaper" if light else "felt"))
	for label in [hud.biome_label, hud.hole_label, hud.strokes_label, hud.par_label, hud.coins_label]:
		_own_material_ink(label)
		label.add_theme_font_override("font", Art.FONT)
		label.add_theme_color_override("font_color", ink)
	for label in hud.score_panel.find_children("*", "Label", true, false):
		_own_material_ink(label)
		label.add_theme_color_override("font_color", ink)
	for icon in hud.score_panel.find_children("*", "UIIcon", true, false):
		icon.hide()

func _style_results() -> void:
	main.interstitial_overlay.get_node("SafeArea/Layout/DetailPanel").add_theme_stylebox_override("panel", Art.box("felt"))
	main.interstitial_title_label.add_theme_font_override("font", Art.FONT)
	Art.button(main.interstitial_continue_button, true)
	Art.button(main.interstitial_menu_button)

func apply_shop(settle := true) -> void:
	# The tutorial retains its native offers, destination and progression wording.
	if main.run_state.tutorial_mode: return
	# Newly built cards are registered by UIAppearance through deferred callbacks.
	if settle: settle_shop_frames = 2
	var shop = main.shop_manager
	var light: bool = main.game_settings.ui_appearance == &"light"
	shop.shop_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shop.shop_overlay.add_theme_stylebox_override("panel", Art.box("scorepaper" if light else "felt"))
	var backdrop: CanvasItem = shop.shop_overlay.get_node_or_null("ShopBackdrop")
	if backdrop: backdrop.hide()
	shop.shop_title_label.add_theme_font_override("font", Art.FONT)
	shop.shop_tokens_label.add_theme_font_override("font", Art.FONT)
	for label in [shop.shop_title_label, shop.shop_status_label, shop.shop_destination_label]:
		_own_material_ink(label)
		label.add_theme_color_override("font_color", Color("21372f") if light else Color("fff1cf"))
	Art.button(shop.continue_button, true)
	_own_material_ink(shop.continue_button)
	shop.continue_button.text = "REPLAY SAMPLE"
	shop.shop_destination_label.text = "THE OLD SWING  ·  same hole on replay"
	for offer in shop.shop_card_buttons:
		if offer is UICard and offer.visible: _card(offer)

func _card(card: UICard) -> void:
	var art_name := String(card.card_id).to_lower().replace(" ", "_")
	if not ResourceLoader.exists(Art.ROOT + "cards/" + art_name + ".png"): return
	card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var material := "epic_card" if card.category_label.text == "EPIC" else "card"
	for state in ["normal", "hover", "pressed", "disabled"]:
		card.add_theme_stylebox_override(state, Art.box(material, Color(0.86, 0.84, 0.84) if state == "pressed" else Color.WHITE))
	card.name_label.add_theme_font_override("font", Art.FONT)
	card.name_label.add_theme_font_size_override("font_size", 29)
	card.category_label.add_theme_font_override("font", Art.FONT)
	card.category_label.add_theme_font_size_override("font_size", 19)
	card.price_label.add_theme_font_override("font", Art.FONT)
	card.price_label.add_theme_font_size_override("font_size", 27)
	card.stack_label.add_theme_font_override("font", Art.FONT)
	card.stack_label.add_theme_font_size_override("font_size", 18)
	card.centerpiece_panel.add_theme_stylebox_override("panel", Art.box("felt"))
	card.benefit_panel.add_theme_stylebox_override("panel", Art.box("benefit"))
	card.curse_panel.add_theme_stylebox_override("panel", Art.box("curse"))
	card.stack_panel.add_theme_stylebox_override("panel", Art.box("scorepaper"))
	for panel in [card.benefit_panel, card.curse_panel]:
		var heading: Label = panel.get_node("Margin/Row/Copy/Heading")
		_own_material_ink(heading)
		heading.add_theme_font_override("font", Art.FONT)
		heading.add_theme_font_size_override("font_size", 19)
		heading.add_theme_color_override("font_color", Color("c8ecc5") if panel == card.benefit_panel else Color("ffb8b0"))
		# Keep Atkinson for large multiline descriptions and equal disclosure.
		var description: Label = panel.get_node("Margin/Row/Copy/Description")
		_own_material_ink(description)
		description.add_theme_color_override("font_color", Color("fff1dc"))
	if not card.has_meta(&"sample_illustration"):
		card.set_meta(&"sample_illustration", true)
		card.centerpiece_icon.hide()
		var art := Art.picture("cards/" + art_name)
		art.name = "SampleIllustration"
		card.centerpiece_icon.get_parent().add_child(art)
		var buy := Button.new()
		buy.name = "SampleBuy"
		buy.custom_minimum_size.y = 45
		buy.set_meta(&"suppress_ui_click_audio", true)
		buy.pressed.connect(func():
			if not card.disabled: card.pressed.emit())
		card.card_layout.add_child(buy)
		_own_material_ink(buy)
		Art.button(buy, true)
		_replace_icon(card.category_icon, "props/bag")
		for node in card.find_children("CoinIcon", "", true, false): _replace_icon(node, "props/coin")
	var buy: Button = card.card_layout.get_node("SampleBuy")
	buy.disabled = card.disabled
	buy.text = "OWNED" if card.purchased else ("BUY  ·  " + card.price_label.text)
	if card.disabled and not card.purchased: buy.text = "UNAVAILABLE"

func _own_material_ink(control: Control) -> void:
	# UIAppearance's production remapper assumes flat panels. The sample owns
	# explicit ink for its raster materials, while other controls keep that adapter.
	# Disconnect its deferred watcher only on these concrete sample controls.
	var id := control.get_instance_id()
	var refresh: Callable = main.ui_appearance._queue_refresh.bind(id)
	if control.theme_changed.is_connected(refresh): control.theme_changed.disconnect(refresh)
	main.ui_appearance._forget(id)

func _replace_icon(icon: Control, asset: String) -> void:
	icon.self_modulate = Color(1, 1, 1, 0)
	var image := Art.picture(asset)
	icon.add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _purchase_feedback(kind: StringName) -> void:
	if kind != &"purchase" or main.run_state.tutorial_mode: return
	apply_shop()
	var card: UICard
	for offer in main.shop_manager.shop_card_buttons:
		if offer.card_id == last_purchased: card = offer
	if not card: return
	var reduce: bool = main.feedback_director.reduced_motion
	if not reduce:
		# Coins leave the wallet and commit to this card; the wallet already updated.
		var start: Vector2 = main.shop_manager.shop_tokens_label.global_position
		var finish: Vector2 = card.global_position + Vector2(card.size.x - 55, 45)
		for index in 3:
			var coin := Art.picture("props/coin")
			coin.size = Vector2(30, 30)
			coin.position = start + Vector2(index * 14, 0)
			fx_layer.add_child(coin)
			pending_effects.append(coin)
			var flight := coin.create_tween()
			flight.tween_interval(index * 0.045)
			flight.tween_property(coin, "position", finish, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			flight.tween_callback(coin.queue_free)
	_acknowledge(card.benefit_panel, "BENEFIT ADDED", "benefit", 0.15, reduce)
	_acknowledge(card.curse_panel, "CURSE ACCEPTED", "curse", 0.24, reduce)
	var art: Control = card.centerpiece_icon.get_parent().get_node_or_null("SampleIllustration")
	if not art: return
	var press := art.create_tween()
	art.modulate = Color(1.4, 1.3, 1.1)
	press.tween_property(art, "modulate", Color.WHITE, 0.18)
	pending_effects = pending_effects.filter(func(effect): return is_instance_valid(effect))

func _acknowledge(region: Control, words: String, material: String, delay: float, reduce: bool) -> void:
	var stamp := Label.new()
	stamp.text = words
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamp.add_theme_font_override("font", Art.FONT)
	stamp.add_theme_font_size_override("font_size", 21)
	stamp.add_theme_color_override("font_color", Color("fff1dc"))
	stamp.add_theme_stylebox_override("normal", Art.box(material))
	stamp.position = region.global_position + Vector2(10, -7)
	stamp.size = Vector2(region.size.x - 20, 32)
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.modulate.a = 0.0
	fx_layer.add_child(stamp)
	pending_effects.append(stamp)
	var tween := stamp.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(stamp, "modulate:a", 1.0, 0.01 if reduce else 0.06)
	tween.tween_interval(0.38)
	tween.tween_property(stamp, "modulate:a", 0.0, 0.12)
	tween.tween_callback(stamp.queue_free)
