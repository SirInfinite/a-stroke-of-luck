class_name CardEffectResolver
extends RefCounted


static func resolve(
	owned_cards: Array[CardDefinition],
	active_curses: Array[ActiveCardCurse]
) -> CardEffectSet:
	var resolved := CardEffectSet.new()
	for card in owned_cards:
		resolved.add_from(card.bonus_effects)
	for active_curse in active_curses:
		resolved.add_from(active_curse.card.curse_effects)
	resolved.clamp_for_release()
	return resolved
