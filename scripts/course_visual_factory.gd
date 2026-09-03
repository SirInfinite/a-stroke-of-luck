class_name CourseVisualFactory
extends RefCounted

const OFF_WHITE := Color("f4f0e6")
const CHARCOAL := Color("252a2c")
const SHADOW := Color(0.035, 0.045, 0.05, 0.48)


static func create_start_marker(tee_color: Color, outline_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = "TeeStartMarker"
	_add_ellipse(root, Vector2(19.0, 8.0), SHADOW, Vector2(3.0, 8.0), "TeeShadow")
	_add_polygon(root, PackedVector2Array([
		Vector2(-7.0, -3.0), Vector2(7.0, -3.0),
		Vector2(4.0, 12.0), Vector2(-4.0, 12.0),
	]), outline_color, Vector2.ZERO, "TeeStemOutline")
	_add_polygon(root, PackedVector2Array([
		Vector2(-4.5, -2.0), Vector2(4.5, -2.0),
		Vector2(2.5, 10.0), Vector2(-2.5, 10.0),
	]), tee_color, Vector2.ZERO, "TeeStem")
	_add_ellipse(root, Vector2(12.0, 5.5), outline_color, Vector2(0.0, -3.0), "TeePadOutline")
	_add_ellipse(root, Vector2(9.0, 3.5), tee_color.lightened(0.22), Vector2(0.0, -3.0), "TeePad")
	_add_ellipse(root, Vector2(6.5, 2.4), Color(CHARCOAL, 0.42), Vector2(0.0, -3.0), "BallSeat")
	return root


static func create_green_patch(green_color: Color, outline_color: Color, _cup_radius: float) -> Node2D:
	var root := Node2D.new()
	root.name = "PuttingSurface"
	_add_polygon(root, _rectangle_polygon(Vector2(66.0, 66.0)), green_color, Vector2.ZERO, "BiomePuttingTile")
	_add_line(root, PackedVector2Array([Vector2(-31.0, -31.0), Vector2(31.0, -31.0)]), Color(outline_color, 0.34), 2.0, "PuttingTileTopEdge")
	for grain_index in range(3):
		var y := -18.0 + float(grain_index) * 17.0
		_add_line(root, PackedVector2Array([Vector2(-23.0, y), Vector2(-7.0, y - 2.0), Vector2(10.0, y + 1.0)]), Color(green_color.lightened(0.12), 0.36), 2.0, "PuttingTileGrain%d" % grain_index)
	return root


static func create_flag(flag_color: Color, outline_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = "FlagAsset"
	_add_line(root, PackedVector2Array([Vector2(0.0, -8.0), Vector2(0.0, -82.0)]), outline_color, 6.0, "PoleOutline")
	_add_line(root, PackedVector2Array([Vector2(0.0, -8.0), Vector2(0.0, -82.0)]), OFF_WHITE, 3.0, "Pole")
	_add_polygon(root, PackedVector2Array([
		Vector2(1.0, -82.0),
		Vector2(50.0, -68.0),
		Vector2(1.0, -54.0),
	]), outline_color, Vector2.ZERO, "FlagOutline")
	_add_polygon(root, PackedVector2Array([
		Vector2(4.0, -78.0),
		Vector2(43.0, -68.0),
		Vector2(4.0, -58.0),
	]), flag_color, Vector2.ZERO, "Flag")
	_add_line(root, PackedVector2Array([Vector2(7.0, -72.0), Vector2(35.0, -66.0)]), flag_color.lightened(0.22), 2.0, "FlagHighlight")
	return root


static func create_hazard_visual(
	hazard_type: String,
	size: Vector2,
	base_color: Color,
	detail_color: Color,
	outline_color: Color
) -> Node2D:
	var root := Node2D.new()
	root.name = "HazardVisual"
	if hazard_type == "bounce_pad":
		var radius := minf(size.x, size.y) * 0.46
		_add_ellipse(root, Vector2(radius + 5.0, radius * 0.5 + 5.0), Color(outline_color, 0.34), Vector2(3.0, 5.0), "BouncePadShadow")
		_add_ellipse(root, Vector2(radius, radius), outline_color, Vector2.ZERO, "BouncePadOuterRing")
		_add_ellipse(root, Vector2(radius - 5.0, radius - 5.0), base_color, Vector2.ZERO, "BouncePadSurface")
		_add_ellipse(root, Vector2(radius * 0.56, radius * 0.56), detail_color, Vector2.ZERO, "BouncePadCore")
		for direction_index in range(4):
			var direction := Vector2.RIGHT.rotated(TAU * float(direction_index) / 4.0)
			var side := direction.orthogonal()
			var arrow_center := direction * radius * 0.7
			_add_polygon(root, PackedVector2Array([
				arrow_center + direction * 4.0,
				arrow_center - direction * 4.0 + side * 3.5,
				arrow_center - direction * 4.0 - side * 3.5,
			]), detail_color, Vector2.ZERO, "BouncePadArrow%d" % direction_index)
		root.set_meta("hazard_type", &"bounce_pad")
		return root
	var embedded_shape := embedded_terrain_polygon(size)
	_add_polygon(root, embedded_shape, Color(outline_color, 0.24), Vector2(2.0, 4.0), "HazardEdgeShadow")
	_add_polygon(root, embedded_shape, base_color, Vector2.ZERO, "HazardSurface")
	_add_line(root, PackedVector2Array([
		Vector2(-size.x * 0.38, -size.y * 0.36),
		Vector2(-size.x * 0.08, -size.y * 0.42),
		Vector2(size.x * 0.24, -size.y * 0.37),
	]), Color(detail_color, 0.28), 2.0, "EmbeddedEdgeHighlight")
	match hazard_type:
		"sand":
			_add_sand_pattern(root, size, detail_color)
		"rough":
			_add_rough_pattern(root, size, detail_color)
		"water":
			_add_water_pattern(root, size, detail_color)
		"ice":
			_add_ice_pattern(root, size, detail_color)
		"lava":
			_add_lava_pattern(root, size, detail_color)
	return root


static func create_moving_hazard_visual(
	hazard_type: StringName,
	size: Vector2,
	primary_color: Color,
	detail_color: Color
) -> Node2D:
	var root := Node2D.new()
	root.name = "MovingHazardVisual_%s" % String(hazard_type)
	root.set_meta("hazard_type", hazard_type)
	match hazard_type:
		&"pendulum", &"spike_ball":
			var radius := maxf(12.0, minf(size.x, size.y) * 0.34)
			_add_ellipse(root, Vector2(radius + 4.0, radius * 0.52), SHADOW, Vector2(4.0, 6.0), "SpikeBallShadow")
			var spikes := PackedVector2Array()
			for point_index in range(24):
				var point_radius := radius * (1.28 if point_index % 2 == 0 else 0.92)
				var angle := TAU * float(point_index) / 24.0
				spikes.append(Vector2(cos(angle), sin(angle)) * point_radius)
			_add_polygon(root, spikes, detail_color.darkened(0.34), Vector2.ZERO, "SpikeSilhouette")
			_add_ellipse(root, Vector2(radius * 0.86, radius * 0.86), primary_color, Vector2.ZERO, "SpikeBall")
			_add_ellipse(root, Vector2(radius * 0.26, radius * 0.26), detail_color, Vector2(-radius * 0.2, -radius * 0.24), "SpikeBallHighlight")
		&"falling_ice":
			var half := size * 0.44
			_add_polygon(root, PackedVector2Array([
				Vector2(-half.x, -half.y * 0.72), Vector2(-half.x * 0.52, -half.y),
				Vector2(half.x * 0.72, -half.y * 0.88), Vector2(half.x, -half.y * 0.22),
				Vector2(half.x * 0.78, half.y), Vector2(-half.x * 0.7, half.y * 0.9),
			]), Color(SHADOW, 0.58), Vector2(4.0, 6.0), "IceBlockShadow")
			_add_polygon(root, PackedVector2Array([
				Vector2(-half.x, -half.y * 0.72), Vector2(-half.x * 0.52, -half.y),
				Vector2(half.x * 0.72, -half.y * 0.88), Vector2(half.x, -half.y * 0.22),
				Vector2(half.x * 0.78, half.y), Vector2(-half.x * 0.7, half.y * 0.9),
			]), primary_color, Vector2.ZERO, "IceBlock")
			_add_line(root, PackedVector2Array([
				Vector2(-half.x * 0.2, -half.y * 0.72), Vector2(half.x * 0.08, -half.y * 0.08),
				Vector2(-half.x * 0.08, half.y * 0.58),
			]), detail_color, 3.0, "IceCrack")
		&"rotating_lava_rod", &"rotating_fire_rod":
			var half_length := maxf(22.0, size.x * 0.5)
			var half_width := maxf(5.0, size.y * 0.22)
			_add_polygon(root, _rectangle_polygon(Vector2(half_length * 2.0, half_width * 2.0)), Color(SHADOW, 0.6), Vector2(3.0, 5.0), "FireRodShadow")
			_add_polygon(root, _rectangle_polygon(Vector2(half_length * 2.0, half_width * 2.0)), primary_color, Vector2.ZERO, "FireRod")
			_add_line(root, PackedVector2Array([Vector2(-half_length * 0.78, 0.0), Vector2(half_length * 0.78, 0.0)]), detail_color, maxf(2.0, half_width * 0.52), "FireRodCore")
			_add_ellipse(root, Vector2(half_width * 1.45, half_width * 1.45), detail_color, Vector2(-half_length, 0.0), "FireEndLeft")
			_add_ellipse(root, Vector2(half_width * 1.45, half_width * 1.45), detail_color, Vector2(half_length, 0.0), "FireEndRight")
			_add_ellipse(root, Vector2(half_width * 0.92, half_width * 0.92), OFF_WHITE, Vector2.ZERO, "FireRodPivot")
		&"fireball":
			var radius := maxf(12.0, minf(size.x, size.y) * 0.34)
			_add_polygon(root, PackedVector2Array([
				Vector2(-radius * 1.8, 0.0), Vector2(-radius * 0.7, -radius * 0.7),
				Vector2(radius * 0.42, -radius), Vector2(radius, 0.0),
				Vector2(radius * 0.42, radius), Vector2(-radius * 0.7, radius * 0.7),
			]), Color(primary_color, 0.72), Vector2.ZERO, "FireballTail")
			_add_ellipse(root, Vector2(radius, radius), primary_color, Vector2.ZERO, "Fireball")
			_add_ellipse(root, Vector2(radius * 0.5, radius * 0.5), detail_color, Vector2(radius * 0.08, -radius * 0.08), "FireballCore")
		_:
			_add_polygon(root, embedded_terrain_polygon(size), primary_color, Vector2.ZERO, "MovingHazardBody")
	return root


static func trajectory_style(terrain_palette: Dictionary, background_palette: Dictionary) -> Dictionary:
	var surfaces: Array[Color] = []
	for key in ["fairway_a", "fairway_b", "green", "sand", "water", "ice", "lava"]:
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


static func create_connected_wall_visual(size: Vector2, color: Color, connections: Dictionary = {}) -> Node2D:
	var root := Node2D.new()
	root.name = "ConnectedWallVisual"
	var shape := _connected_wall_polygon(size, connections)
	_add_polygon(root, shape, SHADOW, Vector2(4.0, 5.0), "WallShadow")
	_add_polygon(root, shape, color, Vector2.ZERO, "WallSurface")
	_add_line(root, PackedVector2Array([
		Vector2(-size.x * 0.42, -size.y * 0.32),
		Vector2(size.x * 0.42, -size.y * 0.32),
	]), Color(color.lightened(0.25), 0.7), 2.0, "WallHighlight")
	root.set_meta("connections", connections.duplicate(true))
	return root


static func create_elevation_cell_visual(
	size: Vector2,
	elevation: int,
	surface_color: Color,
	edge_color: Color
) -> Node2D:
	var root := Node2D.new()
	root.name = "ElevationLevel_%d" % elevation
	root.set_meta("elevation", elevation)
	var vertical_offset := float(-elevation) * 7.0
	if elevation > 0:
		_add_polygon(root, embedded_terrain_polygon(size), Color(edge_color, 0.46), Vector2(5.0, 9.0), "RaisedShadow")
	elif elevation < 0:
		_add_polygon(root, embedded_terrain_polygon(size), Color(edge_color.darkened(0.35), 0.58), Vector2.ZERO, "PitEdge")
	_add_polygon(root, embedded_terrain_polygon(size - Vector2(6.0, 6.0)), surface_color, Vector2(0.0, vertical_offset), "ElevationSurface")
	return root


static func create_ramp_visual(
	size: Vector2,
	from_elevation: int,
	to_elevation: int,
	surface_color: Color,
	edge_color: Color
) -> Node2D:
	var root := Node2D.new()
	root.name = "RampVisual"
	root.set_meta("from_elevation", from_elevation)
	root.set_meta("to_elevation", to_elevation)
	_add_polygon(root, _trapezoid_polygon(size), Color(edge_color, 0.54), Vector2(4.0, 6.0), "RampShadow")
	_add_polygon(root, _trapezoid_polygon(size - Vector2(6.0, 6.0)), surface_color, Vector2.ZERO, "RampSurface")
	for i in range(3):
		var y := lerpf(-size.y * 0.24, size.y * 0.24, float(i) / 2.0)
		_add_line(root, PackedVector2Array([Vector2(-size.x * 0.28, y), Vector2(size.x * 0.28, y)]), Color(edge_color, 0.28 + float(i) * 0.09), 2.0, "RampGrade%d" % i)
	return root


static func create_bridge_visual(size: Vector2, surface_color: Color, edge_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = "BridgeVisual"
	_add_polygon(root, _rectangle_polygon(size + Vector2(4.0, 4.0)), Color(SHADOW, 0.62), Vector2(6.0, 10.0), "BridgeShadow")
	_add_polygon(root, _rectangle_polygon(size), surface_color, Vector2.ZERO, "BridgeDeck")
	_add_line(root, PackedVector2Array([Vector2(-size.x * 0.5, -size.y * 0.38), Vector2(size.x * 0.5, -size.y * 0.38)]), edge_color, 4.0, "BridgeRailTop")
	_add_line(root, PackedVector2Array([Vector2(-size.x * 0.5, size.y * 0.38), Vector2(size.x * 0.5, size.y * 0.38)]), edge_color, 4.0, "BridgeRailBottom")
	return root


static func create_pit_visual(size: Vector2, surface_color: Color, edge_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = "PitVisual"
	_add_polygon(root, embedded_terrain_polygon(size), edge_color.darkened(0.38), Vector2.ZERO, "PitDepth")
	_add_polygon(root, embedded_terrain_polygon(size - Vector2(16.0, 16.0)), surface_color.darkened(0.22), Vector2(3.0, 5.0), "PitFloor")
	_add_line(root, PackedVector2Array([Vector2(-size.x * 0.34, -size.y * 0.34), Vector2(size.x * 0.2, -size.y * 0.38)]), Color(surface_color.lightened(0.26), 0.54), 3.0, "PitRimHighlight")
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


static func create_decoration(
	decoration_id: String,
	primary_color: Color,
	secondary_color: Color,
	accent_color: Color
) -> Node2D:
	var root := Node2D.new()
	root.name = "Decoration_%s" % decoration_id
	root.set_meta("decoration_id", decoration_id)
	match decoration_id:
		"wildflowers", "buttercups", "ice_crystals", "embers":
			_add_bloom_cluster(root, primary_color, accent_color)
		"clover", "fallen_leaves", "lily_pads", "frost_stones":
			_add_ground_cluster(root, primary_color, secondary_color)
		"shrubs", "amber_shrub", "snowdrifts", "mud_pool", "basalt":
			_add_mound_cluster(root, primary_color, secondary_color, accent_color)
		"cactus":
			_add_cactus(root, primary_color, secondary_color)
		"dry_grass", "red_maple", "pine", "reeds", "smoke_vent":
			_add_vertical_cluster(root, primary_color, secondary_color, decoration_id)
		"rocks", "sunstone", "acorns", "mushrooms":
			_add_rock_cluster(root, primary_color, secondary_color, accent_color)
		"lava_crack":
			_add_lava_crack(root, primary_color, accent_color)
		_:
			_add_mound_cluster(root, primary_color, secondary_color, accent_color)
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


static func _connected_wall_polygon(size: Vector2, connections: Dictionary) -> PackedVector2Array:
	var half := size / 2.0
	var bevel := minf(6.0, minf(half.x, half.y) * 0.45)
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
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	parent.add_child(line)
	return line
