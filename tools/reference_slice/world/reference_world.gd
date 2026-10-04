extends Node2D
## Two-biome approval adapter. Geometry, simulation and native state are read-only.

const Art := preload("res://tools/reference_slice/world/world_assets.gd")
const Rig := preload("res://tools/reference_slice/world/reference_pendulum.gd")
var main
var density := 48
var biome: StringName = &"meadow"
var records: Array[Dictionary] = []
var walls: Array[Dictionary] = []
var all_walls: Array[Rect2] = []
var rigs: Array[Node2D] = []
var surfaces: Array[Dictionary] = []
var banks: Array[Node2D] = []
var flag: Sprite2D
var elapsed := 0.0
var animation_frame := -1
var board_bounds := Rect2(-600, -400, 1200, 800)

static func background_path(kind: StringName) -> String:
	return Art.ROOT + "backgrounds/" + ("volcanic" if kind == &"volcanic" else "meadow") + ".png"

func setup(owner_main) -> void:
	main = owner_main
	biome = StringName(main.level_builder.active_level.get("biome_id", "meadow"))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var root: Node2D = main.level_builder.level_root
	for child in root.get_children():
		if child.name in ["BiomeBackground", "BiomeBackgroundVariants", "BiomeAmbience", "CupOpening", "FlagAsset"]:
			if child is CanvasItem: child.hide()
		elif child is HazardTelegraph and child.hazard_type == &"pendulum": child.hide()
	var ground := root.get_node("Green")
	var first_cell := true
	for child in ground.get_children():
		if child is CollisionShape2D: continue
		if child is CanvasItem: child.hide()
		if not child.has_meta(&"cell"): continue
		var cell_rect := Rect2(child.position - Vector2(50, 50), Vector2(100, 100))
		board_bounds = cell_rect if first_cell else board_bounds.merge(cell_rect)
		first_cell = false
		var material := "green" if child.get_meta(&"putting_surface", false) else "fairway"
		if biome == &"volcanic": material = "basalt_green" if material == "green" else "basalt"
		var variant := "a" if child.get_meta(&"checker_variant", 0) == 0 else "b"
		var cell: Vector2i = child.get_meta(&"cell")
		var quiet: bool = posmod(cell.x * 5 + cell.y * 11, 13) != 0 or child.get_meta(&"putting_surface", false)
		_attach(ground, "terrain/%s_%s%s" % [material, variant, "_quiet" if quiet else ""], child.position, Vector2(100, 100))
	for child in root.get_children():
		if child is StaticBody2D and child.has_meta(&"collision_kind"):
			var dimensions := _dimensions(child)
			if dimensions != Vector2.ZERO:
				all_walls.append(Rect2(child.position - dimensions * 0.5, dimensions))
	for child in root.get_children():
		if child is MovingHazard and child.hazard_type == &"pendulum":
			var rig := Rig.new()
			add_child(rig)
			rig.setup(child, density)
			rigs.append(rig)
		elif child is GameplayHazard: _surface(child)
		elif child is StaticBody2D and child.has_meta(&"collision_kind"): _wall(child)
	_skirt()
	var tee: Node2D = main.level_builder.tee_marker
	for child in tee.get_children():
		if child is CanvasItem: child.hide()
	_attach(tee, "props/tee", Vector2.ZERO, Vector2(50, 32))
	var ball_art: Node2D = main.ball.get_node("BallArt")
	var previous := ball_art.get_node_or_null("SampleBall")
	if previous:
		ball_art.remove_child(previous)
		previous.queue_free()
	for child in ball_art.get_children():
		if child is CanvasItem: child.hide()
	var diameter: float = main.ball.get_collision_radius() * 2.0
	var ball_sprite := _attach(ball_art, "props/ball", Vector2.ZERO, Vector2.ONE * diameter)
	ball_sprite.name = "SampleBall"
	ball_art.z_index = 24
	flag = _attach(self, "props/flag_a", Vector2.ZERO, Vector2(60, 90))
	flag.centered = false
	# Exported pole/cup origin is at (approximately) x11%, y90% of its canvas.
	flag.position = main.level_builder.level_point(main.level_builder.active_level, "hole", "hole_cell") - Vector2(7, 81)
	flag.z_index = 2

func _attach(parent: Node, path: String, at: Vector2, size: Vector2) -> Sprite2D:
	var sprite := Art.sprite(path, at, size, density)
	parent.add_child(sprite)
	records.append({"sprite": sprite, "path": path, "size": size})
	return sprite

func set_density(value: int) -> void:
	var next_density := 32 if value == 32 else 48
	if next_density == density: return
	density = next_density
	for record in records:
		var sprite: Sprite2D = record.sprite
		if not is_instance_valid(sprite): continue
		sprite.texture = Art.texture(record.path, density)
		sprite.scale = Vector2(record.size) / sprite.texture.get_size()
	for record in walls:
		var sprite: Sprite2D = record.sprite
		if not is_instance_valid(sprite): continue
		sprite.texture = Art.wall_texture(record.size, record.at, all_walls, biome, density)
		sprite.scale = Vector2(record.size) / sprite.texture.get_size()
	for rig in rigs:
		if is_instance_valid(rig): rig.set_density(density)
	for bank in banks:
		if is_instance_valid(bank): bank.set_density(density)
	for record in surfaces: record.frame = -1
	animation_frame = -1
	queue_redraw()

