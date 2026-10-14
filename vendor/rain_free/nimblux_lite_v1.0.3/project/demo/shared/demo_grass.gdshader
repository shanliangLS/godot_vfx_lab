// Demo grass that bends with the shared NIMBLUX wind (set by demo_stage.gd every frame).
// The same idea works for any foliage: read NimbluxWeatherState.wind and pass it in.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;

uniform vec3 wind = vec3(0.0);
uniform float time = 0.0;
uniform vec3 base_color : source_color = vec3(0.2, 0.3, 0.12);
uniform vec3 tip_color : source_color = vec3(0.45, 0.52, 0.24);
// Compatibility has no sky reflections; the demo adds this much sky light instead.
uniform vec3 compat_sheen = vec3(0.0);
uniform float snow_cover = 0.0;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = UV.y;
	float bend = h * h;
	float strength = length(wind);
	vec2 dir = strength > 0.01 ? wind.xz / strength : vec2(1.0, 0.0);
	float wave = sin(time * (1.6 + strength * 0.25) + dot(world.xz, dir) * 0.8) * 0.5 + 0.5;
	float flutter = sin(time * 7.0 + world.x * 3.1 + world.z * 2.3) * 0.04;
	float push = min(strength * 0.045, 0.6) * (0.55 + 0.45 * wave) + 0.03;
	vec3 offset_world = vec3(dir.x, 0.0, dir.y) * push * bend + vec3(flutter, 0.0, flutter * 0.6) * bend;
	VERTEX += (inverse(MODEL_MATRIX) * vec4(offset_world, 0.0)).xyz;
	VERTEX.y -= push * bend * 0.35;
}

void fragment() {
	vec2 c = vec2(UV.x * 2.0 - 1.0, UV.y);
	float blade = 1.0 - smoothstep(0.0, 0.9 - UV.y * 0.85, abs(c.x));
	if (blade < 0.5) {
		discard;
	}
	vec3 col = mix(base_color, tip_color, UV.y);
	col = mix(col, vec3(0.85, 0.88, 0.92), snow_cover * smoothstep(0.4, 1.0, UV.y));
	ALBEDO = col;
	ROUGHNESS = 0.85;
	BACKLIGHT = vec3(0.15, 0.2, 0.05);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	EMISSION = compat_sheen * 0.8;
#endif
}
