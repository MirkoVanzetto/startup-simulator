extends Node
## EventSystem - Manages emergent random events, business choices, and reputation impact

var pending_event: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func evaluate_daily_events(day: int) -> void:
	# Avoid events on Day 1 tutorial
	if day <= 1:
		return
		
	# 40% probability of event per day
	if randf() > 0.40:
		return
		
	var event_pool = [
		{
			"id": "event_tech_article",
			"title": "Articolo su 'Torino Digitale'",
			"description": "Una rivista tecnologica locale ha pubblicato un trafiletto sulla tua nuova software house a Torino!",
			"choices": [
				{"text": "Condividi l'articolo sui social (+15 Reputazione)", "effect": "rep_15"},
				{"text": "Ignora e continua a lavorare testa bassa", "effect": "none"}
			]
		},
		{
			"id": "event_networking_ogr",
			"title": "Invito Networking alle OGR Torino",
			"description": "C'è un incontro tra startup e investitori stasera alle Officine Grandi Riparazioni.",
			"choices": [
				{"text": "Partecipa all'aperitivo business (-€ 35,00, +25 Reputazione)", "effect": "ogr_attend"},
				{"text": "Rinuncia per risparmiare budget", "effect": "none"}
			]
		},
		{
			"id": "event_hardware_discount",
			"title": "Voucher Fedeltà TorinoHardware",
			"description": "Il negozio di elettronica vicino allo studio ti invia un rimborso promozionale per la tua fedeltà!",
			"choices": [
				{"text": "Incassa il buono (€ +75,00 sul conto)", "effect": "cash_75"}
			]
		}
	]
	
	var chosen = event_pool[randi_range(0, event_pool.size() - 1)]
	trigger_event(chosen)

func trigger_event(event_dict: Dictionary) -> void:
	pending_event = event_dict
	EventBus.random_event_triggered.emit(event_dict)
	EventBus.notification_posted.emit("Nuovo Evento!", event_dict["title"], "event")

func resolve_event(choice_index: int) -> void:
	if pending_event.is_empty():
		return
		
	var choices = pending_event.get("choices", [])
	if choice_index >= 0 and choice_index < choices.size():
		var choice = choices[choice_index]
		var effect = choice.get("effect", "none")
		
		match effect:
			"rep_15":
				GameManager.reputation_points += 15
				EventBus.notification_posted.emit("Reputazione Aumentata", "Hai guadagnato +15 Reputazione aziendale!", "success")
			"ogr_attend":
				if EconomyManager.spend(35.0, "Partecipazione Evento OGR Torino"):
					GameManager.reputation_points += 25
					EventBus.notification_posted.emit("Networking di Successo", "Contatti preziosi acquisiti alle OGR (+25 Reputazione)!", "success")
			"cash_75":
				EconomyManager.earn(75.0, "Voucher TorinoHardware")
				EventBus.notification_posted.emit("Fondi Accreditati", "+€ 75,00 accreditati sul conto aziendale!", "success")
			"none", _:
				pass
				
	pending_event.clear()
	EventBus.random_event_resolved.emit(choice_index)
