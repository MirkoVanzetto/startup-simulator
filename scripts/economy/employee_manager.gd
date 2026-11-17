extends Node
## EmployeeManager - Milestone 6 & v1.5 Autonomous Freelance Hub Workers + Skill Training
## Manages recruitment, staff payroll, autonomous Freelance Hub contract execution, skill upgrades, and studio avatars.

const ContractGenerator = preload("res://scripts/contracts/contract_generator.gd")

const MAX_SKILL_RANK: int = 3

const SKILL_TRACKS: Dictionary = {
	"speed": {
		"id": "speed",
		"icon": "⚡",
		"title": "Velocità Sviluppo",
		"costs_eur": [220.0, 420.0, 680.0],
		"bonuses": [0.0, 0.12, 0.25, 0.40],
		"desc": "+12% / +25% / +40% velocità completamento autonomo incarichi Freelance Hub"
	},
	"value": {
		"id": "value",
		"icon": "💶",
		"title": "Selezione & Valore Commesse",
		"costs_eur": [260.0, 480.0, 750.0],
		"bonuses": [0.0, 0.15, 0.30, 0.45],
		"desc": "+15% / +30% / +45% compenso sugli incarichi B2B selezionati e consegnati"
	},
	"quality": {
		"id": "quality",
		"icon": "⭐",
		"title": "Qualità & Ricerca AI",
		"costs_eur": [280.0, 520.0, 820.0],
		"bonuses": [0.0, 1.0, 2.0, 3.0],
		"desc": "+1/+2/+3 Reputazione e +🔬 Crediti di Ricerca extra ad ogni consegna autonoma"
	}
}

var candidates: Array[Dictionary] = [
	{
		"id": "emp_luca",
		"name": "Luca Vianello",
		"role": "Client Scout & Business Dev",
		"avatar_desc": "Esperto B2B outreach nel Torinese, trova clienti reali, negozia budget e svolge commesse su Freelance Hub.",
		"daily_salary": 55.00,
		"daily_revenue": 70.00,
		"reputation_req": 50,
		"hired": false,
		"status": "In cerca di lavoro",
		"perk": "Svolge incarichi autonomi da Freelance Hub, genera nuovi lead ogni 2h (+15% budget) & € 70/g base"
	},
	{
		"id": "emp_sara",
		"name": "Sara Bellini",
		"role": "Full-Stack & Build Engineer",
		"avatar_desc": "Ingegnere Full-Stack & DevOps, sviluppa commesse autonome, accelera WebForge e protegge il Server Rack.",
		"daily_salary": 85.00,
		"daily_revenue": 110.00,
		"reputation_req": 100,
		"hired": false,
		"status": "In cerca di lavoro",
		"perk": "Sviluppa contratti Freelance Hub autonomamente, -2.5s WebForge, +35% Rack & zero surriscaldamento"
	},
	{
		"id": "emp_marco",
		"name": "Marco Ferri",
		"role": "B2B Sales & Account Closer",
		"avatar_desc": "Esperienza commerciale pluriennale nel settore industriale torinese: chiude commesse ad alto budget.",
		"daily_salary": 100.00,
		"daily_revenue": 130.00,
		"reputation_req": 140,
		"hired": false,
		"status": "In cerca di lavoro",
		"perk": "Chiude commesse B2B autonome ad alto margine, +20% compenso contratti & bonus clienti enterprise"
	}
]

var hired_employee_ids: Array[String] = []
## Incarichi autonomi in corso per dipendente: emp_id -> Dictionary
var employee_tasks: Dictionary = {}
## Statistiche e livelli skill per dipendente: emp_id -> Dictionary
var employee_stats: Dictionary = {}
## Cronologia ultimi incarichi completati dal team
var completed_tasks_log: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_all_stats()
	if is_instance_valid(EventBus):
		EventBus.time_tick.connect(_on_time_tick)

func _default_emp_stats() -> Dictionary:
	return {
		"completed_count": 0,
		"total_revenue": 0.0,
		"skills": {
			"speed": 0,
			"value": 0,
			"quality": 0
		}
	}

