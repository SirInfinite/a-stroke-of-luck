class_name LevelBuilder
extends Node

const CourseVisualFactory := preload("res://scripts/course_visual_factory.gd")
const BiomeAmbienceScript := preload("res://scripts/biome_ambience.gd")
const LevelValidatorScript := preload("res://scripts/level_validator.gd")
const GameplayHazardScript := preload("res://scripts/gameplay_hazard.gd")
const MovingHazardScript := preload("res://scripts/moving_hazard.gd")
const ElevationRampScript := preload("res://scripts/elevation_ramp.gd")
const HazardTelegraphScript := preload("res://scripts/hazard_telegraph.gd")

signal hole_body_entered(body: Node2D)
signal sand_body_entered(body: Node2D)
signal sand_body_exited(body: Node2D)
signal direction_body_entered(body: Node2D, area: Area2D)
signal direction_body_exited(body: Node2D, area: Area2D)
signal reset_hazard_body_entered(body: Node2D, hazard_position: Vector2, hazard_type: StringName)
signal bounce_pad_triggered(strength: float, pad_type: StringName, position: Vector2)
signal hazard_triggered(hazard_type: StringName, intensity: float, position: Vector2)
signal elevation_transitioned(body: Node2D, from_elevation: int, to_elevation: int)

const GRID_CELL_SIZE := 100.0
const WALL_THICKNESS := 30.0
const ELEVATION_Z_STRIDE := 8
const ELEVATION_Z_OFFSET := 1
const GREEN_DARK := Color(0.232, 0.554, 0.248, 1.0)
const GREEN_DARKER := Color(0.161, 0.447, 0.201, 1.0)
const BORDER_BROWN := Color(0.34, 0.19, 0.09)

var level_root: Node2D
var active_terrain_palette: Dictionary = {}
var active_background_palette: Dictionary = {}
var active_level: Dictionary = {}
var elevation_lookup: Dictionary = {}
var tee_marker: Node2D


func build_level(level: Dictionary, parent: Node) -> Node2D:
	if not LevelValidatorScript.validate_level(level, int(level.get("overall_hole_number", 1)) - 1):
		push_error("LevelBuilder refused an invalid level definition.")
		return null
	active_level = level
	_rebuild_elevation_lookup(level)
	active_terrain_palette = level.get("terrain_palette", {}).duplicate(true)
	active_background_palette = level.get("background_palette", {}).duplicate(true)
	level_root = Node2D.new()
	level_root.name = "Level"
	level_root.z_index = -1
	parent.add_child(level_root)

	_create_background(level)
	_create_course(level)
	_create_elevation_presentation(level)
	_create_start_marker(
		level_point(level, "start", "start_cell"),
		int(level.get("start_elevation", 0))
	)
	_create_hole(
		level_point(level, "hole", "hole_cell"),
		float(level.get("cup_radius", 28.0)),
		int(level.get("hole_elevation", 0))
	)
	_create_hazards(level)
	_create_moving_hazards(level)
	_create_elevation_ramps(level)

	for obstacle in level.obstacles:
		_create_box(
			obstacle.pos,
			obstacle.size,
			_terrain_color("border", BORDER_BROWN),
			&"blocker",
			int(obstacle.get("elevation", 0))
		)
	_create_decorations(level)

	return level_root


func set_gameplay_simulation_paused(paused: bool) -> void:
	if not level_root:
		return
	level_root.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT


func reset_dynamic_hazards() -> void:
	if not level_root:
		return
	for child in level_root.get_children():
		if child.has_method("reset_state"):
			child.reset_state()


func get_elevation_presentation_data() -> Dictionary:
	return {
		"cells": active_level.get("elevation_cells", []),
		"transitions": active_level.get("elevation_transitions", []),
		"structures": active_level.get("elevation_structures", []),
		"tee": active_level.get("tee", {}),
	}


func get_start_elevation(level: Dictionary) -> int:
	return int(level.get("start_elevation", 0))


func on_ball_left_tee(_position: Vector2, _elevation: int) -> void:
	if tee_marker:
		tee_marker.visible = false


func level_point(level: Dictionary, world_key: String, cell_key: String) -> Vector2:
	if level.has(cell_key):
		return _cell_to_world(level, level[cell_key])
	return level.get(world_key, Vector2.ZERO)


