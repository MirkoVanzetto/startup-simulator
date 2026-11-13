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
@onready var buy_monitor_btn: Button = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/MonitorCard/VBox/HBox/BuyButton
@onready var buy_chair_btn: Button = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/ChairCard/VBox/HBox/BuyButton
@onready var buy_plant_btn: Button = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/PlantCard/VBox/HBox/BuyButton
@onready var buy_server_btn: Button = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/ServerCard/VBox/HBox/BuyButton
@onready var monitor_status: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/MonitorCard/VBox/HBox/StatusLabel
@onready var chair_status: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/ChairCard/VBox/HBox/StatusLabel
@onready var plant_status: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/PlantCard/VBox/HBox/StatusLabel
@onready var server_status: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/ServerCard/VBox/HBox/StatusLabel
@onready var hw_hint_label: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/HwHintLabel
@onready var hw_grid: GridContainer = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/HwGrid

# Freelance components
@onready var lead_banner_label: Label = $Windows/FreelanceWindow/Margin/VBox/LeadBanner/LeadLabel
@onready var freelance_cards: VBoxContainer = $Windows/FreelanceWindow/Margin/VBox/FreelanceScroll/FreelanceVBox/CardsContainer
@onready var freelance_text: RichTextLabel = $Windows/FreelanceWindow/Margin/VBox/FreelanceScroll/FreelanceVBox/DetailsLabel
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
@onready var firewall_icon: Button = $DesktopIcons/Scroll/VBox/FirewallIcon

var emails: Array[Dictionary] = []
var _selected_email_cid: String = ""

func _ready() -> void:
	visible = false
	EventBus.computer_opened.connect(_on_computer_opened)
	EventBus.computer_closed.connect(_on_computer_closed)
	EventBus.funds_changed.connect(_on_funds_changed)
	EventBus.contract_updated.connect(_on_contract_updated)
	EventBus.contract_completed.connect(func(_id, _r, _rep):
		_update_freelance_display()
		_update_shop_buttons()
		_setup_emails()
		_update_rack_display()
	)
	
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Desktop icons
	$DesktopIcons/Scroll/VBox/MailIcon.pressed.connect(func(): _open_window(mail_window))
	$DesktopIcons/Scroll/VBox/FreelanceIcon.pressed.connect(func(): _open_window(freelance_window))
	$DesktopIcons/Scroll/VBox/WebForgeIcon.pressed.connect(_launch_webforge)
	$DesktopIcons/Scroll/VBox/ShopIcon.pressed.connect(func(): _open_window(shop_window))
	$DesktopIcons/Scroll/VBox/BankIcon.pressed.connect(func(): _open_window(bank_window))
	$DesktopIcons/Scroll/VBox/RackIcon.pressed.connect(func(): _open_window(rack_window))
	$DesktopIcons/Scroll/VBox/TalentIcon.pressed.connect(func(): _open_window(talent_window))
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
	EventBus.employee_hired.connect(func(_id, _n):
		_update_talent_display()
		_update_freelance_display()
	)
	EventBus.employee_fired.connect(func(_id):
		_update_talent_display()
		_update_freelance_display()
	)
	if ShopManager.has_signal("hardware_changed"):
		ShopManager.hardware_changed.connect(func():
			_update_shop_buttons()
			_update_freelance_display()
		)
	
	_setup_emails()
	_update_shop_buttons()
	_update_freelance_display()
	EventBus.time_tick.connect(func(_h, _m, _d):
		_update_top_bar()
		if visible and freelance_window.visible:
			_update_lead_banner_only()
	)
	EventBus.contract_marketplace_refreshed.connect(_update_freelance_display)

func _on_computer_opened() -> void:
	visible = true
	SoundManager.play_keyboard_sound()
	_update_top_bar()
	_setup_emails()
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
	if freelance_window.visible:
		_update_freelance_display()

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
	if target_window == freelance_window:
		_update_freelance_display()
	elif target_window == shop_window:
		_update_shop_buttons()

