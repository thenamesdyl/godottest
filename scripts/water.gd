extends MeshInstance3D

@onready var shader_material = get_surface_override_material(0)

func _ready():
	# Create the water mesh if it doesn't exist
	if mesh == null:
		var plane_mesh = PlaneMesh.new()
		plane_mesh.size = Vector2(100, 100)  # Match ground size
		plane_mesh.subdivide_width = 32
		plane_mesh.subdivide_depth = 32
		mesh = plane_mesh
	
	# Create shader material if it doesn't exist
	if shader_material == null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = preload("res://shaders/water.gdshader")
		set_surface_override_material(0, shader_material)

func _process(delta):
	# Update shader time for wave animation
	if shader_material:
		var time = Time.get_ticks_msec() / 1000.0
		shader_material.set_shader_parameter("TIME", time) 