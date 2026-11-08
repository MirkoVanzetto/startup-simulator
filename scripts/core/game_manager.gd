extends Node
## GameManager - Global state controller and mouse mode coordinator

enum GameState {
	MAIN_MENU = 0,
	FIRST_PERSON = 1,
	COMPUTER = 2,
	DIALOGUE = 3,
	MINIGAME = 4,
	PAUSED = 5
}

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.FIRST_PERSON
var player_node: Node = null
var current_interactive_target: Node = null

# Startup progression flags
var studio_upgrades_installed: Array[String] = []
var reputation_points: int = 0
var days_elapsed: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.computer_opened.connect(_on_computer_opened)
	EventBus.computer_closed.connect(_on_computer_closed)
	EventBus.minigame_started.connect(_on_minigame_started)
	EventBus.minigame_completed.connect(_on_minigame_completed)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.item_purchased.connect(_on_item_purchased)

func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	match current_state:
		GameState.MAIN_MENU:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameState.FIRST_PERSON:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		GameState.COMPUTER, GameState.DIALOGUE, GameState.MINIGAME, GameState.PAUSED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
	EventBus.game_state_changed.emit(current_state, previous_state)

func start_new_game() -> void:
	studio_upgrades_installed.clear()
	reputation_points = 0
	days_elapsed = 1
	EconomyManager.reset_economy(250.0) # Modest starting capital: 250 EUR
	ContractManager.init_tutorial_contract()
	change_state(GameState.FIRST_PERSON)
	EventBus.notification_posted.emit("Nuova Avventura", "Benvenuto nel tuo studio a Torino! Controlla il laptop.", "info")

func _on_computer_opened() -> void:
	change_state(GameState.COMPUTER)

func _on_computer_closed() -> void:
	change_state(GameState.FIRST_PERSON)

func _on_dialogue_started(_speaker: String, _lines: Array, _choices: Array) -> void:
	change_state(GameState.DIALOGUE)

func _on_dialogue_ended() -> void:
	change_state(GameState.FIRST_PERSON)

func _on_minigame_started(_type: String) -> void:
	change_state(GameState.MINIGAME)

func _on_minigame_completed(_score: float, _data: Dictionary) -> void:
	# Return to computer view to finish delivery
	change_state(GameState.COMPUTER)

func _on_item_purchased(item_id: String, _cost: float) -> void:
	if not item_id in studio_upgrades_installed:
		studio_upgrades_installed.append(item_id)
		SaveManager.request_auto_save()
