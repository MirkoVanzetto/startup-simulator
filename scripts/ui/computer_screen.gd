extends Control
## ComputerScreen - Simulated Desktop Operating System (TO-OS 26.4)

@onready var top_balance_label: Label = $TopBar/HBox/BalanceLabel
@onready var clock_label: Label = $TopBar/HBox/ClockLabel
@onready var exit_button: Button = $TopBar/HBox/ExitButton

# App windows
@onready var mail_window: PanelContainer = $Windows/MailWindow
@onready var freelance_window: PanelContainer = $Windows/FreelanceWindow
@onready var shop_window: PanelContainer = $Windows/ShopWindow
@onready var bank_window: PanelContainer = $Windows/BankWindow

# Mail Window components
@onready var mail_list: ItemList = $Windows/MailWindow/Margin/VBox/Split/MailList
@onready var mail_subject: Label = $Windows/MailWindow/Margin/VBox/Split/MailBody/SubjectLabel
@onready var mail_content: RichTextLabel = $Windows/MailWindow/Margin/VBox/Split/MailBody/ContentLabel
@onready var deliver_project_btn: Button = $Windows/MailWindow/Margin/VBox/Split/MailBody/DeliverButton

# Shop components
@onready var buy_monitor_btn: Button = $Windows/ShopWindow/Margin/VBox/Grid/MonitorCard/BuyButton
@onready var buy_chair_btn: Button = $Windows/ShopWindow/Margin/VBox/Grid/ChairCard/BuyButton
@onready var buy_plant_btn: Button = $Windows/ShopWindow/Margin/VBox/Grid/PlantCard/BuyButton
@onready var monitor_status: Label = $Windows/ShopWindow/Margin/VBox/Grid/MonitorCard/StatusLabel
@onready var chair_status: Label = $Windows/ShopWindow/Margin/VBox/Grid/ChairCard/StatusLabel
@onready var plant_status: Label = $Windows/ShopWindow/Margin/VBox/Grid/PlantCard/StatusLabel

# Freelance components
@onready var freelance_text: RichTextLabel = $Windows/FreelanceWindow/Margin/VBox/DetailsLabel
@onready var open_webforge_btn: Button = $Windows/FreelanceWindow/Margin/VBox/LaunchWebForgeButton

# Bank components
@onready var bank_ledger_text: RichTextLabel = $Windows/BankWindow/Margin/VBox/LedgerText

var emails: Array[Dictionary] = []

func _ready() -> void:
	visible = false
	EventBus.computer_opened.connect(_on_computer_opened)
	EventBus.computer_closed.connect(_on_computer_closed)
	EventBus.funds_changed.connect(_on_funds_changed)
	EventBus.contract_updated.connect(_on_contract_updated)
	
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Desktop icons
	$DesktopIcons/VBox/MailIcon.pressed.connect(func(): _open_window(mail_window))
	$DesktopIcons/VBox/FreelanceIcon.pressed.connect(func(): _open_window(freelance_window))
	$DesktopIcons/VBox/WebForgeIcon.pressed.connect(_launch_webforge)
	$DesktopIcons/VBox/ShopIcon.pressed.connect(func(): _open_window(shop_window))
	$DesktopIcons/VBox/BankIcon.pressed.connect(func(): _open_window(bank_window))
	
	# Close buttons for windows
	$Windows/MailWindow/Margin/VBox/Header/CloseBtn.pressed.connect(func(): mail_window.visible = false)
	$Windows/FreelanceWindow/Margin/VBox/Header/CloseBtn.pressed.connect(func(): freelance_window.visible = false)
	$Windows/ShopWindow/Margin/VBox/Header/CloseBtn.pressed.connect(func(): shop_window.visible = false)
	$Windows/BankWindow/Margin/VBox/Header/CloseBtn.pressed.connect(func(): bank_window.visible = false)
	
	mail_list.item_selected.connect(_on_mail_selected)
	deliver_project_btn.pressed.connect(_on_deliver_project_pressed)
	open_webforge_btn.pressed.connect(_launch_webforge)
	buy_monitor_btn.pressed.connect(_buy_monitor)
	buy_chair_btn.pressed.connect(_buy_chair)
	buy_plant_btn.pressed.connect(_buy_plant)
	
	_setup_emails()
	_update_shop_buttons()
	EventBus.time_tick.connect(func(_h, _m, _d): _update_top_bar())
	EventBus.contract_marketplace_refreshed.connect(_update_freelance_display)

