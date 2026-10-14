// Shared helpers for the Sprite FX shaders.

float fx_hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float fx_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(fx_hash(i), fx_hash(i + vec2(1.0, 0.0)), u.x),
			mix(fx_hash(i + vec2(0.0, 1.0)), fx_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// 0..1, spread to cover the range.
float fx_fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * fx_noise(p);
		p = p * 2.03 + 17.0;
		a *= 0.5;
	}
	return clamp((v - 0.12) / 0.76, 0.0, 1.0);
}

float fx_luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 fx_hue_shift(vec3 c, float turns) {
	float a = turns * 6.2831853;
	vec3 k = vec3(0.57735);
	float ca = cos(a);
	return c * ca + cross(k, c) * sin(a) + k * dot(k, c) * (1.0 - ca);
}

// Ordered-dither thresholds in [0, 1).
float fx_bayer2(vec2 a) {
	a = floor(a);
	return fract(dot(a, vec2(0.5, a.y * 0.75)));
}
float fx_bayer4(vec2 a) { return fx_bayer2(0.5 * a) * 0.25 + fx_bayer2(a); }
float fx_bayer8(vec2 a) { return fx_bayer4(0.5 * a) * 0.25 + fx_bayer2(a); }

// 1 inside the 0..1 UV square, 0 outside: stops clamped edge pixels from smearing.
float fx_in01(vec2 uv) {
	return step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
}

// "a over b" for straight alpha.
vec4 fx_over(vec4 a, vec4 b) {
	float o = a.a + b.a * (1.0 - a.a);
	vec3 rgb = o > 0.0 ? (a.rgb * a.a + b.rgb * b.a * (1.0 - a.a)) / o : vec3(0.0);
	return vec4(rgb, o);
}
