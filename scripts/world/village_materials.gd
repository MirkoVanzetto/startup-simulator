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

static func clear_cache() -> void:
	_cache.clear()

static func mat(key: String) -> ShaderMaterial:
	if _cache.has(key):
		return _cache[key]
	var spec := _spec_for(key)
	var m := ShaderMaterial.new()
	var mode: String = str(spec.get("mode", "pbr"))

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

		# Personaggi (ombreggiatura morbida organica PBR + trama tessuti)
		"skin":              return {"tint": Color("#e2ad84"), "rough": 0.64, "spec_val": 0.26, "grain": 0.004, "macro": 0.02}
		"skin_warm":         return {"tint": Color("#d19268"), "rough": 0.64, "spec_val": 0.26, "grain": 0.004, "macro": 0.02}
		"skin_cheek":        return {"tint": Color("#db8274"), "rough": 0.66, "spec_val": 0.22, "grain": 0.004}
		"hair_brown":        return {"tint": Color("#543320"), "rough": 0.60, "spec_val": 0.34, "grain": 0.01}
		"hair_chestnut":     return {"tint": Color("#703e26"), "rough": 0.58, "spec_val": 0.36, "grain": 0.01}
		"hair_blonde":       return {"tint": Color("#d8a346"), "rough": 0.56, "spec_val": 0.38, "grain": 0.01}
		"hair_auburn":       return {"tint": Color("#943f26"), "rough": 0.58, "spec_val": 0.36, "grain": 0.01}
		"hair_dark":         return {"tint": Color("#211e24"), "rough": 0.55, "spec_val": 0.38, "grain": 0.008}
		"hair_salt":         return {"tint": Color("#6d727b"), "rough": 0.62, "spec_val": 0.30, "grain": 0.01}
		"eye_white":         return {"tint": Color("#f6f4ef"), "rough": 0.24, "spec_val": 0.62, "grain": 0.0}
		"iris_brown":        return {"tint": Color("#4d2e19"), "rough": 0.20, "spec_val": 0.68, "grain": 0.0}
		"iris_blue":         return {"tint": Color("#2966a8"), "rough": 0.20, "spec_val": 0.68, "grain": 0.0}
		"iris_green":        return {"tint": Color("#2a754c"), "rough": 0.20, "spec_val": 0.68, "grain": 0.0}
		"lip_warm":          return {"tint": Color("#b45c52"), "rough": 0.52, "spec_val": 0.32, "grain": 0.0}

		"suit_navy":         return {"tex": "fabric", "tint": Color("#2c3d56"), "uv": 1.5, "ndepth": 0.90, "rough": 0.84}
		"hoodie_teal":       return {"tex": "fabric", "tint": Color("#2d6e80"), "uv": 1.5, "ndepth": 0.90, "rough": 0.86}
		"vest_sage":         return {"tex": "fabric", "tint": Color("#447751"), "uv": 1.5, "ndepth": 0.90, "rough": 0.86}
		"vest_charcoal":     return {"tex": "fabric", "tint": Color("#323944"), "uv": 1.5, "ndepth": 0.90, "rough": 0.84}
		"shirt_ruby":        return {"tex": "fabric", "tint": Color("#b03a37"), "uv": 1.5, "ndepth": 0.90, "rough": 0.84}
		"shirt_ochre":       return {"tex": "fabric", "tint": Color("#d0903a"), "uv": 1.5, "ndepth": 0.90, "rough": 0.85}
		"apron_white":       return {"tex": "fabric", "tint": Color("#ebe7de"), "uv": 1.6, "ndepth": 0.85, "rough": 0.88}
		"denim":             return {"tex": "fabric", "tint": Color("#344e70"), "uv": 1.6, "ndepth": 1.15, "rough": 0.90}
		"leather":           return {"tint": Color("#422a1e"), "rough": 0.48, "spec_val": 0.45}
		"sneaker_white":     return {"tint": Color("#e5e1d9"), "rough": 0.62, "spec_val": 0.32}
		"gaming_black":      return {"tint": Color("#1d2026"), "rough": 0.44, "metal": 0.25, "spec_val": 0.55}
		"cyan_accent":       return {"tint": Color("#2cc6e8"), "emit": Color("#1aa3c8"), "emit_e": 0.45, "rough": 0.28}
		"white":             return {"tint": Color("#ece8df"), "rough": 0.78, "spec_val": 0.25}

		# Borgo Valdocco, Mercato OGR & Officina Bellini
		"safety_yellow":     return {"tint": Color("#deb022"), "rough": 0.46, "metal": 0.15, "spec_val": 0.52}
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
		"limbal_dark":       return {"tint": Color("#171519"), "rough": 0.25, "spec_val": 0.55}
		_:                   return {"tint": Color("#cccccc"), "rough": 0.82}
