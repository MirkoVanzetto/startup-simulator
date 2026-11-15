class_name DayNightController
extends Node
## DayNightController - Ciclo giorno/notte continuo legato a CalendarSystem.
## Regola inclinazione solare, cielo stellato/luna in sky_torino.gdshader, nebbia e lampioni stradali.

@export var debug_override_hour: float = -1.0 # < 0 segue CalendarSystem reale

var _sun: DirectionalLight3D = null
var _world_env: WorldEnvironment = null
var _sky_mat: ShaderMaterial = null
var _last_applied_hour: float = -99.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_bind_scene_nodes")

func _bind_scene_nodes() -> void:
	var parent := get_parent()
	if parent == null:
		return
	_sun = parent.get_node_or_null("SunLight") as DirectionalLight3D
	_world_env = parent.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if _world_env and _world_env.environment and _world_env.environment.sky:
		_sky_mat = _world_env.environment.sky.sky_material as ShaderMaterial
	apply_hour(get_effective_hour())

func get_effective_hour() -> float:
	if debug_override_hour >= 0.0:
		return fposmod(debug_override_hour, 24.0)
	if is_instance_valid(CalendarSystem):
		var sub_min := clampf(CalendarSystem.time_accumulator, 0.0, 0.999)
		return fposmod(float(CalendarSystem.current_hour) + (float(CalendarSystem.current_minute) + sub_min) / 60.0, 24.0)
	return 9.0

func set_debug_hour(hour_f: float) -> void:
	debug_override_hour = hour_f
	if _sun == null or _world_env == null:
		_bind_scene_nodes()
	apply_hour(get_effective_hour())

func clear_debug_hour() -> void:
	debug_override_hour = -1.0
	apply_hour(get_effective_hour())

func _process(_delta: float) -> void:
	var h := get_effective_hour()
	if absf(h - _last_applied_hour) >= 0.008:
		apply_hour(h)

