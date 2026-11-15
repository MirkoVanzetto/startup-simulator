class_name VillageMaterials
extends RefCounted
## VillageMaterials - Libreria unica di ShaderMaterial PBR stilo-realistici, fogliame 3D, acqua, alpi e ologrammi per Torino v1.3.

const SHADER_PATH := "res://assets/shaders/toon.gdshader"
const HOLO_SHADER_PATH := "res://assets/shaders/hologram.gdshader"
const FOLIAGE_SHADER_PATH := "res://assets/shaders/foliage.gdshader"
const ALPINE_SHADER_PATH := "res://assets/shaders/alpine_terrain.gdshader"
const WATER_SHADER_PATH := "res://assets/shaders/water_torino.gdshader"
const TEX_DIR := "res://assets/textures/village/"

static var _shader: Shader = null
static var _holo_shader: Shader = null
static var _foliage_shader: Shader = null
static var _alpine_shader: Shader = null
static var _water_shader: Shader = null
static var _cache: Dictionary = {}
static var _tex_cache: Dictionary = {}
static var _noise_tex_cache: Dictionary = {}

static func _get_shader() -> Shader:
	if _shader == null:
		_shader = load(SHADER_PATH)
	return _shader

static func _get_holo_shader() -> Shader:
	if _holo_shader == null:
		_holo_shader = load(HOLO_SHADER_PATH)
	return _holo_shader

static func _get_foliage_shader() -> Shader:
	if _foliage_shader == null:
		_foliage_shader = load(FOLIAGE_SHADER_PATH)
	return _foliage_shader

static func _get_alpine_shader() -> Shader:
	if _alpine_shader == null:
		_alpine_shader = load(ALPINE_SHADER_PATH)
	return _alpine_shader

static func _get_water_shader() -> Shader:
	if _water_shader == null:
		_water_shader = load(WATER_SHADER_PATH)
	return _water_shader

static func _get_tex(name: String) -> Texture2D:
	if name == "":
		return null
	if not _tex_cache.has(name):
		var path := TEX_DIR + name + ".png"
		if ResourceLoader.exists(path):
			_tex_cache[name] = load(path)
		else:
			_tex_cache[name] = null
	return _tex_cache[name]

static func _get_noise_tex(cache_key: String, size: int, is_normal: bool, cfg: Dictionary) -> NoiseTexture2D:
	var full_key := "%s_%d_%s" % [cache_key, size, "nrm" if is_normal else "rgh"]
	if _noise_tex_cache.has(full_key):
		return _noise_tex_cache[full_key]

	var fnl := FastNoiseLite.new()
	fnl.seed = int(cfg.get("seed", 1337))
	fnl.noise_type = int(cfg.get("noise_type", FastNoiseLite.TYPE_SIMPLEX_SMOOTH))
	fnl.frequency = float(cfg.get("freq", 0.14))
	fnl.fractal_type = int(cfg.get("fractal_type", FastNoiseLite.FRACTAL_FBM))
	fnl.fractal_octaves = int(cfg.get("octaves", 4))
	fnl.fractal_lacunarity = float(cfg.get("lacunarity", 2.2))
	fnl.fractal_gain = float(cfg.get("gain", 0.52))
	if cfg.has("cellular_dist"):
		fnl.cellular_distance_function = int(cfg["cellular_dist"])
		fnl.cellular_jitter = float(cfg.get("cellular_jitter", 0.65))
	if bool(cfg.get("warp", false)):
		fnl.domain_warp_enabled = true
		fnl.domain_warp_amplitude = float(cfg.get("warp_amp", 14.0))
		fnl.domain_warp_frequency = float(cfg.get("warp_freq", 0.05))

	var nt := NoiseTexture2D.new()
	nt.width = size
	nt.height = size
	nt.seamless = true
	nt.seamless_blend_skirt = 0.25
	nt.generate_mipmaps = true
	nt.normalize = true
	nt.as_normal_map = is_normal
	if is_normal:
		nt.bump_strength = float(cfg.get("bump", 3.2))
	else:
		var rmin := clampf(float(cfg.get("rmin", 0.72)), 0.0, 1.0)
		var rmax := clampf(float(cfg.get("rmax", 1.0)), rmin, 1.0)
		var grad := Gradient.new()
		grad.set_color(0, Color(rmin, rmin, rmin, 1.0))
		grad.set_color(1, Color(rmax, rmax, rmax, 1.0))
		nt.color_ramp = grad
	nt.noise = fnl
	_noise_tex_cache[full_key] = nt
	return nt

