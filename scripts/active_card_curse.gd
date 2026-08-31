class_name ActiveCardCurse
extends RefCounted

var card: CardDefinition
var remaining_holes: int


func _init(card_definition: CardDefinition) -> void:
	card = card_definition
	remaining_holes = card_definition.curse_duration_holes


func advance_hole() -> bool:
	remaining_holes = maxi(remaining_holes - 1, 0)
	return remaining_holes == 0


func summary() -> String:
	return "%s (%d hole%s)" % [card.name, remaining_holes, "" if remaining_holes == 1 else "s"]
