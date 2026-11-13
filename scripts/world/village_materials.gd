class_name VillageMaterials
extends RefCounted
## VillageMaterials - Libreria unica di ShaderMaterial "toon dipinto" per il Borgo San Carlo.
## Tutte le superfici usano assets/shaders/toon.gdshader + texture in assets/textures/village/.

const SHADER_PATH := "res://assets/shaders/toon.gdshader"
const TEX_DIR := "res://assets/textures/village/"

static var _shader: Shader = null
static var _cache: Dictionary = {}
static var _tex_cache: Dictionary = {}

static func _get_shader() -> Shader:
	if _shader == null:
		_shader = load(SHADER_PATH)
	return _shader

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
	m.shader = _get_shader()
	m.set_shader_parameter("tint", spec.get("tint", Color.WHITE))
	var tex_name: String = spec.get("tex", "")
	var tex := _get_tex(tex_name)
	if tex != null:
		m.set_shader_parameter("albedo_tex", tex)
		m.set_shader_parameter("use_tex", 1.0)
	else:
		m.set_shader_parameter("use_tex", 0.0)
	m.set_shader_parameter("uv_scale", float(spec.get("uv", 0.35)))
	m.set_shader_parameter("brightness", float(spec.get("bright", 1.0)))
	m.set_shader_parameter("emission_color", spec.get("emit", Color.BLACK))
	m.set_shader_parameter("emission_energy", float(spec.get("emit_e", 0.0)))
	m.set_shader_parameter("shade_floor", float(spec.get("floor", 0.45)))
	m.set_shader_parameter("rim_strength", float(spec.get("rim", 0.16)))
	m.set_shader_parameter("wind_sway", float(spec.get("sway", 0.0)))
	_cache[key] = m
	return m

