extends Control
## MainMenu - Main entry point and configuration interface

@onready var btn_new_game: Button = $VBox/MenuButtons/NewGameBtn
@onready var btn_continue: Button = $VBox/MenuButtons/ContinueBtn
@onready var btn_multiplayer: Button = $VBox/MenuButtons/MultiplayerBtn
@onready var btn_settings: Button = $VBox/MenuButtons/SettingsBtn
@onready var btn_credits: Button = $VBox/MenuButtons/CreditsBtn
@onready var btn_exit: Button = $VBox/MenuButtons/ExitBtn

# Dialogs
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var multiplayer_panel: PanelContainer = $MultiplayerPanel

# Settings controls
@onready var master_slider: HSlider = $SettingsPanel/Margin/VBox/MasterSlider
@onready var sens_slider: HSlider = $SettingsPanel/Margin/VBox/SensSlider
@onready var close_settings_btn: Button = $SettingsPanel/Margin/VBox/CloseBtn
@onready var close_credits_btn: Button = $CreditsPanel/Margin/VBox/CloseBtn
@onready var close_multiplayer_btn: Button = $MultiplayerPanel/Margin/VBox/CloseBtn

func _ready() -> void:
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_multiplayer.pressed.connect(func(): multiplayer_panel.visible = true)
	btn_settings.pressed.connect(func(): settings_panel.visible = true)
	btn_credits.pressed.connect(func(): credits_panel.visible = true)
	btn_exit.pressed.connect(_on_exit_pressed)
	
	close_settings_btn.pressed.connect(func(): settings_panel.visible = false)
	close_credits_btn.pressed.connect(func(): credits_panel.visible = false)
	close_multiplayer_btn.pressed.connect(func(): multiplayer_panel.visible = false)
	
	btn_continue.disabled = not SaveManager.has_save_file()
	
	settings_panel.visible = false
	credits_panel.visible = false
	multiplayer_panel.visible = false
	
	master_slider.value_changed.connect(_on_master_volume_changed)

func _on_new_game_pressed() -> void:
	SoundManager.play_ui_click()
	visible = false
	var intro = get_parent().get_node_or_null("IntroMonologue")
	if intro and intro.has_method("start_intro"):
		intro.start_intro()
	else:
		GameManager.start_new_game()

func _on_continue_pressed() -> void:
	SoundManager.play_ui_click()
	if SaveManager.load_game():
		visible = false

func _on_master_volume_changed(val: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(val / 100.0))

func _on_exit_pressed() -> void:
	get_tree().quit()
