extends Node2D
## All transforms are read from the authoritative native pendulum body.

const Art := preload("res://tools/reference_slice/world/world_assets.gd")
const LINK_COUNT := 11
var body: MovingHazard
var density := 48
var links: Array[Sprite2D] = []
var weight: Sprite2D
var bearing: Sprite2D
var shadow: Sprite2D
var impact_remaining := 0.0
var diameter := 88.0
var direction := Vector2.DOWN

func setup(hazard: MovingHazard, source_density := 48) -> void:
	body = hazard
	density = source_density
	z_index = body.z_index
	body.visual_node.hide()
	if body.collision_shape.shape is CircleShape2D:
		diameter = body.collision_shape.shape.radius * 2.0
	bearing = Art.sprite("props/bearing", body.origin, Vector2(58, 50), density)
	add_child(bearing)
	for index in LINK_COUNT:
		var link := Art.sprite("props/chain", Vector2.ZERO, Vector2(10, 17), density)
		add_child(link)
		links.append(link)
	# The visible stone, including its small tips, fits the actual circular body.
	weight = Art.sprite("props/pendulum", Vector2.ZERO, Vector2.ONE * diameter, density)
	add_child(weight)
	body.body_hit.connect(_on_hit)
	body.state_reset.connect(_reset_visuals)
	_process(0.0)
	queue_redraw()

func set_density(value: int) -> void:
	density = value
	if not weight: return
	weight.texture = Art.texture("props/pendulum", density)
	weight.scale = Vector2.ONE * diameter / weight.texture.get_size()
	bearing.texture = Art.texture("props/bearing", density)
	bearing.scale = Vector2(58, 50) / bearing.texture.get_size()
	for link in links:
		link.texture = Art.texture("props/chain", density)
		link.scale = Vector2(10, 17) / link.texture.get_size()

func _draw() -> void:
	if not is_instance_valid(body): return
	# Discrete worn trajectory marks describe travel, never a safe-time promise.
	for index in 15:
		var angle := lerpf(-body.swing_angle, body.swing_angle, index / 14.0)
		var at := body.origin + Vector2.DOWN.rotated(angle) * body.travel_radius
		draw_rect(Rect2(at - Vector2(1.5, 1.5), Vector2(3, 3)), Color("b7c494", 0.36))

func _process(delta: float) -> void:
	if not is_instance_valid(body): return
	direction = (body.position - body.origin).normalized()
	var attachment := body.position - direction * diameter * 0.42
	for index in links.size():
		links[index].position = body.origin.lerp(attachment, float(index + 1) / float(links.size() + 1))
		links[index].rotation = direction.angle() - PI * 0.5
	# No position snapping: collider and dangerous mass keep the same center.
	weight.position = body.position
	weight.rotation = 0.0
	if body.can_process(): impact_remaining = maxf(0.0, impact_remaining - delta)
	weight.modulate = Color(1.32, 1.19, 1.05) if impact_remaining > 0.0 else Color.WHITE
	# Bearing glow is tied to the real phase, not a separate presentation clock.
	var near_reversal := absf(sin(body.elapsed / body.period * TAU)) > 0.965
	bearing.modulate = Color(1.10, 1.08, 1.0) if near_reversal else Color.WHITE

func _on_hit(_golfer: Node2D, _kind: StringName, _at: Vector2) -> void:
	impact_remaining = 0.075

func _reset_visuals() -> void:
	impact_remaining = 0.0
	if weight: weight.modulate = Color.WHITE
