extends Node
## SoundManager - Centralized audio playback service for SFX, UI, ambience, and 44.1kHz multi-stage Foley

var sfx_streams: Dictionary = {}
var ui_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var footstep_player: AudioStreamPlayer
var footstep_player_alt: AudioStreamPlayer
var foley_player: AudioStreamPlayer

## Passi procedurali organici multi-stadio (tallone + rullata punta + micro-grana materiale) a 44.1 kHz
const FOOTSTEP_SURFACES: Array[String] = ["grass", "stone", "wood", "tile", "asphalt", "metal"]
const FOOTSTEP_VARIANTS: int = 6
const FOOTSTEP_MIX_RATE: int = 44100
var footstep_variants: Dictionary = {}
var land_variants: Dictionary = {}
var jump_stream: AudioStreamWAV = null
var _last_footstep_variant: int = -1
var _use_alt_player: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UIPlayer"
	add_child(ui_player)
	
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.volume_db = -13.0
	add_child(ambient_player)
	
	footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "FootstepPlayer"
	footstep_player.volume_db = -11.5
	add_child(footstep_player)

	footstep_player_alt = AudioStreamPlayer.new()
	footstep_player_alt.name = "FootstepPlayerAlt"
	footstep_player_alt.volume_db = -11.5
	add_child(footstep_player_alt)

	foley_player = AudioStreamPlayer.new()
	foley_player.name = "FoleyPlayer"
	foley_player.volume_db = -10.5
	add_child(foley_player)
	
	_load_sound_assets()
	_generate_footsteps()
	_generate_jump_and_lands()

func _load_sound_assets() -> void:
	var files = {
		"ui_click": "res://assets/audio/ui_click.wav",
		"ui_notification": "res://assets/audio/ui_notification.wav",
		"ui_success": "res://assets/audio/ui_success.wav",
		"cash_register": "res://assets/audio/cash_register.wav",
		"door_open": "res://assets/audio/door_open.wav",
		"keyboard_typing": "res://assets/audio/keyboard_typing.wav",
		"footstep_wood": "res://assets/audio/footstep_wood.wav",
		"footstep_stone": "res://assets/audio/footstep_stone.wav",
		"ambient_studio": "res://assets/audio/ambient_studio.wav"
	}
	
	for key in files:
		var path = files[key]
		if ResourceLoader.exists(path):
			sfx_streams[key] = load(path)

func play_ui_click() -> void:
	_play_ui("ui_click")

func play_ui_notification() -> void:
	_play_ui("ui_notification")

func play_ui_success() -> void:
	_play_ui("ui_success")

func play_ui_error() -> void:
	_play_ui("ui_notification")

func play_cash_register() -> void:
	_play_ui("cash_register")

func play_door_sound() -> void:
	_play_ui("door_open")

func play_keyboard_sound() -> void:
	_play_ui("keyboard_typing")

func play_footstep(surface: String, is_sprinting: bool = false, left_foot: bool = true) -> void:
	var key = surface if footstep_variants.has(surface) else "stone"
	if footstep_variants.has(key):
		var variants: Array = footstep_variants[key]
		var idx = randi() % variants.size()
		if variants.size() > 1 and idx == _last_footstep_variant:
			idx = (idx + 1) % variants.size()
		_last_footstep_variant = idx
		var player: AudioStreamPlayer = footstep_player_alt if _use_alt_player else footstep_player
		_use_alt_player = not _use_alt_player
		player.stream = variants[idx]
		var foot_bias: float = -0.025 if left_foot else 0.025
		var sprint_pitch: float = 0.05 if is_sprinting else 0.0
		player.pitch_scale = randf_range(0.95, 1.05) + foot_bias + sprint_pitch
		var base_db: float = -8.5 if is_sprinting else -11.5
		player.volume_db = base_db + randf_range(-1.0, 0.8) + (0.4 if not left_foot else -0.4)
		player.play()
		return
	var stream_key = "footstep_wood" if surface == "wood" else "footstep_stone"
	if sfx_streams.has(stream_key):
		footstep_player.stream = sfx_streams[stream_key]
		footstep_player.pitch_scale = randf_range(0.92, 1.08)
		footstep_player.play()

func play_jump() -> void:
	if jump_stream == null:
		return
	foley_player.stream = jump_stream
	foley_player.pitch_scale = randf_range(0.96, 1.05)
	foley_player.volume_db = -14.0
	foley_player.play()

func play_land(surface: String, impact_speed: float = 4.0) -> void:
	var key = surface if land_variants.has(surface) else "stone"
	if not land_variants.has(key):
		return
	foley_player.stream = land_variants[key]
	var strength: float = clampf((impact_speed - 1.5) / 6.0, 0.0, 1.0)
	foley_player.pitch_scale = randf_range(0.94, 1.03)
	foley_player.volume_db = lerpf(-13.5, -5.5, strength)
	foley_player.play()

