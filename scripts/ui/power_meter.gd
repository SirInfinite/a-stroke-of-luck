class_name PowerMeter
extends Control
## Monotonic shot power, framed horizontally. No reference critical-hit mechanic.
const SEGMENTS := 48
const Style := preload("res://scripts/ui/ui_style.gd")
var power := 0.0
var displayed_power := 0.0
var _frame: StyleBoxTexture

func _init() -> void:
	custom_minimum_size = Vector2(500.0, 48.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_frame = Style.pixel_frame("panel", 4)

func set_power(new_power: float) -> void:
	power = clampf(new_power, 0.0, 1.0)
	displayed_power = power
	queue_redraw()

func _draw() -> void:
	draw_style_box(_frame, Rect2(Vector2.ZERO, size))
	var inner := Rect2(Vector2(12,12), size-Vector2(24,24))
	var step := inner.size.x / SEGMENTS
	for index in SEGMENTS:
		var fraction := float(index+1) / SEGMENTS
		var color := Color("344139")
		if fraction <= displayed_power:
			color = Color("70c6bd") if index < 24 else Color("e6de89") if index < 40 else Color("f4a55b")
		var segment := Rect2(inner.position+Vector2(index*step,0),Vector2(step-1,inner.size.y))
		draw_rect(segment, color)
		draw_rect(Rect2(segment.position,Vector2(segment.size.x,3)),color.lightened(0.18))
		draw_rect(Rect2(segment.position+Vector2(0,inner.size.y-3),Vector2(segment.size.x,3)),color.darkened(0.28))
	var marker := Vector2(inner.position.x + inner.size.x * displayed_power, 5)
	draw_colored_polygon(PackedVector2Array([marker+Vector2(-7,0),marker+Vector2(7,0),marker+Vector2(0,10)]),Color("111b27"))
	draw_colored_polygon(PackedVector2Array([marker+Vector2(-4,1),marker+Vector2(4,1),marker+Vector2(0,7)]),Style.GOLD)
