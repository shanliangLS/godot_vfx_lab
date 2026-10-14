shader_type spatial;
render_mode unshaded;
uniform vec4 base_color : source_color = vec4(0.027, 0.038, 0.059, 1.0);
void fragment() {
	vec2 p = UV * 24.0;
	vec2 edge = abs(fract(p - 0.5) - 0.5) / max(fwidth(p), vec2(0.001));
	float line = 1.0 - min(min(edge.x, edge.y), 1.0);
	float fade = 1.0 - smoothstep(4.0, 12.0, length(p - 12.0));
	ALBEDO = base_color.rgb + vec3(0.07, 0.10, 0.14) * line * fade;
}
