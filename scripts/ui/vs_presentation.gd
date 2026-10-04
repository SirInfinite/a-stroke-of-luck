class_name VsPresentation
extends Control
## Presentation only: intents upward, snapshots downward.
signal mode_selected(vs_ai: bool)
signal opponent_selected(id: StringName)
signal back_requested
signal continue_requested
signal rematch_requested
signal new_opponent_requested
signal menu_requested
signal speed_requested(speed: int)
signal skip_requested
const Style := preload("res://scripts/ui/ui_style.gd")
const Backdrop := preload("res://scripts/ui/ui_backdrop.gd")
const Illustration := preload("res://scripts/ui/card_illustration.gd")
var page: PanelContainer
var backdrop: UIBackdrop
var content: VBoxContainer
var match_bar: PanelContainer
var match_copy: Label
var thinking_copy: Label
var controls: HBoxContainer
var page_id: StringName = &""


func setup(parent: CanvasLayer, shared_theme: Theme) -> void:
	name = "Versus"
	parent.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = shared_theme
	page = PanelContainer.new()
	page.name = "MatchScreen"
	add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	page.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	backdrop = Backdrop.new()
	backdrop.name = "MatchBackdrop"
	backdrop.configure(&"menu", Style.GOLD, Style.INK_DEEP)
	page.add_child(backdrop)
	var safe := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		safe.add_theme_constant_override("margin_" + side, 40)
	page.add_child(safe)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	safe.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var sheet := PanelContainer.new()
	sheet.name = "MatchPanel"
	sheet.add_theme_stylebox_override("panel", Style.pixel_frame("panel", 30))
	center.add_child(sheet)
	content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(1120, 0)
	content.add_theme_constant_override("separation", 22)
	sheet.add_child(content)
	page.hide()
	match_bar = PanelContainer.new()
	match_bar.name = "MatchHUD"
	add_child(match_bar)
	match_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	# Leave the native vertical power meter fully visible during both turns.
	match_bar.offset_left = 96
	match_bar.offset_right = 506
	match_bar.offset_top = -150
	match_bar.offset_bottom = -16
	match_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	match_bar.add_theme_stylebox_override("panel", Style.pixel_frame("panel", 10))
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	match_bar.add_child(rows)
	match_copy = label(rows, "", 20, Style.PAPER)
	thinking_copy = label(rows, "", 16, Style.FOCUS)
	controls = HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_child(controls)
	for speed in [1, 2, 4]:
		var button := Button.new()
		button.name = "Speed%d" % speed
		button.text = "%d×" % speed
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(58, 42)
		controls.add_child(button)
		button.pressed.connect(func() -> void: speed_requested.emit(speed))
	var skip := Button.new()
	skip.name = "SkipAI"
	skip.text = "SKIP TO RESULT"
	skip.custom_minimum_size = Vector2(176, 42)
	controls.add_child(skip)
	skip.pressed.connect(func() -> void: skip_requested.emit())
	match_bar.hide()


func show_modes() -> void:
	_begin(&"mode_select", "CHOOSE YOUR ROUND", "YOUR SHOT. YOUR KIND OF COMPETITION.")
	var row := _row(content)
	var solo := _mode_choice(row, "SOLO", &"hole", "YOUR ROUND. YOUR LUCK.\nBuild a bag across 18 holes.", false)
	_mode_choice(row, "VS AI", &"stroke", "ONE COURSE. TWO GOLFERS.\nTake turns, then compare scores.", true)
	label(content, "An 18-hole roguelike round — alone, or against another golfer.", 22, Style.PAPER_MUTED)
	action(content, "BACK", &"back", func() -> void: back_requested.emit(), &"quiet")
	focus_later(solo)


func show_opponents() -> void:
	_begin(&"opponent_select", "PICK YOUR OPPONENT", "ONE COURSE. TWO GOLFERS.")
	var row := _row(content)
	for id in AIDifficultyProfile.IDS:
		var profile := AIDifficultyProfile.get_profile(id)
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(208, 350)
		panel.add_theme_stylebox_override("panel", Style.pixel_frame("card", 16))
		row.add_child(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 14)
		panel.add_child(column)
		label(column, profile.tier, 16, profile.accent)
		var emblem := UIIcon.new()
		emblem.custom_minimum_size = Vector2(100, 100)
		emblem.configure(&"stroke", profile.accent)
		column.add_child(emblem)
		label(column, profile.display_name.replace(" ", "\n"), 26, Style.PAPER)
		label(column, "%d / 5  SKILL" % profile.rank, 16, profile.accent)
		var copy := label(column, profile.description, 18, Style.PAPER_MUTED)
		copy.custom_minimum_size = Vector2(180, 52)
		copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var select := action(column, "SELECT", &"continue", func() -> void: opponent_selected.emit(id))
		if id == AIDifficultyProfile.IDS[0]:
			focus_later(select)
	label(content, "Text identities only. No affiliation or endorsement.\nCourse curses affect BOTH golfers. Personal bonuses, wallets and purchases stay separate.", 18, Style.PAPER_MUTED)
	action(content, "BACK", &"back", show_modes, &"quiet")


