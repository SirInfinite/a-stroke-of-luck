extends Node
## Development-only optical sheet. Every mark at display AND actual HUD sizes.
## A SubViewport avoids desktop-resolution limits without changing game settings.

const Catalog := preload("res://scripts/ui/icon_catalog.gd")
const Style := preload("res://scripts/ui/ui_style.gd")
const Icon := preload("res://scripts/ui/ui_icon.gd")
const Logo := preload("res://scripts/ui/ui_logo.gd")
const Illustration := preload("res://scripts/ui/card_illustration.gd")
const Cards := preload("res://scripts/card_database.gd")
const DEST := "user://icon_brand_20260907/family"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DEST))
	for mode: StringName in [&"dark", &"light"]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1920, 1600)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		var root := ColorRect.new()
		root.size = Vector2(viewport.size)
		root.color = Style.PAPER if mode == &"light" else Style.INK_DEEP
		viewport.add_child(root)
		var logo := Logo.new()
		logo.position = Vector2(32, 5)
		root.add_child(logo)
		logo.custom_minimum_size = Vector2.ZERO
		logo.size = Vector2(600, 280)
		logo.appearance = mode
		var emblem := TextureRect.new()
		emblem.texture = preload("res://assets/ui/brand/emblem.svg")
		emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblem.position = Vector2(640, 55)
		emblem.size = Vector2(144, 144)
		root.add_child(emblem)
		_label(root, "THE CLUBHOUSE MARKS / " + String(mode).to_upper(), Vector2(820, 48), 30, mode)
		_label(root, "64-unit grid  /  flat ink  /  regular 64px + small 24px + small 16px", Vector2(820, 94), 22, mode)
		_label(root, "One symbol per meaning. Color reinforces shape and text.", Vector2(820, 130), 22, mode)
		_label(root, "APP / EXECUTABLE", Vector2(820, 234), 16, mode)
		var x := 1030.0
		for extent: int in [16, 32, 48, 128]:
			var app := TextureRect.new()
			app.texture = load("res://assets/ui/brand/app_icon_%d.png" % extent)
			app.position = Vector2(x, 224 - extent * 0.5)
			app.size = Vector2.ONE * extent
			root.add_child(app)
			x += float(extent) + 35.0
		var index := 0
		for id: StringName in Catalog.IDS:
			var origin := Vector2(28 + (index % 10) * 188, 290 + (index / 10) * 120)
			for tier: Dictionary in [{"size": 64, "x": 0}, {"size": 24, "x": 89}, {"size": 16, "x": 138}]:
				var icon := Icon.new()
				icon.configure(id)
				icon.icon_color = Style.appearance_color(icon.icon_color, &"foreground", mode)
				icon.custom_minimum_size = Vector2.ONE * float(tier.size)
				icon.position = origin + Vector2(tier.x, 32.0 - float(tier.size) / 2.0)
				icon.size = icon.custom_minimum_size
				root.add_child(icon)
			_label(root, String(id).replace("_", " "), origin + Vector2(0, 72), 16, mode)
			index += 1
		_label(root, "EQUIPMENT / THE SAME GLYPH, GIVEN ROOM", Vector2(28, 1253), 22, mode)
		index = 0
		for card in Cards.get_cards():
			var stock := PanelContainer.new()
			stock.position = Vector2(24 + index * 236, 1310)
			stock.size = Vector2(218, 190)
			stock.add_theme_stylebox_override("panel", Style.ticket_style(Style.PAPER.darkened(0.045), Style.PAPER_EDGE, 6, 1, 0))
			root.add_child(stock)
			var art := Illustration.new()
			art.configure(Style.card_icon(card.id), Style.PAPER, Style.card_accent(card.id))
			stock.add_child(art)
			_label(root, card.name, stock.position + Vector2(0, 200), 19, mode)
			index += 1
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var error := viewport.get_texture().get_image().save_png(DEST.path_join("family_%s.png" % mode))
		if error != OK:
			push_error("Family capture failed")
			get_tree().quit(1)
			return
		viewport.queue_free()
		await get_tree().process_frame
	print("[ICON FAMILY] two 1920x1600 sheets, 71 glyphs at 64/24/16px, logo, emblem and 8 centerpieces")
	get_tree().quit()


func _label(parent: Node, copy: String, origin: Vector2, font_size: int, mode: StringName) -> void:
	var label := Label.new()
	label.text = copy
	label.position = origin
	Style.apply_ui(label, font_size, Style.appearance_color(Style.PAPER, &"foreground", mode), true)
	parent.add_child(label)
