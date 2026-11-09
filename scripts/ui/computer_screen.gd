extends Control
## ComputerScreen - Simulated Desktop Operating System (TO-OS 26.4 Torino Edition)
## Complete with Mail, Freelance Hub, Hardware Shop, Bank, 19" Rack Manager & Talent Hub

@onready var top_balance_label: Label = $TopBar/HBox/BalanceLabel
@onready var clock_label: Label = $TopBar/HBox/ClockLabel
@onready var exit_button: Button = $TopBar/HBox/ExitButton

# App windows
@onready var mail_window: PanelContainer = $Windows/MailWindow
@onready var freelance_window: PanelContainer = $Windows/FreelanceWindow
@onready var shop_window: PanelContainer = $Windows/ShopWindow
@onready var bank_window: PanelContainer = $Windows/BankWindow
@onready var rack_window: PanelContainer = $Windows/RackWindow
@onready var talent_window: PanelContainer = $Windows/TalentWindow

# Mail Window components
@onready var mail_list: ItemList = $Windows/MailWindow/Margin/VBox/Split/MailList
@onready var mail_subject: Label = $Windows/MailWindow/Margin/VBox/Split/MailBody/SubjectLabel
@onready var mail_content: RichTextLabel = $Windows/MailWindow/Margin/VBox/Split/MailBody/ContentLabel
@onready var deliver_project_btn: Button = $Windows/MailWindow/Margin/VBox/Split/MailBody/DeliverButton

# Shop components
@onready var buy_monitor_btn: Button = $Windows/ShopWindow/Margin/VBox/ShopScroll/Grid/MonitorCard/BuyButton
@onready var buy_chair_btn: Button = $Windows/ShopWindow/Margin/VBox/ShopScroll/Grid/ChairCard/BuyButton
@onready var buy_plant_btn: Button = $Windows/ShopWindow/Margin/VBox/ShopScroll/Grid/PlantCard/BuyButton
@onready var buy_server_btn: Button = $Windows/ShopWindow/Margin/VBox/ShopScroll/Grid/ServerCard/BuyButton
@onready var monitor_status: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/Grid/MonitorCard/StatusLabel
@onready var chair_status: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/Grid/ChairCard/StatusLabel
@onready var plant_status: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/Grid/PlantCard/StatusLabel
@onready var server_status: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/Grid/ServerCard/StatusLabel

# Freelance components
@onready var freelance_text: RichTextLabel = $Windows/FreelanceWindow/Margin/VBox/DetailsLabel
@onready var open_webforge_btn: Button = $Windows/FreelanceWindow/Margin/VBox/LaunchWebForgeButton

# Bank components
@onready var bank_ledger_text: RichTextLabel = $Windows/BankWindow/Margin/VBox/LedgerText

# Rack Manager components
@onready var temp_label: Label = $Windows/RackWindow/Margin/VBox/TelemetryBanner/HBox/TempLabel
@onready var fans_label: Label = $Windows/RackWindow/Margin/VBox/TelemetryBanner/HBox/FansLabel
@onready var bandwidth_label: Label = $Windows/RackWindow/Margin/VBox/TelemetryBanner/HBox/BandwidthLabel
@onready var uptime_label: Label = $Windows/RackWindow/Margin/VBox/TelemetryBanner/HBox/UptimeLabel
@onready var cool_silent_btn: Button = $Windows/RackWindow/Margin/VBox/CoolingRow/CoolSilentBtn
@onready var cool_auto_btn: Button = $Windows/RackWindow/Margin/VBox/CoolingRow/CoolAutoBtn
@onready var cool_boost_btn: Button = $Windows/RackWindow/Margin/VBox/CoolingRow/CoolBoostBtn
@onready var recalibrate_btn: Button = $Windows/RackWindow/Margin/VBox/CoolingRow/RecalibrateBtn
@onready var domains_text: RichTextLabel = $Windows/RackWindow/Margin/VBox/Split/DomainsPanel/VBox/DomainsText
@onready var buy_blade_btn: Button = $Windows/RackWindow/Margin/VBox/Split/ModulesPanel/VBox/BuyBladeBtn
@onready var buy_liquid_btn: Button = $Windows/RackWindow/Margin/VBox/Split/ModulesPanel/VBox/BuyLiquidBtn
@onready var buy_san_btn: Button = $Windows/RackWindow/Margin/VBox/Split/ModulesPanel/VBox/BuySanBtn
@onready var upgrade_tier2_btn: Button = $Windows/RackWindow/Margin/VBox/Split/ModulesPanel/VBox/UpgradeTier2Btn
@onready var upgrade_tier3_btn: Button = $Windows/RackWindow/Margin/VBox/Split/ModulesPanel/VBox/UpgradeTier3Btn

