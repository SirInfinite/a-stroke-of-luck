class_name UICard
extends Button

signal details_requested(card_id: StringName)

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const UIIconScript := preload("res://scripts/ui/ui_icon.gd")
const CardIllustrationScript := preload("res://scripts/ui/card_illustration.gd")

var card_id: StringName = &""
var accent := UIStyleScript.FOCUS
var purchased := false
var affordable := true

var card_layout: VBoxContainer
var category_icon: UIIcon
var rarity_icon: UIIcon
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
var buy_button: UIActionButton
var definition: CardDefinition
var _art_tween: Tween


func _ready() -> void:
	_ensure_built()


func configure_card(
	card: CardDefinition,
	is_affordable: bool,
	is_purchased: bool,
	stack_count := 0,
	curse_strength_multiplier := 1.0,
	shared_course_mode := false
) -> UICard:
	_ensure_built()
	card_id = card.id
	definition = card
	accent = CardRarityProfile.PROFILES[card.rarity].color
	category_icon.configure(UIStyleScript.card_icon(card.id), UIStyleScript.PAPER_INK, accent.darkened(0.25))
	centerpiece_icon.configure(UIStyleScript.card_icon(card.id), UIStyleScript.PAPER, UIStyleScript.card_accent(card.id))
	category_label.text = String(card.rarity).to_upper()
	rarity_icon.configure(StringName("rarity_" + String(card.rarity)), accent.darkened(0.2))
	category_label.tooltip_text = UIStyleScript.card_category(card.id)
	name_label.text = card.name
	benefit_description.text = UIStyleScript.compact_sentence(card.bonus_description)
	curse_description.text = UIStyleScript.compact_sentence(card.curse_description_for_multiplier(curse_strength_multiplier))
	curse_panel.get_node("Margin/Row/Copy/Heading").text = "CURSE  •  %d HOLES" % card.curse_duration_holes
	if shared_course_mode and MatchCourseRules.affects_course(card.curse_effects):
		curse_panel.get_node("Margin/Row/Copy/Heading").text = "COURSE CURSE  •  BOTH\n%d HOLES" % card.curse_duration_holes
	stack_label.text = "OWNED ×%d  •  STACKS ADD" % maxi(stack_count, 0)
	stack_panel.tooltip_text = card.stacking_description
	price_label.text = str(card.price)
	tooltip_text = "%s\nBenefit: %s\nCurse: %s\n%s" % [
		"%s • %s" % [card.name, String(card.rarity).to_upper()],
		card.bonus_description,
		card.curse_description_for_multiplier(curse_strength_multiplier),
		card.stacking_description,
	]
	if shared_course_mode and MatchCourseRules.affects_course(card.curse_effects):
		tooltip_text += "\nCOURSE CURSE: affects both golfers on the same shared hole for %d holes." % card.curse_duration_holes
	centerpiece_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_set_card_style()
	set_card_state(is_affordable, is_purchased)
	queue_redraw()
	return self


func set_compact_layout(_compact: bool) -> void:
	_ensure_built()
	# Shared fixed role sizes in all offer counts; six offers use one tall row.
	custom_minimum_size = Vector2(220.0, 676.0)
	centerpiece_panel.custom_minimum_size.y = 116.0
	centerpiece_icon.custom_minimum_size = Vector2(0.0, 0.0)
	# Reserve two complete display lines for every offer, so long names do not
	# push the purchase action outside the frame or stagger the object row.
	name_label.custom_minimum_size.y = 116.0
	benefit_panel.custom_minimum_size.y = 100.0
	curse_panel.custom_minimum_size.y = 100.0
	stack_panel.custom_minimum_size.y = 36.0
	card_layout.add_theme_constant_override("separation", 6)
	UIStyleScript.apply_display(name_label, 44, UIStyleScript.PAPER)
	var copy_size := 22
	UIStyleScript.apply_ui(benefit_description, copy_size, UIStyleScript.PAPER, true)
	UIStyleScript.apply_ui(curse_description, copy_size, UIStyleScript.PAPER, true)


