extends "res://tools/pixel_sample/pixel_sample.gd"
## Matched A/B capture and playable candidate; the production scene stays native.

var previous := false
var hazard_capture_pending := false

func _ready() -> void:
	previous = "--correction-previous" in OS.get_cmdline_user_args()
	baseline = false # A is the prior PIXEL sample, not the earlier vector game.
	output_dir = "res://artifacts/pixel_correction/" + ("previous" if previous else "revised")
	super._ready()
	get_window().title = "A Stroke of Luck — " + ("A: previous pixel sample" if previous else "B: arcade correction sample")

func _make_skin() -> Node:
	if previous: return super._make_skin()
	return preload("res://tools/pixel_correction/arcade_skin.gd").new()

func _feedback_script() -> Script:
	if previous: return super._feedback_script()
	return preload("res://tools/pixel_correction/arcade_feedback.gd")

func _event(kind: String, data: Dictionary) -> void:
	super._event(kind, data)
	if kind == "hazard" and automate and not hazard_capture_pending:
		hazard_capture_pending = true
		_capture_hazard.call_deferred()

func _capture_hazard() -> void:
	await _capture("03c_hazard_contact")

func _run_recording() -> void:
	await _frames(90)
	await _capture("01_title")
	_start_hole()
	await _frames(90)
	main.camera.toggle_overview()
	await _frames(45)
	await _capture("02_hole")
	main.camera.toggle_overview()
	await _frames(45)
	_aim(Vector2.LEFT, 0.45)
	await _frames(45)
	await _capture("03_aim")
	_strike(Vector2.LEFT, 0.45)
	await _frames(310)
	_event("bank_stop", {"position": main.ball.position})
	_aim(Vector2(0.4, -1), 0.28)
	await _frames(45)
	await _capture("03b_hazard_aim")
	_strike(Vector2(0.4, -1), 0.28)
	await _frames(330)
	_event("hazard_stop", {"position": main.ball.position})
	await _frames(60)
	_aim(Vector2.RIGHT, 0.75)
	await _frames(45)
	_strike(Vector2.RIGHT, 0.75)
	await _frames(360)
	_event("approach_stop", {"position": main.ball.position, "phase": main.run_phase})
	await _capture("04_outcome")
	if main.run_phase != RunState.Phase.HOLE_RESULTS:
		push_error("Correction replay did not reach real hole results.")
		get_tree().quit(1)
		return
	main._on_interstitial_continue_pressed()
	skin.apply_shop()
	await _frames(80)
	await _capture("05_shop")
	var card: UICard = main.shop_manager.shop_card_buttons[0]
	card.focus_entered.emit()
	await _frames(8)
	await _capture("05b_hover")
	var buy: Button = card.card_layout.get_node("SampleBuy")
	buy.button_down.emit()
	await _frames(2)
	await _capture("05c_press")
	buy.button_up.emit()
	buy.pressed.emit()
	await _frames(10)
	await _capture("06_purchase_contact")
	await _frames(9)
	await _capture("06b_tradeoff_feedback")
	await _frames(51)
	await _capture("07_purchased")
	await _frames(90)
	var report := {"treatment": "previous" if previous else "revised", "frames": frame, "events": events, "captures": captures, "size": desired_size, "physics_unchanged": physics_unchanged}
	FileAccess.open(output_dir.path_join("events.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("[CORRECTION REPLAY] DONE " + JSON.stringify(report))
	main.audio_controller.stop_all_audio()
	await _frames(6)
	get_tree().quit()

func _review_controls() -> void:
	super._review_controls()
	# Only the review overlay describes the comparison; product UI stays concise.
	for layer in get_children():
		if layer is CanvasLayer and layer.layer == 40:
			for child in layer.get_children():
				if child is Label and child.text.begins_with("PRESENTATION SAMPLE"):
					child.text = ("A · PREVIOUS PIXEL SAMPLE" if previous else "B · ARCADE CORRECTION SAMPLE") + "   ·   F5 retry   ·   F7 shop   ·   F8 title"
