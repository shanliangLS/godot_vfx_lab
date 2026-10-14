shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.2, 0.9, 1.0, 1.0);
uniform float intensity = 1.2;

void fragment() {
	float fade = UV.y;
	float fres = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.5);
	ALBEDO = tint.rgb * intensity * fade * (0.15 + fres * 0.6);
	ALPHA = 1.0;
}
