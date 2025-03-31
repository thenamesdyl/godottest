shader_type spatial;

uniform vec4 water_color : source_color = vec4(0.0, 0.4, 0.6, 0.8);
uniform vec4 deep_water_color : source_color = vec4(0.0, 0.2, 0.4, 0.9);
uniform float wave_speed = 0.5;
uniform float wave_strength = 0.2;
uniform float wave_frequency = 8.0;
uniform float time_factor = 1.0;
uniform float fresnel_power = 3.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0.7;

varying vec3 vertex_pos;

void vertex() {
	vertex_pos = VERTEX;
	
	// Create wave movement
	float wave_x = sin(VERTEX.x * wave_frequency + TIME * wave_speed) * wave_strength;
	float wave_z = sin(VERTEX.z * wave_frequency + TIME * wave_speed) * wave_strength;
	VERTEX.y += wave_x + wave_z;
	
	// Adjust normals for lighting
	NORMAL = normalize(vec3(wave_x, 1.0, wave_z));
}

void fragment() {
	// Fresnel effect for water edge transparency
	float fresnel = pow(1.0 - dot(normalize(VIEW), NORMAL), fresnel_power);
	
	// Mix between shallow and deep water colors based on depth and fresnel
	vec4 water = mix(water_color, deep_water_color, fresnel);
	
	// Apply final color and properties
	ALBEDO = water.rgb;
	ALPHA = water.a;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	
	// Add specular reflection
	SPECULAR = 0.5;
} 