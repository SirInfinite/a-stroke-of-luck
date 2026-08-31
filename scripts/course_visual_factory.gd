class_name CourseVisualFactory
extends RefCounted

const OFF_WHITE := Color("f4f0e6")
const SHADOW := Color(0.035, 0.045, 0.05, 0.48)


static func create_start_marker(tee_color: Color, outline_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = "TeeStartMarker"
	_add_ellipse(root, Vector2(34.0, 24.0), outline_color, Vector2.ZERO, "Outline")
	_add_ellipse(root, Vector2(28.0, 19.0), tee_color, Vector2.ZERO, "TeePad")
	_add_ellipse(root, Vector2(11.0, 7.0), OFF_WHITE.darkened(0.08), Vector2.ZERO, "BallSeat")
	_add_line(root, PackedVector2Array([Vector2(-18.0, 0.0), Vector2(-8.0, 0.0)]), OFF_WHITE, 2.5, "LeftTick")
	_add_line(root, PackedVector2Array([Vector2(8.0, 0.0), Vector2(18.0, 0.0)]), OFF_WHITE, 2.5, "RightTick")
	return root


static func create_green_patch(green_color: Color, outline_color: Color, cup_radius: float) -> Node2D:
	var root := Node2D.new()
	root.name = "PuttingGreen"
	var scale_factor := cup_radius / 28.0
	_add_ellipse(root, Vector2(72.0, 53.0) * scale_factor, outline_color, Vector2.ZERO, "GreenOutline")
	_add_ellipse(root, Vector2(66.0, 47.0) * scale_factor, green_color, Vector2.ZERO, "GreenSurface")
	for angle_index in range(8):
		var angle := TAU * float(angle_index) / 8.0
		var point := Vector2(cos(angle) * 49.0, sin(angle) * 33.0) * scale_factor
		_add_ellipse(root, Vector2(2.3, 1.3), green_color.lightened(0.12), point, "GreenGrain%d" % angle_index)
	return root


static func create_flag(flag_color: Color, outline_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = "FlagAsset"
	_add_ellipse(root, Vector2(11.0, 4.5), SHADOW, Vector2(4.0, -5.0), "FlagShadow")
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
	_add_polygon(root, rounded_rectangle_polygon(size, 12.0), outline_color, Vector2.ZERO, "HazardOutline")
	_add_polygon(root, rounded_rectangle_polygon(size - Vector2(8.0, 8.0), 10.0), base_color, Vector2.ZERO, "HazardSurface")
	match hazard_type:
		"sand":
			_add_sand_pattern(root, size, detail_color)
		"rough":
			_add_rough_pattern(root, size, detail_color)
		"water":
			_add_water_pattern(root, size, detail_color)
		"out":
			_add_out_pattern(root, size, detail_color)
	return root


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


static func _add_out_pattern(root: Node2D, size: Vector2, color: Color) -> void:
	for i in range(-2, 3):
		var x := float(i) * size.x * 0.18
		_add_line(root, PackedVector2Array([Vector2(x - 15.0, -size.y * 0.38), Vector2(x + 15.0, size.y * 0.38)]), color, 4.0, "WarningStripe%d" % (i + 2))


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
