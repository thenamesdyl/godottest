extends Node3D

# Chunk constants
const CHUNK_SIZE = 50.0  # Size of each chunk in world units

# Chunk coordinates
var chunk_x: int = 0
var chunk_z: int = 0

# The seed for this chunk
var chunk_seed: int = 0

# References to nodes
@onready var terrain = $Terrain
@onready var water = $Water
@onready var objects = $Objects

# Called when the node enters the scene tree for the first time
func _ready():
	# Set up the chunk seed based on coordinates
	chunk_seed = hash(str(chunk_x) + "," + str(chunk_z))
	seed(chunk_seed)
	
	# Generate terrain
	generate_terrain()
	
	# Generate water
	generate_water()
	
	# Generate objects
	generate_objects()

# Generate the terrain mesh
func generate_terrain():
	# Create procedural terrain
	var noise = FastNoiseLite.new()
	noise.seed = chunk_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.01
	
	# For a boat game, create islands and underwater terrain
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	plane_mesh.subdivide_width = 20
	plane_mesh.subdivide_depth = 20
	
	# Add the mesh instance
	var terrain_mesh = MeshInstance3D.new()
	terrain_mesh.mesh = plane_mesh
	
	# Apply height deformation using MultiMesh
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(plane_mesh, 0)
	var mesh_data = surface_tool.commit()
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	
	# Get mesh arrays
	var arrays = mesh_data.surface_get_arrays(0)
	vertices = arrays[Mesh.ARRAY_VERTEX]
	normals = arrays[Mesh.ARRAY_NORMAL]
	
	# Apply noise to vertices
	for i in range(vertices.size()):
		var vertex = vertices[i]
		var noise_value = noise.get_noise_2d(vertex.x + position.x, vertex.z + position.z)
		
		# Make most of the terrain underwater for a boat game
		# Only create some islands
		if noise_value > 0.3:
			vertex.y = noise_value * 5.0 # Islands
		else:
			vertex.y = noise_value * 1.0 - 2.0 # Underwater terrain
			
		vertices[i] = vertex
	
	# Create mesh with modified vertices
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	# Recalculate normals
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.create_from_arrays(arrays)
	surface_tool.generate_normals()
	
	# Create properly triangulated collision shape
	var shape = ConcavePolygonShape3D.new()
	
	# We need to create triangles from the mesh
	var mesh_arrays = surface_tool.commit_to_arrays()
	var collision_vertices = mesh_arrays[Mesh.ARRAY_VERTEX]
	var indices = mesh_arrays[Mesh.ARRAY_INDEX] if mesh_arrays[Mesh.ARRAY_INDEX] != null else []
	
	var face_array = PackedVector3Array()
	
	# If we have indices, use them, otherwise use vertices directly
	if indices.size() > 0:
		for i in range(0, indices.size(), 3):
			if i + 2 < indices.size():
				face_array.append(collision_vertices[indices[i]])
				face_array.append(collision_vertices[indices[i+1]])
				face_array.append(collision_vertices[indices[i+2]])
	else:
		for i in range(0, collision_vertices.size(), 3):
			if i + 2 < collision_vertices.size():
				face_array.append(collision_vertices[i])
				face_array.append(collision_vertices[i+1])
				face_array.append(collision_vertices[i+2])
	
	# Set triangles for the collision shape
	shape.set_faces(face_array)
	
	# Create static body for collision
	var static_body = StaticBody3D.new()
	static_body.name = "TerrainCollision"
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = shape
	collision_shape.name = "CollisionShape"
	static_body.add_child(collision_shape)
	
	# Set the mesh on the mesh instance
	terrain_mesh.mesh = surface_tool.commit()
	
	# Apply a material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.35, 0.25, 0.15)
	terrain_mesh.set_surface_override_material(0, material)
	
	# Add the static body to the terrain
	terrain_mesh.add_child(static_body)
	
	# Add the terrain to the chunk
	terrain.add_child(terrain_mesh)

