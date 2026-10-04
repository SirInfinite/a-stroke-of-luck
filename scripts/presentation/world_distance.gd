extends Node2D
## The camera drives depth layers. Near scenery remains in world coordinates.

const Art := preload("res://scripts/presentation/world_art.gd")
const UIStyleScript := preload("res://scripts/ui/ui_style.gd")
var biome: StringName = &"meadow"
var course_anchor := Vector2.ZERO
var _last_canvas := Transform2D()
var _last_viewport := Vector2.ZERO

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	process_priority = 110 # Read the final native camera transform this frame.
	# BiomeBackgroundVariants owns -28. A second relative offset would put
	# these images behind the opaque fallback surround at -30.
	z_index = 0
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()

func _process(_delta: float) -> void:
	var canvas := get_canvas_transform()
	var viewport := get_viewport_rect().size
	if canvas != _last_canvas or viewport != _last_viewport:
		_last_canvas = canvas
		_last_viewport = viewport
		queue_redraw()

func _draw() -> void:
	var inverse := get_canvas_transform().affine_inverse()
	var viewport := get_viewport_rect().size
	var visible := Rect2(inverse * Vector2.ZERO, (inverse * viewport) - inverse * Vector2.ZERO)
	var camera := get_viewport().get_camera_2d()
	var center := camera.get_screen_center_position() if camera else Vector2.ZERO
	var relative := center - course_anchor
	var zoom := camera.zoom.x if camera else 1.0
	var motion := UIStyleScript.motion_enabled(self)
	for index in 2:
		var picture := Art.texture("backgrounds/%s_%s" % [biome,"distance" if index==0 else "middle"])
		var response := 0.12 if index==0 else 0.30
		var scale_value := visible.size.y / 432.0 * (1.48 if index==0 else 1.56) * pow(maxf(zoom,0.01)/1.25,0.08)
		var size := picture.get_size() * scale_value
		var scroll := relative * response if motion else Vector2.ZERO
		var left := visible.position.x - fposmod(scroll.x, size.x)
		var vertical_margin := maxf(0.0,(size.y-visible.size.y)*0.5)
		var top := visible.position.y - vertical_margin - clampf(scroll.y*0.55,-vertical_margin,vertical_margin)
		# Warm distant light and cool nearer masses stay distinct. This is color
		# treatment only; the native camera still owns all spatial displacement.
		var tint := Color(0.72,0.75,0.72,1.0) if index==0 else Color(0.43,0.64,0.62,0.86)
		var count := ceili(visible.size.x/size.x)+2
		for repeat_index in count:
			draw_texture_rect(picture,Rect2(Vector2(left+repeat_index*size.x,top),size),false,tint)
