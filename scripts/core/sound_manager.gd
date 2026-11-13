extends Node
## SoundManager - Centralized audio playback service for SFX, UI, and ambience

var sfx_streams: Dictionary = {}
var ui_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var footstep_player: AudioStreamPlayer

## Passi procedurali morbidi: surface -> Array[AudioStreamWAV] (varianti)
const FOOTSTEP_SURFACES: Array[String] = ["grass", "stone", "wood", "tile", "asphalt"]
const FOOTSTEP_VARIANTS: int = 3
const FOOTSTEP_MIX_RATE: int = 22050
var footstep_variants: Dictionary = {}
var _last_footstep_variant: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UIPlayer"
	add_child(ui_player)
	
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.volume_db = -12.0
	add_child(ambient_player)
	
	footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "FootstepPlayer"
	footstep_player.volume_db = -22.0
	add_child(footstep_player)
	
	_load_sound_assets()
	_generate_footsteps()

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

func play_footstep(surface: String) -> void:
	# Passi morbidi generati proceduralmente (rumore filtrato + thump); fallback sui wav esistenti
	var key = surface if footstep_variants.has(surface) else "stone"
	if footstep_variants.has(key):
		var variants: Array = footstep_variants[key]
		var idx = randi() % variants.size()
		if variants.size() > 1 and idx == _last_footstep_variant:
			idx = (idx + 1) % variants.size()
		_last_footstep_variant = idx
		footstep_player.stream = variants[idx]
		footstep_player.pitch_scale = randf_range(0.94, 1.06)
		footstep_player.play()
		return
	var stream_key = "footstep_wood" if surface == "wood" else "footstep_stone"
	if sfx_streams.has(stream_key):
		footstep_player.stream = sfx_streams[stream_key]
		footstep_player.pitch_scale = randf_range(0.92, 1.08)
		footstep_player.play()

## Parametri per superficie: durata (s), cutoff lowpass (Hz), decadimento (s), attacco (s), ampiezza rumore, freq thump (Hz), ampiezza thump
func _footstep_params(surface: String) -> Dictionary:
	match surface:
		"grass":
			return {"dur": 0.20, "cutoff": 1500.0, "decay": 0.075, "attack": 0.022, "noise": 0.55, "thump_hz": 0.0, "thump": 0.0}
		"wood":
			return {"dur": 0.16, "cutoff": 900.0, "decay": 0.045, "attack": 0.006, "noise": 0.35, "thump_hz": 150.0, "thump": 0.55}
		"tile":
			return {"dur": 0.14, "cutoff": 2600.0, "decay": 0.030, "attack": 0.004, "noise": 0.45, "thump_hz": 210.0, "thump": 0.30}
		"asphalt":
			return {"dur": 0.15, "cutoff": 800.0, "decay": 0.040, "attack": 0.007, "noise": 0.45, "thump_hz": 110.0, "thump": 0.45}
		_: # stone
			return {"dur": 0.15, "cutoff": 1700.0, "decay": 0.035, "attack": 0.005, "noise": 0.50, "thump_hz": 130.0, "thump": 0.40}

func _generate_footsteps() -> void:
	footstep_variants.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = 90210
	for surface in FOOTSTEP_SURFACES:
		var list: Array = []
		for v in range(FOOTSTEP_VARIANTS):
			list.append(_make_footstep(surface, rng))
		footstep_variants[surface] = list

func _make_footstep(surface: String, rng: RandomNumberGenerator) -> AudioStreamWAV:
	var p = _footstep_params(surface)
	var n = int(float(p["dur"]) * FOOTSTEP_MIX_RATE)
	var data = PackedByteArray()
	data.resize(n * 2)
	# Lowpass a un polo (due passate per un suono più "ovattato")
	var alpha = 1.0 - exp(-TAU * float(p["cutoff"]) / FOOTSTEP_MIX_RATE)
	var lp1 = 0.0
	var lp2 = 0.0
	var thump_hz = float(p["thump_hz"]) * rng.randf_range(0.92, 1.08)
	var peak = 0.0
	var samples = PackedFloat32Array()
	samples.resize(n)
	for i in range(n):
		var t = float(i) / FOOTSTEP_MIX_RATE
		var env = minf(t / float(p["attack"]), 1.0) * exp(-t / float(p["decay"]))
		lp1 += alpha * (rng.randf_range(-1.0, 1.0) - lp1)
		lp2 += alpha * (lp1 - lp2)
		var s = lp2 * 3.0 * float(p["noise"]) * env
		if thump_hz > 0.0:
			s += sin(TAU * thump_hz * t) * float(p["thump"]) * exp(-t / (float(p["decay"]) * 1.2)) * minf(t / 0.004, 1.0)
		samples[i] = s
		peak = maxf(peak, absf(s))
	# Normalizza a un picco basso e dolce + fade-out finale per evitare click
	var gain = 0.55 / maxf(peak, 0.0001)
	var fade_n = int(0.01 * FOOTSTEP_MIX_RATE)
	for i in range(n):
		var s2 = samples[i] * gain
		if i > n - fade_n:
			s2 *= float(n - i) / float(fade_n)
		var iv = clampi(int(s2 * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, iv)
	var wav = AudioStreamWAV.new()
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