func _create_course(level: Dictionary) -> void:
	_create_floor(level)
	_create_bounds(level)


func _create_background(level: Dictionary) -> void:
	var map_size := _map_size(level)
	var surround_size := map_size + Vector2(1400.0, 1000.0)

	var backdrop := Polygon2D.new()
	backdrop.name = "BiomeBackground"
	backdrop.z_index = -2
	backdrop.polygon = _rectangle_polygon(surround_size)
	backdrop.color = _background_color("primary", Color(0.48, 0.66, 0.35))
	level_root.add_child(backdrop)

	var background_shapes := Node2D.new()
	background_shapes.name = "BiomeBackgroundVariants"
	background_shapes.z_index = -1
	level_root.add_child(background_shapes)
	var secondary := _background_color("secondary", backdrop.color.lightened(0.08))
	var highlight := _background_color("highlight", secondary.lightened(0.12))
	for i in range(8):
		var patch := Polygon2D.new()
		patch.name = "BackgroundPatch%d" % (i + 1)
		var side := -1.0 if i % 2 == 0 else 1.0
		var row := -1.0 if i % 4 < 2 else 1.0
		patch.position = Vector2(side * (map_size.x * 0.5 + 150.0 + float(i % 3) * 90.0), row * (map_size.y * 0.5 + 100.0 + float(i % 2) * 75.0))
		patch.rotation = float(i) * 0.43
		patch.polygon = _ellipse_polygon(Vector2(95.0 + float(i % 3) * 24.0, 42.0 + float(i % 2) * 16.0), 20)
		patch.color = Color(secondary if i % 3 != 0 else highlight, 0.36)
		background_shapes.add_child(patch)

	var ambience = BiomeAmbienceScript.new()
	ambience.name = "BiomeAmbience"
	ambience.configure(
		StringName(level.get("ambience", &"meadow_breeze")),
		secondary,
		_background_color("accent", highlight),
		map_size,
		surround_size,
		int(level.get("run_seed", 1)) + int(level.get("overall_hole_number", 1)) * 7919
	)
	level_root.add_child(ambience)


func _create_floor(level: Dictionary) -> void:
	var body := StaticBody2D.new()
	body.name = "Green"
	body.collision_layer = 2
	body.collision_mask = 1
	level_root.add_child(body)

	for cell in _playable_cells(level):
		var cell_center := _cell_to_world(level, cell)

		var visual := Polygon2D.new()
		visual.position = cell_center
		visual.name = "FairwayCell_%d_%d" % [cell.x, cell.y]
		visual.polygon = _rectangle_polygon(Vector2(GRID_CELL_SIZE + 2.0, GRID_CELL_SIZE + 2.0))
		visual.color = _terrain_color("fairway_a", GREEN_DARK) if (cell.x + cell.y) % 2 == 0 else _terrain_color("fairway_b", GREEN_DARKER)
		body.add_child(visual)
		if (cell.x * 3 + cell.y) % 4 == 0:
			var grain := Line2D.new()
			grain.name = "FairwayGrain_%d_%d" % [cell.x, cell.y]
			grain.position = cell_center
			grain.width = 2.0
			grain.default_color = Color(_terrain_color("fairway_detail", visual.color.lightened(0.08)), 0.28)
			grain.points = PackedVector2Array([Vector2(-24.0, 18.0), Vector2(-8.0, 15.0), Vector2(9.0, 18.0)])
			body.add_child(grain)

		var collision := CollisionShape2D.new()
		collision.position = cell_center
		var shape := RectangleShape2D.new()
		shape.size = Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE)
		collision.shape = shape
		body.add_child(collision)