func _ensure_all_stats() -> void:
	for c in candidates:
		var eid := str(c["id"])
		if not employee_stats.has(eid):
			employee_stats[eid] = _default_emp_stats()
		else:
			var sk = employee_stats[eid].get("skills", {})
			if not (sk is Dictionary):
				sk = {}
			for k in ["speed", "value", "quality"]:
				if not sk.has(k):
					sk[k] = 0
			employee_stats[eid]["skills"] = sk

func reset() -> void:
	hired_employee_ids.clear()
	employee_tasks.clear()
	employee_stats.clear()
	completed_tasks_log.clear()
	for c in candidates:
		c["hired"] = false
		c["status"] = "In cerca di lavoro"
	_ensure_all_stats()

func serialize() -> Dictionary:
	_ensure_all_stats()
	return {
		"hired_employee_ids": hired_employee_ids.duplicate(),
		"employee_tasks": employee_tasks.duplicate(true),
		"employee_stats": employee_stats.duplicate(true),
		"completed_tasks_log": completed_tasks_log.duplicate(true)
	}

func deserialize(data: Dictionary) -> void:
	reset()
	var raw_stats = data.get("employee_stats", {})
	if raw_stats is Dictionary:
		for k in raw_stats:
			if raw_stats[k] is Dictionary:
				employee_stats[str(k)] = raw_stats[k].duplicate(true)
	_ensure_all_stats()

	var raw_tasks = data.get("employee_tasks", {})
	if raw_tasks is Dictionary:
		for k in raw_tasks:
			if raw_tasks[k] is Dictionary:
				employee_tasks[str(k)] = raw_tasks[k].duplicate(true)

	var raw_log = data.get("completed_tasks_log", [])
	if raw_log is Array:
		for item in raw_log:
			if item is Dictionary:
				completed_tasks_log.append(item.duplicate(true))

	var ids = data.get("hired_employee_ids", [])
	if ids is Array:
		for raw_id in ids:
			var eid := str(raw_id)
			var cand := get_candidate(eid)
			if not cand.is_empty() and not (eid in hired_employee_ids):
				hired_employee_ids.append(eid)
				cand["hired"] = true
				cand["status"] = "Attivo in Studio"
				if not employee_tasks.has(eid) or employee_tasks[eid].is_empty():
					assign_next_autonomous_task(eid, false)

func get_all_candidates() -> Array[Dictionary]:
	return candidates

func get_candidate(emp_id: String) -> Dictionary:
	for c in candidates:
		if c["id"] == emp_id:
			return c
	return {}

func is_employee_hired(emp_id: String) -> bool:
	return emp_id in hired_employee_ids

func get_hired_employees() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c in candidates:
		if c["id"] in hired_employee_ids:
			result.append(c)
	return result

func can_hire_employee(emp_id: String) -> Dictionary:
	var cand = get_candidate(emp_id)
	if cand.is_empty():
		return {"allowed": false, "reason": "Candidato non trovato nel database."}
		
	if is_employee_hired(emp_id):
		return {"allowed": false, "reason": "%s fa già parte del tuo team attivo!" % cand["name"]}
		
	var comp_tier = GameManager.company_tier if ("company_tier" in GameManager) else 1
	if comp_tier < 2:
		return {
			"allowed": false,
			"reason": "La tua azienda è ancora al Livello Garage (Solo Freelance). Espandi lo studio a Startup Emergente per assumere dipendenti!"
		}
		
	var hired = get_hired_employees()
	var max_slots = GameManager.get_max_employee_slots() if GameManager.has_method("get_max_employee_slots") else 1
	if hired.size() >= max_slots:
		return {
			"allowed": false,
			"reason": "Postazioni di lavoro esaurite (%d/%d). Potenzia l'ufficio per creare nuove scrivanie!" % [hired.size(), max_slots]
		}
		
	var rep = GameManager.reputation_points if ("reputation_points" in GameManager) else 0
	if rep < cand["reputation_req"]:
		return {
			"allowed": false,
			"reason": "Reputazione insufficiente (%d / %d richiesta per %s)." % [rep, cand["reputation_req"], cand["name"]]
		}
		
	if not EconomyManager.can_afford(cand["daily_salary"]):
		return {
			"allowed": false,
			"reason": "Fondi insufficienti sul conto aziendale: servono almeno € %0.2f per coprire la prima giornata di assunzione di %s." % [cand["daily_salary"], cand["name"]]
		}
		
	return {"allowed": true, "reason": ""}

