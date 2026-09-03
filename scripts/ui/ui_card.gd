class_name UICard
extends Button

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const UIIconScript := preload("res://scripts/ui/ui_icon.gd")

var card_id: StringName = &""
var accent := UIStyleScript.FOCUS
var purchased := false
var affordable := true

var card_layout: VBoxContainer
var category_icon: UIIcon
var category_label: Label
var name_label: Label
var centerpiece_panel: PanelContainer
var centerpiece_icon: UIIcon
var benefit_panel: PanelContainer
var benefit_description: Label
var curse_panel: PanelContainer
var curse_description: Label
var stack_panel: PanelContainer
var stack_label: Label
var price_label: Label
var purchased_badge: Label
var unavailable_badge: Label


func _ready() -> void:
	_ensure_built()


func configure_card(card: CardDefinition, is_affordable: bool, is_purchased: bool, stack_count := 0) -> UICard:
	_ensure_built()
	card_id = card.id
	accent = UIStyleScript.card_accent(card.id)
	category_icon.configure(UIStyleScript.card_icon(card.id), UIStyleScript.PAPER, accent)
	centerpiece_icon.configure(UIStyleScript.card_icon(card.id), UIStyleScript.PAPER, accent)
	category_label.text = UIStyleScript.card_category(card.id)
	name_label.text = card.name.to_upper()
	benefit_description.text = UIStyleScript.compact_sentence(card.bonus_description)
	curse_description.text = UIStyleScript.compact_sentence(card.curse_description)
	stack_label.text = "STACKS  •  x%d  •  ADDITIVE" % maxi(stack_count, 0)
	stack_panel.tooltip_text = card.stacking_description
	price_label.text = str(card.price)
	tooltip_text = "%s\nBenefit: %s\nCurse: %s\n%s" % [
		card.name,
		card.bonus_description,
		card.curse_description,
		card.stacking_description,
	]
	centerpiece_panel.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color(UIStyleScript.INK_DEEP, 0.72), Color(accent, 0.74), UIStyleScript.RADIUS_MEDIUM, 2, 4))
	_set_card_style()
	set_card_state(is_affordable, is_purchased)
	queue_redraw()
	return self


func set_card_state(is_affordable: bool, is_purchased: bool, purchase_limit_reached := false) -> void:
	affordable = is_affordable
	purchased = is_purchased
	purchased_badge.visible = purchased
	unavailable_badge.visible = not purchased and (not affordable or purchase_limit_reached)
	unavailable_badge.text = "SOLD OUT" if purchase_limit_reached and affordable else "NEED MORE COINS"
	var content_alpha := 1.0 if not disabled or purchased else 0.58
	card_layout.modulate = Color(1.0, 1.0, 1.0, content_alpha)
	if purchased:
		card_layout.modulate = Color(1.0, 1.0, 1.0, 0.45)
	queue_redraw()


