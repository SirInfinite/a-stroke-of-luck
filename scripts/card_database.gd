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
		"Power control is 12% more precise for the run.",
		"Shot power is 10% lower for the next 3 holes.",
		"Copies add both sides; control caps at +150% and power stays at least 35%.",
		CardEffectSetScript.Kind.POWER_CONTROL,
		0.12,
		CardEffectSetScript.Kind.SHOT_POWER,
		-0.1
	))
	cards.append(_card(
		&"sand_cleats",
		"Sand Cleats",
		2,
		"Sand slows 35% less for the run.",
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
		"Sand slows 15% more for the next 3 holes.",
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
		"The cup is 12% smaller for the next 3 holes.",
		"Copies add both sides; reward bonus caps at +8 coins and cup size stays at least 55%.",
		CardEffectSetScript.Kind.COIN_REWARD,
		1.0,
		CardEffectSetScript.Kind.CUP_RADIUS_SCALE,
		-0.12
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


static func get_tutorial_cards() -> Array[CardDefinition]:
	return [
		_card(
			&"tutorial_training_driver",
			"Training Driver",
			1,
			"+15% shot power for the run.",
			"Power control is 10% less precise for the next 3 holes.",
			"Tutorial card; copies add both sides within release caps.",
			CardEffectSetScript.Kind.SHOT_POWER,
			0.15,
			CardEffectSetScript.Kind.POWER_CONTROL,
			-0.1
		),
		_card(
			&"tutorial_sand_shoes",
			"Practice Sand Shoes",
			1,
			"Sand slows 25% less for the run.",
			"Shot power is 10% lower for the next 3 holes.",
			"Tutorial card; copies add both sides within release caps.",
			CardEffectSetScript.Kind.TERRAIN_MITIGATION,
			0.25,
			CardEffectSetScript.Kind.SHOT_POWER,
			-0.1
		),
		_card(
			&"tutorial_pocket_change",
			"Pocket Change",
			1,
			"Earn +1 coin after every hole for the run.",
			"The cup is 10% smaller for the next 3 holes.",
			"Tutorial card; copies add both sides within release caps.",
			CardEffectSetScript.Kind.COIN_REWARD,
			1.0,
			CardEffectSetScript.Kind.CUP_RADIUS_SCALE,
			-0.1
		),
		_card(
			&"tutorial_steady_grip",
			"Steady Grip",
			1,
			"Power control is 15% more precise for the run.",
			"Normal grass stops the ball 10% sooner for the next 3 holes.",
			"Tutorial card; copies add both sides within release caps.",
			CardEffectSetScript.Kind.POWER_CONTROL,
			0.15,
			CardEffectSetScript.Kind.ROLL_DAMPING,
			0.1
		),
	]


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