func _create_bounds(level: Dictionary) -> void:
	var directions := [
		{"cell": Vector2i(0, -1), "offset": Vector2(0.0, -GRID_CELL_SIZE / 2.0 - WALL_THICKNESS / 2.0), "size": Vector2(GRID_CELL_SIZE, WALL_THICKNESS)},
		{"cell": Vector2i(1, 0), "offset": Vector2(GRID_CELL_SIZE / 2.0 + WALL_THICKNESS / 2.0, 0.0), "size": Vector2(WALL_THICKNESS, GRID_CELL_SIZE)},
		{"cell": Vector2i(0, 1), "offset": Vector2(0.0, GRID_CELL_SIZE / 2.0 + WALL_THICKNESS / 2.0), "size": Vector2(GRID_CELL_SIZE, WALL_THICKNESS)},
		{"cell": Vector2i(-1, 0), "offset": Vector2(-GRID_CELL_SIZE / 2.0 - WALL_THICKNESS / 2.0, 0.0), "size": Vector2(WALL_THICKNESS, GRID_CELL_SIZE)},
	]
	var created_segments := {}
	for cell in elevation_lookup.keys():
		var cell_center := _cell_to_world(level, cell)
		for elevation in elevation_lookup[cell]:
			for direction in directions:
				var neighbor: Vector2i = Vector2i(cell) + Vector2i(direction.cell)
				if _surface_exists(neighbor, int(elevation)) or _has_elevation_transition(Vector2i(cell), neighbor, int(elevation)):
					continue
				var segment_position: Vector2 = cell_center + Vector2(direction.offset)
				var segment_key := "%d,%d,%d,%d,%d" % [
					roundi(segment_position.x),
					roundi(segment_position.y),
					roundi(Vector2(direction.size).x),
					roundi(Vector2(direction.size).y),
					int(elevation),
				]
				if created_segments.has(segment_key):
					continue
				created_segments[segment_key] = true
				_create_box(
					segment_position,
					direction.size,
					_terrain_color("border", BORDER_BROWN),
					&"boundary",
					int(elevation),
					_boundary_connections(level, Vector2i(cell), Vector2i(direction.cell), int(elevation))
				)


func _create_box(
	pos: Vector2,
	size: Vector2,
	color: Color,
	collision_kind := &"blocker",
	elevation := 0,
	connections: Dictionary = {}
) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = _collision_layer_for_elevation(elevation)
	body.collision_mask = 1
	body.z_index = _presentation_z_for_elevation(elevation) + 2
	body.set_meta(&"collision_kind", collision_kind)
	body.set_meta(&"elevation", elevation)
	level_root.add_child(body)

	var visual := CourseVisualFactory.create_connected_wall_visual(size, color, connections)
	body.add_child(visual)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _create_hole(pos: Vector2, radius: float, elevation: int) -> void:
	var green := CourseVisualFactory.create_green_patch(
		_terrain_color("green", _terrain_color("fairway_a", GREEN_DARK).lightened(0.18)),
		Color(_terrain_color("outline", BORDER_BROWN.darkened(0.25)), 0.48),
		radius
	)
	green.position = pos
	green.z_index = _presentation_z_for_elevation(elevation)
	level_root.add_child(green)
	_create_cup_opening(pos, radius, elevation)
	_create_hole_flag(pos, elevation)

	var area := Area2D.new()
	area.name = "Hole"
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 1
	area.set_meta(&"elevation", elevation)
	area.body_entered.connect(_on_hole_body_entered.bind(elevation))
	level_root.add_child(area)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	area.add_child(collision)

func _create_cup_opening(pos: Vector2, radius: float, elevation: int) -> void:
	var opening := Polygon2D.new()
	opening.name = "CupOpening"
	opening.position = pos
	opening.z_index = _presentation_z_for_elevation(elevation) + 1
	opening.polygon = _ellipse_polygon(Vector2(radius * 0.52, radius * 0.34), 32)
	opening.color = Color(0.02, 0.018, 0.015, 1.0)
	level_root.add_child(opening)


func _create_hole_flag(pos: Vector2, elevation: int) -> void:
	var flag_root := CourseVisualFactory.create_flag(
		_terrain_color("flag", Color("d9534f")),
		_terrain_color("outline", Color("252a2c"))
	)
	flag_root.position = pos
	flag_root.z_index = _presentation_z_for_elevation(elevation) + 2
	level_root.add_child(flag_root)


func _create_start_marker(pos: Vector2, elevation: int) -> void:
	tee_marker = CourseVisualFactory.create_start_marker(
		_terrain_color("tee", _terrain_color("fairway_a", GREEN_DARK).lightened(0.24)),
		_terrain_color("outline", BORDER_BROWN.darkened(0.25))
	)
	tee_marker.position = pos
	tee_marker.z_index = _presentation_z_for_elevation(elevation) + 1
	tee_marker.set_meta(&"tee_elevation", elevation)
	level_root.add_child(tee_marker)


