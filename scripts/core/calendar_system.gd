extends Node
## CalendarSystem - Simulates time progression, day-night cycles, and daily business expenses

@export var time_scale: float = 1.0 # 1 sec real = 1 min game time
@export var current_hour: int = 9
@export var current_minute: int = 0
@export var current_day: int = 1

# Daily operating expenses (48.00 EUR / day realistic simulator overhead)
const DAILY_RENT: float = 30.00
const DAILY_UTILITIES: float = 10.00
const DAILY_INTERNET: float = 8.00

var time_accumulator: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.MAIN_MENU or GameManager.current_state == GameManager.GameState.PAUSED:
		return
		
	time_accumulator += delta * time_scale
	if time_accumulator >= 1.0:
		time_accumulator -= 1.0
		_advance_minute()

func _advance_minute() -> void:
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		
		# Check day rollover at midnight (24:00 -> 00:00)
		if current_hour >= 24:
			current_hour = 0
			_advance_day()
			
	EventBus.time_tick.emit(current_hour, current_minute, current_day)

func _advance_day() -> void:
	current_day += 1
	GameManager.days_elapsed = current_day
	EventBus.day_passed.emit(current_day)
	
	# Process daily overhead expenses
	_bill_daily_expenses()
	
	# Check for potential random business event
	EventSystem.evaluate_daily_events(current_day)

func _bill_daily_expenses() -> void:
	var disc := UpgradeManager.get_overhead_discount_mult() if is_instance_valid(UpgradeManager) else 1.0
	var total_overhead = snappedf((DAILY_RENT + DAILY_UTILITIES + DAILY_INTERNET) * disc, 0.01)
	var breakdown = {
		"rent": snappedf(DAILY_RENT * disc, 0.01),
		"utilities": snappedf(DAILY_UTILITIES * disc, 0.01),
		"internet": snappedf(DAILY_INTERNET * disc, 0.01),
		"total": total_overhead
	}
	
	var billed_amount := 0.0
	if EconomyManager.can_afford(total_overhead):
		EconomyManager.spend(total_overhead, "Spese Fisse Giornaliere (Affitto, Luce, Fibra)")
		billed_amount = total_overhead
		EventBus.notification_posted.emit(
			"Rendiconto Spese Giornaliere",
			"Addebitati € %0.2f (Affitto €%.0f, Utenze €%.0f, Fibra €%.0f) per il Giorno %d." % [total_overhead, breakdown["rent"], breakdown["utilities"], breakdown["internet"], current_day],
			"warning"
		)
	elif EconomyManager.balance > 0.01:
		var partial := snappedf(EconomyManager.balance, 0.01)
		EconomyManager.spend(partial, "Acconto Spese Giornaliere (Cassa Parziale)")
		billed_amount = partial
		EventBus.notification_posted.emit(
			"Cassa in Rosso Scongiurato",
			"Pagati € %0.2f su € %0.2f di spese fisse. Fai lavoretti rapidi alla Bacheca per fare cassa!" % [partial, total_overhead],
			"warning"
		)
	else:
		EventBus.notification_posted.emit(
			"Avviso Affitto (€ 0 in Cassa)",
			"Conto a zero: proroga concessa per oggi. Vai alla Bacheca Lavori Rapidi in paese per guadagnare subito!",
			"warning"
		)
	EventBus.daily_expenses_billed.emit(billed_amount, breakdown)
	
	# Milestone 5 - Dynamic Hosting Revenue from ServerRackManager
	if ServerRackManager.is_rack_unlocked or ("server_rack_upgrade" in GameManager.studio_upgrades_installed):
		var hosting_income = ServerRackManager.calculate_daily_hosting_revenue()
		if hosting_income > 0.0:
			EconomyManager.earn(hosting_income, "Rendita Ricorrente Hosting Domini & Cloud (Giorno %d)" % current_day)
			EventBus.notification_posted.emit(
				"Incasso Hosting Server",
				"Accreditati € %0.2f per i domini attivi ospitati sul server rack!" % hosting_income,
				"success"
			)
			
	# Milestone 6 - Employee Payroll & Productivity
	var payroll = EmployeeManager.calculate_daily_payroll()
	if payroll > 0.0:
		if EconomyManager.can_afford(payroll):
			EconomyManager.spend(payroll, "Stipendi & Buste Paga Dipendenti (Giorno %d)" % current_day)
			EventBus.notification_posted.emit(
				"Buste Paga Pagate",
				"Liquidati € %0.2f per gli stipendi giornalieri del tuo team." % payroll,
				"warning"
			)
		elif EconomyManager.balance > 0.01:
			var p_part := snappedf(EconomyManager.balance, 0.01)
			EconomyManager.spend(p_part, "Acconto Buste Paga (Giorno %d)" % current_day)
		
	var emp_revenue = EmployeeManager.calculate_employee_revenue()
	if emp_revenue > 0.0:
		EconomyManager.earn(emp_revenue, "Produttività & Ticket Chiusi dal Team (Giorno %d)" % current_day)
		EventBus.notification_posted.emit(
			"Fatturato Dipendenti",
			"Il tuo team ha generato € %0.2f chiudendo task e contratti aziendali!" % emp_revenue,
			"success"
		)


## Avanza il tempo di gioco fino al mattino successivo (default 07:00).
## Se si attraversa la mezzanotte scatta il cambio giorno (spese giornaliere ecc.).
## Ritorna le ore di gioco trascorse (float).
func advance_to_next_morning(morning_hour: int = 7) -> float:
	var start_minutes = current_hour * 60 + current_minute
	var target_minutes = morning_hour * 60
	var crossed_midnight = start_minutes >= target_minutes
	var elapsed_minutes = (24 * 60 - start_minutes + target_minutes) if crossed_midnight else (target_minutes - start_minutes)
	if crossed_midnight:
		current_hour = 0
		current_minute = 0
		_advance_day()
	current_hour = morning_hour
	current_minute = 0
	time_accumulator = 0.0
	EventBus.time_tick.emit(current_hour, current_minute, current_day)
	return float(elapsed_minutes) / 60.0

func get_formatted_time() -> String:
	return "%02d:%02d" % [current_hour, current_minute]

func get_day_name() -> String:
	var days = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]
	return days[(current_day - 1) % 7]
