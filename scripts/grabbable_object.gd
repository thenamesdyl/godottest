extends RigidBody3D

var is_grabbed = false
var grab_force = 20.0
var target_position = Vector3.ZERO
var return_force = 15.0

func _physics_process(delta):
	if is_grabbed:
		# Calculate direction to target position
		var direction = target_position - global_position
		var distance = direction.length()
		direction = direction.normalized()
		
		# Apply force to move object towards target
		if distance > 0.1:
			linear_velocity = direction * grab_force
		else:
			linear_velocity = linear_velocity.lerp(Vector3.ZERO, delta * return_force)

func grab(pos):
	is_grabbed = true
	target_position = pos
	freeze = false

func release(impulse = Vector3.ZERO):
	is_grabbed = false
	if impulse != Vector3.ZERO:
		apply_central_impulse(impulse) 