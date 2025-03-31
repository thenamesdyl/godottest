extends Node3D

var speed = 5.0
var turn_speed = 2.0
var height_range = Vector2(10, 30)  # Min and max flying height
var boundary_size = 50.0  # How far from center they can fly
var velocity = Vector3.ZERO
var target_position = Vector3.ZERO

func _ready():
	# Start at a random position within bounds
	position = Vector3(
		randf_range(-boundary_size, boundary_size),
		randf_range(height_range.x, height_range.y),
		randf_range(-boundary_size, boundary_size)
	)
	
	# Set initial target
	pick_new_target()

func _physics_process(delta):
	# Move towards target
	var direction = (target_position - position).normalized()
	velocity = velocity.lerp(direction * speed, delta * turn_speed)
	position += velocity * delta
	
	# Look in the direction of movement
	if velocity.length() > 0.1:
		look_at(position + velocity, Vector3.UP)
		# Add slight banking effect when turning
		rotation.z = -velocity.cross(Vector3.UP).normalized().dot(transform.basis.x) * 0.3
	
	# Check if we need a new target
	if position.distance_to(target_position) < 2.0:
		pick_new_target()
	
	# Keep within bounds
	if position.length() > boundary_size or position.y < height_range.x or position.y > height_range.y:
		pick_new_target()

func pick_new_target():
	target_position = Vector3(
		randf_range(-boundary_size, boundary_size),
		randf_range(height_range.x, height_range.y),
		randf_range(-boundary_size, boundary_size)
	) 