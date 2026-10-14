// Demo ground: grass, a road and puddles that get darker and glossier with wetness.
shader_type spatial;

uniform float wetness : hint_range(0.0, 1.0) = 0.0;
// Compatibility has no sky reflections; the demo adds this much sky light instead.
uniform vec3 compat_sheen = vec3(0.0);
uniform float snow_cover : hint_range(0.0, 1.0) = 0.0;
uniform float road_half_width = 2.2;

varying vec3 v_world;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += noise(p) * a;
		p *= 2.1;
		a *= 0.5;
	}
	return s;
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = v_world.xz;
	float n = fbm(p * 0.35);
	float fine = noise(p * 6.0);
	vec3 grass = mix(vec3(0.16, 0.24, 0.1), vec3(0.27, 0.33, 0.15), n) * (0.85 + 0.3 * fine);
	vec3 dirt = vec3(0.24, 0.2, 0.15) * (0.8 + 0.4 * fine);
	grass = mix(grass, dirt, smoothstep(0.62, 0.75, fbm(p * 0.12 + 7.0)));
	float road_edge = abs(p.x) + (noise(p * 1.7) - 0.5) * 0.25;
	float road = 1.0 - smoothstep(road_half_width - 0.15, road_half_width + 0.15, road_edge);
	vec3 asphalt = vec3(0.1, 0.1, 0.11) * (0.85 + 0.3 * fine + 0.2 * n);
	float stripe = (1.0 - smoothstep(0.05, 0.08, abs(p.x))) * step(0.5, fract(p.y * 0.25));
	asphalt = mix(asphalt, vec3(0.55, 0.52, 0.42), stripe * 0.8);
	vec3 col = mix(grass, asphalt, road);
	float puddle = smoothstep(0.55, 0.62, fbm(p * 0.45 + 3.0)) * road;
	float wet = wetness * (0.6 + 0.4 * puddle);
	col *= mix(1.0, 0.55, wet);
	float rough = mix(mix(0.95, 0.7, road), mix(mix(0.7, 0.22, road), 0.04, puddle), wetness);
	float cover = smoothstep(0.35, 0.6, snow_cover + (n - 0.5) * 0.5 + fine * 0.15) * snow_cover;
	col = mix(col, vec3(0.86, 0.88, 0.92), cover);
	rough = mix(rough, 0.8, cover);
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = mix(0.3, 0.6, wetness * road);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	EMISSION = compat_sheen * (1.0 - cover * 0.7) * (1.0 - wet * 0.5);
#endif
}
