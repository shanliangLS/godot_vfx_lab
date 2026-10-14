shader_type spatial;
render_mode unshaded, blend_add;

group_uniforms laser;
uniform vec4 core_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.5, 0.5, 0.5);
uniform float laser_width : hint_range(0.01, 1.0) = 0.2;
uniform float core_intensity : hint_range(0.1, 5.0) = 1.0;
uniform float core_length : hint_range(0.0, 1.0) = 1.0;
uniform float glow_fade : hint_range(0.1, 30.0) = 0.1;
uniform float glow_shape : hint_range(0.1, 5.0) = 1.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.3;
uniform float pulse_dir_x : hint_range(-1.0, 1.0) = 0.0;
uniform float pulse_dir_y : hint_range(-1.0, 1.0) = 0.0;
uniform float pulse_dir_z : hint_range(-1.0, 1.0) = 1.0;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.1;

group_uniforms noise;
uniform float noise_scale : hint_range(0.0, 20.0) = 5.0;
uniform float noise_speed : hint_range(0.0, 5.0) = 1.0;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.1;
uniform float length_noise_scale : hint_range(0.0, 20.0) = 2.0;
uniform float length_noise_speed : hint_range(0.0, 5.0) = 0.5;
uniform float length_noise_strength : hint_range(0.0, 1.0) = 0.05;

group_uniforms oscillation;
uniform float osc_amplitude : hint_range(0.0, 0.5) = 0.05;
uniform float osc_frequency : hint_range(0.0, 20.0) = 5.0;
uniform float osc_speed : hint_range(0.0, 10.0) = 1.0;

float random(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(random(i + vec3(0.0, 0.0, 0.0)), random(i + vec3(1.0, 0.0, 0.0)), u.x),
                   mix(random(i + vec3(0.0, 1.0, 0.0)), random(i + vec3(1.0, 1.0, 0.0)), u.x), u.y),
               mix(mix(random(i + vec3(0.0, 0.0, 1.0)), random(i + vec3(1.0, 0.0, 1.0)), u.x),
                   mix(random(i + vec3(0.0, 1.0, 1.0)), random(i + vec3(1.0, 1.0, 1.0)), u.x), u.y), u.z);
}

void vertex() {
    vec3 osc_pos = VERTEX * osc_frequency + vec3(TIME * osc_speed);
    float osc = noise(osc_pos) * osc_amplitude;
    VERTEX += NORMAL * osc;
}

void fragment() {
    vec2 uv = UV;
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float dist_from_center = length(uv - vec2(0.5, 0.5));
    float length_factor = smoothstep(core_length, core_length - 0.1, abs(VERTEX.z / 5.0));
    float core = smoothstep(laser_width, 0.0, dist_from_center) * length_factor;
    vec3 core_result = core_color.rgb * core * core_intensity;
    float glow = pow(smoothstep(glow_fade, 0.0, dist_from_center), glow_shape) * (1.0 - core);
    vec3 glow_result = glow_color.rgb * glow;
    vec3 pulse_dir = normalize(vec3(pulse_dir_x, pulse_dir_y, pulse_dir_z));
    float pulse_pos = dot(world_pos, pulse_dir);
    float pulse = sin(pulse_pos + TIME * pulse_speed) * pulse_strength + 1.0;
    core_result *= pulse;
    glow_result *= pulse;
    vec3 noise_pos = world_pos * noise_scale + vec3(0.0, 0.0, TIME * noise_speed);
    float noise_value = noise(noise_pos) * noise_strength;
    core_result += noise_value;
    glow_result += noise_value;
    vec3 length_noise_pos = world_pos * length_noise_scale + vec3(0.0, 0.0, TIME * length_noise_speed);
    float length_noise_value = noise(length_noise_pos) * length_noise_strength;
    core_result += length_noise_value;
    glow_result += length_noise_value;
    vec3 final_color = core_result + glow_result * glow_color.a;
    final_color = clamp(final_color, 0.0, 1.0);
    ALBEDO = final_color;
    ALPHA = max(glow + core, min_alpha);
}
