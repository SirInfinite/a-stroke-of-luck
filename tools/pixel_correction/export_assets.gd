extends SceneTree
## Measured sheet extraction and nearest-neighbor density export. Sources retained.

const ROOT := "res://assets/pixel_correction/"
var exports: Array[Dictionary] = []
var active_source := ""

func _initialize() -> void:
	var terrain := _source("terrain_flat.png")
	var tiles := ["fairway_a", "fairway_b", "green_a", "green_b", "water_a", "water_b", "sand_a", "sand_b"]
	for index in tiles.size():
		var rect := _cell(terrain, index, 4, 2)
		_export(terrain, rect, "terrain/" + tiles[index], Vector2i(32, 32), false)
	var objects := _source("objects.png")
	var props := ["pendulum", "chain", "pivot", "ball", "flag_a", "flag_b", "tee", "pad", "coin", "bag", "strike", "dust", "willow", "flowers", "lotus", "sign"]
	# The generated rows are uneven. Measured gaps avoid cutting the shackle/flag.
	var row_edges := [0, 344, 640, 942, 1254]
	for index in props.size():
		var rect := _cell(objects, index, 4, 4)
		rect.position.y = row_edges[index / 4]
		rect.size.y = row_edges[index / 4 + 1] - rect.position.y
		_export(objects, rect, "props/" + props[index], Vector2i(48, 48), true)
	var cards := _source("cards_cutout.png")
	var names := ["overdrive_driver", "sand_cleats", "coin_magnet", "rangefinder_lens"]
	for index in names.size():
		_export(cards, _cell(cards, index, 2, 2), "cards/" + names[index], Vector2i(64, 64), true)
	var background := _source("background.png")
	_export(background, Rect2i(Vector2i.ZERO, background.get_size()), "ui/background", Vector2i(480, 270), false)
	var manifest := {"method": "Original generated source colors; measured crop, material alpha normalization, sprite alpha bounds and nearest-neighbor export. No logo processing.", "exports": exports}
	FileAccess.open(ROOT + "export_manifest.json", FileAccess.WRITE).store_string(JSON.stringify(manifest, "\t") + "\n")
	print("[ARCADE EXPORT] %d assets" % exports.size())
	quit()

func _source(filename: String) -> Image:
	active_source = filename
	return Image.load_from_file(ProjectSettings.globalize_path(ROOT + "source/" + filename))

func _cell(source: Image, index: int, columns: int, rows: int) -> Rect2i:
	var x := index % columns
	var y := index / columns
	var start := Vector2i(roundi(float(x) * source.get_width() / columns), roundi(float(y) * source.get_height() / rows))
	var finish := Vector2i(roundi(float(x + 1) * source.get_width() / columns), roundi(float(y + 1) * source.get_height() / rows))
	return Rect2i(start, finish - start)

func _export(source: Image, rect: Rect2i, path: String, dimensions: Vector2i, trim: bool) -> void:
	var image := source.get_region(rect)
	# Terrain/background are opaque materials. Item/prop gutters use binary
	# alpha so near-transparent generation residue cannot inflate trim bounds.
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			color.a = (1.0 if color.a >= 0.5 else 0.0) if trim else 1.0
			image.set_pixel(x, y, color)
	if trim:
		var used := image.get_used_rect()
		image = image.get_region(used)
		var ratio := float(dimensions.x) / maxf(image.get_width(), image.get_height())
		dimensions = Vector2i(maxi(1, roundi(image.get_width() * ratio)), maxi(1, roundi(image.get_height() * ratio)))
	image.resize(dimensions.x, dimensions.y, Image.INTERPOLATE_NEAREST)
	var target := ROOT + path + ".png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target.get_base_dir()))
	var error := image.save_png(target)
	assert(error == OK, "Could not export " + target)
	exports.append({"file": path + ".png", "source": active_source, "crop": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "size": [dimensions.x, dimensions.y], "sha256": FileAccess.get_sha256(target)})
