extends Camera3D

@onready var golfBall = $".."

# vars for raycast
const rayLength = 100
var mousePos : Vector2
var from : Vector3
var to : Vector3
var space : PhysicsDirectSpaceState3D
var query : PhysicsRayQueryParameters3D

# var for cam follow
var vector : Vector3

func _ready() -> void: 
	# do this so cam wont rotate w ball
	self.set_as_top_level(true)

func _process(delta) -> void:
	camera_follow()

func camera_follow() -> void:
	vector = Vector3(golfBall.transform.origin.x, position.y, golfBall.transform.origin.z)
	
	self.transform.origin = self.transform.origin.lerp(vector, 1)

# translate mouse pos from screen to 3d world
func camera_raycast():
	mousePos = get_viewport().get_mouse_position()
	from = project_ray_origin(mousePos)
	to = from + project_ray_normal(mousePos) * rayLength
	space = get_world_3d().direct_space_state
	# raycast only checks 2nd collision mask
	query = PhysicsRayQueryParameters3D.create(from, to, 2)
	
	return space.intersect_ray(query)
