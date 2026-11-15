shader_type spatial;
// Borgo San Carlo v1.3 - Foglie 3D e ciuffi d'erba alpha-scissored con ombre frastagliate naturali e traslucenza solare.
render_mode cull_disabled, depth_prepass_alpha, diffuse_burley, specular_schlick_ggx;

uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float uv_scale = 1.0;
uniform float alpha_scissor = 0.42;
uniform float wind_sway = 0.055;
uniform float translucency = 0.38;
uniform float roughness_val = 0.66;
uniform float macro_variation = 0.14;

varying vec3 world_pos;

float hash31(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.17, 0.23));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (wind_sway > 0.0) {
		float ph = TIME * 1.85 + world_pos.x * 0.9 + world_pos.z * 0.75 + world_pos.y * 0.4;
		float edge = clamp(1.0 - UV.y, 0.0, 1.0);
		VERTEX.x += sin(ph) * wind_sway * (0.4 + 0.6 * edge);
		VERTEX.z += cos(ph * 0.83) * wind_sway * 0.55 * (0.4 + 0.6 * edge);
	}
}

void fragment() {
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	vec4 tex = texture(albedo_tex, UV * uv_scale);
	float v_shift = 1.0 + (hash31(floor(world_pos * 1.4)) - 0.5) * macro_variation;
	vec3 col = tex.rgb * tint.rgb * v_shift;

	ALBEDO = col;
	ALPHA = tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.22;
	METALLIC = 0.0;
	BACKLIGHT = col * translucency;
}
