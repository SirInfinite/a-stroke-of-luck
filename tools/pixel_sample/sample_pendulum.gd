extends Node2D
## The existing body is authoritative. This rig only follows its current pose.

const Art := preload("res://tools/pixel_sample/sample_assets.gd")
var body: MovingHazard
var links: Array[Sprite2D] = []
var weight: Sprite2D
var impact_tween: Tween

func setup(hazard: MovingHazard) -> void:
	body = hazard
	z_index = body.z_index
	body.visual_node.hide()
	var pivot := Art.sprite("props/pivot", body.origin, Vector2(46, 46))
	add_child(pivot)
	for index in 15:
		var link := Art.sprite("props/chain", Vector2.ZERO, Vector2(10, 15))
		add_child(link)
		links.append(link)
	weight = Art.sprite("props/pendulum", Vector2.ZERO, Vector2(91, 101))
	add_child(weight)
	body.body_hit.connect(_on_hit)
	queue_redraw()
	_process(0.0)

func _draw() -> void:
	if not is_instance_valid(body): return
	# These marks trace the real center path, not an invented safe/danger phase.
	for index in 25:
		var angle := lerpf(-body.swing_angle, body.swing_angle, index / 24.0)
		var point := body.origin + Vector2.DOWN.rotated(angle) * body.travel_radius
		draw_rect(Rect2(point.round() - Vector2(2, 2), Vector2(4, 4)), Color("ebba7a"))

func _process(_delta: float) -> void:
	if not is_instance_valid(body): return
	var direction := (body.position - body.origin).normalized()
	var attachment := body.position - direction * 42.0
	for index in links.size():
		links[index].position = body.origin.lerp(attachment, float(index + 1) / float(links.size() + 1)).round()
		links[index].rotation = direction.angle() - PI * 0.5
	# The source includes the attachment above the round stone's center.
	weight.position = body.position + Vector2(0, -6)
	weight.rotation = 0.0

func _on_hit(_golfer: Node2D, _kind: StringName, _at: Vector2) -> void:
	if impact_tween: impact_tween.kill()
	weight.modulate = Color(1.8, 1.35, 1.1)
	impact_tween = create_tween()
	impact_tween.tween_property(weight, "modulate", Color.WHITE, 0.18)
