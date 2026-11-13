extends Node
## MainController - Master orchestrator scene managing 3D world and all UI layers

@onready var game_world: Node3D = $GameWorld
@onready var hud: Control = $UILayer/HUD
@onready var main_menu: Control = $UILayer/MainMenu
@onready var computer_screen: Control = $UILayer/ComputerScreen
@onready var dialogue_overlay: Control = $UILayer/DialogueOverlay
@onready var web_forge: Control = $UILayer/WebForge
@onready var firewall_router: Control = $UILayer/FirewallRouter
@onready var pause_menu: Control = $UILayer/PauseMenu
@onready var shop_menu: Control = $UILayer/ShopMenu
@onready var inventory_menu: Control = $UILayer/InventoryMenu
@onready var world_map_menu: Control = $UILayer/WorldMapMenu
@onready var studio_mgr: Node = $GameWorld/Studio

func _ready() -> void:
	EventBus.game_state_changed.connect(_on_game_state_changed)
	SoundManager.start_studio_ambience()
	
	# Start with main menu active
	GameManager.change_state(GameManager.GameState.MAIN_MENU)

func _input(event: InputEvent) -> void:
	if _is_inventory_toggle_event(event):
		var st := GameManager.current_state
		if st == GameManager.GameState.INVENTORY:
			inventory_menu.close_inventory()
			SoundManager.play_ui_click()
			get_viewport().set_input_as_handled()
			return
		elif st == GameManager.GameState.FIRST_PERSON or st == GameManager.GameState.MAP:
			# In Decor Mode [B] dentro lo studio, Tab continua a ciclare gli arredi!
			if st == GameManager.GameState.FIRST_PERSON and is_instance_valid(studio_mgr) and bool(studio_mgr.get("is_decor_mode")):
				return
			world_map_menu.visible = false
			inventory_menu.open_inventory()
			SoundManager.play_ui_click()
			get_viewport().set_input_as_handled()
			return

	if _is_map_toggle_event(event):
		var st := GameManager.current_state
		if st == GameManager.GameState.MAP:
			world_map_menu.close_map()
			SoundManager.play_ui_click()
			get_viewport().set_input_as_handled()
			return
		elif st == GameManager.GameState.FIRST_PERSON or st == GameManager.GameState.INVENTORY:
			if st == GameManager.GameState.FIRST_PERSON and is_instance_valid(studio_mgr) and bool(studio_mgr.get("is_decor_mode")):
				if studio_mgr.has_method("toggle_decor_mode"):
					studio_mgr.toggle_decor_mode()
			inventory_menu.visible = false
			world_map_menu.open_map()
			SoundManager.play_ui_click()
			get_viewport().set_input_as_handled()
			return

func _is_inventory_toggle_event(event: InputEvent) -> bool:
	if event.is_action_pressed("toggle_inventory"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_TAB or event.physical_keycode == KEY_TAB
	return false

func _is_map_toggle_event(event: InputEvent) -> bool:
	if event.is_action_pressed("toggle_map"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_CAPSLOCK or event.physical_keycode == KEY_CAPSLOCK
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_handle_pause_toggle()

func _handle_pause_toggle() -> void:
	match GameManager.current_state:
		GameManager.GameState.FIRST_PERSON:
			# Pressing ESC in first person opens the in-game Pause / Settings Menu!
			pause_menu.open_pause_menu()
			GameManager.change_state(GameManager.GameState.PAUSED)
		GameManager.GameState.PAUSED:
			# Pressing ESC again resumes gameplay
			pause_menu.close_pause_menu()
			GameManager.change_state(GameManager.GameState.FIRST_PERSON)
		GameManager.GameState.COMPUTER:
			# ESC while at computer closes the computer
			EventBus.computer_closed.emit()
		GameManager.GameState.MINIGAME:
			# ESC while at minigame closes minigame and returns to computer
			web_forge.visible = false
			firewall_router.visible = false
			EventBus.computer_opened.emit()
		GameManager.GameState.SHOP:
			shop_menu.close_shop()
		GameManager.GameState.INVENTORY:
			inventory_menu.close_inventory()
		GameManager.GameState.MAP:
			world_map_menu.close_map()
		GameManager.GameState.DIALOGUE:
			pass
		GameManager.GameState.MAIN_MENU:
			# If game was in progress, ESC resumes
			if GameManager.player_node != null and not main_menu.visible:
				GameManager.change_state(GameManager.GameState.FIRST_PERSON)

func _on_game_state_changed(new_state: int, _old_state: int) -> void:
	match new_state:
		GameManager.GameState.MAIN_MENU:
			main_menu.visible = true
			hud.visible = false
			computer_screen.visible = false
			dialogue_overlay.visible = false
			web_forge.visible = false
			firewall_router.visible = false
			pause_menu.visible = false
			shop_menu.visible = false
			inventory_menu.visible = false
			world_map_menu.visible = false
		GameManager.GameState.FIRST_PERSON:
			main_menu.visible = false
			hud.visible = true
			computer_screen.visible = false
			dialogue_overlay.visible = false
			web_forge.visible = false
			firewall_router.visible = false
			pause_menu.visible = false
			shop_menu.visible = false
			inventory_menu.visible = false
			world_map_menu.visible = false
		GameManager.GameState.PAUSED:
			main_menu.visible = false
			hud.visible = false
			computer_screen.visible = false
			dialogue_overlay.visible = false
			web_forge.visible = false
			firewall_router.visible = false
			pause_menu.visible = true
			shop_menu.visible = false
			inventory_menu.visible = false
			world_map_menu.visible = false
		GameManager.GameState.COMPUTER:
			main_menu.visible = false
			hud.visible = false
			computer_screen.visible = true
			dialogue_overlay.visible = false
			web_forge.visible = false
			firewall_router.visible = false
			pause_menu.visible = false
			shop_menu.visible = false
			inventory_menu.visible = false
			world_map_menu.visible = false
		GameManager.GameState.DIALOGUE:
			main_menu.visible = false
			hud.visible = false
			computer_screen.visible = false
			dialogue_overlay.visible = true
			web_forge.visible = false
			firewall_router.visible = false
			pause_menu.visible = false
			shop_menu.visible = false
			inventory_menu.visible = false
			world_map_menu.visible = false
		GameManager.GameState.MINIGAME:
			main_menu.visible = false
			hud.visible = false
			computer_screen.visible = false
			dialogue_overlay.visible = false
			pause_menu.visible = false
			shop_menu.visible = false
			inventory_menu.visible = false
			world_map_menu.visible = false
		GameManager.GameState.SHOP:
			main_menu.visible = false
			hud.visible = false
			computer_screen.visible = false
			dialogue_overlay.visible = false
			web_forge.visible = false
			firewall_router.visible = false
			pause_menu.visible = false
			shop_menu.visible = true
			inventory_menu.visible = false
			world_map_menu.visible = false
		GameManager.GameState.INVENTORY:
			main_menu.visible = false
			hud.visible = false
			computer_screen.visible = false
			dialogue_overlay.visible = false
			web_forge.visible = false
			firewall_router.visible = false
			pause_menu.visible = false
			shop_menu.visible = false
			inventory_menu.visible = true
			world_map_menu.visible = false
		GameManager.GameState.MAP:
			main_menu.visible = false
			hud.visible = false
			computer_screen.visible = false
			dialogue_overlay.visible = false
			web_forge.visible = false
			firewall_router.visible = false
			pause_menu.visible = false
			shop_menu.visible = false
			inventory_menu.visible = false
			world_map_menu.visible = true
