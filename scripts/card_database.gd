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
		"+25% shot power.",
		"Power meter is 15% less precise.",
		"Copies stack. Power caps at +150%; control stays above 35%.",
		CardEffectSetScript.Kind.SHOT_POWER,
		0.25,
		CardEffectSetScript.Kind.POWER_CONTROL,
		-0.15
	))
	cards.append(_card(
		&"rangefinder_lens",
		"Rangefinder Lens",
		2,
		"Power meter is 12% more precise.",
		"-10% shot power.",
		"Copies stack. Control caps at +150%; power stays above 35%.",
		CardEffectSetScript.Kind.POWER_CONTROL,
		0.12,
		CardEffectSetScript.Kind.SHOT_POWER,
		-0.1
	))
	cards.append(_card(
		&"sand_cleats",
		"Sand Cleats",
		2,
		"Sand slows 35% less.",
		"Direction zones push 25% harder.",
		"Copies stack. Sand relief caps at 75%; push caps at +150%.",
		CardEffectSetScript.Kind.TERRAIN_MITIGATION,
		0.35,
		CardEffectSetScript.Kind.DIRECTION_MITIGATION,
		-0.25
	))
	cards.append(_card(
		&"heavy_core",
		"Heavy Core",
		2,
		"Ball rolls 25% farther.",
		"Sand slows 15% more.",
		"Copies stack. Roll stays above 35%; sand penalty caps at +50%.",
		CardEffectSetScript.Kind.ROLL_DAMPING,
		-0.2,
		CardEffectSetScript.Kind.TERRAIN_MITIGATION,
		-0.15
	))
	cards.append(_card(
		&"lucky_putter",
		"Lucky Putter",
		3,
		"Birdie or better: +2 coins.",
		"Cup is 25% smaller.",
		"Copies stack. Bonus caps at +8 coins; cup stays above 55%.",
		CardEffectSetScript.Kind.BIRDIE_REWARD,
		2.0,
		CardEffectSetScript.Kind.CUP_RADIUS_SCALE,
		-0.25
	))
	cards.append(_card(
		&"power_club",
		"Power Club",
		2,
		"+20% shot power.",
		"+1 direction zone each hole.",
		"Copies stack. Power caps at +150%; extra zones cap at 4.",
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
		"+1 coin after every hole.",
		"Cup is 12% smaller.",
		"Copies stack. Bonus caps at +8 coins; cup stays above 55%.",
		CardEffectSetScript.Kind.COIN_REWARD,
		1.0,
		CardEffectSetScript.Kind.CUP_RADIUS_SCALE,
		-0.12
	))
	cards.append(_card(
		&"gust_guard",
		"Gust Guard",
		2,
		"Direction zones push 50% less.",
		"+1 direction zone each hole.",
		"Copies stack. Push stays above 25%; extra zones cap at 4.",
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
			"+15% shot power.",
			"Power meter is 10% less precise.",
			"Buy another copy to add its benefit and curse.",
			CardEffectSetScript.Kind.SHOT_POWER,
			0.15,
			CardEffectSetScript.Kind.POWER_CONTROL,
			-0.1
		),
		_card(
			&"tutorial_sand_shoes",
			"Practice Sand Shoes",
			1,
			"Sand slows 25% less.",
			"-10% shot power.",
			"Buy another copy to add its benefit and curse.",
			CardEffectSetScript.Kind.TERRAIN_MITIGATION,
			0.25,
			CardEffectSetScript.Kind.SHOT_POWER,
			-0.1
		),
		_card(
			&"tutorial_pocket_change",
			"Pocket Change",
			1,
			"+1 coin after every hole.",
			"Cup is 10% smaller.",
			"Buy another copy to add its benefit and curse.",
			CardEffectSetScript.Kind.COIN_REWARD,
			1.0,
			CardEffectSetScript.Kind.CUP_RADIUS_SCALE,
			-0.1
		),
		_card(
			&"tutorial_steady_grip",
			"Steady Grip",
			1,
			"Power meter is 15% more precise.",
			"Ball stops 10% sooner.",
			"Buy another copy to add its benefit and curse.",
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