func _on_computer_opened() -> void:
	visible = true
	SoundManager.play_keyboard_sound()
	_update_top_bar()
	_update_freelance_display()
	_update_bank_display()
	_update_shop_buttons()
	_open_window(mail_window)

func _on_computer_closed() -> void:
	visible = false

func _on_exit_pressed() -> void:
	SoundManager.play_ui_click()
	EventBus.computer_closed.emit()

func _update_top_bar() -> void:
	top_balance_label.text = "Fondi: € %0.2f" % EconomyManager.balance
	clock_label.text = "%s - Giorno %d (%s)" % [CalendarSystem.get_formatted_time(), CalendarSystem.current_day, CalendarSystem.get_day_name()]

func _on_funds_changed(new_balance: float, _delta: float, _reason: String) -> void:
	top_balance_label.text = "Fondi: € %0.2f" % new_balance
	_update_shop_buttons()
	_update_bank_display()

func _on_contract_updated(_id: String, _status: String) -> void:
	_update_freelance_display()
	_setup_emails()

func _open_window(target_window: PanelContainer) -> void:
	SoundManager.play_ui_click()
	mail_window.visible = false
	freelance_window.visible = false
	shop_window.visible = false
	bank_window.visible = false
	target_window.visible = true

func _setup_emails() -> void:
	mail_list.clear()
	emails.clear()
	
	var tut = ContractManager.get_tutorial_contract()
	var tut_status = tut.get("status", "available")
	
	emails.append({
		"from": "Mario Esposito <mario@pizzeriadamario-to.it>",
		"subject": "Richiesta Realizzazione Sito Web - Pizzeria Da Mario (Via Po)",
		"body": "Gentile Dottore,\n\nHo visto il suo annuncio su Freelance Hub Torino. Cerchiamo qualcuno che crei il nostro sito web ufficiale per attirare turisti e clienti a Torino.\n\nBudget concordato: € 650,00 netti.\n\nIMPORTANTE:\nPer definire i requisiti e stringerci la mano, passi a trovarmi direttamente di persona in bottega in Via Po 18 (esca dal suo garage e segua la via fino all'insegna luminosa della pizzeria).\n\nLa aspetto!\nMario Esposito - Titolare",
		"is_tutorial": true
	})
	
	emails.append({
		"from": "Risorse Umane <recruiting@megacorp-consulting.it>",
		"subject": "Esito candidatura Posizione Junior Software Engineer",
		"body": "Gentile Candidato,\n\nLa ringraziamo per aver inviato il suo CV. Pur apprezzando il suo brillante percorso di laurea con 110 e lode al Politecnico, cerchiamo per questo stage (rimborso mensile: 400€ lordi) un profilo con almeno 8 anni di esperienza pregressa in cloud computing e intelligenza artificiale quantistica.\n\nLe auguriamo il meglio per il suo futuro.",
		"is_tutorial": false
	})
	
	emails.append({
		"from": "Segreteria Studenti <laurea@unito.it>",
		"subject": "Certificato Ufficiale di Laurea in Informatica",
		"body": "Gentile Dottore,\n\nIl suo certificato ufficiale di Laurea Magistrale in Informatica (110 e Lode) è pronto. Può ammirarlo appeso alla parete del suo studio.\n\nCongratulazioni per il traguardo raggiunto!",
		"is_tutorial": false
	})
	
	for i in range(emails.size()):
		var e = emails[i]
		mail_list.add_item(e["subject"])
		
	if emails.size() > 0:
		_display_email(0)

