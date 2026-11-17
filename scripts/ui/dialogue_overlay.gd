extends Control
## DialogueOverlay - Interactive conversation interface with characters in Torino

@onready var speaker_label: Label = $Panel/Margin/VBox/SpeakerHeader/SpeakerName
@onready var dialogue_text: RichTextLabel = $Panel/Margin/VBox/DialogueText
@onready var choices_container: VBoxContainer = $Panel/Margin/VBox/ChoicesContainer
@onready var continue_button: Button = $Panel/Margin/VBox/ContinueButton

var lines_queue: Array = []
var active_choices: Array = []

func _ready() -> void:
	visible = false
	EventBus.dialogue_started.connect(_on_dialogue_started)
	continue_button.pressed.connect(_on_continue_pressed)

func _on_dialogue_started(speaker_name: String, text_lines: Array, choices: Array) -> void:
	visible = true
	speaker_label.text = speaker_name
	lines_queue = text_lines.duplicate()
	active_choices = choices.duplicate()
	_show_next_line()

func _show_next_line() -> void:
	if lines_queue.size() > 0:
		var current_line = lines_queue.pop_front()
		dialogue_text.text = current_line
		choices_container.visible = false
		continue_button.visible = true
		SoundManager.play_ui_click()
	else:
		_show_choices()

func _show_choices() -> void:
	continue_button.visible = false
	for child in choices_container.get_children():
		child.queue_free()
		
	if active_choices.is_empty():
		_close_dialogue()
		return
		
	choices_container.visible = true
	for i in range(active_choices.size()):
		var choice = active_choices[i]
		var btn = Button.new()
		btn.text = "➔ " + str(choice.get("text", ""))
		btn.add_theme_font_size_override("font_size", 14)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var action = choice.get("action", "")
		btn.pressed.connect(func(): _on_choice_clicked(action))
		choices_container.add_child(btn)

func _on_continue_pressed() -> void:
	_show_next_line()

