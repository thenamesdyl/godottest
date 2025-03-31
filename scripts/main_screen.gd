extends Node3D

@onready var player = $Player
@onready var chunk_manager = $ChunkManager

func _ready():
	print("Main scene loaded")
	
	# Set player to start at a good position above water (high enough not to fall through)
	player.position = Vector3(0, 15, 0)
	
	# Ensure chunk is generated before player lands
	await get_tree().create_timer(0.1).timeout
	chunk_manager.update_chunks()
func _process(_delta):
	# Process function for any future updates we might need
	pass 
