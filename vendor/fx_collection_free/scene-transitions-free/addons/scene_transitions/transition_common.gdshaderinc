// Shared helpers for the Scene Transitions shaders.

const float TR_TAU = 6.2831853;

float tr_hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float tr_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(tr_hash(i), tr_hash(i + vec2(1.0, 0.0)), u.x),
			mix(tr_hash(i + vec2(0.0, 1.0)), tr_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// 0..1, spread to cover the range.
float tr_fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * tr_noise(p);
		p = p * 2.03 + 17.0;
		a *= 0.5;
	}
	return clamp((v - 0.15) / 0.7, 0.0, 1.0);
}

// Ordered-dither thresholds in [0, 1).
float tr_bayer2(vec2 a) {
	a = floor(a);
	return fract(dot(a, vec2(0.5, a.y * 0.75)));
}
float tr_bayer4(vec2 a) { return tr_bayer2(0.5 * a) * 0.25 + tr_bayer2(a); }
float tr_bayer8(vec2 a) { return tr_bayer4(0.5 * a) * 0.25 + tr_bayer2(a); }

// Hex grid of unit width: xy = offset from the cell centre, zw = cell id.
vec4 tr_hex(vec2 p) {
	const vec2 s = vec2(1.0, 1.7320508);
	vec4 hc = floor(vec4(p, p - vec2(0.5, 0.866)) / s.xyxy) + 0.5;
	vec4 h = vec4(p - hc.xy * s, p - (hc.zw + 0.5) * s);
	return dot(h.xy, h.xy) < dot(h.zw, h.zw) ? vec4(h.xy, hc.xy) : vec4(h.zw, hc.zw + 0.5);
}

// 0 at a hex centre, 0.5 on its edges.
float tr_hex_dist(vec2 p) {
	p = abs(p);
	return max(dot(p, vec2(0.5, 0.8660254)), p.x);
}
