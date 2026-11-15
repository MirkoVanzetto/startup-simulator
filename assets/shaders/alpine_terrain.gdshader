shader_type spatial;
// Borgo San Carlo v1.3 - Alpi Piemontesi con roccia granitica striata, nevaio sui crinali e foschia di quota.
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 rock_dark : source_color = vec3(0.20, 0.23, 0.29);
uniform vec3 rock_light : source_color = vec3(0.39, 0.43, 0.49);
uniform vec3 snow_color : source_color = vec3(0.84, 0.89, 0.94);
uniform vec3 foothill_color : source_color = vec3(0.18, 0.28, 0.16);
uniform float snow_line_y = 14.5;
uniform float snow_slope_thr = 0.62;

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
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 wn = normalize(world_nrm);
	float strata = snoise3(vec3(world_pos.x * 0.12, world_pos.y * 0.48 + world_pos.x * 0.07, world_pos.z * 0.12));
	float ridge_rib = snoise3(vec3(world_pos.x * 0.22, world_pos.y * 0.18, world_pos.z * 0.22));
	float detail = snoise3(world_pos * 0.45);
	float n_tot = strata * 0.52 + ridge_rib * 0.24 + detail * 0.24;

	vec3 rock = mix(rock_dark, rock_light, smoothstep(0.24, 0.80, n_tot));

	// Boschi pedemontani alla base dei rilievi
	float foothill_mask = smoothstep(7.0, 1.2, world_pos.y + n_tot * 2.2) * smoothstep(0.32, 0.70, wn.y);
	vec3 col = mix(rock, foothill_color * (0.82 + 0.34 * detail), foothill_mask);

	// Neve sui pendii e canaloni sopra snow_line_y lasciando affiorare le creste rocciose scure
	float snow_alt = smoothstep(snow_line_y - 3.5, snow_line_y + 7.5, world_pos.y + (n_tot - 0.5) * 9.0);
	float slope_fit = smoothstep(snow_slope_thr - 0.14, snow_slope_thr + 0.18, wn.y + (n_tot - 0.52) * 0.42);
	float snow_mask = clamp(snow_alt * slope_fit, 0.0, 1.0);
	col = mix(col, snow_color, snow_mask);

	// Foschia atmosferica alpina in lontananza per fusione naturale con il cielo
	float cam_dist = length(world_pos);
	float haze = smoothstep(55.0, 165.0, cam_dist) * smoothstep(1.5, 18.0, world_pos.y);
	col = mix(col, vec3(0.68, 0.80, 0.91), clamp(haze * 0.34, 0.0, 0.34));

	ALBEDO = col;
	ROUGHNESS = mix(0.90, 0.58, snow_mask);
	SPECULAR = mix(0.18, 0.32, snow_mask);
	METALLIC = 0.0;
}