func show_comparison(match_state: VsMatchState) -> void:
	var hole: Dictionary = match_state.hole_results.back()
	_begin(&"hole_comparison", ["YOU WIN THE HOLE", "HOLE TIED", "%s WINS THE HOLE" % match_state.profile.short_name][int(hole.winner) + 1], "HOLE %02d  /  PAR %d" % [hole.hole, hole.par])
	_scorecards(match_state, hole.player_strokes, hole.opponent_strokes, hole.player_time, hole.opponent_time, hole.par)
	var totals := match_state.summary()
	label(content, "MATCH STROKES   YOU %d  •  %s %d\nHOLES WON   %d – %d   /   %d TIED" % [totals.player_strokes, match_state.profile.short_name, totals.opponent_strokes, totals.wins, totals.losses, totals.ties], 24, Style.PAPER_MUTED)
	label(content, "YOUR REWARD  +%d COINS   /   WALLET %d\nStrokes decide first. Equal strokes use completion time." % [match_state.player.last_hole_reward, match_state.player.tokens], 20, Style.GOLD)
	focus_later(action(content, "CONTINUE", &"continue", func() -> void: continue_requested.emit()))


func show_final(match_state: VsMatchState) -> void:
	var result := match_state.summary()
	_begin(&"match_results", ["VICTORY", "MATCH TIED", "DEFEAT"][int(result.winner) + 1], "18 HOLES  /  YOU vs %s" % match_state.profile.short_name)
	_scorecards(match_state, result.player_strokes, result.opponent_strokes, result.player_time, result.opponent_time, result.par)
	label(content, "HOLES WON   %d – %d   /   %d TIED\nSEED  %s" % [result.wins, result.losses, result.ties, SeedCodec.format_seed(match_state.player.run_seed)], 22, Style.GOLD)
	var builds := _row(content)
	for state in [match_state.player, match_state.opponent]:
		var names := PackedStringArray()
		for card in state.owned_card_definitions:
			names.append("%s (%s)" % [card.name, String(card.rarity)])
		var copy := label(builds, ("YOUR BAG\n" if state == match_state.player else "OPPONENT BAG\n") + (", ".join(names) if not names.is_empty() else "No cards bought"), 18, Style.PAPER_MUTED)
		copy.custom_minimum_size = Vector2(510, 0)
		copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var buttons := _row(content)
	action(buttons, "REMATCH", &"restart", func() -> void: rematch_requested.emit())
	action(buttons, "NEW OPPONENT", &"stroke", func() -> void: new_opponent_requested.emit())
	action(buttons, "MAIN MENU", &"menu", func() -> void: menu_requested.emit(), &"quiet")


func show_ai_cards(match_state: VsMatchState, cards: Array[CardDefinition]) -> void:
	_begin(&"ai_cards", "%s'S PICKS" % match_state.profile.short_name, "SAME OFFERS. DIFFERENT DEALS.")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 18)
	content.add_child(grid)
	for card in cards:
		var ticket := PanelContainer.new()
		var paper := Style.pixel_frame("card", 14)
		paper.content_margin_left = 16
		paper.content_margin_right = 16
		paper.content_margin_top = 14
		paper.content_margin_bottom = 14
		ticket.add_theme_stylebox_override("panel", paper)
		ticket.custom_minimum_size.x = 540
		grid.add_child(ticket)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		ticket.add_child(column)
		var art := Illustration.new()
		art.custom_minimum_size = Vector2(104, 104)
		art.configure(Style.card_icon(card.id), Style.PAPER, Style.card_accent(card.id))
		column.add_child(art)
		label(column, card.name.to_upper(), 23, Style.PAPER)
		label(column, "%s  /  %d COINS" % [String(card.rarity).to_upper(), card.price], 16, Style.GOLD)
		var benefit := label(column, card.bonus_description, 20, Style.BONUS)
		benefit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label(column, ("COURSE CURSE • BOTH GOLFERS" if MatchCourseRules.affects_course(card.curse_effects) else "PERSONAL CURSE") + " • %dH" % card.curse_duration_holes, 16, Style.CURSE)
		var copy := label(column, card.curse_description_for_multiplier(match_state.opponent.difficulty_profile.curse_strength_multiplier), 20, Style.PAPER)
		copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if cards.is_empty():
		label(content, "Keeping the coins this time.", 26, Style.PAPER)
	focus_later(action(content, "NEXT BIOME", &"continue", func() -> void: continue_requested.emit()))


