extends SceneTree
## Deterministic build tool, excluded from exports. Uses the same SVG rasterizer
## as the game. Only writes the named app PNG/ICO assets; never an executable.

const SIZES := [16, 32, 48, 128, 256]
const OUTPUT := "res://assets/ui/brand/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var check := "--check" in OS.get_cmdline_user_args()
	var pngs: Array[PackedByteArray] = []
	var failures := 0
	for extent: int in SIZES:
		var source := OUTPUT + ("emblem_small.svg" if extent <= 32 else "emblem.svg")
		var svg := FileAccess.get_file_as_string(source)
		var image := Image.new()
		var error := image.load_svg_from_string(svg, float(extent) / 256.0)
		if error != OK or image.get_size() != Vector2i(extent, extent):
			push_error("App icon rasterization failed: %d (%s)" % [extent, error])
			quit(1)
			return
		var png := image.save_png_to_buffer()
		pngs.append(png)
		failures += _output("app_icon_%d.png" % extent, png, check)
	# ICO directory plus PNG payloads. 256 is encoded as zero by the ICO format.
	var ico := PackedByteArray()
	ico.resize(6 + 16 * SIZES.size())
	ico.encode_u16(2, 1)
	ico.encode_u16(4, SIZES.size())
	var offset := ico.size()
	for index in SIZES.size():
		var entry := 6 + index * 16
		ico[entry] = SIZES[index] % 256
		ico[entry + 1] = SIZES[index] % 256
		ico.encode_u16(entry + 4, 1)
		ico.encode_u16(entry + 6, 32)
		ico.encode_u32(entry + 8, pngs[index].size())
		ico.encode_u32(entry + 12, offset)
		offset += pngs[index].size()
	for png in pngs:
		ico.append_array(png)
	failures += _output("app_icon.ico", ico, check)
	print("[BRAND RASTER %s] %d sizes + Windows ICO; %d failures" % ["CHECK" if check else "BUILD", SIZES.size(), failures])
	quit(0 if failures == 0 else 1)


func _output(filename: String, bytes: PackedByteArray, check: bool) -> int:
	var path := OUTPUT + filename
	if check:
		if FileAccess.get_file_as_bytes(path) != bytes:
			push_error("Stale app icon: " + path)
			return 1
		return 0
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Cannot write app icon: " + path)
		return 1
	file.store_buffer(bytes)
	return 0
