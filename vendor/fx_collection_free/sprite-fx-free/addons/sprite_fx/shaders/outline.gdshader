// Pixel-perfect outline, around the sprite or on its own edge pixels.
shader_type canvas_item;
#include "fx_common.gdshaderinc"
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float width : hint_range(0.0, 16.0, 1.0) = 1.0;
uniform bool diagonals = true;
// Draw on the sprite's own edge pixels instead of around it.
uniform bool inside = false;
// Enlarges the quad so the outline fits sprites without transparent padding.
// Single textures only: leave at 0 for atlas regions and sprite-sheet frames.
uniform float grow : hint_range(0.0, 16.0, 1.0) = 0.0;
varying vec4 v_color;

void vertex() {
	v_color = COLOR;
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	VERTEX += (UV * 2.0 - 1.0) * grow;
	UV = (UV - 0.5) * (size + 2.0 * grow) / size + 0.5;
}

#define ALPHA_AT(uv) (texture(TEXTURE, uv).a * fx_in01(uv))

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * fx_in01(UV);
	float near_max = 0.0;
	float near_min = 1.0;
	for (float i = 1.0; i <= width; i += 1.0) {
		vec2 px = TEXTURE_PIXEL_SIZE * i;
		float a0 = ALPHA_AT(UV + vec2(px.x, 0.0));
		float a1 = ALPHA_AT(UV - vec2(px.x, 0.0));
		float a2 = ALPHA_AT(UV + vec2(0.0, px.y));
		float a3 = ALPHA_AT(UV - vec2(0.0, px.y));
		near_max = max(near_max, max(max(a0, a1), max(a2, a3)));
		near_min = min(near_min, min(min(a0, a1), min(a2, a3)));
		if (diagonals) {
			float d0 = ALPHA_AT(UV + px);
			float d1 = ALPHA_AT(UV - px);
			float d2 = ALPHA_AT(UV + vec2(px.x, -px.y));
			float d3 = ALPHA_AT(UV + vec2(-px.x, px.y));
			near_max = max(near_max, max(max(d0, d1), max(d2, d3)));
			near_min = min(near_min, min(min(d0, d1), min(d2, d3)));
		}
	}
	vec4 result;
	if (inside) {
		float edge = step(0.5, tex.a) * step(near_min, 0.5);
		result = vec4(mix(tex.rgb, outline_color.rgb, edge * outline_color.a), tex.a);
	} else {
		result = fx_over(tex, vec4(outline_color.rgb, near_max * outline_color.a));
	}
	COLOR = result * v_color;
}
