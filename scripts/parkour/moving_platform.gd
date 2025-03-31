extends StaticBody3D

# Movement parameters
@export var movement_vector: Vector3 = Vector3(2.0, 0.0, 0.0)  # Default to side movement
@export var movement_speed: float = 1.0  # Speed of the movement
@export var move_time: float = 2.0  # Time to complete one way (seconds)
@export var show_movement_trail: bool = true  # Show trail indicators

# Private variables
var _start_position: Vector3
var _target_position: Vector3
var _move_timer: float = 0.0
var _moving_forward: bool = true
var _trail_indicators: Array = []
var _material: StandardMaterial3D

func _ready():
	# Store the initial position
	_start_position = global_position
	# Calculate the target position
	_target_position = _start_position + movement_vector
	
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
	# Update the timer
	_move_timer += delta * movement_speed * (1.0 if _moving_forward else -1.0)
	
	# Calculate the progress ratio (0.0 to 1.0)
	var progress = 0.0
	if _moving_forward:
		progress = min(_move_timer / move_time, 1.0)
	else:
		progress = 1.0 - min(abs(_move_timer) / move_time, 1.0)
	
	# Apply smooth interpolation for natural movement
	# Using smoothstep for easing at endpoints
	var smooth_progress = smoothstep(0.0, 1.0, progress)
	global_position = _start_position.lerp(_target_position, smooth_progress)
	
	# Pulse the emission on the material for visual effect
	if _material != null:
		_material.emission_energy = 0.8 + sin(Time.get_ticks_msec() * 0.005) * 0.4
	
	# Change direction when reaching endpoints
	if _moving_forward and _move_timer >= move_time:
		_moving_forward = false
	elif not _moving_forward and _move_timer <= -move_time:
		_moving_forward = true

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
	
	# Create indicators along the movement path
	var num_indicators = 5
	for i in range(num_indicators):
		# Create small sphere indicator
		var indicator = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.15
		sphere.height = 0.3
		indicator.mesh = sphere
		
		# Position along the path
		var pos_ratio = float(i) / float(num_indicators - 1)
		# Position indicator slightly below the platform
		var indicator_pos = _start_position.lerp(_target_position, pos_ratio)
		indicator_pos.y -= platform_mesh.size.y * 0.5 - 0.1  # Below platform but visible
		indicator.position = indicator_pos - global_position  # Make relative to platform
		
		# Apply material
		var indicator_mat = StandardMaterial3D.new()
		indicator_mat.albedo_color = Color(1.0, 1.0, 0.0, 0.7)
		indicator_mat.emission_enabled = true
		indicator_mat.emission = Color(1.0, 1.0, 0.0)
		indicator_mat.emission_energy = 1.0
		indicator.material_override = indicator_mat
		
		add_child(indicator)
		_trail_indicators.append(indicator)
	
	# Add arrow at endpoints to indicate direction
	add_endpoint_arrow(_start_position - global_position)
	add_endpoint_arrow(_target_position - global_position)