static func _spec_for(key: String) -> Dictionary:
	match key:
		# Intonaci piemontesi caldi
		"plaster_cream":     return {"tex": "plaster", "tint": Color("#f3e7d3"), "uv": 0.30}
		"plaster_ochre":     return {"tex": "plaster", "tint": Color("#e8b86d"), "uv": 0.30}
		"plaster_terracotta":return {"tex": "plaster", "tint": Color("#d47353"), "uv": 0.30}
		"plaster_sage":      return {"tex": "plaster", "tint": Color("#9ab696"), "uv": 0.30}
		"plaster_rose":      return {"tex": "plaster", "tint": Color("#dfa094"), "uv": 0.30}
		"plaster_sky":       return {"tex": "plaster", "tint": Color("#93b3c9"), "uv": 0.30}
		"plaster_studio":    return {"tex": "plaster", "tint": Color("#ece6da"), "uv": 0.35}
		"plaster_rough":     return {"tex": "plaster_rough", "tint": Color("#ded6c6"), "uv": 0.35}
		# Pietra e mattoni
		"brick":             return {"tex": "brick", "tint": Color.WHITE, "uv": 0.40}
		"ashlar":            return {"tex": "ashlar", "tint": Color("#d8cfc0"), "uv": 0.35}
		"stone_trim":        return {"tex": "ashlar", "tint": Color("#e5dfd2"), "uv": 0.50}
		"cobble":            return {"tex": "cobble", "tint": Color.WHITE, "uv": 0.38}
		"slabs":             return {"tex": "slabs", "tint": Color("#cfc8ba"), "uv": 0.42}
		"asphalt":           return {"tex": "asphalt", "tint": Color.WHITE, "uv": 0.30}
		"gravel":            return {"tex": "gravel", "tint": Color.WHITE, "uv": 0.45}
		"grass":             return {"tex": "grass", "tint": Color.WHITE, "uv": 0.25}
		# Tetti
		"roof_terracotta":   return {"tex": "roof_terracotta", "tint": Color.WHITE, "uv": 0.45}
		"roof_slate":        return {"tex": "roof_slate", "tint": Color.WHITE, "uv": 0.45}
		# Legni e pavimenti interni
		"wood_light":        return {"tex": "planks_light", "tint": Color.WHITE, "uv": 0.50}
		"wood_dark":         return {"tex": "planks_dark", "tint": Color.WHITE, "uv": 0.50}
		"tile_rc":           return {"tex": "tile_check_rc", "tint": Color.WHITE, "uv": 0.65}
		"tile_cafe":         return {"tex": "tile_check_cafe", "tint": Color.WHITE, "uv": 0.65}
		"tile_gray":         return {"tex": "tile_check_gray", "tint": Color.WHITE, "uv": 0.65}
		# Tende
		"awning_red":        return {"tex": "awning_red", "tint": Color.WHITE, "uv": 0.60}
		"awning_green":      return {"tex": "awning_green", "tint": Color.WHITE, "uv": 0.60}
		"awning_blue":       return {"tex": "awning_blue", "tint": Color.WHITE, "uv": 0.60}
		"awning_yellow":     return {"tex": "awning_yellow", "tint": Color.WHITE, "uv": 0.60}
		# Natura
		"leaves":            return {"tex": "leaves", "tint": Color("#74bd4b"), "uv": 0.55, "sway": 0.045, "rim": 0.22}
		"leaves_dark":       return {"tex": "leaves", "tint": Color("#4a8c38"), "uv": 0.55, "sway": 0.03, "rim": 0.20}
		"bark":              return {"tex": "bark", "tint": Color.WHITE, "uv": 0.65}
		# Metalli, vetri, tessuti, luminosi
		"iron":              return {"tint": Color("#2d323a"), "rim": 0.22}
		"brass":             return {"tint": Color("#d6a84c"), "rim": 0.26}
		"steel":             return {"tint": Color("#b4bec7"), "rim": 0.22}
		"glass_warm":        return {"tint": Color("#ffebb8"), "emit": Color("#ffcf78"), "emit_e": 0.55}
		"glass_cool":        return {"tint": Color("#9fd8f5"), "emit": Color("#6cc4ee"), "emit_e": 0.35}
		"water":             return {"tint": Color("#46a8d9"), "emit": Color("#2a82b5"), "emit_e": 0.28, "rim": 0.30}
		"lamp_glow":         return {"tint": Color("#fff2c2"), "emit": Color("#ffd87a"), "emit_e": 1.3}
		"ember_glow":        return {"tint": Color("#ff7a29"), "emit": Color("#ff5511"), "emit_e": 1.6}
		"fabric_blue":       return {"tex": "fabric", "tint": Color("#4a6fa5"), "uv": 1.2}
		"fabric_red":        return {"tex": "fabric", "tint": Color("#c8463e"), "uv": 1.2}
		"fabric_cream":      return {"tex": "fabric", "tint": Color("#f3ead8"), "uv": 1.2}
		"fabric_green":      return {"tex": "fabric", "tint": Color("#4d8a5b"), "uv": 1.2}
		# Auto
		"car_red":           return {"tint": Color("#d4463c"), "rim": 0.25}
		"car_cream":         return {"tint": Color("#efe4c8"), "rim": 0.22}
		"car_sage":          return {"tint": Color("#6d9a7a"), "rim": 0.22}
		"car_blue":          return {"tint": Color("#3f6ea6"), "rim": 0.24}
		"tire":              return {"tint": Color("#222428"), "rim": 0.10}
		# Cibo / frutta
		"bread":             return {"tint": Color("#d9944a")}
		"apple":             return {"tint": Color("#d63a35")}
		"lemon":             return {"tint": Color("#f2cf3d")}
		"orange":            return {"tint": Color("#eb7d23")}
		# Personaggi e accessori
		"skin":              return {"tint": Color("#e0a67c"), "rim": 0.08, "floor": 0.56, "bright": 0.94}
		"skin_warm":         return {"tint": Color("#d19066"), "rim": 0.08, "floor": 0.54, "bright": 0.94}
		"skin_cheek":        return {"tint": Color("#d87b6c"), "rim": 0.04, "floor": 0.56, "bright": 0.95}
		"hair_brown":        return {"tint": Color("#593723"), "rim": 0.14}
		"hair_chestnut":     return {"tint": Color("#754229"), "rim": 0.15}
		"hair_blonde":       return {"tint": Color("#dfa846"), "rim": 0.14}
		"hair_auburn":       return {"tint": Color("#9a4228"), "rim": 0.16}
		"hair_dark":         return {"tint": Color("#242026"), "rim": 0.16}
		"hair_salt":         return {"tint": Color("#6e737b"), "rim": 0.16}
		"eye_white":         return {"tint": Color("#f5f2eb"), "floor": 0.86, "rim": 0.04}
		"iris_brown":        return {"tint": Color("#54331d"), "floor": 0.7}
		"iris_blue":         return {"tint": Color("#2c6cb0"), "floor": 0.7}
		"iris_green":        return {"tint": Color("#2e7d52"), "floor": 0.7}
		"lip_warm":          return {"tint": Color("#b85d52"), "floor": 0.65}
		"suit_navy":         return {"tex": "fabric", "tint": Color("#2d3e58"), "uv": 1.4}
		"hoodie_teal":       return {"tex": "fabric", "tint": Color("#2d6f82"), "uv": 1.4}
		"vest_sage":         return {"tex": "fabric", "tint": Color("#467a54"), "uv": 1.4}
		"vest_charcoal":     return {"tex": "fabric", "tint": Color("#343b46"), "uv": 1.4}
		"shirt_ruby":        return {"tex": "fabric", "tint": Color("#b43b38"), "uv": 1.4}
		"shirt_ochre":       return {"tex": "fabric", "tint": Color("#d4923a"), "uv": 1.4}
		"apron_white":       return {"tex": "fabric", "tint": Color("#ebe7de"), "uv": 1.5}
		"denim":             return {"tex": "fabric", "tint": Color("#354f73"), "uv": 1.4}
		"leather":           return {"tint": Color("#472e21"), "rim": 0.18}
		"sneaker_white":     return {"tint": Color("#e4e0d8"), "rim": 0.12}
		"gaming_black":      return {"tint": Color("#1d2026"), "rim": 0.22, "floor": 0.42}
		"cyan_accent":       return {"tint": Color("#2cc6e8"), "emit": Color("#1aa3c8"), "emit_e": 0.35}
		"white":             return {"tint": Color("#e9e5dc"), "rim": 0.10}
		# Borgo Valdocco & Officina Bellini
		"safety_yellow":     return {"tint": Color("#e8b923"), "rim": 0.20}
		"metal_panel":       return {"tex": "plaster_rough", "tint": Color("#8b95a3"), "uv": 0.45, "rim": 0.24}
		"road_line":         return {"tint": Color("#ecebe4"), "rim": 0.08}
		"wood_mid":          return {"tex": "planks_light", "tint": Color("#b8864b"), "uv": 0.50}
		"copper":            return {"tint": Color("#c8723d"), "rim": 0.25}
		_:                   return {"tint": Color("#cccccc")}
