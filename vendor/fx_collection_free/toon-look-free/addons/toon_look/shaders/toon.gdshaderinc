// The toon look shared by every toon_*.gdshader: each light in hard bands (or along a ramp) over a
// flat shade colour, a hard-edged highlight, a rim, and waves. The including shader sets
// render_mode (ambient_light_disabled: the shade is shadow_color, not the sky's light), and may
// #define TOON_HATCH, TOON_HALFTONE, TOON_CUTOUT, TOON_TRANSPARENT or TOON_WATER.

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);
uniform bool vertex_colors = false;
// What the albedo is multiplied by where no light reaches. A tinted one (blue, purple) reads cartoony.
uniform vec4 shadow_color : source_color = vec4(0.56, 0.5, 0.7, 1.0);
// Lit steps above the shade: 1 is two-tone cel, 3 or 4 a posterised gradient.
uniform int bands : hint_range(1, 8) = 1;
// 0 hard edges between the bands, 1 a smooth gradient.
uniform float band_softness : hint_range(0.0, 1.0) = 0.06;
// Where the light gives way to shade, as the cosine of the angle to the light: raise it to shrink
// the lit side.
uniform float band_threshold : hint_range(-1.0, 0.95) = 0.0;
// Read left (the shade's side) to right (full light) in place of the bands: any colours between.
uniform sampler2D ramp : source_color, filter_linear, repeat_disable, hint_default_white;
uniform bool use_ramp = false;
uniform float specular : hint_range(0.0, 1.0) = 0.0;
uniform float glossiness : hint_range(1.0, 256.0) = 32.0;
uniform float rim : hint_range(0.0, 1.0) = 0.0;
uniform vec4 rim_color : source_color = vec4(1.0);
// How far in from the silhouette the rim reaches.
uniform float rim_width : hint_range(0.0, 1.0) = 0.3;
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// Vertices ride a wave along their normals: water, flags, foliage. Height and length in metres,
// speed in waves a second; pinned holds the texture's top edge (1: a banner) or its foot (2: grass) still.
uniform float wave_height = 0.0;
uniform float wave_length = 3.0;
uniform float wave_speed = 0.5;
uniform int wave_pinned : hint_range(0, 2) = 0;
#if defined(TOON_HATCH) || defined(TOON_HALFTONE)
// The shade drawn in lines or dots fixed to the screen, this many pixels apart on a 1080-line
// screen (the same share of any other).
uniform float pattern_size : hint_range(2.0, 64.0) = 8.0;
uniform float pattern_angle : hint_range(0.0, 180.0) = 45.0;
#endif
#ifdef TOON_CUTOUT
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;
#endif
#ifdef TOON_WATER
// Foam along the edges of drifting cells, drawn over the albedo.
uniform vec4 foam_color : source_color = vec4(1.0);
uniform float foam : hint_range(0.0, 1.0) = 0.8;
uniform float foam_width : hint_range(0.0, 0.5) = 0.08;
// Cells a metre.
uniform float foam_scale = 0.6;
// The foam's drift, metres a second.
uniform vec2 flow = vec2(0.15, 0.08);
varying vec2 toon_world;
#endif

void vertex() {
	if (wave_height != 0.0) {
		vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float phase = dot(w, vec3(0.8, 0.5, 0.6)) * TAU / max(wave_length, 0.01) + TIME * TAU * wave_speed;
		float lift = 0.65 * sin(phase) + 0.35 * sin(phase * 1.7 + w.x - w.z);
		float pin = wave_pinned == 1 ? clamp(UV.y, 0.0, 1.0) : (wave_pinned == 2 ? clamp(1.0 - UV.y, 0.0, 1.0) : 1.0);
		VERTEX += NORMAL * wave_height * lift * pin;
	}
	UV = UV * uv_scale + uv_offset;
#ifdef TOON_WATER
	toon_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
#endif
}

#ifdef TOON_WATER
vec2 toon_hash(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

// How far p is from the nearest edge between two cells whose centres wander with time.
float toon_cell_edge(vec2 p, float t) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = 0.5 + 0.4 * sin(t + TAU * toon_hash(i + g));
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return d2 - d1;
}
#endif

