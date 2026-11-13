shader_type spatial;
// Borgo San Carlo - shader "toon dipinto" unico per tutto il mondo 3D.
// 3 bande di luce morbide + luce di rimbalzo calda + leggero rim, niente speculare.
render_mode specular_disabled, cull_back;

uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float use_tex = 1.0;
uniform float uv_scale = 0.25;
uniform float brightness = 1.0;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
uniform float shade_floor = 0.42;
uniform float rim_strength = 0.18;
uniform float wind_sway = 0.0;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
	if (wind_sway > 0.0) {
		float w = sin(TIME * 1.3 + VERTEX.x * 0.8 + VERTEX.z * 0.6) * wind_sway * max(VERTEX.y, 0.0);
		VERTEX.x += w;
	}
}

void fragment() {
	vec3 tex = vec3(1.0);
	if (use_tex > 0.5) {
		tex = texture(albedo_tex, UV * uv_scale).rgb;
	}
	vec3 c = tex * tint.rgb * brightness;
	ALBEDO = c;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = emission_color.rgb * emission_energy + c * rim * rim_strength;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float soft = smoothstep(-0.05, 0.12, ndl);
	float band2 = smoothstep(0.42, 0.62, ndl);
	float lit = mix(shade_floor, 0.78, soft);
	lit = mix(lit, 1.0, band2);
	DIFFUSE_LIGHT += LIGHT_COLOR * lit * ATTENUATION * (ndl > -0.05 ? 1.0 : 0.0) / PI * 1.0;
}
