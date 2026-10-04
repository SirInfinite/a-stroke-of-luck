extends RefCounted
## Original raster exports, shared density and deterministic material assembly.

const ROOT := "res://assets/reference_slice/world/"
static var textures: Dictionary = {}

static func texture(path: String, density := 48) -> Texture2D:
	var key := "d%d/%s" % [density, path]
	if not textures.has(key): textures[key] = load(ROOT + key + ".png")
	return textures[key] as Texture2D

static func sprite(path: String, at := Vector2.ZERO, dimensions := Vector2.ZERO, density := 48) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = texture(path, density)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.position = at
	if dimensions != Vector2.ZERO: result.scale = dimensions / result.texture.get_size()
	return result

static func wall_texture(dimensions: Vector2, at: Vector2, all_walls: Array[Rect2], biome: StringName, density: int) -> ImageTexture:
	var pixels := Vector2i(maxi(2, roundi(dimensions.x * density / 100.0)), maxi(2, roundi(dimensions.y * density / 100.0)))
	var image := Image.create(pixels.x, pixels.y, false, Image.FORMAT_RGBA8)
	var stone := texture("terrain/wall_volcanic" if biome == &"volcanic" else "terrain/wall_meadow", density).get_image()
	var ink := Color("211f2a") if biome == &"volcanic" else Color("172f32")
	var cap := Color("c58b5d") if biome == &"volcanic" else Color("c8d5a0")
	var edge := Color("8f4c3d") if biome == &"volcanic" else Color("78985d")
	var side := Color("3a2936") if biome == &"volcanic" else Color("42564c")
	var origin := at - dimensions * 0.5
	var texel := dimensions / Vector2(pixels)
	for y in pixels.y:
		for x in pixels.x:
			var world_at := origin + (Vector2(x, y) + Vector2.ONE * 0.5) * texel
			var source_at := Vector2i(floori(world_at.x * density / 100.0), floori(world_at.y * density / 100.0))
			var color := stone.get_pixel(posmod(source_at.x, density), posmod(source_at.y, density))
			# Longitudinal caps cross native segment joins. Only the exposed union
			# gets a rim; this avoids a heavy square frame around every wall cell.
			var top_open := not _occupied(world_at - Vector2(0, texel.y * float(y + 1)), all_walls)
			var left_open := not _occupied(world_at - Vector2(texel.x * float(x + 1), 0), all_walls)
			var bottom_open := not _occupied(world_at + Vector2(0, texel.y * float(pixels.y - y)), all_walls)
			var right_open := not _occupied(world_at + Vector2(texel.x * float(pixels.x - x), 0), all_walls)
			if (top_open and y == 0) or (left_open and x == 0) or (bottom_open and y == pixels.y - 1) or (right_open and x == pixels.x - 1):
				color = ink
			elif (top_open and y == 1) or (left_open and x == 1): color = cap
			elif (top_open and y == 2) or (left_open and x == 2): color = edge
			elif (bottom_open and y >= pixels.y - 4) or (right_open and x >= pixels.x - 3): color = side
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

static func _occupied(point: Vector2, rectangles: Array[Rect2]) -> bool:
	for rectangle in rectangles:
		if rectangle.has_point(point): return true
	return false
