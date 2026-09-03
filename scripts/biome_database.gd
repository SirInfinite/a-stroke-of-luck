class_name BiomeDatabase
extends RefCounted

const BiomeProfileScript := preload("res://scripts/biome_profile.gd")


static func get_profiles() -> Array:
	var profiles: Array = []
	profiles.append(BiomeProfileScript.new(
		&"meadow",
		"Meadow",
		_palette(Color("63b75d"), Color("58a852"), Color("6f4a2f"), Color("d9bc78"), Color("3f7d44"), Color("4fa6d8"), Color("d9534f"), Color("79b88b")),
		_background(Color("245c3a"), Color("3f7d44"), Color("f2cf5b")),
		PackedStringArray(["wildflowers", "clover", "shrubs", "buttercups"]),
		{"water": 4.0, "sand": 2.0, "direction": 1.0, "bounce_pad": 1.0},
		_difficulty(10, 6, 1, 0),
		&"meadow_breeze"
	))
	profiles.append(BiomeProfileScript.new(
		&"desert",
		"Desert",
		_palette(Color("d8b45f"), Color("c69b4a"), Color("76502d"), Color("efd28a"), Color("9b7a3e"), Color("52a6bd"), Color("c9523f"), Color("ccb06e")),
		_background(Color("6b512d"), Color("a77d3e"), Color("f0c45f")),
		PackedStringArray(["cactus", "rocks", "dry_grass", "sunstone"]),
		{"sand": 5.0, "water": 1.0, "direction": 2.0, "bounce_pad": 1.5},
		_difficulty(10, 6, 2, 1),
		&"dry_wind"
	))
	profiles.append(BiomeProfileScript.new(
		&"autumn",
		"Autumn",
		_palette(Color("b56f39"), Color("934f2d"), Color("573722"), Color("d4a45d"), Color("69482f"), Color("477f9f"), Color("aa3f3a"), Color("c78545")),
		_background(Color("442c2a"), Color("6c3e32"), Color("e29a3b")),
		PackedStringArray(["red_maple", "fallen_leaves", "acorns", "amber_shrub"]),
		{"water": 2.5, "sand": 2.0, "direction": 2.0, "bounce_pad": 1.5},
		_difficulty(11, 6, 2, 1),
		&"leaf_rustle"
	))
	profiles.append(BiomeProfileScript.new(
		&"snow",
		"Snow",
		_palette(Color("dbe9ee"), Color("b9d3dc"), Color("5d7180"), Color("d5c49b"), Color("8ba4a2"), Color("4b91bd"), Color("ba4c58"), Color("a9d8e3")),
		_background(Color("607785"), Color("8faebb"), Color("eefaff")),
		PackedStringArray(["pine", "snowdrifts", "ice_crystals", "frost_stones"]),
		{"ice": 5.0, "water": 2.0, "sand": 1.0, "bounce_pad": 1.0},
		_difficulty(11, 6, 2, 2),
		&"winter_gust"
	))
	profiles.append(BiomeProfileScript.new(
		&"swamp",
		"Swamp",
		_palette(Color("55734a"), Color("405f3d"), Color("3e3526"), Color("89784d"), Color("31553b"), Color("3f7c75"), Color("8f3e45"), Color("718b5f")),
		_background(Color("263a31"), Color("445b3e"), Color("9fbf66")),
		PackedStringArray(["reeds", "mud_pool", "mushrooms", "lily_pads"]),
		{"water": 5.0, "sand": 1.5, "direction": 1.5, "bounce_pad": 1.0},
		_difficulty(11, 7, 3, 2),
		&"swamp_night"
	))
	profiles.append(BiomeProfileScript.new(
		&"volcanic",
		"Volcanic",
		_palette(Color("514846"), Color("3b3434"), Color("211d20"), Color("8c6245"), Color("4b3d39"), Color("d55b32"), Color("e13c2d"), Color("a96442")),
		_background(Color("211d20"), Color("6f342b"), Color("ff7138")),
		PackedStringArray(["basalt", "embers", "lava_crack", "smoke_vent"]),
		{"lava": 5.0, "sand": 1.0, "direction": 1.0, "bounce_pad": 1.5},
		_difficulty(12, 7, 3, 3),
		&"volcanic_rumble"
	))
	return profiles


static func _palette(
	fairway_a: Color,
	fairway_b: Color,
	border: Color,
	sand: Color,
	rough: Color,
	water: Color,
	danger: Color,
	direction: Color
) -> Dictionary:
	return {
		"fairway_a": fairway_a,
		"fairway_b": fairway_a.lerp(fairway_b, 0.42),
		"fairway_detail": fairway_a.lightened(0.09),
		"green": fairway_a.darkened(0.17),
		"tee": fairway_a.lightened(0.24),
		"border": border,
		"outline": border.darkened(0.32),
		"sand": sand,
		"sand_detail": sand.lightened(0.2),
		"rough": rough,
		"rough_detail": rough.lightened(0.2),
		"water": water,
		"water_detail": water.lightened(0.3),
		"ice": Color("9ed5e4") if fairway_a.get_luminance() > 0.62 else water.lightened(0.18),
		"ice_detail": Color("f5fbff"),
		"lava": Color("d9522f") if fairway_a.get_luminance() < 0.42 else danger,
		"lava_detail": Color("ffb13b"),
		"direction": direction,
		"direction_detail": direction.lightened(0.28),
		"flag": danger,
		"hazard_telegraph": danger.lightened(0.16),
		"elevation_edge": border.darkened(0.18),
		"elevation_highlight": fairway_a.lightened(0.22),
	}


static func _background(primary: Color, secondary: Color, accent: Color) -> Dictionary:
	return {
		"primary": primary,
		"secondary": secondary,
		"accent": accent,
		"shadow": primary.darkened(0.28),
		"highlight": secondary.lightened(0.16),
	}


static func _difficulty(map_width: int, map_height: int, max_bend: int, hazard_bonus: int) -> Dictionary:
	return {
		"map_width": map_width,
		"map_height": map_height,
		"max_bend": max_bend,
		"hazard_bonus": hazard_bonus,
		"lane_radius_easy": 2,
		"lane_radius_normal": 2,
		"lane_radius_hard": 1
	}
