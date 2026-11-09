extends Control
## WebForgeController - Interactive visual website builder and software compiler minigame

@onready var ide_label: Label = $Main/Header/HBox/IDELabel
@onready var quality_progress: ProgressBar = $Main/Header/HBox/QualityProgress
@onready var quality_label: Label = $Main/Header/HBox/QualityLabel
@onready var preview_scroll: ScrollContainer = $Main/Body/PreviewArea/Scroll
@onready var preview_vbox: VBoxContainer = $Main/Body/PreviewArea/Scroll/VBox
@onready var compile_btn: Button = $Main/Footer/CompileButton
@onready var exit_btn: Button = $Main/Header/HBox/ExitButton

# Palette
@onready var palette_title: Label = $Main/Body/Palette/VBox/PaletteTitle
@onready var chk_header: CheckButton = $Main/Body/Palette/VBox/ChkHeader
@onready var chk_hero: CheckButton = $Main/Body/Palette/VBox/ChkHero
@onready var chk_menu: CheckButton = $Main/Body/Palette/VBox/ChkMenu
@onready var chk_hours: CheckButton = $Main/Body/Palette/VBox/ChkHours
@onready var chk_booking: CheckButton = $Main/Body/Palette/VBox/ChkBooking
@onready var theme_picker: OptionButton = $Main/Body/Palette/VBox/ThemePicker

var current_theme_color: Color = Color(0.85, 0.25, 0.2, 1)
var active_contract_id: String = "pizzeria_da_mario"

func _ready() -> void:
	visible = false
	EventBus.minigame_started.connect(_on_minigame_started)
	
	exit_btn.pressed.connect(_on_exit_pressed)
	compile_btn.pressed.connect(_on_compile_pressed)
	
	chk_header.toggled.connect(func(_b): _on_component_toggled())
	chk_hero.toggled.connect(func(_b): _on_component_toggled())
	chk_menu.toggled.connect(func(_b): _on_component_toggled())
	chk_hours.toggled.connect(func(_b): _on_component_toggled())
	chk_booking.toggled.connect(func(_b): _on_component_toggled())
	
	theme_picker.item_selected.connect(_on_theme_selected)
	_update_website_preview()

func _on_minigame_started(type: String) -> void:
	if type == "web_forge":
		# Identify which contract is actively in_progress
		active_contract_id = ""
		for cid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to"]:
			var c = ContractManager.get_contract(cid)
			if c.get("status") == "in_progress":
				active_contract_id = cid
				break
				
		if active_contract_id == "":
			# Check marketplace
			for c in ContractManager.active_contracts.values():
				if c.get("status") == "in_progress":
					active_contract_id = c.get("id")
					break
					
		if active_contract_id == "":
			visible = false
			EventBus.notification_posted.emit(
				"WebForge Bloccato",
				"Nessun contratto in lavorazione! Recati dai clienti in Via Po per accettare un progetto.",
				"warning"
			)
			return
			
		var contract = ContractManager.get_contract(active_contract_id)
		visible = true
		ide_label.text = "⚡ WebForge IDE — Progetto: %s (Budget: € %0.2f)" % [contract.get("title", "Progetto"), contract.get("budget", 650.0)]
		_setup_palette_for_active_contract()
		_update_website_preview()

func _setup_palette_for_active_contract() -> void:
	match active_contract_id:
		"pizzeria_da_mario":
			palette_title.text = "REQUISITI: PIZZERIA DA MARIO"
			chk_header.text = "1. Logo Mole Antonelliana"
			chk_hero.text = "2. Hero Banner Tradizione"
			chk_menu.text = "3. Menu Pizze Veraci"
			chk_hours.text = "4. Orari & Sede Via Po"
			chk_booking.text = "5. Prenotazione Tavoli Online"
		"caffe_san_carlo":
			palette_title.text = "REQUISITI: TOUCH POS CAFFÈ SAN CARLO"
			chk_header.text = "1. Header Cassa & Operatore Elena"
			chk_hero.text = "2. Griglia Touchscreen Veloce"
			chk_menu.text = "3. Listino Espresso, Bicerin & Dolci"
			chk_hours.text = "4. Gestione Tavoli Esterni"
			chk_booking.text = "5. POS Pagamenti Contactless"
		"elettronica_to":
			palette_title.text = "REQUISITI: CLOUD BACKEND ELETTRONICA TO"
			chk_header.text = "1. API Gateway & Load Balancer"
			chk_hero.text = "2. Catalogo Hardware & Server Blade"
			chk_menu.text = "3. Cluster Database Postgre/Redis"
			chk_hours.text = "4. Backup Notturno su Server Rack"
			chk_booking.text = "5. Firewall TLS & Token Auth"
		_:
			palette_title.text = "COMPONENTI SOFTWARE B2B"
			chk_header.text = "1. Modulo Architettura Base"
			chk_hero.text = "2. Interfaccia Grafica Utente"
			chk_menu.text = "3. Logica di Business & API"
			chk_hours.text = "4. Database & Storage Locale"
			chk_booking.text = "5. Test Suite & Integrazione"

