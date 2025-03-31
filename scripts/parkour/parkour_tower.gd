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
@export var glass_platform_frequency: int = 4  # Add a glass platform every X platforms (lower = more frequent)
@export var jump_pad_frequency: int = 2  # Add many jump pads throughout the tower

var rng = RandomNumberGenerator.new()
var jump_pads = []  # List to track all jump pads in the scene

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
	
	# Clear jump pads list before generating new tower
	jump_pads = []
	
	# Add glass platforms list to make them easily findable
	var glass_platforms = []
	
	var prev_position = Vector3(0, 0, 0)
	var current_difficulty = 0.0
	
	# Generate each level of the tower
	for i in range(tower_height):
		# Declare slab variable at the beginning of the loop to avoid scope issues
		var slab = null
		
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
			slab = create_slab(slab_size, Vector3(next_x, next_y, next_z), slab_color, false)
			slab.name = "Checkpoint_" + str(i+1)
		# Jump pads - about 10% of platforms
		elif i % jump_pad_frequency == 0 && add_special_platforms:
			slab = create_jump_pad(slab_size, Vector3(next_x, next_y, next_z))
			slab.name = "JumpPad_" + str(i+1)
			# Make them larger and more noticeable
			slab.scale = Vector3(1.2, 1.0, 1.2)
			# Make higher jump pads have stronger effects
			if i > 50:
				slab.gravity_modifier = 0.12
				slab.effect_duration = 12.0
				slab.bounce_force = 25.0
			jump_pads.append(slab)
		# Moving platforms - about 15% of non-checkpoint platforms
		elif !is_checkpoint && rng.randf() < moving_platforms_ratio && add_special_platforms && i > 5:
			slab_color = Color(1.0, 0.1, 0.1)  # Bright red
			slab = create_slab(slab_size, Vector3(next_x, next_y, next_z), slab_color, true)
			slab.name = "MovingSlab_" + str(i+1)
		# Glass platforms - every 8th platform after level 5
		elif add_special_platforms && i > 5 && i % glass_platform_frequency == 0:
			slab = create_glass_slab(slab_size, Vector3(next_x, next_y, next_z))
			slab.name = "GlassSlab_" + str(i+1)
			glass_platforms.append(slab)
		# Standard platforms
		else:
			# Gradient from green to red as you climb higher
			slab_color = Color(
				lerp(0.2, 0.8, current_difficulty),
				lerp(0.7, 0.2, current_difficulty),
				lerp(0.2, 0.2, current_difficulty)
			)
			slab = create_slab(slab_size, Vector3(next_x, next_y, next_z), slab_color, false)
			slab.name = "Slab_" + str(i+1)
		
		# Add the platform to the scene
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
	beacon_material.albedo_color = Color(1.0, 0.8, 0.0)
	beacon_material.emission_enabled = true
	beacon_material.emission = Color(1.0, 0.8, 0.0)
	beacon_material.emission_energy = 2.0
	beacon.material_override = beacon_material
	
	# Add beacon to parent slab
	parent_slab.add_child(beacon)
	
	# Optional: Add level number display
	var text = "Level " + str(level+1)
	print("Adding checkpoint marker for ", text)

# Create a glass platform with appropriate properties
func create_glass_slab(size: Vector3, position: Vector3) -> StaticBody3D:
	# Create a glass platform using our custom script
	var script = load("res://scripts/parkour/glass_platform.gd")
	var slab = StaticBody3D.new()
	slab.set_script(script)
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
	
	# Apply material with transparency for glass effect
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 1.0, 0.7)  # White, slightly transparent
	material.metallic = 0.8
	material.roughness = 0.1
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Add slight rim lighting for visibility
	material.rim_enabled = true
	material.rim = 0.3
	material.rim_tint = 0.8
	
	mesh_instance.set_surface_override_material(0, material)
	slab.add_child(mesh_instance)
	
	# Add an Area3D to detect when player is on the platform
	add_detection_area(slab, size)
	
	return slab

# Add player detection area to a glass platform
func add_detection_area(slab: StaticBody3D, platform_size: Vector3):
	# Create an Area3D slightly above the platform to detect the player
	var area = Area3D.new()
	area.name = "DetectionArea"
	
	# Create a collision shape for the area
	var area_collision = CollisionShape3D.new()
	var area_shape = BoxShape3D.new()
	
	# Make detection area slightly smaller than platform and positioned just above it
	area_shape.size = Vector3(platform_size.x * 0.9, 0.2, platform_size.z * 0.9)
	area_collision.shape = area_shape

	# Position the area just above the platform
	area.position = Vector3(0, platform_size.y/2 + 0.1, 0)
	
	# Connect signals using Callable to ensure proper connection
	area.connect("body_entered", Callable(slab, "_on_body_entered"))
	area.connect("body_exited", Callable(slab, "_on_body_exited"))
	
	# Add to scene
	area.add_child(area_collision)
	slab.add_child(area)

# Jump pads now handle their own detection area setup in their _ready function

# Create a jump pad with moon gravity effect
func create_jump_pad(size: Vector3, position: Vector3) -> StaticBody3D:
	# Use the scene instead of creating it programmatically
	var jump_pad_scene = load("res://scenes/parkour/jump_pad.tscn")
	var slab = jump_pad_scene.instantiate()
	slab.transform.origin = position
	
	# Scale the jump pad to match the requested size if needed
	var default_size = Vector3(1.5, 0.5, 1.5)  # Default size from the scene
	var scale_factor = Vector3(
		size.x / default_size.x,
		size.y / default_size.y,
		size.z / default_size.z
	)
	
	# Apply scaling if necessary
	if scale_factor != Vector3.ONE:
		slab.scale = scale_factor
	
	return slab