func _create_hazards(level: Dictionary) -> void:
	for hazard in level.hazards:
		if not _hazard_fits_playable_map(level, hazard):
			push_warning("Skipping %s hazard because it does not fit the playable grid." % hazard.get("type", "unknown"))
			continue
		_create_gameplay_hazard(hazard)


func _create_gameplay_hazard(definition: Dictionary) -> void:
	var area = GameplayHazardScript.new()
	area.name = "Hazard_%s" % String(definition.type)
	area.configure(definition)
	area.position = definition.pos
	area.z_index = _presentation_z_for_elevation(int(definition.get("elevation", 0))) + 1
	area.hazard_body_entered.connect(_on_gameplay_hazard_body_entered)
	area.hazard_body_exited.connect(_on_gameplay_hazard_body_exited)
	area.hazard_triggered.connect(_relay_hazard_triggered)
	area.bounce_pad_triggered.connect(_relay_bounce_pad_triggered)
	level_root.add_child(area)

	var hazard_type := String(definition.type)
	var base_color := _terrain_color(hazard_type, _terrain_color("direction", Color(0.52, 0.72, 0.62, 0.9)))
	var detail_color := _terrain_color("%s_detail" % hazard_type, base_color.lightened(0.28))
	var visual := CourseVisualFactory.create_hazard_visual(
		hazard_type,
		definition.size,
		base_color,
		detail_color,
		Color(_terrain_color("outline", BORDER_BROWN.darkened(0.25)), 0.54)
	)
	area.add_child(visual)
	if hazard_type == "direction":
		_add_direction_indicator(area, Vector2(definition.direction).normalized(), detail_color)

	var collision := CollisionShape2D.new()
	if hazard_type == "bounce_pad":
		var circle := CircleShape2D.new()
		circle.radius = minf(Vector2(definition.size).x, Vector2(definition.size).y) * 0.5
		collision.shape = circle
	else:
		var rectangle := RectangleShape2D.new()
		rectangle.size = definition.size
		collision.shape = rectangle
	area.add_child(collision)


func _add_direction_indicator(area: Node2D, direction: Vector2, detail_color: Color) -> void:
	var arrow := Line2D.new()
	arrow.width = 5.0
	arrow.default_color = detail_color
	arrow.points = PackedVector2Array([-direction * 24.0, direction * 24.0])
	area.add_child(arrow)
	var head := Polygon2D.new()
	head.position = direction * 24.0
	head.rotation = direction.angle()
	head.polygon = PackedVector2Array([Vector2(12.0, 0.0), Vector2(-8.0, -7.0), Vector2(-8.0, 7.0)])
	head.color = detail_color
	area.add_child(head)


func _create_moving_hazards(level: Dictionary) -> void:
	for definition in level.get("moving_hazards", []):
		var moving = MovingHazardScript.new()
		moving.name = "MovingHazard_%s" % String(definition.type)
		moving.configure(definition)
		moving.z_index = _presentation_z_for_elevation(int(definition.get("elevation", 0))) + 4
		moving.setup_collision(definition.size, String(definition.type) == "pendulum")
		moving.hazard_triggered.connect(_relay_hazard_triggered)
		level_root.add_child(moving)

		var colors := _moving_hazard_colors(StringName(definition.type))
		var moving_visual := CourseVisualFactory.create_moving_hazard_visual(
			StringName(definition.type),
			definition.size,
			colors.primary,
			colors.detail
		)
		moving.add_child(moving_visual)
		_create_moving_hazard_telegraph(moving, definition)


func _create_moving_hazard_telegraph(moving, definition: Dictionary) -> void:
	var data: Dictionary = moving.get_telegraph_data()
	var local_path := PackedVector2Array()
	for point in data.path_points:
		local_path.append(Vector2(point) - Vector2(definition.pos))
	var telegraph = HazardTelegraphScript.new()
	telegraph.name = "Telegraph_%s" % String(definition.type)
	telegraph.position = definition.pos
	telegraph.z_index = _presentation_z_for_elevation(int(definition.get("elevation", 0))) + 1
	telegraph.configure(
		StringName(definition.type),
		definition.size,
		local_path,
		_terrain_color("hazard_telegraph", Color("d9534f")),
		float(data.period),
		float(definition.get("phase", 0.0))
	)
	level_root.add_child(telegraph)


