extends Node
## GameManager - Global state controller and mouse mode coordinator

enum GameState {
	MAIN_MENU = 0,
	FIRST_PERSON = 1,
	COMPUTER = 2,
	DIALOGUE = 3,
	MINIGAME = 4,
	PAUSED = 5,
	SHOP = 6,
	INVENTORY = 7,
	MAP = 8
}

var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.FIRST_PERSON
var player_node: Node = null
var current_interactive_target: Node = null
var active_waypoint: Dictionary = {} # {"id": String, "name": String, "pos": Vector3}

# Startup progression flags
var company_tier: int = 1 # 1: Freelance nel Garage, 2: Startup Emergente, 3: Software House Strutturata, 4: Tech Company & Server Room
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
		GameState.COMPUTER, GameState.DIALOGUE, GameState.MINIGAME, GameState.PAUSED, GameState.SHOP, GameState.INVENTORY, GameState.MAP:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
	EventBus.game_state_changed.emit(current_state, previous_state)

func set_waypoint(poi_id: String, poi_name: String, world_pos: Vector3) -> void:
	active_waypoint = {
		"id": poi_id,
		"name": poi_name,
		"pos": world_pos
	}
	EventBus.waypoint_changed.emit(active_waypoint.duplicate())

func clear_waypoint() -> void:
	active_waypoint = {}
	EventBus.waypoint_changed.emit({})

func serialize_waypoint() -> Dictionary:
	if active_waypoint.is_empty():
		return {}
	var p: Vector3 = active_waypoint.get("pos", Vector3.ZERO)
	return {
		"id": str(active_waypoint.get("id", "")),
		"name": str(active_waypoint.get("name", "")),
		"pos": [p.x, p.y, p.z]
	}

func deserialize_waypoint(data: Dictionary) -> void:
	if data.is_empty() or not data.has("id") or str(data.get("id", "")) == "":
		clear_waypoint()
		return
	var arr: Array = data.get("pos", [0.0, 0.0, 0.0])
	var pos := Vector3(
		float(arr[0]) if arr.size() > 0 else 0.0,
		float(arr[1]) if arr.size() > 1 else 0.0,
		float(arr[2]) if arr.size() > 2 else 0.0
	)
	set_waypoint(str(data.get("id", "")), str(data.get("name", "")), pos)

func get_recommended_quest_poi_id() -> String:
	if not ContractManager.is_contract_completed("pizzeria_da_mario"):
		var tut := ContractManager.get_tutorial_contract()
		return "pizzeria_mario" if tut.get("status", "available") == "available" else "studio"
	if studio_upgrades_installed.is_empty():
		return "studio"
	if not ContractManager.is_contract_completed("caffe_san_carlo"):
		var cs := ContractManager.get_contract("caffe_san_carlo")
		return "caffe_san_carlo" if cs.get("status", "available") == "available" else "studio"
	if not ContractManager.is_contract_completed("elettronica_to"):
		var et := ContractManager.get_contract("elettronica_to")
		return "elettronica_to" if et.get("status", "available") == "available" else "studio"
	if company_tier < 2:
		return "studio"
	var fac := ContractManager.get_factory_progress_summary()
	if not bool(fac["accepted"]) and not bool(fac["completed"]):
		return "officina_bellini"
	if bool(fac["accepted"]) and not bool(fac["completed"]):
		if not bool(fac["all_scouted"]):
			return "officina_bellini"
		if bool(fac["wifi_mounted"]) and not bool(fac["wifi_done"]):
			return "studio"
		if not bool(fac["wifi_done"]) and not ShopManager.has_hardware("hw_wifi_router", 1):
			return "elettronica_to"
		if not bool(fac["server_done"]) and not ShopManager.has_hardware("hw_server_tower", 1):
			return "elettronica_to"
		if not bool(fac["pcs_done"]) and not ShopManager.has_hardware("hw_workstation_pc", 2):
			return "elettronica_to"
		if not bool(fac["wifi_done"]) or not bool(fac["server_done"]) or not bool(fac["pcs_done"]):
			return "officina_bellini"
		return "studio"
	return "studio"

func start_new_game() -> void:
	company_tier = 1
	studio_upgrades_installed.clear()
	reputation_points = 0
	days_elapsed = 1
	active_waypoint.clear()
	NeedsManager.reset()
	ShopManager.reset()
	ShopManager.grant_starter_kit()
	FameManager.reset()
	EmployeeManager.reset()
	ServerRackManager.reset()
	EconomyManager.reset_economy(250.0) # Modest starting capital: 250 EUR
	ContractManager.init_tutorial_contract()
	change_state(GameState.FIRST_PERSON)
	EventBus.waypoint_changed.emit({})
	EventBus.notification_posted.emit("Nuova Avventura", "Benvenuto nel tuo studio a Torino! Controlla il laptop ([TAB] Zaino · [CAPS] Mappa).", "info")

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

