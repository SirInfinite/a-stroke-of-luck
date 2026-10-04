extends Node2D
## Cosmetic exposed banks read native area footprints; no new physics shapes.

var dimensions := Vector2.ZERO
var exposed: Array[bool] = [true, true, true, true]
var kind: StringName = &"water"
var biome: StringName = &"meadow"
var density := 48

func setup(area: GameplayHazard, size: Vector2, biome_id: StringName, source_density := 48) -> void:
	dimensions = size
	kind = area.hazard_type
	biome = biome_id
	density = source_density
	var offsets := [Vector2(0, -size.y), Vector2(size.x, 0), Vector2(0, size.y), Vector2(-size.x, 0)]
	for child in area.get_parent().get_children():
		if not child is GameplayHazard or child == area or child.hazard_type != kind: continue
		for side in 4:
			if child.position.distance_to(area.position + offsets[side]) < 1.0: exposed[side] = false
	queue_redraw()

func set_density(value: int) -> void:
	density = value
	queue_redraw()

func _draw() -> void:
	var half := dimensions * 0.5
	var pixel := 100.0 / density
	var dark := Color("1f4b53") if kind == &"water" else Color("873829") if kind == &"lava" else Color("b69661")
	var light := Color("83bdac") if kind == &"water" else Color("ffb24c") if kind == &"lava" else Color("f3d59b")
	var bank := Color("3b5960") if biome == &"volcanic" else Color("537d68")
	if exposed[0]:
		draw_rect(Rect2(-half, Vector2(dimensions.x, pixel * 2)), dark)
		draw_rect(Rect2(-half + Vector2(0, pixel * 2), Vector2(dimensions.x, pixel)), light)
	if exposed[1]: draw_rect(Rect2(half.x - pixel * 2, -half.y, pixel * 2, dimensions.y), dark)
	if exposed[2]:
		draw_rect(Rect2(-half.x, half.y - pixel * 2, dimensions.x, pixel * 2), dark)
		draw_rect(Rect2(-half.x, half.y - pixel, dimensions.x, pixel), bank)
	if exposed[3]:
		draw_rect(Rect2(-half, Vector2(pixel * 2, dimensions.y)), dark)
		draw_rect(Rect2(-half + Vector2(pixel * 2, 0), Vector2(pixel, dimensions.y)), light)
