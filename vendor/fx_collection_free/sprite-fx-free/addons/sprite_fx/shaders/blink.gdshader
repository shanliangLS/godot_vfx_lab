// Invincibility-frame blink.
shader_type canvas_item;
uniform bool active = true;
// Blinks per second.
uniform float rate : hint_range(0.0, 30.0) = 10.0;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.15;
varying vec4 v_color;
void vertex() { v_color = COLOR; }
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float a = active ? mix(min_alpha, 1.0, step(0.5, fract(TIME * rate))) : 1.0;
	COLOR = vec4(tex.rgb, tex.a * a) * v_color;
}
