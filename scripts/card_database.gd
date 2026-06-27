class_name CardDatabase
extends RefCounted


static func get_cards() -> Array[Dictionary]:
	return [
		{
			"name": "Overdrive Driver",
			"cost": 3,
			"upside": "+25% shot power",
			"downside": "-15% aim pull distance",
			"effects": {"impulse": 0.25, "drag": -0.15}
		},
		{
			"name": "Rangefinder Lens",
			"cost": 2,
			"upside": "+4 trajectory dots",
			"downside": "-10% shot power",
			"effects": {"trajectory": 4, "impulse": -0.1}
		},
		{
			"name": "Sand Cleats",
			"cost": 2,
			"upside": "Sand slows 35% less",
			"downside": "Direction pads push 25% harder",
			"effects": {"sand": -0.35, "direction": 0.25}
		},
		{
			"name": "Heavy Core",
			"cost": 2,
			"upside": "+20% aim pull distance",
			"downside": "+15% sand slowdown",
			"effects": {"drag": 0.2, "sand": 0.15}
		},
		{
			"name": "Lucky Putter",
			"cost": 3,
			"upside": "+1 token reward after each hole",
			"downside": "-2 trajectory dots",
			"effects": {"reward": 1, "trajectory": -2}
		}
	]