func _on_choice_clicked(action: String) -> void:
	SoundManager.play_ui_click()
	EventBus.dialogue_action_triggered.emit(action)
	match action:
		"accept":
			ContractManager.advance_tutorial_to_in_progress()
			_close_dialogue()
		"details":
			lines_queue = [
				"Nel dettaglio: voglio che il cliente veda il logo della nostra Mole Antonelliana in alto, la lista delle nostre specialità come la Margherita DOC e la pizza al Tartufo, i nostri orari di apertura e un bel pulsante per prenotare un tavolo online!",
				"Se il sito è completo ed elegante, i € 260 sono tuoi all'istante!"
			]
			active_choices = [
				{"text": "Chiarissimo Mario, mi metto subito al lavoro!", "action": "accept"}
			]
			_show_next_line()
		"accept_cafe":
			ContractManager.advance_contract_to_in_progress("caffe_san_carlo", "Torna al tuo studio e usa WebForge sul laptop per sviluppare il Touch Web POS.")
			_close_dialogue()
		"details_cafe":
			lines_queue = [
				"Per il POS abbiamo bisogno di: griglia touch per caffè e brioche, comande veloci per i tavoli esterni su Via Po, e integrazione con pagamenti Satispay e carta.",
				"Completando questo, ti affideremo la gestione server cloud a € 45/giorno fissi!"
			]
			active_choices = [
				{"text": "Perfetto Elena, inizio subito lo sviluppo!", "action": "accept_cafe"}
			]
			_show_next_line()
		"accept_tech_shop":
			ContractManager.advance_contract_to_in_progress("elettronica_to", "Torna al tuo studio e usa WebForge sul laptop per impostare la migrazione Cloud e il catalogo.")
			_close_dialogue()
		"details_tech_shop":
			lines_queue = [
				"La nostra architettura richiede: cluster database replicato in tempo reale, catalogo componenti hardware sincronizzato, e backup incrementale notturno sul tuo rack server.",
				"Consegnata la migrazione, avrai € 860 e il 20% di sconto fisso su tutto l'hardware per sempre!"
			]
			active_choices = [
				{"text": "Ottimo Davide, mi metto all'opera sul codice!", "action": "accept_tech_shop"}
			]
			_show_next_line()
		"open_hardware_shop":
			_close_dialogue()
			EventBus.shop_opened.emit("elettronica_componenti")
		"accept_factory_bellini":
			ContractManager.accept_factory_commission()
			_close_dialogue()
		"details_factory_bellini":
			lines_queue = [
				"Prima di ordinare materiali, perlustra tutte e 4 le zone della fabbrica: Reparto CNC (Wi-Fi), Magazzino (Server), Ufficio Tecnico (2 PC) e Vetrina Catalogo (Sito Web).",
				"Dopo il sopralluogo vedrai gli ologrammi ciano dei componenti in officina e potrai installarli o configurare rete e sito!"
			]
			active_choices = [
				{"text": "Perfetto Ing. Bellini! Inizio subito il sopralluogo dell'officina.", "action": "accept_factory_bellini"}
			]
			_show_next_line()
		"start_sidejob_volantinaggio":
			_close_dialogue()
			SideJobManager.start_job("volantinaggio")
		"start_sidejob_corriere_espresso":
			_close_dialogue()
			SideJobManager.start_job("corriere_espresso")
		"start_sidejob_riparazione_rapida":
			_close_dialogue()
			SideJobManager.start_job("riparazione_rapida")
		"start_sidejob_logistica_merci":
			_close_dialogue()
			SideJobManager.start_job("logistica_merci")
		"cancel_sidejob":
			_close_dialogue()
			SideJobManager.cancel_active_job()
		"details_ogr":
			lines_queue = [
				"Ogni progetto serio, contratto Web/NetShield e coppia di lavoretti ti premia con Stelle ★ Potenziamenti.",
				"Apri l'app 'Potenziamenti ★' su TO-OS e investi stelle nel ramo 'Appalti OGR Enterprise': sbloccherai bandi fino al Tier IV (Smart Grid & Intesa Sanpaolo Core, oltre € 5.200+ con hardware dedicato da Elettronica TO)!"
			]
			active_choices = [
				{"text": "Chiarissimo Ing. Viale! Scalo i bandi su TO-OS.", "action": "close"}
			]
			_show_next_line()
		"details_post_ogr":
			lines_queue = [
				"Ecco la roadmap industriale Post-OGR: 1) Nel cortile Sud qui fuori trovi l'Ing. Dario Ferrero e 3 depositi d'estrazione (Rame, Silicio, Alluminio/Terre Rare). Estrai i materiali e consegnali alla Stazione di Raffinazione per ottenere 🔬 Crediti di Ricerca!",
				"2) Usa i Crediti 🔬 RC nell'app 'Conoscenza R&D' su TO-OS per sbloccare 'Automazione & Robotica Lv.1' e costruisci fisicamente il Mining Robot MK1 sulla piazzola OGR per automatizzare la produzione.",
				"3) Sblocca 'Hardware & Avionica Droni Lv.1' e raggiungi la Dr.ssa Chiara Conti al Lab Droni di Borgo Po per assemblare pezzo per pezzo in 7 fasi il tuo TO-Drone MK1 3D e fondare i Dipartimenti Aziendali all'Incubatore Startup Torino!"
			]
			active_choices = [
				{"text": "Fantastico Ing. Viale! Vado subito al Polo Estrazione OGR.", "action": "close"}
			]
			_show_next_line()
		"techops_build_conveyor":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.build_conveyor()
		"techops_sell_stock_batch":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				var sold_any := false
				for m in TechOpsManager.MATERIAL_ORDER:
					if TechOpsManager.get_stored_count(m) > 0:
						TechOpsManager.sell_stored_material(m, mini(3, TechOpsManager.get_stored_count(m)))
						sold_any = true
						break
				if not sold_any:
					EventBus.notification_posted.emit("Magazzino Vuoto", "Nessun materiale disponibile da vendere.", "warning")
		"techops_upgrade_robot_1":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.upgrade_mining_robot(1)
		"techops_upgrade_robot_2":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.upgrade_mining_robot(2)
		"techops_maintain_robot_1":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.maintain_mining_robot(1)
		"techops_maintain_robot_2":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.maintain_mining_robot(2)
		"drone_mission_lidar":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.start_drone_mission("drone_lidar_survey")
		"drone_mission_inspect":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.start_drone_mission("drone_infra_inspect")
		"drone_mission_relay":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.start_drone_mission("drone_net_relay")
		"drone_toggle_logistics":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.toggle_drone_auto_logistics()
		"unlock_dept_hardware":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.unlock_department("dept_hardware")
		"unlock_dept_cloud_ai":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.unlock_department("dept_cloud_ai")
		"unlock_dept_aerospace":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.unlock_department("dept_aerospace")
		"bus_buy_pass":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.buy_or_toggle_vehicle("bus_pass")
		"bus_travel_bus_sancarlo":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.fast_travel_to_bus_stop("bus_sancarlo")
		"bus_travel_bus_valdocco":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.fast_travel_to_bus_stop("bus_valdocco")
		"bus_travel_bus_ogr":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.fast_travel_to_bus_stop("bus_ogr")
		"bus_travel_bus_borgopo":
			_close_dialogue()
			if is_instance_valid(TechOpsManager):
				TechOpsManager.fast_travel_to_bus_stop("bus_borgopo")
		"close", _:
			_close_dialogue()


func _close_dialogue() -> void:
	visible = false
	EventBus.dialogue_ended.emit()

