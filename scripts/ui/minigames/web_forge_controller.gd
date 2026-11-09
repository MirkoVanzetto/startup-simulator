extends Control
## WebForgeController - Milestone 4 & 5: Interactive website builder and software compiler minigame.
## Features modular architecture selection, active requirement toggles, timed compilation with upgrade boosts,
## and terminal log streaming.

@onready var ide_label: Label = $Main/Header/HBox/IDELabel
@onready var quality_progress: ProgressBar = $Main/Header/HBox/QualityProgress
@onready var quality_label: Label = $Main/Header/HBox/QualityLabel
@onready var exit_btn: Button = $Main/Header/HBox/ExitButton

# Palette Controls
@onready var palette_title: Label = $Main/Body/Palette/PaletteScroll/VBox/PaletteTitle
@onready var framework_picker: OptionButton = $Main/Body/Palette/PaletteScroll/VBox/FrameworkPicker
@onready var theme_picker: OptionButton = $Main/Body/Palette/PaletteScroll/VBox/ThemePicker
@onready var chk_header: CheckButton = $Main/Body/Palette/PaletteScroll/VBox/ChkHeader
@onready var chk_hero: CheckButton = $Main/Body/Palette/PaletteScroll/VBox/ChkHero
@onready var chk_menu: CheckButton = $Main/Body/Palette/PaletteScroll/VBox/ChkMenu
@onready var chk_hours: CheckButton = $Main/Body/Palette/PaletteScroll/VBox/ChkHours
@onready var chk_booking: CheckButton = $Main/Body/Palette/PaletteScroll/VBox/ChkBooking
@onready var chk_opt: CheckButton = $Main/Body/Palette/PaletteScroll/VBox/ChkOpt
@onready var compile_btn: Button = $Main/Body/Palette/PaletteScroll/VBox/CompileButton

# Workspace Controls
@onready var tab_preview_btn: Button = $Main/Body/RightWorkspace/WorkspaceTabBar/TabPreviewBtn
@onready var tab_terminal_btn: Button = $Main/Body/RightWorkspace/WorkspaceTabBar/TabTerminalBtn
@onready var build_speed_info: Label = $Main/Body/RightWorkspace/WorkspaceTabBar/BuildSpeedInfo
@onready var preview_area: PanelContainer = $Main/Body/RightWorkspace/PreviewArea
@onready var preview_vbox: VBoxContainer = $Main/Body/RightWorkspace/PreviewArea/Scroll/VBox
@onready var terminal_area: PanelContainer = $Main/Body/RightWorkspace/TerminalArea
@onready var terminal_progress: ProgressBar = $Main/Body/RightWorkspace/TerminalArea/VBox/TerminalProgress
@onready var terminal_logs: RichTextLabel = $Main/Body/RightWorkspace/TerminalArea/VBox/TerminalLogs

# Footer Controls
@onready var status_label: Label = $Main/Footer/HBox/StatusLabel
@onready var deliver_btn: Button = $Main/Footer/HBox/DeliverButton

var current_theme_color: Color = Color(0.85, 0.25, 0.2, 1)
var active_contract_id: String = "pizzeria_da_mario"
var is_compiling: bool = false
var compile_elapsed: float = 0.0
var compile_target_duration: float = 6.0
var compile_step: int = 0
var is_build_completed: bool = false

func _ready() -> void:
	visible = false
	EventBus.minigame_started.connect(_on_minigame_started)
	
	exit_btn.pressed.connect(_on_exit_pressed)
	compile_btn.pressed.connect(_on_compile_pressed)
	deliver_btn.pressed.connect(_on_deliver_pressed)
	
	tab_preview_btn.pressed.connect(func(): _switch_tab(true))
	tab_terminal_btn.pressed.connect(func(): _switch_tab(false))
	
	chk_header.toggled.connect(func(_b): _on_component_toggled())
	chk_hero.toggled.connect(func(_b): _on_component_toggled())
	chk_menu.toggled.connect(func(_b): _on_component_toggled())
	chk_hours.toggled.connect(func(_b): _on_component_toggled())
	chk_booking.toggled.connect(func(_b): _on_component_toggled())
	chk_opt.toggled.connect(func(_b): _on_component_toggled())
	
	theme_picker.item_selected.connect(_on_theme_selected)
	framework_picker.item_selected.connect(func(_idx): SoundManager.play_ui_click(); _update_website_preview())

