class_name UILogo
extends Control

const UIStyleScript := preload("res://scripts/ui/ui_style.gd")

@export var compact := false
@export var show_tagline := false

class LetterMotifs:
	extends Control

	var compact_mode := false

	func _draw() -> void:
		var scale_factor := 0.64 if compact_mode else 1.0
		var ball_center := Vector2(45.0, 166.0) * scale_factor
		var ball_radius := 30.0 * scale_factor
		draw_circle(ball_center + Vector2(5.0, 6.0) * scale_factor, ball_radius * 1.03, Color(0.0, 0.0, 0.0, 0.34))
		draw_circle(ball_center, ball_radius, UIStyleScript.PAPER)
		for offset in [Vector2(-9, -7), Vector2(8, -10), Vector2(2, 7), Vector2(-12, 11), Vector2(13, 8)]:
			draw_circle(ball_center + offset * scale_factor, 2.2 * scale_factor, Color(UIStyleScript.INK, 0.38))

		var card_rect := Rect2(Vector2(2.0, 8.0) * scale_factor, Vector2(64.0, 72.0) * scale_factor)
		draw_line(card_rect.position, card_rect.position + Vector2(card_rect.size.x, 0.0), UIStyleScript.GOLD, 4.0 * scale_factor, true)
		draw_line(card_rect.position, card_rect.position + Vector2(0.0, card_rect.size.y), UIStyleScript.GOLD, 4.0 * scale_factor, true)
		draw_line(card_rect.end, card_rect.end - Vector2(card_rect.size.x * 0.38, 0.0), Color(UIStyleScript.CURSE, 0.92), 4.0 * scale_factor, true)

		var club_start := Vector2(192.0, 228.0) * scale_factor
		var club_mid := Vector2(330.0, 258.0) * scale_factor
		var club_end := Vector2(526.0, 223.0) * scale_factor
		var curve := PackedVector2Array()
		for point_index in range(25):
			var t := float(point_index) / 24.0
			var first := club_start.lerp(club_mid, t)
			var second := club_mid.lerp(club_end, t)
			curve.append(first.lerp(second, t))
		draw_polyline(curve, Color(UIStyleScript.GOLD, 0.74), 6.0 * scale_factor, true)
		draw_colored_polygon(PackedVector2Array([
			club_end + Vector2(-2.0, -4.0) * scale_factor,
			club_end + Vector2(27.0, 1.0) * scale_factor,
			club_end + Vector2(22.0, 13.0) * scale_factor,
			club_end + Vector2(-5.0, 7.0) * scale_factor,
		]), UIStyleScript.PAPER)

		var flag_x := 297.0 * scale_factor
		var flag_top := 97.0 * scale_factor
		draw_line(Vector2(flag_x, flag_top), Vector2(flag_x, 190.0 * scale_factor), UIStyleScript.PAPER, 3.5 * scale_factor, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(flag_x + 2.0 * scale_factor, flag_top),
			Vector2(flag_x + 34.0 * scale_factor, flag_top + 10.0 * scale_factor),
			Vector2(flag_x + 2.0 * scale_factor, flag_top + 22.0 * scale_factor),
		]), UIStyleScript.CURSE)

var kicker_label: Label
var title_label: Label
var tagline_label: Label
var motif_overlay: LetterMotifs
var _entrance_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(760.0, 286.0) if not compact else Vector2(490.0, 184.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	kicker_label = Label.new()
	kicker_label.text = "A STROKE"
	kicker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIStyleScript.apply_display(kicker_label, 58 if not compact else 37, UIStyleScript.PAPER)
	add_child(kicker_label)

	title_label = Label.new()
	title_label.text = "OF LUCK"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIStyleScript.apply_display(title_label, 104 if not compact else 66, UIStyleScript.GOLD)
	add_child(title_label)

	tagline_label = Label.new()
	tagline_label.text = ""
	UIStyleScript.apply_ui(tagline_label, 15 if not compact else 12, UIStyleScript.PAPER_MUTED, true)
	tagline_label.visible = show_tagline
	add_child(tagline_label)

	motif_overlay = LetterMotifs.new()
	motif_overlay.compact_mode = compact
	motif_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(motif_overlay)
	motif_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	resized.connect(_layout_labels)
	_layout_labels()


func play_entrance() -> void:
	if _entrance_tween:
		_entrance_tween.kill()
	modulate.a = 0.0
	pivot_offset = size * 0.5
	scale = Vector2(0.965, 0.965)
	_entrance_tween = create_tween().set_parallel(true)
	_entrance_tween.tween_property(self, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_property(self, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _layout_labels() -> void:
	if not kicker_label:
		return
	var scale_factor := 0.64 if compact else 1.0
	kicker_label.position = Vector2(16.0, 0.0) * scale_factor
	kicker_label.size = Vector2(maxf(size.x - 20.0 * scale_factor, 1.0), 86.0 * scale_factor)
	title_label.position = Vector2(0.0, 78.0) * scale_factor
	title_label.size = Vector2(maxf(size.x, 1.0), 128.0 * scale_factor)
	tagline_label.position = Vector2(4.0, 252.0) * scale_factor
	tagline_label.size = Vector2(maxf(size.x - 8.0, 1.0), 26.0 * scale_factor)
	queue_redraw()


func _draw() -> void:
	var scale_factor := 0.64 if compact else 1.0
	draw_line(Vector2(4.0, 242.0) * scale_factor, Vector2(618.0, 242.0) * scale_factor, Color(UIStyleScript.PAPER, 0.18), 3.0 * scale_factor, true)
