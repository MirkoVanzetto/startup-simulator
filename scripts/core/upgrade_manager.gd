extends Node
## UpgradeManager - Sistema Potenziamenti a Stelle (★) e Tier Enterprise per Startup Simulator v1.4.
## Tutti i moltiplicatori a Rank 0 restituiscono il valore neutro (1.0 / 0.0 / tier 1).

const MAX_RANK: int = 3

const UPGRADE_ORDER: Array[String] = [
	"agility",
	"optics",
	"pipeline",
	"hosting",
	"efficiency",
	"enterprise"
]

const UPGRADES: Dictionary = {
	"agility": {
		"id": "agility",
		"title": "Agilità Urbana & Stamina",
		"icon": "⚡",
		"summary": "+8% / +16% / +24% velocità camminata & scatto; consuma meno energia in giro per Torino.",
		"costs": [1, 2, 3],
		"effect_labels": ["Base (0%)", "+8% passo", "+16% passo", "+24% passo & Sprint Pro"]
	},
	"optics": {
		"id": "optics",
		"title": "Optics & Lavoretti Rapidi",
		"icon": "🔭",
		"summary": "+0.4m / +0.8m / +1.2m raggio interazione 3D e +15% / +30% / +45% compensi Lavoretti.",
		"costs": [1, 2, 3],
		"effect_labels": ["Base (+0.0m)", "+0.4m · +15% paga", "+0.8m · +30% paga", "+1.2m · +45% paga"]
	},
	"pipeline": {
		"id": "pipeline",
		"title": "Pipeline CI/CD & WebForge",
		"icon": "🚀",
		"summary": "-0.7s / -1.4s / -2.1s durata build WebForge IDE e +12% / +24% / +36% bonus contratti Web/B2B.",
		"costs": [2, 3, 4],
		"effect_labels": ["Base (+0%)", "-0.7s · +12% B2B", "-1.4s · +24% B2B", "-2.1s · +36% B2B"]
	},
	"hosting": {
		"id": "hosting",
		"title": "Cluster Hosting Cloud 19\"",
		"icon": "🖥",
		"summary": "+20% / +40% / +60% rendita giornaliera dei domini ospitati sul tuo Server Rack.",
		"costs": [2, 3, 4],
		"effect_labels": ["Base (+0%)", "+20% rendita Rack", "+40% rendita Rack", "+60% rendita Rack"]
	},
	"efficiency": {
		"id": "efficiency",
		"title": "Ottimizzazione Studio & Utenze",
		"icon": "🏛",
		"summary": "-12% / -22% / -32% sulle spese fisse giornaliere di affitto, luce e fibra studio.",
		"costs": [1, 2, 3],
		"effect_labels": ["Base (-0%)", "-12% spese fisse", "-22% spese fisse", "-32% spese fisse"]
	},
	"enterprise": {
		"id": "enterprise",
		"title": "Appalti OGR Enterprise",
		"icon": "🏢",
		"summary": "Sblocca Tier I / II / III nei grandi bandi OGR Tech Hub e +15% / +30% / +45% premio finale.",
		"costs": [2, 3, 4],
		"effect_labels": ["Tier I (Base)", "Tier II · +15%", "Tier III · +30%", "Tier IV · +45% Elite"]
	}
}

var stars: int = 0
var ranks: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_all_ranks()

func _ensure_all_ranks() -> void:
	for k in UPGRADE_ORDER:
		if not ranks.has(k):
			ranks[k] = 0

func get_stars() -> int:
	return stars

func add_stars(amount: int, reason: String = "") -> void:
	if amount <= 0:
		return
	stars += amount
	EventBus.stars_changed.emit(stars, amount, reason)
	if reason != "":
		EventBus.notification_posted.emit(
			"★ +%d Stella Potenziamenti!" % amount,
			"%s (Totale: %d ★) — Spendi le stelle in Potenziamenti ★ su TO-OS." % [reason, stars],
			"success"
		)

func get_rank(upgrade_id: String) -> int:
	return clampi(int(ranks.get(upgrade_id, 0)), 0, MAX_RANK)

