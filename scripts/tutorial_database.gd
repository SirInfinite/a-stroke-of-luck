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
				{"event": &"aim_started", "text": "AIM — drag from the ball or use the arrow keys.", "target": "ball"},
				{"event": &"power_adjusted", "text": "POWER — a short guide means a soft shot; a long guide means a strong shot.", "target": "ball"},
				{"event": &"shot_taken", "text": "TRAJECTORY — the adaptive dots preview every shot at its real scale.", "target": "ball"},
				{"event": &"hole_completed", "text": "NORMAL GRASS and the greener cup area use normal physics.", "target": "hole"},
			]
		),
		_base_level(
			&"sand",
			3,
			[
				{"type": "sand", "pos": Vector2(0.0, 50.0), "size": Vector2(200.0, 100.0), "elevation": 0},
			],
			[],
			[&"entered_sand"],
			[
				{"event": &"entered_sand", "text": "SAND is the ordinary slow terrain. Carry extra speed, then recover with control.", "target": "hazard:0"},
				{"event": &"hole_completed", "text": "Grass that looks rougher is visual variety only; it never changes physics.", "target": "hole"},
			]
		),
		_base_level(
			&"water_reset",
			4,
			[
				{"type": "water", "pos": Vector2(0.0, 50.0), "size": Vector2(200.0, 100.0), "elevation": 0},
			],
			[],
			[&"entered_water"],
			[
				{"event": &"entered_water", "text": "WATER is the main reset hazard. The accepted shot and its cost still count.", "target": "hazard:0"},
				{"event": &"hole_completed", "text": "Aim around hazards; a reset never erases your score.", "target": "hole"},
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
				{"event": &"aim_started", "text": "CARD BENEFIT — the bonus you bought remains active for the run. Aim to continue.", "target": "ball"},
				{"event": &"power_adjusted", "text": "ACTIVE CURSE — its disclosed drawback lasts for the shown number of holes. Adjust power to continue.", "target": "ball"},
				{"event": &"shot_taken", "text": "CONTINUE RUN — plan with both sides of your card, then finish the lesson.", "target": "hole"},
				{"event": &"hole_completed", "text": "Tutorial complete. Continue into the six-biome, 18-hole run.", "target": "hole"},
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
	return {
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
			{"event": &"shot_taken", "text": "HAZARDS — blockers and moving obstacles have readable silhouettes and timing.", "target": "hole"},
			{"event": &"hole_completed", "text": "Use a safe angle; moving hazards never remove the validated main route.", "target": "hole"},
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
			{"event": &"hole_completed", "text": "SHOP — finish this hole to spend the practice coins.", "target": "hole"},
			{"event": &"shop_opened", "text": "Choose one simple card. Every card clearly pairs a BENEFIT with a CURSE.", "target": "shop"},
			{"event": &"card_bought", "text": "Purchase one card to learn its persistent benefit and temporary drawback.", "target": "shop"},
			{"event": &"shop_continued", "text": "Continue to play with both sides of your choice.", "target": "shop"},
		]
	)
	level.forced_tokens = 4
	level.open_shop = true
	level.minimum_shop_purchases = 1
	level.tutorial_card_ids = [&"tutorial_training_driver", &"tutorial_sand_shoes", &"tutorial_pocket_change", &"tutorial_steady_grip"]
	level.shop_cards = tutorial_card_names()
	return level
