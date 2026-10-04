extends Node

const RELEASE_THEME := preload("res://assets/release_theme.tres")
const ShopManagerScript := preload("res://scripts/shop_manager.gd")

const SHOWCASE_SEED := 8844

var layout_index := 0
var shop_manager


func _ready() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "PresentationCanvas"
	add_child(canvas)
	shop_manager = ShopManagerScript.new()
	add_child(shop_manager)
	shop_manager.create_overlay(canvas)
	shop_manager.shop_overlay.theme = RELEASE_THEME
	_show_layout()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		layout_index = mini(layout_index + 1, 2)
		_show_layout()
		get_viewport().set_input_as_handled()


func _show_layout() -> void:
	var offer_counts := [4, 5, 6]
	var purchase_counts := [2, 3, 5]
	var curse_multipliers := [1.0, 1.25, 1.6]
	var difficulty_names := ["EASY", "NORMAL", "HARD"]
	var offer_count: int = offer_counts[layout_index]
	var no_forced_cards: Array[String] = []
	var no_explicit_cards: Array[CardDefinition] = []
	var no_owned_cards: Array[StringName] = []
	shop_manager.show_shop(
		3,
		99,
		18,
		SHOWCASE_SEED,
		no_forced_cards,
		"%s  •  %d OFFERS" % [difficulty_names[layout_index], offer_count],
		no_explicit_cards,
		0,
		no_owned_cards,
		offer_count,
		purchase_counts[layout_index],
		curse_multipliers[layout_index]
	)
