class_name RunSetupScreen
extends Control

signal start_requested(seed_value: int, difficulty_id: StringName)
signal close_requested

const DifficultyDatabaseScript := preload("res://scripts/difficulty_database.gd")
const SeedCodecScript := preload("res://scripts/seed_codec.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const UIBackdropScript := preload("res://scripts/ui/ui_backdrop.gd")
const UIActionButtonScript := preload("res://scripts/ui/ui_action_button.gd")
const UIIconScript := preload("res://scripts/ui/ui_icon.gd")

var settings: GameSettings
var selected_difficulty_id: StringName = DifficultyDatabaseScript.DEFAULT_ID
var difficulty_buttons := {}
var seed_input: LineEdit
var seed_status_label: Label
var start_button: Button
var back_button: Button
var settings_save_path := GameSettings.SAVE_PATH
var round_heading: Label


func setup(parent: CanvasLayer, game_settings: GameSettings) -> void:
	settings = game_settings
	selected_difficulty_id = settings.last_difficulty
	name = "RunSetupScreen"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func open(opponent_name := "") -> void:
	selected_difficulty_id = settings.last_difficulty if settings else DifficultyDatabaseScript.DEFAULT_ID
	round_heading.text = "18 HOLES  /  SIX BIOMES  /  YOUR CALL" if opponent_name.is_empty() else "VS %s  /  ONE SHARED COURSE" % opponent_name.to_upper()
	start_button.configure("START RUN" if opponent_name.is_empty() else "START MATCH", &"hole", &"primary")
	seed_status_label.text = "LEAVE BLANK FOR A RANDOM SEED"
	UIStyleScript.apply_ui(seed_status_label, 13, UIStyleScript.PAPER_MUTED, true)
	_refresh_difficulty_buttons()
	visible = true
	start_button.grab_focus()


func close() -> void:
	visible = false
	close_requested.emit()


func select_difficulty(difficulty_id: StringName) -> void:
	if not DifficultyDatabaseScript.is_valid_id(difficulty_id):
		return
	selected_difficulty_id = difficulty_id
	_refresh_difficulty_buttons()


func selected_profile() -> DifficultyProfile:
	return DifficultyDatabaseScript.get_profile(selected_difficulty_id)


func _build() -> void:
	var backdrop := UIBackdropScript.new()
	backdrop.name = "RunSetupBackdrop"
	backdrop.configure(&"menu", UIStyleScript.GOLD, UIStyleScript.INK_DEEP)
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var safe_area := MarginContainer.new()
	safe_area.name = "SafeArea"
	safe_area.add_theme_constant_override("margin_left", 54)
	safe_area.add_theme_constant_override("margin_top", 34)
	safe_area.add_theme_constant_override("margin_right", 54)
	safe_area.add_theme_constant_override("margin_bottom", 34)
	add_child(safe_area)
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	safe_area.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "RunSetupPanel"
	panel.custom_minimum_size = Vector2(1100.0, 700.0)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("panel", 6))
	center.add_child(panel)
	var panel_margin := MarginContainer.new()
	for side in ["left", "right"]:
		panel_margin.add_theme_constant_override("margin_%s" % side, 42)
	panel_margin.add_theme_constant_override("margin_top", 30)
	panel_margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(panel_margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 17)
	panel_margin.add_child(layout)

	var eyebrow := Label.new()
	round_heading = eyebrow
	eyebrow.text = "18 HOLES  /  SIX BIOMES  /  YOUR CALL"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyleScript.apply_ui(eyebrow, 14, UIStyleScript.GOLD, true)
	layout.add_child(eyebrow)
	var title := Label.new()
	title.text = "CHOOSE YOUR LUCK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyleScript.apply_display(title, 56, UIStyleScript.PAPER)
	layout.add_child(title)

	var difficulty_heading := Label.new()
	difficulty_heading.text = "DIFFICULTY"
	UIStyleScript.apply_ui(difficulty_heading, 15, UIStyleScript.FOCUS, true)
	layout.add_child(difficulty_heading)
	var difficulty_row := HBoxContainer.new()
	difficulty_row.alignment = BoxContainer.ALIGNMENT_CENTER
	difficulty_row.add_theme_constant_override("separation", 16)
	layout.add_child(difficulty_row)
	for profile in DifficultyDatabaseScript.get_profiles():
		var button := _create_difficulty_button(profile)
		difficulty_row.add_child(button)
		difficulty_buttons[profile.id] = button

	var seed_panel := PanelContainer.new()
	seed_panel.add_theme_stylebox_override("panel", UIStyleScript.pixel_frame("card", 4))
	layout.add_child(seed_panel)
	var seed_margin := MarginContainer.new()
	seed_margin.add_theme_constant_override("margin_left", 18)
	seed_margin.add_theme_constant_override("margin_top", 13)
	seed_margin.add_theme_constant_override("margin_right", 18)
	seed_margin.add_theme_constant_override("margin_bottom", 13)
	seed_panel.add_child(seed_margin)
	var seed_layout := VBoxContainer.new()
	seed_layout.add_theme_constant_override("separation", 7)
	seed_margin.add_child(seed_layout)
	var seed_heading := Label.new()
	seed_heading.text = "SEED"
	UIStyleScript.apply_ui(seed_heading, 14, UIStyleScript.FOCUS, true)
	seed_layout.add_child(seed_heading)
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 10)
	seed_layout.add_child(seed_row)
	seed_input = LineEdit.new()
	seed_input.name = "SeedInput"
	seed_input.placeholder_text = "BLANK = RANDOM"
	seed_input.max_length = 10
	seed_input.custom_minimum_size = Vector2(520.0, 52.0)
	seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_input.add_theme_font_override("font", UIStyleScript.UI_BOLD_FONT)
	seed_input.add_theme_font_size_override("font_size", UIStyleScript.text_size(18))
	seed_input.text_changed.connect(_on_seed_text_changed)
	seed_input.text_submitted.connect(func(_text: String) -> void: _on_start_pressed())
	seed_row.add_child(seed_input)
	var randomize_button := UIActionButtonScript.new()
	randomize_button.custom_minimum_size = Vector2(260.0, 52.0)
	randomize_button.configure("RANDOMIZE", &"randomize", &"secondary")
	randomize_button.pressed.connect(_on_randomize_pressed)
	seed_row.add_child(randomize_button)
	seed_status_label = Label.new()
	seed_status_label.name = "SeedStatus"
	seed_status_label.text = "LEAVE BLANK FOR A RANDOM SEED"
	seed_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIStyleScript.apply_ui(seed_status_label, 13, UIStyleScript.PAPER_MUTED, true)
	seed_layout.add_child(seed_status_label)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 16)
	layout.add_child(footer)
	back_button = UIActionButtonScript.new()
	back_button.custom_minimum_size = Vector2(260.0, 62.0)
	back_button.configure("BACK", &"back", &"secondary")
	back_button.pressed.connect(close)
	footer.add_child(back_button)
	start_button = UIActionButtonScript.new()
	start_button.custom_minimum_size = Vector2(420.0, 62.0)
	start_button.configure("START RUN", &"hole", &"primary")
	start_button.pressed.connect(_on_start_pressed)
	footer.add_child(start_button)
	_refresh_difficulty_buttons()