func hire_employee(emp_id: String) -> bool:
	var check = can_hire_employee(emp_id)
	if not check.get("allowed", false):
		var reason = check.get("reason", "Assunzione non consentita.")
		EventBus.notification_posted.emit("Assunzione Non Riuscita", reason, "error")
		return false
		
	var cand = get_candidate(emp_id)
	# Deduct signing fee / initial day
	if not EconomyManager.spend(cand["daily_salary"], "Assunzione & Onboarding: " + cand["name"]):
		return false
		
	hired_employee_ids.append(emp_id)
	cand["hired"] = true
	cand["status"] = "Attivo in Studio"
	assign_next_autonomous_task(emp_id, false)
	
	EventBus.employee_hired.emit(emp_id, cand["name"])
	EventBus.notification_posted.emit(
		"Nuovo Dipendente Assunto!",
		"%s (%s) è ora al lavoro in studio e ha già preso in carico un incarico da Freelance Hub!" % [cand["name"], cand["role"]],
		"success"
	)
	SoundManager.play_ui_success()
	SaveManager.request_auto_save()
	return true

func fire_employee(emp_id: String) -> bool:
	if not is_employee_hired(emp_id):
		return false
		
	var cand = get_candidate(emp_id)
	hired_employee_ids.erase(emp_id)
	employee_tasks.erase(emp_id)
	if not cand.is_empty():
		cand["hired"] = false
		cand["status"] = "In cerca di lavoro"
		
	EventBus.employee_fired.emit(emp_id)
	EventBus.notification_posted.emit(
		"Contratto Terminato",
		"Hai interrotto la collaborazione con %s." % (cand.get("name", "Dipendente")),
		"info"
	)
	SoundManager.play_ui_click()
	SaveManager.request_auto_save()
	return true

# ==============================================================================
# LAVORO AUTONOMO SU FREELANCE HUB & FORMAZIONE DIPENDENTI (SEZIONE 6)
# ==============================================================================

func get_employee_stats(emp_id: String) -> Dictionary:
	_ensure_all_stats()
	return employee_stats.get(emp_id, _default_emp_stats())

func get_employee_skill_level(emp_id: String, skill_id: String) -> int:
	var st := get_employee_stats(emp_id)
	var sk: Dictionary = st.get("skills", {})
	return clampi(int(sk.get(skill_id, 0)), 0, MAX_SKILL_RANK)

func get_employee_skill(emp_id: String, skill_id: String) -> int:
	return get_employee_skill_level(emp_id, skill_id)

func get_employee_completed_count(emp_id: String) -> int:
	var st := get_employee_stats(emp_id)
	return int(st.get("completed_count", 0))

func get_next_skill_cost(emp_id: String, skill_id: String) -> float:
	if not SKILL_TRACKS.has(skill_id):
		return -1.0
	var lvl := get_employee_skill_level(emp_id, skill_id)
	if lvl >= MAX_SKILL_RANK:
		return -1.0
	var costs: Array = SKILL_TRACKS[skill_id].get("costs_eur", [250.0, 480.0, 750.0])
	return float(costs[lvl])

