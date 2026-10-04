extends Control
## Stepped power readout; reads the existing smoothed display value only.

const Art := preload("res://tools/reference_slice/ui/ui_assets.gd")
var source: Control

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(source): return
	var amount: float = clampf(source.displayed_power, 0.0, 1.0)
	draw_style_box(Art.frame("panel", Color.WHITE, 4.0), Rect2(Vector2.ZERO, size))
	var inner := Rect2(Vector2(10,10), size-Vector2(20,20))
	var bands := 24
	var step := inner.size.y / bands
	for index in bands:
		var threshold := float(index+1) / bands
		var color := Color("29444e")
		if amount >= threshold:
			color = Color("71bfb0") if index < 12 else Color("e2d879") if index < 20 else Color("f49b55")
		draw_rect(Rect2(inner.position+Vector2(0,inner.size.y-step*(index+1)),Vector2(inner.size.x,step-1)),color)
