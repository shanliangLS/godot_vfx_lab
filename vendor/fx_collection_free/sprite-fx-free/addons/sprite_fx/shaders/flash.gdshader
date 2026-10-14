// Hit flash: blends the sprite toward a flat colour.
shader_type canvas_item;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
varying vec4 v_color;
void vertex() { v_color = COLOR; }
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(mix(tex.rgb, flash_color.rgb, flash_amount * flash_color.a), tex.a) * v_color;
}
