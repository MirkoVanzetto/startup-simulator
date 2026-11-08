extends Node
## EconomyManager - Authoritative financial engine for Startup Simulator

var balance: float = 250.00
var ledger: Array[Dictionary] = []

func _ready() -> void:
	pass

func reset_economy(initial_funds: float = 250.00) -> void:
	balance = initial_funds
	ledger.clear()
	_record_entry(initial_funds, "Capitale Iniziale")
	EventBus.funds_changed.emit(balance, initial_funds, "Inizializzazione")

func can_afford(amount: float) -> bool:
	return balance >= amount

func spend(amount: float, reason: String) -> bool:
	if not can_afford(amount):
		EventBus.notification_posted.emit("Fondi Insufficienti", "Non hai abbastanza denaro sul conto aziendale.", "warning")
		return false
	
	balance -= amount
	_record_entry(-amount, reason)
	EventBus.funds_changed.emit(balance, -amount, reason)
	SoundManager.play_ui_click()
	return true

func earn(amount: float, reason: String) -> void:
	balance += amount
	_record_entry(amount, reason)
	EventBus.funds_changed.emit(balance, amount, reason)
	SoundManager.play_cash_register()

func _record_entry(delta: float, reason: String) -> void:
	ledger.append({
		"delta": delta,
		"balance_after": balance,
		"reason": reason,
		"timestamp": Time.get_datetime_string_from_system()
	})

func get_formatted_balance() -> String:
	return "€ %0.2f" % balance
