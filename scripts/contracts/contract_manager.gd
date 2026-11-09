extends Node
## ContractManager - Handles active client commissions, story missions, and procedural marketplace

const ContractGenerator = preload("res://scripts/contracts/contract_generator.gd")

var active_contracts: Dictionary = {}
var completed_contracts: Array[String] = []
var marketplace_contracts: Array[Dictionary] = []

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)

func init_tutorial_contract() -> void:
	active_contracts.clear()
	completed_contracts.clear()
	marketplace_contracts.clear()
	
	active_contracts["pizzeria_da_mario"] = {
		"id": "pizzeria_da_mario",
		"title": "Sito Web Ufficiale per Pizzeria Da Mario",
		"client": "Mario Esposito",
		"category": "Web Development",
		"location": "Via Po 18, Torino",
		"budget": 650.00,
		"reputation_reward": 15,
		"difficulty": 1,
		"deadline_days": 2,
		"status": "available", # "available" -> "in_progress" -> "built" -> "completed"
		"objective_text": "Raggiungi la pizzeria in Via Po e parla con Mario per definire i requisiti.",
		"requirements": [
			"Logo con la Mole Antonelliana",
			"Menu con Pizze Speciali",
			"Orari di Apertura & Indirizzo",
			"Pulsante Prenotazione Tavolo"
		],
		"website_build_data": {}
	}
	
	# Generate first batch of marketplace opportunities
	refresh_marketplace()
	EventBus.contract_updated.emit("pizzeria_da_mario", "available")

func refresh_marketplace() -> void:
	marketplace_contracts = ContractGenerator.generate_initial_marketplace_pool(4)
	EventBus.contract_marketplace_refreshed.emit()

func _on_day_passed(_new_day: int) -> void:
	# Add new fresh contracts every day
	if marketplace_contracts.size() < 6:
		marketplace_contracts.append(ContractGenerator.generate_random_contract())
		EventBus.contract_marketplace_refreshed.emit()

func get_tutorial_contract() -> Dictionary:
	return active_contracts.get("pizzeria_da_mario", {})

func get_contract(contract_id: String) -> Dictionary:
	return active_contracts.get(contract_id, {})

func is_contract_completed(contract_id: String) -> bool:
	return contract_id in completed_contracts

func advance_tutorial_to_in_progress() -> void:
	advance_contract_to_in_progress("pizzeria_da_mario", "Torna al tuo studio e usa l'app WebForge sul laptop per sviluppare il sito.")

func advance_contract_to_in_progress(contract_id: String, objective: String = "") -> void:
	if active_contracts.has(contract_id):
		var c = active_contracts[contract_id]
		c["status"] = "in_progress"
		if objective != "":
			c["objective_text"] = objective
		EventBus.contract_updated.emit(contract_id, "in_progress")
		EventBus.notification_posted.emit("Contratto Accettato", "Obiettivo: sviluppa il software richiesto su WebForge IDE!", "contract")
		SaveManager.request_auto_save()

func mark_tutorial_website_built(result_data: Dictionary) -> void:
	mark_contract_built("pizzeria_da_mario", result_data, "Consegna il sito a Mario tramite l'app Posta sul laptop per ricevere il pagamento.")

func mark_contract_built(contract_id: String, result_data: Dictionary, objective: String = "") -> void:
	if active_contracts.has(contract_id):
		var c = active_contracts[contract_id]
		if c.get("status") == "completed" or (contract_id in completed_contracts):
			return
		c["status"] = "built"
		c["website_build_data"] = result_data
		if objective != "":
			c["objective_text"] = objective
		EventBus.contract_updated.emit(contract_id, "built")
		EventBus.notification_posted.emit("Progetto Compilato", "Il software è pronto! Consegnalo tramite TO-OS per riscuotere il pagamento.", "success")
		SaveManager.request_auto_save()

func complete_tutorial_contract() -> void:
	complete_story_contract("pizzeria_da_mario")

func complete_story_contract(contract_id: String) -> void:
	if active_contracts.has(contract_id):
		var c = active_contracts[contract_id]
		if c.get("status") == "completed" or (contract_id in completed_contracts):
			return
		c["status"] = "completed"
		var reward = float(c["budget"])
		var rep = int(c["reputation_reward"])
		completed_contracts.append(contract_id)
		
		# Sales employee bonus
		if EmployeeManager.is_employee_hired("emp_marco"):
			reward *= 1.15 # +15% Marco Ferri commission perk
			
		EconomyManager.earn(reward, "Compenso Progetto: " + c["title"])
		GameManager.reputation_points += rep
		
		EventBus.contract_completed.emit(contract_id, reward, rep)
		EventBus.contract_updated.emit(contract_id, "completed")
		EventBus.notification_posted.emit(
			"Progetto Consegnato!",
			"Hai incassato € %0.2f e guadagnato +%d Reputazione aziendale!" % [reward, rep],
			"success"
		)
		SoundManager.play_ui_success()
		
		# Unlock next story mission in sequence
		_unlock_next_story_mission(contract_id)
		SaveManager.request_auto_save()

