extends Node3D

# Configuration for the tower
@export var tower_height: int = 100  # Number of slabs
@export var base_slab_size: Vector3 = Vector3(4, 0.5, 4)  # Slightly larger base platform
@export var min_slab_size: Vector3 = Vector3(1.5, 0.5, 1.5)  # Smallest platform size
@export var vertical_spacing: float = 2.5  # Space between slabs
@export var max_horizontal_offset: float = 5.0  # Maximum jump distance (increased for more spread-out platforms)
@export var difficulty_increase_rate: float = 0.075  # Slightly more gradual difficulty increase
@export var tower_seed: int = 0  # Seed for randomization
@export var add_special_platforms: bool = true  # Whether to add special platform types
@export var moving_platforms_ratio: float = 0.2  # Increased to about 1 out of 5 platforms moving
@export var platform_movement_distance: float = 3.5  # Increased distance that platforms can move (more dramatic movement)

var rng = RandomNumberGenerator.new()

func _ready():
	if tower_seed == 0:
		tower_seed = randi()  # Generate random seed if not specified
	
	rng.seed = tower_seed
	generate_tower()

# Generate the entire parkour tower
func generate_tower():
	print("Generating parkour tower with ", tower_height, " slabs...")
	
	# Create the base platform
	var base = create_slab(base_slab_size * 1.5, Vector3(0, 0, 0), Color(0.3, 0.3, 0.3))
	base.name = "Base"
	add_child(base)
	
	var prev_position = Vector3(0, 0, 0)
	var current_difficulty = 0.0
	
	# Generate each level of the tower
	for i in range(tower_height):
		# Increase difficulty as we go higher
		current_difficulty = min(1.0, i * difficulty_increase_rate / tower_height)
		
		# Calculate next slab position with more significant horizontal variation
		# Higher minimum offset ensures platforms aren't directly above each other
		var min_offset = max_horizontal_offset * 0.5 # Increased minimum horizontal displacement
		var max_offset = max_horizontal_offset * (1.0 + current_difficulty * 2.0) # Double the maximum offset
		
		# Determine direction using angle to create a more interesting spiral pattern
		# Use a partially guided pattern to create more interesting parkour paths
		var base_angle = (i * 0.3) # Creates a gentle spiral pattern base
		var angle = base_angle + rng.randf_range(-0.5, 0.5) # Add randomness to the spiral
		
		# Every few platforms, force a big jump
		var force_big_jump = (i % 5 == 0 && i > 0) # More frequent big jumps (every 5 instead of 7)
		var jump_multiplier = 1.0 if !force_big_jump else 1.8 # Increased big jump multiplier
		
		# Determine offset magnitude - random between min and max
		var offset_magnitude = rng.randf_range(min_offset, max_offset) * jump_multiplier
		
		# Apply offset based on angle and magnitude
		var next_x = prev_position.x + cos(angle) * offset_magnitude
		var next_z = prev_position.z + sin(angle) * offset_magnitude
		
		# Vary vertical spacing slightly too for more natural look
		var height_variation = rng.randf_range(0.8, 1.2)
		var next_y = prev_position.y + (vertical_spacing * height_variation)
		
		# Every 10 levels, create a larger rest platform (checkpoint)
		var is_checkpoint = (i % 10 == 0 && i > 0)
		
		# Size varies based on height and checkpoints
		var size_reduction = lerp(1.0, min_slab_size.x / base_slab_size.x, current_difficulty)
		var slab_size = base_slab_size * (1.2 if is_checkpoint else size_reduction)
		
		# Platform type variations to increase parkour interest
		var platform_type = rng.randi_range(0, 10)
		var slab_color: Color
		var should_move = false
		
		# Add different platform types for variety
		if is_checkpoint:
			# Checkpoint platforms are gold-colored
			slab_color = Color(0.9, 0.7, 0.2)
		elif platform_type < 2 && add_special_platforms && i > 5:
			# Moving platforms - bright red colored and actually moving
			slab_color = Color(1.0, 0.1, 0.1)
			# Make most red platforms move (higher probability)
			should_move = rng.randf() < 0.9 && !is_checkpoint
		elif platform_type < 4 && add_special_platforms && i > 10:
			# Bouncy platforms - simulated by making them blue
			slab_color = Color(0.2, 0.2, 0.9)
		else:
			# Standard platforms change from green to red as you climb higher
			slab_color = Color(
				lerp(0.2, 0.8, current_difficulty),
				lerp(0.7, 0.2, current_difficulty),
				lerp(0.2, 0.2, current_difficulty)
			)
		
		# Create the slab with appropriate properties - pass flag to make it move if needed
		var slab = create_slab(slab_size, Vector3(next_x, next_y, next_z), slab_color, should_move)
		slab.name = "Slab_" + str(i+1)
		if should_move:
			slab.name = "MovingSlab_" + str(i+1)
		add_child(slab)
		
		# For checkpoints, add a visible marker
		if is_checkpoint:
			add_checkpoint_marker(slab, i)
		
		# Update previous position
		prev_position = Vector3(next_x, next_y, next_z)
		
	print("Parkour tower generation complete!")