func _create_elevation_presentation(level: Dictionary) -> void:
	var rough_lookup := {}
	for rough_cell in level.get("visual_rough_cells", []):
		rough_lookup[Vector2i(rough_cell)] = true

	var structure_lookup := {}
	for structure in level.get("elevation_structures", []):
		var structure_type := StringName(String(structure.get("type", "")))
		for structure_cell in structure.get("cells", []):
			var key := Vector3i(
				Vector2i(structure_cell).x,
				Vector2i(structure_cell).y,
				int(structure.get("elevation", 0))
			)
			structure_lookup[key] = structure_type

	var elevation_entries: Array = level.get("elevation_cells", [])
	if elevation_entries.is_empty():
		for cell in elevation_lookup:
			elevation_entries.append({"cell": cell, "levels": elevation_lookup[cell]})

	for entry in elevation_entries:
		var cell: Vector2i = entry.cell
		var levels: Array = entry.levels
		for elevation_value in levels:
			var elevation := int(elevation_value)
			var structure_type: StringName = structure_lookup.get(
				Vector3i(cell.x, cell.y, elevation),
				&""
			)
			if elevation == 0 and structure_type == &"" and not rough_lookup.has(cell):
				continue

			var surface_color := _terrain_color(
				"rough" if rough_lookup.has(cell) else "fairway_a",
				_terrain_color("fairway_a", GREEN_DARK)
			)
			var edge_color := _terrain_color("elevation_edge", _terrain_color("border", BORDER_BROWN))
			var visual: Node2D
			match structure_type:
				&"bridge", &"overpass":
					visual = CourseVisualFactory.create_bridge_visual(
						Vector2(GRID_CELL_SIZE - 8.0, GRID_CELL_SIZE - 8.0),
						surface_color,
						edge_color
					)
				&"pit":
					visual = CourseVisualFactory.create_pit_visual(
						Vector2(GRID_CELL_SIZE - 4.0, GRID_CELL_SIZE - 4.0),
						surface_color,
						edge_color
					)
				_:
					visual = CourseVisualFactory.create_elevation_cell_visual(
						Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE),
						elevation,
						surface_color,
						edge_color
					)
			visual.name = "Elevation_%d_%d_%d" % [cell.x, cell.y, elevation]
			visual.position = _cell_to_world(level, cell)
			visual.z_index = _presentation_z_for_elevation(elevation) + (1 if elevation < 0 else 0)
			visual.set_meta(&"cell", cell)
			visual.set_meta(&"elevation", elevation)
			visual.set_meta(&"structure_type", structure_type)
			level_root.add_child(visual)


func _create_elevation_ramps(level: Dictionary) -> void:
	for transition_index in range(level.get("elevation_transitions", []).size()):
		var transition: Dictionary = level.elevation_transitions[transition_index]
		var from_position := _cell_to_world(level, transition.from_cell)
		var to_position := _cell_to_world(level, transition.to_cell)
		var from_elevation := int(transition.from_elevation)
		var to_elevation := int(transition.to_elevation)
		var ramp = ElevationRampScript.new()
		ramp.name = "ElevationRamp%d" % (transition_index + 1)
		ramp.configure(from_position, to_position, from_elevation, to_elevation, 72.0)
		ramp.z_index = _presentation_z_for_elevation(maxi(from_elevation, to_elevation)) + 2
		ramp.elevation_transitioned.connect(_relay_elevation_transitioned)
		level_root.add_child(ramp)

		var ramp_visual := CourseVisualFactory.create_ramp_visual(
			Vector2(from_position.distance_to(to_position), 72.0),
			from_elevation,
			to_elevation,
			_terrain_color("fairway_a", GREEN_DARK),
			_terrain_color("elevation_edge", _terrain_color("border", BORDER_BROWN))
		)
		ramp.add_child(ramp_visual)


func _moving_hazard_colors(hazard_type: StringName) -> Dictionary:
	match hazard_type:
		&"falling_ice":
			return {"primary": _terrain_color("ice", Color("9ed5e4")), "detail": _terrain_color("ice_detail", Color("f5fbff"))}
		&"rotating_fire_rod":
			return {"primary": _terrain_color("lava", Color("d9522f")), "detail": _terrain_color("lava_detail", Color("ffb13b"))}
		_:
			return {"primary": _terrain_color("border", BORDER_BROWN), "detail": _terrain_color("outline", Color("252a2c"))}


