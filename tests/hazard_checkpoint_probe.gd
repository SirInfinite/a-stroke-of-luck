extends "res://tests/hazard_checkpoint_review.gd"
## Bounded diagnostics, followed by real shots. Arranged starts are labelled.

func _physics() -> void:
	main = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.ball.wall_impact.connect(func(_strength: float, _point: Vector2) -> void: banks += 1)
	main.ball.elevation_changed.connect(func(_from: int, to: int, _point: Vector2) -> void: elevations.append(to))
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 64
	if OS.get_cmdline_user_args().has("--strategies"):
		await _strategies()
	else:
		await _bank_probes()
		await _timing_probes()
		await _recoveries()
		await _ice_probe()
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	Engine.max_physics_steps_per_frame = 8
	var suffix := "strategies" if OS.get_cmdline_user_args().has("--strategies") else "probes"
	if OS.get_cmdline_user_args().has("--baseline"):
		suffix = "baseline_" + suffix
	var file := FileAccess.open(OUTPUT + "/checkpoint_" + suffix + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"records": records, "failures": failures, "simulation": "Actual Main/GolfBall; 1/60 physics delta; arranged starts explicitly labelled"}, "\t"))
	main.queue_free()
	await process_frame
	print("HAZARD_PROBES_COMPLETE %s records=%d failures=%s" % [suffix, records.size(), str(failures)])

func _arrange(level: Dictionary, raw_cell: Vector2, layer := 0) -> void:
	await _load(level)
	var point: Vector2 = main.level_builder.level_point(level, "start", "start_cell") + raw_cell * 100.0
	main.ball.reset_to(point, layer, false)
	main.last_safe_shot_position = point
	main.last_safe_shot_elevation = layer
	await physics_frame
	await physics_frame

func _bank_probes() -> void:
	for id in ["A1", "A2", "A3"]:
		var level := Catalog.build(id)
		var origin_cell: Vector2 = Vector2(level.benchmark_setup_cell - level.start_cell)
		await _arrange(level, origin_cell)
		var model := AICourseModel.new()
		model.configure(main.level_builder, main.ball, main.run_state)
		var start: Vector2 = main.ball.global_position
		var before := model.remaining_distance(start, 0)
		var best := {}
		var score := -INF
		# 360 candidates maximum, using only a query body and copied metadata.
		for angle in range(-180, 180, 5):
			for power in [0.35, 0.5, 0.65, 0.8, 1.0]:
				var direction := Vector2.RIGHT.rotated(deg_to_rad(angle))
				var forecast := model.predict(start, 0, direction, power, 0.0, 1.0 / 60.0)
				if forecast.reset or not forecast.complete or forecast.bounces < 1:
					continue
				var progress := before - model.remaining_distance(forecast.endpoint, int(forecast.elevation))
				if progress > score:
					score = progress
					best = {"angle": angle, "power": power, "forecast": forecast, "route_progress_px": progress}
		model.dispose()
		if best.is_empty():
			failures.append(id + " no bank witness")
		else:
			var row := await _shot(id, "arranged_bank_witness", Vector2.RIGHT.rotated(deg_to_rad(best.angle)), best.power, best)
			records.append(row)
		print("BANK_PROBE ", id, " predicted progress=", score)

func _timing_probes() -> void:
	var cases := {"A1": Vector2(6, -1), "A2": Vector2(8, -1), "A3": Vector2(7, 0), "C1": Vector2(5, 1), "C3": Vector2(5, 1)}
	for id in cases:
		var level := Catalog.build(id)
		for sample in 16:
			await _arrange(level, cases[id])
			var mover: MovingHazard
			for node in main.level_builder.level_root.get_children():
				if node is MovingHazard:
					mover = node
			# Reset the native phase, then let real physics advance the wait.
			main.level_builder.reset_dynamic_hazards()
			var delay := sample * mover.period / 16.0
			for tick in roundi(delay * 60.0):
				await physics_frame
			var elapsed := mover.elapsed
			var row := await _shot(id, "arranged_timing_%02d" % sample, Vector2.DOWN, 0.65)
			row["release_elapsed"] = elapsed
			row["wait_seconds"] = delay
			records.append(row)
		print("TIMING_PROBE ", id, " complete")

