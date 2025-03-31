extends StaticBody3D

# Movement parameters
@export var movement_vector: Vector3 = Vector3(2.0, 0.0, 0.0)  # Default to side movement
@export var movement_speed: float = 1.0  # Speed of the movement - controls frequency
@export var movement_amplitude: float = 1.0  # Controls the distance moved (multiplied by movement_vector)
@export var show_movement_trail: bool = true  # Show trail indicators

# Private variables
var _center_position: Vector3  # Middle point of movement
var _movement_direction: Vector3  # Normalized direction vector
var _total_time: float = 0.0  # Tracks elapsed time for smooth sine movement
var _trail_indicators: Array = []
var _material: StandardMaterial3D

func _ready():
	# Store the center position (starting position will be the center)
	_center_position = global_position
	
	# Calculate normalized movement direction
	_movement_direction = movement_vector.normalized()
	
	# Randomize starting position in the cycle
	_total_time = randf() * TAU  # Random phase between 0 and 2π
	
	# Store material reference if the platform has one
	var mesh_instance = find_child("*", false) as MeshInstance3D
	if mesh_instance and mesh_instance.get_surface_override_material(0):
		_material = mesh_instance.get_surface_override_material(0)
		
		# Add emission to the material to make it stand out
		_material.emission_enabled = true
		_material.emission = _material.albedo_color
		_material.emission_energy = 0.8
	
	# Create movement trail indicators if enabled
	if show_movement_trail:
		create_movement_trail()

func _physics_process(delta):
	# Update the total time continuously
	_total_time += delta * movement_speed
	
	# Calculate smooth sine wave motion (continuous and never jumps)
	var sine_factor = sin(_total_time)
	
	# Apply movement along the direction vector
	var offset = _movement_direction * movement_vector.length() * movement_amplitude * sine_factor
	global_position = _center_position + offset
	
	# Pulse the emission on the material for visual effect
	if _material != null:
		# Sync the glow effect with the movement for natural feel
		var glow_intensity = 0.8 + abs(sine_factor) * 0.5
		_material.emission_energy = glow_intensity

# Helper function for smoother interpolation
func smoothstep(edge0: float, edge1: float, x: float) -> float:
	# Scale and clamp x to 0..1 range
	x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	# Evaluate polynomial
	return x * x * (3.0 - 2.0 * x)

# Add an arrow indicator at an endpoint
func add_endpoint_arrow(position: Vector3):
	var arrow = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.2
	cone.height = 0.4
	arrow.mesh = cone
	
	# Position and rotate arrow
	arrow.position = position
	arrow.rotate_x(PI/2)  # Point up by default
	
	# Apply material
	var arrow_mat = StandardMaterial3D.new()
	arrow_mat.albedo_color = Color(1.0, 0.0, 0.0)
	arrow_mat.emission_enabled = true
	arrow_mat.emission = Color(1.0, 0.5, 0.0)
	arrow_mat.emission_energy = 1.5
	arrow.material_override = arrow_mat
	
	add_child(arrow)
	_trail_indicators.append(arrow)

# Create visual indicators showing the movement path
func create_movement_trail():
	# Clear any existing indicators
	for indicator in _trail_indicators:
		if indicator != null:
			indicator.queue_free()
	_trail_indicators.clear()
	
	# Get the mesh size for proper scaling of indicators
	var platform_mesh: BoxMesh
	var mesh_instance = find_child("*", false) as MeshInstance3D
	if mesh_instance and mesh_instance.mesh is BoxMesh:
		platform_mesh = mesh_instance.mesh
	else:
		return # Can't create trail without a mesh reference
	
	# Calculate the start and end positions for the trail
	var amplitude = movement_vector.length() * movement_amplitude
	var start_pos = _center_position - _movement_direction * amplitude - global_position
	var end_pos = _center_position + _movement_direction * amplitude - global_position
	
	# Create indicators along the movement path
	var num_indicators = 7  # Increased for better visibility
	for i in range(num_indicators):
		# Create small sphere indicator
		var indicator = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.15
		sphere.height = 0.3
		indicator.mesh = sphere
		
		# Position along the path with cosine distribution for more indicators at the ends
		var angle = PI * float(i) / float(num_indicators - 1)
		var pos_ratio = (1.0 - cos(angle)) * 0.5  # Cosine distribution between 0 and 1
		
		# Position indicator slightly below the platform
		var indicator_pos = start_pos.lerp(end_pos, pos_ratio)
		indicator_pos.y = -platform_mesh.size.y * 0.5 - 0.1  # Below platform but visible
		indicator.position = indicator_pos
		
		# Apply material with size variation
		var indicator_mat = StandardMaterial3D.new()
		indicator_mat.albedo_color = Color(1.0, 0.8, 0.0, 0.8)
		indicator_mat.emission_enabled = true
		indicator_mat.emission = Color(1.0, 0.8, 0.0)
		indicator_mat.emission_energy = 1.0
		indicator.material_override = indicator_mat
		
		# Vary size based on position - larger at endpoints
		var size_factor = 1.0 + abs(pos_ratio - 0.5) * 1.0
		indicator.scale = Vector3.ONE * size_factor
		
		add_child(indicator)
		_trail_indicators.append(indicator)
	
	# Add arrows at endpoints to indicate direction
	add_endpoint_arrow(start_pos)
	add_endpoint_arrow(end_pos)
