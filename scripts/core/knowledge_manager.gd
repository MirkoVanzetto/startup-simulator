extends Node
## KnowledgeManager - Sistema Ricerca & Skill della Conoscenza Post-Bellini (Startup Simulator).
## Si sblocca solo dopo il completamento del Maxi-Appalto Officina Bellini a Borgo Valdocco.
## A Rank 0 su tutti i rami restituisce valori strettamente neutri (1.0x / 0.0 / []).

const MAX_RANK: int = 3

const TRACK_ORDER: Array[String] = [
	"web_architecture",
	"cloud_devops",
	"cyber_governance",
	"ai_automation"
]

const TRACKS: Dictionary = {
	"web_architecture": {
		"id": "web_architecture",
		"title": "Architettura Web & UX",
		"icon": "🌐",
		"specialty_tag": "Web & Portali",
		"summary": "Sblocca commesse web complesse su Freelance Hub (+12%/liv. compenso) e accelera WebForge IDE (-0.30s/liv.).",
		"costs": [380.0, 820.0, 1550.0],
		"rep_reqs": [40, 75, 115],
		"effect_labels": [
			"Base (Nessuna ricerca)",
			"Lv.1 · Commesse UX Pro · +12% paga Web · -0.3s WebForge",
			"Lv.2 · Micro-Frontend & Design System · +24% paga Web · -0.6s",
			"Lv.3 · Web Architecture Lead · +36% paga Web · -0.9s"
		]
	},
	"cloud_devops": {
		"id": "cloud_devops",
		"title": "Cloud, DevOps & Cluster",
		"icon": "☁",
		"specialty_tag": "Cloud & Server",
		"summary": "Sblocca appalti Cloud & Cluster ibridi, +10%/liv. rendita Server Rack e +12%/liv. compenso Cloud/Hardware.",
		"costs": [420.0, 900.0, 1680.0],
		"rep_reqs": [45, 80, 120],
		"effect_labels": [
			"Base (Nessuna ricerca)",
			"Lv.1 · Orchestrazione Container · +10% Rack · +12% Cloud/HW",
			"Lv.2 · Failover Multi-Region · +20% Rack · +24% Cloud/HW",
			"Lv.3 · Principal Cloud Architect · +30% Rack · +36% Cloud/HW"
		]
	},
	"cyber_governance": {
		"id": "cyber_governance",
		"title": "Cybersecurity & NIS2",
		"icon": "🛡",
		"specialty_tag": "Cyber & Audit",
		"summary": "Sblocca audit compliance NIS2 & reti bancarie su NetShield con +12%/liv. compenso su commesse Cyber.",
		"costs": [450.0, 960.0, 1780.0],
		"rep_reqs": [50, 85, 125],
		"effect_labels": [
			"Base (Nessuna ricerca)",
			"Lv.1 · Audit Perimetrale · +12% commesse Cyber/NetShield",
			"Lv.2 · SOC & Pentest PMI · +24% commesse Cyber/NetShield",
			"Lv.3 · CISO Advisor NIS2 · +36% commesse Cyber/NetShield"
		]
	},
	"ai_automation": {
		"id": "ai_automation",
		"title": "AI & Automazione Industriale",
		"icon": "🤖",
		"specialty_tag": "AI & Robotica",
		"summary": "Sblocca progetti AI Vision, RAG aziendale e nodi Edge GPU con +12%/liv. compenso su contratti AI & Bot.",
		"costs": [520.0, 1100.0, 1950.0],
		"rep_reqs": [55, 95, 135],
		"effect_labels": [
			"Base (Nessuna ricerca)",
			"Lv.1 · Copilot & Automazioni · +12% commesse AI/Bot",
			"Lv.2 · Visione Artificiale PMI · +24% commesse AI/Bot",
			"Lv.3 · Enterprise AI & Digital Twin · +36% commesse AI/Bot"
		]
	}
}

var ranks: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_all_ranks()

func _ensure_all_ranks() -> void:
	for k in TRACK_ORDER:
		if not ranks.has(k):
			ranks[k] = 0

func is_unlocked() -> bool:
	if not is_instance_valid(ContractManager):
		return false
	return ContractManager.is_contract_completed("factory_bellini") \
		or bool(ContractManager.factory_state.get("completed", false))

func get_rank(track_id: String) -> int:
	return clampi(int(ranks.get(track_id, 0)), 0, MAX_RANK)

func get_total_rank() -> int:
	var tot := 0
	for k in TRACK_ORDER:
		tot += get_rank(k)
	return tot

func get_next_cost(track_id: String) -> float:
	var def: Dictionary = TRACKS.get(track_id, {})
	if def.is_empty():
		return -1.0
	var cur := get_rank(track_id)
	if cur >= MAX_RANK:
		return -1.0
	var costs: Array = def.get("costs", [])
	if cur >= costs.size():
		return -1.0
	return float(costs[cur])

func get_next_rep_req(track_id: String) -> int:
	var def: Dictionary = TRACKS.get(track_id, {})
	if def.is_empty():
		return -1
	var cur := get_rank(track_id)
	if cur >= MAX_RANK:
		return -1
	var reqs: Array = def.get("rep_reqs", [])
	if cur >= reqs.size():
		return -1
	return int(reqs[cur])

