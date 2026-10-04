extends Control
## A pixel-block readout of the existing meter. Input and power stay native.

const Pixel := preload("res://tools/pixel_correction/arcade_assets.gd")
var source: PowerMeter

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(source): return
	draw_rect(Rect2(6, 0, 44, size.y), Pixel.INK)
	draw_rect(Rect2(8, 2, 40, size.y - 4), Pixel.PAPER)
	draw_rect(Rect2(12, 6, 32, size.y - 12), Color("233747"))
	var count := 12
	var step := (size.y - 20) / count
	for index in count:
		var on := float(index) / count < source.displayed_power
		var color := Color("405b65")
		if on: color = Pixel.GOLD if index < 9 else Pixel.CORAL
		draw_rect(Rect2(16, size.y - 10 - (index + 1) * step, 24, maxf(2, step - 4)), color)
