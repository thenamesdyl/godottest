extends StaticBody3D

# Glass Platform Parameters
@export var break_time: float = 5.0  # Time in seconds before platform breaks
@export var respawn_time: float = 5.0  # Time in seconds before platform respawns
@export var cracking_start_percentage: float = 0.5  # When to start visual cracking effects (0.0-1.0)

# Private variables
var _is_active: bool = true  # Whether the platform is currently solid/visible
var _time_stood_on: float = 0.0  # Time player has been on the platform
var _respawn_timer: float = 0.0  # Time since platform broke
var _player_on_platform: bool = false  # Whether player is currently on the platform
var _material: StandardMaterial3D  # Reference to the platform material
var _collision_shape: CollisionShape3D  # Reference to the collision shape
var _mesh_instance: MeshInstance3D  # Reference to the mesh
var _original_position: Vector3  # Original position for respawning

func _ready():
	# Store original position
	_original_position = global_position
	print("Glass platform initialized at: ", global_position)
	
	# Get references to important nodes
	_collision_shape = get_node_or_null("CollisionShape3D") 
	if _collision_shape == null:
		_collision_shape = find_child("CollisionShape3D", true)
		
	_mesh_instance = get_node_or_null("MeshInstance3D")
	if _mesh_instance == null:
		_mesh_instance = find_child("MeshInstance3D", true)
	
	print("Glass platform components - Collision: ", _collision_shape != null, " Mesh: ", _mesh_instance != null)
	
	if _mesh_instance and _mesh_instance.get_surface_override_material(0):
		_material = _mesh_instance.get_surface_override_material(0)
	else:
		# Create a new material if none exists
		_material = StandardMaterial3D.new()
		_material.albedo_color = Color(1.0, 1.0, 1.0, 0.7)  # White, slightly transparent
		_material.metallic = 0.8
		_material.roughness = 0.1
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		if _mesh_instance:
			_mesh_instance.set_surface_override_material(0, _material)

func _physics_process(delta):
	if not _is_active:
		# Handle respawning
		_respawn_timer += delta
		if _respawn_timer >= respawn_time:
			respawn()
		return
	
	# Check if player is on platform
	if _player_on_platform:
		_time_stood_on += delta
		
		# Update visual feedback based on time stood on
		update_visual_feedback()
		
		# Break platform if time exceeds break time
		if _time_stood_on >= break_time:
			break_platform()
	else:
		# Gradually reset timer when player steps off
		_time_stood_on = max(0.0, _time_stood_on - delta * 2)  # Reset twice as fast as it builds up
		update_visual_feedback()

# Update visual feedback based on how close platform is to breaking
func update_visual_feedback():
	if not _material or not _is_active:
		return
	
	var break_percentage = _time_stood_on / break_time
	if break_percentage > cracking_start_percentage:
		# Calculate how close we are to breaking (0.0 = just started cracking, 1.0 = about to break)
		var crack_progress = (break_percentage - cracking_start_percentage) / (1.0 - cracking_start_percentage)
		
		# Visual effects showing platform is about to break
		_material.albedo_color = Color(1.0, 1.0 - crack_progress, 1.0 - crack_progress, 0.7)
		_material.emission_enabled = true
		_material.emission = Color(0.8, 0.2, 0.2)
		_material.emission_energy = crack_progress * 2.0
		
		# Optional: Add shaking effect as platform is about to break
		if crack_progress > 0.7:
			var shake_amount = crack_progress * 0.05
			global_position = _original_position + Vector3(
				randf_range(-shake_amount, shake_amount),
				0,
				randf_range(-shake_amount, shake_amount)
			)
	else:
		# Reset visual effects when below threshold
		_material.albedo_color = Color(1.0, 1.0, 1.0, 0.7)
		_material.emission_enabled = false
		global_position = _original_position

# Break the platform
func break_platform():
	print("Breaking glass platform!")
	_is_active = false
	_respawn_timer = 0.0
	
	# Disable collision
	if _collision_shape:
		_collision_shape.disabled = true
	else:
		push_error("Glass platform missing collision shape!")
	
	# Hide mesh
	if _mesh_instance:
		_mesh_instance.visible = false
	else:
		push_error("Glass platform missing mesh instance!")
	
	# Make sure we reset player on platform state
	_player_on_platform = false
	_time_stood_on = 0.0
	
	# Optional: Play break effect/sound here

# Respawn the platform
func respawn():
	_is_active = true
	_time_stood_on = 0.0
	_player_on_platform = false
	
	# Reset position
	global_position = _original_position
	
	# Re-enable collision
	if _collision_shape:
		_collision_shape.disabled = false
	
	# Show mesh
	if _mesh_instance:
		_mesh_instance.visible = true
	
	# Reset material
	if _material:
		_material.albedo_color = Color(1.0, 1.0, 1.0, 0.7)
		_material.emission_enabled = false
	
	# Optional: Play spawn effect/sound here

# Called when a body enters the platform's area
func _on_body_entered(body):
	if body is CharacterBody3D and body.is_in_group("player"):
		print("Player detected on glass platform")
		_player_on_platform = true
	else:
		print("Non-player body touched glass platform: ", body.name)

# Called when a body exits the platform's area
func _on_body_exited(body):
	if body is CharacterBody3D and body.is_in_group("player"):
		print("Player left glass platform")
		_player_on_platform = false
	else:
		print("Non-player body left glass platform: ", body.name)