func _create_difficulty_button(profile: DifficultyProfile) -> Button:
	var button := Button.new()
	button.name = "%sDifficulty" % profile.display_name.capitalize()
	button.custom_minimum_size = Vector2(310.0, 264.0)
	button.tooltip_text = "%s\n%s" % [profile.display_name, profile.setup_summary()]
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 16)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var emblem := UIIconScript.new()
	emblem.custom_minimum_size = Vector2(54, 54)
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	emblem.configure(StringName("difficulty_" + String(profile.id)), UIStyleScript.PAPER, UIStyleScript.CURSE if profile.id == &"hard" else UIStyleScript.GOLD)
	column.add_child(emblem)
	var heading := Label.new()
	heading.text = profile.display_name
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyleScript.apply_display(heading, 32)
	column.add_child(heading)
	var summary := Label.new()
	summary.text = profile.setup_summary()
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyleScript.apply_ui(summary, 20, UIStyleScript.PAPER, true)
	column.add_child(summary)
	var selection := Label.new()
	selection.name = "Selection"
	selection.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyleScript.apply_ui(selection, 14, UIStyleScript.GOLD, true)
	column.add_child(selection)
	button.pressed.connect(select_difficulty.bind(profile.id))
	return button


func _refresh_difficulty_buttons() -> void:
	for profile in DifficultyDatabaseScript.get_profiles():
		var button := difficulty_buttons.get(profile.id) as Button
		if not button:
			continue
		var selected := profile.id == selected_difficulty_id
		button.add_theme_stylebox_override("normal", UIStyleScript.pixel_frame("primary" if selected else "card", 4))
		button.add_theme_stylebox_override("hover", UIStyleScript.pixel_frame("hover", 4))
		button.add_theme_stylebox_override("pressed", UIStyleScript.pixel_frame("pressed", 4))
		button.add_theme_stylebox_override("focus", UIStyleScript.pixel_frame("focus", 4))
		(button.find_child("Selection", true, false) as Label).text = "• SELECTED •" if selected else "SELECT"
		button.set_meta(&"selected", selected)


func _on_seed_text_changed(raw_text: String) -> void:
	var parsed := SeedCodecScript.parse_optional_seed(raw_text)
	seed_status_label.text = String(parsed.message)
	UIStyleScript.apply_ui(seed_status_label, 13, UIStyleScript.BONUS if bool(parsed.valid) else UIStyleScript.CURSE, true)


func _on_randomize_pressed() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	seed_input.text = SeedCodecScript.format_seed(rng.randi_range(1, SeedCodecScript.MAX_SEED))
	_on_seed_text_changed(seed_input.text)
	seed_input.grab_focus()
	seed_input.caret_column = seed_input.text.length()


func _on_start_pressed() -> void:
	var parsed := SeedCodecScript.parse_optional_seed(seed_input.text)
	_on_seed_text_changed(seed_input.text)
	if not bool(parsed.valid):
		seed_input.grab_focus()
		return
	if settings:
		settings.last_difficulty = selected_difficulty_id
		settings.save_to(settings_save_path)
	visible = false
	start_requested.emit(int(parsed.value), selected_difficulty_id)
