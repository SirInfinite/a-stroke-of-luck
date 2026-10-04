class_name BallMotion
extends RefCounted
## Static-course sweep shared by the CCD backstop and the shot forecast.
## Native RigidBody2D still owns ordinary motion and moving-body contacts.

const MAX_IMPACTS := 8
const SKIN := 0.08

static func reflect_velocity(velocity: Vector2, normal: Vector2, restitution: float) -> Vector2:
	# Golf has no spin: preserve the incident/reflected angle, losing energy
	# uniformly. Coulomb tangential clipping flattened oblique shots into normals.
	return velocity.bounce(normal.normalized()) * clampf(restitution, 0.0, 1.0)

static func damp_velocity(velocity: Vector2, damping: float, step: float) -> Vector2:
	# GodotPhysics2D integrates damping BEFORE position, including world damping.
	return velocity * maxf(1.0 - maxf(damping, 0.0) * step, 0.0)

static func sweep(body: RID, from: Transform2D, velocity: Vector2, step: float, bounce := 0.35, _friction := 0.4) -> Dictionary:
	var remaining := maxf(step, 0.0)
	var contacts: Array[Dictionary] = []
	var points := PackedVector2Array()
	var parameters := PhysicsTestMotionParameters2D.new()
	parameters.margin = SKIN
	var result := PhysicsTestMotionResult2D.new()
	for iteration in range(MAX_IMPACTS):
		if remaining <= 0.000001 or velocity.length_squared() < 0.0001:
			break
		parameters.from = from
		parameters.motion = velocity * remaining
		parameters.exclude_bodies = []
		var hit := false
		# Ignore moving timing hazards, not the static boundary behind them.
		for exclusion in range(MAX_IMPACTS):
			hit = PhysicsServer2D.body_test_motion(body, parameters, result)
			if not hit:
				break
			var collider := result.get_collider()
			if collider is AnimatableBody2D and collider.get("fall_state") != &"landed":
				parameters.exclude_bodies.append(collider.get_rid())
				hit = false
				continue
			break
		if not hit:
			from.origin += parameters.motion
			remaining = 0.0
			break
		var normal := result.get_collision_normal().normalized()
		var incoming := velocity.dot(normal)
		from.origin += result.get_travel()
		if incoming >= -0.001:
			# A grazing/recovery contact must not inject a second impulse.
			remaining = 0.0
			break
		from.origin += normal * SKIN
		points.append(from.origin)
		contacts.append({"position": result.get_collision_point(), "speed": -incoming})
		remaining *= 1.0 - result.get_collision_safe_fraction()
		velocity = reflect_velocity(velocity, normal, bounce)
	# Exhausted iterations discard only unresolved travel, never cross a wall.
	return {"position": from.origin, "velocity": velocity, "contacts": contacts, "points": points, "capped": remaining > 0.000001}
