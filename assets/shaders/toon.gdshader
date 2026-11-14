shader_type spatial;
// Borgo San Carlo v1.2 - shader "toon dipinto" con micro-texture procedurale e riflesso cel selettivo.
render_mode cull_back;

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
uniform float spec_strength = 0.0;
uniform float spec_shininess = 28.0;
uniform float spec_threshold = 0.52;
uniform float grain_strength = 0.045;

varying vec3 local_pos;
varying vec3 world_pos;

void vertex() {
	local_pos = VERTEX;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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
	if (grain_strength > 0.001) {
		float g = fract(sin(dot(floor(world_pos * 12.0), vec3(12.9898, 78.233, 37.719))) * 43758.5453);
		c *= 1.0 + (g - 0.5) * grain_strength;
	}
	ALBEDO = c;
	ROUGHNESS = spec_strength > 0.0 ? 0.35 : 0.96;
	METALLIC = 0.0;
	SPECULAR = spec_strength > 0.0 ? 0.45 : 0.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = emission_color.rgb * emission_energy + c * rim * rim_strength;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float soft = smoothstep(-0.05, 0.12, ndl);
	float band2 = smoothstep(0.42, 0.62, ndl);
	float lit = mix(shade_floor, 0.78, soft);
	lit = mix(lit, 1.0, band2);
	DIFFUSE_LIGHT += LIGHT_COLOR * lit * ATTENUATION * (ndl > -0.05 ? 1.0 : 0.0) / PI;
	if (spec_strength > 0.001 && ndl > 0.0) {
		vec3 half_vec = normalize(LIGHT + VIEW);
		float ndh = clamp(dot(NORMAL, half_vec), 0.0, 1.0);
		float sp = smoothstep(spec_threshold, spec_threshold + 0.06, pow(ndh, spec_shininess));
		SPECULAR_LIGHT += LIGHT_COLOR * sp * spec_strength * ATTENUATION;
	}
}
