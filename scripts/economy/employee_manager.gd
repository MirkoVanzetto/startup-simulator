extends Node
## EmployeeManager - Milestone 6: 3D Employees & Talent Recruitment
## Manages recruitment, staff payroll, passive task productivity, and studio employee avatars.

var candidates: Array[Dictionary] = [
	{
		"id": "emp_luca",
		"name": "Luca Vianello",
		"role": "Client Scout & Business Dev",
		"avatar_desc": "Esperto B2B outreach nel Torinese, trova clienti reali e negozia budget più alti.",
		"daily_salary": 55.00,
		"daily_revenue": 70.00,
		"reputation_req": 50,
		"hired": false,
		"status": "In cerca di lavoro",
		"perk": "Genera nuovi incarichi Freelance ogni 2h (+2 subito), +15% budget offerte & € 70/giorno passivi"
	},
	{
		"id": "emp_sara",
		"name": "Sara Bellini",
		"role": "Full-Stack & Build Engineer",
		"avatar_desc": "Ingegnere Full-Stack & DevOps, accelera il build WebForge e protegge i cluster server.",
		"daily_salary": 85.00,
		"daily_revenue": 110.00,
		"reputation_req": 100,
		"hired": false,
		"status": "In cerca di lavoro",
		"perk": "-2.5s compilazione WebForge, hint debug codice, +35% ricavi Rack & zero surriscaldamento"
	},
	{
		"id": "emp_marco",
		"name": "Marco Ferri",
		"role": "B2B Sales & Account Closer",
		"avatar_desc": "Esperienza commerciale pluriennale nel settore industriale torinese.",
		"daily_salary": 100.00,
		"daily_revenue": 130.00,
		"reputation_req": 140,
		"hired": false,
		"status": "In cerca di lavoro",
		"perk": "+20% compenso alla consegna contratti & bonus clienti enterprise"
	}
]

var hired_employee_ids: Array[String] = []

func _ready() -> void:
	pass

func reset() -> void:
	hired_employee_ids.clear()
	for c in candidates:
		c["hired"] = false
		c["status"] = "In cerca di lavoro"

func serialize() -> Dictionary:
	return {
		"hired_employee_ids": hired_employee_ids.duplicate()
	}

func deserialize(data: Dictionary) -> void:
	reset()
	var ids = data.get("hired_employee_ids", [])
	if ids is Array:
		for raw_id in ids:
			var eid := str(raw_id)
			var cand := get_candidate(eid)
			if not cand.is_empty() and not (eid in hired_employee_ids):
				hired_employee_ids.append(eid)
				cand["hired"] = true
				cand["status"] = "Attivo in Studio"

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
	
	EventBus.employee_hired.emit(emp_id, cand["name"])
	EventBus.notification_posted.emit(
		"Nuovo Dipendente Assunto!",
		"%s (%s) si è seduto alla postazione nel tuo studio!" % [cand["name"], cand["role"]],
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
			total += float(c["daily_revenue"])
	return total

func get_active_employee_display_info() -> String:
	var hired = get_hired_employees()
	if hired.is_empty():
		return "Nessun dipendente assunto. Postazione libera."
	var primary = hired[0]
	return "%s\n(%s)" % [primary["name"], primary["role"]]