# Talent Hub components
@onready var talent_stats_label: Label = $Windows/TalentWindow/Margin/VBox/StatsBanner/StatsLabel
@onready var candidates_list: VBoxContainer = $Windows/TalentWindow/Margin/VBox/CandidatesScroll/CandidatesList
@onready var firewall_icon: Button = $DesktopIcons/VBox/FirewallIcon

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
	$DesktopIcons/VBox/RackIcon.pressed.connect(func(): _open_window(rack_window))
	$DesktopIcons/VBox/TalentIcon.pressed.connect(func(): _open_window(talent_window))
	firewall_icon.pressed.connect(_launch_firewall)
	
	# Close buttons for windows
	$Windows/MailWindow/Margin/VBox/Header/CloseBtn.pressed.connect(func(): mail_window.visible = false)
	$Windows/FreelanceWindow/Margin/VBox/Header/CloseBtn.pressed.connect(func(): freelance_window.visible = false)
	$Windows/ShopWindow/Margin/VBox/Header/CloseBtn.pressed.connect(func(): shop_window.visible = false)
	$Windows/BankWindow/Margin/VBox/Header/CloseBtn.pressed.connect(func(): bank_window.visible = false)
	$Windows/RackWindow/Margin/VBox/Header/CloseBtn.pressed.connect(func(): rack_window.visible = false)
	$Windows/TalentWindow/Margin/VBox/Header/CloseBtn.pressed.connect(func(): talent_window.visible = false)
	
	mail_list.item_selected.connect(_on_mail_selected)
	deliver_project_btn.pressed.connect(_on_deliver_project_pressed)
	open_webforge_btn.pressed.connect(_launch_webforge)
	buy_monitor_btn.pressed.connect(_buy_monitor)
	buy_chair_btn.pressed.connect(_buy_chair)
	buy_plant_btn.pressed.connect(_buy_plant)
	buy_server_btn.pressed.connect(_buy_server)
	
	# Rack Manager buttons
	cool_silent_btn.pressed.connect(func(): ServerRackManager.set_cooling_mode("silent"))
	cool_auto_btn.pressed.connect(func(): ServerRackManager.set_cooling_mode("auto"))
	cool_boost_btn.pressed.connect(func(): ServerRackManager.set_cooling_mode("boost"))
	recalibrate_btn.pressed.connect(func(): ServerRackManager.resolve_physical_maintenance(); _update_rack_display())
	buy_blade_btn.pressed.connect(_buy_blade)
	buy_liquid_btn.pressed.connect(_buy_liquid)
	buy_san_btn.pressed.connect(_buy_san)
	upgrade_tier2_btn.pressed.connect(func(): ServerRackManager.upgrade_rack_tier(2); _update_rack_display())
	upgrade_tier3_btn.pressed.connect(func(): ServerRackManager.upgrade_rack_tier(3); _update_rack_display())
	
	ServerRackManager.telemetry_updated.connect(_on_rack_telemetry)
	EventBus.employee_hired.connect(func(_id, _n): _update_talent_display())
	EventBus.employee_fired.connect(func(_id): _update_talent_display())
	
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
	_update_rack_display()
	_update_talent_display()
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
	_update_rack_display()

func _on_contract_updated(_id: String, _status: String) -> void:
	_update_freelance_display()
	_setup_emails()

func _open_window(target_window: PanelContainer) -> void:
	SoundManager.play_ui_click()
	mail_window.visible = false
	freelance_window.visible = false
	shop_window.visible = false
	bank_window.visible = false
	rack_window.visible = false
	talent_window.visible = false
	target_window.visible = true

