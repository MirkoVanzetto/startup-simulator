extends Node
## SaveManager - Atomic JSON persistence for Startup Simulator

const SAVE_PATH: String = "user://savegame.json"
const BACKUP_PATH: String = "user://savegame.json.bak"
const FurniturePlacementManagerScript = preload("res://scripts/world/furniture_placement_manager.gd")

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func request_auto_save() -> void:
	save_game()

func save_game() -> bool:
	var player_pos: Vector3 = Vector3.ZERO
	var player_rot: float = 0.0
	if is_instance_valid(GameManager.player_node):
		player_pos = GameManager.player_node.global_position
		player_rot = GameManager.player_node.rotation.y
		
	var save_dict: Dictionary = {
		"version": "1.0.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"economy": {
			"balance": EconomyManager.balance,
			"ledger": EconomyManager.ledger
		},
		"progression": {
			"reputation": GameManager.reputation_points,
			"days_elapsed": GameManager.days_elapsed,
			"upgrades": GameManager.studio_upgrades_installed
		},
		"contracts": {
			"active": ContractManager.active_contracts,
			"completed": ContractManager.completed_contracts
		},
		"player": {
			"pos_x": player_pos.x,
			"pos_y": player_pos.y,
			"pos_z": player_pos.z,
			"rot_y": player_rot
		},
		"placed_furniture": FurniturePlacementManagerScript.get_placed_furniture()
	}
	
	var json_string = JSON.stringify(save_dict, "\t")
	
	# Rotate backup if previous save exists
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Impossibile aprire il file di salvataggio per la scrittura: %s" % SAVE_PATH)
		return false
		
	file.store_string(json_string)
	file.close()
	EventBus.notification_posted.emit("Partita Salvata", "I progressi aziendali sono stati salvati.", "info")
	return true

func load_game() -> bool:
	if not has_save_file():
		return false
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
		
	var content = file.get_as_text()
	file.close()
	
	var test_json = JSON.new()
	var error = test_json.parse(content)
	if error != OK:
		push_error("Errore di parsing del salvataggio JSON: riga %d - %s" % [test_json.get_error_line(), test_json.get_error_message()])
		return false
		
	var data: Dictionary = test_json.data
	
	# Restore Economy
	if data.has("economy"):
		EconomyManager.balance = float(data["economy"].get("balance", 250.0))
		EconomyManager.ledger.clear()
		for item in data["economy"].get("ledger", []):
			if item is Dictionary:
				EconomyManager.ledger.append(item)
		EventBus.funds_changed.emit(EconomyManager.balance, 0.0, "Caricamento")
		
	# Restore Progression
	if data.has("progression"):
		GameManager.reputation_points = int(data["progression"].get("reputation", 0))
		GameManager.days_elapsed = int(data["progression"].get("days_elapsed", 1))
		var upg_list = data["progression"].get("upgrades", [])
		GameManager.studio_upgrades_installed.clear()
		for u in upg_list:
			GameManager.studio_upgrades_installed.append(str(u))
			
	# Restore Contracts
	if data.has("contracts"):
		ContractManager.active_contracts = data["contracts"].get("active", {})
		ContractManager.completed_contracts.clear()
		for c in data["contracts"].get("completed", []):
			ContractManager.completed_contracts.append(str(c))
		
	# Restore Player position if in world
	if is_instance_valid(GameManager.player_node) and data.has("player"):
		var p = data["player"]
		GameManager.player_node.global_position = Vector3(float(p.get("pos_x", 0)), float(p.get("pos_y", 0)), float(p.get("pos_z", 0)))
		GameManager.player_node.rotation.y = float(p.get("rot_y", 0))

	# Restore Placed Furniture (M4)
	if data.has("placed_furniture") and data["placed_furniture"] is Array:
		FurniturePlacementManagerScript.load_placed_furniture(data["placed_furniture"])
	else:
		FurniturePlacementManagerScript.load_placed_furniture([])
		
	GameManager.change_state(GameManager.GameState.FIRST_PERSON)
	EventBus.notification_posted.emit("Partita Caricata", "Bentornato nella tua startup!", "success")
	return true
