class_name CardDatabase
extends RefCounted

const CardDefinitionScript := preload("res://scripts/card_definition.gd")
const CardEffectSetScript := preload("res://scripts/card_effect_set.gd")

static func get_cards() -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []
	cards.append(_card(
		&"overdrive_driver",
		"Overdrive Driver",
		3,
		"+25% shot power for the run.",
		"Power control is 15% less precise for the next 3 holes.",
		"Copies add both sides; power caps at 250% and control stays at least 35%.",
		CardEffectSetScript.Kind.SHOT_POWER,
		0.25,
		CardEffectSetScript.Kind.POWER_CONTROL,
		-0.15
	))
	cards.append(_card(
		&"rangefinder_lens",
		"Rangefinder Lens",
		2,
		"+4 trajectory dots for the run.",
		"Shot power is 10% lower for the next 3 holes.",
		"Copies add both sides; preview bonus caps at +24 dots and power stays at least 35%.",
		CardEffectSetScript.Kind.TRAJECTORY_DOTS,
		4.0,
		CardEffectSetScript.Kind.SHOT_POWER,
		-0.1
	))
	cards.append(_card(
		&"sand_cleats",
		"Sand Cleats",
		2,
		"Sand and rough slow 35% less for the run.",
		"Direction zones push 25% harder for the next 3 holes.",
		"Copies add both sides; terrain reduction caps at 75% and push at 150%.",
		CardEffectSetScript.Kind.TERRAIN_MITIGATION,
		0.35,
		CardEffectSetScript.Kind.DIRECTION_MITIGATION,
		-0.25
	))
	cards.append(_card(
		&"heavy_core",
		"Heavy Core",
		2,
		"Normal roll damping is 20% lower for the run.",
		"Sand and rough slow 15% more for the next 3 holes.",
		"Copies add both sides; damping stays at least 35% and terrain severity at most 150%.",
		CardEffectSetScript.Kind.ROLL_DAMPING,
		-0.2,
		CardEffectSetScript.Kind.TERRAIN_MITIGATION,
		-0.15
	))
	cards.append(_card(
		&"lucky_putter",
		"Lucky Putter",
		3,
		"Birdie or better earns +2 coins for the run.",
		"The cup is 25% smaller for the next 3 holes.",
		"Copies add both sides; birdie bonus caps at +8 coins and cup size stays at least 55%.",
		CardEffectSetScript.Kind.BIRDIE_REWARD,
		2.0,
		CardEffectSetScript.Kind.CUP_RADIUS_SCALE,
		-0.25
	))
	cards.append(_card(
		&"power_club",
		"Power Club",
		2,
		"+20% shot power for the run.",
		"One extra direction zone is generated on each of the next 3 holes.",
		"Copies add both sides; power caps at 250% and added hazards at 4 per hole.",
		CardEffectSetScript.Kind.SHOT_POWER,
		0.2,
		CardEffectSetScript.Kind.HAZARD_COUNT,
		1.0,
		&"direction"
	))
	cards.append(_card(
		&"coin_magnet",
		"Coin Magnet",
		1,
		"Earn +1 coin after every hole for the run.",
		"The trajectory preview loses 2 dots for the next 3 holes.",
		"Copies add both sides; reward bonus caps at +8 coins and preview keeps at least 2 dots.",
		CardEffectSetScript.Kind.COIN_REWARD,
		1.0,
		CardEffectSetScript.Kind.TRAJECTORY_DOTS,
		-2.0
	))
	cards.append(_card(
		&"gust_guard",
		"Gust Guard",
		2,
		"Direction-zone push is reduced by 50% for the run.",
		"One extra direction zone is generated on each of the next 3 holes.",
		"Copies add both sides; push stays at least 25% and added hazards cap at 4 per hole.",
		CardEffectSetScript.Kind.DIRECTION_MITIGATION,
		0.5,
		CardEffectSetScript.Kind.HAZARD_COUNT,
		1.0,
		&"direction"
	))
	return cards


static func _card(
	card_id: StringName,
	card_name: String,
	price: int,
	bonus_description: String,
	curse_description: String,
	stacking_description: String,
	bonus_kind: int,
	bonus_amount: float,
	curse_kind: int,
	curse_amount: float,
	curse_detail: StringName = &""
) -> CardDefinition:
	return CardDefinitionScript.new(
		card_id,
		card_name,
		price,
		bonus_description,
		curse_description,
		stacking_description,
		CardEffectSetScript.single(bonus_kind, bonus_amount),
		CardEffectSetScript.single(curse_kind, curse_amount, curse_detail)
	)
