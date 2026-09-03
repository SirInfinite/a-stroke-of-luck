class_name SettingsScreen
extends PanelContainer

signal close_requested
signal settings_changed(settings: GameSettings)

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const UIIconScript := preload("res://scripts/ui/ui_icon.gd")
const UIBackdropScript := preload("res://scripts/ui/ui_backdrop.gd")
const UIActionButtonScript := preload("res://scripts/ui/ui_action_button.gd")

var settings: GameSettings
var tabs: TabContainer
var window_mode_option: OptionButton
var resolution_option: OptionButton
var vsync_toggle: CheckButton
var screen_shake_slider: HSlider
var visual_effects_slider: HSlider
var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var master_mute: CheckButton
var music_mute: CheckButton
var sfx_mute: CheckButton
var shoot_binding_button: Button
var reset_binding_button: Button
var aim_sensitivity_slider: HSlider
var trajectory_toggle: CheckButton
var reduced_motion_toggle: CheckButton
var close_button: Button
var binding_status: Label
var _rebinding_action: StringName = &""
var _syncing := false


func setup(parent: CanvasLayer, current_settings: GameSettings) -> void:
	settings = current_settings
	name = "SettingsScreen"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_sync_from_settings()


func open() -> void:
	_sync_from_settings()
	visible = true
	if tabs:
		tabs.current_tab = 0
	if close_button:
		close_button.grab_focus()


func close() -> void:
	_rebinding_action = &""
	visible = false
	close_requested.emit()


func _input(event: InputEvent) -> void:
	if not visible or _rebinding_action == &"":
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()
	if event.keycode == KEY_ESCAPE:
		_rebinding_action = &""
		binding_status.text = "REBIND CANCELED"
		_sync_binding_labels()
		return
	if event.keycode <= 0:
		return
	if _rebinding_action == &"shoot":
		settings.shoot_keycode = event.keycode
	else:
		settings.reset_keycode = event.keycode
	_rebinding_action = &""
	binding_status.text = "CONTROL SAVED"
	_commit()
	_sync_binding_labels()


func _build() -> void:
	add_theme_stylebox_override("panel", UIStyleScript.panel_style(UIStyleScript.INK_DEEP, Color(UIStyleScript.FOCUS, 0.65), 0, 0, 0))
	var backdrop := UIBackdropScript.new()
	backdrop.name = "SettingsBackdrop"
	backdrop.configure(&"menu", UIStyleScript.FOCUS, UIStyleScript.INK_DEEP)
	add_child(backdrop)

	var safe := MarginContainer.new()
	safe.name = "SafeArea"
	safe.add_theme_constant_override("margin_left", 54)
	safe.add_theme_constant_override("margin_top", 38)
	safe.add_theme_constant_override("margin_right", 54)
	safe.add_theme_constant_override("margin_bottom", 38)
	add_child(safe)
	var panel := PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color(UIStyleScript.INK, 0.97), Color(UIStyleScript.FOCUS, 0.58), 22, 3, 14))
	safe.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 62.0
	header.add_theme_constant_override("separation", 14)
	layout.add_child(header)
	var icon := UIIconScript.new()
	icon.custom_minimum_size = Vector2(48.0, 48.0)
	icon.configure(&"control", UIStyleScript.PAPER, UIStyleScript.FOCUS)
	header.add_child(icon)
	var title := Label.new()
	title.text = "SETTINGS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyleScript.apply_display(title, 42, UIStyleScript.PAPER)
	header.add_child(title)
	close_button = UIActionButtonScript.new()
	close_button.custom_minimum_size = Vector2(190.0, 58.0)
	close_button.configure("BACK", &"menu", &"secondary")
	close_button.pressed.connect(close)
	header.add_child(close_button)

	tabs = TabContainer.new()
	tabs.name = "SettingsTabs"
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_override("font", UIStyleScript.UI_BOLD_FONT)
	tabs.add_theme_font_size_override("font_size", 18)
	layout.add_child(tabs)
	_build_video_tab()
	_build_audio_tab()
	_build_controls_tab()
	_build_accessibility_tab()