func _setup_emails() -> void:
	mail_list.clear()
	emails.clear()
	
	# Mario (Pizzeria)
	emails.append({
		"from": "Mario Esposito <mario@pizzeriadamario-to.it>",
		"subject": "Richiesta Realizzazione Sito Web - Pizzeria Da Mario (Via Po)",
		"body": "Gentile Dottore,\n\nHo visto il suo annuncio su Freelance Hub Torino. Cerchiamo qualcuno che crei il nostro sito web ufficiale per attirare turisti e clienti a Torino.\n\nBudget concordato: € 650,00 netti.\n\nPassi a trovarmi direttamente di persona in bottega in Via Po 18 (esca dal suo garage e segua la via fino all'insegna luminosa).\n\nMario Esposito - Titolare",
		"contract_id": "pizzeria_da_mario"
	})
	
	# Elena (Caffè San Carlo) - Appears after tutorial or when contract unlocked
	if ContractManager.is_contract_completed("pizzeria_da_mario") or ContractManager.active_contracts.has("caffe_san_carlo"):
		emails.append({
			"from": "Elena Barista <elena@caffesancarlo.to.it>",
			"subject": "Richiesta Touch Web POS Cassa & Ordini - Caffè San Carlo",
			"body": "Gentile Sviluppatore,\n\nMario mi ha mostrato il nuovo sito web e ne sono rimasta affascinata!\nQui al Caffè San Carlo in Via Po abbiamo code infinite al bancone nelle ore di punta.\nCi serve un sistema Web POS moderno per velocizzare le ordinazioni di caffè e bicerin e gestire i tavoli del dehors.\n\nBudget: € 1.250,00 netti + Hosting mensile sul suo server rack!\nPassi a trovarmi al bancone del Caffè in Via Po per definire i dettagli.\n\nCordiali saluti,\nElena - Store Manager",
			"contract_id": "caffe_san_carlo"
		})
		
	# Davide (Elettronica TO) - Appears after Caffè San Carlo
	if ContractManager.is_contract_completed("caffe_san_carlo") or ContractManager.active_contracts.has("elettronica_to"):
		emails.append({
			"from": "Davide Tecnico <davide@elettronicato.com>",
			"subject": "Proposta Migrazione Cloud & Catalogo - Elettronica TO",
			"body": "Ciao collega,\n\nHo saputo del Web POS che hai installato al Caffè San Carlo, lavoro eccellente!\nDa Elettronica TO dobbiamo dismettere il nostro vecchio server locale e migrare a un'architettura cloud con database ridondato e backup sul tuo server rack.\n\nBudget stanziato: € 1.850,00 netti + 20% di sconto permanente su tutti i nostri prodotti hardware!\nVieni in negozio in Via Po per iniziare.\n\nA presto,\nDavide - Senior Tech Clerk",
			"contract_id": "elettronica_to"
		})
	
	emails.append({
		"from": "Risorse Umane <recruiting@megacorp-consulting.it>",
		"subject": "Esito candidatura Posizione Junior Software Engineer",
		"body": "Gentile Candidato,\n\nLa ringraziamo per aver inviato il suo CV. Pur apprezzando il suo brillante percorso di laurea con 110 e lode al Politecnico, cerchiamo per questo stage (rimborso mensile: 400€ lordi) un profilo con almeno 8 anni di esperienza pregressa in cloud computing e intelligenza artificiale quantistica.\n\nLe auguriamo il meglio per il suo futuro.",
		"contract_id": ""
	})
	
	emails.append({
		"from": "Segreteria Studenti <laurea@unito.it>",
		"subject": "Certificato Ufficiale di Laurea in Informatica",
		"body": "Gentile Dottore,\n\nIl suo certificato ufficiale di Laurea Magistrale in Informatica (110 e Lode) è pronto. Può ammirarlo appeso alla parete del suo studio.\n\nCongratulazioni per il traguardo raggiunto!",
		"contract_id": ""
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
		
		var cid = e.get("contract_id", "")
		if cid != "":
			var c = ContractManager.get_contract(cid)
			var status = c.get("status", "available")
			if status == "built" and not ContractManager.is_contract_completed(cid):
				deliver_project_btn.visible = true
				deliver_project_btn.text = "★ Consegna Progetto a %s (€ %0.2f)" % [c.get("client", "Cliente"), c.get("budget", 650.0)]
				return
		deliver_project_btn.visible = false

func _on_deliver_project_pressed() -> void:
	# Find built contract to complete
	for cid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to"]:
		var c = ContractManager.get_contract(cid)
		if c.get("status") == "built":
			ContractManager.complete_story_contract(cid)
			deliver_project_btn.visible = false
			_setup_emails()
			_update_shop_buttons()
			_update_rack_display()
			return

func _update_freelance_display() -> void:
	var t = "[b]COMMISSIONI E MISSIONI STORIA:[/b]\n\n"
	
	for cid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to"]:
		var c = ContractManager.get_contract(cid)
		if c.is_empty():
			continue
		var st = c.get("status", "available")
		var st_color = "#ffbb33"
		if st == "in_progress": st_color = "#33ccff"
		elif st == "built": st_color = "#33ff77"
		elif st == "completed": st_color = "#88ff88"
		
		t += "• [b]%s[/b] — %s\n" % [c.get("title", ""), c.get("client", "")]
		t += "  Compenso: [color=#44ff88]€ %0.2f[/color] | Stato: [color=%s]%s[/color]\n" % [c.get("budget", 0.0), st_color, st.to_upper()]
		t += "  Obiettivo: %s\n\n" % c.get("objective_text", "")
		
	# Check if any project is in progress for the IDE button
	var has_in_progress = false
	for c in ContractManager.active_contracts.values():
		if c.get("status") == "in_progress":
			has_in_progress = true
			break
			
	open_webforge_btn.visible = has_in_progress
	if has_in_progress:
		open_webforge_btn.text = "⚡ Apri WebForge IDE (Sviluppa Software)"
		
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
	var has_active = false
	for c in ContractManager.active_contracts.values():
		if c.get("status") == "in_progress":
			has_active = true
			break
			
	if not has_active:
		SoundManager.play_ui_click()
		EventBus.notification_posted.emit(
			"WebForge Inattivo",
			"Nessun contratto in lavorazione! Recati dai clienti in Via Po per definire e accettare i requisiti.",
			"warning"
		)
		return
		
	SoundManager.play_ui_click()
	EventBus.minigame_started.emit("web_forge")

func _update_shop_buttons() -> void:
	var has_monitor = "monitor_upgrade" in GameManager.studio_upgrades_installed
	var has_chair = "chair_gaming_upgrade" in GameManager.studio_upgrades_installed
	var has_plant = "plant_aloe" in GameManager.studio_upgrades_installed
	var has_server = "server_rack_upgrade" in GameManager.studio_upgrades_installed
	
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

	if has_server:
		buy_server_btn.disabled = true
		buy_server_btn.text = "GIA' INSTALLATO"
		server_status.text = "[color=#44ff88]Attivo in studio (Hosting ON)[/color]"
	else:
		buy_server_btn.disabled = not EconomyManager.can_afford(450.0)
		buy_server_btn.text = "Acquista (€ 450,00)"
		server_status.text = "Disponibile per l'ordine"

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

func _buy_server() -> void:
	if EconomyManager.spend(450.0, "Acquisto Mini Server Rack 4U & NAS"):
		EventBus.item_purchased.emit("server_rack_upgrade", 450.0)
		ServerRackManager.unlock_server_rack()
		EventBus.notification_posted.emit("Infrastruttura Attiva", "Il server rack è attivo in studio! Sbloccati servizi di Hosting.", "success")
		_update_shop_buttons()
		_update_rack_display()

func _update_bank_display() -> void:
	var t = "[b]SALDO ATTUALE:[/b] € %0.2f\n\n[b]ESTRATTO CONTO RECENTE:[/b]\n" % EconomyManager.balance
	for entry in EconomyManager.ledger:
		var delta_str = "+€ %0.2f" % entry["delta"] if entry["delta"] >= 0 else "-€ %0.2f" % abs(entry["delta"])
		t += "• %s: %s (Saldo: € %0.2f)\n" % [entry["reason"], delta_str, entry["balance_after"]]
	bank_ledger_text.text = t

# -------------------------------------------------------------
# RACK MANAGER UI
# -------------------------------------------------------------
func _launch_firewall() -> void:
	SoundManager.play_ui_click()
	EventBus.minigame_started.emit("firewall_router")

func _update_rack_display() -> void:
	if not rack_window:
		return
		
	var temp = ServerRackManager.temperature_celsius
	var fans = ServerRackManager.fan_speed_rpm
	var bw = ServerRackManager.bandwidth_mbps
	var uptime = ServerRackManager.uptime_percent
	var status = ServerRackManager.status_health
	
	_on_rack_telemetry(temp, fans, bw, status)
	
	# Domains & Tier Info
	var max_safe = ServerRackManager.get_max_safe_domains()
	var current_domains = ServerRackManager.hosted_domains.size()
	var dt = "[b]HARDWARE:[/b] [color=#00ccff]%s[/color]\n" % ServerRackManager.get_tier_name()
	dt += "[b]CAPACITÀ ATTUALE:[/b] %d / %d Domini Massimi\n\n" % [current_domains, max_safe]
	
	if current_domains > max_safe:
		dt += "[color=#ff4444][b]⚠ ATTENZIONE: SERVER IN SOVRACCARICO (OVERLOAD)![/b]\nIl mini-rack casalingo è sovraccarico (limite: %d clienti). CPU al 95%%, thermal throttling attivo e rendite dimezzate (-50%%)! Aggiorna a Blade 12U Enterprise![/color]\n\n" % max_safe
	elif current_domains == max_safe:
		dt += "[color=#ffbb33]Capacità massima del rack raggiunta (%d/%d). Nuovi contratti richiederanno un upgrade hardware![/color]\n\n" % [current_domains, max_safe]
		
	if ServerRackManager.hosted_domains.is_empty():
		dt += "Nessun dominio ospitato. Acquista il server rack e completa contratti per vendere servizi di hosting!\n"
	else:
		var total_daily = ServerRackManager.calculate_daily_hosting_revenue()
		for d in ServerRackManager.hosted_domains:
			dt += "• [b]%s[/b] (%s)\n  Canone: [color=#44ff88]+€ %0.2f/giorno[/color] | Status: [color=#33ff77]ONLINE 200 OK[/color]\n\n" % [d["domain"], d["client_name"], d["daily_rate"]]
		dt += "[b]Totale Ricavi Ricorrenti:[/b] [color=#44ff88]+€ %0.2f/giorno[/color]" % total_daily
		if EmployeeManager.is_employee_hired("emp_sara"):
			dt += " [color=#00ccff](+35% Bonus DevOps Sara Bellini)[/color]"
			
	domains_text.text = dt
	
	# Module Buttons
	var has_blade = "server_blade_quad" in ServerRackManager.installed_modules
	var has_liquid = "server_cooling_liquid" in ServerRackManager.installed_modules
	var has_san = "server_storage_san" in ServerRackManager.installed_modules
	
	var is_unlocked = ServerRackManager.is_rack_unlocked
	
	buy_blade_btn.disabled = has_blade or not is_unlocked or not EconomyManager.can_afford(450.0)
	buy_blade_btn.text = "✔ Modulo Blade Quad-Core Installato" if has_blade else "+ Installa Modulo Blade Quad-Core Xeon (€ 450,00)"
	
	buy_liquid_btn.disabled = has_liquid or not is_unlocked or not EconomyManager.can_afford(320.0)
	buy_liquid_btn.text = "✔ Raffreddamento Liquido AIO Attivo" if has_liquid else "+ Installa Raffreddamento a Liquido AIO (€ 320,00)"
	
	buy_san_btn.disabled = has_san or not is_unlocked or not EconomyManager.can_afford(680.0)
	buy_san_btn.text = "✔ Storage SAN Raid-10 Operativo (+25% fee)" if has_san else "+ Installa Array Storage SAN Raid-10 (€ 680,00)"
	
	# Tier Upgrade Buttons
	var tier = ServerRackManager.rack_tier
	if tier >= 2:
		upgrade_tier2_btn.disabled = true
		upgrade_tier2_btn.text = "✔ Tier 2: Blade 12U Enterprise Attivo"
	else:
		upgrade_tier2_btn.disabled = not is_unlocked or not EconomyManager.can_afford(750.0)
		upgrade_tier2_btn.text = "▲ Upgrade a Server Blade 12U Enterprise (€ 750,00) [Capacità: 8 domini]"
		
	if tier >= 3:
		upgrade_tier3_btn.disabled = true
		upgrade_tier3_btn.text = "✔ Tier 3: Full Cabinet 42U Data Center Attivo"
	elif tier == 2:
		upgrade_tier3_btn.disabled = not EconomyManager.can_afford(1600.0)
		upgrade_tier3_btn.text = "▲ Upgrade a Full Cabinet 42U Data Center (€ 1.600,00) [Capacità: 20 domini]"
	else:
		upgrade_tier3_btn.disabled = true
		upgrade_tier3_btn.text = "▲ Upgrade Cabinet 42U (Richiede Tier 2)"

func _on_rack_telemetry(temp: float, fans: int, bw: float, status: String) -> void:
	var color_tag = "#44ff88"
	if status == "warning": color_tag = "#ffaa33"
	elif status == "critical": color_tag = "#ff4444"
	
	temp_label.text = "🌡 CPU: %0.1f °C [%s]" % [temp, status.to_upper()]
	fans_label.text = "💨 Ventole: %d RPM" % fans
	bandwidth_label.text = "📡 Banda: %0.1f Mbps" % bw
	uptime_label.text = "⏱ Uptime: %0.2f%%" % ServerRackManager.uptime_percent

func _buy_blade() -> void:
	if ServerRackManager.install_module("server_blade_quad", "Blade Quad-Core Xeon", 450.0):
		_update_rack_display()

func _buy_liquid() -> void:
	if ServerRackManager.install_module("server_cooling_liquid", "Raffreddamento a Liquido AIO", 320.0):
		_update_rack_display()

func _buy_san() -> void:
	if ServerRackManager.install_module("server_storage_san", "Storage SAN Raid-10", 680.0):
		_update_rack_display()

# -------------------------------------------------------------
# TALENT HUB UI
# -------------------------------------------------------------
func _update_talent_display() -> void:
	if not talent_window:
		return
		
	var hired = EmployeeManager.get_hired_employees()
	var payroll = EmployeeManager.calculate_daily_payroll()
	var revenue = EmployeeManager.calculate_employee_revenue()
	var net = revenue - payroll
	
	talent_stats_label.text = "👥 Team Attivo: %d Dipendenti | Buste Paga: € %0.2f/g | Utile Generato: +€ %0.2f/g | Netto: +€ %0.2f/g" % [hired.size(), payroll, revenue, net]
	
	# Clear previous candidates
	for child in candidates_list.get_children():
		child.queue_free()
		
	var candidates = EmployeeManager.get_all_candidates()
	for cand in candidates:
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.18, 0.21, 0.28, 1)
		card_style.set_content_margin_all(12)
		card_style.set_corner_radius_all(6)
		card.add_theme_stylebox_override("panel", card_style)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = SIZE_EXPAND_FILL
		
		var name_lbl = Label.new()
		name_lbl.text = "%s — %s" % [cand["name"], cand["role"]]
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1, 1))
		vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = cand["avatar_desc"]
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85, 1))
		vbox.add_child(desc_lbl)
		
		var perk_lbl = Label.new()
		perk_lbl.text = "★ Specializzazione: " + cand["perk"]
		perk_lbl.add_theme_font_size_override("font_size", 13)
		perk_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
		vbox.add_child(perk_lbl)
		
		var salary_lbl = Label.new()
		salary_lbl.text = "Stipendio: € %0.2f/giorno | Valore Prodotto: € %0.2f/giorno | Reputazione Richiesta: %d" % [cand["daily_salary"], cand["daily_revenue"], cand["reputation_req"]]
		salary_lbl.add_theme_font_size_override("font_size", 12)
		salary_lbl.add_theme_color_override("font_color", Color(0.4, 1, 0.6, 1))
		vbox.add_child(salary_lbl)
		
		hbox.add_child(vbox)
		
		var is_hired = EmployeeManager.is_employee_hired(cand["id"])
		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(140, 42)
		action_btn.size_flags_vertical = SIZE_SHRINK_CENTER
		
		if is_hired:
			action_btn.text = "Licenzia"
			action_btn.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
			var cid = cand["id"]
			action_btn.pressed.connect(func(): EmployeeManager.fire_employee(cid); _update_talent_display())
		else:
			action_btn.text = "Assumi (€ %0.2f)" % cand["daily_salary"]
			action_btn.add_theme_color_override("font_color", Color(0.3, 1, 0.6, 1))
			var can_hire = GameManager.reputation_points >= cand["reputation_req"] and EconomyManager.can_afford(cand["daily_salary"])
			action_btn.disabled = not can_hire
			var cid = cand["id"]
			action_btn.pressed.connect(func(): EmployeeManager.hire_employee(cid); _update_talent_display())
			
		hbox.add_child(action_btn)
		card.add_child(hbox)
		candidates_list.add_child(card)
