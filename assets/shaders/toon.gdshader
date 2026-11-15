shader_type spatial;
// Borgo San Carlo v1.3 - Shader PBR stilo-realistico con normal map, roughness, cavity AO, patina ambientale e vetri riflettenti.
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D pbr_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float use_tex = 1.0;
uniform float use_pbr = 0.0;
uniform float uv_scale = 0.35;
uniform float brightness = 1.0;

uniform float normal_depth = 1.0;
uniform float roughness_base = 0.88;
uniform float metallic_val = 0.0;
uniform float specular_val = 0.35;
uniform float ao_strength = 0.85;
uniform float world_dirt_strength = 0.12;
uniform float macro_variation = 0.08;
uniform float glass_mode = 0.0;

uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 0.0;
uniform float shade_floor = 0.42;
uniform float rim_strength = 0.0;
uniform float wind_sway = 0.0;
uniform float spec_strength = 0.0;
uniform float spec_shininess = 28.0;
uniform float spec_threshold = 0.52;
uniform float grain_strength = 0.025;

varying vec3 local_pos;
varying vec3 world_pos;
varying vec3 world_nrm;

float hash31(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.17, 0.23));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float snoise3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));
	return mix(
		mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
		mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),
		f.z
	);
}

void vertex() {
	local_pos = VERTEX;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	if (wind_sway > 0.0) {
		float w = sin(TIME * 1.4 + world_pos.x * 0.7 + world_pos.z * 0.5) * wind_sway * max(VERTEX.y, 0.0);
		VERTEX.x += w;
	}
}

void fragment() {
	vec2 uv = UV * uv_scale;
	vec3 tex = vec3(1.0);
	if (use_tex > 0.5) {
		tex = texture(albedo_tex, uv).rgb;
	}
	vec3 c = tex * tint.rgb * brightness;

	// Variazione organica a grande scala + patina architettonica continua (zero pattern a quadretti!)
	float macro_n = snoise3(world_pos * 0.24) * 0.65 + snoise3(world_pos * 0.72) * 0.35;
	if (macro_variation > 0.001) {
		c *= 1.0 + (macro_n - 0.5) * macro_variation;
	}
	if (grain_strength > 0.001) {
		float fine_n = snoise3(world_pos * 6.5);
		c *= 1.0 + (fine_n - 0.5) * grain_strength;
	}

	float ao_val = 1.0;
	float rough = clamp(roughness_base, 0.04, 1.0);
	if (use_pbr > 0.5) {
		vec4 pbr = texture(pbr_tex, uv);
		float nx = pbr.r * 2.0 - 1.0;
		float ny = pbr.g * 2.0 - 1.0;
		float nz = sqrt(clamp(1.0 - nx * nx - ny * ny, 0.001, 1.0));
		NORMAL_MAP = vec3(pbr.r, pbr.g, nz * 0.5 + 0.5);
		NORMAL_MAP_DEPTH = normal_depth;
		rough = clamp(pbr.b * roughness_base, 0.04, 1.0);
		ao_val = mix(1.0, pbr.a, ao_strength);
	}

	// Usura e ombreggiatura di contatto vicino al pavimento/battiscopa (pareti interne e muretti)
	if (world_dirt_strength > 0.001) {
		float base_grime = smoothstep(0.55, 0.01, max(world_pos.y, 0.0));
		float wall_mask = 1.0 - smoothstep(0.65, 0.92, abs(world_nrm.y));
		float dirt_pat = 0.65 + 0.70 * snoise3(world_pos * 0.85);
		float d = clamp(base_grime * wall_mask * dirt_pat * world_dirt_strength, 0.0, 0.45);
		c *= (1.0 - d * 0.55);
		ao_val *= (1.0 - base_grime * wall_mask * 0.28 * clamp(world_dirt_strength * 2.0, 0.0, 1.0));
		rough = clamp(rough + d * 0.15, 0.05, 1.0);
	}

	// Vetri esterni realistici con interno scuro profondo e riflesso Fresnel controllato
	float metal_eff = metallic_val;
	if (glass_mode > 0.5) {
		float nv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float fres = pow(1.0 - nv, 2.8);
		vec3 sky_refl = mix(vec3(0.10, 0.17, 0.27), vec3(0.32, 0.48, 0.66), clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0));
		float win_grad = mix(0.65, 1.0, clamp((world_pos.y - 0.6) * 0.55, 0.0, 1.0));
		c = mix(c * 0.22 * win_grad, sky_refl, clamp(0.10 + fres * 0.34, 0.0, 0.46));
		rough = 0.04;
		metal_eff = max(metal_eff, 0.18);
	}

	ALBEDO = c;
	ROUGHNESS = rough;
	METALLIC = clamp(metal_eff, 0.0, 1.0);
	SPECULAR = clamp(specular_val, 0.0, 1.0);
	AO = clamp(ao_val, 0.15, 1.0);
	AO_LIGHT_AFFECT = 0.55;

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.2);
	EMISSION = emission_color.rgb * emission_energy + c * rim * rim_strength;
}