func _setup_emails() -> void:
	mail_list.clear()
	emails.clear()
	_selected_email_cid = ""
	
	# Mario (Pizzeria)
	emails.append({
		"from": "Mario Esposito <mario@pizzeriadamario-to.it>",
		"subject": "Richiesta Realizzazione Sito Web - Pizzeria Da Mario (Via Po)",
		"body": "Gentile Dottore,\n\nHo visto il suo annuncio su Freelance Hub Torino. Cerchiamo qualcuno che crei il nostro sito web ufficiale per attirare turisti e clienti a Torino.\n\nBudget concordato: € 650,00 netti.\n\nPassi a trovarmi direttamente di persona in bottega in Via Po 18 (esca dal suo studio e segua la via fino all'insegna luminosa).\n\nMario Esposito - Titolare",
		"contract_id": "pizzeria_da_mario"
	})
	
	# Elena (Caffè San Carlo)
	if ContractManager.is_contract_completed("pizzeria_da_mario") or ContractManager.active_contracts.has("caffe_san_carlo"):
		emails.append({
			"from": "Elena Rossi <elena@caffesancarlo.to.it>",
			"subject": "Richiesta Touch Web POS Cassa & Ordini - Caffè San Carlo",
			"body": "Gentile Sviluppatore,\n\nMario mi ha mostrato il nuovo sito web e ne sono rimasta affascinata!\nQui al Caffè San Carlo abbiamo code al bancone nelle ore di punta. Ci serve un sistema Web POS moderno per velocizzare le ordinazioni di caffè e bicerin.\n\nBudget: € 1.250,00 netti + Hosting mensile sul suo server rack!\nPassi al bancone del Caffè in Piazzetta per definire i dettagli.\n\nCordiali saluti,\nElena - Store Manager",
			"contract_id": "caffe_san_carlo"
		})
		
	# Davide (Elettronica TO)
	if ContractManager.is_contract_completed("caffe_san_carlo") or ContractManager.active_contracts.has("elettronica_to"):
		emails.append({
			"from": "Davide Ferrero <davide@elettronicato.com>",
			"subject": "Proposta Migrazione Cloud & Catalogo - Elettronica TO",
			"body": "Ciao collega,\n\nHo saputo del Web POS installato al Caffè San Carlo, lavoro eccellente!\nDa Elettronica TO dobbiamo dismettere il nostro vecchio server locale e migrare a un'architettura cloud con database ridondato e backup sul tuo server rack.\n\nBudget stanziato: € 1.850,00 netti + 20% di sconto permanente sui componenti hardware (Router Wi-Fi, Server Xeon, PC & Firewall)!\nVieni in negozio in Piazzetta per iniziare.\n\nA presto,\nDavide - Tecnico Elettronica TO",
			"contract_id": "elettronica_to"
		})

	# Officina Bellini e contratti B2B WebForge in corso o pronti per consegna
	for cid in ContractManager.active_contracts:
		if cid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to"]:
			continue
		var ac = ContractManager.active_contracts[cid]
		if ac is Dictionary and ac.get("execution_type", "webforge") == "webforge":
			var st = ac.get("status", "")
			if st == "in_progress" or st == "built":
				emails.append({
					"from": "%s <b2b@torino-clienti.it>" % str(ac.get("client", "Cliente B2B")),
					"subject": "%s%s (€ %0.2f)" % ["[PRONTA CONSEGNA] " if st == "built" else "[ATTIVO] ", str(ac.get("title", cid)), float(ac.get("budget", 0.0))],
					"body": "Commissione B2B attiva: %s\n\n%s\n\nCompenso base: € %0.2f\nStato attuale: %s\nRequisiti: %s" % [
						str(ac.get("title", cid)),
						str(ac.get("brief", ac.get("objective_text", ""))),
						float(ac.get("budget", 0.0)),
						st.to_upper(),
						", ".join(ac.get("requirements", []))
					],
					"contract_id": cid
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
		
		var cid = str(e.get("contract_id", ""))
		_selected_email_cid = cid
		if cid != "":
			var c = ContractManager.get_contract(cid)
			var status = c.get("status", "available")
			if status == "built" and not ContractManager.is_contract_completed(cid):
				deliver_project_btn.visible = true
				deliver_project_btn.text = "★ Consegna Progetto a %s (€ %0.2f)" % [c.get("client", "Cliente"), c.get("budget", 650.0)]
				return
		deliver_project_btn.visible = false

func _on_deliver_project_pressed() -> void:
	if _selected_email_cid != "":
		var sel = ContractManager.get_contract(_selected_email_cid)
		if sel.get("status") == "built":
			_complete_contract_by_id(_selected_email_cid)
			return
	for cid in ContractManager.active_contracts.keys():
		var c = ContractManager.get_contract(cid)
		if c.get("status") == "built":
			_complete_contract_by_id(cid)
			return

func _complete_contract_by_id(cid: String) -> void:
	if cid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to"]:
		ContractManager.complete_story_contract(cid)
	else:
		ContractManager.complete_marketplace_contract(cid)
	deliver_project_btn.visible = false
	_setup_emails()
	_update_freelance_display()
	_update_shop_buttons()
	_update_rack_display()

func _update_lead_banner_only() -> void:
	if not lead_banner_label:
		return
	var hw_summary := "Magazzino Hardware: Router x%d | Server x%d | PC x%d | Firewall x%d" % [
		ShopManager.get_hardware_count("hw_wifi_router"),
		ShopManager.get_hardware_count("hw_server_tower"),
		ShopManager.get_hardware_count("hw_workstation_pc"),
		ShopManager.get_hardware_count("hw_firewall_appliance")
	]
	lead_banner_label.text = "📡 %s\n📦 %s" % [ContractManager.get_lead_eta_text(), hw_summary]

func _make_hub_card(bg: Color, border: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(1)
	st.set_corner_radius_all(6)
	st.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", st)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return card

func _update_freelance_display() -> void:
	_update_lead_banner_only()
	if not freelance_cards:
		return
	for ch in freelance_cards.get_children():
		ch.queue_free()

	# 1. Grande Appalto Officina Bellini (Borgo Valdocco Est)
	var fac := ContractManager.get_factory_progress_summary()
	if fac["accepted"] or ContractManager.is_contract_completed("elettronica_to"):
		var f_card := _make_hub_card(Color(0.14, 0.17, 0.24, 1.0), Color(0.92, 0.65, 0.22, 0.85))
		var f_vbox := VBoxContainer.new()
		f_vbox.add_theme_constant_override("separation", 6)
		f_card.add_child(f_vbox)

		var f_title := Label.new()
		f_title.text = "🏭 MAXI-APPALTO: OFFICINA MECCANICA BELLINI (BORGO VALDOCCO — EST)"
		f_title.add_theme_font_size_override("font_size", 13)
		f_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
		f_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		f_vbox.add_child(f_title)

		var f_info := Label.new()
		f_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		f_info.add_theme_font_size_override("font_size", 12)
		if not fac["accepted"]:
			f_info.text = "Esci dalla piazzetta e segui la strada asfaltata verso Est fino a Borgo Valdocco. Parla con l'Ing. Bellini e perlustra la fabbrica (Wi-Fi, Sito, Server Xeon, 2 PC)!"
			f_info.add_theme_color_override("font_color", Color(0.84, 0.88, 0.94))
			f_vbox.add_child(f_info)
		elif fac["completed"]:
			f_info.text = "✔ Appalto Completato al 100%%! Wi-Fi, Sito Web, Server Xeon e 2 Workstation CAD attivi."
			f_info.add_theme_color_override("font_color", Color(0.35, 1.0, 0.58))
			f_vbox.add_child(f_info)
		else:
			var s_tag := "✔" if fac["all_scouted"] else "○"
			var w_tag := "✔" if fac["wifi_done"] else ("⚡NetShield" if fac["wifi_mounted"] else "○")
			var web_tag := "✔" if fac["web_done"] else "○"
			var srv_tag := "✔" if fac["server_done"] else "○"
			var pc_tag := "✔" if fac["pcs_done"] else "○"
			f_info.text = "Sopralluogo %s (%d/4 zone) | %s Wi-Fi Router & VLAN | %s Portale Web | %s Server Xeon | %s 2x PC CAD" % [
				s_tag, fac["scouted_count"], w_tag, web_tag, srv_tag, pc_tag
			]
			f_info.add_theme_color_override("font_color", Color(0.86, 0.92, 0.98))
			f_vbox.add_child(f_info)

			var f_actions := HFlowContainer.new()
			f_actions.add_theme_constant_override("h_separation", 8)
			f_actions.add_theme_constant_override("v_separation", 6)
			var web_c := ContractManager.get_contract("factory_bellini_web")
			var web_st := str(web_c.get("status", ""))
			if web_st == "in_progress":
				var b_wf := Button.new()
				b_wf.text = "⚡ Sito WebForge (€ 950)"
				b_wf.pressed.connect(func(): _launch_webforge_for("factory_bellini_web"))
				f_actions.add_child(b_wf)
			elif web_st == "built":
				var b_del := Button.new()
				b_del.text = "★ Consegna Sito (€ 950)"
				b_del.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
				b_del.pressed.connect(func(): _complete_contract_by_id("factory_bellini_web"))
				f_actions.add_child(b_del)
			if fac["wifi_mounted"] and not fac["wifi_done"]:
				var b_ns := Button.new()
				b_ns.text = "🛡 VLAN NetShield (€ 350)"
				b_ns.add_theme_color_override("font_color", Color(1.0, 0.72, 0.3))
				b_ns.pressed.connect(func(): _launch_netshield_for("factory_bellini_wifi"))
				f_actions.add_child(b_ns)
			if f_actions.get_child_count() > 0:
				f_vbox.add_child(f_actions)

		freelance_cards.add_child(f_card)

	# 2. Incarichi Attivi (Storia + B2B presi in carico)
	var active_ids: Array[String] = []
	for cid in ContractManager.active_contracts.keys():
		if cid == "factory_bellini_web":
			continue
		var st := str(ContractManager.active_contracts[cid].get("status", ""))
		if st == "in_progress" or st == "built":
			active_ids.append(cid)

	if not active_ids.is_empty():
		var act_hdr := Label.new()
		act_hdr.text = "🔧 INCARICHI IN LAVORAZIONE:"
		act_hdr.add_theme_font_size_override("font_size", 13)
		act_hdr.add_theme_color_override("font_color", Color(0.4, 0.92, 1.0))
		freelance_cards.add_child(act_hdr)

		for cid in active_ids:
			var c: Dictionary = ContractManager.active_contracts[cid]
			var st := str(c.get("status", "in_progress"))
			var etype := str(c.get("execution_type", "webforge"))
			var card := _make_hub_card(Color(0.15, 0.20, 0.28, 1.0), Color(0.30, 0.72, 0.95, 0.85))
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", 6)
			card.add_child(v)

			var ttl := Label.new()
			ttl.text = "%s — %s (€ %0.2f · +%d Rep)" % [str(c.get("title", cid)), str(c.get("client", "")), float(c.get("budget", 0.0)), int(c.get("reputation_reward", 10))]
			ttl.add_theme_font_size_override("font_size", 13)
			ttl.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
			ttl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(ttl)

			var req := Label.new()
			req.text = "%s | Requisiti: %s" % [str(c.get("category", "B2B")), ", ".join(c.get("requirements", []))]
			req.add_theme_font_size_override("font_size", 11)
			req.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90))
			req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(req)

			var row := HFlowContainer.new()
			row.add_theme_constant_override("h_separation", 8)
			row.add_theme_constant_override("v_separation", 6)
			if st == "built":
				var d_btn := Button.new()
				d_btn.text = "★ Consegna & Incassa (€ %0.2f)" % float(c.get("budget", 0.0))
				d_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
				var cid_copy := cid
				d_btn.pressed.connect(func(): _complete_contract_by_id(cid_copy))
				row.add_child(d_btn)
			elif etype == "netshield":
				var ns_btn := Button.new()
				ns_btn.text = "🛡 Configura su NetShield Cyber"
				ns_btn.add_theme_color_override("font_color", Color(1.0, 0.72, 0.30))
				var cid_copy := cid
				ns_btn.pressed.connect(func(): _launch_netshield_for(cid_copy))
				row.add_child(ns_btn)
			elif etype == "hardware":
				var req_hw: Dictionary = c.get("required_hardware", {})
				var parts: Array[String] = []
				var all_ok := true
				for hw_id in req_hw:
					var need := int(req_hw[hw_id])
					var have := ShopManager.get_hardware_count(str(hw_id))
					if have < need:
						all_ok = false
					parts.append("%s: %d/%d" % [ShopManager.get_hardware_item_name(str(hw_id)), have, need])
				var hw_lbl := Label.new()
				hw_lbl.custom_minimum_size = Vector2(220, 0)
				hw_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hw_lbl.text = "Stock: " + ", ".join(parts)
				hw_lbl.add_theme_font_size_override("font_size", 11)
				hw_lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.65) if all_ok else Color(1.0, 0.78, 0.35))
				hw_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				row.add_child(hw_lbl)

				var hw_btn := Button.new()
				hw_btn.text = "📦 Installa & Consegna" if all_ok else "🛒 Compra Hardware"
				var cid_copy := cid
				if all_ok:
					hw_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
					hw_btn.pressed.connect(func():
						ContractManager.deliver_hardware_contract(cid_copy)
						_update_freelance_display()
					)
				else:
					hw_btn.pressed.connect(func(): _open_window(shop_window))
				row.add_child(hw_btn)
			else:
				var wf_btn := Button.new()
				wf_btn.text = "⚡ Sviluppa su WebForge"
				wf_btn.add_theme_color_override("font_color", Color(0.40, 0.92, 1.0))
				var cid_copy := cid
				wf_btn.pressed.connect(func(): _launch_webforge_for(cid_copy))
				row.add_child(wf_btn)

			v.add_child(row)
			freelance_cards.add_child(card)

	# 3. Offerte B2B Disponibili su Freelance Hub
	var mkt_hdr := Label.new()
	mkt_hdr.text = "💼 MARKETPLACE FREELANCE TORINO (%d OFFERTE APERTE):" % ContractManager.marketplace_contracts.size()
	mkt_hdr.add_theme_font_size_override("font_size", 13)
	mkt_hdr.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))
	freelance_cards.add_child(mkt_hdr)

	if ContractManager.marketplace_contracts.is_empty():
		var empty_card := _make_hub_card(Color(0.14, 0.16, 0.21, 0.9), Color(0.28, 0.34, 0.45, 0.7))
		var empty_lbl := Label.new()
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.88))
		if not ContractManager.is_contract_completed("pizzeria_da_mario"):
			empty_lbl.text = "Consegna prima il sito alla Pizzeria Da Mario: i primi clienti B2B arriveranno dopo la tua prima referenza nel borgo!"
		else:
			empty_lbl.text = "Nessuna nuova richiesta in questo istante. %s" % ContractManager.get_lead_eta_text()
		empty_card.add_child(empty_lbl)
		freelance_cards.add_child(empty_card)
	else:
		for c in ContractManager.marketplace_contracts:
			var cid := str(c["id"])
			var etype := str(c.get("execution_type", "webforge"))
			var badge_col := Color(0.35, 0.88, 1.0)
			var type_tag := "WEBFORGE"
			if etype == "netshield":
				badge_col = Color(1.0, 0.68, 0.25)
				type_tag = "NETSHIELD CYBER"
			elif etype == "hardware":
				badge_col = Color(0.55, 1.0, 0.58)
				type_tag = "HARDWARE B2B"

			var m_card := _make_hub_card(Color(0.16, 0.19, 0.26, 1.0), badge_col * Color(1, 1, 1, 0.7))
			var mv := VBoxContainer.new()
			mv.add_theme_constant_override("separation", 5)
			m_card.add_child(mv)

			var top_row := HBoxContainer.new()
			top_row.add_theme_constant_override("separation", 8)
			var title_lbl := Label.new()
			title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			title_lbl.text = "[%s] %s — %s" % [type_tag, str(c["title"]), str(c["client"])]
			title_lbl.add_theme_font_size_override("font_size", 13)
			title_lbl.add_theme_color_override("font_color", badge_col)
			title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			top_row.add_child(title_lbl)

			var accept_btn := Button.new()
			accept_btn.custom_minimum_size = Vector2(145, 32)
			accept_btn.text = "✓ Accetta (€ %0.0f)" % float(c["budget"])
			accept_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.58))
			accept_btn.pressed.connect(func():
				SoundManager.play_ui_click()
				ContractManager.accept_marketplace_contract(cid)
				_update_freelance_display()
			)
			top_row.add_child(accept_btn)
			mv.add_child(top_row)

			var meta_lbl := Label.new()
			meta_lbl.text = "Settore: %s | Compenso: € %0.2f (+%d Rep) | Scadenza: %d gg | Difficoltà: %s\nRequisiti: %s" % [
				str(c.get("category", "B2B")),
				float(c.get("budget", 0.0)),
				int(c.get("reputation_reward", 10)),
				int(c.get("deadline_days", 3)),
				"★".repeat(int(c.get("difficulty", 1))),
				", ".join(c.get("requirements", []))
			]
			meta_lbl.add_theme_font_size_override("font_size", 11)
			meta_lbl.add_theme_color_override("font_color", Color(0.80, 0.85, 0.92))
			meta_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			mv.add_child(meta_lbl)

			freelance_cards.add_child(m_card)

	# 4. Riepilogo Missioni Storia San Carlo
	var story_hdr := Label.new()
	story_hdr.text = "📜 COMMISSIONI QUARTIERE BORGO SAN CARLO:"
	story_hdr.add_theme_font_size_override("font_size", 12)
	story_hdr.add_theme_color_override("font_color", Color(0.75, 0.82, 0.92))
	freelance_cards.add_child(story_hdr)

	for scid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to"]:
		var sc = ContractManager.get_contract(scid)
		if sc.is_empty():
			continue
		var sst = str(sc.get("status", "available"))
		var s_lbl := Label.new()
		s_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s_lbl.add_theme_font_size_override("font_size", 11)
		s_lbl.text = "• %s (%s) — € %0.2f [%s] — %s" % [sc.get("title", ""), sc.get("client", ""), float(sc.get("budget", 0.0)), sst.to_upper(), sc.get("objective_text", "")]
		s_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65) if sst == "completed" else Color(0.78, 0.82, 0.88))
		freelance_cards.add_child(s_lbl)

	# Pulsante veloce footer WebForge visibile solo se c'è un contratto webforge in lavorazione
	var has_wf := false
	for ac in ContractManager.active_contracts.values():
		if ac.get("status") == "in_progress" and ac.get("execution_type", "webforge") == "webforge":
			has_wf = true
			break
	open_webforge_btn.visible = has_wf
	if has_wf:
		open_webforge_btn.text = "⚡ Apri WebForge IDE (Sviluppa Sito Selezionato)"

	# Mantiene freelance_text popolato per retrocompatibilità
	if freelance_text:
		freelance_text.text = ContractManager.get_lead_eta_text()

