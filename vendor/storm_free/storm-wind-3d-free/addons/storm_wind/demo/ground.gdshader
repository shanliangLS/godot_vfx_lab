shader_type spatial;
// The demo's moor, laid by world position: patches of dark grass and bare earth.

uniform vec3 grass : source_color = vec3(0.16, 0.2, 0.11);
uniform vec3 earth : source_color = vec3(0.2, 0.16, 0.12);

varying vec3 world;

float hash(vec2 p) {
	uvec2 q = uvec2(ivec2(floor(p))) * uvec2(1597334673u, 3812015801u);
	return float((q.x ^ q.y) * 1597334673u) * (1.0 / 4294967295.0);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world.xz;
	float patch = noise(p * 0.3) * 0.65 + noise(p * 1.1) * 0.35;
	float tufts = noise(p * 9.0) * noise(p * 23.0);
	vec3 c = mix(earth, grass, smoothstep(0.35, 0.6, patch));
	ALBEDO = c * (0.75 + 0.6 * tufts);
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
