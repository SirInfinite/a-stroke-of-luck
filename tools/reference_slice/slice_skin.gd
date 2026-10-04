extends Node
## Composes exclusive specialist adapters; no production scene or rules are replaced.

var main
var ui: Node
var world: Node2D
var fx_layer: CanvasLayer
var density := 48
var background_layer: CanvasLayer
var background: TextureRect
var title_picture: TextureRect
var shop_picture: TextureRect
var background_path := ""

func setup(owner_main) -> void:
	main = owner_main
	ui = load("res://tools/reference_slice/ui/reference_ui.gd").new()
	add_child(ui)
	ui.setup(main)
	background_layer = CanvasLayer.new()
	background_layer.layer = -20
	add_child(background_layer)
	background = _picture()
	background_layer.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.modulate = Color(0.56, 0.66, 0.66, 1.0)
	# A scenic screen behind shop controls covers enlarged leftover course fragments.
	# Canvas rendering only: course visibility/state/collisions remain untouched.
	var shop_layer := CanvasLayer.new()
	shop_layer.layer = 0
	add_child(shop_layer)
	shop_picture = _picture()
	shop_layer.add_child(shop_picture)
	shop_picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_picture.modulate = Color(0.54, 0.62, 0.64, 1.0)
	shop_picture.hide()
	# The scenic child moves with the existing title attract control. Native title
	# parallax/input/lifecycle remain active; pause still reveals the frozen course.
	title_picture = _picture()
	main.title_attract_mode.add_child(title_picture)
	title_picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_background(&"meadow")
	if "fx_layer" in ui: fx_layer = ui.fx_layer

func _picture() -> TextureRect:
	var result := TextureRect.new()
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	return result

func apply_hole() -> void:
	if is_instance_valid(world): world.queue_free()
	world = load("res://tools/reference_slice/world/reference_world.gd").new()
	world.density = density
	main.level_builder.level_root.add_child(world)
	world.setup(main)
	ui.apply_hole()
	_update_background(StringName(main.level_builder.active_level.get("biome_id", "meadow")))

func apply_shop(settle := true) -> void:
	ui.apply_shop()
	main.shop_manager.shop_destination_label.text = "THE OLD SWING · " + String(main.level_builder.active_level.get("biome_name", "Meadow"))
	if not main.shop_manager.continue_button.disabled:
		main.shop_manager.continue_button.text = "REPLAY SAMPLE"

func set_density(value: int) -> void:
	density = value
	if is_instance_valid(world): world.set_density(value)

func _update_background(biome: StringName) -> void:
	var script = load("res://tools/reference_slice/world/reference_world.gd")
	var next_path: String = script.background_path(biome)
	if next_path == background_path: return
	background_path = next_path
	background.texture = load(next_path)
	shop_picture.texture = background.texture
	title_picture.texture = load(script.background_path(&"meadow"))

func _process(_delta: float) -> void:
	if not main or not title_picture: return
	shop_picture.visible = main.shop_manager.shop_overlay.visible or main.interstitial_overlay.visible
	if main.shop_manager.shop_overlay.visible:
		main.shop_manager.shop_destination_label.text = "THE OLD SWING · " + String(main.level_builder.active_level.get("biome_name", "Meadow"))
		if not main.shop_manager.continue_button.disabled:
			main.shop_manager.continue_button.text = "REPLAY SAMPLE"
	if main.game_settings.reduced_motion:
		title_picture.position = Vector2(-12, -12)
	else:
		title_picture.position = Vector2(-12, -12) - main.title_attract_mode.parallax * 0.22
	# Overscan avoids background gaps during pointer parallax at every aspect.
	title_picture.size = main.get_viewport_rect().size + Vector2(24, 24)