func _launch_webforge() -> void:
	var has_active = false
	for c in ContractManager.active_contracts.values():
		if c.get("status") == "in_progress" and c.get("execution_type", "webforge") == "webforge":
			has_active = true
			break
	if not has_active:
		SoundManager.play_ui_click()
		EventBus.notification_posted.emit(
			"WebForge Inattivo",
			"Nessun sito web in lavorazione! Accetta un lavoro su Freelance Hub o parla con i clienti nel Borgo.",
			"warning"
		)
		return
	SoundManager.play_ui_click()
	EventBus.minigame_started.emit("web_forge")

func _launch_webforge_for(cid: String) -> void:
	ContractManager.preferred_webforge_contract_id = cid
	SoundManager.play_ui_click()
	EventBus.minigame_started.emit("web_forge")

func _launch_netshield_for(cid: String) -> void:
	ContractManager.preferred_netshield_contract_id = cid
	SoundManager.play_ui_click()
	EventBus.minigame_started.emit("firewall_router")

func _update_shop_buttons() -> void:
	var has_monitor = "monitor_upgrade" in GameManager.studio_upgrades_installed
	var has_chair = "chair_gaming_upgrade" in GameManager.studio_upgrades_installed
	var has_plant = "plant_aloe" in GameManager.studio_upgrades_installed or "plant_aloe_upgrade" in GameManager.studio_upgrades_installed
	var has_server = "server_rack_upgrade" in GameManager.studio_upgrades_installed
	var col_ok := Color(0.27, 1.0, 0.53)
	var col_avail := Color(0.75, 0.78, 0.85)
	
	if has_monitor:
		buy_monitor_btn.disabled = true
		buy_monitor_btn.text = "GIÀ INSTALLATO"
		monitor_status.text = "Installato sulla scrivania"
		monitor_status.add_theme_color_override("font_color", col_ok)
	else:
		buy_monitor_btn.disabled = not EconomyManager.can_afford(350.0)
		buy_monitor_btn.text = "Acquista (€ 350,00)"
		monitor_status.text = "Disponibile"
		monitor_status.add_theme_color_override("font_color", col_avail)
		
	if has_chair:
		buy_chair_btn.disabled = true
		buy_chair_btn.text = "GIÀ INSTALLATA"
		chair_status.text = "Installata alla postazione"
		chair_status.add_theme_color_override("font_color", col_ok)
	else:
		buy_chair_btn.disabled = not EconomyManager.can_afford(220.0)
		buy_chair_btn.text = "Acquista (€ 220,00)"
		chair_status.text = "Disponibile"
		chair_status.add_theme_color_override("font_color", col_avail)

	if has_plant:
		buy_plant_btn.disabled = true
		buy_plant_btn.text = "GIÀ POSIZIONATA"
		plant_status.text = "Posizionata in studio"
		plant_status.add_theme_color_override("font_color", col_ok)
	else:
		buy_plant_btn.disabled = not EconomyManager.can_afford(35.0)
		buy_plant_btn.text = "Acquista (€ 35,00)"
		plant_status.text = "Disponibile"
		plant_status.add_theme_color_override("font_color", col_avail)

	if has_server:
		buy_server_btn.disabled = true
		buy_server_btn.text = "GIÀ INSTALLATO"
		server_status.text = "Attivo (Hosting ON)"
		server_status.add_theme_color_override("font_color", col_ok)
	else:
		buy_server_btn.disabled = not EconomyManager.can_afford(450.0)
		buy_server_btn.text = "Acquista (€ 450,00)"
		server_status.text = "Disponibile"
		server_status.add_theme_color_override("font_color", col_avail)

	_rebuild_client_hardware_shop()

