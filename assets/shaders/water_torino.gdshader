shader_type spatial;
// Borgo San Carlo v1.3 - Acqua animata turchese per fontana/laghetto e getti schiumosi semitrasparenti.
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.16, 0.56, 0.70, 0.88);
uniform vec4 deep_color : source_color = vec4(0.05, 0.28, 0.46, 0.95);
uniform sampler2D water_nrm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_depth = 0.75;
uniform float uv_scale = 0.65;
uniform float wave_speed = 0.045;
uniform float foam_ring = 0.16;
uniform float is_spray = 0.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (is_spray > 0.5) {
		// Zampilli e getti schiumosi semitrasparenti a gocce/filamenti fini aerati
		float stream1 = 0.5 + 0.5 * sin(UV.x * 58.0 + TIME * 7.5 + sin(UV.y * 14.0) * 1.4);
		float stream2 = 0.5 + 0.5 * cos(UV.x * 92.0 - TIME * 11.0 + UV.y * 22.0);
		float droplets = smoothstep(0.32, 0.85, stream1 * 0.55 + stream2 * 0.45);
		float v_fade = smoothstep(0.0, 0.16, UV.y) * smoothstep(1.0, 0.22, UV.y);
		float spray_density = mix(0.28, 1.0, droplets) * (0.38 + 0.62 * v_fade);
		vec3 foam_col = mix(shallow_color.rgb, vec3(0.95, 0.99, 1.0), 0.78);
		ALBEDO = foam_col;
		ALPHA = clamp(spray_density * 0.52, 0.04, 0.52);
		ROUGHNESS = 0.22;
		SPECULAR = 0.68;
		METALLIC = 0.0;
	} else {
		vec2 wuv = world_pos.xz * uv_scale;
		vec3 n1 = texture(water_nrm, wuv + vec2(TIME * wave_speed, TIME * wave_speed * 0.72)).rgb;
		vec3 n2 = texture(water_nrm, wuv * 1.55 - vec2(TIME * wave_speed * 0.85, -TIME * wave_speed * 0.62)).rgb;
		vec3 nblend = normalize(vec3((n1.rg + n2.rg - 1.0), 1.0));

		// Increspature concentriche dovute agli zampilli
		float radial = clamp(length(UV - vec2(0.5)) * 2.0, 0.0, 1.0);
		float wave_ring = sin(radial * 34.0 - TIME * 6.2);
		vec2 radial_dir = normalize((UV - vec2(0.5)) + vec2(0.0001));
		vec3 ripple_n = normalize(vec3(nblend.rg + radial_dir * wave_ring * foam_ring * 0.35, 1.0));

		NORMAL_MAP = vec3(ripple_n.r * 0.5 + 0.5, ripple_n.g * 0.5 + 0.5, 1.0);
		NORMAL_MAP_DEPTH = normal_depth * 1.15;

		float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float fres = pow(1.0 - ndv, 3.6);
		vec3 sky_refl = vec3(0.48, 0.78, 0.94);

		// Caustiche luminose sottili nella vasca
		float caustic = pow(clamp(0.5 + 0.5 * (nblend.r * nblend.g * 1.6), 0.0, 1.0), 2.4);
		float center_foam = (1.0 - smoothstep(0.04, 0.28, radial)) * clamp(0.45 + 0.55 * wave_ring, 0.0, 1.0) * foam_ring;
		float edge_rim = smoothstep(0.90, 1.0, radial) * foam_ring * 0.45;

		vec3 base = mix(deep_color.rgb, shallow_color.rgb, clamp(0.46 + (nblend.r + nblend.g) * 0.16 + caustic * 0.24, 0.0, 1.0));
		vec3 col = mix(base, sky_refl, clamp(fres * 0.44, 0.0, 0.48));
		col = mix(col, vec3(0.90, 0.97, 1.0), clamp(center_foam * 0.85 + edge_rim, 0.0, 0.78));

		ALBEDO = col;
		ALPHA = clamp(mix(deep_color.a, 0.94, fres * 0.45 + center_foam), 0.76, 0.94);
		ROUGHNESS = 0.07;
		SPECULAR = 0.72;
		METALLIC = 0.04;
	}
}