func _ensure_built() -> void:
	if card_layout:
		return
	name = name if not name.is_empty() else "Card"
	custom_minimum_size = Vector2(242.0, 438.0)
	focus_mode = Control.FOCUS_ALL
	clip_contents = false
	text = ""
	theme_type_variation = &"CardButton"
	set_meta(&"suppress_ui_click_audio", true)

	var margin := MarginContainer.new()
	margin.name = "CardContentMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	card_layout = VBoxContainer.new()
	card_layout.name = "CardLayout"
	card_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_layout.add_theme_constant_override("separation", 8)
	card_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(card_layout)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 7)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_layout.add_child(header)

	category_icon = UIIconScript.new()
	category_icon.name = "CategoryIcon"
	category_icon.custom_minimum_size = Vector2(25.0, 25.0)
	header.add_child(category_icon)

	category_label = Label.new()
	category_label.name = "CategoryLabel"
	category_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyleScript.apply_ui(category_label, 12, UIStyleScript.PAPER_MUTED, true)
	header.add_child(category_label)

	var price_badge := PanelContainer.new()
	price_badge.name = "PriceBadge"
	price_badge.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color(UIStyleScript.GOLD, 0.96), UIStyleScript.INK_DEEP, 10, 2, 2))
	header.add_child(price_badge)
	var price_margin := MarginContainer.new()
	price_margin.add_theme_constant_override("margin_left", 7)
	price_margin.add_theme_constant_override("margin_top", 3)
	price_margin.add_theme_constant_override("margin_right", 9)
	price_margin.add_theme_constant_override("margin_bottom", 3)
	price_badge.add_child(price_margin)
	var price_row := HBoxContainer.new()
	price_row.add_theme_constant_override("separation", 4)
	price_margin.add_child(price_row)
	var coin_icon := UIIconScript.new()
	coin_icon.name = "CoinIcon"
	coin_icon.custom_minimum_size = Vector2(24.0, 24.0)
	coin_icon.configure(&"coin", UIStyleScript.INK_DEEP, UIStyleScript.GOLD_DARK)
	price_row.add_child(coin_icon)
	price_label = Label.new()
	price_label.name = "PriceLabel"
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyleScript.apply_ui(price_label, 20, UIStyleScript.INK_DEEP, true)
	price_row.add_child(price_label)

	name_label = Label.new()
	name_label.name = "CardName"
	name_label.custom_minimum_size.y = 49.0
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UIStyleScript.apply_display(name_label, 22, UIStyleScript.PAPER)
	card_layout.add_child(name_label)

	centerpiece_panel = PanelContainer.new()
	centerpiece_panel.name = "VisualCenterpiece"
	centerpiece_panel.custom_minimum_size.y = 130.0
	centerpiece_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centerpiece_panel.size_flags_stretch_ratio = 2.0
	centerpiece_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_layout.add_child(centerpiece_panel)
	var icon_center := CenterContainer.new()
	icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centerpiece_panel.add_child(icon_center)
	centerpiece_icon = UIIconScript.new()
	centerpiece_icon.name = "MechanicIcon"
	centerpiece_icon.custom_minimum_size = Vector2(112.0, 112.0)
	icon_center.add_child(centerpiece_icon)

	benefit_panel = _create_effect_panel(card_layout, "Benefit", &"bonus", UIStyleScript.BONUS, UIStyleScript.BONUS_DARK)
	benefit_description = benefit_panel.get_node("Margin/Row/Copy/Description") as Label
	curse_panel = _create_effect_panel(card_layout, "Curse", &"curse", UIStyleScript.CURSE, UIStyleScript.CURSE_DARK)
	curse_description = curse_panel.get_node("Margin/Row/Copy/Description") as Label

	stack_panel = PanelContainer.new()
	stack_panel.name = "StacksPanel"
	stack_panel.custom_minimum_size.y = 48.0
	stack_panel.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color(UIStyleScript.STACK_DARK, 0.94), Color(UIStyleScript.STACK, 0.9), 9, 2, 2))
	stack_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_layout.add_child(stack_panel)
	var stack_margin := MarginContainer.new()
	stack_margin.add_theme_constant_override("margin_left", 9)
	stack_margin.add_theme_constant_override("margin_top", 5)
	stack_margin.add_theme_constant_override("margin_right", 9)
	stack_margin.add_theme_constant_override("margin_bottom", 5)
	stack_panel.add_child(stack_margin)
	var stack_row := HBoxContainer.new()
	stack_row.add_theme_constant_override("separation", 8)
	stack_margin.add_child(stack_row)
	var stack_icon := UIIconScript.new()
	stack_icon.name = "StackIcon"
	stack_icon.custom_minimum_size = Vector2(30.0, 30.0)
	stack_icon.configure(&"stack", UIStyleScript.PAPER, UIStyleScript.STACK)
	stack_row.add_child(stack_icon)
	stack_label = Label.new()
	stack_label.name = "StackingRule"
	stack_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stack_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UIStyleScript.apply_ui(stack_label, 14, UIStyleScript.PAPER, true)
	stack_row.add_child(stack_label)

	purchased_badge = _create_state_badge("PurchasedBadge", "PURCHASED  ✓", UIStyleScript.GOLD, UIStyleScript.INK_DEEP)
	unavailable_badge = _create_state_badge("UnavailableBadge", "NEED MORE COINS", UIStyleScript.PAPER_MUTED, UIStyleScript.INK_DEEP)
	purchased_badge.visible = false
	unavailable_badge.visible = false

	_set_card_style()


