class_name LevelDatabase
extends RefCounted

const WALL_THICKNESS := 30.0


static func get_levels() -> Array[Dictionary]:
	return [
		{
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
			"obstacles": []
		},
		{
			"map": [
				"..........",
				"..........",
				"..........",
				"..........",
				"..........",
				".........."
			],
			"start_cell": Vector2i(1, 1),
			"hole_cell": Vector2i(8, 4),
			"par": 3,
			"hazards": [
				{"type": "sand", "pos": Vector2(-200.0, -50.0), "size": Vector2(200.0, 100.0)}
			],
			"obstacles": [
				{"pos": Vector2(0.0, 0.0), "size": Vector2(WALL_THICKNESS, 300.0)}
			]
		},
		{
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
			"par": 4,
			"hazards": [
				{"type": "water", "pos": Vector2(0.0, 0.0), "size": Vector2(200.0, 200.0)}
			],
			"obstacles": [
				{"pos": Vector2(-150.0, 0.0), "size": Vector2(WALL_THICKNESS, 300.0)},
				{"pos": Vector2(150.0, 0.0), "size": Vector2(WALL_THICKNESS, 300.0)}
			]
		},
		{
			"map": [
				"######    ",
				"######    ",
				"##########",
				"##########",
				"    ######",
				"    ######"
			],
			"start_cell": Vector2i(0, 2),
			"hole_cell": Vector2i(9, 3),
			"par": 4,
			"hazards": [
				{"type": "direction", "pos": Vector2(-250.0, 50.0), "size": Vector2(100.0, 100.0), "direction": Vector2.RIGHT},
				{"type": "sand", "pos": Vector2(250.0, -50.0), "size": Vector2(100.0, 100.0)}
			],
			"obstacles": [
				{"pos": Vector2(-100.0, -150.0), "size": Vector2(300.0, WALL_THICKNESS)},
				{"pos": Vector2(100.0, 150.0), "size": Vector2(300.0, WALL_THICKNESS)}
			]
		},
		{
			"map": [
				"#####     ",
				"#######   ",
				"  ########",
				"  ########",
				"   #######",
				"     #####"
			],
			"start_cell": Vector2i(0, 0),
			"hole_cell": Vector2i(9, 5),
			"par": 5,
			"hazards": [
				{"type": "water", "pos": Vector2(-50.0, 50.0), "size": Vector2(100.0, 100.0)},
				{"type": "direction", "pos": Vector2(50.0, -50.0), "size": Vector2(100.0, 100.0), "direction": Vector2.DOWN},
				{"type": "direction", "pos": Vector2(250.0, 50.0), "size": Vector2(100.0, 100.0), "direction": Vector2.RIGHT}
			],
			"obstacles": [
				{"pos": Vector2(-150.0, -50.0), "size": Vector2(WALL_THICKNESS, 300.0)},
				{"pos": Vector2(50.0, 50.0), "size": Vector2(WALL_THICKNESS, 300.0)},
				{"pos": Vector2(250.0, -50.0), "size": Vector2(WALL_THICKNESS, 300.0)}
			]
		}
	]
