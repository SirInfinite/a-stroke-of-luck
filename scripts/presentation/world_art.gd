class_name WorldArt
extends RefCounted
## Production-only raster catalog. No sample, reference or tooling dependencies.

const ROOT := "res://assets/world/"
const DENSITY := 48
const BIOMES := [&"meadow", &"desert", &"autumn", &"snow", &"swamp", &"volcanic"]
static var _textures: Dictionary = {}

static func background_path(biome: StringName) -> String:
	return ROOT + "backgrounds/" + String(biome if biome in BIOMES else &"meadow") + ".png"

static func texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(ROOT + path + ".png")
	return _textures[path] as Texture2D

static func sprite(path: String, at := Vector2.ZERO, dimensions := Vector2.ZERO) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = texture(path)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.position = at
	if dimensions != Vector2.ZERO:
		result.scale = dimensions / result.texture.get_size()
	return result

static func floor_sprite(biome: StringName, cell: Vector2i, putting: bool, size := Vector2(100, 100)) -> Sprite2D:
	if biome not in BIOMES: biome = &"meadow"
	var material := "green" if putting else "fairway"
	var variant := "a" if posmod(cell.x + cell.y, 2) == 0 else "b"
	var quiet := "_quiet" if putting or posmod(cell.x * 5 + cell.y * 11, 13) != 0 else ""
	return sprite("terrain/%s_%s_%s%s" % [biome, material, variant, quiet], Vector2.ZERO, size)

static func biome_for_ambience(id: StringName) -> StringName:
	return {&"meadow_breeze":&"meadow", &"dry_wind":&"desert", &"leaf_rustle":&"autumn",
		&"winter_gust":&"snow", &"swamp_night":&"swamp", &"volcanic_rumble":&"volcanic"}.get(id, &"meadow")

static func landmark(biome: StringName) -> String:
	return {&"meadow":"willow", &"desert":"cactus", &"autumn":"maple", &"snow":"spruce",
		&"swamp":"cypress", &"volcanic":"basalt_columns"}.get(biome, "willow")

static func stone_colors(biome: StringName) -> Array[Color]:
	var values: Array = {
		&"meadow":["172f32","c8d5a0","78985d","42564c"],
		&"desert":["4b332e","efcd91","b78659","79523d"],
		&"autumn":["30322e","d5c78d","a48e5b","635441"],
		&"snow":["293e54","e0eadf","9bb9ca","597487"],
		&"swamp":["172e2b","abb27c","718657","394d3b"],
		&"volcanic":["211f2a","c58b5d","8f4c3d","3a2936"]}.get(biome, ["172f32","c8d5a0","78985d","42564c"])
	return [Color(values[0]), Color(values[1]), Color(values[2]), Color(values[3])]
