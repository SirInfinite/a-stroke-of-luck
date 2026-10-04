extends SceneTree
## Dense, timestamped presentation evidence from the normal Main and resolved data.
var main
var output := "res://artifacts/reference_review/reconstruction/feedback_cycle1"
var frames: Array[Dictionary] = []

func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1920,1080)
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	main = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	main._start_normal_run(8675309)
	main._load_level(0)
	for i in 30: await process_frame
	root.grab_focus()
	# Native input dispatch exercises pointer-to-world alignment and shot release.
	var start: Vector2 = main.ball.get_global_transform_with_canvas().origin
	var target: Vector2 = start - Vector2(160,0)
	var move := InputEventMouseMotion.new()
	move.position = start
	root.warp_mouse(start)
	Input.parse_input_event(move)
	for i in 4: await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = start
	press.pressed = true
	Input.parse_input_event(press)
	for i in 3: await process_frame
	print("POINTER_PRESS selected=", main.ball.selected, " world_mouse=", main.ball.get_global_mouse_position(), " ball=", main.ball.global_position, " screen=", start)
	root.warp_mouse(target)
	move.position = target
	Input.parse_input_event(move)
	for i in 10: await process_frame
	print("POINTER_DRAG selected=", main.ball.selected, " world_mouse=", main.ball.get_global_mouse_position())
	await _sequence("aim", 12)
	press = press.duplicate()
	press.pressed = false
	press.position = target
	Input.parse_input_event(press)
	await process_frame
	if main.run_state.strokes != 1:
		push_error("Native pointer shot failed; no motion evidence claimed")
		quit(1)
		return
	await _sequence("shot", 90)
	# Arrange an already resolved result through Main's authoritative handler.
	# This is a scripted outcome fixture, not evidence of a human sinking a putt.
	main._complete_current_hole(true, false)
	await _sequence("result", 66)
	var f := FileAccess.open(output.path_join("timeline.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"seed":8675309,"frames":frames,"kind":"scripted native input and resolved production outcome"},"\t"))
	main.queue_free()
	await process_frame
	quit()

func _sequence(label: String, count: int) -> void:
	var time := 0.0
	for index in count:
		await process_frame
		time += main.get_process_delta_time()
		await RenderingServer.frame_post_draw
		var filename := "%s_%03d.png" % [label,index]
		root.get_texture().get_image().save_png(output.path_join(filename))
		frames.append({"file":filename,"time":time,"phase":main.run_state.phase,"strokes":main.run_state.strokes,"wallet":main.run_state.tokens})