func get_next_cost(upgrade_id: String) -> int:
	var def: Dictionary = UPGRADES.get(upgrade_id, {})
	if def.is_empty():
		return -1
	var cur := get_rank(upgrade_id)
	if cur >= MAX_RANK:
		return -1
	var costs: Array = def.get("costs", [1, 2, 3])
	if cur >= costs.size():
		return -1
	return int(costs[cur])

func can_purchase(upgrade_id: String) -> bool:
	var cost := get_next_cost(upgrade_id)
	return cost > 0 and stars >= cost

func purchase(upgrade_id: String) -> bool:
	var cost := get_next_cost(upgrade_id)
	if cost <= 0:
		SoundManager.play_ui_error()
		return false
	if stars < cost:
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit(
			"Stelle Insufficienti",
			"Servono %d ★ (hai %d ★). Completa contratti, lavoretti (ogni 2 = +1★) o sali di Notorietà!",
			"warning"
		)
		return false

	stars -= cost
	var new_rank := get_rank(upgrade_id) + 1
	ranks[upgrade_id] = new_rank
	var title := str(UPGRADES[upgrade_id].get("title", upgrade_id))
	SoundManager.play_ui_success()
	EventBus.stars_changed.emit(stars, -cost, "Potenziamento: %s Lv.%d" % [title, new_rank])
	EventBus.upgrade_purchased.emit(upgrade_id, new_rank)
	EventBus.notification_posted.emit(
		"Potenziamento Sbloccato!",
		"%s salito a Livello %d/%d (-%d ★)." % [title, new_rank, MAX_RANK, cost],
		"success"
	)
	SaveManager.request_auto_save()
	return true

func get_all_upgrades() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in UPGRADE_ORDER:
		var def: Dictionary = UPGRADES[k].duplicate(true)
		var r := get_rank(k)
		def["rank"] = r
		def["max_rank"] = MAX_RANK
		def["next_cost"] = get_next_cost(k)
		def["can_afford"] = can_purchase(k)
		out.append(def)
	return out

# --- Moltiplicatori neutrali a Rank 0 ---
func get_speed_mult() -> float:
	return 1.0 + 0.08 * float(get_rank("agility"))

func get_sprint_drain_mult() -> float:
	return maxf(0.55, 1.0 - 0.12 * float(get_rank("agility")))

func get_interaction_reach_bonus() -> float:
	return 0.40 * float(get_rank("optics"))

func get_side_job_pay_mult() -> float:
	return 1.0 + 0.15 * float(get_rank("optics"))

func get_webforge_speed_bonus() -> float:
	return 0.70 * float(get_rank("pipeline"))

func get_contract_payout_mult() -> float:
	return 1.0 + 0.12 * float(get_rank("pipeline"))

func get_hosting_bonus_mult() -> float:
	return 1.0 + 0.20 * float(get_rank("hosting"))

func get_overhead_discount_mult() -> float:
	var table: Array[float] = [1.0, 0.88, 0.78, 0.68]
	return table[get_rank("efficiency")]

func get_enterprise_tier() -> int:
	return 1 + get_rank("enterprise")

func get_enterprise_payout_mult() -> float:
	return 1.0 + 0.15 * float(get_rank("enterprise"))

func reset() -> void:
	stars = 0
	ranks.clear()
	_ensure_all_ranks()
	EventBus.stars_changed.emit(stars, 0, "Reset")

func serialize() -> Dictionary:
	_ensure_all_ranks()
	return {
		"stars": stars,
		"ranks": ranks.duplicate()
	}

func deserialize(data: Dictionary) -> void:
	stars = maxi(0, int(data.get("stars", 0)))
	ranks.clear()
	var raw_ranks = data.get("ranks", {})
	if raw_ranks is Dictionary:
		for k in UPGRADE_ORDER:
			ranks[k] = clampi(int(raw_ranks.get(k, 0)), 0, MAX_RANK)
	_ensure_all_ranks()
	EventBus.stars_changed.emit(stars, 0, "Caricamento")