func set_card_state(is_affordable: bool, is_purchased: bool, purchase_limit_reached := false) -> void:
	affordable = is_affordable
	purchased = is_purchased
	purchased_badge.visible = purchased
	unavailable_badge.visible = not purchased and (not affordable or purchase_limit_reached)
	unavailable_badge.text = "SOLD OUT" if purchase_limit_reached and affordable else "NEED MORE COINS"
	# Disclosure stays fully readable even when the offer cannot be bought.
	card_layout.modulate = Color.WHITE
	centerpiece_icon.modulate = Color(1.0, 1.0, 1.0, 0.62 if disabled else 1.0)
	buy_button.disabled = disabled
	buy_button.text = "BOUGHT" if purchased else "BUY!"
	if disabled and not purchased:
		buy_button.text = "SOLD" if affordable else "LOCKED"
	queue_redraw()


func _ensure_built() -> void:
	if card_layout:
		return
	name = name if not name.is_empty() else "Card"
	custom_minimum_size = Vector2(220.0, 676.0)
	focus_mode = Control.FOCUS_ALL
	clip_contents = false
	text = ""
	theme_type_variation = &"CardButton"
	set_meta(&"suppress_ui_click_audio", true)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_entered.connect(_inspect.bind(true))
	mouse_exited.connect(_inspect.bind(false))
	focus_entered.connect(_inspect.bind(true))
	focus_exited.connect(_inspect.bind(false))

	var margin := MarginContainer.new()
	margin.name = "CardContentMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 12)
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
	category_icon.visible = false
	header.add_child(category_icon)

	rarity_icon = UIIconScript.new()
	rarity_icon.name = "RarityIcon"
	rarity_icon.custom_minimum_size = Vector2(18.0, 18.0)
	header.add_child(rarity_icon)

	category_label = Label.new()
	category_label.name = "CategoryLabel"
	category_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyleScript.apply_ui(category_label, 17, UIStyleScript.PAPER_MUTED, true)
	header.add_child(category_label)

	var price_badge := PanelContainer.new()
	price_badge.name = "PriceBadge"
	price_badge.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	price_badge.set_meta(&"keep_ui_ink", true)
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
	coin_icon.configure(&"coin", UIStyleScript.GOLD, UIStyleScript.GOLD)
	price_row.add_child(coin_icon)
	price_label = Label.new()
	price_label.name = "PriceLabel"
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyleScript.apply_display(price_label, 36, UIStyleScript.GOLD)
	price_row.add_child(price_label)

	name_label = Label.new()
	name_label.name = "CardName"
	name_label.custom_minimum_size.y = 49.0
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	UIStyleScript.apply_display(name_label, 34, UIStyleScript.PAPER)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_layout.add_child(name_label)

	centerpiece_panel = PanelContainer.new()
	centerpiece_panel.name = "VisualCenterpiece"
	centerpiece_panel.custom_minimum_size.y = 130.0
	centerpiece_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centerpiece_panel.size_flags_stretch_ratio = 2.0
	centerpiece_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_layout.add_child(centerpiece_panel)
	var icon_center := MarginContainer.new()
	icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centerpiece_panel.add_child(icon_center)
	centerpiece_icon = CardIllustrationScript.new()
	centerpiece_icon.name = "MechanicIcon"
	centerpiece_icon.custom_minimum_size = Vector2(0.0, 0.0)
	icon_center.add_child(centerpiece_icon)

	benefit_panel = _create_effect_panel(card_layout, "Benefit", &"bonus", UIStyleScript.BONUS, UIStyleScript.BONUS_DARK)
	benefit_description = benefit_panel.get_node("Margin/Row/Copy/Description") as Label
	curse_panel = _create_effect_panel(card_layout, "Curse", &"curse", UIStyleScript.CURSE, UIStyleScript.CURSE_DARK)
	curse_description = curse_panel.get_node("Margin/Row/Copy/Description") as Label

	stack_panel = PanelContainer.new()
	stack_panel.name = "StacksPanel"
	stack_panel.custom_minimum_size.y = 48.0
	stack_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
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
	stack_icon.custom_minimum_size = Vector2(24.0, 24.0)
	stack_icon.configure(&"stack", UIStyleScript.PAPER_MUTED, UIStyleScript.PAPER_MUTED)
	stack_icon.visible = false
	stack_row.add_child(stack_icon)
	stack_label = Label.new()
	stack_label.name = "StackingRule"
	stack_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stack_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	UIStyleScript.apply_ui(stack_label, 17, UIStyleScript.PAPER_MUTED, true)
	stack_row.add_child(stack_label)
	buy_button = UIActionButton.new()
	buy_button.name = "BuyButton"
	buy_button.custom_minimum_size.y = 100
	buy_button.display_size = 78
	buy_button.frameless = true
	buy_button.show_icon = false
	buy_button.set_meta(&"suppress_ui_click_audio", true)
	card_layout.add_child(buy_button)
	buy_button.configure("BUY", &"coin", &"primary")
	buy_button.pressed.connect(func():
		if not disabled: pressed.emit())
	buy_button.mouse_entered.connect(_inspect.bind(true))
	buy_button.focus_entered.connect(_inspect.bind(true))
	buy_button.mouse_exited.connect(_inspect.bind(false))
	buy_button.focus_exited.connect(_inspect.bind(false))

	purchased_badge = _create_state_badge("PurchasedBadge", "PURCHASED", UIStyleScript.GOLD, UIStyleScript.INK_DEEP)
	unavailable_badge = _create_state_badge("UnavailableBadge", "NEED MORE COINS", UIStyleScript.PAPER_MUTED, UIStyleScript.INK_DEEP)
	purchased_badge.visible = false
	unavailable_badge.visible = false

	_set_card_style()


