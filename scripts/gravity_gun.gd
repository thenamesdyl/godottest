extends Node3D

@onready var camera = get_parent().get_node("Camera3D")
var grab_distance = 5.0
var throw_force = 20.0
var max_grab_distance = 10.0
var current_object: RigidBody3D = null

func _ready():
	# Add to group for easy access
	add_to_group("gravity_gun")

func _physics_process(_delta):
	if current_object:
		# Update target position in front of camera
		var target_pos = camera.global_position + (-camera.global_transform.basis.z * grab_distance)
		current_object.target_position = target_pos

func _input(event):
	if event.is_action_pressed("grab"): # We'll define this input action later
		if current_object:
			release_object(true)
		else:
			grab_object()
	elif event.is_action_pressed("release"): # We'll define this input action later
		if current_object:
			release_object(false)

func grab_object():
	var space_state = get_world_3d().direct_space_state
	var mouse_position = get_viewport().get_mouse_position()
	
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z * max_grab_distance)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider is RigidBody3D:
		current_object = result.collider
		grab_distance = (result.position - from).length()
		current_object.grab(from + (-camera.global_transform.basis.z * grab_distance))

func release_object(throw: bool):
	if current_object:
		var impulse = Vector3.ZERO
		if throw:
			impulse = -camera.global_transform.basis.z * throw_force
		current_object.release(impulse)
		current_object = null 