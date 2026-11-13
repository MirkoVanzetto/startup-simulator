extends Node
## ContractManager - Handles active client commissions, story missions, paced B2B leads, and Officina Bellini

const ContractGenerator = preload("res://scripts/contracts/contract_generator.gd")

const FACTORY_SCOUT_ZONES: Array[String] = [
	"scout_ingresso",
	"scout_magazzino",
	"scout_ufficio",
	"scout_vetrina"
]

var active_contracts: Dictionary = {}
var completed_contracts: Array[String] = []
var marketplace_contracts: Array[Dictionary] = []

var lead_timer_minutes: int = 0
var preferred_webforge_contract_id: String = ""
var preferred_netshield_contract_id: String = ""
var factory_state: Dictionary = {}

func _default_factory_state() -> Dictionary:
	return {
		"accepted": false,
		"scouted": [],
		"wifi_hardware_mounted": false,
		"wifi_done": false,
		"web_done": false,
		"server_done": false,
		"pcs_done": false,
		"completed": false
	}

func _ready() -> void:
	factory_state = _default_factory_state()
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.time_tick.connect(_on_time_tick)
	EventBus.employee_hired.connect(_on_employee_hired)

func init_tutorial_contract() -> void:
	active_contracts.clear()
	completed_contracts.clear()
	marketplace_contracts.clear()
	lead_timer_minutes = 0
	preferred_webforge_contract_id = ""
	preferred_netshield_contract_id = ""
	factory_state = _default_factory_state()

	active_contracts["pizzeria_da_mario"] = {
		"id": "pizzeria_da_mario",
		"title": "Sito Web Ufficiale per Pizzeria Da Mario",
		"client": "Mario Esposito",
		"category": "Web Development",
		"execution_type": "webforge",
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

	# Non generiamo lead immediati al Giorno 1: arrivano periodicamente dopo i primi incarichi o assumendo Luca.
	_stamp_fame_bonus()
	EventBus.contract_updated.emit("pizzeria_da_mario", "available")
	EventBus.contract_marketplace_refreshed.emit()

func refresh_marketplace() -> void:
	var budget_mult := 1.15 if EmployeeManager.is_employee_hired("emp_luca") else 1.0
	marketplace_contracts = ContractGenerator.generate_initial_marketplace_pool(2, budget_mult)
	EventBus.contract_marketplace_refreshed.emit()

func get_lead_interval_minutes() -> int:
	if not is_contract_completed("pizzeria_da_mario"):
		return 0 # Durante il tutorial iniziale i lead B2B restano in pausa
	if EmployeeManager.is_employee_hired("emp_luca"):
		return 120 # Luca Vianello (Client Scout) trova un nuovo lead ogni 2 ore di gioco!
	if is_contract_completed("elettronica_to"):
		return 360 # Ogni 6 ore senza scout dedicato
	return 720 # Dopo Mario ma prima di Davide: un'occasione occasionale ogni 12 ore

func get_max_marketplace_pool() -> int:
	if not is_contract_completed("pizzeria_da_mario"):
		return 0
	if EmployeeManager.is_employee_hired("emp_luca"):
		return 5
	if is_contract_completed("elettronica_to"):
		return 3
	return 2

func get_lead_eta_text() -> String:
	if not is_contract_completed("pizzeria_da_mario"):
		return "Completa il primo sito per Pizzeria Da Mario per aprire la bacheca B2B."
	var interval := get_lead_interval_minutes()
	var pool_cap := get_max_marketplace_pool()
	if marketplace_contracts.size() >= pool_cap:
		return "Bacheca piena (%d/%d offerte attive): accetta o libera incarichi per ricevere nuovi lead." % [marketplace_contracts.size(), pool_cap]
	var rem := maxi(1, interval - lead_timer_minutes)
	var hrs := rem / 60
	var mins := rem % 60
	if EmployeeManager.is_employee_hired("emp_luca"):
		return "Luca Vianello (Scout attivo, +15%% budget) — Prossimo lead tra ~%dh %02dm (%d/%d slot)" % [hrs, mins, marketplace_contracts.size(), pool_cap]
	return "Ricerca passiva lenta — Prossimo lead tra ~%dh %02dm (%d/%d). Assumi Luca per lead ogni 2h!" % [hrs, mins, marketplace_contracts.size(), pool_cap]

func discover_new_lead(force_notify: bool = true) -> Dictionary:
	var pool_cap := get_max_marketplace_pool()
	if pool_cap <= 0:
		pool_cap = 3
	if marketplace_contracts.size() >= pool_cap:
		return {}
	var budget_mult := 1.15 if EmployeeManager.is_employee_hired("emp_luca") else 1.0
	var gig := ContractGenerator.generate_random_contract(0, budget_mult)
	marketplace_contracts.append(gig)
	EventBus.contract_marketplace_refreshed.emit()
	if force_notify:
		var source_str := "Scout Luca Vianello" if EmployeeManager.is_employee_hired("emp_luca") else "Freelance Hub"
		EventBus.notification_posted.emit(
			"Nuova Richiesta (%s)" % source_str,
			"%s — Budget € %0.2f su TO-OS." % [gig["title"], float(gig["budget"])],
			"contract"
		)
	return gig

func _on_time_tick(_h: int, _m: int, _d: int) -> void:
	var interval := get_lead_interval_minutes()
	if interval <= 0:
		return
	if marketplace_contracts.size() >= get_max_marketplace_pool():
		return
	lead_timer_minutes += 1
	if lead_timer_minutes >= interval:
		lead_timer_minutes = 0
		discover_new_lead(true)

func _on_day_passed(_new_day: int) -> void:
	var interval := get_lead_interval_minutes()
	if interval <= 0:
		return
	# Simula lead arrivati durante la notte quando cambia giorno / il player dorme
	lead_timer_minutes += 480
	var safety := 0
	while lead_timer_minutes >= interval and marketplace_contracts.size() < get_max_marketplace_pool() and safety < 3:
		lead_timer_minutes -= interval
		safety += 1
		discover_new_lead(false)

func _on_employee_hired(emp_id: String, _emp_name: String) -> void:
	if emp_id == "emp_luca":
		lead_timer_minutes = 0
		# Assumere Luca sblocca subito fino a 2 lead ad alto budget
		var found := 0
		for _i in range(2):
			if not discover_new_lead(false).is_empty():
				found += 1
		if found > 0:
			EventBus.notification_posted.emit(
				"Outreach Luca Vianello",
				"Luca ha appena individuato %d nuovi clienti B2B su Freelance Hub (+15%% budget)!" % found,
				"contract"
			)

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
		var reward = float(c["budget"]) * float(c.get("fame_bonus", 1.0))
		var rep = int(c["reputation_reward"])
		completed_contracts.append(contract_id)

		if EmployeeManager.is_employee_hired("emp_marco"):
			reward *= 1.20 # +20% Marco Ferri closer perk

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

		_unlock_next_story_mission(contract_id)
		_stamp_fame_bonus()
		SaveManager.request_auto_save()

func _stamp_fame_bonus() -> void:
	var bonus = FameManager.get_contract_bonus()
	for cid in active_contracts:
		var c = active_contracts[cid]
		if c is Dictionary and not c.has("fame_bonus") and c.get("status", "") != "completed":
			c["fame_bonus"] = bonus

func _unlock_next_story_mission(just_completed_id: String) -> void:
	match just_completed_id:
		"pizzeria_da_mario":
			active_contracts["caffe_san_carlo"] = {
				"id": "caffe_san_carlo",
				"title": "Sistema Touch Web POS & Prenotazioni per Caffè San Carlo",
				"client": "Elena Barista",
				"category": "Web Application / POS",
				"execution_type": "webforge",
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
			# Primo piccolo lead su Freelance Hub dopo Mario!
			lead_timer_minutes = 0
			discover_new_lead(false)
			EventBus.contract_updated.emit("caffe_san_carlo", "available")
			EventBus.notification_posted.emit(
				"Nuova Opportunità Sbloccata!",
				"Elena del Caffè San Carlo cerca un Web POS! Intanto è arrivato il primo lead B2B su Freelance Hub.",
				"contract"
			)
		"caffe_san_carlo":
			active_contracts["elettronica_to"] = {
				"id": "elettronica_to",
				"title": "Migrazione Cloud & Catalogo B2B Elettronica TO",
				"client": "Davide Tecnico",
				"category": "Cloud Infrastructure & Backend",
				"execution_type": "webforge",
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
			discover_new_lead(false)
			EventBus.notification_posted.emit(
				"Missioni San Carlo Completate!",
				"Davide consiglia di visitare l'Officina Bellini a Borgo Valdocco (strada Est) o espandere i contratti B2B su Freelance Hub!",
				"success"
			)

func accept_marketplace_contract(contract_id: String) -> bool:
	for i in range(marketplace_contracts.size()):
		var c = marketplace_contracts[i]
		if c["id"] == contract_id:
			c["status"] = "in_progress"
			c["fame_bonus"] = FameManager.get_contract_bonus()
			active_contracts[contract_id] = c
			marketplace_contracts.remove_at(i)
			if c.get("execution_type", "webforge") == "webforge":
				preferred_webforge_contract_id = contract_id
			elif c.get("execution_type", "") == "netshield":
				preferred_netshield_contract_id = contract_id
			EventBus.contract_updated.emit(contract_id, "in_progress")
			EventBus.notification_posted.emit("Contratto B2B Accettato!", "Preso in carico: " + c["title"], "info")
			EventBus.contract_marketplace_refreshed.emit()
			SaveManager.request_auto_save()
			return true
	return false

func complete_marketplace_contract(contract_id: String) -> bool:
	if active_contracts.has(contract_id):
		var c = active_contracts[contract_id]
		if c.get("status") == "completed" or (contract_id in completed_contracts):
			return false
		c["status"] = "completed"
		var reward = float(c["budget"]) * float(c.get("fame_bonus", 1.0))
		if EmployeeManager.is_employee_hired("emp_marco"):
			reward *= 1.20

		var rep = int(c["reputation_reward"])
		completed_contracts.append(contract_id)

		EconomyManager.earn(reward, "Liquidazione Progetto: " + c["title"])
		GameManager.reputation_points += rep

		EventBus.contract_completed.emit(contract_id, reward, rep)
		EventBus.contract_updated.emit(contract_id, "completed")
		EventBus.notification_posted.emit("Lavoro Liquidato!", "Incassati € %0.2f e +%d Reputazione!" % [reward, rep], "success")

		if contract_id == "factory_bellini_web":
			on_factory_web_completed()

		SaveManager.request_auto_save()
		return true
	return false

func deliver_hardware_contract(contract_id: String) -> bool:
	if not active_contracts.has(contract_id):
		return false
	var c: Dictionary = active_contracts[contract_id]
	if c.get("status", "") == "completed":
		return false
	var req_hw: Dictionary = c.get("required_hardware", {})
	var missing: Array[String] = []
	for hw_id in req_hw:
		var need_qty := int(req_hw[hw_id])
		var have_qty := ShopManager.get_hardware_count(str(hw_id))
		if have_qty < need_qty:
			missing.append("%s (%d/%d)" % [ShopManager.get_hardware_item_name(str(hw_id)), have_qty, need_qty])
	if not missing.is_empty():
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit(
			"Componenti Mancanti",
			"Acquista prima da Elettronica TO: " + ", ".join(missing),
			"warning"
		)
		return false
	for hw_id in req_hw:
		ShopManager.consume_hardware(str(hw_id), int(req_hw[hw_id]))
	return complete_marketplace_contract(contract_id)

# ==============================================================================
# OFFICINA BELLINI — GRANDE APPALTO BORGO VALDOCCO (4 PILASTRI + 4 SOPRALLUOGHI)
# ==============================================================================

func accept_factory_commission() -> void:
	if bool(factory_state.get("accepted", false)):
		return
	factory_state["accepted"] = true
	active_contracts["factory_bellini_web"] = {
		"id": "factory_bellini_web",
		"title": "Portale & Catalogo B2B Officina Meccanica Bellini",
		"client": "Ing. Gianluca Bellini (Officina Valdocco)",
		"category": "Web Development",
		"execution_type": "webforge",
		"location": "Borgo Valdocco (Est)",
		"brief": "Portale industriale con listino lavorazioni CNC, richiesta preventivi B2B, orari di carico/scarico e stile tecnico robusto.",
		"preferred_tags": ["Tech", "Booking"],
		"preferred_palette": "amber",
		"budget": 950.00,
		"reputation_reward": 22,
		"difficulty": 3,
		"deadline_days": 5,
		"status": "in_progress",
		"objective_text": "Sviluppa il sito industriale di Officina Bellini su WebForge (TO-OS).",
		"requirements": [
			"Header Officina Meccanica Bellini",
			"Hero Reparto CNC & Lavorazioni di Precisione",
			"Catalogo Lavorazioni & Preventivi Rapidi"
		],
		"website_build_data": {}
	}
	_stamp_fame_bonus()
	preferred_webforge_contract_id = "factory_bellini_web"
	EventBus.contract_updated.emit("factory_bellini", "accepted")
	EventBus.contract_updated.emit("factory_bellini_web", "in_progress")
	EventBus.notification_posted.emit(
		"Maxi-Commessa Bellini Avviata!",
		"Perlustra le 4 zone dell'Officina per sbloccare Wi-Fi, Server e Workstation PC!",
		"contract"
	)
	SoundManager.play_ui_success()
	SaveManager.request_auto_save()

func is_factory_zone_scouted(zone_id: String) -> bool:
	var arr: Array = factory_state.get("scouted", [])
	return zone_id in arr

func get_factory_scouted_count() -> int:
	var arr: Array = factory_state.get("scouted", [])
	return arr.size()

func is_factory_all_scouted() -> bool:
	return get_factory_scouted_count() >= FACTORY_SCOUT_ZONES.size()

func scout_factory_zone(zone_id: String, zone_title: String = "") -> bool:
	if not bool(factory_state.get("accepted", false)):
		accept_factory_commission()
	var arr: Array = factory_state.get("scouted", [])
	if zone_id in arr:
		return false
	arr.append(zone_id)
	factory_state["scouted"] = arr
	GameManager.reputation_points += 2
	var label := zone_title if zone_title != "" else zone_id
	if is_factory_all_scouted():
		GameManager.reputation_points += 4
		EventBus.notification_posted.emit(
			"Sopralluogo Officina Completo (4/4)!",
			"Rilievo terminato (%s). Puoi ora installare Router Wi-Fi, Server Xeon e 2 PC da Elettronica TO!" % label,
			"success"
		)
	else:
		EventBus.notification_posted.emit(
			"Zona Perlustrata (%d/4)" % arr.size(),
			"Verificato %s! Restano %d zone da ispezionare in officina." % [label, FACTORY_SCOUT_ZONES.size() - arr.size()],
			"info"
		)
	SoundManager.play_ui_success()
	EventBus.contract_updated.emit("factory_bellini", "scouted")
	SaveManager.request_auto_save()
	return true

func mount_factory_wifi_hardware() -> bool:
	if not is_factory_all_scouted():
		EventBus.notification_posted.emit("Sopralluogo Incompleto", "Prima perlustra tutte e 4 le zone della fabbrica!", "warning")
		return false
	if bool(factory_state.get("wifi_hardware_mounted", false)) or bool(factory_state.get("wifi_done", false)):
		return false
	if not ShopManager.has_hardware("hw_wifi_router", 1):
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Serve 1x Router Wi-Fi 6", "Acquista 'Router Wi-Fi 6 Dual-Band Mesh' da Elettronica TO o TorinoHardware!", "warning")
		return false
	ShopManager.consume_hardware("hw_wifi_router", 1)
	factory_state["wifi_hardware_mounted"] = true
	preferred_netshield_contract_id = "factory_bellini_wifi"
	EventBus.contract_updated.emit("factory_bellini", "wifi_mounted")
	EventBus.notification_posted.emit(
		"Router Wi-Fi 6 Montato!",
		"Hardware posizionato in reparto. Configura VLAN & Firewall su NetShield Cyber dal tuo laptop!",
		"success"
	)
	SoundManager.play_ui_success()
	SaveManager.request_auto_save()
	return true

func complete_factory_wifi_netshield() -> bool:
	if not bool(factory_state.get("wifi_hardware_mounted", false)) or bool(factory_state.get("wifi_done", false)):
		return false
	factory_state["wifi_done"] = true
	var pay := 350.0
	if EmployeeManager.is_employee_hired("emp_marco"):
		pay *= 1.20
	EconomyManager.earn(pay, "Officina Bellini: Configurazione Wi-Fi 6 & VLAN")
	GameManager.reputation_points += 12
	EventBus.contract_completed.emit("factory_bellini_wifi", pay, 12)
	EventBus.contract_updated.emit("factory_bellini", "wifi_done")
	EventBus.notification_posted.emit("Wi-Fi & VLAN Officina Operativi!", "Incassati € %0.2f (+12 Rep)." % pay, "success")
	_check_factory_grand_completion()
	SaveManager.request_auto_save()
	return true

func install_factory_server() -> bool:
	if not is_factory_all_scouted():
		EventBus.notification_posted.emit("Sopralluogo Incompleto", "Prima perlustra tutte e 4 le zone della fabbrica!", "warning")
		return false
	if bool(factory_state.get("server_done", false)):
		return false
	if not ShopManager.has_hardware("hw_server_tower", 1):
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Serve 1x Server Tower Xeon", "Acquista 'Server Tower Xeon 8-Core RAID-10' da Elettronica TO o TorinoHardware!", "warning")
		return false
	ShopManager.consume_hardware("hw_server_tower", 1)
	factory_state["server_done"] = true
	var pay := 820.0
	if EmployeeManager.is_employee_hired("emp_marco"):
		pay *= 1.20
	EconomyManager.earn(pay, "Officina Bellini: Installazione Server Xeon RAID-10")
	GameManager.reputation_points += 18
	SoundManager.play_cash_register()
	EventBus.contract_completed.emit("factory_bellini_server", pay, 18)
	EventBus.contract_updated.emit("factory_bellini", "server_done")
	EventBus.notification_posted.emit("Server Xeon Officina Installato!", "Incassati € %0.2f (+18 Rep)." % pay, "success")
	_check_factory_grand_completion()
	SaveManager.request_auto_save()
	return true

func install_factory_pcs() -> bool:
	if not is_factory_all_scouted():
		EventBus.notification_posted.emit("Sopralluogo Incompleto", "Prima perlustra tutte e 4 le zone della fabbrica!", "warning")
		return false
	if bool(factory_state.get("pcs_done", false)):
		return false
	if not ShopManager.has_hardware("hw_workstation_pc", 2):
		SoundManager.play_ui_error()
		var cur := ShopManager.get_hardware_count("hw_workstation_pc")
		EventBus.notification_posted.emit("Servono 2x Workstation PC", "In inventario hai %d/2 PC Workstation CAD & Ufficio. Acquista da Elettronica TO!" % cur, "warning")
		return false
	ShopManager.consume_hardware("hw_workstation_pc", 2)
	factory_state["pcs_done"] = true
	var pay := 960.0
	if EmployeeManager.is_employee_hired("emp_marco"):
		pay *= 1.20
	EconomyManager.earn(pay, "Officina Bellini: Installazione 2 Workstation CAD")
	GameManager.reputation_points += 18
	SoundManager.play_cash_register()
	EventBus.contract_completed.emit("factory_bellini_pcs", pay, 18)
	EventBus.contract_updated.emit("factory_bellini", "pcs_done")
	EventBus.notification_posted.emit("Postazioni Ufficio Bellini Collaudate!", "Incassati € %0.2f (+18 Rep)." % pay, "success")
	_check_factory_grand_completion()
	SaveManager.request_auto_save()
	return true

func on_factory_web_completed() -> void:
	factory_state["web_done"] = true
	EventBus.contract_updated.emit("factory_bellini", "web_done")
	_check_factory_grand_completion()

func _check_factory_grand_completion() -> void:
	if bool(factory_state.get("completed", false)):
		return
	if bool(factory_state.get("wifi_done", false)) and bool(factory_state.get("web_done", false)) and bool(factory_state.get("server_done", false)) and bool(factory_state.get("pcs_done", false)):
		factory_state["completed"] = true
		if not ("factory_bellini" in completed_contracts):
			completed_contracts.append("factory_bellini")
		var bonus := 1500.0
		EconomyManager.earn(bonus, "Premio Maxi-Appalto Completato: Officina Bellini")
		GameManager.reputation_points += 40
		SoundManager.play_ui_success()
		EventBus.contract_completed.emit("factory_bellini", bonus, 40)
		EventBus.contract_updated.emit("factory_bellini", "completed")
		EventBus.notification_posted.emit(
			"MAXI-APPALTO OFFICINA BELLINI COMPLETATO!",
			"Wi-Fi, Server, 2 PC & Sito Web consegnati! Bonus finale +€ 1.500,00 & +40 Reputazione!",
			"success"
		)

func get_factory_progress_summary() -> Dictionary:
	var pillars_done := 0
	for k in ["wifi_done", "web_done", "server_done", "pcs_done"]:
		if bool(factory_state.get(k, false)):
			pillars_done += 1
	return {
		"accepted": bool(factory_state.get("accepted", false)),
		"scouted_count": get_factory_scouted_count(),
		"all_scouted": is_factory_all_scouted(),
		"wifi_mounted": bool(factory_state.get("wifi_hardware_mounted", false)),
		"wifi_done": bool(factory_state.get("wifi_done", false)),
		"web_done": bool(factory_state.get("web_done", false)),
		"server_done": bool(factory_state.get("server_done", false)),
		"pcs_done": bool(factory_state.get("pcs_done", false)),
		"pillars_done": pillars_done,
		"completed": bool(factory_state.get("completed", false))
	}

static func _parse_vec2i_key(raw_key) -> Variant:
	if raw_key is Vector2i:
		return raw_key
	if raw_key is Vector2:
		return Vector2i(int(raw_key.x), int(raw_key.y))
	var s := str(raw_key).strip_edges()
	s = s.trim_prefix("(").trim_suffix(")")
	var parts := s.split(",")
	if parts.size() == 2:
		return Vector2i(int(parts[0].strip_edges()), int(parts[1].strip_edges()))
	return null

static func _normalize_contract_dict(c: Dictionary) -> Dictionary:
	var out := c.duplicate(true)
	for cp_key in ["netshield_checkpoints", "checkpoints"]:
		if out.has(cp_key) and out[cp_key] is Dictionary:
			var fixed_cp := {}
			for rk in out[cp_key].keys():
				var v2 = _parse_vec2i_key(rk)
				if v2 is Vector2i:
					fixed_cp[v2] = int(out[cp_key][rk])
			out[cp_key] = fixed_cp
	return out

func serialize() -> Dictionary:
	return {
		"active": active_contracts.duplicate(true),
		"completed": completed_contracts.duplicate(),
		"marketplace": marketplace_contracts.duplicate(true),
		"lead_timer_minutes": lead_timer_minutes,
		"preferred_webforge_contract_id": preferred_webforge_contract_id,
		"preferred_netshield_contract_id": preferred_netshield_contract_id,
		"factory_state": factory_state.duplicate(true)
	}

func deserialize(data: Dictionary) -> void:
	active_contracts.clear()
	var raw_active = data.get("active", {})
	if raw_active is Dictionary:
		for k in raw_active:
			if raw_active[k] is Dictionary:
				active_contracts[str(k)] = _normalize_contract_dict(raw_active[k])
	completed_contracts.clear()
	for c in data.get("completed", []):
		completed_contracts.append(str(c))
	marketplace_contracts.clear()
	for mc in data.get("marketplace", []):
		if mc is Dictionary:
			marketplace_contracts.append(_normalize_contract_dict(mc))
	lead_timer_minutes = int(data.get("lead_timer_minutes", 0))
	preferred_webforge_contract_id = str(data.get("preferred_webforge_contract_id", ""))
	preferred_netshield_contract_id = str(data.get("preferred_netshield_contract_id", ""))
	var fs = data.get("factory_state", {})
	factory_state = _default_factory_state()
	if fs is Dictionary:
		for k in fs:
			factory_state[k] = fs[k]
	EventBus.contract_marketplace_refreshed.emit()
	EventBus.contract_updated.emit("factory_bellini", "loaded")