func _dimensions(node: Node) -> Vector2:
	for child in node.get_children():
		if child is CollisionShape2D:
			if child.shape is RectangleShape2D: return child.shape.size
			if child.shape is CircleShape2D: return Vector2.ONE * child.shape.radius * 2.0
	return Vector2.ZERO

func _wall(body: StaticBody2D) -> void:
	var dimensions := _dimensions(body)
	if dimensions == Vector2.ZERO: return
	for child in body.get_children():
		if child is CanvasItem and not child is CollisionShape2D: child.hide()
	var sprite := Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = Art.wall_texture(dimensions, body.position, all_walls, biome, density)
	sprite.scale = dimensions / sprite.texture.get_size()
	body.add_child(sprite)
	walls.append({"sprite": sprite, "size": dimensions, "at": body.position})

func _surface(area: GameplayHazard) -> void:
	if area.hazard_type not in [&"sand", &"water", &"lava", &"ice", &"bounce_pad"]: return
	# Ice is outside this two-biome fixture; preserve its native honest material.
	if area.hazard_type == &"ice": return
	var dimensions := _dimensions(area)
	if dimensions == Vector2.ZERO: return
	for child in area.get_children():
		if child is CanvasItem and not child is CollisionShape2D: child.hide()
	var path := "props/pad" if area.hazard_type == &"bounce_pad" else "terrain/%s_a" % area.hazard_type
	var sprite := _attach(area, path, Vector2.ZERO, dimensions)
	if area.hazard_type in [&"water", &"lava"]:
		var phase := fposmod(area.position.x * 0.0031 + area.position.y * 0.0053, 1.0)
		surfaces.append({"sprite": sprite, "kind": String(area.hazard_type), "phase": phase, "frame": -1})
	# A thin inside bank follows connected native hazard cells. Adjacent tiles
	# remain one pool, and the dangerous boundary still uses its original area.
	if area.hazard_type in [&"water", &"lava", &"sand"]:
		var bank := Node2D.new()
		bank.set_script(preload("res://tools/reference_slice/world/surface_bank.gd"))
		area.add_child(bank)
		bank.setup(area, dimensions, biome, density)
		banks.append(bank)

func _skirt() -> void:
	var outer := board_bounds.grow(42.0)
	var skirt := Polygon2D.new()
	skirt.polygon = PackedVector2Array([
		outer.position, Vector2(outer.end.x, outer.position.y), outer.end + Vector2(0, 28),
		outer.end + Vector2(-20, 42), Vector2(outer.position.x + 20, outer.end.y + 42),
		Vector2(outer.position.x, outer.end.y + 28)])
	skirt.color = Color("262432") if biome == &"volcanic" else Color("1e3838")
	skirt.z_index = -3
	add_child(skirt)
	var side := Polygon2D.new()
	side.polygon = PackedVector2Array([
		Vector2(outer.position.x, outer.end.y - 2), outer.end - Vector2(0, 2),
		outer.end + Vector2(0, 24), outer.end + Vector2(-20, 37),
		Vector2(outer.position.x + 20, outer.end.y + 37), Vector2(outer.position.x, outer.end.y + 24)])
	side.color = Color("4b303a") if biome == &"volcanic" else Color("38554a")
	side.z_index = -2
	add_child(side)
	queue_redraw()

func _draw() -> void:
	if not main: return
	# Hand-authored small grass/rock clusters repeat along the exposed skirt,
	# not along every tile. Cosmetic positions never consume generation RNG.
	var pattern := [0, 3, 2, 7, 1, 4, 6, 1, 3, 5, 2, 0, 4, 2, 6, 1]
	var pitch := 100.0 / density
	var count := roundi((board_bounds.size.x + 84.0) / pitch)
	var left := board_bounds.position.x - 42.0
	var y := board_bounds.end.y + 42.0
	for index in count:
		var height: float = (2 + pattern[index % pattern.size()]) * pitch * 0.65
		var color := Color("694235") if biome == &"volcanic" else Color("5d7c4d")
		if index % 4 == 0: color = Color("ac6740") if biome == &"volcanic" else Color("90a568")
		draw_rect(Rect2(left + index * pitch, y, pitch, height), color)

func _process(delta: float) -> void:
	if not main or not main.run_state.is_playing(): return
	if main.feedback_director.reduced_motion: return
	elapsed += delta
	var frame := int(elapsed * 2.0) % 2
	if frame != animation_frame:
		animation_frame = frame
		if flag: flag.texture = Art.texture("props/flag_a" if frame == 0 else "props/flag_b", density)
	for record in surfaces:
		var surface_frame := int(elapsed * 1.6 + float(record.phase) * 2.0) % 2
		if surface_frame == int(record.frame): continue
		record.frame = surface_frame
		if is_instance_valid(record.sprite): record.sprite.texture = Art.texture("terrain/%s_%s" % [record.kind, "a" if surface_frame == 0 else "b"], density)
