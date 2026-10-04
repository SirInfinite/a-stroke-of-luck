class_name TutorialDatabase
extends RefCounted

const CardDatabaseScript := preload("res://scripts/card_database.gd")
const WALL_THICKNESS := 30.0
const TUTORIAL_MAP := [
	"..........",
	"..........",
	"..........",
	"..........",
	"..........",
	"..........",
]


static func get_levels() -> Array[Dictionary]:
	var levels: Array[Dictionary] = [
		_base_level(
			&"aim_power_trajectory",
			2,
			[],
			[],
			[&"aim_started", &"power_adjusted", &"shot_taken"],
			[
				{"event": &"aim_started", "text": "Aim with the mouse or arrow keys.", "target": "ball"},
				{"event": &"power_adjusted", "text": "Drag farther to add power.", "target": "ball"},
				{"event": &"shot_taken", "text": "The arrow marks a straight-line finish. Release to shoot.", "target": "ball"},
				{"event": &"hole_completed", "text": "Strokes and time track your round. Now sink the ball.", "target": "hole"},
			]
		),
		_base_level(
			&"sand",
			3,
			[
				{"type": "sand", "pos": Vector2.ZERO, "size": Vector2(100.0, 600.0), "elevation": 0},
			],
			[],
			[&"entered_sand"],
			[
				{"event": &"entered_sand", "text": "Hit into the sand band. Feel how it slows the ball.", "target": "hazard:0"},
				{"event": &"hole_completed", "text": "Recover and finish the hole.", "target": "hole"},
			]
		),
		_base_level(
			&"water_reset",
			4,
			[
				{"type": "water", "pos": Vector2.ZERO, "size": Vector2(100.0, 600.0), "elevation": 0, "tutorial_barrier": true},
			],
			[],
			[&"entered_water"],
			[
				{"event": &"entered_water", "text": "Hit the water once. It returns you to the tee with a penalty stroke.", "target": "hazard:0"},
				{"event": &"hole_completed", "text": "The banks are open now. Aim around the remaining water.", "target": "hole"},
			]
		),
		_moving_hazard_level(),
		_shop_level(),
		_base_level(
			&"card_tradeoff_continue",
			3,
			[
				{"type": "sand", "pos": Vector2(0.0, -50.0), "size": Vector2(100.0, 100.0), "elevation": 0},
			],
			[],
			[&"card_benefit_active", &"card_curse_active", &"shot_taken"],
			[
				{"event": &"aim_started", "text": "Your bonus stays for the run.", "target": "ball"},
				{"event": &"power_adjusted", "text": "The curse lasts 3 holes.", "target": "ball"},
				{"event": &"shot_taken", "text": "Play around both effects.", "target": "hole"},
				{"event": &"hole_completed", "text": "Tutorial complete.", "target": "hole"},
			]
		),
	]
	return levels


static func get_tutorial_cards() -> Array[CardDefinition]:
	return CardDatabaseScript.get_tutorial_cards()


static func tutorial_card_names() -> Array[String]:
	var names: Array[String] = []
	for card in get_tutorial_cards():
		names.append(card.name)
	return names


static func _base_level(
	lesson: StringName,
	par: int,
	hazards: Array,
	obstacles: Array,
	required_events: Array,
	steps: Array
) -> Dictionary:
	var meadow: BiomeProfile = BiomeDatabase.get_profiles()[0]
	return {
		"terrain_palette": meadow.terrain_palette.duplicate(true),
		"background_palette": meadow.background_palette.duplicate(true),
		"ambience": meadow.ambience,
		"lesson": lesson,
		"map": TUTORIAL_MAP.duplicate(),
		"start_cell": Vector2i(1, 3),
		"hole_cell": Vector2i(8, 3),
		"start_elevation": 0,
		"hole_elevation": 0,
		"par": par,
		"hazards": hazards,
		"moving_hazards": [],
		"obstacles": obstacles,
		"branches": [],
		"elevation_transitions": [],
		"elevation_structures": [],
		"visual_rough_cells": [Vector2i(2, 1), Vector2i(7, 4)],
		"tee": {"cell": Vector2i(1, 3), "elevation": 0},
		"required_events": required_events,
		"steps": steps,
	}


static func _moving_hazard_level() -> Dictionary:
	var level := _base_level(
		&"blocker_and_moving_hazard",
		4,
		[],
		[
			{"type": "blocker", "pos": Vector2(0.0, 50.0), "size": Vector2(WALL_THICKNESS, 200.0), "elevation": 0},
		],
		[&"shot_taken"],
		[
			{"event": &"shot_taken", "text": "Shoot around the blocker.", "target": "hole"},
			{"event": &"hole_completed", "text": "Watch moving obstacles.", "target": "hole"},
		]
	)
	level.moving_hazards = [
		{
			"type": "pendulum",
			"pos": Vector2(150.0, -50.0),
			"size": Vector2(38.0, 38.0),
			"elevation": 0,
			"period": 2.8,
			"phase": 0.125,
			"intensity": 0.55,
			"travel_radius": 28.0,
			"swing_angle": 0.9,
			"blocks_main_route": false,
		},
	]
	return level


static func _shop_level() -> Dictionary:
	var level := _base_level(
		&"shop_tradeoff",
		2,
		[],
		[],
		[],
		[
			{"event": &"hole_completed", "text": "Finish to earn coins and open the shop.", "target": "hole"},
			{"event": &"shop_opened", "text": "Cards give a bonus and a curse.", "target": "shop"},
			{"event": &"card_bought", "text": "Buy a card to continue.", "target": "shop"},
			{"event": &"shop_continued", "text": "Continue to the next hole.", "target": "shop"},
		]
	)
	level.forced_tokens = 4
	level.open_shop = true
	level.minimum_shop_purchases = 1
	level.tutorial_card_ids = [&"tutorial_training_driver", &"tutorial_sand_shoes", &"tutorial_pocket_change", &"tutorial_steady_grip"]
	level.shop_cards = tutorial_card_names()
	return level
