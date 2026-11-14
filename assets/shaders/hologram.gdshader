shader_type spatial;
// Hologram Blueprint Shader - sagome semi-trasparenti con scanline e Fresnel pulsante per installazioni in fabbrica.
render_mode blend_mix, depth_draw_never, cull_back, unshaded;

uniform vec4 holo_color : source_color = vec4(0.18, 0.92, 1.0, 1.0);
uniform float alpha_base = 0.36;
uniform float rim_power = 2.0;
uniform float pulse_speed = 2.6;
uniform float scan_freq = 26.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	float scan = 0.72 + 0.28 * sin(world_pos.y * scan_freq - TIME * 4.5);
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);
	vec3 col = holo_color.rgb * (0.95 + 0.75 * fresnel) * scan * pulse;
	float alpha = clamp((alpha_base + fresnel * 0.44) * scan * pulse, 0.14, 0.86);
	ALBEDO = col;
	ALPHA = alpha;
}
