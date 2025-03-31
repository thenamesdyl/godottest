extends Node3D

@onready var camera = get_parent().get_node("Camera3D")
var grab_distance = 5.0
var throw_force = 15.0  # Reduced for better control
var max_grab_distance = 10.0
var current_object: RigidBody3D = null
var target_grab_distance = 5.0
var smooth_factor = 10.0  # For smooth distance changes
var attached_blocks = {}  # Dictionary to track attached blocks {block: parent_block}

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

# Attach the currently held block to another block
func attach_blocks():
	if current_object == null:
		return  # No block is grabbed, can't attach
	
	# Check for nearby blocks to attach to
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z * max_grab_distance)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	# Exclude the current object from the raycast
	query.exclude = [current_object]
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider is RigidBody3D and result.collider.has_method("is_grabbable"):
		# This is a block we can attach to
		var target_block = result.collider
		
		# Calculate the attachment position (close to the hit point)
		var attach_offset = result.position - target_block.global_position
		
		# Create a fixed joint to attach the blocks
		var joint = create_joint(current_object, target_block, attach_offset)
		
		# Add to attached blocks dictionary
		attached_blocks[current_object] = {
			"parent": target_block,
			"joint": joint
		}
		
		# Release the object from the gravity gun, but don't apply impulse
		current_object.release(Vector3.ZERO)
		current_object = null
		target_grab_distance = 5.0
		grab_distance = 5.0

# Detach any attached blocks that are currently visible
func detach_blocks():
	# If we're holding an object, check if it's in our attached_blocks dictionary
	if current_object and attached_blocks.has(current_object):
		# Remove the joint
		var joint_data = attached_blocks[current_object]
		joint_data.joint.queue_free()
		attached_blocks.erase(current_object)
		return
	
	# If we're not holding anything, try to detach what we're looking at
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z * max_grab_distance)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider is RigidBody3D:
		var target_block = result.collider
		
		# Check if this block is attached to something or has other blocks attached to it
		for block in attached_blocks.keys():
			if attached_blocks[block].parent == target_block:
				# This block has another block attached to it, detach it
				attached_blocks[block].joint.queue_free()
				attached_blocks.erase(block)
				return
		
		# If we're looking at a block that is attached to something, detach it
		if attached_blocks.has(target_block):
			attached_blocks[target_block].joint.queue_free()
			attached_blocks.erase(target_block)

# Create a fixed joint between two blocks
func create_joint(block_a, block_b, offset = Vector3.ZERO) -> Node:
	var joint = Generic6DOFJoint3D.new()
	joint.name = "AttachJoint"
	joint.node_a = block_a.get_path()
	joint.node_b = block_b.get_path()
	
	# Set transform to position the joint at the connection point
	joint.global_transform.origin = block_b.global_position + offset
	
	# Lock all the degrees of freedom for a solid connection
	# Linear limits
	joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	
	# Angular limits (we could allow some rotation if desired)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0)
	
	# Add the joint to the scene
	get_tree().get_root().add_child(joint)
	return joint 