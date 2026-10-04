class_name CourseVisualFactory
extends RefCounted

const Art := preload("res://scripts/presentation/world_art.gd")
const WorldSurface := preload("res://scripts/presentation/world_surface.gd")
const WorldWall := preload("res://scripts/presentation/world_wall.gd")

const OFF_WHITE := Color("f4f0e6")
const CHARCOAL := Color("252a2c")
const SHADOW := Color(0.035, 0.045, 0.05, 0.48)
const BOUNCE_PAD_YELLOW := Color("f6c945")
const BOUNCE_PAD_GOLD := Color("d88918")
const BOUNCE_PAD_HIGHLIGHT := Color("fff1a6")
const BOUNCE_PAD_ENERGY_INK := Color("5b410d")

static func create_grass_motif(tile_color: Color, biome: StringName, seed_value: int) -> Node2D:
	var root := Node2D.new()
	root.name = "GrassMotif"
	var count := 1 + posmod(seed_value, 2)
	var ink := tile_color.darkened(0.22)
	for index in range(count):
		var at := Vector2(-18 + index * 13, 19 + posmod(seed_value, 9))
		var points := PackedVector2Array([at + Vector2(-3, 1), at + Vector2(0, -5), at + Vector2(3, 1)])
		if biome == &"volcanic":
			points = PackedVector2Array([at + Vector2(-4, -2), at, at + Vector2(-1, 4)])
		_add_line(root, points, ink, 1.8, "Blade%d" % index)
	return root

class SurfaceMotion:
	extends Node2D
	const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
	var kind := "water"
	var dimensions := Vector2(100, 100)
	var tint := Color.WHITE
	var elapsed := 0.0
	var redraw_elapsed := 0.0

	func _process(delta: float) -> void:
		if not is_visible_in_tree() or not UIStyleScript.motion_enabled(self):
			return
		elapsed += delta
		redraw_elapsed += delta
		if redraw_elapsed >= 1.0 / 24.0:
			redraw_elapsed = 0.0
			queue_redraw()

	func _draw() -> void:
		if kind == "bounce_pad":
			for index in range(4):
				var ray := Vector2.RIGHT.rotated(PI * 0.5 * float(index))
				var side := ray.orthogonal()
				var phase := fmod(elapsed * 0.65, 1.0)
				var center := ray * dimensions.x * (0.33 + phase * 0.12)
				draw_polyline(PackedVector2Array([center-ray*4.0-side*4.0,center,center-ray*4.0+side*4.0]), Color(tint, 0.8*(1.0-phase)), 2.0, true)
		else:
			for index in range(2):
				var point := Vector2(-dimensions.x*0.21+float(index)*dimensions.x*0.39, sin(elapsed*0.6+index)*dimensions.y*0.19)
				var radius := 4.0 + (sin(elapsed * 0.8 + index) + 1.0) * 2.0
				draw_arc(point, radius, 0.0, PI*1.4, 18, Color(tint, 0.3), 1.5, true)


