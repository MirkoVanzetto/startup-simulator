class_name QuestManager
extends Node
## QuestManager - Centralized state-aware dynamic objective and quest tracking system.
## Dynamically evaluates story progression, store upgrades, company tier expansion,
## and B2B marketplace contracts without hardcoded or frozen HUD strings.

signal objective_updated(text: String, category: String, is_complete: bool)

static var instance: Node = null

func _init() -> void:
	if instance == null:
		instance = self

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if instance == self:
			instance = null

func _ready() -> void:
	if instance == null:
		instance = self
	
	if Engine.has_singleton("EventBus") or is_instance_valid(EventBus):
		EventBus.contract_updated.connect(_on_contract_updated)
		EventBus.contract_completed.connect(_on_contract_completed)
		EventBus.item_purchased.connect(_on_item_purchased)
		if EventBus.has_signal("contract_marketplace_refreshed"):
			EventBus.contract_marketplace_refreshed.connect(_on_marketplace_refreshed)
		if EventBus.has_signal("employee_hired"):
			EventBus.employee_hired.connect(_on_employee_hired)
		if EventBus.has_signal("needs_changed"):
			EventBus.needs_changed.connect(_on_needs_changed)

var _last_needs_hint: String = ""

func _on_needs_changed(_hunger: float, _energy: float) -> void:
	# Aggiorna l'obiettivo solo quando il suggerimento fame/energia cambia
	var hint = get_needs_hint()
	if hint != _last_needs_hint:
		_last_needs_hint = hint
		refresh_objective()

func _on_contract_updated(_contract_id: String, _status: String) -> void:
	refresh_objective()

func _on_contract_completed(_contract_id: String, _reward: float, _reputation: int) -> void:
	refresh_objective()

func _on_item_purchased(item_id: String, _cost: float) -> void:
	if not item_id in GameManager.studio_upgrades_installed:
		GameManager.studio_upgrades_installed.append(item_id)
	refresh_objective()

func _on_marketplace_refreshed() -> void:
	refresh_objective()

func _on_employee_hired(_emp_id: String, _emp_name: String) -> void:
	refresh_objective()

## Evaluates the active world/inventory state and returns the current objective text.
## Dopo il tutorial aggiunge (senza bloccare la storia) un suggerimento su fame/energia.
func get_current_objective() -> String:
	var objective = _get_story_objective()
	var hint = get_needs_hint()
	if hint != "":
		objective += "\n" + hint
	return objective

## Suggerimento non bloccante sui bisogni (solo dopo il tutorial, cioè dopo il contratto di Mario).
func get_needs_hint() -> String:
	if not ContractManager.is_contract_completed("pizzeria_da_mario"):
		return ""
	if NeedsManager.get_hunger() < 50.0:
		return "Mangia qualcosa: la fame è sotto il 50%. Prova la Pizzeria, il Forno o l'Alimentari."
	if NeedsManager.get_energy() < 30.0:
		return "Riposa: bevi un caffè o dormi nel tuo studio."
	return ""

