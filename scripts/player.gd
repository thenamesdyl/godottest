extends CharacterBody3D

# Movement parameters
const SPEED = 10.0
const ACCELERATION = 15.0
const DECELERATION = 20.0
const JUMP_VELOCITY = 6.0
const MOUSE_SENSITIVITY = 0.002

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

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

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Small adjustment to keep the player grounded
		velocity.y = -0.1

	# Handle jump with a slightly higher jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		print("Jumping!")
		velocity.y = JUMP_VELOCITY

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
		# Accelerate towards target velocity
		var target_velocity = direction * SPEED
		velocity.x = move_toward(velocity.x, target_velocity.x, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, ACCELERATION * delta)
		print("Current velocity: ", velocity)
	else:
		# Decelerate to zero
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)

	move_and_slide() 