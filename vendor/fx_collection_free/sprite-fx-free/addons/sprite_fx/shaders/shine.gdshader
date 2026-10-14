// A band of light sweeping across: pickups, UI, rare items.
shader_type canvas_item;
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 0.85);
uniform float width : hint_range(0.0, 1.0) = 0.18;
uniform float angle : hint_range(-80.0, 80.0) = 25.0;
uniform float speed : hint_range(0.0, 5.0) = 1.2;
// Seconds between sweeps.
uniform float interval : hint_range(0.0, 10.0) = 1.2;
// 0..1 drives the band by hand; below 0 it runs on TIME.
uniform float progress : hint_range(-1.0, 1.0) = -1.0;
varying vec4 v_color;
void vertex() { v_color = COLOR; }
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float k = tan(radians(angle));
	float s = UV.x + (UV.y - 0.5) * k;
	float t = progress >= 0.0 ? progress : mod(TIME * speed, 1.0 + interval * speed);
	float c = mix(-width - abs(k) * 0.5, 1.0 + width + abs(k) * 0.5, t);
	float band = (1.0 - smoothstep(0.0, width * 0.5, abs(s - c))) * step(t, 1.0);
	COLOR = vec4(tex.rgb + shine_color.rgb * shine_color.a * band, tex.a) * v_color;
}
