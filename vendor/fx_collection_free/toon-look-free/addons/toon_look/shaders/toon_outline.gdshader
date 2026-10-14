shader_type spatial;
render_mode unshaded, cull_front;
// The ink line: the mesh's back faces pushed out a fixed width on screen, as a toon material's
// next_pass.

uniform vec4 outline_color : source_color = vec4(0.1, 0.07, 0.12, 1.0);
// Pixels of a 1080-line screen, the same share of any other.
uniform float outline_width : hint_range(0.0, 16.0) = 3.0;
// 0 pushes along the normals (smooth meshes), 1 out from the mesh's origin, which closes the gaps
// hard-edged meshes (a box's split normals) leave at their corners.
uniform float outline_smooth : hint_range(0.0, 1.0) = 0.0;
// The lit material's wave, which the line rides with.
uniform float wave_height = 0.0;
uniform float wave_length = 3.0;
uniform float wave_speed = 0.5;
uniform int wave_pinned : hint_range(0, 2) = 0;

void vertex() {
	if (wave_height != 0.0) {
		vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float phase = dot(w, vec3(0.8, 0.5, 0.6)) * TAU / max(wave_length, 0.01) + TIME * TAU * wave_speed;
		float lift = 0.65 * sin(phase) + 0.35 * sin(phase * 1.7 + w.x - w.z);
		float pin = wave_pinned == 1 ? clamp(UV.y, 0.0, 1.0) : (wave_pinned == 2 ? clamp(1.0 - UV.y, 0.0, 1.0) : 1.0);
		VERTEX += NORMAL * wave_height * lift * pin;
	}
	vec3 out_dir = normalize(mix(NORMAL, VERTEX / max(length(VERTEX), 1e-5), outline_smooth) + vec3(1e-6));
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec2 dir = (PROJECTION_MATRIX * vec4(mat3(MODELVIEW_MATRIX) * out_dir, 0.0)).xy;
	float aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
	dir.x *= aspect;  // to square pixels, then back
	if (length(dir) > 1e-6) {
		dir = normalize(dir);
		dir.x /= aspect;
		clip.xy += dir * outline_width * (2.0 / 1080.0) * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
