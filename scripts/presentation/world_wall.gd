extends Node2D
## A joined material face follows the exact native wall rectangle.

const Art := preload("res://scripts/presentation/world_art.gd")
var dimensions := Vector2.ZERO
var world_origin := Vector2.ZERO
var biome: StringName = &"meadow"
var neighbors: Array[Rect2] = []
var image_sprite: Sprite2D
var rim: Texture2D

func configure(size: Vector2, at: Vector2, biome_id: StringName) -> void:
	dimensions = size
	world_origin = at
	biome = biome_id
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	rim = Art.texture("terrain/%s_rim" % biome)
	image_sprite = Art.sprite("terrain/%s_wall" % biome)
	image_sprite.region_enabled = true
	image_sprite.region_rect = Rect2((at - size * 0.5) * 0.48, size * 0.48)
	image_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	image_sprite.scale = Vector2.ONE / 0.48
	image_sprite.show_behind_parent = true
	image_sprite.modulate = Color(0.32,0.38,0.35)
	add_child(image_sprite)

func join_walls(rectangles: Array[Rect2]) -> void:
	var bounds := Rect2(world_origin - dimensions * 0.5, dimensions).grow(3.0)
	neighbors.clear()
	for rect in rectangles:
		if bounds.intersects(rect): neighbors.append(rect)
	queue_redraw()

func _occupied(point: Vector2) -> bool:
	for rect in neighbors:
		if rect.has_point(point): return true
	return false

func _draw() -> void:
	var pixel := 100.0 / Art.DENSITY
	for edge in 4:
		var extent := dimensions.x if edge % 2 == 0 else dimensions.y
		var count := ceili(extent / pixel)
		var run_start := -1
		for index in count + 1:
			var exposed := false
			if index < count:
				var along := -extent * 0.5 + (index + 0.5) * pixel
				var point := Vector2(along, -dimensions.y * 0.5 - 0.5) if edge == 0 else Vector2(dimensions.x * 0.5 + 0.5, along) if edge == 1 else Vector2(along, dimensions.y * 0.5 + 0.5) if edge == 2 else Vector2(-dimensions.x * 0.5 - 0.5, along)
				exposed = not _occupied(world_origin + point)
			if exposed and run_start < 0:
				run_start = index
			elif not exposed and run_start >= 0:
				var start := -extent * 0.5 + run_start * pixel
				var end := minf(extent * 0.5, -extent * 0.5 + index * pixel)
				_draw_edge(edge, start, end - start, pixel)
				run_start = -1

func _draw_edge(edge: int, along: float, length: float, pixel: float) -> void:
	var horizontal := edge % 2 == 0
	var half := dimensions * 0.5
	var depth := minf(12.0 * pixel, minf(dimensions.x, dimensions.y) * 0.46)
	var at := Vector2(along,-half.y) if edge == 0 else Vector2(half.x,along) if edge == 1 else Vector2(along,half.y) if edge == 2 else Vector2(-half.x,along)
	var target := Rect2(at, Vector2(length,depth) if horizontal else Vector2(depth,length))
	if edge == 1: target.position.x -= depth
	if edge == 2: target.position.y -= depth
	var points := PackedVector2Array([target.position, target.position+Vector2(target.size.x,0), target.end, target.position+Vector2(0,target.size.y)])
	var u := ((world_origin.x if horizontal else world_origin.y) + along) / pixel / rim.get_width()
	var v := u + length / pixel / rim.get_width()
	var uv := PackedVector2Array([Vector2(u,0),Vector2(v,0),Vector2(v,1),Vector2(u,1)])
	if edge == 1: uv = PackedVector2Array([Vector2(u,1),Vector2(u,0),Vector2(v,0),Vector2(v,1)])
	elif edge == 2: uv = PackedVector2Array([Vector2(u,1),Vector2(v,1),Vector2(v,0),Vector2(u,0)])
	elif edge == 3: uv = PackedVector2Array([Vector2(u,0),Vector2(u,1),Vector2(v,1),Vector2(v,0)])
	# One textured quad per exposed run, not one draw call per source pixel.
	draw_polygon(points, PackedColorArray([Color.WHITE]), uv, rim)
	var outline_at := at
	if edge == 1: outline_at.x -= pixel
	if edge == 2: outline_at.y -= pixel
	draw_rect(Rect2(outline_at,Vector2(length,pixel) if horizontal else Vector2(pixel,length)),Art.stone_colors(biome)[0])