# Generate water for the chunk
func generate_water():
	# Create a simple water plane mesh
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	
	# Create water mesh instance
	var water_mesh = MeshInstance3D.new()
	water_mesh.mesh = plane_mesh
	water_mesh.position = Vector3(0, 0, 0) # Water level at y=0
	
	# Apply water material
	var water_material = StandardMaterial3D.new()
	water_material.albedo_color = Color(0.0, 0.4, 0.8, 0.7) # Blue, semi-transparent
	water_material.metallic = 0.5
	water_material.roughness = 0.2
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mesh.set_surface_override_material(0, water_material)
	
	# Add collision for the water surface (so we can stand on it)
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	
	# Use box shape for water collision (simpler and more efficient)
	var shape = BoxShape3D.new()
	shape.size = Vector3(CHUNK_SIZE, 0.1, CHUNK_SIZE) # Very thin box for water surface
	
	collision_shape.shape = shape
	static_body.add_child(collision_shape)
	water_mesh.add_child(static_body)
	
	# Add to water node
	water.add_child(water_mesh)

# Generate objects like trees, rocks, etc.
func generate_objects():
	# Set random seed based on chunk coordinates
	var object_seed = hash(str(chunk_x) + "," + str(chunk_z) + ",objects")
	seed(object_seed)
	
	# Get noise for object placement
	var noise = FastNoiseLite.new()
	noise.seed = object_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	
	# Place objects based on noise
	for i in range(10): # Try to place up to 10 objects
		var pos_x = randf_range(0, Globals.CHUNK_SIZE)
		var pos_z = randf_range(0, Globals.CHUNK_SIZE)
		
		var world_pos_x = pos_x + position.x
		var world_pos_z = pos_z + position.z
		
		var noise_value = noise.get_noise_2d(world_pos_x * 0.1, world_pos_z * 0.1)
		
		# Only place objects where terrain is above water (islands)
		if noise_value > 0.4:
			var height = noise.get_noise_2d(world_pos_x, world_pos_z)
			
			if height > 0.3: # On islands
				# Decide what object to place
				var object_type = randi() % 3
				
				if object_type == 0:
					place_tree(Vector3(pos_x, 0, pos_z))
				elif object_type == 1:
					place_rock(Vector3(pos_x, 0, pos_z))
				else:
					place_vegetation(Vector3(pos_x, 0, pos_z))

# Place a tree at the given position
func place_tree(pos: Vector3):
	# Create a simple tree using cylinders and spheres
	var tree = Node3D.new()
	
	# Tree trunk
	var trunk = CSGCylinder3D.new()
	trunk.radius = 0.3
	trunk.height = 3.0
	trunk.position.y = 1.5
	
	var trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.4, 0.25, 0.1)
	trunk.material = trunk_material
	
	# Tree top
	var top = CSGSphere3D.new()
	top.radius = 2.0
	top.position.y = 4.0
	
	var top_material = StandardMaterial3D.new()
	top_material.albedo_color = Color(0.2, 0.5, 0.2)
	top.material = top_material
	
	# Add to tree
	tree.add_child(trunk)
	tree.add_child(top)
	
	# Position the tree and add to objects
	tree.position = pos
	tree.position.y = get_height_at(pos) # Place on terrain
	objects.add_child(tree)

# Place a rock at the given position
func place_rock(pos: Vector3):
	# Create a simple rock using sphere
	var rock = CSGSphere3D.new()
	rock.radius = randf_range(0.5, 1.5)
	
	# Flatten the rock a bit
	rock.scale.y = 0.6
	
	var rock_material = StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.5, 0.5, 0.5)
	rock.material = rock_material
	
	# Position the rock and add to objects
	rock.position = pos
	rock.position.y = get_height_at(pos) - 0.3 # Partially buried
	objects.add_child(rock)

# Place vegetation at the given position
func place_vegetation(pos: Vector3):
	# Create simple vegetation using cone
	var vegetation = CSGCylinder3D.new()
	vegetation.radius = 0.5
	vegetation.height = 0.8
	vegetation.cone = true
	
	var veg_material = StandardMaterial3D.new()
	veg_material.albedo_color = Color(0.3, 0.6, 0.3)
	vegetation.material = veg_material
	
	# Position the vegetation and add to objects
	vegetation.position = pos
	vegetation.position.y = get_height_at(pos) + 0.4
	objects.add_child(vegetation)

# Get approximate height at a position within the chunk
func get_height_at(pos: Vector3) -> float:
	var noise = FastNoiseLite.new()
	noise.seed = chunk_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.01
	
	var world_pos_x = pos.x + position.x
	var world_pos_z = pos.z + position.z
	
	var noise_value = noise.get_noise_2d(world_pos_x, world_pos_z)
	
	# Same heightmap logic as in generate_terrain
	if noise_value > 0.3:
		return noise_value * 5.0 # Islands
	else:
		return noise_value * 1.0 - 2.0 # Underwater terrain