static func _build_character_pbr_material(spec: Dictionary) -> StandardMaterial3D:
	var smat := StandardMaterial3D.new()
	smat.albedo_color = spec.get("tint", Color.WHITE)
	smat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	smat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	smat.roughness = clampf(float(spec.get("rough", 0.78)), 0.05, 1.0)
	smat.metallic = clampf(float(spec.get("metal", 0.0)), 0.0, 1.0)
	smat.metallic_specular = clampf(float(spec.get("spec_val", 0.34)), 0.0, 1.0)

	var kind: String = str(spec.get("kind", "cloth"))
	var uv_s := float(spec.get("uv", 5.0))
	smat.uv1_scale = Vector3(uv_s, float(spec.get("uv_y", uv_s)), uv_s)
	smat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	if kind == "skin":
		var skin_cfg := {
			"seed": 4102, "noise_type": FastNoiseLite.TYPE_SIMPLEX_SMOOTH,
			"freq": 0.28, "octaves": 4, "lacunarity": 2.4, "gain": 0.58,
			"bump": 3.0, "rmin": 0.68, "rmax": 1.0
		}
		smat.normal_enabled = true
		smat.normal_scale = float(spec.get("nscale", 0.34))
		smat.normal_texture = _get_noise_tex("skin_pores", 256, true, skin_cfg)
		smat.roughness_texture = _get_noise_tex("skin_pores", 256, false, skin_cfg)
		smat.subsurf_scatter_enabled = true
		smat.subsurf_scatter_strength = float(spec.get("sss", 0.36))
		smat.subsurf_scatter_skin_mode = true
		smat.subsurf_scatter_transmittance_enabled = false
		smat.backlight_enabled = false
		smat.rim_enabled = true
		smat.rim = float(spec.get("rim", 0.10))
		smat.rim_tint = float(spec.get("rim_tint", 0.55))
	elif kind == "cloth" or kind == "denim":
		var is_denim := (kind == "denim")
		var cloth_cfg := {
			"seed": 7219 if is_denim else 5831,
			"noise_type": FastNoiseLite.TYPE_SIMPLEX_SMOOTH,
			"freq": 0.20 if is_denim else 0.18,
			"octaves": 4, "lacunarity": 2.5, "gain": 0.58,
			"warp": not is_denim, "warp_amp": 5.0, "warp_freq": 0.12,
			"bump": 4.4 if is_denim else 3.6, "rmin": 0.80, "rmax": 1.0
		}
		var nkey := "fabric_denim" if is_denim else "fabric_linen"
		smat.normal_enabled = true
		smat.normal_scale = float(spec.get("nscale", 0.56 if is_denim else 0.46))
		smat.normal_texture = _get_noise_tex(nkey, 256, true, cloth_cfg)
		smat.roughness_texture = _get_noise_tex(nkey, 256, false, cloth_cfg)
		smat.subsurf_scatter_enabled = false
		smat.rim_enabled = true
		smat.rim = float(spec.get("rim", 0.11))
		smat.rim_tint = float(spec.get("rim_tint", 0.28))
	elif kind == "hair":
		var hair_cfg := {
			"seed": 9041, "noise_type": FastNoiseLite.TYPE_SIMPLEX_SMOOTH,
			"freq": 0.14, "octaves": 4, "lacunarity": 2.2, "gain": 0.55,
			"warp": true, "warp_amp": 18.0, "warp_freq": 0.055,
			"bump": 3.8, "rmin": 0.80, "rmax": 1.0
		}
		smat.normal_enabled = true
		smat.normal_scale = float(spec.get("nscale", 0.44))
		smat.normal_texture = _get_noise_tex("hair_strands", 256, true, hair_cfg)
		smat.roughness_texture = _get_noise_tex("hair_strands", 256, false, hair_cfg)
		smat.subsurf_scatter_enabled = false
		smat.rim_enabled = true
		smat.rim = float(spec.get("rim", 0.10))
		smat.rim_tint = float(spec.get("rim_tint", 0.25))
	elif kind == "leather":
		var lth_cfg := {
			"seed": 3187, "noise_type": FastNoiseLite.TYPE_CELLULAR,
			"freq": 0.16, "octaves": 2,
			"cellular_dist": FastNoiseLite.DISTANCE_EUCLIDEAN, "cellular_jitter": 0.85,
			"bump": 3.4, "rmin": 0.76, "rmax": 1.0
		}
		smat.normal_enabled = true
		smat.normal_scale = float(spec.get("nscale", 0.44))
		smat.normal_texture = _get_noise_tex("leather_grain", 256, true, lth_cfg)
		smat.roughness_texture = _get_noise_tex("leather_grain", 256, false, lth_cfg)
		smat.subsurf_scatter_enabled = false
	elif kind == "eye":
		smat.subsurf_scatter_enabled = false
		smat.clearcoat_enabled = true
		smat.clearcoat = float(spec.get("clearcoat", 0.88))
		smat.clearcoat_roughness = 0.05
	elif kind == "metal":
		var met_cfg := {
			"seed": 6611, "noise_type": FastNoiseLite.TYPE_SIMPLEX_SMOOTH,
			"freq": 0.18, "octaves": 2, "bump": 1.8, "rmin": 0.80, "rmax": 1.0
		}
		smat.normal_enabled = true
		smat.normal_scale = 0.22
		smat.normal_texture = _get_noise_tex("metal_micro", 256, true, met_cfg)
		smat.roughness_texture = _get_noise_tex("metal_micro", 256, false, met_cfg)
		smat.subsurf_scatter_enabled = false

	return smat

static func clear_cache() -> void:
	_cache.clear()
	_noise_tex_cache.clear()

