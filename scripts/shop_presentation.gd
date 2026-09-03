class_name ShopPresentation
extends Node

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

var shop: Node
var _last_state_signature := ""


func setup(shop_manager: Node) -> void:
	shop = shop_manager
	name = "ShopPresentation"
	shop.add_child(self)
	_style_shell()
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
		overlay.add_theme_stylebox_override("panel", UIStyleScript.panel_style(UIStyleScript.INK_DEEP, Color(UIStyleScript.GOLD, 0.62), 18, 3, 0))
	var title := shop.get("shop_title_label") as Label
	if title:
		UIStyleScript.apply_display(title, 38, UIStyleScript.PAPER)
	var tokens := shop.get("shop_tokens_label") as Label
	if tokens:
		UIStyleScript.apply_display(tokens, 27, UIStyleScript.GOLD)
	var destination := shop.get("shop_destination_label") as Label
	if destination:
		UIStyleScript.apply_ui(destination, 15, UIStyleScript.PAPER_MUTED, true)
	var status := shop.get("shop_status_label") as Label
	if status:
		UIStyleScript.apply_display(status, 22, UIStyleScript.PAPER)
	var curse_status := shop.get("shop_curse_status_label") as Label
	if curse_status:
		UIStyleScript.apply_ui(curse_status, 18, UIStyleScript.CURSE, true)


func _refresh_card_states() -> void:
	var buttons: Array = shop.get("shop_card_buttons")
	var purchased_indices: Array = shop.get("purchased_card_indices")
	var current_cards: Array = shop.get("current_shop_cards")
	var current_tokens := int(shop.get("tokens"))
	for index in range(buttons.size()):
		var card_view := buttons[index] as UICard
		if not card_view or index >= current_cards.size():
			continue
		var card := current_cards[index] as CardDefinition
		var purchased := purchased_indices.has(index)
		var limit_reached := card_view.disabled and current_tokens >= card.price and not purchased
		card_view.set_card_state(current_tokens >= card.price, purchased, limit_reached)
