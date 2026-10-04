class_name BiomeAmbience
extends Node2D
## Course-anchored scenery and bounded independent ambience. Never gameplay RNG.

const PARTICLE_COUNT := 40
const LANDSCAPE_GROUPS := 8
const BANK_WIDTH := 58.0
const BANK_SHADOW_WIDTH := 66.0
const ROOT_EDGE_OFFSET := 32.0
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
const Art := preload("res://scripts/presentation/world_art.gd")
var ambience_id: StringName = &"meadow_breeze"
var primary_color := Color.WHITE
var accent_color := Color.WHITE
var map_size := Vector2(1000,600)
var surround_size := Vector2(7600,4600)
var visual_seed := 1
var elapsed := 0.0
var static_details: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var landscape: Array[Dictionary] = []
var redraw_elapsed := 0.0
var biome: StringName = &"meadow"
var course_cells: Array[Rect2] = []
var boundary_roots: Array[Dictionary] = []

func configure(new_id: StringName, new_primary: Color, new_accent: Color, new_map: Vector2, new_surround: Vector2, seed_value: int, new_cells: Array[Rect2] = []) -> void:
	ambience_id = new_id
	primary_color = new_primary
	accent_color = new_accent
	map_size = new_map
	surround_size = new_surround
	visual_seed = maxi(absi(seed_value),1)
	course_cells.assign(new_cells)
	biome = Art.biome_for_ambience(ambience_id)
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_layout()
	queue_redraw()

func _build_layout() -> void:
	static_details.clear()
	landscape.clear()
	particles.clear()
	_build_ground()
	var rng := RandomNumberGenerator.new()
	rng.seed = visual_seed
	for index in LANDSCAPE_GROUPS:
		var side := index % 4
		var band := float(index / 4) - 0.5
		var at := Vector2(band*map_size.x*0.42,(-map_size.y*0.5-290.0) if side==0 else map_size.y*0.5+390.0) if side<2 else Vector2((-map_size.x*0.5-310.0) if side==2 else map_size.x*0.5+310.0,band*map_size.y*0.43)
		var edge_direction: Vector2 = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT][side]
		var nearest := INF
		var requested := at
		for candidate in boundary_roots:
			if candidate.direction != edge_direction: continue
			var distance: float = requested.distance_squared_to(candidate.position)
			if distance < nearest:
				nearest = distance
				at = candidate.position
		var radii := Vector2(240,115) if side<2 else Vector2(155,185)
		landscape.append({"position":at,"radii":radii,"variant":index,"phase":rng.randf_range(0,TAU)})
		for detail in (2 if index % 3 == 0 else 1):
			var tangent := edge_direction.orthogonal()
			var offset := tangent * (-24.0 if detail == 0 else 48.0)
			var scale_value := rng.randf_range(0.82,1.15) * (1.0 if detail==0 else 0.64)
			static_details.append({"position":at+offset,"scale":scale_value,"variant":index,"phase":rng.randf_range(0,TAU)})
	for index in PARTICLE_COUNT:
		var group: Dictionary = landscape[index%LANDSCAPE_GROUPS]
		var velocity := Vector2(28,4)
		if biome in [&"autumn",&"snow"]: velocity=Vector2(8,21)
		elif biome in [&"swamp",&"volcanic"]: velocity=Vector2(5,-19)
		particles.append({"position":Vector2(group.position)+Vector2(rng.randf_range(-120,120),rng.randf_range(-100,100)),"velocity":velocity*rng.randf_range(0.65,1.3),"duration":rng.randf_range(7,13),"phase":rng.randf_range(0,14),"scale":rng.randf_range(0.8,1.35)})

func _build_ground() -> void:
	boundary_roots.clear()
	var centers := {}
	for cell in course_cells: centers[cell.get_center()] = true
	for cell in course_cells:
		for direction: Vector2 in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]:
			if centers.has(cell.get_center() + direction * cell.size): continue
			boundary_roots.append({"position":cell.get_center() + direction * (cell.size * 0.5 + Vector2.ONE * ROOT_EDGE_OFFSET), "direction":direction})

func _ready() -> void:
	# Ground contact, sprite origin and placement are fixed once per course.
	for index in static_details.size():
		var detail: Dictionary = static_details[index]
		var path := "objects/"+Art.landmark(biome)
		var sprite := Art.sprite(path)
		sprite.name = "AnchoredLandmark%d"%index
		sprite.centered = false
		sprite.scale = Vector2.ONE * 2.1 * float(detail.scale)
		sprite.position = Vector2(detail.position) - Vector2(sprite.texture.get_width()*0.5,sprite.texture.get_height())*sprite.scale
		sprite.modulate = Color(0.72,0.81,0.77)
		add_child(sprite)

func _process(delta: float) -> void:
	if not UIStyleScript.motion_enabled(self): return
	# Each particle wraps while fully faded. A shared elapsed reset would jump
	# particles with different seven-to-thirteen-second periods at 240 seconds.
	elapsed += delta
	redraw_elapsed += delta
	if redraw_elapsed>=1.0/24.0:
		redraw_elapsed=0.0
		queue_redraw()

func _draw() -> void:
	var land_color: Color = {&"meadow":Color("243e38"),&"desert":Color("71553e"),&"autumn":Color("533e34"),&"snow":Color("455d71"),&"swamp":Color("263e35"),&"volcanic":Color("302b36")}.get(biome,Color("243e38"))
	# Overlapping solid banks merge visually without per-cell outlines. They
	# have no collider and do not enlarge the playable geometry. Nearby roots
	# occupy this world-fixed shoulder, while the panorama stays beyond it.
	for cell in course_cells:
		var shadow_bank := cell.grow(BANK_SHADOW_WIDTH)
		shadow_bank.position += Vector2(0,12)
		draw_rect(shadow_bank,land_color.darkened(0.32))
	for cell in course_cells:
		draw_rect(cell.grow(BANK_WIDTH),land_color)
	for index in particles.size():
		var particle: Dictionary = particles[index]
		var duration := float(particle.duration)
		var life := fposmod(elapsed+float(particle.phase),duration)/duration
		var alpha := smoothstep(0.0,0.15,life)*(1.0-smoothstep(0.76,1.0,life))
		var at := Vector2(particle.position)+Vector2(particle.velocity)*life*duration
		at += Vector2(sin(elapsed*0.8+index)*7,0)
		var color: Color = {&"meadow":Color("d6d995"),&"desert":Color("d4b67e"),&"autumn":Color("e4a35c"),&"snow":Color("ddebe6"),&"swamp":Color("a3bd78"),&"volcanic":Color("ed9956")}.get(biome,Color.WHITE)
		color.a = alpha*0.55
		var size := Vector2(4,4)*float(particle.scale)
		if biome==&"desert": size=Vector2(24,2)
		draw_rect(Rect2(at.round(),size),color)
