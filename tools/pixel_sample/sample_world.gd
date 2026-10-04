extends Node2D
## Visual adapters for the review fixture. No collision or level mutations.

const Art := preload("res://tools/pixel_sample/sample_assets.gd")
const Rig := preload("res://tools/pixel_sample/sample_pendulum.gd")
var main
var water: Array[Sprite2D] = []
var flag: Sprite2D
var elapsed := 0.0
var last_frame := -1

func setup(owner_main) -> void:
	main = owner_main
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
		var tile := Art.sprite("terrain/%s_%s" % [material, variant], child.position, Vector2(100, 100))
		if variant == "b": tile.modulate = Color(0.88, 0.91, 0.9)
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
	tee.add_child(Art.sprite("props/tee", Vector2.ZERO, Vector2(62, 42)))
	var ball_art: Node2D = main.ball.get_node("BallArt")
	var previous := ball_art.get_node_or_null("SampleBall")
	if previous:
		ball_art.remove_child(previous)
		previous.queue_free()
	for child in ball_art.get_children():
		if child is CanvasItem: child.hide()
	# Keep the native BallArt sink/reset transform and every gameplay signal.
	var ball_sprite := Art.sprite("props/ball", Vector2.ZERO, Vector2(26, 26))
	ball_sprite.name = "SampleBall"
	ball_art.add_child(ball_sprite)
	ball_art.z_index = 24
	flag = Art.sprite("props/flag_a")
	flag.centered = false
	flag.scale = Vector2(1.5, 1.5)
	flag.position = main.level_builder.level_point(main.level_builder.active_level, "hole", "hole_cell") - Vector2(17, 91)
	flag.z_index = 2
	add_child(flag)

func _wall(body: StaticBody2D) -> void:
	var dimensions := Vector2.ZERO
	for child in body.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			dimensions = child.shape.size
		elif child is CanvasItem: child.hide()
	if dimensions == Vector2.ZERO: return
	var material := "wall_h" if dimensions.x > dimensions.y else "wall_v"
	if absf(dimensions.x - dimensions.y) < 1.0: material = "wall_join"
	body.add_child(Art.sprite("terrain/" + material, Vector2.ZERO, dimensions))

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
	var sprite := Art.sprite(path, Vector2.ZERO, dimensions)
	area.add_child(sprite)
	if area.hazard_type == &"water": water.append(sprite)

func _background() -> void:
	var garden := Art.sprite("terrain/garden")
	garden.region_enabled = true
	garden.region_rect = Rect2(0, 0, 3800, 2300)
	garden.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	garden.scale = Vector2(2, 2)
	garden.modulate = Color(0.19, 0.28, 0.3)
	garden.z_index = -3
	add_child(garden)
	# Three composed clusters leave long quiet sides and an open aiming corridor.
	for placement in [
		["willow", Vector2(-770, -345), 2.8], ["flowers", Vector2(-655, -467), 1.7],
		["willow", Vector2(-910, -175), 2.1], ["flowers", Vector2(-780, -100), 1.2],
		["lotus", Vector2(745, 255), 2.4], ["flowers", Vector2(875, 370), 1.9],
		["willow", Vector2(900, 105), 2.6], ["lotus", Vector2(695, 485), 1.5],
		["sign", Vector2(-425, 530), 1.5], ["flowers", Vector2(-565, 518), 1.2]]:
		var prop := Art.sprite("props/" + placement[0], placement[1])
		prop.scale = Vector2.ONE * placement[2]
		prop.z_index = -1
		add_child(prop)

func _process(delta: float) -> void:
	if not main or main.run_state.phase != RunState.Phase.HOLE_PLAY: return
	if main.feedback_director.reduced_motion: return
	elapsed += delta
	var animation_frame := int(elapsed * 3.0) % 2
	if animation_frame == last_frame: return
	last_frame = animation_frame
	for sprite in water:
		if is_instance_valid(sprite): sprite.texture = Art.texture("terrain/water_" + ("a" if animation_frame == 0 else "b"))
	if flag: flag.texture = Art.texture("props/flag_" + ("a" if int(elapsed * 2.0) % 2 == 0 else "b"))
