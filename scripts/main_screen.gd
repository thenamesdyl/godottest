extends Node3D

@onready var player = $Player
@onready var chunk_manager = $ChunkManager
var parkour_tower_scene = preload("res://scenes/parkour/parkour_tower.tscn")

func _ready():
	print("Main scene loaded")
	
	# Player will be positioned near the parkour tower once it's created
	# Initial position is just temporary
	player.position = Vector3(0, 15, 0)
	
	# Ensure chunk is generated before player lands
	await get_tree().create_timer(0.1).timeout
	chunk_manager.update_chunks()
	
	# Setup skybox
	setup_skybox()
	
	# Add parkour tower
	await get_tree().create_timer(0.5).timeout # Wait for terrain to generate
	add_parkour_tower()

func _process(_delta):
	# Process function for any future updates we might need
	pass 

# Add the parkour tower to the scene at a suitable location
func add_parkour_tower():
	print("Adding parkour tower...")
	
	# Create instance of the tower
	var tower_instance = parkour_tower_scene.instantiate()
	
	# Find a good position for the tower on an island
	var tower_position = find_island_position()
	
	# Set the tower position - make sure it's above the highest terrain point
	tower_instance.position = tower_position
	
	# Add to the scene
	add_child(tower_instance)
	
	# Position player near the tower's base for testing
	player.position = tower_instance.position + Vector3(5, 10, 5)
	
	print("Parkour tower added at position: ", tower_instance.position)
	print("Player positioned near tower at: ", player.position)

# Find a suitable position for the tower on an island
func find_island_position() -> Vector3:
	# This is a simplified method to find an island location
	# In a real implementation, you would scan through the terrain to find actual islands
	
	# Use a noise generator to find a consistent position that's likely to be on an island
	var noise = FastNoiseLite.new()
	noise.seed = 12345 # Fixed seed for consistent results
	noise.frequency = 0.01
	
	# Search for a spot with high elevation (islands have noise value > 0.3)
	var best_pos = Vector3(100, 0, 100) # Default fallback position
	var best_value = 0.0
	
	# Try several candidate positions to find the best island
	for attempt in range(20):
		# Check in different directions with increasing distance
		var angle = attempt * (2.0 * PI / 20.0)
		var distance = 100 + (attempt * 10) # Increasing distance
		var check_x = cos(angle) * distance
		var check_z = sin(angle) * distance
		
		# Get the noise value at this position
		var noise_value = noise.get_noise_2d(check_x, check_z)
		
		# If this is a good island spot (> 0.3) and better than what we've found
		if noise_value > 0.3 and noise_value > best_value:
			best_value = noise_value
			best_pos = Vector3(check_x, best_value * 5.0, check_z)
	
	# Add some extra height to make sure the tower base is above water
	best_pos.y += 1.0
	
	print("Found island position with elevation: ", best_pos.y)
	return best_pos

# Setup skybox with the provided image
func setup_skybox():
	# Create environment if it doesn't exist
	var environment
	
	# Check if we already have a WorldEnvironment node
	var world_environment = get_node_or_null("WorldEnvironment")
	if world_environment:
		environment = world_environment.environment
	else:
		# Create a new WorldEnvironment node
		world_environment = WorldEnvironment.new()
		world_environment.name = "WorldEnvironment"
		add_child(world_environment)
		
		# Create new environment
		environment = Environment.new()
		world_environment.environment = environment
	
	# Create sky
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.4, 0.6, 0.8) # Default sky blue
	
	# Try to load skybox texture
	var skybox_texture = load("res://skybox.jpg")
	if skybox_texture:
		# Create a skybox using a mesh instead
		var skybox = MeshInstance3D.new()
		skybox.name = "Skybox"
		
		# Create sphere mesh for skybox
		var sphere = SphereMesh.new()
		sphere.radius = 1000 # Large enough to encompass the scene
		sphere.height = 2000
		sphere.is_hemisphere = false
		skybox.mesh = sphere
		
		# Create material for skybox
		var material = StandardMaterial3D.new()
		material.albedo_texture = skybox_texture
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.flags_do_not_receive_shadows = true
		material.params_cull_mode = BaseMaterial3D.CULL_FRONT # Draw on inside of sphere
		
		# Apply material to skybox
		skybox.material_override = material
		
		# Add ambient light
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(0.2, 0.2, 0.2)
		environment.ambient_light_energy = 1.0
		
		# Add to scene
		add_child(skybox)
		
		print("Skybox applied successfully")
	else:
		print("Failed to load skybox texture. Make sure 'skybox.jpg' exists in the project root.")
