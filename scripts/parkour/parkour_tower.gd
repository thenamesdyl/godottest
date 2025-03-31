extends Node3D

# Configuration for the tower
@export var tower_height: int = 100  # Number of slabs
@export var base_slab_size: Vector3 = Vector3(3, 0.5, 3)
@export var min_slab_size: Vector3 = Vector3(1.5, 0.5, 1.5)
@export var vertical_spacing: float = 2.5  # Space between slabs
@export var max_horizontal_offset: float = 4.0  # Maximum jump distance
@export var difficulty_increase_rate: float = 0.1  # How quickly difficulty increases (0-1)
@export var tower_seed: int = 0  # Seed for randomization

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
		
		# Calculate next slab position with increasing offset
		var max_offset = max_horizontal_offset * current_difficulty
		var next_x = prev_position.x + rng.randf_range(-max_offset, max_offset)
		var next_z = prev_position.z + rng.randf_range(-max_offset, max_offset)
		var next_y = prev_position.y + vertical_spacing
		
		# Size decreases slightly as we go higher
		var size_reduction = lerp(1.0, min_slab_size.x / base_slab_size.x, current_difficulty)
		var slab_size = base_slab_size * size_reduction
		
		# Create the slab
		var slab = create_slab(
			slab_size, 
			Vector3(next_x, next_y, next_z),
			Color(
				lerp(0.2, 0.8, current_difficulty),
				lerp(0.7, 0.2, current_difficulty),
				lerp(0.2, 0.2, current_difficulty)
			)
		)
		slab.name = "Slab_" + str(i+1)
		add_child(slab)
		
		# Update previous position
		prev_position = Vector3(next_x, next_y, next_z)
		
	print("Parkour tower generation complete!")

# Create a single slab with proper collision
func create_slab(size: Vector3, position: Vector3, color: Color) -> StaticBody3D:
	var slab = StaticBody3D.new()
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
	
	# Apply material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.set_surface_override_material(0, material)
	
	slab.add_child(mesh_instance)
	return slab