func _process(delta: float) -> void:
	if not is_compiling:
		return
		
	compile_elapsed += delta
	var progress = clampf(compile_elapsed / compile_target_duration, 0.0, 1.0)
	terminal_progress.value = progress * 100.0
	
	# Step-by-step console streaming
	var step_threshold = compile_target_duration / 5.0
	var current_expected_step = int(compile_elapsed / step_threshold)
	if current_expected_step > compile_step:
		compile_step = current_expected_step
		_append_compilation_log_step(compile_step)
		
	if progress >= 1.0:
		_finish_compilation()

func _on_minigame_started(type: String) -> void:
	if type != "web_forge":
		return
		
	# Find active contract
	active_contract_id = ""
	for cid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to"]:
		var c = ContractManager.get_contract(cid)
		if c.get("status") == "in_progress":
			active_contract_id = cid
			break
			
	if active_contract_id == "":
		for c in ContractManager.active_contracts.values():
			if c.get("status") == "in_progress":
				active_contract_id = c.get("id")
				break
				
	if active_contract_id == "":
		visible = false
		EventBus.notification_posted.emit(
			"WebForge Inattivo",
			"Nessun contratto in lavorazione! Recati dai clienti in Via Po per accettare un progetto.",
			"warning"
		)
		return
		
	var contract = ContractManager.get_contract(active_contract_id)
	visible = true
	is_compiling = false
	is_build_completed = false
	compile_elapsed = 0.0
	compile_step = 0
	
	# Reset all toggles so nothing is pre-selected for new work!
	chk_header.button_pressed = false
	chk_hero.button_pressed = false
	chk_menu.button_pressed = false
	chk_hours.button_pressed = false
	chk_booking.button_pressed = false
	chk_opt.button_pressed = false
	
	deliver_btn.disabled = true
	deliver_btn.visible = false
	terminal_progress.value = 0.0
	terminal_logs.text = "[color=#00ccff]WebForge Toolchain v2.0 pronta per il bundling.[/color]\n"
	
	_switch_tab(true)
	_setup_palette_for_active_contract()
	_calculate_compilation_speed()
	_update_website_preview()

func _calculate_compilation_speed() -> void:
	# Base build time on starter laptop: 6.5s
	var duration = 6.5
	var boosts: Array[String] = []
	
	if "monitor_upgrade" in GameManager.studio_upgrades_installed:
		duration -= 1.5
		boosts.append("Monitor 2K (-1.5s)")
		
	if "chair_gaming_upgrade" in GameManager.studio_upgrades_installed:
		duration -= 0.8
		boosts.append("Sedia Pro (-0.8s)")
		
	if EmployeeManager and EmployeeManager.is_employee_hired("emp_luca"):
		duration -= 2.2
		boosts.append("Luca Vianello Dev (-2.2s)")
		
	compile_target_duration = max(1.2, duration)
	
	if boosts.is_empty():
		build_speed_info.text = "Velocità build: Base Starter Laptop (%0.1fs)" % compile_target_duration
	else:
		build_speed_info.text = "Velocità build: %0.1fs [%s]" % [compile_target_duration, ", ".join(boosts)]

func _setup_palette_for_active_contract() -> void:
	var contract = ContractManager.get_contract(active_contract_id)
	ide_label.text = "⚡ WebForge IDE — Progetto: %s (Budget: € %0.2f)" % [contract.get("title", "Progetto"), contract.get("budget", 650.0)]
	
	match active_contract_id:
		"pizzeria_da_mario":
			palette_title.text = "REQUISITI: PIZZERIA DA MARIO"
			chk_header.text = "1. Logo Mole & Insegna Storica"
			chk_hero.text = "2. Hero Banner Forno a Legna"
			chk_menu.text = "3. Menu Pizze Tradizionali"
			chk_hours.text = "4. Orari & Sede Via Po 18"
			chk_booking.text = "5. Modulo Prenotazione Tavoli"
		"caffe_san_carlo":
			palette_title.text = "REQUISITI: TOUCH POS CAFFÈ SAN CARLO"
			chk_header.text = "1. Header Cassa & Operatore Elena"
			chk_hero.text = "2. Griglia Touchscreen Veloce"
			chk_menu.text = "3. Listino Espresso, Bicerin & Dolci"
			chk_hours.text = "4. Gestione Tavoli & Dehors Via Po"
			chk_booking.text = "5. POS Pagamenti Contactless"
		"elettronica_to":
			palette_title.text = "REQUISITI: CLUSTER CLOUD ELETTRONICA TO"
			chk_header.text = "1. API Gateway & Load Balancer"
			chk_hero.text = "2. Catalogo Prodotti & Blade Server"
			chk_menu.text = "3. Replica Database Postgres/Redis"
			chk_hours.text = "4. Backup Notturno su Server Rack"
			chk_booking.text = "5. Firewall TLS & Token Auth"
		_:
			palette_title.text = "REQUISITI SOFTWARE AZIENDALE"
			chk_header.text = "1. Architettura Modulare Base"
			chk_hero.text = "2. Interfaccia Grafica Utente"
			chk_menu.text = "3. Logica di Business & API"
			chk_hours.text = "4. Database & Storage Dati"
			chk_booking.text = "5. Modulo Validazione & Sicurezza"

