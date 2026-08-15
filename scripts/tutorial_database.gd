class_name TutorialDatabase
extends RefCounted

const WALL_THICKNESS := 30.0


static func get_levels() -> Array[Dictionary]:
	return [
		{
			"lesson": "basic_shot",
			"map": [
				"..........",
				"..........",
				"..........",
				"..........",
				"..........",
				".........."
			],
			"start_cell": Vector2i(1, 3),
			"hole_cell": Vector2i(8, 3),
			"par": 2,
			"hazards": [],
			"obstacles": [],
			"required_events": ["aim_started", "shot_taken"],
			"steps": [
				{"event": "aim_started", "text": "Aim from the ball.", "target": "ball"},
				{"event": "shot_taken", "text": "Charge power, then release.", "target": "ball"},
				{"event": "hole_completed", "text": "Reach the cup.", "target": "hole"}
			]
		},
		{
			"lesson": "rough",
			"map": [
				"..........",
				"..........",
				"..........",
				"..........",
				"..........",
				".........."
			],
			"start_cell": Vector2i(1, 3),
			"hole_cell": Vector2i(8, 3),
			"par": 3,
			"hazards": [
				{"type": "rough", "pos": Vector2(0.0, 50.0), "size": Vector2(200.0, 100.0)}
			],
			"obstacles": [],
			"required_events": ["entered_rough"],
			"steps": [
				{"event": "entered_rough", "text": "Rough slows the ball.", "target": "hazard:0"},
				{"event": "hole_completed", "text": "Use enough power to escape.", "target": "hole"}
			]
		},
		{
			"lesson": "sand",
			"map": [
				"..........",
				"..........",
				"..........",
				"..........",
				"..........",
				".........."
			],
			"start_cell": Vector2i(1, 3),
			"hole_cell": Vector2i(8, 3),
			"par": 3,
			"hazards": [
				{"type": "sand", "pos": Vector2(0.0, 50.0), "size": Vector2(200.0, 100.0)}
			],
			"obstacles": [],
			"required_events": ["entered_sand"],
			"steps": [
				{"event": "entered_sand", "text": "Sand kills speed quickly.", "target": "hazard:0"},
				{"event": "hole_completed", "text": "Short recovery shots are safer.", "target": "hole"}
			]
		},
		{
			"lesson": "water_penalty",
			"map": [
				"..........",
				"..........",
				"..........",
				"..........",
				"..........",
				".........."
			],
			"start_cell": Vector2i(1, 3),
			"hole_cell": Vector2i(8, 3),
			"par": 4,
			"hazards": [
				{"type": "water", "pos": Vector2(0.0, 50.0), "size": Vector2(200.0, 100.0)}
			],
			"obstacles": [],
			"required_events": ["entered_water"],
			"steps": [
				{"event": "entered_water", "text": "Water resets you and adds a penalty.", "target": "hazard:0"},
				{"event": "hole_completed", "text": "Now play around it.", "target": "hole"}
			]
		},
		{
			"lesson": "out_of_bounds",
			"map": [
				"..........",
				"..........",
				"..........",
				"..........",
				"..........",
				".........."
			],
			"start_cell": Vector2i(1, 3),
			"hole_cell": Vector2i(8, 3),
			"par": 4,
			"hazards": [
				{"type": "out", "pos": Vector2(0.0, -150.0), "size": Vector2(200.0, 100.0)}
			],
			"obstacles": [
				{"pos": Vector2(0.0, -50.0), "size": Vector2(200.0, WALL_THICKNESS)}
			],
			"required_events": ["entered_out"],
			"steps": [
				{"event": "entered_out", "text": "Red zones are out of bounds.", "target": "hazard:0"},
				{"event": "hole_completed", "text": "Boundaries protect the fairway.", "target": "hole"}
			]
		},
		{
			"lesson": "shop_tradeoff",
			"map": [
				"..........",
				"..........",
				"..........",
				"..........",
				"..........",
				".........."
			],
			"start_cell": Vector2i(1, 3),
			"hole_cell": Vector2i(8, 3),
			"par": 2,
			"hazards": [],
			"obstacles": [],
			"forced_tokens": 3,
			"shop_cards": ["Overdrive Driver", "Rangefinder Lens", "Heavy Core"],
			"require_shop_purchase": true,
			"required_events": [],
			"steps": [
				{"event": "hole_completed", "text": "Finish holes to reach the shop.", "target": "hole"},
				{"event": "card_bought", "text": "Every bonus has a drawback.", "target": "shop"}
			]
		},
		{
			"lesson": "wind",
			"map": [
				"..........",
				"..........",
				"..........",
				"..........",
				"..........",
				".........."
			],
			"start_cell": Vector2i(1, 3),
			"hole_cell": Vector2i(8, 3),
			"par": 3,
			"hazards": [
				{"type": "direction", "pos": Vector2(0.0, 50.0), "size": Vector2(200.0, 100.0), "direction": Vector2.UP}
			],
			"obstacles": [],
			"required_events": ["entered_direction"],
			"steps": [
				{"event": "entered_direction", "text": "Wind pads push while you cross.", "target": "hazard:0"},
				{"event": "hole_completed", "text": "Aim against the push.", "target": "hole"}
			]
		},
		{
			"lesson": "narrow_fairway",
			"map": [
				"   ####   ",
				"   ####   ",
				"##########",
				"##########",
				"   ####   ",
				"   ####   "
			],
			"start_cell": Vector2i(0, 2),
			"hole_cell": Vector2i(9, 3),
			"par": 4,
			"hazards": [],
			"obstacles": [
				{"pos": Vector2(-100.0, -50.0), "size": Vector2(WALL_THICKNESS, 300.0)},
				{"pos": Vector2(100.0, 50.0), "size": Vector2(WALL_THICKNESS, 300.0)}
			],
			"required_events": ["shot_taken"],
			"steps": [
				{"event": "shot_taken", "text": "Narrow fairways reward control.", "target": "hole"},
				{"event": "hole_completed", "text": "Use the walls only when you mean to.", "target": "hole"}
			]
		},
		{
			"lesson": "small_cup",
			"map": [
				"..........",
				"..........",
				"..........",
				"..........",
				"..........",
				".........."
			],
			"start_cell": Vector2i(1, 3),
			"hole_cell": Vector2i(8, 3),
			"par": 3,
			"cup_radius": 18.0,
			"hazards": [],
			"obstacles": [],
			"required_events": ["shot_taken"],
			"steps": [
				{"event": "shot_taken", "text": "Small cups need softer approaches.", "target": "hole"},
				{"event": "hole_completed", "text": "Control beats power here.", "target": "hole"}
			]
		},
		{
			"lesson": "strategy_final",
			"map": [
				"  ######  ",
				" ######## ",
				"##########",
				"##########",
				" ######## ",
				"  ######  "
			],
			"start_cell": Vector2i(1, 4),
			"hole_cell": Vector2i(8, 1),
			"par": 5,
			"cup_radius": 20.0,
			"hazards": [
				{"type": "rough", "pos": Vector2(-200.0, 150.0), "size": Vector2(100.0, 100.0)},
				{"type": "sand", "pos": Vector2(0.0, 50.0), "size": Vector2(100.0, 100.0)},
				{"type": "water", "pos": Vector2(100.0, -50.0), "size": Vector2(100.0, 100.0)},
				{"type": "direction", "pos": Vector2(300.0, -150.0), "size": Vector2(100.0, 100.0), "direction": Vector2.LEFT}
			],
			"obstacles": [
				{"pos": Vector2(-150.0, 0.0), "size": Vector2(WALL_THICKNESS, 300.0)},
				{"pos": Vector2(250.0, -100.0), "size": Vector2(WALL_THICKNESS, 200.0)}
			],
			"required_events": [],
			"steps": [
				{"event": "shot_taken", "text": "Plan the next shot before you swing.", "target": "hole"},
				{"event": "hole_completed", "text": "Tutorial complete.", "target": "hole"}
			]
		}
	]
