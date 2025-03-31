extends Node3D

@onready var player = $Player
@onready var chunk_manager = $ChunkManager
var parkour_tower_scene = preload("res://scenes/parkour/parkour_tower.tscn")

func _ready():
	print("Main scene loaded")
	
	# Setup input actions for block attachment/detachment
	setup_input_actions()
	
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
	
	# Position grabbable objects near the tower
	reposition_grabbable_objects(tower_instance.position)
	
	print("Parkour tower added at position: ", tower_instance.position)
	print("Player positioned near tower at: ", player.position)

# Reposition grabbable objects near the given position
func reposition_grabbable_objects(tower_position: Vector3):
	# Find the grabbable objects container
	var grabbable_objects = get_node_or_null("GrabbableObjects")
	if not grabbable_objects:
		print("Warning: GrabbableObjects node not found")
		return
	
	# Get all grabbable objects
	var objects = grabbable_objects.get_children()
	print("Repositioning ", objects.size(), " grabbable objects near tower")
	
	# Create a pattern around the tower base
	for i in range(objects.size()):
		var object = objects[i]
		if object is RigidBody3D:
			# Calculate position in a circle pattern around tower
			var angle = i * (2.0 * PI / objects.size())
			var distance = 3.0 # Distance from tower base
			var x_offset = cos(angle) * distance
			var z_offset = sin(angle) * distance
			var height_offset = 2.0 # Height above tower base
			
			# Set new position
			object.global_position = tower_position + Vector3(x_offset, height_offset, z_offset)
			
			# Reset physics to avoid residual velocity
			object.linear_velocity = Vector3.ZERO
			object.angular_velocity = Vector3.ZERO
			
			print("Repositioned object ", object.name, " to ", object.global_position)

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
# Setup input actions for block attachment/detachment
func setup_input_actions():
	# Only add if they don't already exist
	if not InputMap.has_action("attach_blocks"):
		# E key for attaching blocks
		var attach_event = InputEventKey.new()
		attach_event.keycode = KEY_E
		InputMap.add_action("attach_blocks")
		InputMap.action_add_event("attach_blocks", attach_event)
	
	if not InputMap.has_action("detach_blocks"):
		# Q key for detaching blocks
		var detach_event = InputEventKey.new()
		detach_event.keycode = KEY_Q
		InputMap.add_action("detach_blocks")
		InputMap.action_add_event("detach_blocks", detach_event)
	
	# Also ensure the grab/release actions are defined
	if not InputMap.has_action("grab"):
		# Left mouse button for grab
		var grab_event = InputEventMouseButton.new()
		grab_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.add_action("grab")
		InputMap.action_add_event("grab", grab_event)
	
	if not InputMap.has_action("release"):
		# Right mouse button for release
		var release_event = InputEventMouseButton.new()
		release_event.button_index = MOUSE_BUTTON_RIGHT
		InputMap.add_action("release")
		InputMap.action_add_event("release", release_event)

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