func _create_decorations(level: Dictionary) -> void:
	var decoration_ids := PackedStringArray(level.get("decoration_identifiers", PackedStringArray()))
	if decoration_ids.is_empty():
		return

	var rows: Array = level.map
	var columns := 0
	for row in rows:
		columns = maxi(columns, String(row).length())
	var map_size := Vector2(float(columns), float(rows.size())) * GRID_CELL_SIZE
	var primary := _background_color("highlight", Color(0.46, 0.65, 0.4))
	var secondary := _background_color("secondary", Color(0.36, 0.55, 0.3))
	var accent := _background_color("accent", primary.lightened(0.2))
	for i in range(decoration_ids.size()):
		for copy_index in range(2):
			var decoration := CourseVisualFactory.create_decoration(String(decoration_ids[i]), primary, secondary, accent)
			decoration.name = "Decoration_%s_%d" % [decoration_ids[i], copy_index + 1]
			if i % 2 == 0:
				decoration.position = Vector2(
					lerpf(-map_size.x * 0.38, map_size.x * 0.38, float(i + copy_index) / float(decoration_ids.size())),
					(-1.0 if copy_index == 0 else 1.0) * (map_size.y * 0.5 + 70.0 + float(i) * 10.0)
				)
			else:
				decoration.position = Vector2(
					(-1.0 if copy_index == 0 else 1.0) * (map_size.x * 0.5 + 75.0 + float(i) * 12.0),
					lerpf(-map_size.y * 0.32, map_size.y * 0.32, float(i) / float(decoration_ids.size() - 1))
				)
			decoration.rotation = (float(i) - 1.5) * 0.08 * (-1.0 if copy_index == 0 else 1.0)
			decoration.scale = Vector2.ONE * (0.9 + float((i + copy_index) % 3) * 0.1)
			level_root.add_child(decoration)


func _terrain_color(key: String, fallback: Color) -> Color:
	return active_terrain_palette.get(key, fallback)


func _background_color(key: String, fallback: Color) -> Color:
	return active_background_palette.get(key, fallback)


func _on_hole_body_entered(body: Node2D, elevation: int) -> void:
	if not _body_matches_elevation(body, elevation):
		return
	hole_body_entered.emit(body)


func _on_sand_body_entered(body: Node2D) -> void:
	sand_body_entered.emit(body)


func _on_sand_body_exited(body: Node2D) -> void:
	sand_body_exited.emit(body)


func _on_direction_body_entered(body: Node2D, area: Area2D) -> void:
	direction_body_entered.emit(body, area)


func _on_direction_body_exited(body: Node2D, area: Area2D) -> void:
	direction_body_exited.emit(body, area)


func _on_gameplay_hazard_body_entered(body: Node2D, hazard) -> void:
	match hazard.hazard_type:
		&"sand":
			sand_body_entered.emit(body)
		&"water":
			reset_hazard_body_entered.emit(body, hazard.global_position, &"water")
		&"lava":
			reset_hazard_body_entered.emit(body, hazard.global_position, &"lava")
		&"direction":
			direction_body_entered.emit(body, hazard)


func _on_gameplay_hazard_body_exited(body: Node2D, hazard) -> void:
	match hazard.hazard_type:
		&"sand":
			sand_body_exited.emit(body)
		&"direction":
			direction_body_exited.emit(body, hazard)


func _relay_hazard_triggered(hazard_type: StringName, intensity: float, position: Vector2) -> void:
	hazard_triggered.emit(hazard_type, clampf(intensity, 0.0, 1.0), position)


func _relay_bounce_pad_triggered(strength: float, pad_type: StringName, position: Vector2) -> void:
	bounce_pad_triggered.emit(clampf(strength, 0.0, 1.0), pad_type, position)


func _relay_elevation_transitioned(body: Node2D, from_elevation: int, to_elevation: int) -> void:
	elevation_transitioned.emit(body, from_elevation, to_elevation)