func apply_hour(hour_f: float) -> void:
	_last_applied_hour = hour_f
	if _sun == null or _world_env == null:
		_bind_scene_nodes()
	if _sun == null or _world_env == null or _world_env.environment == null:
		return

	# Keyframes atmosferici (09:00 preserva perfettamente il look nitido di default!)
	# 00:00 notte | 05:30 pre-alba | 07:00 alba | 09:00 mattino | 13:00 mezzogiorno | 18:15 tramonto | 20:00 crepuscolo | 22:00 notte
	var sky_top := Color(0.22, 0.48, 0.80)
	var sky_mid := Color(0.48, 0.72, 0.93)
	var sky_hor := Color(0.84, 0.90, 0.95)
	var sun_haze := Color(1.00, 0.92, 0.78)
	var fog_col := Color(0.76, 0.85, 0.94)
	var sun_col := Color(1.00, 0.95, 0.87)
	var sun_energy := 1.25
	var amb_sky := 0.62
	var amb_col := Color(0.74, 0.78, 0.82)
	var night_factor := 0.0
	var sunset_factor := 0.0
	var lamp_energy := 0.0
	var fog_density := 0.0038
	var exposure := 1.04

	if hour_f >= 20.0 or hour_f < 5.2:
		# Notte stellata torinese con luna alta
		var nt := 1.0
		if hour_f >= 20.0 and hour_f < 21.3:
			nt = smoothstep(20.0, 21.3, hour_f)
		elif hour_f >= 4.2 and hour_f < 5.2:
			nt = 1.0 - smoothstep(4.2, 5.2, hour_f)
		night_factor = lerpf(0.55, 1.0, nt)
		sunset_factor = lerpf(0.35, 0.0, nt)
		sky_top = Color(0.22, 0.48, 0.80).lerp(Color(0.025, 0.045, 0.11), night_factor)
		sky_mid = Color(0.48, 0.72, 0.93).lerp(Color(0.055, 0.095, 0.21), night_factor)
		sky_hor = Color(0.84, 0.90, 0.95).lerp(Color(0.11, 0.16, 0.29), night_factor)
		sun_haze = Color(0.36, 0.48, 0.72)
		fog_col = Color(0.07, 0.11, 0.20)
		sun_col = Color(0.48, 0.62, 0.88)
		sun_energy = lerpf(0.42, 0.28, nt)
		amb_sky = lerpf(0.40, 0.26, nt)
		amb_col = Color(0.20, 0.26, 0.40)
		lamp_energy = lerpf(2.2, 3.2, nt)
		fog_density = 0.0048
		exposure = 1.08
	elif hour_f >= 5.2 and hour_f < 8.5:
		# Alba rosa-oro sulle Alpi
		var t := clampf((hour_f - 5.2) / 3.3, 0.0, 1.0)
		var dawn_peak := sin(t * PI)
		sunset_factor = dawn_peak * 0.88
		night_factor = (1.0 - smoothstep(5.2, 6.8, hour_f)) * 0.55
		sky_top = Color(0.09, 0.16, 0.34).lerp(Color(0.22, 0.48, 0.80), smoothstep(0.0, 0.9, t))
		sky_mid = Color(0.34, 0.38, 0.56).lerp(Color(0.48, 0.72, 0.93), smoothstep(0.15, 1.0, t))
		sky_hor = Color(0.95, 0.64, 0.46).lerp(Color(0.84, 0.90, 0.95), smoothstep(0.25, 1.0, t))
		sun_haze = Color(1.00, 0.66, 0.38).lerp(Color(1.00, 0.92, 0.78), t)
		fog_col = Color(0.68, 0.60, 0.64).lerp(Color(0.76, 0.85, 0.94), t)
		sun_col = Color(1.00, 0.72, 0.48).lerp(Color(1.00, 0.95, 0.87), t)
		sun_energy = lerpf(0.48, 1.25, smoothstep(0.0, 1.0, t))
		amb_sky = lerpf(0.34, 0.62, t)
		amb_col = Color(0.46, 0.42, 0.52).lerp(Color(0.74, 0.78, 0.82), t)
		lamp_energy = lerpf(2.2, 0.05, smoothstep(0.1, 0.75, t))
		fog_density = lerpf(0.0046, 0.0038, t)
	elif hour_f >= 8.5 and hour_f < 16.8:
		# Giorno limpido torinese (09:00 = esattamente parametro base)
		var peak := sin(clampf((hour_f - 8.5) / 8.3, 0.0, 1.0) * PI)
		sun_energy = 1.25 + peak * 0.14
		amb_sky = 0.62 + peak * 0.06
		lamp_energy = 0.0
	else:
		# 16:48 -> 20:00 Tramonto dorato e crepuscolo blu
		var t := clampf((hour_f - 16.8) / 3.2, 0.0, 1.0)
		sunset_factor = sin(clampf(t * 1.15, 0.0, 1.0) * PI) * 0.95
		night_factor = smoothstep(18.6, 20.0, hour_f) * 0.62
		sky_top = Color(0.22, 0.48, 0.80).lerp(Color(0.11, 0.16, 0.36), smoothstep(0.25, 1.0, t))
		sky_mid = Color(0.48, 0.72, 0.93).lerp(Color(0.26, 0.28, 0.48), smoothstep(0.35, 1.0, t))
		sky_hor = Color(0.84, 0.90, 0.95).lerp(Color(0.95, 0.52, 0.32), smoothstep(0.0, 0.65, t)).lerp(Color(0.19, 0.22, 0.36), smoothstep(0.62, 1.0, t))
		sun_haze = Color(1.00, 0.60, 0.28).lerp(Color(0.54, 0.38, 0.56), smoothstep(0.65, 1.0, t))
		fog_col = Color(0.76, 0.85, 0.94).lerp(Color(0.86, 0.58, 0.46), smoothstep(0.0, 0.6, t)).lerp(Color(0.14, 0.18, 0.30), smoothstep(0.60, 1.0, t))
		sun_col = Color(1.00, 0.95, 0.87).lerp(Color(1.00, 0.62, 0.34), smoothstep(0.0, 0.7, t)).lerp(Color(0.55, 0.64, 0.85), smoothstep(0.72, 1.0, t))
		sun_energy = lerpf(1.25, 0.42, smoothstep(0.1, 1.0, t))
		amb_sky = lerpf(0.62, 0.38, smoothstep(0.2, 1.0, t))
		amb_col = Color(0.74, 0.78, 0.82).lerp(Color(0.68, 0.52, 0.48), smoothstep(0.0, 0.6, t)).lerp(Color(0.26, 0.31, 0.48), smoothstep(0.65, 1.0, t))
		lamp_energy = lerpf(0.0, 2.35, smoothstep(0.35, 0.95, t))
		fog_density = lerpf(0.0038, 0.0046, smoothstep(0.4, 1.0, t))

	# Applica inclinazione solare (alle 09:00 ≈ -45° con orientamento originale limpido)
	var pitch_deg := -45.0
	var yaw_deg := 30.0
	if hour_f >= 5.2 and hour_f <= 20.0:
		var day_t := clampf((hour_f - 5.2) / 14.8, 0.0, 1.0)
		var elev := lerpf(14.0, 62.0, sin(day_t * PI))
		pitch_deg = -elev
		yaw_deg = lerpf(62.0, -58.0, day_t)
	else:
		# Luce lunare dolce dall'angolo opposto
		pitch_deg = -36.0
		yaw_deg = -142.0

	_sun.rotation_degrees = Vector3(pitch_deg, yaw_deg, 0.0)
	_sun.light_color = sun_col
	_sun.light_energy = sun_energy

	var env := _world_env.environment
	env.ambient_light_color = amb_col
	env.ambient_light_sky_contribution = amb_sky
	env.fog_light_color = fog_col
	env.fog_density = fog_density
	env.tonemap_exposure = exposure

	if _sky_mat:
		_sky_mat.set_shader_parameter("sky_top", sky_top)
		_sky_mat.set_shader_parameter("sky_mid", sky_mid)
		_sky_mat.set_shader_parameter("sky_horizon", sky_hor)
		_sky_mat.set_shader_parameter("sun_haze_color", sun_haze)
		_sky_mat.set_shader_parameter("night_factor", night_factor)
		_sky_mat.set_shader_parameter("sunset_factor", sunset_factor)

	if is_inside_tree():
		for lamp_node in get_tree().get_nodes_in_group("day_night_lamp"):
			if lamp_node is OmniLight3D:
				lamp_node.light_energy = lamp_energy