func _switch_tab(show_preview: bool) -> void:
	preview_area.visible = show_preview
	terminal_area.visible = not show_preview
	SoundManager.play_ui_click()

func _on_exit_pressed() -> void:
	if is_compiling:
		return
	visible = false
	EventBus.computer_opened.emit()

func _on_theme_selected(index: int) -> void:
	match index:
		0: current_theme_color = Color(0.85, 0.25, 0.2, 1)  # Rosso Tradizionale
		1: current_theme_color = Color(0.15, 0.65, 0.35, 1) # Verde Basilico
		2: current_theme_color = Color(0.20, 0.55, 0.85, 1) # Blu Sabaudo Tech
	SoundManager.play_ui_click()
	_update_website_preview()

func _on_component_toggled() -> void:
	SoundManager.play_ui_click()
	_update_website_preview()

func _update_website_preview() -> void:
	for child in preview_vbox.get_children():
		child.queue_free()
		
	var contract = ContractManager.get_contract(active_contract_id)
	
	# Browser Bar
	var url_bar = PanelContainer.new()
	var url_style = StyleBoxFlat.new()
	url_style.bg_color = Color(0.18, 0.2, 0.26, 1)
	url_style.set_content_margin_all(8)
	url_style.set_corner_radius_all(4)
	url_bar.add_theme_stylebox_override("panel", url_style)
	var url_lbl = Label.new()
	
	var domain_text = "https://localhost:8080/build"
	match active_contract_id:
		"pizzeria_da_mario": domain_text = "🔒 https://www.pizzeriadamario-torino.it [Preview Live]"
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
			"caffe_san_carlo": h_lbl.text = "☕ CAFFÈ SAN CARLO — WEB POS CASSA [Elena]"
			"elettronica_to": h_lbl.text = "⚡ ELETTRONICA TO — CLOUD REPLICATION CLUSTER"
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
		hero_style.set_content_margin_all(14)
		hero_panel.add_theme_stylebox_override("panel", hero_style)
		var hero_lbl = Label.new()
		match active_contract_id:
			"pizzeria_da_mario": hero_lbl.text = "«La vera pizza napoletana con il cuore sabaudo, cotta nel nostro forno a legna dal 1994»"
			"caffe_san_carlo": hero_lbl.text = "⚡ Modalità Servizio Veloce: Gestione Comande Banco & Tavoli Dehors in tempo reale."
			"elettronica_to": hero_lbl.text = "☁ Cluster Multi-Region: 99.99% SLA Uptime garantito con backup notturno su Server Rack."
			_: hero_lbl.text = "Piattaforma Enterprise performante e scalabile."
		hero_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hero_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hero_panel.add_child(hero_lbl)
		preview_vbox.add_child(hero_panel)
		
	# 3. Catalog / Menu
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
		
	# 4. Hours / Location
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
				op_text.text = "[center]📍 Via Po 18, Torino | 📞 011 555 4321 | Mar-Dom 12-15 / 19-23:30[/center]"
			"caffe_san_carlo":
				op_text.text = "[center]📍 Piazza San Carlo / Via Po 12 | 14 Tavoli Interni + 8 Tavoli Portici Dehors[/center]"
			"elettronica_to":
				op_text.text = "[center]💾 Backup Automatico: Mirroring SAN su Mini Rack 19\" dello studio ogni notte alle 03:00[/center]"
			_:
				op_text.text = "[center]Configurazione di rete verificata.[/center]"
		op_panel.add_child(op_text)
		preview_vbox.add_child(op_panel)
		
	# 5. Booking / Action
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
		cta.add_theme_font_size_override("font_size", 14)
		btn_panel.add_child(cta)
		preview_vbox.add_child(btn_panel)
		
	# Quality calculation
	var quality_percent = float(active_count) / 5.0 * 100.0
	quality_progress.value = quality_percent
	quality_label.text = "Completezza: %d%% (%d / 5 Requisiti)" % [int(quality_percent), active_count]
	
	if active_count == 5:
		compile_btn.disabled = is_compiling or is_build_completed
		compile_btn.text = "⚡ Avvia Compilazione & Bundling"
		status_label.text = "Requisiti soddisfatti al 100%! Clicca su 'Avvia Compilazione' per generare la build."
	else:
		compile_btn.disabled = true
		compile_btn.text = "Seleziona i requisiti (%d / 5)" % active_count
		status_label.text = "Mancano ancora %d requisiti richiesti dal cliente." % (5 - active_count)