func _playable_cells(level: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var rows: Array = level.map
	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var cell := Vector2i(x, y)
			if _is_playable_cell(level, cell):
				cells.append(cell)
	return cells


func _is_playable_cell(level: Dictionary, cell: Vector2i) -> bool:
	var rows: Array = level.map
	if cell.y < 0 or cell.y >= rows.size():
		return false

	var row: String = rows[cell.y]
	if cell.x < 0 or cell.x >= row.length():
		return false

	return row[cell.x] != " "


func _hazard_fits_playable_map(level: Dictionary, hazard: Dictionary) -> bool:
	if not hazard.has("pos") or not hazard.has("size"):
		return false

	var size: Vector2 = hazard.size
	if size.x <= 0.0 or size.y <= 0.0:
		return false

	var rect := Rect2(hazard.pos - size / 2.0, size)
	var top_left := _map_top_left(level)
	var min_cell := Vector2i(
		floori((rect.position.x - top_left.x) / GRID_CELL_SIZE),
		floori((rect.position.y - top_left.y) / GRID_CELL_SIZE)
	)
	var max_cell := Vector2i(
		floori((rect.end.x - top_left.x - 0.001) / GRID_CELL_SIZE),
		floori((rect.end.y - top_left.y - 0.001) / GRID_CELL_SIZE)
	)

	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			var elevation := int(hazard.get("elevation", 0))
			if not _surface_exists(Vector2i(x, y), elevation):
				return false

	return true


func _rebuild_elevation_lookup(level: Dictionary) -> void:
	elevation_lookup.clear()
	if not level.has("elevation_cells"):
		for cell in _playable_cells(level):
			elevation_lookup[cell] = [0]
		return
	for entry in level.get("elevation_cells", []):
		elevation_lookup[Vector2i(entry.cell)] = Array(entry.levels).duplicate()


func _surface_exists(cell: Vector2i, elevation: int) -> bool:
	return elevation_lookup.has(cell) and Array(elevation_lookup[cell]).has(elevation)


func _has_elevation_transition(from_cell: Vector2i, to_cell: Vector2i, elevation: int) -> bool:
	for transition in active_level.get("elevation_transitions", []):
		var transition_from: Vector2i = transition.from_cell
		var transition_to: Vector2i = transition.to_cell
		var from_elevation := int(transition.from_elevation)
		var to_elevation := int(transition.to_elevation)
		if transition_from == from_cell and transition_to == to_cell and from_elevation == elevation:
			return true
		if transition_to == from_cell and transition_from == to_cell and to_elevation == elevation:
			return true
	return false


func _boundary_connections(
	level: Dictionary,
	cell: Vector2i,
	outward: Vector2i,
	elevation: int
) -> Dictionary:
	var connections := {"left": false, "right": false, "top": false, "bottom": false}
	if outward.y != 0:
		connections.left = _has_parallel_boundary(level, cell + Vector2i.LEFT, outward, elevation)
		connections.right = _has_parallel_boundary(level, cell + Vector2i.RIGHT, outward, elevation)
	else:
		connections.top = _has_parallel_boundary(level, cell + Vector2i.UP, outward, elevation)
		connections.bottom = _has_parallel_boundary(level, cell + Vector2i.DOWN, outward, elevation)
	return connections


func _has_parallel_boundary(
	_level: Dictionary,
	cell: Vector2i,
	outward: Vector2i,
	elevation: int
) -> bool:
	return _surface_exists(cell, elevation) and not _surface_exists(cell + outward, elevation)


func _body_matches_elevation(body: Node2D, elevation: int) -> bool:
	if "current_elevation" not in body:
		return elevation == 0
	return int(body.current_elevation) == elevation


func _collision_layer_for_elevation(elevation: int) -> int:
	match clampi(elevation, -1, 1):
		-1:
			return 1 << 4
		0:
			return 1 << 5
		_:
			return 1 << 6


static func _presentation_z_for_elevation(elevation: int) -> int:
	return (clampi(elevation, -1, 1) + ELEVATION_Z_OFFSET) * ELEVATION_Z_STRIDE


func _cell_to_world(level: Dictionary, cell: Vector2i) -> Vector2:
	return _map_top_left(level) + Vector2(float(cell.x) + 0.5, float(cell.y) + 0.5) * GRID_CELL_SIZE


func _map_top_left(level: Dictionary) -> Vector2:
	return -_map_size(level) / 2.0


func _map_size(level: Dictionary) -> Vector2:
	var rows: Array = level.map
	var columns := 0
	for row in rows:
		columns = maxi(columns, String(row).length())
	return Vector2(float(columns), float(rows.size())) * GRID_CELL_SIZE


func _ellipse_polygon(radii: Vector2, segments := 32) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


func _rectangle_polygon(size: Vector2) -> PackedVector2Array:
	var half_size := size / 2.0
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])
