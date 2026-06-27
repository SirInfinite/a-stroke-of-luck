extends Control

const GAME_SCENE := "res://scenes/main.tscn"

var how_to_play_panel: PanelContainer


func _ready() -> void:
	_create_background()
	_create_menu()


func _create_background() -> void:
	var background := ColorRect.new()
	background.color = Color(0.09, 0.18, 0.11)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)


func _create_menu() -> void:
	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 64)
	root_margin.add_theme_constant_override("margin_top", 48)
	root_margin.add_theme_constant_override("margin_right", 64)
	root_margin.add_theme_constant_override("margin_bottom", 48)
	add_child(root_margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 16)
	root_margin.add_child(layout)

	var title := Label.new()
	title.text = "A Stroke of Luck"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Top-down golf where every upgrade has a cost."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	layout.add_child(subtitle)

	var button_column := VBoxContainer.new()
	button_column.custom_minimum_size = Vector2(260, 0)
	button_column.add_theme_constant_override("separation", 10)
	layout.add_child(button_column)

	var start_button := _create_menu_button("Start Run")
	start_button.pressed.connect(_on_start_run_pressed)
	button_column.add_child(start_button)

	var how_to_play_button := _create_menu_button("How to Play")
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	button_column.add_child(how_to_play_button)

	var quit_button := _create_menu_button("Quit")
	quit_button.pressed.connect(_on_quit_pressed)
	button_column.add_child(quit_button)

	how_to_play_panel = _create_how_to_play_panel()
	how_to_play_panel.visible = false
	layout.add_child(how_to_play_panel)


func _create_menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 46)
	button.add_theme_font_size_override("font_size", 18)
	return button


func _create_how_to_play_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var text := Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 16)
	text.text = "Mouse aim: click the stopped ball, drag away from it, and release to shoot.\n" \
		+ "Keyboard aim: use left/right to turn, up/down to set power, then Space or Enter to shoot.\n" \
		+ "Strokes count when the ball finishes moving. Total strokes carry across holes.\n" \
		+ "Tokens are earned after sinking the ball based on score versus par.\n" \
		+ "Shop cards can be bought between holes. Each card gives an upgrade and a downside.\n" \
		+ "Hazards change the shot: sand slows the ball, water resets it, and direction pads push it."
	margin.add_child(text)

	return panel


func _on_start_run_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_how_to_play_pressed() -> void:
	how_to_play_panel.visible = not how_to_play_panel.visible


func _on_quit_pressed() -> void:
	get_tree().quit()
