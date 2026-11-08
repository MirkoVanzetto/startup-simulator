extends Node
## CalendarSystem - Simulates time progression, day-night cycles, and daily business expenses

@export var time_scale: float = 1.0 # 1 sec real = 1 min game time
@export var current_hour: int = 9
@export var current_minute: int = 0
@export var current_day: int = 1

# Daily operating expenses
const DAILY_RENT: float = 25.00
const DAILY_UTILITIES: float = 8.00
const DAILY_INTERNET: float = 5.00

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
	var total_overhead = DAILY_RENT + DAILY_UTILITIES + DAILY_INTERNET
	var breakdown = {
		"rent": DAILY_RENT,
		"utilities": DAILY_UTILITIES,
		"internet": DAILY_INTERNET,
		"total": total_overhead
	}
	
	EconomyManager.spend(total_overhead, "Spese Fisse Giornaliere (Affitto, Luce, Fibra)")
	EventBus.daily_expenses_billed.emit(total_overhead, breakdown)
	EventBus.notification_posted.emit(
		"Rendiconto Spese Giornaliere",
		"Addebitati € %0.2f (Affitto €25, Utenze €8, Fibra €5) per il Giorno %d." % [total_overhead, current_day],
		"warning"
	)

func get_formatted_time() -> String:
	return "%02d:%02d" % [current_hour, current_minute]

func get_day_name() -> String:
	var days = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]
	return days[(current_day - 1) % 7]
