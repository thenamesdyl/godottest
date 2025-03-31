extends StaticBody3D

# Jump Pad Parameters
@export var gravity_modifier: float = 0.16  # Moon gravity is ~1/6 of Earth's
@export var effect_duration: float = 10.0   # Duration of moon gravity effect in seconds
@export var bounce_force: float = 15.0      # Force applied when landing on pad
@export var pad_color: Color = Color(1.0, 0.0, 1.0, 1.0)  # Bright pink color for high visibility

# Visual effects
var _material: StandardMaterial3D
var _mesh_instance: MeshInstance3D
var _original_position: Vector3
var _animation_timer: float = 0.0
var _active: bool = true
var _detection_area: Area3D

# Called when the node enters the scene tree for the first time
func _ready():
	# Store original position
	_original_position = global_position
	
	# Get reference to the mesh instance
	_mesh_instance = get_node_or_null("MeshInstance3D")
	if _mesh_instance == null:
		_mesh_instance = find_child("MeshInstance3D", true)
		
	# Setup detection area if not already set up
	_setup_detection_area()
	
	# Get or create material
	if _mesh_instance and _mesh_instance.get_surface_override_material(0):
		_material = _mesh_instance.get_surface_override_material(0)
		# Apply jump pad colors
		_material.albedo_color = pad_color
		_material.emission_enabled = true
		_material.emission = pad_color
		_material.emission_energy = 1.0
	else:
		# Create a new material if none exists
		_material = StandardMaterial3D.new()
		_material.albedo_color = pad_color
		_material.emission_enabled = true
		_material.emission = pad_color
		_material.emission_energy = 1.0
		
		if _mesh_instance:
			_mesh_instance.set_surface_override_material(0, _material)

func _physics_process(delta):
	# Animate the jump pad
	_animation_timer += delta * 4.0  # Faster animation
	
	# Pulse the emission energy for visual effect
	if _material and _active:
		_material.emission_energy = 2.5 + 1.5 * sin(_animation_timer)  # Much stronger glow (1.0-4.0 range)
		
		# More noticeable hovering animation
		var hover_offset = 0.2 * sin(_animation_timer)  # 4x larger hover height
		global_position = _original_position + Vector3(0, hover_offset, 0)

# Apply moon gravity effect to the player
func apply_moon_gravity(player):
	if player and player.has_method("set_gravity_modifier"):
		player.set_gravity_modifier(gravity_modifier, effect_duration)
		player.velocity.y = bounce_force  # Apply bounce force
		
		# Visual feedback
		flash_pad()

# Visual feedback when pad is activated
func flash_pad():
	if _material:
		# Briefly increase emission for activation effect
		_material.emission_energy = 3.0
		
		# You could add particles or other effects here

# Create and setup the detection area
func _setup_detection_area():
	# Check if we already have one
	_detection_area = get_node_or_null("JumpPadDetectionArea")
	if _detection_area != null:
		return
		
	# Create an Area3D slightly above the platform to detect the player
	_detection_area = Area3D.new()
	_detection_area.name = "JumpPadDetectionArea"
	
	# Create a collision shape for the area
	var area_collision = CollisionShape3D.new()
	var area_shape = BoxShape3D.new()
	
	# Get platform size from collision shape
	var platform_size = Vector3(1, 0.5, 1)  # Default fallback size
	var collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape and collision_shape.shape is BoxShape3D:
		platform_size = collision_shape.shape.size
	
	# Make detection area slightly smaller than platform and positioned just above it
	area_shape.size = Vector3(platform_size.x * 0.9, 0.2, platform_size.z * 0.9)
	area_collision.shape = area_shape

	# Position the area just above the platform
	_detection_area.position = Vector3(0, platform_size.y/2 + 0.1, 0)
	
	# Connect signals directly
	_detection_area.connect("body_entered", _on_area_body_entered)
	
	# Add to scene
	_detection_area.add_child(area_collision)
	add_child(_detection_area)

# Direct handler for area body entered signal
func _on_area_body_entered(body):
	if body is CharacterBody3D and body.is_in_group("player"):
		print("Player landed on jump pad")
		apply_moon_gravity(body)