func update_match(match_state: VsMatchState, status: String, playing: bool, speed := 1) -> void:
	match_bar.visible = playing and not page.visible
	var watching := match_state.turn == VsMatchState.Turn.OPPONENT
	match_bar.offset_top = -150 if watching else -92
	match_copy.text = "%sYOU %d    •    %s%s %d" % ["" if watching else "> ", match_state.player.strokes, "> " if watching else "", match_state.profile.short_name, match_state.opponent.strokes]
	thinking_copy.text = status if watching else "YOUR TURN  /  MATCH %d – %d" % [match_state.player.total_strokes, match_state.opponent.total_strokes]
	controls.visible = watching
	for value in [1, 2, 4]:
		(controls.get_node("Speed%d" % value) as Button).set_pressed_no_signal(value == speed)


func hide_page() -> void:
	page.hide()
	page_id = &""


func _begin(id: StringName, title: String, eyebrow: String) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	page_id = id
	page.show()
	match_bar.hide()
	label(content, eyebrow, 18, Style.GOLD)
	var heading := label(content, title, 66, Style.PAPER)
	Style.apply_display(heading, 66, Style.PAPER)


func _scorecards(match_state: VsMatchState, first: int, second: int, first_time: float, second_time: float, par: int) -> void:
	var row := _row(content)
	for index in 2:
		var strokes := first if index == 0 else second
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(510, 200)
		panel.add_theme_stylebox_override("panel", Style.pixel_frame("card", 18))
		row.add_child(panel)
		var column := VBoxContainer.new()
		panel.add_child(column)
		label(column, "YOU" if index == 0 else match_state.profile.display_name.to_upper(), 24, Style.PAPER)
		var number := label(column, "%d" % strokes, 84, Style.GOLD if index == 0 else match_state.profile.accent)
		Style.apply_display(number, 84, Style.GOLD if index == 0 else match_state.profile.accent)
		label(column, "%+d vs PAR   /   %.1fs" % [strokes - par, first_time if index == 0 else second_time], 22, Style.PAPER_MUTED)


static func label(parent: Node, text: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Style.apply_ui(result, size, color, true)
	parent.add_child(result)
	return result


static func action(parent: Node, title: String, icon: StringName, callback: Callable, variant := &"primary") -> UIActionButton:
	var button := UIActionButton.new()
	button.name = title.to_pascal_case()
	button.custom_minimum_size = Vector2(maxf(220, Style.UI_BOLD_FONT.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x + 96), 62)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(button)
	button.configure(title, icon, variant)
	button.pressed.connect(callback)
	if parent.get_child_count() == 1:
		focus_later(button)
	return button


func _mode_choice(parent: HBoxContainer, title: String, icon: StringName, copy: String, versus: bool) -> UIActionButton:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 340)
	panel.add_theme_stylebox_override("panel", Style.pixel_frame("card", 22))
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 20)
	panel.add_child(column)
	var emblem := UIIcon.new()
	emblem.custom_minimum_size = Vector2(96, 96)
	emblem.configure(icon, Style.GOLD)
	column.add_child(emblem)
	var button := action(column, title, icon, func() -> void: mode_selected.emit(versus))
	button.display_size = 44
	button.custom_minimum_size = Vector2(380, 78)
	label(column, copy, 22, Style.PAPER_MUTED)
	return button


static func focus_later(control: Control) -> void:
	_focus_live.call_deferred(control.get_instance_id())


static func _focus_live(instance_id: int) -> void:
	var control := instance_from_id(instance_id) as Control
	if is_instance_valid(control) and control.is_inside_tree() and control.is_visible_in_tree():
		control.grab_focus()


static func _row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	parent.add_child(row)
	return row
