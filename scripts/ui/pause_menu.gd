extends Control
## PauseMenu - In-game pause modal with saving, loading, and live settings

@onready var main_panel: PanelContainer = $CenterContainer/MainPanel
@onready var settings_panel: PanelContainer = $CenterContainer/SettingsPanel

# Main Pause buttons
@onready var resume_btn: Button = $CenterContainer/MainPanel/Margin/VBox/ResumeBtn
@onready var save_btn: Button = $CenterContainer/MainPanel/Margin/VBox/SaveBtn
@onready var load_btn: Button = $CenterContainer/MainPanel/Margin/VBox/LoadBtn
@onready var settings_btn: Button = $CenterContainer/MainPanel/Margin/VBox/SettingsBtn
@onready var menu_btn: Button = $CenterContainer/MainPanel/Margin/VBox/MenuBtn
@onready var exit_btn: Button = $CenterContainer/MainPanel/Margin/VBox/ExitBtn

# Settings sliders & controls
@onready var master_slider: HSlider = $CenterContainer/SettingsPanel/Margin/VBox/MasterSlider
@onready var sens_slider: HSlider = $CenterContainer/SettingsPanel/Margin/VBox/SensSlider
@onready var fullscreen_check: CheckButton = $CenterContainer/SettingsPanel/Margin/VBox/FullscreenCheck
@onready var close_settings_btn: Button = $CenterContainer/SettingsPanel/Margin/VBox/CloseSettingsBtn

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	resume_btn.pressed.connect(_on_resume_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	load_btn.pressed.connect(_on_load_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	close_settings_btn.pressed.connect(_on_close_settings_pressed)
	master_slider.value_changed.connect(_on_master_slider_changed)
	sens_slider.value_changed.connect(_on_sens_slider_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

func open_pause_menu() -> void:
	visible = true
	main_panel.visible = true
	settings_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	load_btn.disabled = not SaveManager.has_save_file()
	SoundManager.play_ui_click()

func close_pause_menu() -> void:
	visible = false
	if GameManager.current_state == GameManager.GameState.FIRST_PERSON:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SoundManager.play_ui_click()

func _on_resume_pressed() -> void:
	close_pause_menu()
	GameManager.change_state(GameManager.GameState.FIRST_PERSON)

func _on_save_pressed() -> void:
	SoundManager.play_ui_click()
	SaveManager.save_game()
	load_btn.disabled = false

func _on_load_pressed() -> void:
	SoundManager.play_ui_click()
	if SaveManager.load_game():
		close_pause_menu()

func _on_settings_pressed() -> void:
	SoundManager.play_ui_click()
	main_panel.visible = false
	settings_panel.visible = true

func _on_close_settings_pressed() -> void:
	SoundManager.play_ui_click()
	settings_panel.visible = false
	main_panel.visible = true

func _on_master_slider_changed(val: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(val / 100.0))

func _on_sens_slider_changed(val: float) -> void:
	if is_instance_valid(GameManager.player_node):
		# Default sensitivity is 0.0022
		GameManager.player_node.mouse_sensitivity = 0.0022 * (val / 50.0)

func _on_fullscreen_toggled(is_fullscreen: bool) -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_menu_pressed() -> void:
	SoundManager.play_ui_click()
	close_pause_menu()
	GameManager.change_state(GameManager.GameState.MAIN_MENU)

func _on_exit_pressed() -> void:
	get_tree().quit(0)
