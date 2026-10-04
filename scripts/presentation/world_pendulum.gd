extends Node2D
## Reads the native moving body. No secondary swing clock or collision geometry.

const Art := preload("res://scripts/presentation/world_art.gd")
var body: MovingHazard
var links: Array[Sprite2D] = []
var bearing: Sprite2D
var impact_remaining := 0.0

func setup(hazard: MovingHazard) -> void:
	body = hazard
	set_meta(&"elevation", body.elevation)
	bearing = Art.sprite("objects/bearing", body.origin, Vector2(58, 50))
	add_child(bearing)
	for index in 11:
		var link := Art.sprite("objects/chain", Vector2.ZERO, Vector2(10,17))
		add_child(link)
		links.append(link)
	body.body_hit.connect(_on_contact)
	body.state_reset.connect(_on_reset)
	_process(0.0)

func _process(delta: float) -> void:
	if not is_instance_valid(body): return
	var direction := (body.position - body.origin).normalized()
	var radius: float = body.collision_shape.shape.radius
	var end := body.position - direction * radius * 0.85
	for index in links.size():
		links[index].position = body.origin.lerp(end, float(index+1)/(links.size()+1))
		links[index].rotation = direction.angle() - PI*0.5
	impact_remaining = maxf(0.0, impact_remaining - delta)
	if body.visual_node:
		body.visual_node.modulate = Color(1.25,1.16,1.04) if impact_remaining > 0 else Color.WHITE

func _on_contact(_golfer: Node2D, _kind: StringName, _at: Vector2) -> void:
	impact_remaining = 0.075

func _on_reset() -> void:
	impact_remaining = 0.0
	if is_instance_valid(body) and body.visual_node: body.visual_node.modulate = Color.WHITE
