// Demo floor: dark tiles with a faint grid so lights and flashes read well.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.045, 0.05, 0.06);
uniform vec3 line_color : source_color = vec3(0.11, 0.13, 0.17);
uniform float tile_size = 2.0;
uniform float line_width = 0.025;

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 g = v_world.xz / tile_size;
	vec2 f = abs(fract(g) - 0.5);
	float edge = max(f.x, f.y);
	float fw = fwidth(edge) + 1e-4;
	float line = smoothstep(0.5 - line_width - fw, 0.5 - line_width, edge);
	vec2 cell = floor(g);
	float tint = fract(sin(dot(cell, vec2(12.71, 31.13))) * 9137.31) * 0.25;
	ALBEDO = mix(base_color * (0.85 + tint), line_color, line);
	ROUGHNESS = mix(0.32, 0.6, line);
	SPECULAR = 0.5;
}