func get_unlocked_specialties() -> Array[String]:
	var out: Array[String] = []
	for k in TRACK_ORDER:
		if get_rank(k) > 0:
			out.append(k)
	return out

func can_study(track_id: String) -> Dictionary:
	if not TRACKS.has(track_id):
		return {"allowed": false, "reason": "Percorso di ricerca non valido."}
	if not is_unlocked():
		return {
			"allowed": false,
			"reason": "Sblocca prima Conoscenza R&D completando il Maxi-Appalto Officina Bellini (Borgo Valdocco).",
			"cost": get_next_cost(track_id),
			"rep_req": get_next_rep_req(track_id),
			"next_rank": get_rank(track_id) + 1
		}
	var cur := get_rank(track_id)
	if cur >= MAX_RANK:
		return {
			"allowed": false,
			"reason": "Padronanza massima raggiunta (Livello 3/3).",
			"cost": -1.0,
			"rep_req": -1,
			"next_rank": MAX_RANK
		}
	var cost := get_next_cost(track_id)
	var rep_req := get_next_rep_req(track_id)
	var next_rk := cur + 1
	if GameManager.reputation_points < rep_req:
		return {
			"allowed": false,
			"reason": "Reputazione insufficiente: servono %d Rep (attuali: %d)." % [rep_req, GameManager.reputation_points],
			"cost": cost,
			"rep_req": rep_req,
			"next_rank": next_rk
		}
	if not EconomyManager.can_afford(cost):
		return {
			"allowed": false,
			"reason": "Fondi insufficienti: servono € %0.2f." % cost,
			"cost": cost,
			"rep_req": rep_req,
			"next_rank": next_rk
		}
	return {
		"allowed": true,
		"reason": "",
		"cost": cost,
		"rep_req": rep_req,
		"next_rank": next_rk
	}

func study(track_id: String) -> bool:
	var chk := can_study(track_id)
	if not bool(chk.get("allowed", false)):
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Ricerca Non Disponibile", str(chk.get("reason", "Requisiti non soddisfatti.")), "warning")
		return false

	var cost := float(chk.get("cost", 0.0))
	var next_rk := int(chk.get("next_rank", get_rank(track_id) + 1))
	var title := str(TRACKS[track_id].get("title", track_id))

	if not EconomyManager.spend(cost, "Ricerca R&D: %s Lv.%d" % [title, next_rk]):
		return false

	ranks[track_id] = next_rk
	SoundManager.play_ui_success()
	EventBus.knowledge_upgraded.emit(track_id, next_rk)
	EventBus.notification_posted.emit(
		"Ricerca R&D Completata!",
		"%s salita a Livello %d/%d! Nuovi contratti specialistici disponibili." % [title, next_rk, MAX_RANK],
		"success"
	)
	SaveManager.request_auto_save()
	return true

func get_all_tracks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in TRACK_ORDER:
		var def: Dictionary = TRACKS[k].duplicate(true)
		var rk := get_rank(k)
		var chk := can_study(k)
		def["rank"] = rk
		def["max_rank"] = MAX_RANK
		def["next_cost"] = get_next_cost(k)
		def["next_rep_req"] = get_next_rep_req(k)
		def["can_study"] = bool(chk.get("allowed", false))
		def["block_reason"] = str(chk.get("reason", ""))
		out.append(def)
	return out

# --- Moltiplicatori rigorosamente neutri a Rank 0 ---
func get_webforge_speed_bonus() -> float:
	var tech_b := TechOpsManager.get_webforge_tech_speed_bonus() if is_instance_valid(TechOpsManager) else 0.0
	return 0.30 * float(get_rank("web_architecture")) + tech_b


func get_rack_hosting_mult() -> float:
	return 1.0 + 0.10 * float(get_rank("cloud_devops"))

func get_contract_matching_track(contract: Dictionary) -> String:
	var explicit_track := str(contract.get("knowledge_track", ""))
	if explicit_track != "" and TRACKS.has(explicit_track):
		return explicit_track
	var etype := str(contract.get("execution_type", "")).to_lower()
	var cat := str(contract.get("category", "")).to_lower()
	if etype == "netshield" or "cyber" in cat or "fintech" in cat or "security" in cat:
		return "cyber_governance"
	if "automazione" in cat or "bot" in cat or "aerospace" in cat or "ai" in cat:
		return "ai_automation"
	if etype == "hardware" or "cloud" in cat or "database" in cat or "infrastruttura" in cat:
		return "cloud_devops"
	if etype == "webforge" or "web" in cat:
		return "web_architecture"
	return ""

func get_contract_payout_mult(contract: Dictionary) -> float:
	var track := get_contract_matching_track(contract)
	if track == "":
		return 1.0
	var rk := get_rank(track)
	if rk <= 0:
		return 1.0
	return 1.0 + 0.12 * float(rk)

func reset() -> void:
	ranks.clear()
	_ensure_all_ranks()

func serialize() -> Dictionary:
	_ensure_all_ranks()
	return {
		"ranks": ranks.duplicate()
	}

func deserialize(data: Dictionary) -> void:
	ranks.clear()
	var raw_ranks = data.get("ranks", {})
	if raw_ranks is Dictionary:
		for k in TRACK_ORDER:
			ranks[k] = clampi(int(raw_ranks.get(k, 0)), 0, MAX_RANK)
	_ensure_all_ranks()
