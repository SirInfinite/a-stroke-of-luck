extends Node
## Dev-only practice host. All shots, resets, hazards, scoring and menus use Main.
const Catalog := preload("res://tests/hazard_benchmarks.gd")
const MAIN := preload("res://scenes/main.tscn")
var selected := 0
var tier := 1
var main: Node2D
var panel: PanelContainer
var title: Label
var explanation: Label
var busy := false
var details := false
var selector: OptionButton
var art_reference := false

func _ready() -> void:
	if not OS.is_debug_build():
		get_tree().quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--benchmark="):
			selected = maxi(Catalog.IDS.find(argument.get_slice("=", 1).to_upper()), 0)
			art_reference = argument.get_slice("=", 1).to_upper() == "ART"
		elif argument.begins_with("--difficulty="):
			tier = maxi(["easy", "normal", "hard"].find(argument.get_slice("=", 1)), 0)
	main = MAIN.instantiate()
	add_child(main)
	_create_controls()
	load_benchmark()

func _create_controls() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 30
	add_child(canvas)
	panel = PanelContainer.new()
	# The existing HUD leaves this strip below its summary and left of Menu.
	# Expanded notes are opt-in, so they cannot cover a pocket/cup by default.
	panel.position = Vector2(20, 162)
	panel.custom_minimum_size = Vector2(1480, 0)
	panel.theme = main.RELEASE_THEME
	canvas.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	selector = OptionButton.new()
	for index in Catalog.IDS.size():
		selector.add_item("%s  %s" % [Catalog.IDS[index], Catalog.NAMES[index]])
	selector.add_item("ART  The Old Swing")
	selector.item_selected.connect(_select)
	buttons.add_child(selector)
	for item in [["Previous [F6]", -1], ["Next [F7]", 1]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(_change.bind(int(item[1])))
		buttons.add_child(button)
	var difficulty_button := Button.new()
	difficulty_button.text = "Difficulty [F8]"
	difficulty_button.pressed.connect(_change_tier)
	buttons.add_child(difficulty_button)
	var retry := Button.new()
	retry.text = "New attempt [F9]"
	retry.pressed.connect(load_benchmark)
	buttons.add_child(retry)
	var help_button := Button.new()
	help_button.text = "Brief [H]"
	help_button.pressed.connect(_toggle_details)
	buttons.add_child(help_button)
	title = Label.new()
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	explanation = Label.new()
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.custom_minimum_size.x = 1450
	explanation.add_theme_font_size_override("font_size", 17)
	explanation.visible = details
	box.add_child(explanation)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F6: _change(-1)
		KEY_F7: _change(1)
		KEY_F8: _change_tier()
		KEY_F9: load_benchmark()
		KEY_F10: _select(Catalog.IDS.size())
		KEY_H: _toggle_details()
		_: return
	get_viewport().set_input_as_handled()

func _change(step: int) -> void:
	if busy:
		return
	selected = posmod(selected + step, Catalog.IDS.size())
	art_reference = false
	load_benchmark()

func _select(index: int) -> void:
	if busy:
		return
	art_reference = index == Catalog.IDS.size()
	if not art_reference:
		selected = index
	load_benchmark()

func _change_tier() -> void:
	if busy:
		return
	tier = (tier + 1) % 3
	load_benchmark()

func _toggle_details() -> void:
	details = not details
	explanation.visible = details
	panel.reset_size()

func load_benchmark() -> void:
	if busy:
		return
	busy = true
	var level := Catalog.build(Catalog.IDS[selected], [&"easy", &"normal", &"hard"][tier])
	if art_reference:
		# Exact physical fixture used by the visual thread, loaded read-only.
		level = preload("res://tools/pixel_sample/sample_level.gd").create()
		level["benchmark_id"] = "ART"
		level["benchmark_name"] = "The Old Swing (shared art reference)"
		level["benchmark_notes"] = {"decision": "Shared Meadow reference: the exact course used by the art correction, with existing runtime art here.", "skill": "Compare the same tee, cup, bank, surfaces and 88-unit stone in both threads.", "consequence": "Ordinary water, pendulum and bounce-pad rules apply.", "recovery": "Use the clear lower region to line up a bank or another approach.", "variation": "Unmodified companion reference; outside the nine revised family variants. Difficulty does not retune this art fixture."}
	if not LevelValidator.validate_level(level, 0):
		title.text = "Benchmark rejected by validation: " + Catalog.IDS[selected]
		busy = false
		return
	main._hide_main_menu()
	main._hide_interstitial()
	main._reset_run_state(int(level.run_seed))
	main.run_state.difficulty_profile = DifficultyDatabase.get_profile([&"easy", &"normal", &"hard"][tier])
	main.biome_profiles = BiomeDatabase.get_profiles()
	# Repeating slots let Main's ordinary result/continue path keep practicing the
	# selected fixture. They are practice rounds, not an altered production run.
	for n in 18:
		main.run_state.normal_levels.append(level.duplicate(true))
	main.run_state.levels = main.run_state.normal_levels.duplicate(true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	main._load_level(0)
	main.audio_controller.set_biome(int(level.biome_index))
	main.ball.keyboard_direction = Vector2.RIGHT
	selector.select(Catalog.IDS.size() if art_reference else selected)
	title.text = "%s | %s — %s | %s | seed %d | Tab: overview | H: brief" % ["ART REFERENCE" if art_reference else "PRACTICE %d / 9" % (selected + 1), level.benchmark_id, level.benchmark_name, "FIXED" if art_reference else ["EASY", "NORMAL", "HARD"][tier], level.run_seed]
	explanation.text = "%s\n%s\n%s\n%s\n%s\nDrag or arrows + Shoot. R: reset (strokes kept). F9: fresh attempt. H: close brief." % [level.benchmark_notes.decision, level.benchmark_notes.skill, level.benchmark_notes.consequence, level.benchmark_notes.recovery, level.benchmark_notes.variation]
	panel.reset_size()
	busy = false
