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
		// Zampilli e getti schiumosi semitrasparenti a striature verticali (mai coni bianchi opachi!)
		float stream1 = 0.5 + 0.5 * sin(UV.x * 48.0 + TIME * 5.0);
		float stream2 = 0.5 + 0.5 * cos(UV.x * 78.0 - TIME * 7.0 + UV.y * 12.0);
		float v_fade = smoothstep(0.0, 0.22, UV.y) * smoothstep(1.0, 0.18, abs(UV.y * 2.0 - 1.0));
		float spray_density = clamp(stream1 * 0.6 + stream2 * 0.4, 0.0, 1.0) * (0.45 + 0.55 * v_fade);
		ALBEDO = mix(shallow_color.rgb, vec3(0.92, 0.97, 1.0), 0.72);
		ALPHA = clamp(spray_density * 0.62, 0.06, 0.62);
		ROUGHNESS = 0.35;
		SPECULAR = 0.45;
		METALLIC = 0.0;
	} else {
		vec2 wuv = world_pos.xz * uv_scale;
		vec3 n1 = texture(water_nrm, wuv + vec2(TIME * wave_speed, TIME * wave_speed * 0.7)).rgb;
		vec3 n2 = texture(water_nrm, wuv * 1.45 - vec2(TIME * wave_speed * 0.8, -TIME * wave_speed * 0.55)).rgb;
		vec3 nblend = normalize(vec3((n1.rg + n2.rg - 1.0), 1.0));

		NORMAL_MAP = vec3(nblend.r * 0.5 + 0.5, nblend.g * 0.5 + 0.5, 1.0);
		NORMAL_MAP_DEPTH = normal_depth;

		// Fresnel calibrato per mantenere colore turchese intenso anche a vista radente
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
		vec3 sky_refl = vec3(0.42, 0.70, 0.86);

		float radial = clamp(length(UV - vec2(0.5)) * 2.0, 0.0, 1.0);
		float ripple = 0.5 + 0.5 * sin(radial * 28.0 - TIME * 4.5);
		float center_foam = (1.0 - smoothstep(0.02, 0.17, radial)) * ripple * foam_ring;

		vec3 base = mix(deep_color.rgb, shallow_color.rgb, clamp(0.48 + (nblend.r + nblend.g) * 0.15, 0.0, 1.0));
		vec3 col = mix(base, sky_refl, clamp(fres * 0.38, 0.0, 0.42));
		col = mix(col, vec3(0.88, 0.96, 1.0), clamp(center_foam, 0.0, 0.75));

		ALBEDO = col;
		ALPHA = clamp(mix(deep_color.a, 0.95, fres * 0.5 + center_foam), 0.82, 0.96);
		ROUGHNESS = 0.12;
		SPECULAR = 0.58;
		METALLIC = 0.02;
	}
}