func _unlock_next_story_mission(just_completed_id: String) -> void:
	match just_completed_id:
		"pizzeria_da_mario":
			# Unlock Mission 2: Caffè San Carlo
			active_contracts["caffe_san_carlo"] = {
				"id": "caffe_san_carlo",
				"title": "Sistema Touch Web POS & Prenotazioni per Caffè San Carlo",
				"client": "Elena Barista",
				"category": "Web Application / POS",
				"location": "Via Po 12, Torino (Lato Est)",
				"budget": 1250.00,
				"reputation_reward": 25,
				"difficulty": 2,
				"deadline_days": 3,
				"status": "available",
				"objective_text": "Visita il Caffè San Carlo in Via Po e parla con Elena al bancone.",
				"requirements": [
					"Interfaccia Touch Screen Veloce per Cassa",
					"Menu Caffetteria, Croissant & Aperitivi Torinesi",
					"Integrazione Pagamenti Elettronici Satispay",
					"Modulo Prenotazione Tavoli Esterni"
				],
				"website_build_data": {}
			}
			EventBus.contract_updated.emit("caffe_san_carlo", "available")
			EventBus.notification_posted.emit(
				"Nuova Opportunità Sbloccata!",
				"Elena del celebre Caffè San Carlo cerca una Web App per la cassa! Raggiungila in Via Po.",
				"contract"
			)
		"caffe_san_carlo":
			# Unlock Mission 3: Elettronica TO
			active_contracts["elettronica_to"] = {
				"id": "elettronica_to",
				"title": "Migrazione Cloud & Catalogo B2B Elettronica TO",
				"client": "Davide Tecnico",
				"category": "Cloud Infrastructure & Backend",
				"location": "Via Po 6, Torino (Lato Ovest)",
				"budget": 1850.00,
				"reputation_reward": 35,
				"difficulty": 3,
				"deadline_days": 4,
				"status": "available",
				"objective_text": "Raggiungi il negozio Elettronica TO in Via Po e parla con Davide.",
				"requirements": [
					"Architettura Ridondata Multi-Zone",
					"Catalogo Hardware & Server in Tempo Reale",
					"Backup Notturno Automatico su Server Rack",
					"Crittografia TLS e Token API Sicuri"
				],
				"website_build_data": {}
			}
			EventBus.contract_updated.emit("elettronica_to", "available")
			EventBus.notification_posted.emit(
				"Nuova Missione Enterprise!",
				"Davide di Elettronica TO ha bisogno di una soluzione Cloud per il negozio! Trovalo in Via Po.",
				"contract"
			)
		"elettronica_to":
			EventBus.notification_posted.emit(
				"Missioni Principali Completate!",
				"Tutti i contratti della storia completati! Espandi l'azienda o affronta incarichi B2B dal Marketplace.",
				"success"
			)

func accept_marketplace_contract(contract_id: String) -> bool:
	for i in range(marketplace_contracts.size()):
		var c = marketplace_contracts[i]
		if c["id"] == contract_id:
			c["status"] = "in_progress"
			active_contracts[contract_id] = c
			marketplace_contracts.remove_at(i)
			EventBus.contract_updated.emit(contract_id, "in_progress")
			EventBus.notification_posted.emit("Nuovo Contratto B2B", "Hai accettato il contratto per: " + c["title"], "info")
			EventBus.contract_marketplace_refreshed.emit()
			return true
	return false

func complete_marketplace_contract(contract_id: String) -> bool:
	if active_contracts.has(contract_id):
		var c = active_contracts[contract_id]
		c["status"] = "completed"
		var reward = float(c["budget"])
		if EmployeeManager.is_employee_hired("emp_marco"):
			reward *= 1.15
			
		var rep = int(c["reputation_reward"])
		completed_contracts.append(contract_id)
		
		EconomyManager.earn(reward, "Liquidazione Progetto: " + c["title"])
		GameManager.reputation_points += rep
		
		EventBus.contract_completed.emit(contract_id, reward, rep)
		EventBus.contract_updated.emit(contract_id, "completed")
		EventBus.notification_posted.emit("Lavoro Liquidato!", "Incassati € %0.2f e +%d Reputazione!" % [reward, rep], "success")
		SaveManager.request_auto_save()
		return true
	return false
