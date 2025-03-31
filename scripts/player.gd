extends CharacterBody3D

# Movement parameters
const SPEED = 10.0
const ACCELERATION = 15.0
const DECELERATION = 20.0
const JUMP_VELOCITY = 8.0  # Increased jump height for parkour
const DOUBLE_JUMP_VELOCITY = 7.0  # Velocity for second jump
const AIR_CONTROL = 0.7  # How much control player has in air (0-1)
const MOUSE_SENSITIVITY = 0.002

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Parkour variables
var can_double_jump = false
var coyote_time = 0.15  # Time in seconds player can jump after leaving platform
var coyote_timer = 0.0
var has_jumped = false

func _ready():
	# Capture mouse for first-person camera control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("Player ready!")

func _input(event):
	# Handle mouse movement for camera rotation
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		$Camera3D.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -PI/2, PI/2)
	
	# Press Escape to free the mouse
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Handle attach/detach blocks with E and Q keys
	if event.is_action_pressed("attach_blocks"):
		if $GravityGun.has_method("attach_blocks"):
			$GravityGun.attach_blocks()
	
	if event.is_action_pressed("detach_blocks"):
		if $GravityGun.has_method("detach_blocks"):
			$GravityGun.detach_blocks()

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Small adjustment to keep the player grounded
		velocity.y = -0.1

	# Handle jumping with advanced parkour features
	if is_on_floor():
		can_double_jump = true
		coyote_timer = coyote_time
		has_jumped = false
	else:
		coyote_timer -= delta
	
	# Primary jump (with coyote time)
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or coyote_timer > 0) and not has_jumped:
		print("Jumping!")
		velocity.y = JUMP_VELOCITY
		has_jumped = true
		coyote_timer = 0
	
	# Double jump
	elif Input.is_action_just_pressed("ui_accept") and can_double_jump and not is_on_floor():
		print("Double jumping!")
		velocity.y = DOUBLE_JUMP_VELOCITY
		can_double_jump = false

	# Get input direction using direct key checks
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1
		print("Moving forward")
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1
		print("Moving backward")
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1
		print("Moving left")
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1
		print("Moving right")
	
	input_dir = input_dir.normalized()
	print("Input direction: ", input_dir)
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	print("Movement direction: ", direction)
	
	# Handle movement with acceleration and deceleration
	if direction:
		# Accelerate towards target velocity with reduced control in air for more skill-based parkour
		var target_velocity = direction * SPEED
		var current_acceleration = ACCELERATION
		
		# Apply air control factor when not on ground
		if not is_on_floor():
			current_acceleration *= AIR_CONTROL
		
		velocity.x = move_toward(velocity.x, target_velocity.x, current_acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, current_acceleration * delta)
	else:
		# Decelerate to zero (also affected by air control)
		var current_deceleration = DECELERATION
		if not is_on_floor():
			current_deceleration *= AIR_CONTROL
		
		velocity.x = move_toward(velocity.x, 0, current_deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, current_deceleration * delta)

	move_and_slide() 