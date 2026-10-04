extends "res://tests/gameplay_direction_review.gd"
## Actual runtime captures with explicitly arranged starting positions.
## This scene is never used by the manual launcher.
var caption: Label

func _run() -> void:
	main = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.ball.wall_impact.connect(func(_strength: float, _point: Vector2) -> void: banks += 1)
	main.ball.elevation_changed.connect(func(_from: int, to: int, _point: Vector2) -> void: elevations.append(to))
	var canvas := CanvasLayer.new()
	canvas.layer = 30
	root.add_child(canvas)
	caption = Label.new()
	caption.position = Vector2(28, 174)
	caption.add_theme_font_size_override("font_size", 24)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(caption)
	var definitions := _strategy_definitions()
	var side := "before" if OS.get_cmdline_user_args().has("--before") else "after"
	await _load(definitions[0])
	caption.text = "%s | SCRIPTED RUNTIME REVIEW | original art, actual physics" % side.to_upper()
	main._toggle_course_overview()
	await _ticks(120)
	for phase in [0.0, 0.25]:
		await _arrange(definitions[0], Vector2(6, -1))
		caption.text = "A1 | arranged setup | same 65%% downward shot | %s" % ("release into the stone" if phase == 0.0 else "wait for the crossing window")
		main.level_builder.reset_dynamic_hazards()
		await _ticks(roundi(float(definitions[0].moving_hazards[0].period) * phase * 60.0))
		var row := await _shot("A1", "movie_phase_%.2f" % phase, Vector2.DOWN, 0.65)
		records.append(row)
		caption.text += " | resets: %s | strokes: %d" % [str(row.hazard_resets), row.strokes]
		await _ticks(75)
	await _arrange(definitions[6], Vector2(2, 4))
	caption.text = "C1 | arranged lower approach | one clear underpass, same elevation throughout"
	records.append(await _shot("C1", "movie_underpass", Vector2.RIGHT, 0.65))
	await _ticks(75)
	await _arrange(definitions[4], Vector2(3, 0))
	caption.text = "B2 | arranged fork setup | 38% entry feeds the recoverable pocket"
	records.append(await _shot("B2", "movie_pocket_entry", Vector2.RIGHT, 0.38))
	await _ticks(60)
	caption.text = "B2 | escape from that actual landing | no teleport between these shots"
	var model := AICourseModel.new()
	model.configure(main.level_builder, main.ball, main.run_state)
	var best := -INF
	var choice := {}
	for angle in range(-180, 180, 5):
		for power in [0.4, 0.6, 0.8, 1.0]:
			var direction := Vector2.RIGHT.rotated(deg_to_rad(angle))
			var forecast := model.predict(main.ball.global_position, 0, direction, power, 0.0, 1.0 / 60.0)
			if not forecast.reset and forecast.complete:
				var score := -model.remaining_distance(forecast.endpoint, 0)
				if score > best:
					best = score
					choice = {"direction": direction, "power": power}
	model.dispose()
	if choice.is_empty():
		failures.append("No pocket exit within fixed recording search")
	else:
		records.append(await _shot("B2", "movie_actual_pocket_escape", choice.direction, choice.power))
	await _ticks(90)
	_write(side + "/movie_events.json", {"records": records, "failures": failures, "arranged_starts": true, "actual_simulation": true})
	main.queue_free()
	canvas.queue_free()
	await process_frame
	print("DIRECTION_MOVIE_COMPLETE ", side, " failures=", failures)
	quit(0 if failures.is_empty() else 1)

func _ticks(count: int) -> void:
	for index in count:
		await physics_frame
