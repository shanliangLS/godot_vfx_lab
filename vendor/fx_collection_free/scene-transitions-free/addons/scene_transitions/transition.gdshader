// Covers the rect with `color` as `progress` goes 0 -> 1, in the pattern picked by `style`.
// Every pixel gets a threshold v in 0..1 and is covered once progress passes it.
shader_type canvas_item;
render_mode unshaded;

#include "transition_common.gdshaderinc"

uniform float progress : hint_range(0.0, 1.0) = 0.0;
// 0 fade, 1 dither, 2 wipe, 3 diamonds, 4 circles, 5 iris, 6 clock, 7 blinds, 8 checker, 9 noise,
// 10 spiral, 11 curtain, 12 zigzag, 13 shards, 14 bars, 15 hexagons, 16 tiles, 17 mask, 18 triangles,
// 19 waves, 20 rays, 21 box, 22 interlace, 23 rings, 24 bubbles, 25 pinwheel
uniform int style : hint_range(0, 25) = 0;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float softness : hint_range(0.0, 0.5) = 0.04;
// Direction of travel in degrees, 0 = left to right.
uniform float angle : hint_range(-180.0, 180.0) = 0.0;
// Pattern cells across the rect's height.
uniform float cells : hint_range(1.0, 64.0) = 10.0;
// Where iris, clock, spiral, rays, box, rings and pinwheel close to, in UV.
uniform vec2 center = vec2(0.5);
// Runs the pattern backwards: iris opens, curtain splits, wipe starts at the other side.
uniform bool flip = false;
// Snap the pattern to blocks of this many screen pixels, for pixel-art games. 0 = smooth.
uniform float pixel_size : hint_range(0.0, 32.0, 1.0) = 0.0;
uniform float seed = 0.0;
// Greyscale rule image for the Mask style: black covers first, white last.
uniform sampler2D mask : hint_default_white, filter_linear;

float sweep(vec2 q, vec2 dir, float aspect) {
	float extent = 0.5 * (abs(dir.x) * aspect + abs(dir.y));
	return clamp(dot(q, dir) / extent * 0.5 + 0.5, 0.0, 1.0);
}

void fragment() {
	vec2 px = vec2(abs(dFdx(UV.x)), abs(dFdy(UV.y)));
	float aspect = px.y / px.x;
	vec2 uv = UV;
	if (pixel_size >= 1.0) {
		vec2 b = px * pixel_size;
		uv = (floor(uv / b) + 0.5) * b;
	}
	vec2 q = (uv - 0.5) * vec2(aspect, 1.0);
	float a = radians(angle);
	vec2 dir = vec2(cos(a), sin(a));
	vec2 perp = vec2(-dir.y, dir.x);
	vec2 d = q - (center - 0.5) * vec2(aspect, 1.0);
	float v = 0.0;

	if (style == 1) {  // dither
		float dot_px = max(pixel_size, 1.0 / (px.y * cells * 8.0));
		v = tr_bayer8(uv / (px * dot_px)) + 1.0 / 128.0;
	} else if (style == 2) {  // wipe
		v = sweep(q, dir, aspect);
	} else if (style == 3 || style == 4) {  // diamonds, circles
		vec2 g = q * cells;
		vec2 id = floor(g) + 0.5;
		vec2 f = g - id;
		float local = style == 3 ? abs(f.x) + abs(f.y) : length(f) * 1.4142;
		v = sweep(id / cells, dir, aspect) * 0.5 + local * 0.5;
	} else if (style == 5) {  // iris
		vec2 c = (center - 0.5) * vec2(aspect, 1.0);
		vec2 far = max(abs(vec2(-0.5 * aspect, -0.5) - c), abs(vec2(0.5 * aspect, 0.5) - c));
		v = 1.0 - length(d) / length(far);
	} else if (style == 17) {  // mask
		v = texture(mask, uv).r;
	}
	if (flip) {
		v = 1.0 - v;
	}

	float s = max(softness, 0.001);
	float amount = style == 0 ? progress : smoothstep(v, v + s, progress * (1.0 + s));
	COLOR = vec4(color.rgb, color.a * amount);
}