func _on_mail_selected(index: int) -> void:
	_display_email(index)

func _display_email(index: int) -> void:
	if index >= 0 and index < emails.size():
		var e = emails[index]
		mail_subject.text = e["subject"]
		mail_content.text = "[b]Da:[/b] " + e["from"] + "\n\n" + e["body"]
		
		var tut = ContractManager.get_tutorial_contract()
		var tut_status = tut.get("status", "available")
		if e["is_tutorial"] and tut_status == "built":
			deliver_project_btn.visible = true
			deliver_project_btn.text = "★ Consegna Progetto WebForge a Mario (€ 650,00)"
		else:
			deliver_project_btn.visible = false

func _on_deliver_project_pressed() -> void:
	ContractManager.complete_tutorial_contract()
	deliver_project_btn.visible = false
	_setup_emails()
	_update_shop_buttons()

func _update_freelance_display() -> void:
	var tut = ContractManager.get_tutorial_contract()
	var status = tut.get("status", "available")
	var status_text = ""
	match status:
		"available":
			status_text = "[color=#ffbb33]DA ACCETTARE DI PERSONA IN VIA PO[/color]"
			open_webforge_btn.visible = false
		"in_progress":
			status_text = "[color=#33ccff]IN SVILUPPO (Usa WebForge sul laptop)[/color]"
			open_webforge_btn.visible = true
			open_webforge_btn.text = "⚡ Apri WebForge IDE (Sviluppa Sito Pizzeria)"
		"built":
			status_text = "[color=#33ff77]COMPLETATO (Pronto per la consegna via email)[/color]"
			open_webforge_btn.visible = true
			open_webforge_btn.text = "⚡ Apri WebForge IDE (Revisiona Sito)"
		"completed":
			status_text = "[color=#88ff88]CONSEGNATO & LIQUIDATO (€ 650,00)[/color]"
			open_webforge_btn.visible = false

	var t = "[b]COMMISSIONE ATTIVA:[/b]\n"
	t += "[b]Cliente:[/b] Mario Esposito (Pizzeria Da Mario)\n[b]Budget:[/b] € 650.00\n[b]Stato:[/b] %s\n\n" % status_text
	
	if status == "available":
		t += "[b][color=#ffbb33]ISTRUZIONI PER L'ACCETTAZIONE:[/color][/b]\n"
		t += "• Esci dal tuo garage studio e incamminati lungo Via Po.\n"
		t += "• Raggiungi la bottega della Pizzeria Da Mario (insegna luminosa).\n"
		t += "• Premi [E] per parlare di persona con Mario e accettare l'incarico!\n\n"
	else:
		t += "[b]Requisiti Concordati:[/b]\n• Logo con la Mole Antonelliana\n• Menu Pizze Napoletane\n• Orari & Indirizzo Via Po\n• Modulo Prenotazione Tavoli\n\n"
	
	t += "[b]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/b]\n"
	t += "[b][color=#ffcc44]MARKETPLACE FREELANCE DI TORINO (OPPORTUNITÀ B2B):[/color][/b]\n\n"
	
	if ContractManager.marketplace_contracts.is_empty():
		t += "Nessun bando aperto al momento. Nuove offerte disponibili domani mattina alle 08:00.\n"
	else:
		for c in ContractManager.marketplace_contracts:
			t += "• [b]%s[/b] — %s\n" % [c["title"], c["client"]]
			t += "  Settore: %s | Compenso: [color=#44ff88]€ %0.2f[/color] | Scadenza: %d gg | Difficoltà: %s\n" % [c["category"], c["budget"], c["deadline_days"], "★".repeat(c["difficulty"])]
			t += "  Requisiti: %s\n\n" % ", ".join(c["requirements"])
			
	freelance_text.text = t

