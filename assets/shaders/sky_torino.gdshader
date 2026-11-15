shader_type sky;
// Borgo San Carlo v1.3 - Cielo diurno piemontese con nuvole fBm stratificate, sole caldo e foschia alpina.

uniform vec3 sky_top : source_color = vec3(0.22, 0.48, 0.80);
uniform vec3 sky_mid : source_color = vec3(0.48, 0.72, 0.93);
uniform vec3 sky_horizon : source_color = vec3(0.84, 0.90, 0.95);
uniform vec3 sun_haze_color : source_color = vec3(1.0, 0.92, 0.78);
uniform vec3 ground_color : source_color = vec3(0.28, 0.34, 0.24);
uniform float cloud_coverage = 0.44;
uniform float cloud_softness = 0.26;
uniform float sun_disc_size = 0.025;
uniform float night_factor : hint_range(0.0, 1.0) = 0.0;
uniform float sunset_factor : hint_range(0.0, 1.0) = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.52;
	mat2 rot = mat2(vec2(0.80, -0.60), vec2(0.60, 0.80));
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = rot * p * 2.05 + vec2(17.1, 31.7);
		a *= 0.50;
	}
	return v;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float y = dir.y;

	vec3 sun_dir = LIGHT0_ENABLED ? normalize(LIGHT0_DIRECTION) : normalize(vec3(0.45, 0.58, 0.68));
	float sun_dot = max(dot(dir, sun_dir), 0.0);

	// Gradiente atmosferico cielo & suolo
	float up_t = clamp(y, 0.0, 1.0);
	vec3 col = mix(sky_horizon, sky_mid, pow(up_t, 0.42));
	col = mix(col, sky_top, smoothstep(0.18, 0.88, up_t));

	// Alone caldo intorno al sole e verso l'orizzonte (amplificato al tramonto / alba)
	float horizon_band = pow(1.0 - up_t, 2.8);
	float sun_glow = pow(sun_dot, 8.0) * 0.28 + pow(sun_dot, 64.0) * 0.42;
	float dusk_glow = sunset_factor * (0.48 * horizon_band + 0.36 * pow(sun_dot, 3.0) * (1.0 - up_t * 0.45));
	col = mix(col, sun_haze_color, clamp(sun_glow * (1.0 - up_t * 0.55) + dusk_glow, 0.0, 0.78));

	// Stelle procedurali notturne scintillanti (visibili sopra l'orizzonte e attenuate dalle nuvole)
	float cloud_alpha_mask = 0.0;
	vec3 cloud_col_final = vec3(1.0);
	if (y > 0.015) {
		vec2 uv = dir.xz / (y + 0.18) * 1.15;
		float c1 = fbm(uv + vec2(0.012 * TIME, 0.004 * TIME));
		float c2 = fbm(uv * 2.2 - vec2(0.018 * TIME, -0.006 * TIME));
		float density = c1 * 0.72 + c2 * 0.28;
		float cloud_mask = smoothstep(1.0 - cloud_coverage, 1.0 - cloud_coverage + cloud_softness, density);
		float horizon_fade = smoothstep(0.02, 0.24, y);
		cloud_mask *= horizon_fade * 0.88;
		cloud_alpha_mask = cloud_mask;

		// Ombreggiatura nuvole (bordo soleggiato bianco crema, notte grigio-blu argentato)
		float lit_shift = fbm(uv + sun_dir.xz * 0.14);
		float cloud_lit = clamp(0.65 + (density - lit_shift) * 1.8 + sun_dot * 0.25, 0.45, 1.05);
		vec3 cloud_shadow = mix(vec3(0.66, 0.74, 0.84), sky_horizon, 0.35);
		vec3 cloud_bright = mix(vec3(1.0, 0.99, 0.96), sun_haze_color, sunset_factor * 0.45);
		vec3 cloud_col = mix(cloud_shadow, cloud_bright, clamp(cloud_lit, 0.0, 1.0));
		cloud_col = mix(cloud_col, mix(vec3(0.07, 0.10, 0.18), vec3(0.18, 0.23, 0.36), clamp(cloud_lit, 0.0, 1.0)), night_factor * 0.90);
		cloud_col_final = cloud_col;
	}

	if (night_factor > 0.04 && y > 0.03) {
		vec2 suv = dir.xz / (y + 0.38) * 52.0;
		vec2 scell = floor(suv);
		vec2 sf = fract(suv) - 0.5;
		float h = hash21(scell);
		if (h > 0.885) {
			vec2 jitter = (vec2(hash21(scell + vec2(3.1, 7.4)), hash21(scell + vec2(9.2, 2.8))) - 0.5) * 0.62;
			float d_star = length(sf - jitter);
			float twinkle = 0.68 + 0.32 * sin(TIME * (1.8 + h * 3.5) + h * 42.0);
			float star_spot = smoothstep(0.16, 0.02, d_star);
			float star_vis = smoothstep(0.04, 0.28, y) * smoothstep(0.08, 0.80, night_factor) * (1.0 - cloud_alpha_mask * 0.92);
			vec3 star_tint = mix(vec3(0.84, 0.91, 1.0), vec3(1.0, 0.94, 0.84), fract(h * 19.7));
			col += star_tint * star_spot * twinkle * star_vis * (0.45 + 0.85 * (h - 0.885) * 8.5);
		}
	}

	// Applica strato nuvole sopra le stelle
	col = mix(col, cloud_col_final, cloud_alpha_mask);

	// Disco solare morbido (attenuato di notte)
	float sun_vis = max(0.0, 1.0 - night_factor * 1.45);
	float disc = smoothstep(1.0 - sun_disc_size * 0.16, 1.0 - sun_disc_size * 0.03, sun_dot);
	col += vec3(1.0, 0.95, 0.82) * disc * 1.4 * sun_vis;

	// Luna piena e alone freddo notturno
	if (night_factor > 0.05 && y > 0.01) {
		vec3 moon_dir = normalize(vec3(-0.36, 0.48, -0.56));
		float moon_dot = max(dot(dir, moon_dir), 0.0);
		float moon_disc = smoothstep(0.9984, 0.9991, moon_dot);
		float moon_halo = pow(moon_dot, 22.0) * 0.24 + pow(moon_dot, 160.0) * 0.32;
		float m_vis = smoothstep(0.10, 0.72, night_factor) * smoothstep(0.01, 0.12, y);
		col += vec3(0.82, 0.90, 1.0) * (moon_halo + moon_disc * 1.15) * m_vis * (1.0 - cloud_alpha_mask * 0.65);
	}

	// Emisfero inferiore per riflessi fresnel coerenti
	if (y < 0.0) {
		col = mix(sky_horizon, ground_color, smoothstep(0.0, -0.35, y));
	}

	COLOR = col;
}

