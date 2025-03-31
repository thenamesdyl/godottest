extends RigidBody3D

var is_grabbed = false
var target_position = Vector3.ZERO
var grab_force = 15.0  # Reduced from 20 for smoother movement
var return_force = 10.0
var damping_factor = 0.8  # Added damping to reduce jitter

# Helper method to identify this object as grabbable for the gravity gun
func is_grabbable():
	return true

func _physics_process(delta):
	if is_grabbed:
		# Calculate direction and distance to target
		var direction = target_position - global_position
		var distance = direction.length()
		
		if distance > 0.1:
			# Apply smooth interpolation instead of direct force
			var target_velocity = direction.normalized() * grab_force * distance
			
			# Dampen current velocity to reduce oscillation
			linear_velocity = linear_velocity.lerp(target_velocity, delta * return_force)
			
			# Apply additional damping to angular velocity
			angular_velocity = angular_velocity * (1.0 - delta * damping_factor)
			
			# Ensure we're not overshooting
			if distance < 1.0:
				linear_velocity = linear_velocity * (distance)
		else:
			# If we're very close to target, dampen movement more aggressively
			linear_velocity = linear_velocity.lerp(Vector3.ZERO, delta * return_force)
			angular_velocity = angular_velocity * (1.0 - delta * damping_factor)

func grab(pos):
	is_grabbed = true
	target_position = pos
	# Reset velocities when grabbed to prevent initial jitter
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	# Increase gravity scale when grabbed to make it more stable
	gravity_scale = 0.1
	# Enable continuous collision detection for better physics
	custom_integrator = true
	contact_monitor = true
	max_contacts_reported = 4

func release(impulse = Vector3.ZERO):
	is_grabbed = false
	# Restore normal physics properties
	gravity_scale = 1.0
	custom_integrator = false
	contact_monitor = false
	if impulse != Vector3.ZERO:
		apply_central_impulse(impulse) 