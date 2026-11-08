extends Node
## ContractManager - Handles active client commissions, tutorial flow, and procedural marketplace

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

func advance_tutorial_to_in_progress() -> void:
	if active_contracts.has("pizzeria_da_mario"):
		var c = active_contracts["pizzeria_da_mario"]
		c["status"] = "in_progress"
		c["objective_text"] = "Torna al tuo studio e usa l'app WebForge sul laptop per sviluppare il sito."
		EventBus.contract_updated.emit("pizzeria_da_mario", "in_progress")
		EventBus.notification_posted.emit("Contratto Accettato", "Nuovo obiettivo: sviluppa il sito web su WebForge!", "contract")

func mark_tutorial_website_built(result_data: Dictionary) -> void:
	if active_contracts.has("pizzeria_da_mario"):
		var c = active_contracts["pizzeria_da_mario"]
		c["status"] = "built"
		c["website_build_data"] = result_data
		c["objective_text"] = "Consegna il sito a Mario tramite l'app Posta sul laptop per ricevere il pagamento."
		EventBus.contract_updated.emit("pizzeria_da_mario", "built")
		EventBus.notification_posted.emit("Sito Completato", "Il sito è pronto! Aprilo su TO-OS per la consegna finale.", "success")

func complete_tutorial_contract() -> void:
	if active_contracts.has("pizzeria_da_mario"):
		var c = active_contracts["pizzeria_da_mario"]
		c["status"] = "completed"
		var reward = float(c["budget"])
		var rep = int(c["reputation_reward"])
		completed_contracts.append("pizzeria_da_mario")
		
		EconomyManager.earn(reward, "Compenso Sito Web - Pizzeria Da Mario")
		GameManager.reputation_points += rep
		
		EventBus.contract_completed.emit("pizzeria_da_mario", reward, rep)
		EventBus.contract_updated.emit("pizzeria_da_mario", "completed")
		EventBus.notification_posted.emit(
			"Progetto Consegnato!",
			"Mario è entusiasta! Hai guadagnato €%0.2f e +%d Reputazione. Ora puoi accedere al Marketplace aperto nel Freelance Hub!" % [reward, rep],
			"success"
		)
		SoundManager.play_ui_success()
		SaveManager.request_auto_save()

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
