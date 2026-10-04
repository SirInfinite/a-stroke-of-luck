extends Node2D

const Art := preload("res://scripts/presentation/world_art.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
var flag: Sprite2D
var elapsed := 0.0
var last_frame := -1

func _ready() -> void:
	flag = Art.sprite("objects/flag_a",Vector2(-4,-70))
	flag.name = "Flag"
	flag.centered = false
	flag.scale = Vector2(2,2)
	add_child(flag)
	var pole := Marker2D.new()
	pole.name = "Pole"
	add_child(pole)

func _process(delta: float) -> void:
	if not UIStyleScript.motion_enabled(self): return
	elapsed += delta
	var frame := int(elapsed*2.0)%2
	if frame==last_frame: return
	last_frame=frame
	flag.texture=Art.texture("objects/flag_a" if frame==0 else "objects/flag_b")