static func mat(key: String) -> Material:
	if _cache.has(key):
		return _cache[key]
	var spec := _spec_for(key)
	var mode: String = str(spec.get("mode", "pbr"))

	if mode == "char_pbr":
		var smat := _build_character_pbr_material(spec)
		_cache[key] = smat
		return smat

	var m := ShaderMaterial.new()

	if mode == "holo" or bool(spec.get("holo", false)):
		m.shader = _get_holo_shader()
		m.set_shader_parameter("holo_color", spec.get("holo_color", Color(0.18, 0.92, 1.0, 1.0)))
		m.set_shader_parameter("alpha_base", float(spec.get("alpha", 0.36)))
		m.set_shader_parameter("rim_power", float(spec.get("rim_power", 2.0)))
		m.set_shader_parameter("pulse_speed", float(spec.get("pulse_speed", 2.6)))
		m.set_shader_parameter("scan_freq", float(spec.get("scan_freq", 26.0)))
		_cache[key] = m
		return m

	if mode == "foliage":
		m.shader = _get_foliage_shader()
		m.set_shader_parameter("tint", spec.get("tint", Color.WHITE))
		var ftex := _get_tex(str(spec.get("tex", "leaf_cluster")))
		if ftex != null:
			m.set_shader_parameter("albedo_tex", ftex)
		m.set_shader_parameter("uv_scale", float(spec.get("uv", 1.0)))
		m.set_shader_parameter("alpha_scissor", float(spec.get("scissor", 0.42)))
		m.set_shader_parameter("wind_sway", float(spec.get("sway", 0.055)))
		m.set_shader_parameter("translucency", float(spec.get("trans", 0.38)))
		m.set_shader_parameter("roughness_val", float(spec.get("rough", 0.66)))
		m.set_shader_parameter("macro_variation", float(spec.get("macro", 0.14)))
		_cache[key] = m
		return m

	if mode == "alpine":
		m.shader = _get_alpine_shader()
		m.set_shader_parameter("rock_dark", spec.get("rock_dark", Color(0.28, 0.32, 0.39)))
		m.set_shader_parameter("rock_light", spec.get("rock_light", Color(0.46, 0.49, 0.54)))
		m.set_shader_parameter("snow_color", spec.get("snow_color", Color(0.92, 0.95, 0.99)))
		m.set_shader_parameter("foothill_color", spec.get("foothill_color", Color(0.18, 0.30, 0.18)))
		m.set_shader_parameter("snow_line_y", float(spec.get("snow_y", 9.0)))
		m.set_shader_parameter("snow_slope_thr", float(spec.get("snow_thr", 0.52)))
		_cache[key] = m
		return m

	if mode == "water":
		m.shader = _get_water_shader()
		m.set_shader_parameter("shallow_color", spec.get("shallow", Color(0.16, 0.56, 0.70, 0.88)))
		m.set_shader_parameter("deep_color", spec.get("deep", Color(0.05, 0.28, 0.46, 0.95)))
		var wtex := _get_tex("water_nrm")
		if wtex != null:
			m.set_shader_parameter("water_nrm", wtex)
		m.set_shader_parameter("normal_depth", float(spec.get("ndepth", 0.75)))
		m.set_shader_parameter("uv_scale", float(spec.get("uv", 0.65)))
		m.set_shader_parameter("wave_speed", float(spec.get("speed", 0.045)))
		m.set_shader_parameter("foam_ring", float(spec.get("foam", 0.16)))
		m.set_shader_parameter("is_spray", float(spec.get("spray", 0.0)))
		_cache[key] = m
		return m

	# Default: stylized-realistic PBR shader (assets/shaders/toon.gdshader)
	m.shader = _get_shader()
	m.set_shader_parameter("tint", spec.get("tint", Color.WHITE))
	var tex_name: String = str(spec.get("tex", ""))
	var tex := _get_tex(tex_name)
	if tex != null:
		m.set_shader_parameter("albedo_tex", tex)
		m.set_shader_parameter("use_tex", 1.0)
		var pbr_tex := _get_tex(tex_name + "_pbr")
		if pbr_tex != null:
			m.set_shader_parameter("pbr_tex", pbr_tex)
			m.set_shader_parameter("use_pbr", 1.0)
		else:
			m.set_shader_parameter("use_pbr", 0.0)
	else:
		m.set_shader_parameter("use_tex", 0.0)
		m.set_shader_parameter("use_pbr", 0.0)

	m.set_shader_parameter("uv_scale", float(spec.get("uv", 0.35)))
	m.set_shader_parameter("brightness", float(spec.get("bright", 1.0)))
	m.set_shader_parameter("normal_depth", float(spec.get("ndepth", 1.15)))
	m.set_shader_parameter("roughness_base", float(spec.get("rough", 0.88)))
	m.set_shader_parameter("metallic_val", float(spec.get("metal", 0.0)))
	m.set_shader_parameter("specular_val", float(spec.get("spec_val", 0.35)))
	m.set_shader_parameter("ao_strength", float(spec.get("ao", 0.85)))
	m.set_shader_parameter("world_dirt_strength", float(spec.get("dirt", 0.0)))
	m.set_shader_parameter("macro_variation", float(spec.get("macro", 0.06)))
	m.set_shader_parameter("glass_mode", float(spec.get("glass", 0.0)))

	m.set_shader_parameter("emission_color", spec.get("emit", Color.BLACK))
	m.set_shader_parameter("emission_energy", float(spec.get("emit_e", 0.0)))
	m.set_shader_parameter("shade_floor", float(spec.get("floor", 0.42)))
	m.set_shader_parameter("rim_strength", float(spec.get("rim", 0.0)))
	m.set_shader_parameter("wind_sway", float(spec.get("sway", 0.0)))
	m.set_shader_parameter("spec_strength", float(spec.get("spec", 0.0)))
	m.set_shader_parameter("spec_shininess", float(spec.get("shininess", 28.0)))
	m.set_shader_parameter("spec_threshold", float(spec.get("spec_thr", 0.52)))
	m.set_shader_parameter("grain_strength", float(spec.get("grain", 0.015)))
	_cache[key] = m
	return m