func _on_exit_pressed() -> void:
	visible = false
	EventBus.computer_opened.emit()

func _on_theme_selected(index: int) -> void:
	match index:
		0: current_theme_color = Color(0.85, 0.25, 0.2, 1)  # Rosso Tradizionale / Brand 1
		1: current_theme_color = Color(0.15, 0.65, 0.35, 1) # Verde Basilico / Emerald
		2: current_theme_color = Color(0.20, 0.55, 0.85, 1) # Blue Tech Sabaudo
	SoundManager.play_ui_click()
	_update_website_preview()

func _on_component_toggled() -> void:
	SoundManager.play_ui_click()
	_update_website_preview()

func _update_website_preview() -> void:
	for child in preview_vbox.get_children():
		child.queue_free()
		
	var contract = ContractManager.get_contract(active_contract_id)
	
	# Browser Bar URL simulation
	var url_bar = PanelContainer.new()
	var url_style = StyleBoxFlat.new()
	url_style.bg_color = Color(0.18, 0.2, 0.26, 1)
	url_style.set_content_margin_all(8)
	url_style.set_corner_radius_all(4)
	url_bar.add_theme_stylebox_override("panel", url_style)
	var url_lbl = Label.new()
	
	var domain_text = "https://localhost:8080/build"
	match active_contract_id:
		"pizzeria_da_mario": domain_text = "🔒 https://www.pizzeriadamario-torino.it [Preview]"
		"caffe_san_carlo": domain_text = "🔒 https://pos.caffesancarlo.to.it [Touch Screen Preview]"
		"elettronica_to": domain_text = "🔒 https://api.elettronicato.com/v1/cluster [Cloud Health 200 OK]"
		
	url_lbl.text = domain_text
	url_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 1))
	url_lbl.add_theme_font_size_override("font_size", 12)
	url_bar.add_child(url_lbl)
	preview_vbox.add_child(url_bar)

	var active_count = 0
	
	# 1. Header
	if chk_header.button_pressed:
		active_count += 1
		var header_panel = PanelContainer.new()
		var h_style = StyleBoxFlat.new()
		h_style.bg_color = current_theme_color
		h_style.set_content_margin_all(14)
		h_style.set_corner_radius_all(6)
		header_panel.add_theme_stylebox_override("panel", h_style)
		var h_lbl = Label.new()
		match active_contract_id:
			"pizzeria_da_mario": h_lbl.text = "🏛 PIZZERIA DA MARIO - TORINO 🏛"
			"caffe_san_carlo": h_lbl.text = "☕ CAFFÈ SAN CARLO — WEB POS CASSA [Operatore: Elena]"
			"elettronica_to": h_lbl.text = "⚡ ELETTRONICA TO — CLUSTER CLOUD INFRASTRUCTURE"
			_: h_lbl.text = "❖ " + contract.get("title", "Software B2B")
		h_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h_lbl.add_theme_font_size_override("font_size", 18)
		header_panel.add_child(h_lbl)
		preview_vbox.add_child(header_panel)
		
	# 2. Hero Banner
	if chk_hero.button_pressed:
		active_count += 1
		var hero_panel = PanelContainer.new()
		var hero_style = StyleBoxFlat.new()
		hero_style.bg_color = Color(0.12, 0.14, 0.18, 1)
		hero_style.set_content_margin_all(16)
		hero_panel.add_theme_stylebox_override("panel", hero_style)
		var hero_lbl = Label.new()
		match active_contract_id:
			"pizzeria_da_mario": hero_lbl.text = "«La vera pizza napoletana con il cuore sabaudo, cotta nel nostro forno a legna dal 1994»"
			"caffe_san_carlo": hero_lbl.text = "⚡ Modalità Servizio Rapido: Ordini Banco & Tavoli Dehors Via Po in tempo reale."
			"elettronica_to": hero_lbl.text = "☁ Cluster Multi-Region: 99.99% SLA Uptime garantito con backup notturno su Server Rack."
			_: hero_lbl.text = "Piattaforma Enterprise performante e scalabile."
		hero_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hero_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hero_panel.add_child(hero_lbl)
		preview_vbox.add_child(hero_panel)
		
	# 3. Main Catalog / Menu / Service
	if chk_menu.button_pressed:
		active_count += 1
		var menu_panel = PanelContainer.new()
		var m_style = StyleBoxFlat.new()
		m_style.bg_color = Color(0.16, 0.18, 0.24, 1)
		m_style.set_content_margin_all(14)
		menu_panel.add_theme_stylebox_override("panel", m_style)
		var m_text = RichTextLabel.new()
		m_text.bbcode_enabled = true
		m_text.fit_content = true
		match active_contract_id:
			"pizzeria_da_mario":
				m_text.text = "[center][b][color=#ffcc44]LE NOSTRE SPECIALITÀ[/color][/b][/center]\n\n• [b]Margherita Verace:[/b] Bufala DOP, San Marzano - € 7,50\n• [b]Diavola del Po:[/b] Salame piccante, Fiordilatte - € 9,00\n• [b]Piemontese DOC:[/b] Crema di tartufo, Salsiccia di Bra - € 12,00"
			"caffe_san_carlo":
				m_text.text = "[center][b][color=#ffcc44]LISTINO TOUCH BANCO[/color][/b][/center]\n\n• [b]Espresso Miscela Torino:[/b] € 1,30 | [b]Bicerin Tradizionale:[/b] € 4,50\n• [b]Croissant Pistacchio & Crema:[/b] € 2,00 | [b]Aperitivo con Tramezzini:[/b] € 9,00"
			"elettronica_to":
				m_text.text = "[center][b][color=#44ffbb]SERVICES & DB REPLICATION[/color][/b][/center]\n\n• [b]PostgreSQL Master-Replica:[/b] Active (Sync latency < 2ms)\n• [b]Redis Cache Layer:[/b] 64GB Allocated | Hit ratio: 98.4%\n• [b]Catalog Inventory API:[/b] 1,450 SKU sincronizzati"
			_:
				m_text.text = "[center]Moduli applicativi caricati con successo.[/center]"
		menu_panel.add_child(m_text)
		preview_vbox.add_child(menu_panel)
		
	# 4. Operations / Storage
	if chk_hours.button_pressed:
		active_count += 1
		var op_panel = PanelContainer.new()
		var op_style = StyleBoxFlat.new()
		op_style.bg_color = Color(0.12, 0.15, 0.20, 1)
		op_style.set_content_margin_all(12)
		op_panel.add_theme_stylebox_override("panel", op_style)
		var op_text = RichTextLabel.new()
		op_text.bbcode_enabled = true
		op_text.fit_content = true
		match active_contract_id:
			"pizzeria_da_mario":
				op_text.text = "[center]📍 Via Po 18, Torino | 📞 011 555 4321 | Martedì-Domenica 12-15 / 19-23:30[/center]"
			"caffe_san_carlo":
				op_text.text = "[center]📍 Piazza San Carlo / Via Po 12 | 14 Tavoli Interni + 8 Tavoli Portici Dehors[/center]"
			"elettronica_to":
				op_text.text = "[center]💾 Backup Automatico: Mirroring SAN su Mini Rack 19\" dello studio ogni notte alle 03:00[/center]"
			_:
				op_text.text = "[center]Configurazione di rete verificata.[/center]"
		op_panel.add_child(op_text)
		preview_vbox.add_child(op_panel)
		
	# 5. CTA Button / Action
	if chk_booking.button_pressed:
		active_count += 1
		var btn_panel = PanelContainer.new()
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = current_theme_color
		b_style.set_content_margin_all(12)
		btn_panel.add_theme_stylebox_override("panel", b_style)
		var cta = Button.new()
		match active_contract_id:
			"pizzeria_da_mario": cta.text = "➔ PRENOTA UN TAVOLO O ORDINA ASPORTO ONLINE"
			"caffe_san_carlo": cta.text = "➔ SALDA CONTO & STAMPA SCONTRINO FISCALE"
			"elettronica_to": cta.text = "➔ DEPLOY CONTAINER PRODUCTION & VERIFICA TLS"
			_: cta.text = "➔ ESEGUI BUILD DEFINITIVA"
		cta.add_theme_font_size_override("font_size", 15)
		btn_panel.add_child(cta)
		preview_vbox.add_child(btn_panel)
		
	# Quality
	var quality_percent = float(active_count) / 5.0 * 100.0
	quality_progress.value = quality_percent
	quality_label.text = "Completezza Requisiti: %d%% (%d / 5 Componenti)" % [int(quality_percent), active_count]
	
	if active_count == 5:
		compile_btn.disabled = false
		compile_btn.text = "✔ Compila Release Finale per %s (€ %0.2f)" % [contract.get("client", "Cliente"), contract.get("budget", 650.0)]
	else:
		compile_btn.disabled = true
		compile_btn.text = "Inserisci tutti i 5 requisiti richiesti dal cliente (%d/5)" % active_count

func _on_compile_pressed() -> void:
	SoundManager.play_ui_success()
	var result_data = {
		"theme": current_theme_color.to_html(),
		"quality": 100.0,
		"components": ["header", "hero", "menu", "hours", "booking"]
	}
	ContractManager.mark_contract_built(active_contract_id, result_data)
	visible = false
	EventBus.minigame_completed.emit(100.0, result_data)
