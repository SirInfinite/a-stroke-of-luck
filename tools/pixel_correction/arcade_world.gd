extends Node2D
## Meadow-only visual adapter. No writes to collision, physics or level data.

const Pixel := preload("res://tools/pixel_correction/arcade_assets.gd")
const Rig := preload("res://tools/pixel_correction/arcade_pendulum.gd")
var main
var water: Array[Sprite2D] = []
var flag: Sprite2D
var elapsed := 0.0
var last_frame := -1

func setup(owner_main) -> void:
	main = owner_main
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var root: Node2D = main.level_builder.level_root
	for child in root.get_children():
		if child.name in ["BiomeBackground", "BiomeBackgroundVariants", "BiomeAmbience", "CupOpening", "FlagAsset"] or String(child.name).begins_with("Telegraph_"):
			if child is CanvasItem: child.hide()
	_background()
	var ground := root.get_node("Green")
	for child in ground.get_children():
		if child is CollisionShape2D: continue
		if child is CanvasItem: child.hide()
		if not child.has_meta(&"cell"): continue
		var material := "green" if child.get_meta(&"putting_surface", false) else "fairway"
		var variant := "a" if child.get_meta(&"checker_variant", 0) == 0 else "b"
		var tile := Pixel.sprite("terrain/%s_%s" % [material, variant], child.position, Vector2(100, 100))
		ground.add_child(tile)
	for child in root.get_children():
		if child is MovingHazard:
			var rig := Rig.new()
			root.add_child(rig)
			rig.setup(child)
		elif child is GameplayHazard:
			_surface(child)
		elif child is StaticBody2D and child.has_meta(&"collision_kind"):
			_wall(child)
	var tee: Node2D = main.level_builder.tee_marker
	for child in tee.get_children():
		if child is CanvasItem: child.hide()
	tee.add_child(Pixel.sprite("props/tee", Vector2.ZERO, Vector2(62, 42)))
	var ball_art: Node2D = main.ball.get_node("BallArt")
	var previous := ball_art.get_node_or_null("SampleBall")
	if previous:
		ball_art.remove_child(previous)
		previous.queue_free()
	for child in ball_art.get_children():
		if child is CanvasItem: child.hide()
	var ball_sprite := Pixel.sprite("props/ball", Vector2.ZERO, Vector2(26, 26))
	ball_sprite.name = "SampleBall"
	ball_art.add_child(ball_sprite)
	ball_art.z_index = 24
	flag = Pixel.sprite("props/flag_a")
	flag.centered = false
	flag.scale = Vector2(1.8, 1.8)
	flag.position = main.level_builder.level_point(main.level_builder.active_level, "hole", "hole_cell") - Vector2(20, 80)
	flag.z_index = 2
	add_child(flag)

func _wall(body: StaticBody2D) -> void:
	var dimensions := Vector2.ZERO
	for child in body.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			dimensions = child.shape.size
		elif child is CanvasItem: child.hide()
	if dimensions == Vector2.ZERO: return
	# Flat material faces occupy the exact existing wall rectangle. The playset
	# skirt supplies depth outside the footprint instead of stealing playable turf.
	var horizontal := dimensions.x >= dimensions.y
	var pixels := Vector2i(maxi(8, roundi(dimensions.x / 2)), maxi(8, roundi(dimensions.y / 2)))
	var image := Image.create(pixels.x, pixels.y, false, Image.FORMAT_RGBA8)
	image.fill(Pixel.INK)
	image.fill_rect(Rect2i(1, 1, pixels.x - 2, pixels.y - 2), Color("b56c38"))
	if horizontal:
		image.fill_rect(Rect2i(1, 1, pixels.x - 2, 3), Color("ffe2a0"))
		image.fill_rect(Rect2i(1, 4, pixels.x - 2, maxi(1, pixels.y - 10)), Color("e8ad5e"))
		image.fill_rect(Rect2i(1, pixels.y - 4, pixels.x - 2, 2), Color("71433a"))
	else:
		image.fill_rect(Rect2i(1, 1, 3, pixels.y - 2), Color("ffe2a0"))
		image.fill_rect(Rect2i(4, 1, maxi(1, pixels.x - 10), pixels.y - 2), Color("e8ad5e"))
		image.fill_rect(Rect2i(pixels.x - 4, 1, 2, pixels.y - 2), Color("71433a"))
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = dimensions / Vector2(pixels)
	body.add_child(sprite)