func _recoveries() -> void:
	for id in ["C1", "C3"]:
		var level := Catalog.build(id)
		await _arrange(level, Vector2(2, 4 if id == "C1" else 5))
		var row := await _shot(id, "arranged_underpass", Vector2.RIGHT, 0.65)
		records.append(row)
		if row.endpoint.x - row.origin.x < 420.0 or not row.elevation_changes.is_empty() or not row.hazard_resets.is_empty():
			failures.append(id + " lower crossing did not clear on its own layer")
	for id in ["B1", "B2", "B3"]:
		var level := Catalog.build(id)
		await _arrange(level, Vector2(level.benchmark_setup_cell - level.start_cell))
		var first := await _shot(id, "arranged_pocket_entry", Vector2.RIGHT, 0.38)
		records.append(first)
		# This escape starts from the actual stopped ball; no reset/teleport.
		var model := AICourseModel.new()
		model.configure(main.level_builder, main.ball, main.run_state)
		var best := -INF
		var choice := {}
		for angle in range(-180, 180, 5):
			for power in [0.4, 0.6, 0.8, 1.0]:
				var direction := Vector2.RIGHT.rotated(deg_to_rad(angle))
				var forecast := model.predict(main.ball.global_position, 0, direction, power, 0.0, 1.0 / 60.0)
				if forecast.reset or not forecast.complete:
					continue
				var score := -model.remaining_distance(forecast.endpoint, 0)
				if score > best:
					best = score
					choice = {"direction": direction, "power": power, "forecast": forecast}
		model.dispose()
		if choice.is_empty():
			failures.append(id + " no pocket escape found within diagnostic budget")
			continue
		var second := await _shot(id, "pocket_escape_from_actual_landing", choice.direction, choice.power, choice.forecast)
		records.append(second)
		if not second.hazard_resets.is_empty() or second.strokes != 2 or second.endpoint.distance_to(second.origin) < 180.0:
			failures.append(id + " pocket escape failed")

func _ice_probe() -> void:
	# Same flat lane, cup deliberately off the measured line. Long enough that
	# walls do not turn extra glide into an apparently accurate rebound.
	for type in ["normal", "ice"]:
		var level := {"map": ["########################################", "########################################", "########################################", "########################################", "########################################"], "start_cell": Vector2i(2, 2), "hole_cell": Vector2i(37, 0), "par": 4, "hazards": [], "obstacles": [], "moving_hazards": [], "run_seed": 910900, "run_difficulty_id": "normal"}
		if type == "ice":
			# 500 px segment entered after 450 px of ordinary ground (438 px
			# for the leading edge of the 12 px ball). Low powers miss it.
			level.hazards.append({"type": "ice", "pos": Vector2(-1050, 0), "size": Vector2(500, 100), "intensity": 0.22, "elevation": 0})
		for power in [0.3, 0.35, 0.4, 0.65, 1.0]:
			await _load(level)
			var forecast: Dictionary = main.ball.get_trajectory_prediction_for_power(Vector2.RIGHT, power)
			records.append(await _shot("surface_" + type, "matched_surface_%.2f" % power, Vector2.RIGHT, power, forecast))

func _strategy_definitions() -> Array:
	var definitions: Array = []
	if OS.get_cmdline_user_args().has("--baseline"):
		var file := FileAccess.open(OUTPUT + "/baseline_fixtures.dat", FileAccess.READ)
		for level: Dictionary in file.get_var():
			# Three run positions for each difficulty; same seed, nine real holes.
			if int(level.overall_hole_number) in [3, 10, 18]:
				definitions.append(level)
	else:
		for id in Catalog.IDS:
			definitions.append(Catalog.build(id))
	return definitions