func _create_effect_panel(parent: Control, label_text: String, icon_name: StringName, semantic_color: Color, _background: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "%sPanel" % label_text
	panel.custom_minimum_size.y = 82.0
	panel.size_flags_vertical = Control.SIZE_FILL
	panel.size_flags_stretch_ratio = 1.0
	panel.add_theme_stylebox_override("panel", UIStyleScript.disclosure_band(semantic_color))
	panel.set_meta(&"keep_ui_ink", true)
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
	effect_icon.visible = false
	row.add_child(effect_icon)
	var copy := VBoxContainer.new()
	copy.name = "Copy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 0)
	row.add_child(copy)
	var heading := Label.new()
	heading.name = "Heading"
	heading.text = "%s  •  %s" % [label_text.to_upper(), "RUN" if label_text == "Benefit" else "3 HOLES"]
	UIStyleScript.apply_ui(heading, 17, semantic_color, true)
	copy.add_child(heading)
	var description := Label.new()
	description.name = "Description"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyleScript.apply_ui(description, 22, UIStyleScript.PAPER, true)
	copy.add_child(description)
	return panel


func _create_state_badge(node_name: String, badge_text: String, background: Color, foreground: Color) -> Label:
	var badge := Label.new()
	badge.name = node_name
	badge.text = badge_text
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.set_anchors_preset(Control.PRESET_CENTER)
	badge.offset_left = -104.0
	badge.offset_right = 104.0
	badge.offset_top = -74.0
	badge.offset_bottom = -30.0
	badge.add_theme_font_override("font", UIStyleScript.UI_BOLD_FONT)
	badge.add_theme_font_size_override("font_size", UIStyleScript.text_size(19))
	badge.add_theme_color_override("font_color", foreground)
	badge.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	badge.add_theme_constant_override("shadow_offset_x", 0)
	badge.add_theme_constant_override("shadow_offset_y", 0)
	badge.add_theme_stylebox_override("normal", UIStyleScript.panel_style(background, foreground, 10, 3, 7, 6.0))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_meta(&"keep_ui_ink", true)
	add_child(badge)
	return badge


func _set_card_style() -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, UIStyleScript.pixel_frame("card" if state == "normal" else state, 8))


func _draw() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	draw_rect(Rect2(10, 3, maxf(size.x - 20, 0), 3), accent)


func _inspect(active: bool) -> void:
	if active: details_requested.emit(card_id)
	if _art_tween: _art_tween.kill()
	if not UIStyleScript.motion_enabled(self):
		centerpiece_icon.scale = Vector2.ONE
		return
	centerpiece_icon.pivot_offset = centerpiece_icon.size * 0.5
	_art_tween = create_tween()
	_art_tween.tween_property(centerpiece_icon,"scale",Vector2.ONE * (1.04 if active else 1.0),0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
