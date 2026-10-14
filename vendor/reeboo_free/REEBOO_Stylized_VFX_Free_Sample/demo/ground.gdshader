// Demo stage floor: dark slate with a faint 1 m grid that fades out with distance.
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.065, 0.07, 0.085);
uniform vec3 line_color : source_color = vec3(0.13, 0.14, 0.17);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 grid = abs(fract(world_pos.xz - 0.5) - 0.5) / fwidth(world_pos.xz);
	float line = 1.0 - min(min(grid.x, grid.y), 1.0);
	float fade = 1.0 - smoothstep(5.0, 20.0, length(world_pos.xz));
	ALBEDO = mix(base_color, line_color, line * fade * 0.8);
	ROUGHNESS = 0.55;
	SPECULAR = 0.35;
}