func _get_story_objective() -> String:
	# Priority 1: Story contract 1 (pizzeria_da_mario)
	if not ContractManager.is_contract_completed("pizzeria_da_mario"):
		var tut = ContractManager.get_tutorial_contract()
		if not tut.is_empty():
			var status = tut.get("status", "available")
			match status:
				"available":
					return "Raggiungi la Pizzeria Da Mario in Via Po e parla con Mario."
				"in_progress":
					return "Rientra in studio e sviluppa il sito web per Mario su WebForge."
				"built":
					return "Consegna la release del sito a Mario tramite TO-OS sul laptop."
				_:
					return "Raggiungi la Pizzeria Da Mario in Via Po e parla con Mario."
		elif ContractManager.completed_contracts.is_empty():
			return "Controlla il laptop sul tuo banco di lavoro per iniziare."

	# Priority 2: Studio Upgrade (State-Aware!)
	# If player already owns any upgrade, this step is automatically satisfied!
	if GameManager.studio_upgrades_installed.is_empty():
		return "Visita TorinoHardware sul laptop per acquistare i primi upgrade per lo studio."

	# Priority 3: Story contract 2 (caffe_san_carlo)
	if not ContractManager.is_contract_completed("caffe_san_carlo"):
		var c = ContractManager.get_contract("caffe_san_carlo")
		var status = c.get("status", "available")
		match status:
			"available":
				return "Visita il Caffè San Carlo in Via Po e parla con Elena al bancone."
			"in_progress":
				return "Usa WebForge sul laptop per sviluppare il Touch POS per Elena."
			"built":
				return "Consegna il Web POS a Elena tramite TO-OS sul laptop."
			_:
				return "Visita il Caffè San Carlo in Via Po e parla con Elena al bancone."

	# Priority 4: Story contract 3 (elettronica_to)
	if not ContractManager.is_contract_completed("elettronica_to"):
		var c = ContractManager.get_contract("elettronica_to")
		var status = c.get("status", "available")
		match status:
			"available":
				return "Incontra Davide da Elettronica TO in Via Po per la migrazione Cloud."
			"in_progress":
				return "Configura il cluster Cloud su WebForge e installa il Server Rack."
			"built":
				return "Consegna l'infrastruttura Cloud a Davide per completare il contratto."
			_:
				return "Incontra Davide da Elettronica TO in Via Po per la migrazione Cloud."

	# Priority 5: Startup Expansion
	var comp_tier = GameManager.get("company_tier") if ("company_tier" in GameManager) else 1
	if comp_tier < 2:
		return "Raggiungi 50 Reputazione e registra l'espansione aziendale su TO-OS per assumere personale."

	# Priority 6: Marketplace B2B freelance projects
	for cid in ContractManager.active_contracts:
		if cid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to"]:
			continue
		var c = ContractManager.active_contracts[cid]
		if c.get("status") == "in_progress":
			return "Completa il progetto B2B '%s' su WebForge IDE." % c.get("title", cid)
		elif c.get("status") == "built":
			return "Consegna il progetto '%s' tramite TO-OS per riscuotere il compenso." % c.get("title", cid)

	return "Esplora il marketplace freelance su TO-OS per nuovi progetti B2B."

## Returns the narrative/functional category for the active objective.
func get_current_category() -> String:
	if not ContractManager.is_contract_completed("pizzeria_da_mario"):
		return "Storia"
	if GameManager.studio_upgrades_installed.is_empty():
		return "Upgrade"
	if not ContractManager.is_contract_completed("caffe_san_carlo"):
		return "Storia"
	if not ContractManager.is_contract_completed("elettronica_to"):
		return "Enterprise"
	var comp_tier = GameManager.get("company_tier") if ("company_tier" in GameManager) else 1
	if comp_tier < 2:
		return "Espansione"
	return "Freelance"

func get_current_quest_info() -> Dictionary:
	return {
		"text": get_current_objective(),
		"category": get_current_category(),
		"is_complete": is_story_completed() and (GameManager.get("company_tier") >= 2 if "company_tier" in GameManager else true)
	}

func refresh_objective() -> void:
	var info = get_current_quest_info()
	objective_updated.emit(info.text, info.category, info.is_complete)

func is_studio_upgrade_objective_satisfied() -> bool:
	return not GameManager.studio_upgrades_installed.is_empty()

func is_story_completed() -> bool:
	return ContractManager.is_contract_completed("pizzeria_da_mario") and \
		ContractManager.is_contract_completed("caffe_san_carlo") and \
		ContractManager.is_contract_completed("elettronica_to")

static func get_instance() -> Node:
	return instance

static func get_objective() -> String:
	if instance != null:
		return instance.get_current_objective()
	var script = load("res://scripts/core/quest_manager.gd") as GDScript
	var temp = script.new()
	var result = temp.get_current_objective()
	return result