func _launch_webforge() -> void:
	var tut = ContractManager.get_tutorial_contract()
	var status = tut.get("status", "available")
	if status == "available":
		SoundManager.play_ui_click()
		EventBus.notification_posted.emit(
			"WebForge Bloccato",
			"Nessuna commissione accettata! Devi prima recarti di persona da Mario alla Pizzeria in Via Po per accettare il lavoro.",
			"warning"
		)
		return
		
	SoundManager.play_ui_click()
	EventBus.minigame_started.emit("web_forge")

func _update_shop_buttons() -> void:
	var has_monitor = "monitor_upgrade" in GameManager.studio_upgrades_installed
	var has_chair = "chair_gaming_upgrade" in GameManager.studio_upgrades_installed
	var has_plant = "plant_aloe" in GameManager.studio_upgrades_installed
	
	if has_monitor:
		buy_monitor_btn.disabled = true
		buy_monitor_btn.text = "GIA' INSTALLATO"
		monitor_status.text = "[color=#44ff88]Installato sulla scrivania[/color]"
	else:
		buy_monitor_btn.disabled = not EconomyManager.can_afford(350.0)
		buy_monitor_btn.text = "Acquista (€ 350,00)"
		monitor_status.text = "Disponibile per l'ordine"
		
	if has_chair:
		buy_chair_btn.disabled = true
		buy_chair_btn.text = "GIA' INSTALLATA"
		chair_status.text = "[color=#44ff88]Installata alla postazione[/color]"
	else:
		buy_chair_btn.disabled = not EconomyManager.can_afford(220.0)
		buy_chair_btn.text = "Acquista (€ 220,00)"
		chair_status.text = "Disponibile per l'ordine"

	if has_plant:
		buy_plant_btn.disabled = true
		buy_plant_btn.text = "GIA' POSIZIONATA"
		plant_status.text = "[color=#44ff88]Posizionata in studio[/color]"
	else:
		buy_plant_btn.disabled = not EconomyManager.can_afford(35.0)
		buy_plant_btn.text = "Acquista (€ 35,00)"
		plant_status.text = "Disponibile per l'ordine"

func _buy_monitor() -> void:
	if EconomyManager.spend(350.0, "Acquisto Monitor 27\" Ultrawide"):
		EventBus.item_purchased.emit("monitor_upgrade", 350.0)
		EventBus.notification_posted.emit("Upgrade Installato", "Il secondo monitor è stato montato sulla scrivania!", "success")
		_update_shop_buttons()

func _buy_chair() -> void:
	if EconomyManager.spend(220.0, "Acquisto Sedia Ergonomica Pro"):
		EventBus.item_purchased.emit("chair_gaming_upgrade", 220.0)
		EventBus.notification_posted.emit("Upgrade Installato", "La nuova sedia ergonomica è stata posizionata!", "success")
		_update_shop_buttons()

func _buy_plant() -> void:
	if EconomyManager.spend(35.0, "Acquisto Pianta Succulenta d'Arredo"):
		EventBus.item_purchased.emit("plant_aloe", 35.0)
		EventBus.notification_posted.emit("Arredo Posizionato", "La pianta d'arredo è stata collocata nel tuo studio!", "success")
		_update_shop_buttons()

func _update_bank_display() -> void:
	var t = "[b]SALDO ATTUALE:[/b] € %0.2f\n\n[b]ESTRATTO CONTO RECENTE:[/b]\n" % EconomyManager.balance
	for entry in EconomyManager.ledger:
		var delta_str = "+€ %0.2f" % entry["delta"] if entry["delta"] >= 0 else "-€ %0.2f" % abs(entry["delta"])
		t += "• %s: %s (Saldo: € %0.2f)\n" % [entry["reason"], delta_str, entry["balance_after"]]
	bank_ledger_text.text = t
