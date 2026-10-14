shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.2, 0.9, 1.0, 1.0);
uniform float intensity = 2.5;
uniform float line_density = 40.0;
uniform float scroll = 1.2;
uniform float glitch = 0.04;
varying vec3 wpos;

float hash(float x) { return fract(sin(x) * 43758.5453); }

void vertex() {
	float g = step(0.97, hash(floor(TIME * 12.0) + floor(VERTEX.y * 10.0)));
	VERTEX.x += g * glitch;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float fres = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.0);
	float lines = step(0.5, fract(wpos.y * line_density - TIME * scroll));
	float flick = 1.0 - 0.4 * step(0.93, hash(floor(TIME * 9.0)));
	ALBEDO = tint.rgb * intensity * (0.2 + fres * 1.3) * (0.55 + 0.45 * lines) * flick;
	ALPHA = 1.0;
}
