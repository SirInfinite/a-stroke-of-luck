class_name ShopPresentation
extends Node

const OFF_WHITE := Color("f4f0e6")
const CHARCOAL := Color("252a2c")
const GOLD := Color("e2b84b")
const BONUS := Color("43b96b")
const CURSE := Color("d9534f")

var shop: Node
var _last_state_signature := ""


func setup(shop_manager: Node) -> void:
	shop = shop_manager
	name = "ShopPresentation"
	shop.add_child(self)
	_style_shell()
	_style_cards()
	set_process(true)


func _process(_delta: float) -> void:
	if not shop or not is_instance_valid(shop):
		set_process(false)
		return
	var signature := "%s|%s|%s" % [
		str(shop.get("tokens")),
		str(shop.get("purchases_this_visit")),
		str(shop.get("purchased_card_indices")),
	]
	if signature == _last_state_signature:
		return
	_last_state_signature = signature
	_refresh_card_states()


func _style_shell() -> void:
	var overlay := shop.get("shop_overlay") as Control
	if overlay:
		overlay.add_theme_stylebox_override("panel", _style(Color("111c1a", 0.98), Color(GOLD, 0.5), 12, 3))
	var title := shop.get("shop_title_label") as Label
	if title:
		title.text = "THE CLUBHOUSE SHOP"
		title.add_theme_color_override("font_color", GOLD)
		title.add_theme_font_size_override("font_size", 38)
	var tokens := shop.get("shop_tokens_label") as Label
	if tokens:
		tokens.add_theme_color_override("font_color", GOLD)
	var destination := shop.get("shop_destination_label") as Label
	if destination:
		destination.add_theme_color_override("font_color", Color(OFF_WHITE, 0.78))
	var status := shop.get("shop_status_label") as Label
	if status:
		status.add_theme_color_override("font_color", Color(OFF_WHITE, 0.86))
	var continue_button := shop.get("continue_button") as Button
	if continue_button:
		continue_button.add_theme_stylebox_override("normal", _style(Color("1f332b"), Color(GOLD, 0.54), 8, 2))
		continue_button.add_theme_stylebox_override("hover", _style(Color("294537"), GOLD, 8, 2))


func _style_cards() -> void:
	var buttons: Array = shop.get("shop_card_buttons")
	for index in range(buttons.size()):
		var button := buttons[index] as Button
		if not button:
			continue
		button.add_theme_color_override("font_color", OFF_WHITE)
		button.add_theme_color_override("font_hover_color", OFF_WHITE)
		button.add_theme_color_override("font_pressed_color", OFF_WHITE)
		button.add_theme_color_override("font_disabled_color", Color(OFF_WHITE, 0.56))
		button.add_theme_stylebox_override("normal", _card_style(index, false, false))
		button.add_theme_stylebox_override("hover", _card_style(index, true, false))
		button.add_theme_stylebox_override("pressed", _card_style(index, true, false))
		button.add_theme_stylebox_override("disabled", _card_style(index, false, true))
		_add_semantic_strips(button)


func _refresh_card_states() -> void:
	var buttons: Array = shop.get("shop_card_buttons")
	var purchased: Array = shop.get("purchased_card_indices")
	for index in range(buttons.size()):
		var button := buttons[index] as Button
		if not button:
			continue
		button.modulate = Color.WHITE if not button.disabled else Color(0.8, 0.84, 0.82, 0.84)
		var badge := button.get_node_or_null("Presentation/PurchasedBadge") as Label
		if badge:
			badge.visible = purchased.has(index)


func _add_semantic_strips(button: Button) -> void:
	var presentation := Control.new()
	presentation.name = "Presentation"
	presentation.set_anchors_preset(Control.PRESET_FULL_RECT)
	presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(presentation)

	var benefit_strip := ColorRect.new()
	benefit_strip.name = "BenefitStrip"
	benefit_strip.color = Color(BONUS, 0.88)
	benefit_strip.position = Vector2(7.0, 88.0)
	benefit_strip.size = Vector2(5.0, 94.0)
	benefit_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(benefit_strip)

	var curse_strip := ColorRect.new()
	curse_strip.name = "CurseStrip"
	curse_strip.color = Color(CURSE, 0.92)
	curse_strip.position = Vector2(7.0, 194.0)
	curse_strip.size = Vector2(5.0, 104.0)
	curse_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(curse_strip)

	var badge := Label.new()
	badge.name = "PurchasedBadge"
	badge.text = "PURCHASED"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.position = Vector2(24.0, 342.0)
	badge.size = Vector2(172.0, 30.0)
	badge.add_theme_font_size_override("font_size", 15)
	badge.add_theme_color_override("font_color", CHARCOAL)
	badge.add_theme_stylebox_override("normal", _style(GOLD, GOLD, 6, 0))
	badge.visible = false
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(badge)


func _card_style(index: int, hovered: bool, disabled: bool) -> StyleBoxFlat:
	var accents := [Color("79b88b"), Color("6f8fb9"), Color("b7865b"), Color("a16f9b")]
	var accent: Color = accents[index % accents.size()]
	var background := Color("18231f") if not hovered else Color("24362f")
	if disabled:
		background = Color("202522")
		accent = Color(accent, 0.35)
	var style := _style(background, accent, 10, 2)
	style.shadow_color = Color(0.02, 0.025, 0.03, 0.48)
	style.shadow_size = 8 if hovered else 5
	return style


func _style(background: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14.0
	style.content_margin_top = 14.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 14.0
	return style