## Parametri fisici per superficie (zero sinusoidi pure: solo impulsi filtrati, risonatori Biquad smorzati e micro-grana)
func _footstep_params(surface: String) -> Dictionary:
	match surface:
		"grass":
			return {
				"dur": 0.24, "heel_rise": 0.018, "heel_decay": 0.042, "toe_delay": 0.052, "toe_rise": 0.020, "toe_decay": 0.048,
				"sub_hz": 180.0, "sub_gain": 0.28, "body_hz": 420.0, "body_q": 0.9, "body_gain": 0.35,
				"scuff_lo": 1400.0, "scuff_hi": 4200.0, "scuff_gain": 0.68,
				"grain_count": 7, "grain_hz": 3600.0, "grain_gain": 0.28, "rms_target": 0.115
			}
		"wood":
			return {
				"dur": 0.19, "heel_rise": 0.004, "heel_decay": 0.024, "toe_delay": 0.044, "toe_rise": 0.008, "toe_decay": 0.026,
				"sub_hz": 125.0, "sub_gain": 0.58, "body_hz": 240.0, "body_q": 2.3, "body_gain": 0.52,
				"scuff_lo": 700.0, "scuff_hi": 2300.0, "scuff_gain": 0.38,
				"grain_count": 1, "grain_hz": 1800.0, "grain_gain": 0.10, "rms_target": 0.130
			}
		"tile":
			return {
				"dur": 0.15, "heel_rise": 0.0025, "heel_decay": 0.015, "toe_delay": 0.036, "toe_rise": 0.006, "toe_decay": 0.018,
				"sub_hz": 150.0, "sub_gain": 0.36, "body_hz": 680.0, "body_q": 1.6, "body_gain": 0.42,
				"scuff_lo": 1250.0, "scuff_hi": 3900.0, "scuff_gain": 0.62,
				"grain_count": 2, "grain_hz": 3100.0, "grain_gain": 0.22, "rms_target": 0.120
			}
		"asphalt":
			return {
				"dur": 0.18, "heel_rise": 0.0035, "heel_decay": 0.020, "toe_delay": 0.042, "toe_rise": 0.009, "toe_decay": 0.028,
				"sub_hz": 135.0, "sub_gain": 0.52, "body_hz": 440.0, "body_q": 1.1, "body_gain": 0.36,
				"scuff_lo": 1000.0, "scuff_hi": 3300.0, "scuff_gain": 0.56,
				"grain_count": 4, "grain_hz": 2900.0, "grain_gain": 0.32, "rms_target": 0.130
			}
		"metal":
			return {
				"dur": 0.18, "heel_rise": 0.002, "heel_decay": 0.014, "toe_delay": 0.038, "toe_rise": 0.005, "toe_decay": 0.020,
				"sub_hz": 165.0, "sub_gain": 0.35, "body_hz": 340.0, "body_q": 3.4, "body_gain": 0.44,
				"scuff_lo": 1500.0, "scuff_hi": 4600.0, "scuff_gain": 0.58,
				"grain_count": 2, "grain_hz": 3800.0, "grain_gain": 0.24, "rms_target": 0.120
			}
		_: # stone (porfido/acciottolato Torino)
			return {
				"dur": 0.18, "heel_rise": 0.003, "heel_decay": 0.018, "toe_delay": 0.040, "toe_rise": 0.008, "toe_decay": 0.024,
				"sub_hz": 145.0, "sub_gain": 0.46, "body_hz": 520.0, "body_q": 1.3, "body_gain": 0.40,
				"scuff_lo": 1150.0, "scuff_hi": 3700.0, "scuff_gain": 0.60,
				"grain_count": 5, "grain_hz": 3400.0, "grain_gain": 0.36, "rms_target": 0.128
			}

func _generate_footsteps() -> void:
	footstep_variants.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = 9021044
	for surface in FOOTSTEP_SURFACES:
		var list: Array = []
		for _v in range(FOOTSTEP_VARIANTS):
			list.append(_make_footstep(surface, rng))
		footstep_variants[surface] = list

func _generate_jump_and_lands() -> void:
	land_variants.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = 4410088
	for surface in FOOTSTEP_SURFACES:
		land_variants[surface] = _make_land_sound(surface, rng)
	jump_stream = _make_jump_sound(rng)

