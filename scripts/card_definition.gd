class_name CardDefinition
extends RefCounted

var id: StringName
var name: String
var price: int
var bonus_description: String
var curse_description: String
var stacking_description: String
var bonus_effects: CardEffectSet
var curse_effects: CardEffectSet
var curse_duration_holes: int


func _init(
	card_id: StringName,
	card_name: String,
	card_price: int,
	card_bonus_description: String,
	card_curse_description: String,
	card_stacking_description: String,
	card_bonus_effects: CardEffectSet,
	card_curse_effects: CardEffectSet,
	card_curse_duration_holes := 3
) -> void:
	id = card_id
	name = card_name
	price = card_price
	bonus_description = card_bonus_description
	curse_description = card_curse_description
	stacking_description = card_stacking_description
	bonus_effects = card_bonus_effects
	curse_effects = card_curse_effects
	curse_duration_holes = card_curse_duration_holes


func is_valid() -> bool:
	return (
		not id.is_empty()
		and not name.is_empty()
		and price > 0
		and not bonus_description.is_empty()
		and not curse_description.is_empty()
		and not stacking_description.is_empty()
		and bonus_effects != null
		and not bonus_effects.is_empty()
		and curse_effects != null
		and not curse_effects.is_empty()
		and curse_duration_holes > 0
	)