func _create_effect_panel(parent: Control, label_text: String, icon_name: StringName, semantic_color: Color, background: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "%sPanel" % label_text
	panel.custom_minimum_size.y = 72.0
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.0
	panel.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color(background, 0.9), Color(semantic_color, 0.82), 10, 2, 2))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	var effect_icon := UIIconScript.new()
	effect_icon.name = "%sIcon" % label_text
	effect_icon.custom_minimum_size = Vector2(34.0, 34.0)
	effect_icon.configure(icon_name, UIStyleScript.PAPER, semantic_color)
	row.add_child(effect_icon)
	var copy := VBoxContainer.new()
	copy.name = "Copy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	row.add_child(copy)
	var heading := Label.new()
	heading.name = "Heading"
	heading.text = "%s  •  %s" % [label_text.to_upper(), "RUN" if label_text == "Benefit" else "3 HOLES"]
	UIStyleScript.apply_ui(heading, 12, semantic_color, true)
	copy.add_child(heading)
	var description := Label.new()
	description.name = "Description"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UIStyleScript.apply_ui(description, 14, UIStyleScript.PAPER)
	copy.add_child(description)
	return panel


func _create_state_badge(node_name: String, badge_text: String, background: Color, foreground: Color) -> Label:
	var badge := Label.new()
	badge.name = node_name
	badge.text = badge_text
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.set_anchors_preset(Control.PRESET_CENTER)
	badge.position = Vector2(-90.0, -26.0)
	badge.size = Vector2(180.0, 52.0)
	badge.add_theme_font_override("font", UIStyleScript.UI_BOLD_FONT)
	badge.add_theme_font_size_override("font_size", 16)
	badge.add_theme_color_override("font_color", foreground)
	badge.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	badge.add_theme_constant_override("shadow_offset_x", 0)
	badge.add_theme_constant_override("shadow_offset_y", 0)
	badge.add_theme_stylebox_override("normal", UIStyleScript.panel_style(background, foreground, 10, 3, 7, 6.0))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge)
	return badge


func _set_card_style() -> void:
	add_theme_stylebox_override("normal", UIStyleScript.panel_style(Color("1a2925"), Color(accent, 0.62), 18, 3, 8))
	add_theme_stylebox_override("hover", UIStyleScript.panel_style(Color("223a33"), accent, 18, 4, 14))
	add_theme_stylebox_override("pressed", UIStyleScript.panel_style(Color("13231f"), UIStyleScript.GOLD, 18, 4, 5))
	add_theme_stylebox_override("focus", UIStyleScript.panel_style(Color(0.0, 0.0, 0.0, 0.0), UIStyleScript.FOCUS, 18, 3, 0))
	add_theme_stylebox_override("disabled", UIStyleScript.panel_style(Color("17201e"), Color(accent, 0.24), 18, 2, 4))


func _draw() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var notch := PackedVector2Array([
		Vector2(size.x - 43.0, 0.0),
		Vector2(size.x, 0.0),
		Vector2(size.x, 43.0),
	])
	draw_colored_polygon(notch, Color(accent, 0.72 if not disabled else 0.24))
	for corner in [Vector2(11, 11), Vector2(size.x - 11, size.y - 11)]:
		draw_circle(corner, 3.0, Color(accent, 0.72))