static func create_start_marker(_tee_color: Color, _outline_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = "TeeStartMarker"
	var tee := Art.sprite("objects/tee",Vector2(-11,-6))
	tee.name = "TeeStem"
	tee.centered = false
	tee.scale = Vector2(2,2)
	root.add_child(tee)
	var seat := Marker2D.new()
	seat.name = "BallSeat"
	root.add_child(seat)
	root.set_meta(&"tee_art_count",1)
	return root


static func create_flag(_flag_color: Color, _outline_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = "FlagAsset"
	root.set_script(preload("res://scripts/presentation/world_flag.gd"))
	return root


static func create_hazard_visual(hazard_type: String, size: Vector2, _base_color: Color, _detail_color: Color, _outline_color: Color, connections: Dictionary = {}) -> Node2D:
	var root := Node2D.new()
	root.name = "HazardVisual"
	root.set_meta(&"hazard_type",StringName(hazard_type))
	root.set_meta(&"visual_connections",connections.duplicate())
	root.set_meta(&"visual_footprint",size)
	if hazard_type == "rough":
		var tuft := Art.sprite("terrain/rough",Vector2.ZERO,size)
		tuft.name = "RoughTuft0"
		root.add_child(tuft)
		return root
	var material := WorldSurface.new()
	material.name = "HazardSurface"
	material.configure(hazard_type,size,connections)
	root.add_child(material)
	return root


static func _add_surface_motion(root: Node2D, kind: String, dimensions: Vector2, tint: Color) -> void:
	var motion := SurfaceMotion.new()
	motion.name = "SurfaceMotion"
	motion.kind = kind
	motion.dimensions = dimensions
	motion.tint = tint
	root.add_child(motion)


static func create_moving_hazard_visual(hazard_type: StringName, size: Vector2, _primary_color: Color, _detail_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = "MovingHazardVisual_%s" % hazard_type
	root.set_meta(&"hazard_type",hazard_type)
	root.set_meta(&"visual_footprint",Vector2(100,100) if hazard_type==&"falling_ice" else size)
	var path := "objects/pendulum"
	var visual_name := "StoneMass"
	if hazard_type==&"falling_ice": path="objects/ice_block"; visual_name="IceBlock"; size=Vector2(100,100)
	elif hazard_type in [&"rotating_lava_rod",&"rotating_fire_rod"]: path="objects/fire_rod"; visual_name="FireRod"
	elif hazard_type==&"fireball": path="terrain/lava_a"; visual_name="Fireball"
	var sprite := Art.sprite(path,Vector2.ZERO,size)
	sprite.name = visual_name
	root.add_child(sprite)
	var center := Marker2D.new()
	center.name = "ContactCenter"
	root.add_child(center)
	return root


static func trajectory_style(terrain_palette: Dictionary, background_palette: Dictionary) -> Dictionary:
	var surfaces: Array[Color] = []
	for key in ["fairway_a", "fairway_b", "green_a", "green_b", "sand", "water", "ice", "lava"]:
		if terrain_palette.has(key):
			surfaces.append(terrain_palette[key])
	if background_palette.has("primary"):
		surfaces.append(background_palette.primary)
	var light_min_contrast := INF
	var dark_min_contrast := INF
	for surface in surfaces:
		light_min_contrast = minf(light_min_contrast, _contrast_ratio(OFF_WHITE, surface))
		dark_min_contrast = minf(dark_min_contrast, _contrast_ratio(CHARCOAL, surface))
	var primary := OFF_WHITE if light_min_contrast >= dark_min_contrast else CHARCOAL
	var backing := CHARCOAL if primary == OFF_WHITE else OFF_WHITE
	return {
		"primary": Color(primary, 0.86),
		"backing": Color(backing, 0.58),
		"halo": Color(backing, 0.22),
		"minimum_contrast": maxf(light_min_contrast, dark_min_contrast),
	}


static func create_connected_wall_visual(size: Vector2, _color: Color, connections: Dictionary = {}, world_origin := Vector2.ZERO, biome: StringName = &"meadow") -> Node2D:
	var root := Node2D.new()
	root.name = "ConnectedWallVisual"
	root.set_meta(&"connections",connections.duplicate())
	root.set_meta(&"visual_footprint",size)
	var face := WorldWall.new()
	face.name = "WallSurface"
	face.configure(size,world_origin,biome)
	root.add_child(face)
	return root


static func create_elevation_cell_visual(size: Vector2, elevation: int, _surface_color: Color, edge_color: Color, biome: StringName = &"meadow", cell := Vector2i.ZERO, putting := false) -> Node2D:
	var root := Node2D.new()
	root.name = "ElevationLevel_%d"%elevation
	root.set_meta(&"elevation",elevation)
	if elevation>0: _add_polygon(root,_rectangle_polygon(size),Color(edge_color.darkened(0.3),0.7),Vector2(5,9),"RaisedShadow")
	var surface := Art.floor_sprite(biome,cell,putting,size)
	surface.name = "ElevationSurface"
	root.add_child(surface)
	if elevation<0: _add_polygon(root,_rectangle_polygon(Vector2(size.x,10)),Color(SHADOW,0.34),Vector2(0,-size.y*0.5+5),"UpperWallShadow")
	return root


static func create_ramp_visual(size: Vector2, from_elevation: int, to_elevation: int, _surface_color: Color, edge_color: Color, biome: StringName = &"meadow") -> Node2D:
	var root := Node2D.new()
	root.name = "RampVisual"
	root.set_meta(&"from_elevation",from_elevation)
	root.set_meta(&"to_elevation",to_elevation)
	_add_polygon(root,_rectangle_polygon(size),Color(edge_color,0.6),Vector2(3,5),"RampShadow")
	var surface := Art.floor_sprite(biome,Vector2i.ZERO,false,size)
	surface.name = "RampSurface"
	root.add_child(surface)
	for index in 3:
		var x := lerpf(-size.x*0.35,size.x*0.35,index/2.0)
		var strength := 0.1+index*0.07 if to_elevation<from_elevation else 0.24-index*0.07
		_add_polygon(root,_rectangle_polygon(Vector2(2.083,size.y*0.85)),Color("172d35",strength),Vector2(x,0),"RampGrade%d"%index)
	return root


static func create_bridge_visual(size: Vector2, _surface_color: Color, edge_color: Color, biome: StringName = &"meadow", cell := Vector2i.ZERO, putting := false) -> Node2D:
	var root := Node2D.new()
	root.name = "BridgeVisual"
	_add_polygon(root,_rectangle_polygon(size),Color(SHADOW,0.62),Vector2(5,9),"BridgeShadow")
	var surface := Art.floor_sprite(biome,cell,putting,size)
	surface.name = "BridgeDeck"
	root.add_child(surface)
	for side in [-1.0,1.0]:
		_add_polygon(root,_rectangle_polygon(Vector2(size.x,4.1667)),edge_color,Vector2(0,side*(size.y*0.5-2.083)),"BridgeRailTop" if side<0 else "BridgeRailBottom")
	return root


static func create_pit_visual(size: Vector2, surface_color: Color, edge_color: Color) -> Node2D:
	return create_lower_course_visual(size, surface_color, edge_color)


static func create_lower_course_visual(size: Vector2, _surface_color: Color, edge_color: Color, connections: Dictionary = {}, biome: StringName = &"meadow", cell := Vector2i.ZERO, putting := false) -> Node2D:
	var root := Node2D.new()
	root.name = "LowerCourseVisual"
	var surface := Art.floor_sprite(biome,cell,putting,size)
	surface.name = "LowerCourseSurface"
	root.add_child(surface)
	var edge := Node2D.new()
	edge.name = "LowerCourseEdge"
	root.add_child(edge)
	for side in ["up","right","down","left"]:
		if bool(connections.get(side,false)): continue
		var extent := Vector2(size.x,4.1667) if side in ["up","down"] else Vector2(4.1667,size.y)
		var at := Vector2(0,-size.y*0.5+2.083) if side=="up" else Vector2(0,size.y*0.5-2.083) if side=="down" else Vector2(-size.x*0.5+2.083,0) if side=="left" else Vector2(size.x*0.5-2.083,0)
		_add_polygon(edge,_rectangle_polygon(extent),edge_color,at,side)
	if not bool(connections.get("up",false)):
		_add_polygon(root,_rectangle_polygon(Vector2(size.x,12)),Color(SHADOW,0.30),Vector2(0,-size.y*0.5+6),"UpperWallShadow")
	return root


static func create_hazard_telegraph(
	hazard_type: StringName,
	size: Vector2,
	path_points: PackedVector2Array,
	danger_color: Color
) -> Node2D:
	var root := Node2D.new()
	root.name = "HazardTelegraph_%s" % String(hazard_type)
	root.set_meta("hazard_type", hazard_type)
	if path_points.size() >= 2:
		_add_line(root, path_points, Color(danger_color, 0.34), 4.0, "MotionPath")
	match hazard_type:
		&"falling_ice":
			_add_polygon(root, embedded_terrain_polygon(size), Color(danger_color, 0.13), Vector2.ZERO, "DangerRegion")
			for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var point: Vector2 = corner * size * 0.43
				_add_line(root, PackedVector2Array([point-Vector2(corner.x*12,0),point,point-Vector2(0,corner.y*12)]), Color(danger_color,0.85), 3.0, "FallCorner")
			_add_line(root, PackedVector2Array([Vector2(-size.x * 0.26, 0.0), Vector2(size.x * 0.26, 0.0)]), Color(danger_color, 0.72), 3.0, "FallTimingBar")
		&"rotating_lava_rod", &"rotating_fire_rod":
			_add_arc_lines(root, maxf(size.x, size.y) * 0.5, danger_color)
		&"pendulum", &"spike_ball":
			_add_arc_lines(root, maxf(size.x, size.y) * 0.5, danger_color)
		&"fireball":
			_spawn_chevrons(root, path_points, danger_color)
		_:
			_add_polygon(root, embedded_terrain_polygon(size), Color(danger_color, 0.1), Vector2.ZERO, "DangerRegion")
	return root


static func embedded_terrain_polygon(size: Vector2) -> PackedVector2Array:
	var half := size / 2.0
	return PackedVector2Array([
		Vector2(-half.x, -half.y * 0.72),
		Vector2(-half.x * 0.72, -half.y),
		Vector2(-half.x * 0.16, -half.y * 0.94),
		Vector2(half.x * 0.34, -half.y),
		Vector2(half.x, -half.y * 0.68),
		Vector2(half.x * 0.94, -half.y * 0.08),
		Vector2(half.x, half.y * 0.62),
		Vector2(half.x * 0.58, half.y),
		Vector2(0.0, half.y * 0.92),
		Vector2(-half.x * 0.58, half.y),
		Vector2(-half.x, half.y * 0.6),
		Vector2(-half.x * 0.94, 0.0),
	])


static func create_decoration(decoration_id: String, _primary_color: Color, _secondary_color: Color, _accent_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = "Decoration_%s"%decoration_id
	root.set_meta(&"decoration_id",decoration_id)
	var asset := "flowers"
	if decoration_id in ["shrubs","clover"]: asset="willow"
	elif decoration_id in ["cactus","dry_grass"]: asset="cactus"
	elif decoration_id in ["red_maple","fallen_leaves","amber_shrub","acorns"]: asset="maple"
	elif decoration_id in ["pine","snowdrifts"]: asset="spruce"
	elif decoration_id in ["ice_crystals","frost_stones"]: asset="ice_block"
	elif decoration_id in ["reeds","mud_pool","lily_pads","mushrooms"]: asset="cypress"
	elif decoration_id in ["rocks","sunstone","basalt","lava_crack","smoke_vent","embers"]: asset="basalt_columns"
	var picture := Art.sprite("objects/"+asset)
	picture.name = "Illustration"
	picture.scale=Vector2(2,2)
	root.add_child(picture)
	return root


static func rounded_rectangle_polygon(size: Vector2, corner_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var half := size / 2.0
	var radius := minf(corner_radius, minf(half.x, half.y))
	var centers := [
		Vector2(half.x - radius, half.y - radius),
		Vector2(-half.x + radius, half.y - radius),
		Vector2(-half.x + radius, -half.y + radius),
		Vector2(half.x - radius, -half.y + radius),
	]
	var starts := [0.0, PI * 0.5, PI, PI * 1.5]
	for corner_index in range(4):
		for segment_index in range(5):
			var angle: float = float(starts[corner_index]) + PI * 0.5 * float(segment_index) / 4.0
			points.append(centers[corner_index] + Vector2(cos(angle), sin(angle)) * radius)
	return points


static func ellipse_polygon(radii: Vector2, segments := 28) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


static func _organic_ellipse_polygon(radii: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		var wobble := 1.0 + sin(angle * 3.0 + 0.7) * 0.035 + cos(angle * 5.0) * 0.025
		points.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y) * wobble)
	return points


static func _connected_wall_polygon(size: Vector2, connections: Dictionary, bevel_size := 6.0) -> PackedVector2Array:
	var half := size / 2.0
	var bevel := minf(bevel_size, minf(half.x, half.y) * 0.45)
	var left_connected := bool(connections.get("left", false))
	var right_connected := bool(connections.get("right", false))
	var top_connected := bool(connections.get("top", false))
	var bottom_connected := bool(connections.get("bottom", false))
	var top_left_bevel := bevel if not left_connected and not top_connected else 0.0
	var top_right_bevel := bevel if not right_connected and not top_connected else 0.0
	var bottom_right_bevel := bevel if not right_connected and not bottom_connected else 0.0
	var bottom_left_bevel := bevel if not left_connected and not bottom_connected else 0.0
	return PackedVector2Array([
		Vector2(-half.x + top_left_bevel, -half.y),
		Vector2(half.x - top_right_bevel, -half.y),
		Vector2(half.x, -half.y + top_right_bevel),
		Vector2(half.x, half.y - bottom_right_bevel),
		Vector2(half.x - bottom_right_bevel, half.y),
		Vector2(-half.x + bottom_left_bevel, half.y),
		Vector2(-half.x, half.y - bottom_left_bevel),
		Vector2(-half.x, -half.y + top_left_bevel),
	])


static func _trapezoid_polygon(size: Vector2) -> PackedVector2Array:
	var half := size / 2.0
	return PackedVector2Array([
		Vector2(-half.x * 0.72, -half.y),
		Vector2(half.x * 0.72, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])


static func _rectangle_polygon(size: Vector2) -> PackedVector2Array:
	var half := size / 2.0
	return PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])


static func _scaled_points(points: PackedVector2Array, scale_factor: float) -> PackedVector2Array:
	var scaled := PackedVector2Array()
	for point in points:
		scaled.append(point * scale_factor)
	return scaled


static func _contrast_ratio(first: Color, second: Color) -> float:
	var first_luminance := _relative_luminance(first)
	var second_luminance := _relative_luminance(second)
	var lighter := maxf(first_luminance, second_luminance)
	var darker := minf(first_luminance, second_luminance)
	return (lighter + 0.05) / (darker + 0.05)


static func _relative_luminance(color: Color) -> float:
	return (
		0.2126 * _linear_channel(color.r)
		+ 0.7152 * _linear_channel(color.g)
		+ 0.0722 * _linear_channel(color.b)
	)


static func _linear_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)


static func _add_sand_pattern(root: Node2D, size: Vector2, color: Color) -> void:
	for i in range(7):
		var x := lerpf(-size.x * 0.34, size.x * 0.34, float(i % 4) / 3.0)
		var y := -size.y * 0.22 + float(i / 4) * size.y * 0.38 + float(i % 2) * 7.0
		_add_ellipse(root, Vector2(2.5, 1.7), color, Vector2(x, y), "SandGrain%d" % i)
	_add_line(root, PackedVector2Array([Vector2(-size.x * 0.3, size.y * 0.2), Vector2(0.0, size.y * 0.14), Vector2(size.x * 0.3, size.y * 0.2)]), color, 2.0, "SandRidge")


static func _add_rough_pattern(root: Node2D, size: Vector2, color: Color) -> void:
	for i in range(5):
		var x := lerpf(-size.x * 0.32, size.x * 0.32, float(i) / 4.0)
		var y := -8.0 if i % 2 == 0 else 12.0
		_add_line(root, PackedVector2Array([Vector2(x - 5.0, y + 7.0), Vector2(x, y - 7.0), Vector2(x + 5.0, y + 7.0)]), color, 2.2, "RoughTuft%d" % i)


static func _add_water_pattern(root: Node2D, size: Vector2, color: Color) -> void:
	for i in range(3):
		var y := -size.y * 0.22 + float(i) * size.y * 0.22
		_add_line(root, PackedVector2Array([
			Vector2(-size.x * 0.34, y),
			Vector2(-size.x * 0.12, y - 4.0),
			Vector2(size.x * 0.1, y + 4.0),
			Vector2(size.x * 0.34, y),
		]), color, 2.5, "WaterRipple%d" % i)


static func _add_ice_pattern(root: Node2D, size: Vector2, color: Color) -> void:
	_add_line(root, PackedVector2Array([
		Vector2(-size.x * 0.34, size.y * 0.2),
		Vector2(-size.x * 0.12, -size.y * 0.08),
		Vector2(size.x * 0.04, size.y * 0.04),
		Vector2(size.x * 0.3, -size.y * 0.24),
	]), Color(color, 0.74), 2.4, "IceCrack")
	_add_line(root, PackedVector2Array([
		Vector2(-size.x * 0.3, -size.y * 0.29),
		Vector2(size.x * 0.22, -size.y * 0.35),
	]), Color(OFF_WHITE, 0.48), 3.0, "IceSheen")


static func _add_lava_pattern(root: Node2D, size: Vector2, color: Color) -> void:
	for i in range(3):
		var y := lerpf(-size.y * 0.25, size.y * 0.25, float(i) / 2.0)
		_add_line(root, PackedVector2Array([
			Vector2(-size.x * 0.34, y),
			Vector2(-size.x * 0.12, y - 5.0),
			Vector2(size.x * 0.08, y + 4.0),
			Vector2(size.x * 0.32, y - 2.0),
		]), Color(color, 0.78 - float(i) * 0.12), 3.5, "LavaFlow%d" % i)


static func _add_arc_lines(root: Node2D, radius: float, color: Color) -> void:
	for arc_index in range(2):
		var arc := Line2D.new()
		arc.name = "DangerArc%d" % arc_index
		arc.width = 3.0
		arc.default_color = Color(color, 0.38 + float(arc_index) * 0.12)
		arc.begin_cap_mode = Line2D.LINE_CAP_ROUND
		arc.end_cap_mode = Line2D.LINE_CAP_ROUND
		var points := PackedVector2Array()
		for point_index in range(9):
			var angle := lerpf(-PI * 0.72, PI * 0.72, float(point_index) / 8.0) + float(arc_index) * PI
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		arc.points = points
		root.add_child(arc)


static func _spawn_chevrons(root: Node2D, path_points: PackedVector2Array, color: Color) -> void:
	if path_points.size() < 2:
		return
	var direction := (path_points[-1] - path_points[0]).normalized()
	var side := direction.orthogonal() * 6.0
	for i in range(1, 4):
		var point := path_points[0].lerp(path_points[-1], float(i) / 4.0)
		_add_line(root, PackedVector2Array([
			point - direction * 7.0 - side,
			point,
			point - direction * 7.0 + side,
		]), Color(color, 0.58), 2.5, "PathChevron%d" % i)


static func _add_bloom_cluster(root: Node2D, primary: Color, accent: Color) -> void:
	var centers := [Vector2(-13.0, 5.0), Vector2(0.0, -5.0), Vector2(14.0, 6.0)]
	for i in range(centers.size()):
		for petal_index in range(5):
			var angle := TAU * float(petal_index) / 5.0
			_add_ellipse(root, Vector2(4.0, 2.2), primary, centers[i] + Vector2(cos(angle), sin(angle)) * 5.0, "Petal%d_%d" % [i, petal_index], angle)
		_add_ellipse(root, Vector2(2.3, 2.3), accent, centers[i], "BloomCenter%d" % i)


static func _add_ground_cluster(root: Node2D, primary: Color, secondary: Color) -> void:
	for i in range(5):
		var angle := TAU * float(i) / 5.0
		var leaf := PackedVector2Array([Vector2(-7.0, 0.0), Vector2(0.0, -4.0), Vector2(8.0, 0.0), Vector2(0.0, 4.0)])
		_add_polygon(root, leaf, primary if i % 2 == 0 else secondary, Vector2(cos(angle) * 13.0, sin(angle) * 7.0), "GroundLeaf%d" % i, angle)


static func _add_mound_cluster(root: Node2D, primary: Color, secondary: Color, accent: Color) -> void:
	_add_ellipse(root, Vector2(28.0, 8.0), SHADOW, Vector2(3.0, 9.0), "Shadow")
	_add_ellipse(root, Vector2(23.0, 14.0), secondary, Vector2.ZERO, "MoundBack")
	_add_ellipse(root, Vector2(15.0, 12.0), primary, Vector2(-9.0, -5.0), "MoundLeft")
	_add_ellipse(root, Vector2(13.0, 10.0), accent, Vector2(10.0, -3.0), "MoundRight")


static func _add_cactus(root: Node2D, primary: Color, secondary: Color) -> void:
	_add_ellipse(root, Vector2(18.0, 6.0), SHADOW, Vector2(4.0, 21.0), "Shadow")
	_add_polygon(root, rounded_rectangle_polygon(Vector2(13.0, 48.0), 6.0), primary, Vector2(0.0, -3.0), "CactusStem")
	_add_polygon(root, rounded_rectangle_polygon(Vector2(22.0, 10.0), 5.0), primary, Vector2(-8.0, -4.0), "CactusArmLeft", -0.45)
	_add_polygon(root, rounded_rectangle_polygon(Vector2(20.0, 10.0), 5.0), primary, Vector2(9.0, 5.0), "CactusArmRight", 0.48)
	_add_line(root, PackedVector2Array([Vector2(-2.0, -22.0), Vector2(-2.0, 16.0)]), secondary, 2.0, "CactusHighlight")


static func _add_vertical_cluster(root: Node2D, primary: Color, secondary: Color, style: String) -> void:
	_add_ellipse(root, Vector2(22.0, 6.0), SHADOW, Vector2(3.0, 17.0), "Shadow")
	var height := 34.0 if style != "pine" else 50.0
	for i in range(5):
		var x := lerpf(-14.0, 14.0, float(i) / 4.0)
		var tip_y := -height + absf(x) * 0.65
		_add_line(root, PackedVector2Array([Vector2(x, 15.0), Vector2(x * 0.45, tip_y)]), primary if i % 2 == 0 else secondary, 4.0, "Stem%d" % i)
	if style == "pine" or style == "red_maple":
		_add_polygon(root, PackedVector2Array([Vector2(0.0, -52.0), Vector2(-23.0, 4.0), Vector2(23.0, 4.0)]), secondary, Vector2.ZERO, "CanopyBack")
		_add_polygon(root, PackedVector2Array([Vector2(0.0, -42.0), Vector2(-17.0, 12.0), Vector2(17.0, 12.0)]), primary, Vector2.ZERO, "CanopyFront")


static func _add_rock_cluster(root: Node2D, primary: Color, secondary: Color, accent: Color) -> void:
	_add_ellipse(root, Vector2(25.0, 7.0), SHADOW, Vector2(3.0, 11.0), "Shadow")
	_add_polygon(root, PackedVector2Array([Vector2(-22.0, 8.0), Vector2(-15.0, -9.0), Vector2(-2.0, -15.0), Vector2(8.0, 8.0)]), primary, Vector2.ZERO, "RockLarge")
	_add_polygon(root, PackedVector2Array([Vector2(2.0, 9.0), Vector2(10.0, -8.0), Vector2(23.0, -2.0), Vector2(25.0, 10.0)]), secondary, Vector2.ZERO, "RockSmall")
	_add_line(root, PackedVector2Array([Vector2(-14.0, -6.0), Vector2(-3.0, -10.0)]), accent, 2.0, "RockHighlight")


static func _add_lava_crack(root: Node2D, primary: Color, accent: Color) -> void:
	_add_line(root, PackedVector2Array([Vector2(-29.0, -8.0), Vector2(-13.0, -2.0), Vector2(-5.0, -10.0), Vector2(8.0, 2.0), Vector2(28.0, -4.0)]), primary.darkened(0.45), 8.0, "CrackShadow")
	_add_line(root, PackedVector2Array([Vector2(-29.0, -8.0), Vector2(-13.0, -2.0), Vector2(-5.0, -10.0), Vector2(8.0, 2.0), Vector2(28.0, -4.0)]), accent, 3.0, "LavaGlow")
	_add_ellipse(root, Vector2(4.0, 2.5), Color(accent, 0.72), Vector2(13.0, -11.0), "HotFragment")


static func _add_ellipse(
	parent: Node,
	radii: Vector2,
	color: Color,
	position := Vector2.ZERO,
	visual_name := "Ellipse",
	rotation := 0.0
) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = visual_name
	polygon.position = position
	polygon.rotation = rotation
	polygon.polygon = ellipse_polygon(radii)
	polygon.color = color
	parent.add_child(polygon)
	return polygon


static func _add_polygon(
	parent: Node,
	points: PackedVector2Array,
	color: Color,
	position := Vector2.ZERO,
	visual_name := "Polygon",
	rotation := 0.0
) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = visual_name
	polygon.position = position
	polygon.rotation = rotation
	polygon.polygon = points
	polygon.antialiased = false
	polygon.color = color
	parent.add_child(polygon)
	return polygon


static func _add_line(
	parent: Node,
	points: PackedVector2Array,
	color: Color,
	width: float,
	visual_name := "Line"
) -> Line2D:
	var line := Line2D.new()
	line.name = visual_name
	line.points = points
	line.default_color = color
	line.width = width
	line.antialiased = false
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	parent.add_child(line)
	return line