func _build_video_tab() -> void:
	var page := _create_page("VIDEO")
	window_mode_option = _add_option(page, "WINDOW MODE", ["WINDOWED", "FULLSCREEN"])
	window_mode_option.item_selected.connect(func(index: int) -> void:
		if _syncing:
			return
		settings.fullscreen = index == 1
		resolution_option.disabled = settings.fullscreen
		_commit()
	)
	var resolution_labels: Array[String] = []
	for size_value in GameSettings.RESOLUTIONS:
		resolution_labels.append("%d × %d" % [size_value.x, size_value.y])
	resolution_option = _add_option(page, "RESOLUTION", resolution_labels)
	resolution_option.item_selected.connect(func(index: int) -> void:
		if _syncing:
			return
		settings.resolution = GameSettings.RESOLUTIONS[clampi(index, 0, GameSettings.RESOLUTIONS.size() - 1)]
		_commit()
	)
	vsync_toggle = _add_toggle(page, "VSYNC")
	vsync_toggle.toggled.connect(func(enabled: bool) -> void:
		if not _syncing:
			settings.vsync_enabled = enabled
			_commit()
	)
	screen_shake_slider = _add_slider(page, "SCREEN SHAKE", 0.0, 100.0, 5.0)
	screen_shake_slider.value_changed.connect(func(value: float) -> void:
		if not _syncing:
			settings.screen_shake_intensity = value / 100.0
			_commit()
	)
	visual_effects_slider = _add_slider(page, "VISUAL EFFECTS", 0.0, 100.0, 5.0)
	visual_effects_slider.value_changed.connect(func(value: float) -> void:
		if not _syncing:
			settings.visual_effects_intensity = value / 100.0
			_commit()
	)


func _build_audio_tab() -> void:
	var page := _create_page("AUDIO")
	var master := _add_volume_row(page, "MASTER")
	master_slider = master.slider
	master_mute = master.mute
	var music := _add_volume_row(page, "MUSIC")
	music_slider = music.slider
	music_mute = music.mute
	var sfx := _add_volume_row(page, "SFX")
	sfx_slider = sfx.slider
	sfx_mute = sfx.mute
	master_slider.value_changed.connect(_on_volume_changed)
	music_slider.value_changed.connect(_on_volume_changed)
	sfx_slider.value_changed.connect(_on_volume_changed)
	master_mute.toggled.connect(_on_mute_changed)
	music_mute.toggled.connect(_on_mute_changed)
	sfx_mute.toggled.connect(_on_mute_changed)


func _build_controls_tab() -> void:
	var page := _create_page("CONTROLS")
	shoot_binding_button = _add_binding_row(page, "SHOOT / CONFIRM", &"shoot")
	reset_binding_button = _add_binding_row(page, "RESET HOLE", &"reset_level")
	aim_sensitivity_slider = _add_slider(page, "KEYBOARD AIM SPEED", 50.0, 200.0, 5.0)
	aim_sensitivity_slider.value_changed.connect(func(value: float) -> void:
		if not _syncing:
			settings.aim_sensitivity = value / 100.0
			_commit()
	)
	binding_status = Label.new()
	binding_status.text = "SELECT A CONTROL, THEN PRESS A KEY"
	UIStyleScript.apply_ui(binding_status, 14, UIStyleScript.PAPER_MUTED, true)
	page.add_child(binding_status)
	var reset_controls := UIActionButtonScript.new()
	reset_controls.custom_minimum_size = Vector2(260.0, 54.0)
	reset_controls.configure("RESET CONTROLS", &"restart", &"secondary")
	reset_controls.pressed.connect(_reset_controls)
	page.add_child(reset_controls)


func _build_accessibility_tab() -> void:
	var page := _create_page("GAMEPLAY + ACCESSIBILITY")
	trajectory_toggle = _add_toggle(page, "TRAJECTORY PREVIEW")
	trajectory_toggle.toggled.connect(func(enabled: bool) -> void:
		if not _syncing:
			settings.trajectory_visible = enabled
			_commit()
	)
	reduced_motion_toggle = _add_toggle(page, "REDUCED MOTION")
	reduced_motion_toggle.toggled.connect(func(enabled: bool) -> void:
		if not _syncing:
			settings.reduced_motion = enabled
			_commit()
	)
	var note := Label.new()
	note.text = "Reduced Motion removes camera movement and shortens decorative transitions."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyleScript.apply_ui(note, 15, UIStyleScript.PAPER_MUTED)
	page.add_child(note)


func _create_page(page_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = page_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 22)
	scroll.add_child(margin)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)
	return page


func _add_option(parent: VBoxContainer, label_text: String, values: Array[String]) -> OptionButton:
	var row := _setting_row(parent, label_text)
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(300.0, 52.0)
	option.add_theme_font_override("font", UIStyleScript.UI_BOLD_FONT)
	option.add_theme_font_size_override("font_size", 17)
	for value in values:
		option.add_item(value)
	row.add_child(option)
	return option


