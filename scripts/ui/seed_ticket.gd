class_name SeedTicket
extends UIValueTicket
signal copy_requested(seed_value: int)
var seed_value := 0
var copied_remaining := 0.0
var hover_copy := false

func _init() -> void:
	super()
	name = "SeedTicket"
	value_button.pressed.connect(func() -> void: copy_requested.emit(seed_value))
	value_button.mouse_entered.connect(set_hovered.bind(true))
	value_button.mouse_exited.connect(set_hovered.bind(false))
	value_button.focus_entered.connect(set_hovered.bind(true))
	value_button.focus_exited.connect(set_hovered.bind(false))
	show_value("0", UIStyle.PAPER, false)

func set_seed(value: int) -> void:
	if seed_value == value:
		return
	seed_value = value
	copied_remaining = 0.0
	hover_copy = false
	show_value(str(value), UIStyle.PAPER, false)
	value_button.tooltip_text = "Copy this run's seed"

func set_hovered(value: bool) -> void:
	hover_copy = value
	if copied_remaining <= 0.0:
		show_value("Copy" if value else str(seed_value))

func show_copied() -> void:
	copied_remaining = 1.15 # includes the fade; roughly one second fully visible
	show_value("Seed copied!", UIStyle.BONUS)

func _process(delta: float) -> void:
	if copied_remaining <= 0.0:
		return
	copied_remaining -= delta
	if copied_remaining <= 0.0:
		hover_copy = false
		show_value(str(seed_value))