func _surface(area: GameplayHazard) -> void:
	if area.hazard_type not in [&"sand", &"water", &"bounce_pad"]: return
	var dimensions := Vector2.ZERO
	for child in area.get_children():
		if child is CollisionShape2D:
			if child.shape is RectangleShape2D: dimensions = child.shape.size
			elif child.shape is CircleShape2D: dimensions = Vector2.ONE * child.shape.radius * 2.0
		elif child is CanvasItem: child.hide()
	if dimensions == Vector2.ZERO: return
	var path := "props/pad" if area.hazard_type == &"bounce_pad" else "terrain/%s_a" % area.hazard_type
	var sprite := Pixel.sprite(path, Vector2.ZERO, dimensions)
	area.add_child(sprite)
	if area.hazard_type == &"water": water.append(sprite)

func _background() -> void:
	# Quiet flat surround and a thick assembled board base, all below gameplay.
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([Vector2(-5000, -4000), Vector2(5000, -4000), Vector2(5000, 4000), Vector2(-5000, 4000)])
	ground.color = Color("142e36")
	ground.z_index = -5
	add_child(ground)
	var board := Polygon2D.new()
	board.polygon = PackedVector2Array([Vector2(-640, -434), Vector2(640, -434), Vector2(640, 452), Vector2(620, 472), Vector2(-620, 472), Vector2(-640, 452)])
	board.color = Color("553b36")
	board.z_index = -2
	add_child(board)
	for at in [Vector2(-628, -405), Vector2(628, -405), Vector2(-610, 446), Vector2(610, 446)]:
		var stud := Polygon2D.new()
		stud.polygon = PackedVector2Array([Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)])
		stud.position = at
		stud.color = Color("cd9762")
		stud.z_index = -1
		add_child(stud)
	# Two bounded corner groups retain Meadow identity without scenic dominance.
	for placement in [
		["willow", Vector2(-800, -270), 3.6], ["flowers", Vector2(-725, -100), 1.6],
		["lotus", Vector2(770, 335), 2.4], ["willow", Vector2(850, 170), 3.0],
		["flowers", Vector2(890, 400), 1.4], ["sign", Vector2(-500, 530), 1.8]]:
		var prop := Pixel.sprite("props/" + placement[0], placement[1])
		prop.scale = Vector2.ONE * placement[2]
		prop.modulate = Color(0.64, 0.76, 0.76)
		prop.z_index = -1
		add_child(prop)
	# Broad silhouette patches at the edges support the playset; no texture field.
	for at in [Vector2(-950, -320), Vector2(1020, 350), Vector2(-450, 780)]:
		var patch := Polygon2D.new()
		patch.polygon = PackedVector2Array([Vector2(-190, -55), Vector2(-120, -55), Vector2(-120, -95), Vector2(80, -95), Vector2(80, -55), Vector2(200, -55), Vector2(200, 60), Vector2(120, 60), Vector2(120, 95), Vector2(-180, 95), Vector2(-180, 55), Vector2(-230, 55), Vector2(-230, -20), Vector2(-190, -20)])
		patch.position = at
		patch.color = Color("1c3e43")
		patch.z_index = -4
		add_child(patch)

func _process(delta: float) -> void:
	if not main or main.run_state.phase != RunState.Phase.HOLE_PLAY: return
	if main.feedback_director.reduced_motion: return
	elapsed += delta
	var animation_frame := int(elapsed * 3.0) % 2
	if animation_frame == last_frame: return
	last_frame = animation_frame
	for sprite in water:
		if is_instance_valid(sprite): sprite.texture = Pixel.texture("terrain/water_" + ("a" if animation_frame == 0 else "b"))
	if flag: flag.texture = Pixel.texture("props/flag_" + ("a" if int(elapsed * 2.0) % 2 == 0 else "b"))
