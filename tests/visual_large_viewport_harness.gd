extends Node

const MainScene := preload("res://scenes/main.tscn")
const LARGE_SIZE := Vector2i(2560, 1440)
const ULTRAWIDE_SIZE := Vector2i(3440, 1440)
const SAFE_SEED := 486271

var large_viewport: SubViewport
var preview: TextureRect
var main: Node
var view_state := 0
var logical_width := LARGE_SIZE.x


func _ready() -> void:
	var backfill := ColorRect.new()
	backfill.name = "Backfill"
	backfill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backfill.color = Color("101716")
	backfill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backfill)

	large_viewport = SubViewport.new()
	large_viewport.name = "LargeViewport"
	large_viewport.size = LARGE_SIZE
	large_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	large_viewport.handle_input_locally = false
	add_child(large_viewport)

	main = MainScene.instantiate()
	main.name = "Main"
	large_viewport.add_child(main)

	preview = TextureRect.new()
	preview.name = "Preview"
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.texture = large_viewport.get_texture()
	add_child(preview)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode != KEY_ENTER:
		return
	get_viewport().set_input_as_handled()
	view_state += 1
	match view_state:
		1:
			large_viewport.size = ULTRAWIDE_SIZE
			logical_width = ULTRAWIDE_SIZE.x
		2:
			_show_ultrawide_course.call_deferred()


func _show_ultrawide_course() -> void:
	main._start_normal_run(SAFE_SEED)
	await get_tree().process_frame
	main._load_level(0)