# Create a single slab with proper collision
func create_slab(size: Vector3, position: Vector3, color: Color, make_moving: bool = false) -> StaticBody3D:
	var slab
	
	if make_moving:
		# Create a moving platform using our custom script
		var script = load("res://scripts/parkour/moving_platform.gd")
		slab = StaticBody3D.new()
		slab.set_script(script)
		slab.transform.origin = position
		
		# Set random movement direction (excluding vertical movement)
		var move_dir = get_random_movement_direction()
		var move_distance = platform_movement_distance * (0.8 + 0.4 * rng.randf()) # Randomize slightly, but keep distance large
		
		# Set movement parameters for smooth sine-based movement
		slab.movement_vector = move_dir * move_distance
		slab.movement_speed = 1.2 + rng.randf() * 0.8  # Controls frequency - between 1.2 and 2.0
		slab.movement_amplitude = 0.8 + rng.randf() * 0.4  # Controls distance moved - between 0.8 and 1.2
	else:
		# Create a regular static platform
		slab = StaticBody3D.new()
		slab.transform.origin = position
		
	# Create collision shape
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	slab.add_child(collision)
	
	# Create visual mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	
	# Apply material with some shininess for better visuals
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.2
	material.roughness = 0.7
	
	# Add rim lighting for better visibility
	material.rim_enabled = true
	material.rim = 0.2
	
	mesh_instance.set_surface_override_material(0, material)
	slab.add_child(mesh_instance)
	return slab

# Generate a random movement direction for moving platforms (no vertical movement)
func get_random_movement_direction() -> Vector3:
	var direction_type = rng.randi() % 3  # Simplify to more dramatic directions
	var direction = Vector3.ZERO
	
	match direction_type:
		0: # X-axis movement (left-right)
			direction = Vector3(1, 0, 0)
		1: # Z-axis movement (forward-backward)
			direction = Vector3(0, 0, 1) 
		2: # Diagonal movement
			direction = Vector3(0.7, 0, 0.7)
	
	# Random flip direction
	if rng.randf() > 0.5:
		direction.x *= -1
	if rng.randf() > 0.5:
		direction.z *= -1
		
	return direction.normalized()

# Add a visible marker for checkpoint platforms
func add_checkpoint_marker(parent_slab: Node3D, level: int):
	# Create a small beacon
	var beacon = MeshInstance3D.new()
	beacon.name = "CheckpointMarker"
	
	# Create a cylinder mesh for the beacon
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.2
	cylinder.bottom_radius = 0.3
	cylinder.height = 2.0
	beacon.mesh = cylinder
	
	# Position it on top of the platform
	beacon.position = Vector3(0, 1.5, 0)
	
	# Add a rotating animation
	var beacon_material = StandardMaterial3D.new()
	beacon_material.emission_enabled = true
	beacon_material.emission = Color(1.0, 0.8, 0.0)
	beacon_material.emission_energy = 2.0
	beacon.set_surface_override_material(0, beacon_material)
	
	# Add a label showing the checkpoint level
	var label_3d = Label3D.new()
	label_3d.text = "Level " + str(level)
	label_3d.font_size = 24
	label_3d.position = Vector3(0, 2.5, 0)
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Add to the slab
	parent_slab.add_child(beacon)
	parent_slab.add_child(label_3d)
