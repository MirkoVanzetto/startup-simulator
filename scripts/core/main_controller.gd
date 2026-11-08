extends Node
## MainController - Master orchestrator scene managing 3D world and all UI layers

@onready var game_world: Node3D = $GameWorld
@onready var hud: Control = $UILayer/HUD
@onready var main_menu: Control = $UILayer/MainMenu
@onready var computer_screen: Control = $UILayer/ComputerScreen
@onready var dialogue_overlay: Control = $UILayer/DialogueOverlay
@onready var web_forge: Control = $UILayer/WebForge

func _ready() -> void:
	EventBus.game_state_changed.connect(_on_game_state_changed)
	SoundManager.start_studio_ambience()
	
	# Start with main menu active
	GameManager.change_state(GameManager.GameState.MAIN_MENU)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_handle_pause_toggle()

func _handle_pause_toggle() -> void:
	match GameManager.current_state:
		GameManager.GameState.FIRST_PERSON:
			# If at first person, ESC can return to menu or pause
			main_menu.visible = true
			GameManager.change_state(GameManager.GameState.MAIN_MENU)
		GameManager.GameState.COMPUTER:
			# ESC while at computer closes the computer
			EventBus.computer_closed.emit()
		GameManager.GameState.MINIGAME:
			# ESC while at minigame closes minigame and returns to computer
			web_forge.visible = false
			EventBus.computer_opened.emit()
		GameManager.GameState.DIALOGUE:
			pass
		GameManager.GameState.MAIN_MENU:
			# If a game is active, ESC resumes
			if GameManager.player_node != null:
				main_menu.visible = false
				GameManager.change_state(GameManager.GameState.FIRST_PERSON)

func _on_game_state_changed(new_state: int, _old_state: int) -> void:
	match new_state:
		GameManager.GameState.MAIN_MENU:
			main_menu.visible = true
			hud.visible = false
			computer_screen.visible = false
			dialogue_overlay.visible = false
			web_forge.visible = false
		GameManager.GameState.FIRST_PERSON:
			main_menu.visible = false
			hud.visible = true
			computer_screen.visible = false
			dialogue_overlay.visible = false
			web_forge.visible = false
		GameManager.GameState.COMPUTER:
			main_menu.visible = false
			hud.visible = false
			computer_screen.visible = true
			dialogue_overlay.visible = false
			web_forge.visible = false
		GameManager.GameState.DIALOGUE:
			main_menu.visible = false
			hud.visible = false
			computer_screen.visible = false
			dialogue_overlay.visible = true
			web_forge.visible = false
		GameManager.GameState.MINIGAME:
			main_menu.visible = false
			hud.visible = false
			computer_screen.visible = false
			dialogue_overlay.visible = false
			web_forge.visible = true
