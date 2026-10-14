// Retro post-processing of whatever is drawn under the rect: CRT and VHS. The full pack, Retro Screen FX,
// adds palettes, colour levels, dithering and an LCD grid.
// Every effect is off at its default, so a preset only sets what it uses.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform sampler2D screen_nearest : hint_screen_texture, filter_nearest;

group_uniforms pixels;
// Size of one retro pixel, in screen pixels.
uniform float pixel_size : hint_range(1.0, 16.0, 1.0) = 1.0;

group_uniforms color;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float contrast : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform vec4 tint : source_color = vec4(1.0);

group_uniforms crt;
uniform float curvature : hint_range(0.0, 0.5) = 0.0;
uniform float corner_radius : hint_range(0.0, 0.2) = 0.0;
uniform float scanlines : hint_range(0.0, 1.0) = 0.0;
uniform float scanline_count : hint_range(60.0, 1080.0) = 240.0;
// RGB aperture-grille stripes.
uniform float mask : hint_range(0.0, 1.0) = 0.0;
uniform float mask_size : hint_range(1.0, 8.0, 1.0) = 3.0;
uniform float glow : hint_range(0.0, 1.0) = 0.0;
// Red/blue split, in screen pixels.
uniform float chromatic : hint_range(0.0, 8.0) = 0.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.0;

group_uniforms vhs;
// Per-line horizontal wobble.
uniform float jitter : hint_range(0.0, 1.0) = 0.0;
// Colour smeared to the right, as on tape.
uniform float color_bleed : hint_range(0.0, 1.0) = 0.0;
// A rolling band of distortion.
uniform float tracking : hint_range(0.0, 1.0) = 0.0;
uniform float noise : hint_range(0.0, 1.0) = 0.0;

group_uniforms compare;
// Left of this (in UV) stays untouched, for before/after shots.
uniform float split : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec3 grab(vec2 screen_uv, bool nearest) {
	return nearest ? textureLod(screen_nearest, screen_uv, 0.0).rgb : textureLod(screen, screen_uv, 0.0).rgb;
}

void fragment() {
	vec2 px = vec2(abs(dFdx(UV.x)), abs(dFdy(UV.y)));
	// Rect UV offsets -> screen UV offsets, so the effect also works on a rect smaller than the screen.
	vec2 to_screen = SCREEN_PIXEL_SIZE / px;
	vec3 col;

	if (UV.x < split) {
		col = grab(SCREEN_UV, false);
	} else {
		vec2 c = UV * 2.0 - 1.0;
		c += c * (c.yx * c.yx) * curvature;
		vec2 uv = c * 0.5 + 0.5;
		float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);

		float line = floor(uv.y * scanline_count);
		float frame = floor(TIME * 30.0);
		uv.x += (hash(vec2(line, frame)) - 0.5) * jitter * 0.006 + sin(uv.y * 30.0 + TIME * 4.0) * jitter * 0.002;
		float band = uv.y - fract(TIME * 0.12) * 1.3 + 0.15;
		float in_band = smoothstep(0.08, 0.0, abs(band));
		uv.x += in_band * tracking * (hash(vec2(line, frame + 7.0)) - 0.3) * 0.03;

		vec2 cell = px * pixel_size;
		vec2 puv = pixel_size > 1.0 ? (floor(uv / cell) + 0.5) * cell : uv;
		bool nearest = pixel_size > 1.0;
		vec2 s = SCREEN_UV + (puv - UV) * to_screen;
		vec2 ca = vec2(chromatic, 0.0) * SCREEN_PIXEL_SIZE;
		col = vec3(grab(s + ca, nearest).r, grab(s, nearest).g, grab(s - ca, nearest).b);

		if (color_bleed > 0.0) {
			vec3 smear = vec3(0.0);
			for (int i = 1; i <= 6; i++) {
				smear += grab(s - vec2(float(i) * color_bleed * 3.0, 0.0) * SCREEN_PIXEL_SIZE, nearest);
			}
			smear /= 6.0;
			float y = dot(col, vec3(0.299, 0.587, 0.114));
			col = y + (smear - dot(smear, vec3(0.299, 0.587, 0.114)));
		}
		if (glow > 0.0) {
			vec3 blur = vec3(0.0);
			for (int i = 0; i < 8; i++) {
				float a = float(i) * 0.785398;
				blur += grab(s + vec2(cos(a), sin(a)) * 6.0 * SCREEN_PIXEL_SIZE, false);
				blur += grab(s + vec2(cos(a + 0.39), sin(a + 0.39)) * 14.0 * SCREEN_PIXEL_SIZE, false);
			}
			col += max(blur / 16.0 - 0.55, 0.0) * glow * 2.0;
		}
		col += in_band * tracking * hash(uv * 400.0 + frame) * 0.25;

		col = (col - 0.5) * contrast + 0.5;
		col *= brightness;
		col = mix(vec3(dot(col, vec3(0.299, 0.587, 0.114))), col, saturation);
		col *= tint.rgb;

		float sl = 0.5 + 0.5 * cos(uv.y * scanline_count * 6.2831853);
		col *= (1.0 - scanlines * (1.0 - sl) * 0.75) * (1.0 + scanlines * 0.3);
		float stripe = mod(floor(UV.x / px.x / mask_size), 3.0);
		vec3 m = vec3(float(stripe == 0.0), float(stripe == 1.0), float(stripe == 2.0));
		col *= mix(vec3(1.0), m * 2.1 + 0.3, mask * 0.45);
		col += (hash(UV / px + fract(TIME) * 91.0) - 0.5) * noise * 0.3;
		vec2 v = uv * (1.0 - uv);
		col *= mix(1.0, pow(clamp(16.0 * v.x * v.y, 0.0, 1.0), 0.35), vignette);

		vec2 q = abs(c) - (1.0 - corner_radius * 2.0);
		float corner = length(max(q, 0.0)) - corner_radius * 2.0;
		inside *= corner_radius > 0.0 ? smoothstep(px.x * 3.0, 0.0, corner) : 1.0;
		col *= inside;
	}
	COLOR = vec4(col, 1.0);
}