func _make_footstep(surface: String, rng: RandomNumberGenerator) -> AudioStreamWAV:
	var p = _footstep_params(surface)
	var rate: float = float(FOOTSTEP_MIX_RATE)
	var dur: float = float(p["dur"]) * rng.randf_range(0.93, 1.07)
	var n: int = int(dur * rate)

	var heel_rise: float = float(p["heel_rise"]) * rng.randf_range(0.85, 1.20)
	var heel_decay: float = float(p["heel_decay"]) * rng.randf_range(0.88, 1.15)
	var toe_delay: float = float(p["toe_delay"]) * rng.randf_range(0.88, 1.15)
	var toe_rise: float = float(p["toe_rise"]) * rng.randf_range(0.85, 1.20)
	var toe_decay: float = float(p["toe_decay"]) * rng.randf_range(0.88, 1.15)

	# Filtro Sub-Lowpass (peso corporeo suolo, zero oscillatore tonale)
	var sub_alpha: float = 1.0 - exp(-TAU * (float(p["sub_hz"]) * rng.randf_range(0.90, 1.10)) / rate)
	# Risonatore bandpass 2° ordine (State-Variable Filter semplificato per timbro legno/pietra/piastrella)
	var body_fc: float = float(p["body_hz"]) * rng.randf_range(0.92, 1.08)
	var body_f: float = clampf(2.0 * sin(PI * body_fc / rate), 0.001, 0.85)
	var body_d: float = clampf(1.0 / float(p["body_q"]), 0.08, 1.4)
	# Bandpass Scuff (attrito suola tra scuff_lo e scuff_hi)
	var hp_alpha: float = exp(-TAU * (float(p["scuff_lo"]) * rng.randf_range(0.92, 1.08)) / rate)
	var lp_alpha: float = 1.0 - exp(-TAU * (float(p["scuff_hi"]) * rng.randf_range(0.92, 1.08)) / rate)
	# Highpass grana ghiaia/foglie
	var gr_alpha: float = exp(-TAU * float(p["grain_hz"]) / rate)

	var grain_count: int = int(p["grain_count"])
	var grain_times: Array[float] = []
	var grain_amps: Array[float] = []
	for _g in range(grain_count):
		grain_times.append(rng.randf_range(0.008, dur * 0.62))
		grain_amps.append(rng.randf_range(0.45, 1.15))

	var sub_lp1: float = 0.0
	var sub_lp2: float = 0.0
	var svf_lp: float = 0.0
	var svf_bp: float = 0.0
	var prev_w: float = 0.0
	var scuff_hp: float = 0.0
	var scuff_lp: float = 0.0
	var gr_hp: float = 0.0
	var prev_wg: float = 0.0

	var samples := PackedFloat32Array()
	samples.resize(n)
	var sum_sq: float = 0.0

	for i in range(n):
		var t: float = float(i) / rate
		var env_heel: float = minf(t / maxf(heel_rise, 0.001), 1.0) * exp(-t / maxf(heel_decay, 0.005))
		var t_toe: float = t - toe_delay
		var env_toe: float = 0.0
		if t_toe > 0.0:
			env_toe = minf(t_toe / maxf(toe_rise, 0.001), 1.0) * exp(-t_toe / maxf(toe_decay, 0.005))
		var drive_env: float = env_heel + 0.65 * env_toe

		var w1: float = rng.randf_range(-1.0, 1.0)
		var w2: float = rng.randf_range(-1.0, 1.0)

		# 1. Sub thud noise (filtrato a doppio polo LP -> impulso soffice di scarpa senza alcuna nota tonale)
		sub_lp1 += sub_alpha * (w1 - sub_lp1)
		sub_lp2 += sub_alpha * (sub_lp1 - sub_lp2)
		var sub_comp: float = sub_lp2 * 4.2 * float(p["sub_gain"]) * (env_heel + 0.35 * env_toe)

		# 2. Body SVF resonance (cassa armonica pavimento / legno / lamiera)
		var svf_in: float = w1 * (env_heel * 0.9 + env_toe * 0.45)
		var svf_hp: float = svf_in - svf_lp - body_d * svf_bp
		svf_bp += body_f * svf_hp
		svf_lp += body_f * svf_bp
		var body_comp: float = svf_bp * float(p["body_gain"]) * 1.4

		# 3. Scuff bandpass (sfregamento gomma/tomaia su rullata punta)
		scuff_hp = hp_alpha * (scuff_hp + w2 - prev_w)
		prev_w = w2
		scuff_lp += lp_alpha * (scuff_hp - scuff_lp)
		var scuff_comp: float = scuff_lp * float(p["scuff_gain"]) * (0.45 * env_heel + 0.95 * env_toe)

		# 4. Surface micro-grains (granelli di ghiaia/sassolini/fili d'erba)
		gr_hp = gr_alpha * (gr_hp + w1 - prev_wg)
		prev_wg = w1
		var grain_env: float = 0.0
		for gi in range(grain_count):
			var dt: float = t - grain_times[gi]
			if absf(dt) < 0.008:
				grain_env += grain_amps[gi] * exp(-(dt * dt) / 0.0000032)
		var grain_comp: float = gr_hp * float(p["grain_gain"]) * grain_env

		var sample: float = (sub_comp + body_comp + scuff_comp + grain_comp) * clampf(drive_env + 0.15, 0.0, 1.4)
		samples[i] = sample
		sum_sq += sample * sample

	return _finalize_wav(samples, n, sum_sq, float(p["rms_target"]), 0.002, 0.014)