func _rebuild_client_hardware_shop() -> void:
	if not hw_grid:
		return
	for ch in hw_grid.get_children():
		ch.queue_free()

	if hw_hint_label:
		var partner := ContractManager.is_contract_completed("elettronica_to")
		var fame_disc := FameManager.get_discount_percent()
		var disc_str := "Sconto Partner Davide (-20%) ATTIVO!" if partner else "Completa Elettronica TO per -20% sconto fisso."
		if fame_disc > 0:
			disc_str += " | Bonus Fame: -%d%%" % fame_disc
		hw_hint_label.text = "%s | Totale pezzi in magazzino: %d" % [disc_str, ShopManager.get_hardware_count()]

	var items := ShopManager.get_items("elettronica_componenti")
	for it in items:
		var hw_id := str(it["id"])
		var base_p := ShopManager.get_base_price("elettronica_componenti", hw_id)
		var price := ShopManager.get_price("elettronica_componenti", hw_id)
		var stock := ShopManager.get_hardware_count(hw_id)

		var card := _make_hub_card(Color(0.17, 0.20, 0.27, 1.0), Color(0.32, 0.45, 0.65, 0.75))
		card.custom_minimum_size = Vector2(235, 138)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		card.add_child(v)

		var n_lbl := Label.new()
		n_lbl.text = str(it["name"])
		n_lbl.add_theme_font_size_override("font_size", 14)
		n_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
		n_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(n_lbl)

		var p_lbl := Label.new()
		if price < base_p:
			p_lbl.text = "€ %0.2f (Listino € %0.2f)" % [price, base_p]
		else:
			p_lbl.text = "€ %0.2f" % price
		p_lbl.add_theme_font_size_override("font_size", 13)
		p_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.60))
		v.add_child(p_lbl)

		var d_lbl := Label.new()
		d_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		d_lbl.text = str(it.get("desc", ""))
		d_lbl.add_theme_font_size_override("font_size", 11)
		d_lbl.add_theme_color_override("font_color", Color(0.76, 0.82, 0.88))
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(d_lbl)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		var st_lbl := Label.new()
		st_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		st_lbl.text = "Stock: x%d" % stock
		st_lbl.clip_text = true
		st_lbl.add_theme_font_size_override("font_size", 12)
		st_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.60) if stock > 0 else Color(0.75, 0.78, 0.85))
		hbox.add_child(st_lbl)

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(115, 32)
		buy_btn.text = "Ordina (€ %0.0f)" % price
		buy_btn.disabled = not EconomyManager.can_afford(price)
		buy_btn.pressed.connect(func():
			if ShopManager.buy_hardware(hw_id, 1):
				_update_shop_buttons()
				_update_freelance_display()
		)
		hbox.add_child(buy_btn)
		v.add_child(hbox)
		hw_grid.add_child(card)

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
	
	var max_slots: int = GameManager.get_max_employee_slots() if GameManager.has_method("get_max_employee_slots") else 1
	var tier_name: String = GameManager.get_company_tier_name() if GameManager.has_method("get_company_tier_name") else "Sede Aziendale"
	talent_stats_label.text = "🏢 Sede: %s (Scrivanie: %d/%d) | 👥 Team: %d | Buste Paga: € %0.2f/g | Ricavi: +€ %0.2f/g | Netto: +€ %0.2f/g" % [
		tier_name, hired.size(), max_slots, hired.size(), payroll, revenue, net
	]
	
	# Clear previous candidates
	for child in candidates_list.get_children():
		child.queue_free()
		
	# Company Expansion Section (if not at max tier)
	if GameManager.company_tier < 4:
		var exp_check: Dictionary = GameManager.can_upgrade_company_tier()
		var target_tier: int = GameManager.company_tier + 1
		var target_name: String = GameManager.get_company_tier_name(target_tier)
		
		var exp_card = PanelContainer.new()
		var exp_style = StyleBoxFlat.new()
		exp_style.bg_color = Color(0.14, 0.18, 0.26, 1)
		exp_style.border_color = Color(0.35, 0.55, 0.85, 0.8)
		exp_style.set_border_width_all(1)
		exp_style.set_content_margin_all(12)
		exp_style.set_corner_radius_all(6)
		exp_card.add_theme_stylebox_override("panel", exp_style)
		
		var exp_hbox = HBoxContainer.new()
		exp_hbox.add_theme_constant_override("separation", 16)
		
		var exp_vbox = VBoxContainer.new()
		exp_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
		
		var exp_title = Label.new()
		exp_title.text = "🏢 Espansione Sede: %s (Livello %d)" % [target_name, target_tier]
		exp_title.add_theme_font_size_override("font_size", 15)
		exp_title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35, 1))
		exp_vbox.add_child(exp_title)
		
		var exp_desc = Label.new()
		var target_slots: int = 1 if target_tier == 2 else (3 if target_tier == 3 else 6)
		exp_desc.text = "Espandi l'ufficio per ospitare fino a %d dipendenti e sbloccare nuove opportunità commerciali a Torino." % target_slots
		exp_desc.add_theme_font_size_override("font_size", 12)
		exp_desc.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85, 1))
		exp_vbox.add_child(exp_desc)
		
		var exp_req = Label.new()
		var cost_val = exp_check.get("cost", 0.0)
		exp_req.text = "Costo Espansione: € %0.2f | Reputazione Richiesta: %s" % [cost_val, "50" if target_tier == 2 else ("120" if target_tier == 3 else "250")]
		exp_req.add_theme_font_size_override("font_size", 11)
		exp_req.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6, 1))
		exp_vbox.add_child(exp_req)
		
		if not exp_check.get("allowed", false):
			var exp_blocked_lbl = Label.new()
			exp_blocked_lbl.text = "🔒 " + str(exp_check.get("reason", "Requisiti non soddisfatti"))
			exp_blocked_lbl.add_theme_font_size_override("font_size", 11)
			exp_blocked_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1))
			exp_blocked_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			exp_vbox.add_child(exp_blocked_lbl)
			
		exp_hbox.add_child(exp_vbox)
		
		var exp_btn = Button.new()
		exp_btn.custom_minimum_size = Vector2(160, 42)
		exp_btn.size_flags_vertical = SIZE_SHRINK_CENTER
		exp_btn.text = "Espandi Sede (€ %0.2f)" % cost_val
		exp_btn.disabled = not exp_check.get("allowed", false)
		if exp_check.get("allowed", false):
			exp_btn.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
		exp_btn.pressed.connect(func():
			if GameManager.upgrade_company_tier():
				_update_talent_display()
		)
		exp_hbox.add_child(exp_btn)
		exp_card.add_child(exp_hbox)
		candidates_list.add_child(exp_card)
		
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
			var hire_check: Dictionary = EmployeeManager.can_hire_employee(cand["id"])
			var can_hire: bool = hire_check.get("allowed", false)
			action_btn.text = "Assumi (€ %0.2f)" % cand["daily_salary"]
			action_btn.disabled = not can_hire
			if can_hire:
				action_btn.add_theme_color_override("font_color", Color(0.3, 1, 0.6, 1))
			else:
				action_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
				var block_lbl = Label.new()
				block_lbl.text = "🔒 " + str(hire_check.get("reason", "Assunzione non consentita"))
				block_lbl.add_theme_font_size_override("font_size", 11)
				block_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1))
				block_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				vbox.add_child(block_lbl)
				
			var cid = cand["id"]
			action_btn.pressed.connect(func(): EmployeeManager.hire_employee(cid); _update_talent_display())
			
		hbox.add_child(vbox)
		hbox.add_child(action_btn)
		card.add_child(hbox)
		candidates_list.add_child(card)

func _render_talent_hub() -> void:
	_update_talent_display()