func can_upgrade_employee_skill(emp_id: String, skill_id: String) -> Dictionary:
	if not is_employee_hired(emp_id) or not SKILL_TRACKS.has(skill_id):
		return {"allowed": false, "reason": "Dipendente o competenza non valida.", "cost": 0.0}
	var lvl := get_employee_skill_level(emp_id, skill_id)
	if lvl >= MAX_SKILL_RANK:
		return {"allowed": false, "reason": "Livello massimo raggiunto (3/3).", "cost": 0.0}
	var cost := get_next_skill_cost(emp_id, skill_id)
	if not EconomyManager.can_afford(cost):
		return {"allowed": false, "reason": "Fondi insufficienti (€ %0.2f)." % cost, "cost": cost}
	return {"allowed": true, "reason": "", "cost": cost}

func get_employee_task_status_text(emp_id: String) -> String:
	var t := get_employee_task(emp_id)
	var st := get_employee_stats(emp_id)
	var done_cnt := int(st.get("completed_count", 0))
	var tot_rev := float(st.get("total_revenue", 0.0))
	if t.is_empty():
		return "🤖 Freelance Hub: in attesa · Completati: %d (€ %0.0f)" % [done_cnt, tot_rev]
	var prog := int(t.get("progress_mins", 0))
	var dur := maxi(1, int(t.get("duration_mins", 150)))
	var pct := clampi(int(roundf(100.0 * float(prog) / float(dur))), 0, 100)
	return "🤖 Freelance Hub: «%s» (%d%% · +€ %0.0f) · Chiusi: %d (€ %0.0f)" % [
		str(t.get("title", "Incarico B2B")),
		pct,
		float(t.get("reward", 0.0)),
		done_cnt,
		tot_rev
	]

func upgrade_employee_skill(emp_id: String, skill_id: String) -> bool:
	if not is_employee_hired(emp_id) or not SKILL_TRACKS.has(skill_id):
		return false
	var lvl := get_employee_skill_level(emp_id, skill_id)
	if lvl >= 3:
		EventBus.notification_posted.emit("Competenza al Massimo", "Questa competenza è già al Livello 3/3!", "info")
		return false
	var cost := get_next_skill_cost(emp_id, skill_id)
	if not EconomyManager.can_afford(cost):
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Fondi Insufficienti", "Servono € %0.2f per il corso di formazione." % cost, "warning")
		return false

	var cand := get_candidate(emp_id)
	var track_title := str(SKILL_TRACKS[skill_id].get("title", skill_id))
	EconomyManager.spend(cost, "Formazione %s: %s Lv.%d" % [str(cand.get("name", emp_id)), track_title, lvl + 1])

	_ensure_all_stats()
	employee_stats[emp_id]["skills"][skill_id] = lvl + 1

	# Ricalcola durata eventuale task in corso se migliorata la velocità
	if skill_id == "speed" and employee_tasks.has(emp_id) and not employee_tasks[emp_id].is_empty():
		var cur_dur := int(employee_tasks[emp_id].get("duration_mins", 160))
		employee_tasks[emp_id]["duration_mins"] = maxi(45, int(roundf(float(cur_dur) * 0.88)))

	SoundManager.play_ui_success()
	EventBus.notification_posted.emit(
		"Dipendente Potenziato!",
		"%s ha raggiunto Lv.%d/3 in %s!" % [str(cand.get("name", emp_id)), lvl + 1, track_title],
		"success"
	)
	EventBus.employee_task_updated.emit()
	SaveManager.request_auto_save()
	return true

func get_employee_speed_mult(emp_id: String) -> float:
	var lvl := get_employee_skill_level(emp_id, "speed")
	var bonuses: Array = SKILL_TRACKS["speed"]["bonuses"]
	var mult := 1.0 + float(bonuses[lvl])
	if is_instance_valid(TechOpsManager):
		mult *= TechOpsManager.get_employee_tech_speed_mult()
	return mult

func get_employee_value_mult(emp_id: String) -> float:
	var lvl := get_employee_skill_level(emp_id, "value")
	var bonuses: Array = SKILL_TRACKS["value"]["bonuses"]
	var mult := 1.0 + float(bonuses[lvl])
	if emp_id == "emp_marco":
		mult += 0.15
	elif emp_id == "emp_sara":
		mult += 0.08
	return mult

