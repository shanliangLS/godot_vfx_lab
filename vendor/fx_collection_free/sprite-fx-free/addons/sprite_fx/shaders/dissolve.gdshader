// Noise dissolve with a glowing edge. progress 0 = whole, 1 = gone.
shader_type canvas_item;
#include "fx_common.gdshaderinc"
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_scale : hint_range(1.0, 64.0) = 10.0;
uniform float edge_width : hint_range(0.0, 0.3) = 0.08;
uniform vec4 edge_color : source_color = vec4(1.0, 0.55, 0.1, 1.0);
uniform float edge_intensity : hint_range(1.0, 4.0) = 1.5;
// Blends a straight sweep into the noise; direction is in UV space, (0, -1) sweeps bottom to top.
uniform vec2 direction = vec2(0.0, -1.0);
uniform float direction_mix : hint_range(0.0, 1.0) = 0.0;
// Snaps the noise to texture pixels so pixel art stays crisp.
uniform bool pixel_snap = true;
uniform float seed = 0.0;
varying vec4 v_color;
void vertex() { v_color = COLOR; }

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 uv = pixel_snap ? (floor(UV / TEXTURE_PIXEL_SIZE) + 0.5) * TEXTURE_PIXEL_SIZE : UV;
	float n = fx_fbm(uv * noise_scale + seed * 31.7);
	if (direction_mix > 0.0 && length(direction) > 0.0) {
		float g = dot(uv - 0.5, normalize(direction)) + 0.5;
		n = mix(n, g, direction_mix);
	}
	float t = mix(-edge_width, 1.0, progress);
	float gone = step(n, t);
	float edge = (1.0 - gone) * step(n, t + edge_width) * step(0.001, progress);
	vec3 rgb = mix(tex.rgb, edge_color.rgb * edge_intensity, edge);
	COLOR = vec4(rgb, tex.a * (1.0 - gone)) * v_color;
}