func _add_toggle(parent: VBoxContainer, label_text: String) -> CheckButton:
	var row := _setting_row(parent, label_text)
	var toggle := CheckButton.new()
	toggle.text = "ON"
	toggle.custom_minimum_size = Vector2(150.0, 52.0)
	toggle.add_theme_font_override("font", UIStyleScript.UI_BOLD_FONT)
	toggle.add_theme_font_size_override("font_size", 17)
	row.add_child(toggle)
	return toggle


func _add_slider(parent: VBoxContainer, label_text: String, minimum: float, maximum: float, step: float) -> HSlider:
	var row := _setting_row(parent, label_text)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(360.0, 48.0)
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.focus_mode = Control.FOCUS_ALL
	row.add_child(slider)
	return slider


func _add_volume_row(parent: VBoxContainer, label_text: String) -> Dictionary:
	var row := _setting_row(parent, label_text)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(320.0, 48.0)
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 2.0
	row.add_child(slider)
	var mute := CheckButton.new()
	mute.text = "MUTE"
	mute.custom_minimum_size = Vector2(130.0, 48.0)
	mute.add_theme_font_override("font", UIStyleScript.UI_BOLD_FONT)
	mute.add_theme_font_size_override("font_size", 15)
	row.add_child(mute)
	return {"slider": slider, "mute": mute}


func _add_binding_row(parent: VBoxContainer, label_text: String, action: StringName) -> Button:
	var row := _setting_row(parent, label_text)
	var button := UIActionButtonScript.new()
	button.custom_minimum_size = Vector2(280.0, 52.0)
	button.configure("—", &"control", &"secondary")
	button.pressed.connect(func() -> void:
		_rebinding_action = action
		binding_status.text = "PRESS A KEY  •  ESC TO CANCEL"
		_sync_binding_labels()
	)
	row.add_child(button)
	return button


func _setting_row(parent: VBoxContainer, label_text: String) -> HBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 66.0
	panel.add_theme_stylebox_override("panel", UIStyleScript.panel_style(Color(UIStyleScript.INK_DEEP, 0.76), Color(UIStyleScript.PAPER, 0.16), 12, 2, 2))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyleScript.apply_ui(label, 18, UIStyleScript.PAPER, true)
	row.add_child(label)
	return row


func _sync_from_settings() -> void:
	if not settings or not tabs:
		return
	_syncing = true
	window_mode_option.select(1 if settings.fullscreen else 0)
	resolution_option.select(maxi(GameSettings.RESOLUTIONS.find(settings.resolution), 0))
	resolution_option.disabled = settings.fullscreen
	vsync_toggle.button_pressed = settings.vsync_enabled
	screen_shake_slider.value = settings.screen_shake_intensity * 100.0
	visual_effects_slider.value = settings.visual_effects_intensity * 100.0
	master_slider.value = settings.master_volume * 100.0
	music_slider.value = settings.music_volume * 100.0
	sfx_slider.value = settings.sfx_volume * 100.0
	master_mute.button_pressed = settings.master_muted
	music_mute.button_pressed = settings.music_muted
	sfx_mute.button_pressed = settings.sfx_muted
	aim_sensitivity_slider.value = settings.aim_sensitivity * 100.0
	trajectory_toggle.button_pressed = settings.trajectory_visible
	reduced_motion_toggle.button_pressed = settings.reduced_motion
	_syncing = false
	_sync_binding_labels()


func _sync_binding_labels() -> void:
	if not shoot_binding_button or not reset_binding_button:
		return
	shoot_binding_button.text = "PRESS A KEY…" if _rebinding_action == &"shoot" else OS.get_keycode_string(settings.shoot_keycode)
	reset_binding_button.text = "PRESS A KEY…" if _rebinding_action == &"reset_level" else OS.get_keycode_string(settings.reset_keycode)


func _on_volume_changed(_value: float) -> void:
	if _syncing:
		return
	settings.master_volume = master_slider.value / 100.0
	settings.music_volume = music_slider.value / 100.0
	settings.sfx_volume = sfx_slider.value / 100.0
	_commit()


func _on_mute_changed(_enabled: bool) -> void:
	if _syncing:
		return
	settings.master_muted = master_mute.button_pressed
	settings.music_muted = music_mute.button_pressed
	settings.sfx_muted = sfx_mute.button_pressed
	_commit()


func _reset_controls() -> void:
	settings.shoot_keycode = KEY_SPACE
	settings.reset_keycode = KEY_R
	settings.aim_sensitivity = 1.0
	binding_status.text = "DEFAULT CONTROLS RESTORED"
	_commit()
	_sync_from_settings()


func _commit() -> void:
	settings.apply_runtime()
	var error := settings.save_to()
	if error != OK and binding_status:
		binding_status.text = "SETTINGS COULD NOT BE SAVED"
	settings_changed.emit(settings)
