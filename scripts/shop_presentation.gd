class_name ShopPresentation
extends Node
## Native shop composition and feedback. ShopManager owns every transaction.
const Style := preload("res://scripts/ui/ui_style.gd")
const Illustration := preload("res://scripts/ui/card_illustration.gd")
var shop: ShopManager
var selected_id: StringName
var detail_side: PanelContainer
var detail_strip: PanelContainer
var _details: Array[Dictionary] = []
var _feedback_tween: Tween

func setup(shop_manager: Node) -> void:
	shop = shop_manager
	name = "ShopPresentation"
	shop.add_child(self)
	shop.presentation = self
	shop.hover_scale = 1.0
	shop.purchase_pulse_scale = 1.0
	shop.coin_pulse_scale = 1.025
	shop.curse_flash_intensity = 0.0
	_style_shell()
	var layout: VBoxContainer = shop.shop_overlay.get_node("SafeArea/ShopLayout")
	var body: HBoxContainer = layout.get_node("ShopBody")
	detail_side = _make_details(false)
	detail_side.custom_minimum_size.x = 320
	body.add_child(detail_side)
	body.move_child(detail_side, 0)
	detail_strip = _make_details(true)
	layout.add_child(detail_strip)
	layout.move_child(detail_strip, 2)
	for card: UICard in shop.shop_card_buttons:
		card.details_requested.connect(select_item)
	shop.card_bought.connect(func(card: CardDefinition): selected_id = card.id)
	shop.feedback_requested.connect(_feedback)
	shop.shop_overlay.visibility_changed.connect(_visibility_changed)
	refresh_layout()

func _style_shell() -> void:
	shop.shop_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shop.shop_overlay.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	Style.apply_display(shop.shop_title_label,47)
	Style.apply_display(shop.shop_tokens_label,42,Style.GOLD)
	Style.apply_ui(shop.shop_purchase_label,18)
	Style.apply_ui(shop.shop_destination_label,19)
	Style.apply_display(shop.shop_status_label,25)
	Style.apply_ui(shop.shop_curse_status_label,18,Style.CURSE)
	# These labels sit directly over scenery; surrounding card stock changes
	# with appearance, while their contrasting ink stays readable in both modes.
	shop.shop_title_label.get_parent().set_meta(&"keep_ui_ink", true)
	for label: Label in [shop.shop_destination_label, shop.shop_status_label, shop.shop_curse_status_label]:
		label.set_meta(&"keep_ui_ink", true)
	var wallet: Control = shop.shop_tokens_label.get_parent().get_parent().get_parent().get_parent()
	wallet.add_theme_stylebox_override("panel",Style.pixel_frame("panel",4))
	var title_stage: Control = shop.shop_title_label.get_parent().get_parent().get_child(0)
	title_stage.visible = false
	shop.continue_button.display_size = 34

func refresh_layout() -> void:
	if not detail_side: return
	detail_side.visible = shop.current_offer_count <= 4
	detail_strip.visible = shop.current_offer_count > 4
	var backdrop: UIBackdrop = shop.shop_overlay.get_node("ShopBackdrop")
	if shop._run_state:
		var profiles := BiomeDatabase.get_profiles()
		backdrop.biome_id = profiles[clampi(shop._run_state.biome_index,0,profiles.size()-1)].id

func refresh_offers() -> void:
	if not _definition(selected_id) and not shop.current_shop_cards.is_empty():
		selected_id = shop.current_shop_cards[0].id
	select_item(selected_id)

func _make_details(horizontal: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "SelectedItemStrip" if horizontal else "SelectedItemDetails"
	panel.add_theme_stylebox_override("panel",Style.pixel_frame("panel",16))
	panel.set_meta(&"keep_ui_ink",true)
	var row: BoxContainer = HBoxContainer.new() if horizontal else VBoxContainer.new()
	row.add_theme_constant_override("separation",14 if horizontal else 16)
	panel.add_child(row)
	var art := Illustration.new()
	art.custom_minimum_size = Vector2(100,100) if horizontal else Vector2(0,164)
	art.maximum_extent = 164
	row.add_child(art)
	var title_group := VBoxContainer.new()
	title_group.custom_minimum_size.x = 250 if horizontal else 0
	title_group.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(title_group)
	var eyebrow := _label(title_group,"SELECTED EQUIPMENT",18,Style.PAPER_MUTED)
	eyebrow.name = "SelectedHeading"
	var title := _label(title_group,"",30 if horizontal else 38)
	Style.apply_display(title,30 if horizontal else 38)
	var benefit := _label(row,"",22,Style.BONUS)
	var curse := _label(row,"",22,Style.CURSE)
	var stacking := _label(row,"",19,Style.PAPER_MUTED)
	if not horizontal:
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		_label(row,"HOVER OR FOCUS\nTO INSPECT GEAR",18,Style.PAPER_MUTED)
	_details.append({"art":art,"title":title,"benefit":benefit,"curse":curse,"stacking":stacking})
	return panel

func _label(parent: Node, copy: String, text_size: int, ink := Style.PAPER) -> Label:
	var label := Label.new()
	label.text = copy
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	Style.apply_ui(label,text_size,ink,true)
	return label

func _definition(id: StringName) -> CardDefinition:
	for card: CardDefinition in shop.current_shop_cards:
		if card.id == id: return card
	return null

func select_item(id: StringName) -> void:
	var card := _definition(id)
	if not card: return
	selected_id = id
	for detail in _details:
		detail.art.configure(Style.card_icon(card.id),Style.PAPER,Style.card_accent(card.id))
		detail.title.text = card.name
		detail.benefit.text = "BENEFIT / RUN\n" + card.bonus_description
		var shared: bool = shop.shared_course_mode and MatchCourseRules.affects_course(card.curse_effects)
		detail.curse.text = ("COURSE CURSE / BOTH / %d HOLES\n" if shared else "CURSE / %d HOLES\n") % card.curse_duration_holes + card.curse_description_for_multiplier(shop.current_curse_strength_multiplier)
		detail.stacking.text = card.stacking_description

func _feedback(kind: StringName) -> void:
	if kind != &"purchase": return
	select_item(selected_id)
	if _feedback_tween: _feedback_tween.kill()
	shop.shop_curse_status_label.text = "BENEFIT ADDED / CURSE ACCEPTED"
	if not Style.motion_enabled(shop.shop_overlay): return
	shop.shop_curse_status_label.modulate.a = 0.3
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(shop.shop_curse_status_label,"modulate:a",1.0,0.14)

func _visibility_changed() -> void:
	if shop.shop_overlay.visible: return
	if _feedback_tween: _feedback_tween.kill()
	shop.shop_curse_status_label.modulate = Color.WHITE