func _make_land_sound(surface: String, rng: RandomNumberGenerator) -> AudioStreamWAV:
	var p = _footstep_params(surface)
	var rate: float = float(FOOTSTEP_MIX_RATE)
	var dur: float = 0.24
	var n: int = int(dur * rate)
	var sub_alpha: float = 1.0 - exp(-TAU * (float(p["sub_hz"]) * 0.82) / rate)
	var scuff_alpha: float = 1.0 - exp(-TAU * 1800.0 / rate)
	var lp1: float = 0.0
	var lp2: float = 0.0
	var slp: float = 0.0
	var samples := PackedFloat32Array()
	samples.resize(n)
	var sum_sq: float = 0.0

	for i in range(n):
		var t: float = float(i) / rate
		# Doppio appoggio quasi simultaneo + compressione caviglia
		var env1: float = minf(t / 0.003, 1.0) * exp(-t / 0.028)
		var t2: float = maxf(0.0, t - 0.018)
		var env2: float = (minf(t2 / 0.005, 1.0) * exp(-t2 / 0.036)) if t > 0.018 else 0.0
		var w1: float = rng.randf_range(-1.0, 1.0)
		var w2: float = rng.randf_range(-1.0, 1.0)
		lp1 += sub_alpha * (w1 - lp1)
		lp2 += sub_alpha * (lp1 - lp2)
		slp += scuff_alpha * (w2 - slp)
		var s: float = (lp2 * 4.5 + slp * 0.45 * float(p["scuff_gain"])) * (env1 + 0.7 * env2)
		samples[i] = s
		sum_sq += s * s

	return _finalize_wav(samples, n, sum_sq, float(p["rms_target"]) * 1.15, 0.002, 0.018)

func _make_jump_sound(rng: RandomNumberGenerator) -> AudioStreamWAV:
	var rate: float = float(FOOTSTEP_MIX_RATE)
	var dur: float = 0.14
	var n: int = int(dur * rate)
	var hp_a: float = exp(-TAU * 750.0 / rate)
	var lp_a: float = 1.0 - exp(-TAU * 2800.0 / rate)
	var hp: float = 0.0
	var lp: float = 0.0
	var prev: float = 0.0
	var samples := PackedFloat32Array()
	samples.resize(n)
	var sum_sq: float = 0.0
	for i in range(n):
		var t: float = float(i) / rate
		var env: float = minf(t / 0.012, 1.0) * exp(-t / 0.032)
		var w: float = rng.randf_range(-1.0, 1.0)
		hp = hp_a * (hp + w - prev)
		prev = w
		lp += lp_a * (hp - lp)
		var s: float = lp * env
		samples[i] = s
		sum_sq += s * s
	return _finalize_wav(samples, n, sum_sq, 0.09, 0.003, 0.015)

func _finalize_wav(samples: PackedFloat32Array, n: int, sum_sq: float, rms_target: float, fade_in_s: float, fade_out_s: float) -> AudioStreamWAV:
	var rms: float = sqrt(sum_sq / maxf(float(n), 1.0))
	var gain: float = rms_target / maxf(rms, 0.0001)
	var fade_in_n: int = maxi(1, int(fade_in_s * float(FOOTSTEP_MIX_RATE)))
	var fade_out_n: int = maxi(1, int(fade_out_s * float(FOOTSTEP_MIX_RATE)))
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var s: float = tanh(samples[i] * gain * 1.15) * 0.82
		if i < fade_in_n:
			s *= float(i) / float(fade_in_n)
		if i > n - fade_out_n:
			s *= float(n - i) / float(fade_out_n)
		var iv: int = clampi(int(s * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, iv)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = FOOTSTEP_MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav

func _play_ui(key: String) -> void:
	if sfx_streams.has(key):
		ui_player.stream = sfx_streams[key]
		ui_player.pitch_scale = randf_range(0.97, 1.03)
		ui_player.play()

func start_studio_ambience() -> void:
	if sfx_streams.has("ambient_studio") and not ambient_player.playing:
		ambient_player.stream = sfx_streams["ambient_studio"]
		ambient_player.play()
