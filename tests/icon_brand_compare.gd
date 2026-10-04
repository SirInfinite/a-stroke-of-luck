extends Node
## Before/after evidence only. Reads captures from the actual Main review and
## writes comparison sheets under user://; does not manufacture replacement UI.

const Style := preload("res://scripts/ui/ui_style.gd")
const ROOT := "user://icon_brand_20260907/"
const PAIRS := [
	["TITLE / WORDMARK", "01_title", "01_title"],
	["GAMEPLAY / HUD", "09_gameplay_0", "09_gameplay_0"],
	["SHOP", "10_shop_normal", "10_shop_normal"],
	["CARD FAMILY / RARITY", "19_all_rarities", "23_equipment_rarities_0"],
	["SETTINGS", "02_settings_0", "02_settings_0"],
	["RUN RESULTS", "16_run_results", "16_run_results"],
]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	for page in range(2):
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1920, 1770)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		var background := ColorRect.new()
		background.size = Vector2(viewport.size)
		background.color = Style.INK_DEEP
		viewport.add_child(background)
		for row in range(3):
			var pair: Array = PAIRS[page * 3 + row]
			for column in range(2):
				var label := Label.new()
				label.text = "%s / %s" % [pair[0], "BEFORE" if column == 0 else "AFTER"]
				label.position = Vector2(column * 960 + 20, row * 590 + 8)
				Style.apply_ui(label, 22, Style.PAPER, true)
				background.add_child(label)
				var filename: String = ROOT + ("before/1280x720/" + pair[1] if column == 0 else "after/dark/1280x720/" + pair[2]) + ".png"
				var image := Image.load_from_file(filename)
				if image == null:
					push_error("Missing comparison capture: " + filename)
					get_tree().quit(1)
					return
				var picture := TextureRect.new()
				picture.texture = ImageTexture.create_from_image(image)
				picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
				picture.position = Vector2(column * 960, row * 590 + 44)
				picture.size = Vector2(960, 540)
				background.add_child(picture)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var error := viewport.get_texture().get_image().save_png(ROOT + "comparison_%d.png" % (page + 1))
		if error != OK:
			push_error("Cannot save comparison")
			get_tree().quit(1)
			return
		viewport.queue_free()
		await get_tree().process_frame
	print("[ICON COMPARISON] Six actual before/after screen pairs, two sheets")
	get_tree().quit()