func _strategies() -> void:
	for level: Dictionary in _strategy_definitions():
		var id := String(level.get("benchmark_id", "%s_%02d" % [level.get("run_difficulty_id"), level.get("overall_hole_number")]))
		for strategy in ["naive_full", "power_aware", "angle_full", "route_timing"]:
			await _load(level)
			main.level_builder.reset_dynamic_hazards()
			var model := AICourseModel.new()
			model.configure(main.level_builder, main.ball, main.run_state)
			var shots: Array[Dictionary] = []
			var interrupted_waits: Array[Dictionary] = []
			for shot_index in 12:
				if not main.ball.can_shoot():
					break
				model.refresh(main.level_builder, main.ball, main.run_state)
				var origin: Vector2 = main.ball.global_position
				var layer: int = main.ball.current_elevation
				var direction := origin.direction_to(model.cup)
				var power := 1.0
				var wait_time := 0.0
				if strategy == "power_aware":
					var best := -INF
					# Same direct aim; only power varies, using the shared simulation.
					for index in 20:
						var candidate_power := (index + 1) / 20.0
						var predicted := model.predict(origin, layer, direction, candidate_power)
						var score := -model.remaining_distance(predicted.endpoint, int(predicted.elevation)) - (100000.0 if predicted.reset else 0.0) + (100000.0 if predicted.sunk else 0.0)
						if score > best:
							best = score
							power = candidate_power
				elif strategy == "angle_full":
					var best := -INF
					# Stronger diagnostic: searches angles but always shoots at full
					# power immediately. This is not the direct-to-cup straw man.
					for angle in range(-180, 180, 5):
						var candidate_direction := Vector2.RIGHT.rotated(deg_to_rad(angle))
						var predicted := model.predict(origin, layer, candidate_direction, 1.0, 0.0, 1.0 / 60.0)
						var score := -model.remaining_distance(predicted.endpoint, int(predicted.elevation)) - (100000.0 if predicted.reset else 0.0) + (100000.0 if predicted.sunk else 0.0)
						if score > best:
							best = score
							direction = candidate_direction
				elif strategy == "route_timing":
					var profile := AIDifficultyProfile.get_profile(&"nicklaus")
					var choice := AIShotPlanner.new().plan(model, origin, layer, profile, 1000 + shot_index)
					direction = choice.direction
					power = choice.power
					wait_time = AIShotPlanner.AIM_TIME + float(choice.wait)
				for tick in roundi(wait_time * 60.0):
					await physics_frame
				# A moving stone can hit a stationary golfer during a planned wait.
				# Keep that real penalty, and never fire a stale plan from the tee or
				# report a ceiling reached during the wait as a rejected shot.
				if main.ball.sunk or not main.ball.can_shoot() or main.ball.global_position.distance_to(origin) > 1.0:
					interrupted_waits.append({"origin": origin, "wait_seconds": wait_time, "strokes": main.run_state.strokes, "position": main.ball.global_position})
					for tick in 300:
						if main.ball.can_shoot() or main.ball.sunk:
							break
						await physics_frame
					continue
				var row := await _shot(id, strategy, direction, power)
				row["wait_seconds"] = wait_time
				shots.append(row)
				await physics_frame
				if main.ball.sunk or main.run_state.strokes >= int(level.par) + RunState.STROKES_OVER_PAR:
					break
			model.dispose()
			var completed: bool = main.ball.sunk and main.run_state.strokes < int(level.par) + RunState.STROKES_OVER_PAR
			records.append({"id": id, "strategy": strategy, "cup_completed": completed, "strokes": main.run_state.strokes, "shots": shots, "interrupted_waits": interrupted_waits, "ceiling": int(level.par) + RunState.STROKES_OVER_PAR})
			print("STRATEGY ", id, " ", strategy, " completed=", completed, " strokes=", main.run_state.strokes)