func get_employee_task(emp_id: String) -> Dictionary:
	if not is_employee_hired(emp_id):
		return {}
	if not employee_tasks.has(emp_id) or employee_tasks[emp_id].is_empty():
		assign_next_autonomous_task(emp_id, false)
	return employee_tasks.get(emp_id, {})

func assign_next_autonomous_task(emp_id: String, prefer_marketplace: bool = true) -> Dictionary:
	if not is_employee_hired(emp_id):
		return {}
	var cand := get_candidate(emp_id)
	var picked_gig: Dictionary = {}
	var from_hub := false

	# Se in bacheca Freelance Hub ci sono più di 1 offerta, il dipendente può prelevarne una reale
	# (lasciando sempre almeno 1 offerta disponibile per il giocatore, oppure prelevando la migliore se > 1)
	if prefer_marketplace and is_instance_valid(ContractManager) and ContractManager.marketplace_contracts.size() > 1:
		var best_idx := 0
		var best_budget := -1.0
		for i in range(ContractManager.marketplace_contracts.size()):
			var mc: Dictionary = ContractManager.marketplace_contracts[i]
			var b := float(mc.get("budget", 0.0))
			if b > best_budget:
				best_budget = b
				best_idx = i
		picked_gig = ContractManager.marketplace_contracts[best_idx].duplicate(true)
		ContractManager.marketplace_contracts.remove_at(best_idx)
		from_hub = true
		EventBus.contract_marketplace_refreshed.emit()
	else:
		var specialties: Array = KnowledgeManager.get_unlocked_specialties() if is_instance_valid(KnowledgeManager) else []
		picked_gig = ContractGenerator.generate_random_contract(0, 1.0, specialties)

	var base_budget := float(picked_gig.get("budget", 180.0))
	# Compenso commisurato al ruolo e alle skill del dipendente
	var val_mult := get_employee_value_mult(emp_id)
	var payout := snappedf(clampf(base_budget * 0.55 * val_mult, 85.0, 950.0), 0.01)

	var base_duration := 180 # 3 ore di gioco base
	if emp_id == "emp_sara":
		base_duration = 155
	elif emp_id == "emp_marco":
		base_duration = 165
	var spd_mult := get_employee_speed_mult(emp_id)
	var duration := maxi(45, int(roundf(float(base_duration) / spd_mult)))

	var qual_lvl := get_employee_skill_level(emp_id, "quality")
	var rep_rew := 3 + qual_lvl
	var rc_rew := qual_lvl * 2

	var task_dict := {
		"emp_id": emp_id,
		"title": str(picked_gig.get("title", "Sviluppo Modulo Web B2B")),
		"client": str(picked_gig.get("client", "Cliente PMI Torino")),
		"category": str(picked_gig.get("category", "Web & Cloud")),
		"from_hub": from_hub,
		"reward": payout,
		"rep_reward": rep_rew,
		"rc_reward": rc_rew,
		"progress_mins": 0,
		"duration_mins": duration
	}
	employee_tasks[emp_id] = task_dict
	cand["status"] = "Al lavoro su: %s" % str(task_dict["title"])
	if is_instance_valid(EventBus):
		EventBus.employee_task_updated.emit()
	return task_dict

func _on_time_tick(_h: int, _m: int, _d: int) -> void:
	if hired_employee_ids.is_empty():
		return
	_advance_employee_tasks(1, true)

