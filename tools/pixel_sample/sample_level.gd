extends RefCounted
## Authored presentation fixture. Production generation and rules are untouched.

const SEED := 9102026

static func create() -> Dictionary:
	var meadow = BiomeDatabase.get_profiles()[0]
	return {
		"map": ["............", "............", "............", "............", "............", "............", "............", "............"],
		"start_cell": Vector2i(1, 5), "hole_cell": Vector2i(10, 5), "par": 4,
		"hazards": [
			{"type": "water", "pos": Vector2(50, -250), "size": Vector2(100, 100)},
			{"type": "water", "pos": Vector2(150, -250), "size": Vector2(100, 100)},
			{"type": "water", "pos": Vector2(150, -150), "size": Vector2(100, 100)},
			{"type": "sand", "pos": Vector2(350, -150), "size": Vector2(100, 100)},
			{"type": "sand", "pos": Vector2(450, -150), "size": Vector2(100, 100)},
			{"type": "bounce_pad", "pos": Vector2(50, 300), "size": Vector2(70, 70), "seed": 17},
		],
		"moving_hazards": [{"type": "pendulum", "pos": Vector2(-260, -290), "size": Vector2(88, 88), "travel_radius": 160.0, "swing_angle": 0.8, "period": 3.2, "phase": 0.0, "blocks_main_route": false}],
		"obstacles": [{"pos": Vector2(80, -20), "size": Vector2(180, 42)}],
		"biome_id": &"meadow", "biome_name": "Meadow", "biome_index": 0,
		"overall_hole_number": 3, "hole_index": 2, "hole_name": "THE OLD SWING",
		"terrain_palette": meadow.terrain_palette.duplicate(true),
		"background_palette": meadow.background_palette.duplicate(true),
		"decoration_identifiers": meadow.decoration_identifiers.duplicate(),
		"ambience": meadow.ambience, "run_seed": SEED,
		"shop_cards": ["Overdrive Driver", "Sand Cleats", "Coin Magnet", "Rangefinder Lens"],
	}