## Progression & Expansion System
func get_company_tier_name(tier: int = -1) -> String:
	var t = tier if tier >= 0 else company_tier
	match t:
		1:
			return "Freelance nel Garage"
		2:
			return "Startup Emergente"
		3:
			return "Software House Strutturata"
		4:
			return "Tech Company & Server Room"
		_:
			return "Azienda Livello %d" % t

func get_max_employee_slots() -> int:
	match company_tier:
		1:
			return 0
		2:
			return 1
		3:
			return 3
		4:
			return 6
		_:
			return 0

func can_upgrade_company_tier() -> Dictionary:
	var target_tier = company_tier + 1
	if target_tier > 4:
		return {
			"allowed": false,
			"can_upgrade": false,
			"reason": "Hai già raggiunto il livello aziendale massimo (Tech Company & Server Room)!"
		}
		
	match target_tier:
		2:
			var req_rep = 50
			var req_cap = 2500.0
			var cost = 1200.0
			if reputation_points < req_rep:
				return {
					"allowed": false,
					"can_upgrade": false,
					"reason": "Reputazione insufficiente: servono almeno %d punti Reputazione (attuali: %d)." % [req_rep, reputation_points]
				}
			if EconomyManager.balance < req_cap:
				return {
					"allowed": false,
					"can_upgrade": false,
					"reason": "Capitale insufficiente: servono almeno € %0.2f di capitale aziendale (saldo attuale: € %0.2f)." % [req_cap, EconomyManager.balance]
				}
			if not ContractManager.is_contract_completed("pizzeria_da_mario"):
				return {
					"allowed": false,
					"can_upgrade": false,
					"reason": "Devi completare la commessa principale con Pizzeria Da Mario prima di registrare l'espansione aziendale."
				}
			return {
				"allowed": true,
				"can_upgrade": true,
				"reason": "",
				"target_tier": 2,
				"cost": cost,
				"tier_name": "Startup Emergente"
			}
		3:
			var req_rep = 120
			var req_cap = 8000.0
			var cost = 3500.0
			if reputation_points < req_rep:
				return {
					"allowed": false,
					"can_upgrade": false,
					"reason": "Reputazione insufficiente: servono almeno %d punti Reputazione (attuali: %d)." % [req_rep, reputation_points]
				}
			if EconomyManager.balance < req_cap:
				return {
					"allowed": false,
					"can_upgrade": false,
					"reason": "Capitale insufficiente: servono almeno € %0.2f (saldo attuale: € %0.2f)." % [req_cap, EconomyManager.balance]
				}
			return {
				"allowed": true,
				"can_upgrade": true,
				"reason": "",
				"target_tier": 3,
				"cost": cost,
				"tier_name": "Software House Strutturata"
			}
		4:
			var req_rep = 250
			var req_cap = 20000.0
			var cost = 8000.0
			if reputation_points < req_rep:
				return {
					"allowed": false,
					"can_upgrade": false,
					"reason": "Reputazione insufficiente: servono almeno %d punti Reputazione (attuali: %d)." % [req_rep, reputation_points]
				}
			if EconomyManager.balance < req_cap:
				return {
					"allowed": false,
					"can_upgrade": false,
					"reason": "Capitale insufficiente: servono almeno € %0.2f (saldo attuale: € %0.2f)." % [req_cap, EconomyManager.balance]
				}
			return {
				"allowed": true,
				"can_upgrade": true,
				"reason": "",
				"target_tier": 4,
				"cost": cost,
				"tier_name": "Tech Company & Server Room"
			}
		_:
			return {"allowed": false, "can_upgrade": false, "reason": "Livello aziendale non valido."}

func upgrade_company_tier(bypass_requirements: bool = false) -> bool:
	var check = can_upgrade_company_tier()
	if not bypass_requirements:
		if not check.get("allowed", false):
			EventBus.notification_posted.emit("Espansione Non Disponibile", check.get("reason", "Requisiti non soddisfatti"), "warning")
			return false
		
		var cost = float(check.get("cost", 0.0))
		if cost > 0.0:
			if not EconomyManager.spend(cost, "Espansione Sede Aziendale a %s" % check.get("tier_name", "Tier %d" % (company_tier + 1))):
				return false
				
	company_tier += 1
	var tier_name = get_company_tier_name(company_tier)
	EventBus.notification_posted.emit(
		"Espansione Sede Completata!",
		"Congratulazioni! La tua azienda è ora una '%s'! Postazioni dipendenti disponibili: %d." % [tier_name, get_max_employee_slots()],
		"success"
	)
	SoundManager.play_ui_success()
	SaveManager.request_auto_save()
	return true

