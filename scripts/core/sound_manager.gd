extends Node
## SoundManager - Centralized audio playback service for SFX, UI, and ambience

var sfx_streams: Dictionary = {}
var ui_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var footstep_player: AudioStreamPlayer

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
	footstep_player.volume_db = -16.0
	add_child(footstep_player)
	
	_load_sound_assets()

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
	var stream_key = "footstep_wood" if surface == "wood" else "footstep_stone"
	if sfx_streams.has(stream_key):
		footstep_player.stream = sfx_streams[stream_key]
		footstep_player.pitch_scale = randf_range(0.92, 1.08)
		footstep_player.play()

func _play_ui(key: String) -> void:
	if sfx_streams.has(key):
		ui_player.stream = sfx_streams[key]
		ui_player.pitch_scale = randf_range(0.97, 1.03)
		ui_player.play()

func start_studio_ambience() -> void:
	if sfx_streams.has("ambient_studio") and not ambient_player.playing:
		ambient_player.stream = sfx_streams["ambient_studio"]
		ambient_player.play()
