class_name IntroMonologue
extends Control
## IntroMonologue - Narrative story prologue explaining the protagonist's motivation

@onready var step1_panel: PanelContainer = $Center/VBox/Step1
@onready var step2_panel: PanelContainer = $Center/VBox/Step2
@onready var step3_panel: PanelContainer = $Center/VBox/Step3
@onready var next_button: Button = $Center/VBox/Buttons/NextButton
@onready var start_button: Button = $Center/VBox/Buttons/StartButton

var current_step: int = 1

func _ready() -> void:
	visible = false
	next_button.pressed.connect(_on_next_pressed)
	start_button.pressed.connect(_on_start_pressed)

func start_intro() -> void:
	current_step = 1
	visible = true
	_update_step_display()

func _update_step_display() -> void:
	step1_panel.visible = (current_step == 1)
	step2_panel.visible = (current_step == 2)
	step3_panel.visible = (current_step == 3)
	
	next_button.visible = (current_step < 3)
	start_button.visible = (current_step == 3)

func _on_next_pressed() -> void:
	SoundManager.play_ui_click()
	current_step += 1
	_update_step_display()

func _on_start_pressed() -> void:
	SoundManager.play_ui_success()
	visible = false
	GameManager.start_new_game()
	EventBus.notification_posted.emit(
		"Nuovo Obiettivo",
		"Esplora il tuo garage studio e premi [E] sulla scrivania per aprire il laptop!",
		"contract"
	)