func _on_compile_pressed() -> void:
	if is_compiling or is_build_completed:
		return
		
	is_compiling = true
	compile_elapsed = 0.0
	compile_step = 0
	compile_btn.disabled = true
	_switch_tab(false) # Switch to terminal
	
	SoundManager.play_keyboard_sound()
	terminal_logs.text = "[color=#00ccff]▶ [00:00.00] Inizializzazione toolchain Vite / Node.js runtime...[/color]\n"
	terminal_logs.text += "[color=#aaaaaa]• Framework: %s | Tema: %s[/color]\n" % [framework_picker.get_item_text(framework_picker.selected), theme_picker.get_item_text(theme_picker.selected)]
	terminal_logs.text += "[color=#44ffbb]• Profilo Hardware: %s[/color]\n\n" % build_speed_info.text
	status_label.text = "Compilazione in corso... Attendi il termine del processo di bundling."

func _append_compilation_log_step(step: int) -> void:
	SoundManager.play_keyboard_sound()
	match step:
		1:
			terminal_logs.text += "[color=#33ccff]▶ [%0.2fs] Parsing moduli TypeScript & componenti JSX... OK[/color]\n" % compile_elapsed
		2:
			terminal_logs.text += "[color=#33ccff]▶ [%0.2fs] Compilazione CSS e ottimizzazione bundle grafico... OK[/color]\n" % compile_elapsed
		3:
			if chk_opt.button_pressed:
				terminal_logs.text += "[color=#44ffbb]▶ [%0.2fs] Compressione WebP attiva: risparmiati 4.2 MB di asset![/color]\n" % compile_elapsed
			else:
				terminal_logs.text += "[color=#ffbb33]▶ [%0.2fs] Asset non compressi: bundling standard in corso...[/color]\n" % compile_elapsed
		4:
			terminal_logs.text += "[color=#33ccff]▶ [%0.2fs] Esecuzione suite di test automatizzati (14 superati)... OK[/color]\n" % compile_elapsed

func _finish_compilation() -> void:
	is_compiling = false
	is_build_completed = true
	compile_btn.disabled = true
	compile_btn.text = "✔ Compilazione Terminata"
	
	SoundManager.play_ui_success()
	terminal_logs.text += "\n[color=#33ff77]✔ [%0.2fs] BUILD COMPLETATA CON SUCCESSO![/color]\n" % compile_target_duration
	terminal_logs.text += "[color=#00ccff]• Artifact: dist/release_%s.tar.gz (Generato con Qualità 100%%)[/color]\n" % active_contract_id
	terminal_logs.text += "[color=#ffffff]Il software è pronto per essere consegnato al cliente.[/color]\n"
	
	var result_data = {
		"theme": current_theme_color.to_html(),
		"framework": framework_picker.get_item_text(framework_picker.selected),
		"quality": 100.0,
		"optimized": chk_opt.button_pressed,
		"components": ["header", "hero", "menu", "hours", "booking"]
	}
	ContractManager.mark_contract_built(active_contract_id, result_data)
	
	var contract = ContractManager.get_contract(active_contract_id)
	deliver_btn.visible = true
	deliver_btn.disabled = false
	deliver_btn.text = "★ Consegna Release a %s (€ %0.2f)" % [contract.get("client", "Cliente"), contract.get("budget", 650.0)]
	status_label.text = "Build completata con successo! Clicca su 'Consegna Release' per riscuotere il pagamento."

func _on_deliver_pressed() -> void:
	SoundManager.play_ui_success()
	ContractManager.complete_story_contract(active_contract_id)
	visible = false
	EventBus.computer_opened.emit()
