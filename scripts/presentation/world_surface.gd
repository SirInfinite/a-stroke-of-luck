extends Node2D
## Material animation and exposed banks; never a collision or timing owner.

const Art := preload("res://scripts/presentation/world_art.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
var kind := "water"
var dimensions := Vector2(100, 100)
var connections: Dictionary = {}
var body: Sprite2D
var elapsed := 0.0
var phase := 0.0
var last_frame := -1

func configure(material: String, size: Vector2, joined: Dictionary) -> void:
	kind = material
	dimensions = size
	connections = joined.duplicate()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var path := "objects/pad" if kind == "bounce_pad" else "objects/direction_plate" if kind == "direction" else "terrain/%s_a" % kind
	body = Art.sprite(path, Vector2.ZERO, dimensions)
	body.name = "MaterialSprite"
	body.show_behind_parent = true
	if kind not in ["bounce_pad", "direction"]:
		body.region_enabled = true
		body.region_rect = Rect2(Vector2.ZERO, dimensions * 0.48)
		body.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		body.scale = Vector2.ONE / 0.48
	add_child(body)
	queue_redraw()

func _ready() -> void:
	phase = fposmod(global_position.x * 0.0031 + global_position.y * 0.0053, 1.0)

func _process(delta: float) -> void:
	if kind not in ["water", "lava"] or not UIStyleScript.motion_enabled(self): return
	elapsed += delta
	var frame := int(elapsed * 1.6 + phase * 2.0) % 2
	if frame == last_frame: return
	last_frame = frame
	body.texture = Art.texture("terrain/%s_%s" % [kind, "a" if frame == 0 else "b"])

func _draw() -> void:
	if kind in ["bounce_pad", "direction"]: return
	var half := dimensions * 0.5
	var dark := Color("1f4b53") if kind == "water" else Color("873829") if kind == "lava" else Color("b69661") if kind == "sand" else Color("527e93")
	var light := Color("83bdac") if kind == "water" else Color("ffb24c") if kind == "lava" else Color("f3d59b") if kind == "sand" else Color("d1eddf")
	# Draw behind the child material only where the continuous pool ends.
	for edge in ["top", "right", "bottom", "left"]:
		if bool(connections.get(edge, false)): continue
		var rect := Rect2(-half, dimensions)
		match edge:
			"top": rect.size.y = 4.1667
			"bottom": rect.position.y = half.y - 4.1667; rect.size.y = 4.1667
			"left": rect.size.x = 4.1667
			"right": rect.position.x = half.x - 4.1667; rect.size.x = 4.1667
		draw_rect(rect, light if edge in ["top", "left"] else dark)