static func _spec_for(key: String) -> Dictionary:
	match key:
		# Ologrammi 3D Blueprint (Officina Bellini & Waypoint Pads)
		"ghost_ready":       return {"mode": "holo", "holo_color": Color(0.18, 0.94, 1.0, 1.0), "alpha": 0.42, "pulse_speed": 2.8}
		"ghost_locked":      return {"mode": "holo", "holo_color": Color(1.0, 0.74, 0.22, 1.0), "alpha": 0.22, "pulse_speed": 1.4}
		"ghost_pad":         return {"mode": "holo", "holo_color": Color(0.22, 0.96, 0.78, 1.0), "alpha": 0.44, "pulse_speed": 2.2, "scan_freq": 18.0}

		# Fogliame 3D, prati e Alpi
		"leaves_canopy":     return {"mode": "foliage", "tex": "leaf_cluster", "tint": Color(0.96, 0.97, 0.90), "sway": 0.055, "trans": 0.40, "macro": 0.16}
		"leaves_canopy_dark":return {"mode": "foliage", "tex": "leaf_cluster", "tint": Color(0.76, 0.84, 0.72), "sway": 0.042, "trans": 0.28, "macro": 0.14}
		"grass_tuft":        return {"mode": "foliage", "tex": "grass_tuft", "tint": Color(0.88, 0.92, 0.84), "scissor": 0.38, "sway": 0.038, "trans": 0.32, "macro": 0.18}
		"alpine_peak":       return {"mode": "alpine", "snow_y": 13.5, "snow_thr": 0.66, "rock_dark": Color(0.18, 0.21, 0.27), "rock_light": Color(0.37, 0.41, 0.48), "snow_color": Color(0.76, 0.82, 0.90)}
		"alpine_hill":       return {"mode": "alpine", "snow_y": 99.0, "foothill_color": Color(0.20, 0.31, 0.17), "rock_dark": Color(0.22, 0.31, 0.18), "rock_light": Color(0.28, 0.38, 0.22)}
		"water":             return {"mode": "water", "shallow": Color(0.16, 0.56, 0.70, 0.88), "deep": Color(0.05, 0.28, 0.46, 0.95), "ndepth": 0.78, "uv": 0.65, "foam": 0.16, "spray": 0.0}
		"water_spray":       return {"mode": "water", "shallow": Color(0.82, 0.93, 0.98, 0.65), "deep": Color(0.50, 0.78, 0.90, 0.45), "ndepth": 0.90, "uv": 1.8, "speed": 0.32, "foam": 0.55, "spray": 1.0}

		# Intonaci piemontesi & calcestruzzo industriale con patina e normali
		"plaster_cream":     return {"tex": "plaster", "tint": Color("#ebe0cb"), "uv": 0.34, "ndepth": 1.32, "rough": 0.90, "ao": 0.90, "dirt": 0.28, "macro": 0.11}
		"plaster_ochre":     return {"tex": "plaster", "tint": Color("#d8a65e"), "uv": 0.34, "ndepth": 1.32, "rough": 0.88, "ao": 0.90, "dirt": 0.26, "macro": 0.11}
		"plaster_terracotta":return {"tex": "plaster", "tint": Color("#c26648"), "uv": 0.34, "ndepth": 1.38, "rough": 0.88, "ao": 0.92, "dirt": 0.28, "macro": 0.12}
		"plaster_sage":      return {"tex": "plaster", "tint": Color("#8da989"), "uv": 0.34, "ndepth": 1.35, "rough": 0.89, "ao": 0.92, "dirt": 0.28, "macro": 0.12}
		"plaster_rose":      return {"tex": "plaster", "tint": Color("#cf8d82"), "uv": 0.34, "ndepth": 1.32, "rough": 0.89, "ao": 0.90, "dirt": 0.26, "macro": 0.11}
		"plaster_sky":       return {"tex": "plaster", "tint": Color("#82a2b8"), "uv": 0.34, "ndepth": 1.32, "rough": 0.88, "ao": 0.90, "dirt": 0.24, "macro": 0.11}
		"plaster_studio":    return {"tex": "plaster", "tint": Color("#eae2d4"), "uv": 0.38, "ndepth": 1.22, "rough": 0.88, "ao": 0.88, "dirt": 0.24, "macro": 0.09}
		"plaster_rough":     return {"tex": "plaster_rough", "tint": Color("#d2cec5"), "uv": 0.42, "ndepth": 1.70, "rough": 0.92, "ao": 0.96, "dirt": 0.44, "macro": 0.15}

		# Muratura, pietra, strade e terreno
		"wall_garden":       return {"tex": "wall_garden", "tint": Color("#f3ede3"), "uv": 0.42, "ndepth": 1.50, "rough": 0.92, "ao": 0.96, "dirt": 0.36, "macro": 0.14}
		"brick":             return {"tex": "brick", "tint": Color("#f2ebe4"), "uv": 0.42, "ndepth": 1.48, "rough": 0.88, "ao": 0.96, "dirt": 0.24, "macro": 0.10}
		"brick_ogr":         return {"tex": "brick", "tint": Color("#b45b42"), "uv": 0.46, "ndepth": 1.55, "rough": 0.88, "ao": 0.96, "dirt": 0.28, "macro": 0.12}
		"ashlar":            return {"tex": "ashlar", "tint": Color("#c4b49e"), "uv": 0.38, "ndepth": 1.45, "rough": 0.86, "ao": 0.94, "dirt": 0.24}
		"stone_trim":        return {"tex": "ashlar", "tint": Color("#cfc6b3"), "uv": 0.48, "ndepth": 1.32, "rough": 0.84, "ao": 0.92, "dirt": 0.18}
		"stone_dark":        return {"tex": "ashlar", "tint": Color("#636c79"), "uv": 0.35, "ndepth": 1.42, "rough": 0.86, "ao": 0.94}
		"mountain_rock":     return {"mode": "alpine"}
		"mountain_snow":     return {"tint": Color("#e3ecf2"), "rough": 0.58, "spec_val": 0.35}
		"cobble":            return {"tex": "cobble", "tint": Color("#ded6c9"), "uv": 0.46, "ndepth": 1.68, "rough": 0.86, "ao": 0.98, "macro": 0.13}
		"slabs":             return {"tex": "slabs", "tint": Color("#c6beb0"), "uv": 0.44, "ndepth": 1.40, "rough": 0.84, "ao": 0.94, "macro": 0.11}
		"asphalt":           return {"tex": "asphalt", "tint": Color.WHITE, "uv": 0.34, "ndepth": 1.48, "rough": 0.88, "ao": 0.92, "macro": 0.15}
		"gravel":            return {"tex": "gravel", "tint": Color("#aca292"), "uv": 1.05, "ndepth": 2.05, "rough": 0.95, "ao": 0.96, "macro": 0.20}
		"grass":             return {"tex": "grass", "tint": Color("#93a882"), "uv": 0.44, "ndepth": 1.48, "rough": 0.95, "ao": 0.90, "macro": 0.24}
		"concrete_ogr":      return {"tex": "concrete_ogr", "tint": Color("#e4e8ec"), "uv": 0.30, "ndepth": 1.38, "rough": 0.48, "spec_val": 0.72, "ao": 0.92, "macro": 0.14}

		# Tetti & lamiere
		"roof_terracotta":   return {"tex": "roof_terracotta", "tint": Color.WHITE, "uv": 0.48, "ndepth": 1.50, "rough": 0.82, "ao": 0.92}
		"roof_slate":        return {"tex": "roof_slate", "tint": Color.WHITE, "uv": 0.48, "ndepth": 1.40, "rough": 0.76, "ao": 0.92}
		"corrugated_metal":  return {"tex": "corrugated_metal", "tint": Color("#a9b3be"), "uv": 0.50, "ndepth": 1.45, "rough": 0.46, "metal": 0.48, "spec_val": 0.68, "ao": 0.90}

		# Legni, marmo e pavimenti interni
		"wood_light":        return {"tex": "planks_light", "tint": Color("#f3e6d3"), "uv": 0.58, "ndepth": 1.05, "rough": 0.48, "spec_val": 0.52, "ao": 0.90}
		"wood_dark":         return {"tex": "planks_dark", "tint": Color("#e8ddd0"), "uv": 0.58, "ndepth": 1.05, "rough": 0.52, "spec_val": 0.45, "ao": 0.90}
		"wood_mid":          return {"tex": "planks_light", "tint": Color("#b4834b"), "uv": 0.58, "ndepth": 1.05, "rough": 0.52, "spec_val": 0.44, "ao": 0.90}
		"marble_dark":       return {"tex": "marble_dark", "tint": Color.WHITE, "uv": 0.55, "ndepth": 0.75, "rough": 0.22, "spec_val": 0.75, "ao": 0.65}
		"marble_light":      return {"tex": "plaster", "tint": Color("#e5dfd2"), "uv": 0.55, "ndepth": 0.45, "rough": 0.24, "spec_val": 0.72, "ao": 0.75}
		"tile_rc":           return {"tex": "tile_check_rc", "tint": Color.WHITE, "uv": 0.68, "ndepth": 1.25, "rough": 0.36, "spec_val": 0.64, "ao": 0.92}
		"tile_bw":           return {"tex": "tile_check_bw", "tint": Color.WHITE, "uv": 0.68, "ndepth": 1.25, "rough": 0.35, "spec_val": 0.64, "ao": 0.92}
		"tile_cafe":         return {"tex": "tile_check_cafe", "tint": Color.WHITE, "uv": 0.68, "ndepth": 1.20, "rough": 0.36, "spec_val": 0.62, "ao": 0.90}
		"tile_gray":         return {"tex": "tile_check_gray", "tint": Color.WHITE, "uv": 0.58, "ndepth": 1.25, "rough": 0.34, "spec_val": 0.65, "ao": 0.90}

		# Tende da sole
		"awning_red":        return {"tex": "awning_red", "tint": Color.WHITE, "uv": 0.62, "ndepth": 1.15, "rough": 0.82}
		"awning_green":      return {"tex": "awning_green", "tint": Color.WHITE, "uv": 0.62, "ndepth": 1.15, "rough": 0.82}
		"awning_blue":       return {"tex": "awning_blue", "tint": Color.WHITE, "uv": 0.62, "ndepth": 1.15, "rough": 0.82}
		"awning_yellow":     return {"tex": "awning_yellow", "tint": Color.WHITE, "uv": 0.62, "ndepth": 1.15, "rough": 0.82}

		# Natura, cortecce, fibre & pane
		"leaves":            return {"tex": "leaves", "tint": Color("#6ead45"), "uv": 0.55, "ndepth": 1.20, "sway": 0.04, "rough": 0.74}
		"leaves_dark":       return {"tex": "leaves", "tint": Color("#468236"), "uv": 0.55, "ndepth": 1.20, "sway": 0.03, "rough": 0.78}
		"bark":              return {"tex": "bark", "tint": Color.WHITE, "uv": 0.70, "ndepth": 1.65, "rough": 0.94, "ao": 0.96, "macro": 0.10}
		"wicker":            return {"tex": "wicker", "tint": Color.WHITE, "uv": 1.40, "ndepth": 1.40, "rough": 0.84, "ao": 0.95}
		"burlap":            return {"tex": "burlap", "tint": Color.WHITE, "uv": 1.10, "ndepth": 1.35, "rough": 0.94, "ao": 0.90}
		"bread":             return {"tex": "bread_crust", "tint": Color("#f8e4cb"), "uv": 1.45, "ndepth": 1.30, "rough": 0.72, "ao": 0.90}
		"flour":             return {"tex": "plaster_rough", "tint": Color("#ebe2d0"), "uv": 1.80, "ndepth": 0.45, "rough": 0.98}
		"flower_red":        return {"tint": Color("#d6453e"), "rough": 0.65}
		"flower_yellow":     return {"tint": Color("#efc43b"), "rough": 0.65}
		"flower_purple":     return {"tint": Color("#9f5cc8"), "rough": 0.65}

		# Metalli, vetri architettonici, tessuti, LED
		"iron":              return {"tint": Color("#2a3038"), "rough": 0.48, "metal": 0.68, "spec_val": 0.58}
		"brass":             return {"tint": Color("#cfa046"), "rough": 0.28, "metal": 0.86, "spec_val": 0.80}
		"steel":             return {"tint": Color("#adb7c2"), "rough": 0.34, "metal": 0.74, "spec_val": 0.78}
		"steel_duct":        return {"tint": Color("#bcc6cf"), "rough": 0.28, "metal": 0.82, "spec_val": 0.86}
		"copper":            return {"tint": Color("#be6e3c"), "rough": 0.32, "metal": 0.82, "spec_val": 0.78}
		"glass_exterior":    return {"tint": Color("#1d2c3b"), "glass": 1.0, "rough": 0.06, "spec_val": 0.92}
		"glass_warm":        return {"tint": Color("#21303f"), "glass": 1.0, "rough": 0.06, "spec_val": 0.90}
		"glass_studio_day":  return {"tint": Color("#648ea8"), "glass": 1.0, "rough": 0.08, "spec_val": 0.86, "emit": Color("#9ad0ef"), "emit_e": 0.28}
		"glass_cool":        return {"tint": Color("#7fbbe0"), "rough": 0.14, "spec_val": 0.82, "emit": Color("#5cb8e6"), "emit_e": 0.32}
		"lamp_glow":         return {"tint": Color("#fff5d6"), "emit": Color("#ffdf8e"), "emit_e": 1.45, "rough": 0.22}
		"led_white":         return {"tint": Color("#f5fbff"), "emit": Color("#eaf5ff"), "emit_e": 1.85, "rough": 0.15}
		"ember_glow":        return {"tint": Color("#ff7c2c"), "emit": Color("#ff5714"), "emit_e": 1.65, "rough": 0.45}

		"fabric_blue":       return {"tex": "fabric", "tint": Color("#486d9e"), "uv": 1.3, "ndepth": 0.95, "rough": 0.86}
		"fabric_red":        return {"tex": "fabric", "tint": Color("#bc433b"), "uv": 1.3, "ndepth": 0.95, "rough": 0.86}
		"fabric_cream":      return {"tex": "fabric", "tint": Color("#ede4d2"), "uv": 1.3, "ndepth": 0.95, "rough": 0.88}
		"fabric_green":      return {"tex": "fabric", "tint": Color("#467e54"), "uv": 1.3, "ndepth": 0.95, "rough": 0.86}

		# Auto e furgoni (vernice lucida automobilistica)
		"car_red":           return {"tint": Color("#c83e36"), "rough": 0.24, "metal": 0.22, "spec_val": 0.80}
		"car_cream":         return {"tint": Color("#dad0bc"), "rough": 0.26, "metal": 0.14, "spec_val": 0.76}
		"car_sage":          return {"tint": Color("#649172"), "rough": 0.25, "metal": 0.18, "spec_val": 0.76}
		"car_blue":          return {"tint": Color("#386599"), "rough": 0.24, "metal": 0.24, "spec_val": 0.80}
		"tire":              return {"tint": Color("#1e2024"), "rough": 0.86, "spec_val": 0.15}

		# Frutta
		"apple":             return {"tint": Color("#cd3732"), "rough": 0.36, "spec_val": 0.55}
		"lemon":             return {"tint": Color("#ecc938"), "rough": 0.42, "spec_val": 0.45}
		"orange":            return {"tint": Color("#e47820"), "rough": 0.48, "spec_val": 0.40}

		# Personaggi v1.5: StandardMaterial3D semi-realistico (Pelle SSS + pori, Capelli con fibre, Occhi corneali, Tessuti tramati NoiseTexture2D)
		"skin":              return {"mode": "char_pbr", "kind": "skin", "tint": Color("#cca084"), "rough": 0.70, "spec_val": 0.22, "nscale": 0.34, "uv": 5.5, "sss": 0.36, "rim": 0.08}
		"skin_warm":         return {"mode": "char_pbr", "kind": "skin", "tint": Color("#c49272"), "rough": 0.71, "spec_val": 0.21, "nscale": 0.36, "uv": 5.5, "sss": 0.38, "rim": 0.08}
		"skin_cheek":        return {"mode": "char_pbr", "kind": "skin", "tint": Color("#c78b78"), "rough": 0.71, "spec_val": 0.19, "nscale": 0.28, "uv": 5.5, "sss": 0.36, "rim": 0.07}
		"skin_crevice":      return {"mode": "char_pbr", "kind": "skin", "tint": Color("#a06f57"), "rough": 0.84, "spec_val": 0.12, "nscale": 0.22, "uv": 5.5, "sss": 0.22, "rim": 0.04}
		"lip_warm":          return {"mode": "char_pbr", "kind": "skin", "tint": Color("#b3786a"), "rough": 0.64, "spec_val": 0.23, "nscale": 0.20, "uv": 6.0, "sss": 0.32, "rim": 0.07}
		"lip_rose":          return {"mode": "char_pbr", "kind": "skin", "tint": Color("#b86f68"), "rough": 0.58, "spec_val": 0.26, "nscale": 0.20, "uv": 6.0, "sss": 0.32, "rim": 0.08}

		"hair_brown":        return {"mode": "char_pbr", "kind": "hair", "tint": Color("#462a1a"), "rough": 0.68, "spec_val": 0.24, "uv": 3.5, "uv_y": 12.0, "nscale": 0.44, "rim": 0.10}
		"hair_chestnut":     return {"mode": "char_pbr", "kind": "hair", "tint": Color("#5d331f"), "rough": 0.66, "spec_val": 0.26, "uv": 3.5, "uv_y": 12.0, "nscale": 0.46, "rim": 0.11}
		"hair_blonde":       return {"mode": "char_pbr", "kind": "hair", "tint": Color("#b48742"), "rough": 0.66, "spec_val": 0.26, "uv": 3.5, "uv_y": 12.0, "nscale": 0.44, "rim": 0.11}
		"hair_auburn":       return {"mode": "char_pbr", "kind": "hair", "tint": Color("#7d3620"), "rough": 0.66, "spec_val": 0.26, "uv": 3.5, "uv_y": 12.0, "nscale": 0.46, "rim": 0.11}
		"hair_dark":         return {"mode": "char_pbr", "kind": "hair", "tint": Color("#242024"), "rough": 0.70, "spec_val": 0.22, "uv": 3.5, "uv_y": 12.0, "nscale": 0.42, "rim": 0.09}
		"hair_salt":         return {"mode": "char_pbr", "kind": "hair", "tint": Color("#6d727a"), "rough": 0.68, "spec_val": 0.24, "uv": 3.5, "uv_y": 12.0, "nscale": 0.44, "rim": 0.10}
		"eyebrow_dark":      return {"mode": "char_pbr", "kind": "hair", "tint": Color("#34241c"), "rough": 0.84, "spec_val": 0.14, "uv": 4.2, "uv_y": 8.0, "nscale": 0.34, "rim": 0.04}

		"eye_white":         return {"mode": "char_pbr", "kind": "eye", "tint": Color("#d8d1c7"), "rough": 0.16, "spec_val": 0.68, "clearcoat": 0.80}
		"iris_brown":        return {"mode": "char_pbr", "kind": "eye", "tint": Color("#4a2b17"), "rough": 0.12, "spec_val": 0.85, "clearcoat": 0.92}
		"iris_blue":         return {"mode": "char_pbr", "kind": "eye", "tint": Color("#2c629e"), "rough": 0.12, "spec_val": 0.85, "clearcoat": 0.92}
		"iris_green":        return {"mode": "char_pbr", "kind": "eye", "tint": Color("#2d6f49"), "rough": 0.12, "spec_val": 0.85, "clearcoat": 0.92}
		"limbal_dark":       return {"mode": "char_pbr", "kind": "eye", "tint": Color("#141216"), "rough": 0.10, "spec_val": 0.88, "clearcoat": 0.95}
		"eye_glint":         return {"mode": "char_pbr", "kind": "eye", "tint": Color("#ffffff"), "rough": 0.05, "spec_val": 1.0, "clearcoat": 1.0}
		"glass_frame":       return {"mode": "char_pbr", "kind": "metal", "tint": Color("#282320"), "rough": 0.32, "metal": 0.42, "spec_val": 0.62, "uv": 4.0}

		"suit_navy":         return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#243248"), "rough": 0.86, "spec_val": 0.22, "uv": 7.5, "nscale": 0.46, "rim": 0.11}
		"hoodie_teal":       return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#2a5f6f"), "rough": 0.88, "spec_val": 0.20, "uv": 7.0, "nscale": 0.50, "rim": 0.12}
		"vest_sage":         return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#3b6647"), "rough": 0.86, "spec_val": 0.22, "uv": 7.5, "nscale": 0.48, "rim": 0.12}
		"vest_charcoal":     return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#2b313b"), "rough": 0.85, "spec_val": 0.22, "uv": 7.5, "nscale": 0.48, "rim": 0.11}
		"shirt_ruby":        return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#94302e"), "rough": 0.85, "spec_val": 0.22, "uv": 7.2, "nscale": 0.46, "rim": 0.12}
		"shirt_burgundy":    return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#822b2c"), "rough": 0.86, "spec_val": 0.22, "uv": 7.2, "nscale": 0.48, "rim": 0.12}
		"shirt_ochre":       return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#ba823c"), "rough": 0.87, "spec_val": 0.22, "uv": 7.2, "nscale": 0.48, "rim": 0.12}
		"shirt_oatmeal":     return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#b49a74"), "rough": 0.89, "spec_val": 0.20, "uv": 8.0, "nscale": 0.52, "rim": 0.12}
		"shirt_linen_cream": return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#cec3ae"), "rough": 0.89, "spec_val": 0.20, "uv": 8.0, "nscale": 0.50, "rim": 0.12}
		"shirt_olive_sage":  return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#36593d"), "rough": 0.89, "spec_val": 0.20, "uv": 8.0, "nscale": 0.52, "rim": 0.12}
		"shirt_sky":         return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#4d7094"), "rough": 0.85, "spec_val": 0.24, "uv": 7.5, "nscale": 0.46, "rim": 0.12}
		"shirt_white":       return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#ddd8ce"), "rough": 0.86, "spec_val": 0.22, "uv": 8.0, "nscale": 0.44, "rim": 0.10}
		"apron_white":       return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#e0d9ce"), "rough": 0.87, "spec_val": 0.20, "uv": 7.2, "nscale": 0.52, "rim": 0.12}
		"apron_cream":       return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#dfd5c3"), "rough": 0.87, "spec_val": 0.19, "uv": 7.2, "nscale": 0.54, "rim": 0.12}
		"apron_red":         return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#8c2623"), "rough": 0.88, "spec_val": 0.20, "uv": 7.2, "nscale": 0.54, "rim": 0.12}
		"ribbon_red":        return {"mode": "char_pbr", "kind": "cloth", "tint": Color("#9f302c"), "rough": 0.72, "spec_val": 0.34, "uv": 6.5, "nscale": 0.34, "rim": 0.12}
		"denim":             return {"mode": "char_pbr", "kind": "denim", "tint": Color("#2e4460"), "rough": 0.90, "spec_val": 0.20, "uv": 7.0, "nscale": 0.58, "rim": 0.12}
		"pants_charcoal":    return {"mode": "char_pbr", "kind": "denim", "tint": Color("#262b33"), "rough": 0.88, "spec_val": 0.20, "uv": 7.0, "nscale": 0.54, "rim": 0.10}
		"leather":           return {"mode": "char_pbr", "kind": "leather", "tint": Color("#40271b"), "rough": 0.44, "spec_val": 0.54, "uv": 5.5, "nscale": 0.46}
		"shoe_black":        return {"mode": "char_pbr", "kind": "leather", "tint": Color("#232428"), "rough": 0.42, "spec_val": 0.56, "uv": 5.5, "nscale": 0.42}
		"sneaker_white":     return {"mode": "char_pbr", "kind": "leather", "tint": Color("#d6d2c8"), "rough": 0.58, "spec_val": 0.34, "uv": 5.0, "nscale": 0.28}
		"belt_brass":        return {"mode": "char_pbr", "kind": "metal", "tint": Color("#cfa046"), "rough": 0.28, "metal": 0.86, "spec_val": 0.80, "uv": 4.0}
		"badge_cyan":        return {"mode": "char_pbr", "kind": "eye", "tint": Color("#2cc6e8"), "rough": 0.22, "spec_val": 0.88, "clearcoat": 0.92}
		"gaming_black":      return {"tint": Color("#1d2026"), "rough": 0.44, "metal": 0.25, "spec_val": 0.55}
		"cyan_accent":       return {"tint": Color("#2cc6e8"), "emit": Color("#1aa3c8"), "emit_e": 0.45, "rough": 0.28}
		"white":             return {"tint": Color("#ece8df"), "rough": 0.78, "spec_val": 0.25}

		# Borgo Valdocco, Mercato OGR & Officina Bellini
		"safety_yellow":     return {"mode": "char_pbr", "kind": "metal", "tint": Color("#deb022"), "rough": 0.42, "metal": 0.12, "spec_val": 0.56, "uv": 4.0}
		"metal_panel":       return {"tex": "plaster_rough", "tint": Color("#8b95a3"), "uv": 0.45, "ndepth": 0.90, "rough": 0.44, "metal": 0.55, "spec_val": 0.68}
		"road_line":         return {"tex": "asphalt", "tint": Color("#ecebe4"), "uv": 0.4, "ndepth": 0.4, "rough": 0.84}

		# Interni v1.4, Alimentari Rosa, Pizzeria Da Mario & OGR Enterprise
		"wood_plank":        return {"tex": "planks_light", "tint": Color("#b47d44"), "uv": 0.62, "ndepth": 1.32, "rough": 0.58, "spec_val": 0.40, "ao": 0.94}
		"stone_counter":     return {"tex": "ashlar", "tint": Color("#b5aea2"), "uv": 0.52, "ndepth": 1.42, "rough": 0.72, "spec_val": 0.36, "ao": 0.92}
		"red_table":         return {"tint": Color("#b5342c"), "rough": 0.46, "spec_val": 0.45}
		"ogr_orange":        return {"tint": Color("#ea5c22"), "rough": 0.42, "spec_val": 0.52, "emit": Color("#cc4212"), "emit_e": 0.14}
		"paper_bag":         return {"tex": "burlap", "tint": Color("#c89f6e"), "uv": 1.35, "ndepth": 0.88, "rough": 0.90, "ao": 0.85}
		"jar_jam":           return {"tint": Color("#98222a"), "rough": 0.22, "spec_val": 0.78}
		"jar_green":         return {"tint": Color("#54784a"), "rough": 0.24, "spec_val": 0.72}
		"tin_red":           return {"tint": Color("#c22823"), "rough": 0.34, "metal": 0.35, "spec_val": 0.66}
		"tin_blue":          return {"tint": Color("#2a6792"), "rough": 0.34, "metal": 0.35, "spec_val": 0.66}
		"tin_gold":          return {"tint": Color("#d49b3e"), "rough": 0.30, "metal": 0.42, "spec_val": 0.72}
		"grate_dark":        return {"tex": "tile_check_gray", "tint": Color("#383f48"), "uv": 1.45, "ndepth": 1.55, "metal": 0.68, "rough": 0.50, "spec_val": 0.62, "ao": 0.92}
		"lounge_sofa":       return {"tex": "fabric", "tint": Color("#424852"), "uv": 1.50, "ndepth": 1.05, "rough": 0.88}
		"smoke_soft":        return {"tint": Color("#8c867f"), "rough": 0.96, "macro": 0.08}
		_:                   return {"tint": Color("#cccccc"), "rough": 0.82}
