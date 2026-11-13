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
			"company_tier": GameManager.company_tier,
			"reputation": GameManager.reputation_points,
			"days_elapsed": GameManager.days_elapsed,
			"upgrades": GameManager.studio_upgrades_installed
		},
		"contracts": ContractManager.serialize(),
		"employees": EmployeeManager.serialize(),
		"server_rack": ServerRackManager.serialize(),
		"player": {
			"pos_x": player_pos.x,
			"pos_y": player_pos.y,
			"pos_z": player_pos.z,
			"rot_y": player_rot
		},
		"placed_furniture": FurniturePlacementManagerScript.get_placed_furniture(),
		"needs": NeedsManager.serialize(),
		"shops": ShopManager.serialize(),
		"fame": FameManager.serialize(),
		"waypoint": GameManager.serialize_waypoint()
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
		GameManager.company_tier = maxi(1, int(data["progression"].get("company_tier", 1)))
		GameManager.reputation_points = int(data["progression"].get("reputation", 0))
		GameManager.days_elapsed = int(data["progression"].get("days_elapsed", 1))
		var upg_list = data["progression"].get("upgrades", [])
		GameManager.studio_upgrades_installed.clear()
		for u in upg_list:
			GameManager.studio_upgrades_installed.append(str(u))
			
	# Restore Contracts (includes active, completed, marketplace, lead timer, factory_state)
	if data.has("contracts") and data["contracts"] is Dictionary:
		ContractManager.deserialize(data["contracts"])

	# Restore Employees & Server Rack
	if data.has("employees") and data["employees"] is Dictionary:
		EmployeeManager.deserialize(data["employees"])
	else:
		EmployeeManager.reset()

	if data.has("server_rack") and data["server_rack"] is Dictionary:
		ServerRackManager.deserialize(data["server_rack"])
	else:
		ServerRackManager.reset()
		if "server_rack_upgrade" in GameManager.studio_upgrades_installed:
			ServerRackManager.unlock_server_rack()
		
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
		
	# Restore Needs, Shops & Fame (vecchi salvataggi senza queste sezioni: valori di default)
	if data.has("needs") and data["needs"] is Dictionary:
		NeedsManager.deserialize(data["needs"])
	else:
		NeedsManager.reset()
	if data.has("shops") and data["shops"] is Dictionary:
		ShopManager.deserialize(data["shops"])
	else:
		ShopManager.reset()
	if data.has("fame") and data["fame"] is Dictionary:
		FameManager.deserialize(data["fame"])
	else:
		FameManager.reset()
	if data.has("waypoint") and data["waypoint"] is Dictionary:
		GameManager.deserialize_waypoint(data["waypoint"])
	else:
		GameManager.clear_waypoint()
		
	GameManager.change_state(GameManager.GameState.FIRST_PERSON)
	EventBus.notification_posted.emit("Partita Caricata", "Bentornato nella tua startup!", "success")
	return true
