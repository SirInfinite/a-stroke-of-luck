class_name DifficultyProfile
extends RefCounted

var id: StringName
var display_name: String
var shop_offer_count: int
var max_purchases: int
var curse_strength_multiplier: float
var generation_difficulty_factor: float
var curse_label: String


func _init(
	profile_id: StringName,
	profile_name: String,
	offer_count: int,
	purchase_limit: int,
	curse_multiplier: float,
	generation_factor: float,
	profile_curse_label: String
) -> void:
	id = profile_id
	display_name = profile_name
	shop_offer_count = clampi(offer_count, 4, 6)
	max_purchases = clampi(purchase_limit, 1, shop_offer_count)
	curse_strength_multiplier = clampf(curse_multiplier, 1.0, 1.75)
	generation_difficulty_factor = clampf(generation_factor, 0.85, 1.2)
	curse_label = profile_curse_label


func setup_summary() -> String:
	return "%d PICKS\n%d OFFERS\n%s" % [max_purchases, shop_offer_count, curse_label]


func generation_options() -> Dictionary:
	return {
		"difficulty_id": id,
		"difficulty_name": display_name,
		"generation_difficulty_factor": generation_difficulty_factor,
	}
