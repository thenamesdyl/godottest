extends Node3D

@onready var camera = get_parent().get_node("Camera3D")
var grab_distance = 5.0
var throw_force = 15.0  # Reduced for better control
var max_grab_distance = 10.0
var current_object: RigidBody3D = null
var target_grab_distance = 5.0
var smooth_factor = 10.0  # For smooth distance changes

func _ready():
	# Add to group for easy access
	add_to_group("gravity_gun")

func _physics_process(delta):
	if current_object:
		# Smoothly adjust grab distance based on mouse wheel
		grab_distance = lerp(grab_distance, target_grab_distance, delta * smooth_factor)
		
		# Calculate target position with smooth interpolation
		var target_pos = camera.global_position + (-camera.global_transform.basis.z * grab_distance)
		current_object.target_position = target_pos

func _input(event):
	if event.is_action_pressed("grab"):
		if current_object:
			release_object(true)
		else:
			grab_object()
	elif event.is_action_pressed("release"):
		if current_object:
			release_object(false)
	
	# Handle mouse wheel for distance adjustment
	if event is InputEventMouseButton and current_object:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_grab_distance = min(target_grab_distance + 0.5, max_grab_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_grab_distance = max(target_grab_distance - 0.5, 2.0)

func grab_object():
	var space_state = get_world_3d().direct_space_state
	
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z * max_grab_distance)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider is RigidBody3D:
		current_object = result.collider
		target_grab_distance = (result.position - from).length()
		grab_distance = target_grab_distance
		current_object.grab(from + (-camera.global_transform.basis.z * grab_distance))

func release_object(throw: bool):
	if current_object:
		var impulse = Vector3.ZERO
		if throw:
			# Calculate throw force based on current movement
			var throw_dir = -camera.global_transform.basis.z
			impulse = throw_dir * throw_force
		current_object.release(impulse)
		current_object = null
		# Reset grab distance
		target_grab_distance = 5.0
		grab_distance = 5.0 