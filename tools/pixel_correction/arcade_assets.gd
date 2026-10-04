extends RefCounted
## One sample-local pixel scale, ink palette and stepped UI material family.

const ROOT := "res://assets/pixel_correction/"
const FONT := preload("res://assets/pixel_sample/fonts/PixelifySans.ttf")
const INK := Color("121d2c")
const PAPER := Color("fff2d3")
const GOLD := Color("ffca50")
const MINT := Color("69d8a4")
const CORAL := Color("ff7766")
const CARD_NAMES := ["overdrive_driver", "sand_cleats", "coin_magnet", "rangefinder_lens"]
static var textures: Dictionary = {}
static var materials: Dictionary = {}

static func texture(path: String) -> Texture2D:
	if not textures.has(path): textures[path] = load(ROOT + path + ".png")
	return textures[path] as Texture2D

static func sprite(path: String, at := Vector2.ZERO, dimensions := Vector2.ZERO) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = texture(path)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.position = at
	if dimensions != Vector2.ZERO: result.scale = dimensions / result.texture.get_size()
	return result

static func picture(path: String) -> TextureRect:
	var result := TextureRect.new()
	result.texture = texture(path)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func box(material: String, tint := Color.WHITE) -> StyleBoxTexture:
	# Native pixel UI construction; exact flat inks, 2-pixel steps, hard lower lip.
	# 9-slice margins protect the corner clusters at every supported viewport.
	if not materials.has(material):
		var colors: Array = {
			"felt": [Color("233747"), Color("50657a"), Color("152432")],
			"card": [Color("f7e6bc"), Color("fff7dd"), Color("b78a55")],
			"epic_card": [Color("ddc5f4"), Color("f7e6ff"), Color("8b5aba")],
			"scorepaper": [Color("f7e6bc"), Color("fff7dd"), Color("ad8653")],
			"benefit": [Color("194738"), MINT, Color("103229")],
			"curse": [Color("562c3e"), CORAL, Color("321d30")],
			"gold_button": [GOLD, Color("fff0a3"), Color("b96b29")],
			"teal_button": [Color("327b7b"), Color("82dfc0"), Color("214653")],
			"pressed": [Color("e4a438"), GOLD, Color("9c5428")],
			"disabled": [Color("59636c"), Color("939a9f"), Color("323a46")],
			"focus": [Color.TRANSPARENT, PAPER, Color.TRANSPARENT],
			"overdrive_driver": [Color("8a382f"), Color("eea56c"), Color("542937")],
			"sand_cleats": [Color("806024"), Color("e9bf68"), Color("483923")],
			"coin_magnet": [Color("245e62"), Color("62c5bd"), Color("1a3643")],
			"rangefinder_lens": [Color("4b315f"), Color("b18acf"), Color("2b2444")],
		}.get(material, [Color("233747"), Color("50657a"), Color("152432")])
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		image.fill_rect(Rect2i(2, 0, 28, 32), INK)
		image.fill_rect(Rect2i(0, 2, 32, 28), INK)
		image.fill_rect(Rect2i(2, 2, 28, 26), colors[1])
		image.fill_rect(Rect2i(3, 4, 26, 24), colors[0])
		image.fill_rect(Rect2i(2, 27, 28, 3), colors[2])
		if material == "focus":
			image.fill_rect(Rect2i(4, 4, 24, 24), Color.TRANSPARENT)
		image.resize(96, 96, Image.INTERPOLATE_NEAREST)
		materials[material] = ImageTexture.create_from_image(image)
	var result := StyleBoxTexture.new()
	result.texture = materials[material]
	result.modulate_color = tint
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		result.set_texture_margin(side, 15)
		result.set_expand_margin(side, 0)
		result.set_content_margin(side, 10)
	result.region_rect = Rect2(0, 0, 96, 96)
	result.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	result.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	result.set_texture_margin(SIDE_BOTTOM, 21)
	result.set_content_margin(SIDE_BOTTOM, 13)
	result.set_meta(&"arcade_material", true)
	return result

static func button(control: Button, primary := false) -> void:
	if not control: return
	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	control.add_theme_font_override("font", FONT)
	control.add_theme_font_size_override("font_size", 26)
	var material := "gold_button" if primary else "teal_button"
	control.add_theme_stylebox_override("normal", box(material))
	control.add_theme_stylebox_override("hover", box(material, Color(1.13, 1.13, 1.08)))
	control.add_theme_stylebox_override("pressed", box("pressed" if primary else "teal_button", Color(0.9, 0.9, 0.94)))
	control.add_theme_stylebox_override("disabled", box("disabled"))
	control.add_theme_stylebox_override("focus", box("focus"))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		control.add_theme_color_override(state, INK if primary else PAPER)
	control.add_theme_color_override("font_disabled_color", PAPER)
	if control is UIActionButton and control.action_icon: control.action_icon.hide()

static func symbol(kind: String) -> Texture2D:
	var key := "symbol/" + kind
	if textures.has(key): return textures[key]
	var pattern: Array = {
		"benefit": ["........", "...xx...", "...xx...", ".xxxxxx.", ".xxxxxx.", "...xx...", "...xx...", "........"],
		"curse": ["...xxx..", "..xxx...", ".xxxxxx.", "...xxx..", "..xxx...", "..xx....", ".xx.....", "........"],
		"stack": [".xxxxx..", ".x...xx.", ".x...xx.", ".x...xx.", ".xxxxxx.", "..xxxxx.", "........", "........"],
		"arrow": ["...x....", "...xx...", ".xxxxx..", ".xxxxxx.", ".xxxxx..", "...xx...", "...x....", "........"],
		"rarity_common": ["........", "...xx...", "..x..x..", ".x....x.", ".x....x.", "..x..x..", "...xx...", "........"],
		"rarity_epic": ["...xx...", "..xxxx..", ".xx..xx.", "xx.xx.xx", "xx.xx.xx", ".xx..xx.", "..xxxx..", "...xx..."],
	}.get(kind, ["..xxxx..", ".xxxxxx.", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", ".xxxxxx.", "..xxxx..", "........"])
	var image := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var ink := MINT if kind == "benefit" else (CORAL if kind == "curse" else PAPER)
	if kind.begins_with("rarity"): ink = INK
	for y in 8:
		for x in 8:
			if pattern[y][x] == "x":
				image.set_pixel(x + 2, y + 2, INK)
	for y in 8:
		for x in 8:
			if pattern[y][x] == "x": image.set_pixel(x + 1, y + 1, ink)
	textures[key] = ImageTexture.create_from_image(image)
	return textures[key]
