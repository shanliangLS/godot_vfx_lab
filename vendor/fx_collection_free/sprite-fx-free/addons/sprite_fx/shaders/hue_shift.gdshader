// Hue rotation, static or cycling (rainbow), with saturation control.
shader_type canvas_item;
#include "fx_common.gdshaderinc"
uniform float shift : hint_range(0.0, 1.0) = 0.0;
// Full hue turns per second; 0 = static.
uniform float speed : hint_range(0.0, 4.0) = 0.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
varying vec4 v_color;
void vertex() { v_color = COLOR; }
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 rgb = fx_hue_shift(tex.rgb, shift + TIME * speed);
	rgb = mix(vec3(fx_luma(rgb)), rgb, saturation);
	COLOR = vec4(clamp(rgb, 0.0, 1.0), tex.a) * v_color;
}
