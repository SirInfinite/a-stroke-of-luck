extends Node2D
## The damaging body owns motion; the visual rig follows without retiming it.

const Pixel := preload("res://tools/pixel_correction/arcade_assets.gd")
const LINK_COUNT := 9
var body: MovingHazard
var links: Array[Sprite2D] = []
var weight: Sprite2D
var bearing: Sprite2D
var impact_tween: Tween

func setup(hazard: MovingHazard) -> void:
	body = hazard
	z_index = body.z_index
	body.visual_node.hide()
	bearing = Pixel.sprite("props/pivot", body.origin, Vector2(54, 54))
	add_child(bearing)
	for index in LINK_COUNT:
		var link := Pixel.sprite("props/chain", Vector2.ZERO, Vector2(14, 26))
		add_child(link)
		links.append(link)
	# The shackle sits above an 88-unit stone, matching the existing circular body.
	weight = Pixel.sprite("props/pendulum", Vector2.ZERO, Vector2(88, 102))
	add_child(weight)
	body.body_hit.connect(_on_hit)
	_process(0.0)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(body): return
	# Quiet center-path marks are a trajectory, never a promised safe interval.
	for index in 17:
		var angle := lerpf(-body.swing_angle, body.swing_angle, index / 16.0)
		var point := (body.origin + Vector2.DOWN.rotated(angle) * body.travel_radius).snapped(Vector2(2, 2))
		draw_rect(Rect2(point - Vector2(4, 4), Vector2(8, 8)), Pixel.INK)
		draw_rect(Rect2(point - Vector2(2, 2), Vector2(4, 4)), Color("c6b68b"))

func _process(_delta: float) -> void:
	if not is_instance_valid(body): return
	var direction := (body.position - body.origin).normalized()
	var attachment := body.position - direction * 40.0
	for index in links.size():
		links[index].position = body.origin.lerp(attachment, float(index + 1) / float(links.size() + 1)).snapped(Vector2(2, 2))
		links[index].rotation = direction.angle() - PI * 0.5
	weight.position = body.position + Vector2(0, -7)
	weight.rotation = 0.0
	# A hard bearing highlight at the real reversal poses adds anticipation.
	# It does not change essential motion, collision, time or safe/danger phases.
	var near_reversal := absf(sin(body.elapsed / body.period * TAU)) > 0.94
	bearing.modulate = Color(1.18, 1.12, 1.0) if near_reversal else Color.WHITE

func _on_hit(_golfer: Node2D, _kind: StringName, _at: Vector2) -> void:
	if impact_tween: impact_tween.kill()
	weight.modulate = Color(1.7, 1.45, 1.15)
	impact_tween = create_tween()
	impact_tween.tween_interval(0.07)
	impact_tween.tween_callback(func(): weight.modulate = Color.WHITE)
