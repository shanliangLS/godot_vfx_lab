shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 color_a : source_color = vec4(0.55, 0.1, 1.0, 1.0);
uniform vec4 color_b : source_color = vec4(0.1, 0.85, 1.0, 1.0);
uniform float intensity = 3.0;
uniform float speed = 0.35;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x) / 6.28318;
	float sw = a + r * 0.9 - TIME * speed;
	float n = texture(noise_tex, vec2(sw, r * 0.6 - TIME * 0.3)).r;
	float n2 = texture(noise_tex, vec2(sw * 2.0 + 0.3, r - TIME * 0.5)).r;
	float mask = smoothstep(1.0, 0.82, r);
	float core = smoothstep(0.65, 0.0, r);
	vec3 col = mix(color_a.rgb, color_b.rgb, n2) * (n * 1.6 + core * 0.9);
	ALBEDO = col * intensity * mask;
	ALPHA = mask * (0.6 + 0.4 * n);
}