void fragment() {
	vec4 c = albedo * texture(albedo_texture, UV);
	if (vertex_colors) {
		c *= COLOR;
	}
#ifdef TOON_WATER
	vec2 p = (toon_world - flow * TIME) * foam_scale;
	float edge = toon_cell_edge(p, TIME * 0.6);
	float f = (1.0 - smoothstep(foam_width, foam_width + 0.03, edge)) * foam;
	c = mix(c, vec4(foam_color.rgb, 1.0), f * foam_color.a);
#endif
	ALBEDO = c.rgb;
	float facing = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float r = smoothstep(1.0 - rim_width, 1.0 - rim_width + 0.04 + band_softness * 0.2, facing) * rim;
	EMISSION = c.rgb * shadow_color.rgb + rim_color.rgb * r + emission.rgb;
#ifdef TOON_CUTOUT
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
#endif
#if defined(TOON_TRANSPARENT) || defined(TOON_WATER)
	ALPHA = c.a;
#endif
	METALLIC = 0.0;
	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
}

// `d` light (0 shade, 1 full) in `bands` steps, each edge softened by band_softness.
float toon_steps(float d) {
	float n = float(bands);
	float f = d * n;
	return clamp((floor(f) + smoothstep(0.0, max(band_softness, 0.001), fract(f))) / n, 0.0, 1.0);
}

// A light's attenuation cut to on or off at a crisp edge, a pixel wide: the sun's shadows fall
// hard, and a lamp lights a pool nearly as wide as its range.
float toon_cut(float a, bool directional) {
	float at = directional ? 0.5 : 0.03;
	float w = max(fwidth(a), 0.0005);
	return smoothstep(at - w, at + w, a);
}

#if defined(TOON_HATCH) || defined(TOON_HALFTONE)
// 1 where the paper shows through the strokes or dots for `d` light, 0 on them.
float toon_pattern(float d, vec2 frag, vec2 viewport) {
	float px = 1080.0 / viewport.y / pattern_size;  // one screen pixel in pattern cells
	float a = radians(pattern_angle);
	vec2 p = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * (frag * px);
	float aa = px * 0.75;
#ifdef TOON_HATCH
	// Lines that thicken as the light falls, crossed by a second set in the dark.
	float w1 = clamp(1.0 - d / 0.75, 0.0, 1.0);
	float w2 = clamp(1.0 - d / 0.4, 0.0, 1.0);
	float t1 = abs(fract(p.x) - 0.5) * 2.0;
	float t2 = abs(fract(p.y) - 0.5) * 2.0;
	float paper = w1 > 0.0 ? smoothstep(w1 - aa, w1 + aa, t1) : 1.0;
	return paper * (w2 > 0.0 ? smoothstep(w2 - aa, w2 + aa, t2) : 1.0);
#else
	// Dots that grow as the light falls, until they meet.
	float radius = 0.75 * sqrt(clamp(1.0 - d / 0.7, 0.0, 1.0));
	float r = length(fract(p) - 0.5);
	return radius > 0.0 ? smoothstep(radius - aa, radius + aa, r) : 1.0;
#endif
}
#endif

void light() {
	float reach = toon_cut(ATTENUATION, LIGHT_IS_DIRECTIONAL);
	float d = clamp((dot(NORMAL, LIGHT) - band_threshold) / (1.0 - band_threshold), 0.0, 1.0) * reach;
#if defined(TOON_HATCH) || defined(TOON_HALFTONE)
	vec3 lit = vec3(toon_pattern(d, FRAGCOORD.xy, VIEWPORT_SIZE));
#else
	vec3 lit = use_ramp ? texture(ramp, vec2(d, 0.5)).rgb : vec3(toon_steps(d));
#endif
	vec3 light = LIGHT_COLOR / PI;
	DIFFUSE_LIGHT += light * lit * (vec3(1.0) - shadow_color.rgb);
	if (specular > 0.0 && d > 0.0) {
		float s = pow(max(dot(NORMAL, normalize(VIEW + LIGHT)), 0.0), glossiness);
		float soft = max(band_softness, 0.02) * 0.5;
		SPECULAR_LIGHT += light * smoothstep(0.5 - soft, 0.5 + soft, s) * specular * reach;
	}
}
