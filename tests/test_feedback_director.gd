extends GutTest

const BALL_SCENE := preload("res://scenes/golf_ball.tscn")
const FeedbackDirectorScript := preload("res://scripts/feedback_director.gd")


func test_shot_feedback_starts_trail_impulse_and_sound_hook() -> void:
	var setup := _spawn_feedback()
	var director = setup.director
	watch_signals(director)

	director.play_shot_feedback(Vector2(120.0, 80.0), Vector2.RIGHT, 0.8)

	assert_eq(director.last_feedback_kind, &"shot")
	assert_true(director.trail.visible)
	assert_eq(director.trail.points.size(), 1)
	assert_gt(setup.camera.offset.length(), 0.0)
	assert_gt(director.transient_root.get_child_count(), 0)
	assert_signal_emitted_with_parameters(director, "sound_requested", [&"golf_strike", 0.8])


func test_terrain_feedback_reuses_palette_specific_effects_and_audio_cues() -> void:
	var setup := _spawn_feedback()
	var director = setup.director
	watch_signals(director)
	director.configure_level({
		"biome_id": &"snow",
		"terrain_palette": {
			"sand": Color("d8e5ea"),
			"sand_detail": Color("ffffff"),
			"water": Color("7fc7e8"),
			"water_detail": Color("d8f4ff"),
		}
	})

	director.play_terrain_feedback(&"sand", Vector2.ZERO)
	assert_eq(director.last_feedback_kind, &"sand")
	assert_signal_emitted_with_parameters(director, "sound_requested", [&"terrain_impact", director.terrain_burst_intensity])
	director.play_terrain_feedback(&"water", Vector2.ZERO)
	assert_eq(director.last_feedback_kind, &"water")
	assert_signal_emitted_with_parameters(director, "sound_requested", [&"water", director.terrain_burst_intensity])
	assert_gt(director.transient_root.get_child_count(), 0)


func test_cup_and_progression_feedback_cover_final_completion() -> void:
	var setup := _spawn_feedback()
	var director = setup.director
	watch_signals(director)

	director.play_cup_feedback(Vector2(200.0, 100.0), true)
	assert_eq(director.last_feedback_kind, &"final_cup")
	assert_true(director.screen_flash.visible)
	assert_signal_emitted_with_parameters(director, "sound_requested", [&"cup_sink", 1.0])

	director.play_progression_feedback(&"final_completion", Color.WHITE)
	assert_eq(director.last_feedback_kind, &"final_completion")
	assert_signal_emitted_with_parameters(director, "sound_requested", [&"final_run_completion", 1.0])
	director.play_progression_feedback(&"ending_transition", Color("17221f"))
	assert_eq(director.last_feedback_kind, &"ending_transition")


func _spawn_feedback() -> Dictionary:
	var root := Node2D.new()
	add_child_autofree(root)
	var camera := Camera2D.new()
	root.add_child(camera)
	var ball = BALL_SCENE.instantiate()
	root.add_child(ball)
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	var director = FeedbackDirectorScript.new()
	root.add_child(director)
	director.setup(ball, camera, canvas)
	return {"director": director, "camera": camera, "ball": ball}
