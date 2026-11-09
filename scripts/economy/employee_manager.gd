extends Node
## EmployeeManager - Milestone 6: 3D Employees & Talent Recruitment
## Manages recruitment, staff payroll, passive task productivity, and studio employee avatars.

var candidates: Array[Dictionary] = [
	{
		"id": "emp_luca",
		"name": "Luca Vianello",
		"role": "Junior Frontend Developer",
		"avatar_desc": "Laureato ITS ICT Torino, esperto Vue.js, Tailwind & Responsive Design.",
		"daily_salary": 45.00,
		"daily_revenue": 95.00,
		"reputation_req": 20,
		"hired": false,
		"status": "In cerca di lavoro",
		"perk": "+50% velocità contratti web & genera € 95/giorno passivi da micro-task"
	},
	{
		"id": "emp_sara",
		"name": "Sara Bellini",
		"role": "DevOps & Cloud SysAdmin",
		"avatar_desc": "Specialista Docker, Linux Server e cluster ad alta disponibilità.",
		"daily_salary": 65.00,
		"daily_revenue": 140.00,
		"reputation_req": 40,
		"hired": false,
		"status": "In cerca di lavoro",
		"perk": "+35% ricavi SLA server rack & azzera rischio surriscaldamento hardware"
	},
	{
		"id": "emp_marco",
		"name": "Marco Ferri",
		"role": "B2B Sales & Account Closer",
		"avatar_desc": "Esperienza commerciale pluriennale nel settore industriale torinese.",
		"daily_salary": 75.00,
		"daily_revenue": 175.00,
		"reputation_req": 60,
		"hired": false,
		"status": "In cerca di lavoro",
		"perk": "+15% valore su tutti i contratti marketplace & porta clienti enterprise"
	}
]

var hired_employee_ids: Array[String] = []

func _ready() -> void:
	pass

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

func hire_employee(emp_id: String) -> bool:
	var cand = get_candidate(emp_id)
	if cand.is_empty():
		return false
	if is_employee_hired(emp_id):
		EventBus.notification_posted.emit("Già Assunto", "%s fa già parte del tuo team!" % cand["name"], "warning")
		return false
		
	if GameManager.reputation_points < cand["reputation_req"]:
		EventBus.notification_posted.emit(
			"Reputazione Insufficiente",
			"%s richiede almeno %d punti Reputazione per unirsi alla tua startup!" % [cand["name"], cand["reputation_req"]],
			"error"
		)
		return false
		
	# First day salary deposit check
	if not EconomyManager.can_afford(cand["daily_salary"]):
		EventBus.notification_posted.emit(
			"Fondi Insufficienti",
			"Ti servono almeno € %0.2f per coprire la prima giornata di assunzione di %s." % [cand["daily_salary"], cand["name"]],
			"error"
		)
		return false
		
	# Deduct signing fee / initial day
	EconomyManager.spend(cand["daily_salary"], "Assunzione & Onboarding: " + cand["name"])
	hired_employee_ids.append(emp_id)
	cand["hired"] = true
	cand["status"] = "Attivo in Studio"
	
	EventBus.employee_hired.emit(emp_id, cand["name"])
	EventBus.notification_posted.emit(
		"Nuovo Dipendente Assunto!",
		"%s (%s) si è seduto alla seconda postazione nel tuo studio!" % [cand["name"], cand["role"]],
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
