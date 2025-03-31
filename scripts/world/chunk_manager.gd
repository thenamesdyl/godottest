extends Node3D

# Preload the chunk scene
var chunk_scene = preload("res://scenes/world/chunk.tscn")

# Dictionary to keep track of loaded chunks
var active_chunks = {}

# Reference to the player/boat
var player: Node3D

# Called when the node enters the scene tree for the first time
func _ready():
	player = get_node("../Player")
	if not player:
		push_error("ChunkManager: Cannot find Player node")
		return
	
	# Generate initial chunks around player
	update_chunks()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Only update chunks if player moves significantly
	update_chunks()

# Constants for chunk system (in case globals not accessible)
const CHUNK_SIZE = 50.0  # Size of each chunk in world units
const RENDER_DISTANCE = 2  # How many chunks to render in each direction from player
const UNLOAD_DISTANCE = 3  # How far chunks need to be to get unloaded

# Update which chunks should be active based on player position
func update_chunks():
	var player_chunk_x = floor(player.global_position.x / CHUNK_SIZE)
	var player_chunk_z = floor(player.global_position.z / CHUNK_SIZE)
	
	# Track which chunks we've updated this frame
	var updated_chunks = {}
	
	# Generate/Load chunks within render distance
	for x in range(player_chunk_x - RENDER_DISTANCE, player_chunk_x + RENDER_DISTANCE + 1):
		for z in range(player_chunk_z - RENDER_DISTANCE, player_chunk_z + RENDER_DISTANCE + 1):
			var chunk_key = str(x) + "," + str(z)
			updated_chunks[chunk_key] = true
			
			# If chunk doesn't exist, create it
			if not active_chunks.has(chunk_key):
				create_chunk(x, z, chunk_key)
	
	# Unload chunks that are too far away
	var chunks_to_remove = []
	for chunk_key in active_chunks:
		if not updated_chunks.has(chunk_key):
			var chunk_coords = chunk_key.split(",")
			var chunk_x = int(chunk_coords[0])
			var chunk_z = int(chunk_coords[1])
			
			# Check if chunk is outside unload distance
			if abs(chunk_x - player_chunk_x) > UNLOAD_DISTANCE or abs(chunk_z - player_chunk_z) > UNLOAD_DISTANCE:
				chunks_to_remove.append(chunk_key)
	
	# Remove chunks marked for removal
	for chunk_key in chunks_to_remove:
		unload_chunk(chunk_key)

# Create a new chunk at the specified coordinates
func create_chunk(x: int, z: int, chunk_key: String):
	var chunk_instance = chunk_scene.instantiate()
	chunk_instance.position = Vector3(x * CHUNK_SIZE, 0, z * CHUNK_SIZE)
	chunk_instance.chunk_x = x
	chunk_instance.chunk_z = z
	
	# Store reference to the chunk
	active_chunks[chunk_key] = chunk_instance
	
	# Add to scene tree
	add_child(chunk_instance)
	
	print("Created chunk at: ", x, ", ", z)

# Unload a chunk
func unload_chunk(chunk_key: String):
	if active_chunks.has(chunk_key):
		var chunk = active_chunks[chunk_key]
		chunk.queue_free()
		active_chunks.erase(chunk_key)
		
		print("Unloaded chunk: ", chunk_key)