func _advance_employee_tasks(minutes: int, notify_each: bool = true) -> Dictionary:
	var completed_now := 0
	var earned_now := 0.0
	var rc_now := 0

	for emp_id in hired_employee_ids:
		if not employee_tasks.has(emp_id) or employee_tasks[emp_id].is_empty():
			assign_next_autonomous_task(emp_id, true)
		var t: Dictionary = employee_tasks.get(emp_id, {})
		if t.is_empty():
			continue

		t["progress_mins"] = int(t.get("progress_mins", 0)) + minutes
		var safety := 0
		while int(t.get("progress_mins", 0)) >= int(t.get("duration_mins", 150)) and safety < 6:
			safety += 1
			var leftover := int(t["progress_mins"]) - int(t["duration_mins"])
			var pay := float(t.get("reward", 110.0))
			var rep := int(t.get("rep_reward", 3))
			var rc := int(t.get("rc_reward", 0))
			var title := str(t.get("title", "Incarico Freelance Hub"))
			var cand := get_candidate(emp_id)
			var emp_name := str(cand.get("name", emp_id))

			EconomyManager.earn(pay, "Incarico Autonomo Freelance Hub (%s): %s" % [emp_name, title])
			GameManager.reputation_points += rep
			if rc > 0 and is_instance_valid(TechOpsManager):
				TechOpsManager.add_research_credits(rc, "R&D Team (%s): %s" % [emp_name, title])

			_ensure_all_stats()
			employee_stats[emp_id]["completed_count"] = int(employee_stats[emp_id].get("completed_count", 0)) + 1
			employee_stats[emp_id]["total_revenue"] = snappedf(float(employee_stats[emp_id].get("total_revenue", 0.0)) + pay, 0.01)

			completed_tasks_log.push_front({
				"emp_id": emp_id,
				"emp_name": emp_name,
				"title": title,
				"reward": pay,
				"rep": rep,
				"rc": rc,
				"day": CalendarSystem.current_day if is_instance_valid(CalendarSystem) else 1
			})
			if completed_tasks_log.size() > 8:
				completed_tasks_log.resize(8)

			completed_now += 1
			earned_now += pay
			rc_now += rc

			if notify_each:
				EventBus.notification_posted.emit(
					"Incarico Completato da %s!" % emp_name,
					"«%s» consegnato su Freelance Hub: +€ %0.2f · +%d Rep%s!" % [
						title,
						pay,
						rep,
						(" · +%d 🔬 RC" % rc) if rc > 0 else ""
					],
					"success"
				)

			t = assign_next_autonomous_task(emp_id, true)
			t["progress_mins"] = leftover

	if is_instance_valid(EventBus):
		EventBus.employee_task_updated.emit()
	return {"completed": completed_now, "earned": earned_now, "rc": rc_now}

## Avanza il lavoro autonomo dei dipendenti durante le ore di sonno!
func simulate_sleep_hours(hours: float) -> Dictionary:
	var mins := maxi(0, int(roundf(hours * 60.0)))
	if mins <= 0 or hired_employee_ids.is_empty():
		return {"completed": 0, "earned": 0.0, "rc": 0}
	return _advance_employee_tasks(mins, false)

func calculate_daily_payroll() -> float:
	var total = 0.0
	for c in candidates:
		if c["id"] in hired_employee_ids:
			total += float(c["daily_salary"])
	return total

func calculate_employee_revenue() -> float:
	var total = 0.0
	for c in candidates:
		if c["id"] in hired_employee_ids:
			var eid := str(c["id"])
			var mult := get_employee_value_mult(eid)
			total += snappedf(float(c["daily_revenue"]) * mult, 0.01)
	return total

func get_total_team_produced_revenue() -> float:
	_ensure_all_stats()
	var tot := 0.0
	for eid in employee_stats:
		tot += float(employee_stats[eid].get("total_revenue", 0.0))
	return snappedf(tot, 0.01)

func get_active_employee_display_info() -> String:
	var hired = get_hired_employees()
	if hired.is_empty():
		return "Nessun dipendente assunto. Postazione libera."
	var primary = hired[0]
	var t := get_employee_task(str(primary["id"]))
	if not t.is_empty():
		var pct := int(roundf(100.0 * float(t.get("progress_mins", 0)) / float(maxi(1, int(t.get("duration_mins", 150))))))
		return "%s (%s)\nTask: %s (%d%%)" % [primary["name"], primary["role"], str(t.get("title", "")), clampi(pct, 0, 100)]
	return "%s\n(%s)" % [primary["name"], primary["role"]]
