extends Control
## WebForgeController - WebForge 3.0: Reinvented Modular Website Assembler & Performance Tuning Suite.
## Eradicates static boolean checkboxes and passive delays.
## Features modular slot assembly (Header, Hero, Body, Widget, Footer), client tag affinities,
## CSS Brand Palette selection, clickable linting/bug-squashing optimizations,
## and real-time Lighthouse audit scoring (Performance, Accessibility, SEO).

# Top Header Nodes
@onready var ide_label: Label = $Main/Header/HBox/IDELabel
@onready var lighthouse_score_label: Label = $Main/Header/HBox/LighthouseBadge/LighthouseScoreLabel
@onready var exit_btn: Button = $Main/Header/HBox/ExitButton

# Left Toolbox Nodes
@onready var client_title: Label = $Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/BriefPanel/BriefVBox/ClientTitle
@onready var client_prefs: Label = $Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/BriefPanel/BriefVBox/ClientPrefs
@onready var slot_tab_buttons: Array[Button] = [
	$Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/SlotTabsHBox/TabSlot1,
	$Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/SlotTabsHBox/TabSlot2,
	$Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/SlotTabsHBox/TabSlot3,
	$Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/SlotTabsHBox/TabSlot4,
	$Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/SlotTabsHBox/TabSlot5
]
@onready var component_tray_vbox: VBoxContainer = $Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/ComponentTrayVBox
@onready var palette_picker: OptionButton = $Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/PalettePicker
@onready var palette_affinity_badge: Label = $Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/PaletteAffinityBadge
@onready var opt_btn_minify: Button = $Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/BadgesVBox/OptBtnMinify
@onready var opt_btn_webp: Button = $Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/BadgesVBox/OptBtnWebP
@onready var opt_btn_meta: Button = $Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/BadgesVBox/OptBtnMeta
@onready var build_speed_info: Label = $Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/BuildSpeedInfo
@onready var compile_btn: Button = $Main/Body/Toolbox/ToolboxScroll/ToolboxVBox/CompileButton

# Canvas & Preview Nodes
@onready var canvas_node: PanelContainer = $Main/Body/Canvas
@onready var tab_preview_btn: Button = $Main/Body/Canvas/CanvasVBox/CanvasHeaderHBox/TabPreviewBtn
@onready var tab_terminal_btn: Button = $Main/Body/Canvas/CanvasVBox/CanvasHeaderHBox/TabTerminalBtn
@onready var preview_area: PanelContainer = $Main/Body/Canvas/CanvasVBox/PreviewArea
@onready var preview_vbox: VBoxContainer = $Main/Body/Canvas/CanvasVBox/PreviewArea/PreviewScroll/PreviewVBox
@onready var terminal_area: PanelContainer = $Main/Body/Canvas/CanvasVBox/TerminalArea
@onready var terminal_progress: ProgressBar = $Main/Body/Canvas/CanvasVBox/TerminalArea/TerminalVBox/TerminalProgress
@onready var terminal_logs: RichTextLabel = $Main/Body/Canvas/CanvasVBox/TerminalArea/TerminalVBox/TerminalLogs

# Footer Nodes
@onready var perf_label: Label = $Main/Footer/HBox/GaugesHBox/PerfLabel
@onready var a11y_label: Label = $Main/Footer/HBox/GaugesHBox/A11yLabel
@onready var seo_label: Label = $Main/Footer/HBox/GaugesHBox/SEOLabel
@onready var status_label: Label = $Main/Footer/HBox/StatusLabel
@onready var deliver_btn: Button = $Main/Footer/HBox/DeliverButton

# Slot Identifiers
const SLOT_KEYS: Array[String] = ["header", "hero", "body", "widget", "footer"]
const SLOT_NAMES: Array[String] = ["1. Header & Logo", "2. Hero Banner", "3. Body Content", "4. Action Widget", "5. Footer & Info"]

# CSS Brand Palettes
const BRAND_PALETTES: Array[Dictionary] = [
	{
		"id": "terracotta",
		"name": "Terracotta Napoletana (Rosso & Oro)",
		"primary": Color(0.85, 0.28, 0.20, 1.0),
		"accent": Color(0.96, 0.65, 0.14, 1.0),
		"bg": Color(0.14, 0.10, 0.10, 1.0),
		"client_bias": "pizzeria_da_mario"
	},
	{
		"id": "mocha",
		"name": "Café Mocha & Oro (Espresso & Oro)",
		"primary": Color(0.48, 0.32, 0.22, 1.0),
		"accent": Color(0.86, 0.70, 0.25, 1.0),
		"bg": Color(0.12, 0.10, 0.09, 1.0),
		"client_bias": "caffe_san_carlo"
	},
	{
		"id": "cyan",
		"name": "Cyber Cyan & Slate (Dark Tech)",
		"primary": Color(0.00, 0.75, 0.95, 1.0),
		"accent": Color(0.20, 1.00, 0.60, 1.0),
		"bg": Color(0.08, 0.10, 0.14, 1.0),
		"client_bias": "elettronica_to"
	},
	{
		"id": "emerald",
		"name": "Smeraldo Alpino (Verde & Menta)",
		"primary": Color(0.18, 0.68, 0.38, 1.0),
		"accent": Color(0.60, 0.92, 0.30, 1.0),
		"bg": Color(0.08, 0.12, 0.10, 1.0),
		"client_bias": ""
	},
	{
		"id": "monochrome",
		"name": "Modern Minimal White (Bianco & Grafite)",
		"primary": Color(0.90, 0.92, 0.95, 1.0),
		"accent": Color(0.45, 0.60, 0.85, 1.0),
		"bg": Color(0.10, 0.10, 0.12, 1.0),
		"client_bias": ""
	}
]

# Modular Components Catalog
const COMPONENT_CATALOG: Dictionary = {
	"header": [
		{
			"id": "header_mole",
			"title": "🏛 Mole Antonelliana Classic",
			"tags": ["Tradition", "Speed"],
			"bias": "pizzeria_da_mario",
			"desc": "Logo Mole dorato, tipografia artigianale e navbar classica.",
			"preview_title": "🏛 PIZZERIA DA MARIO — TORINO 🏛",
			"preview_sub": "Tradizione Napoletana & Cuore Sabaudo dal 1994"
		},
		{
			"id": "header_pos",
			"title": "☕ Cassa Express San Carlo",
			"tags": ["Speed", "Booking"],
			"bias": "caffe_san_carlo",
			"desc": "Header compatto con stato operatore banco e tavoli dehors.",
			"preview_title": "☕ CAFFÈ SAN CARLO — WEB POS [Operatore Elena]",
			"preview_sub": "Postazione Cassa Touchscreen & Gestione Ordini Rapidi"
		},
		{
			"id": "header_cloud",
			"title": "⚡ Enterprise Cloud Gateway",
			"tags": ["Tech", "E-Commerce"],
			"bias": "elettronica_to",
			"desc": "Navbar con metriche di latenza, cluster status e token auth.",
			"preview_title": "⚡ ELETTRONICA TO — CLOUD REPLICATION CLUSTER",
			"preview_sub": "Cluster Multi-Region 99.99% SLA | Auth TLS 1.3"
		}
	],
	"hero": [
		{
			"id": "hero_oven",
			"title": "🍕 Forno a Legna Napoletano",
			"tags": ["Tradition", "Speed"],
			"bias": "pizzeria_da_mario",
			"desc": "Banner scenografico con fiamma viva a 450°C e impasti 48h.",
			"preview_text": "«La vera pizza napoletana a Torino: impasto a lievitazione lenta 48h, fiordilatte di Agerola e cottura nel forno a legna artigianale.»"
		},
		{
			"id": "hero_bistro",
			"title": "⚡ Touch Order Showcase",
			"tags": ["Speed", "Booking"],
			"bias": "caffe_san_carlo",
			"desc": "Vetrina comande con pulsanti veloci espresso, bicerin e dehors.",
			"preview_text": "«Modalità Servizio Express: Smistamento comande banco e dehors in 12 secondi con sincronizzazione cloud immediata.»"
		},
		{
			"id": "hero_cluster",
			"title": "☁ Blade Server & Cloud Matrix",
			"tags": ["Tech", "Speed"],
			"bias": "elettronica_to",
			"desc": "Cruscotto monitoraggio 42U Server Rack e replica PostgreSQL.",
			"preview_text": "«Mirroring asincrono continuo, cluster Redis 64GB in-memory e storage SAN ridondato per 1,450 SKU di magazzino.»"
		}
	],
	"body": [
		{
			"id": "body_pizza",
			"title": "📜 Menu Pizze Tradizionali",
			"tags": ["Tradition", "E-Commerce"],
			"bias": "pizzeria_da_mario",
			"desc": "Margherita Verace DOP, Diavola del Po e Salsiccia di Bra.",
			"preview_text": "• [b]Margherita Verace:[/b] Mozzarella di bufala DOP, San Marzano - € 7,50\n• [b]Diavola del Po:[/b] Salame piccante, Fiordilatte - € 9,00\n• [b]Piemontese DOC:[/b] Crema di tartufo, Salsiccia di Bra - € 12,00"
		},
		{
			"id": "body_cafe",
			"title": "🥐 Listino Bicerin & Dolci",
			"tags": ["Tradition", "Speed"],
			"bias": "caffe_san_carlo",
			"desc": "Espresso Miscela Torino, Bicerin tradizionale e aperitivi.",
			"preview_text": "• [b]Espresso Miscela Torino:[/b] € 1,30 | [b]Bicerin Tradizionale:[/b] € 4,50\n• [b]Croissant Pistacchio & Crema:[/b] € 2,00 | [b]Aperitivo Portici:[/b] € 9,00"
		},
		{
			"id": "body_tech",
			"title": "💾 Database & Services Grid",
			"tags": ["Tech", "E-Commerce"],
			"bias": "elettronica_to",
			"desc": "Catalogo hardware, sincronizzazione SKU e API REST/GraphQL.",
			"preview_text": "• [b]PostgreSQL Master-Replica:[/b] Active (Latenza sincrona < 1.4ms)\n• [b]Redis Cache Layer:[/b] 98.6% Hit Ratio | Memory: 64 GB\n• [b]Catalogo B2B:[/b] 1,450 SKU sincronizzati in tempo reale"
		}
	],
	"widget": [
		{
			"id": "widget_booking",
			"title": "📅 Prenotazione Tavoli Online",
			"tags": ["Booking", "Tradition"],
			"bias": "pizzeria_da_mario",
			"desc": "Selezione orario, numero coperti e conferma istantanea SMS.",
			"preview_btn": "➔ PRENOTA UN TAVOLO O ORDINA ASPORTO ONLINE"
		},
		{
			"id": "widget_pos",
			"title": "💳 Touch POS Cassa & Satispay",
			"tags": ["Speed", "E-Commerce"],
			"bias": "caffe_san_carlo",
			"desc": "Integrazione POS contactless, Satispay e scontrino fiscale.",
			"preview_btn": "➔ INCASSA CONTO TOUCH & EMETTI SCONTRINO"
		},
		{
			"id": "widget_deploy",
			"title": "🚀 Console Docker & Deploy TLS",
			"tags": ["Tech", "Speed"],
			"bias": "elettronica_to",
			"desc": "Trigger rilascio container di produzione e verifica chiavi TLS.",
			"preview_btn": "➔ DEPLOY CONTAINER PRODUCTION & VERIFICA TLS"
		}
	],
	"footer": [
		{
			"id": "footer_mario",
			"title": "📍 Sede Via Po 18 & Orari",
			"tags": ["Tradition", "Booking"],
			"bias": "pizzeria_da_mario",
			"desc": "Indirizzo Via Po, recapiti telefonici e orari 12-15 / 19-23:30.",
			"preview_text": "📍 Via Po 18, Torino | 📞 011 555 4321 | Mar-Dom 12:00-15:00 / 19:00-23:30"
		},
		{
			"id": "footer_elena",
			"title": "🏛 Dehors Portici & Free WiFi",
			"tags": ["Tradition", "Speed"],
			"bias": "caffe_san_carlo",
			"desc": "Piazza San Carlo / Via Po 12 con mappa dehors e connettività.",
			"preview_text": "📍 Piazza San Carlo / Via Po 12 | 14 Tavoli Interni + 8 Tavoli Portici Dehors | Free WiFi"
		},
		{
			"id": "footer_davide",
			"title": "🛡 System Status 200 OK & SAN",
			"tags": ["Tech", "Speed"],
			"bias": "elettronica_to",
			"desc": "Mirroring SAN notturno alle 03:00 e diagnostica heartbeat nodi.",
			"preview_text": "💾 Backup Notturno Automatico su Server Rack 19\" alle 03:00 | Uptime: 99.992% 200 OK"
		}
	]
}

# State Variables
var active_contract_id: String = "pizzeria_da_mario"
var active_slot_idx: int = 0
var slotted_components: Dictionary = {
	"header": null,
	"hero": null,
	"body": null,
	"widget": null,
	"footer": null
}
var current_palette_idx: int = 0
var opt_minify: bool = false
var opt_webp: bool = false
var opt_meta: bool = false

# Compilation & Build State
var is_compiling: bool = false
var is_build_completed: bool = false
var compile_elapsed: float = 0.0
var compile_target_duration: float = 5.0
var compile_step: int = 0
var last_calculated_tip: float = 0.0
var last_calculated_score: float = 0.0

func _ready() -> void:
	visible = false
	EventBus.minigame_started.connect(_on_minigame_started)
	
	exit_btn.pressed.connect(_on_exit_pressed)
	compile_btn.pressed.connect(_on_compile_pressed)
	deliver_btn.pressed.connect(_on_deliver_pressed)
	
	tab_preview_btn.pressed.connect(func(): _switch_tab(true))
	tab_terminal_btn.pressed.connect(func(): _switch_tab(false))
	
	for i in range(slot_tab_buttons.size()):
		var idx = i
		slot_tab_buttons[idx].pressed.connect(func(): _select_slot(idx))
		
	_setup_palette_picker()
	palette_picker.item_selected.connect(_on_palette_selected)
	
	opt_btn_minify.pressed.connect(_on_opt_minify_pressed)
	opt_btn_webp.pressed.connect(_on_opt_webp_pressed)
	opt_btn_meta.pressed.connect(_on_opt_meta_pressed)

func _process(delta: float) -> void:
	if not is_compiling:
		return
		
	compile_elapsed += delta
	# Snappy build animation completes in 0.8s
	var progress = clampf(compile_elapsed / 0.8, 0.0, 1.0)
	terminal_progress.value = progress * 100.0
	
	var step_threshold = 0.8 / 4.0
	var current_expected_step = int(compile_elapsed / step_threshold)
	if current_expected_step > compile_step:
		compile_step = current_expected_step
		_append_compilation_log_step(compile_step)
		
	if progress >= 1.0:
		_finish_compilation()

func _on_minigame_started(type: String) -> void:
	if type != "web_forge":
		return
		
	active_contract_id = ""
	for cid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to"]:
		var c = ContractManager.get_contract(cid)
		if c.get("status") == "in_progress":
			active_contract_id = cid
			break
			
	if active_contract_id == "":
		for c in ContractManager.active_contracts.values():
			if c.get("status") == "in_progress":
				active_contract_id = c.get("id", "")
				break
				
	if active_contract_id == "":
		visible = false
		EventBus.notification_posted.emit(
			"WebForge Inattivo",
			"Nessun contratto in lavorazione! Recati dai clienti in Via Po per accettare un progetto.",
			"warning"
		)
		return
		
	visible = true
	is_compiling = false
	is_build_completed = false
	compile_elapsed = 0.0
	compile_step = 0
	last_calculated_tip = 0.0
	
	# Reset state
	for k in SLOT_KEYS:
		slotted_components[k] = null
	opt_minify = false
	opt_webp = false
	opt_meta = false
	active_slot_idx = 0
	
	deliver_btn.disabled = true
	deliver_btn.visible = false
	terminal_progress.value = 0.0
	terminal_logs.text = "[color=#00ccff]WebForge Toolchain v3.0 pronta per il bundling modular architecture.[/color]\n"
	
	_switch_tab(true)
	_setup_for_active_contract()
	_calculate_compilation_speed()
	_update_slot_tabs_visual()
	_update_component_tray()
	_update_optimization_buttons_visual()
	_update_palette_affinity_badge()
	_update_website_preview()
	_update_lighthouse_display()

func _calculate_compilation_speed() -> void:
	# Base build speed benchmark on starter laptop: 5.5s
	var duration = 5.5
	var boosts: Array[String] = []
	
	if "monitor_upgrade" in GameManager.studio_upgrades_installed:
		duration -= 1.5
		boosts.append("Dual Monitor (-1.5s)")
		
	if "chair_gaming_upgrade" in GameManager.studio_upgrades_installed:
		duration -= 0.8
		boosts.append("Sedia Ergonomica (-0.8s)")
		
	if EmployeeManager and EmployeeManager.is_employee_hired("emp_luca"):
		duration -= 1.5
		boosts.append("Luca Dev (-1.5s)")
		
	compile_target_duration = max(1.2, duration)
	
	if boosts.is_empty():
		build_speed_info.text = "Toolchain: Starter Laptop (%0.1fs)" % compile_target_duration
	else:
		build_speed_info.text = "Toolchain: %0.1fs [%s]" % [compile_target_duration, ", ".join(boosts)]

func _setup_palette_picker() -> void:
	palette_picker.clear()
	for p in BRAND_PALETTES:
		palette_picker.add_item(p["name"])
	palette_picker.selected = 0
	current_palette_idx = 0

func _setup_for_active_contract() -> void:
	var contract = ContractManager.get_contract(active_contract_id)
	var title = contract.get("title", "Progetto Web")
	var budget = float(contract.get("budget", 650.0))
	ide_label.text = "⚡ WebForge IDE — Progetto: %s (Budget: € %0.2f)" % [title, budget]
	
	client_title.text = "PROGETTO: %s" % contract.get("client", "Cliente")
	
	var prefs = _get_client_preferences(active_contract_id)
	var tags_str = " ".join(prefs["preferred_tags"].map(func(t): return "[%s]" % t))
	client_prefs.text = "Affinità: %s | Palette consigliata: %s" % [tags_str, prefs["palette_name"]]
	
	# Select recommended palette index
	for i in range(BRAND_PALETTES.size()):
		if BRAND_PALETTES[i]["id"] == prefs["preferred_palette"]:
			palette_picker.selected = i
			current_palette_idx = i
			break

func _get_client_preferences(cid: String) -> Dictionary:
	match cid:
		"pizzeria_da_mario":
			return {
				"client_name": "Mario Rossi",
				"preferred_tags": ["Tradition", "Booking"],
				"preferred_palette": "terracotta",
				"palette_name": "Terracotta Napoletana",
				"perfect_review": "«Mamma mia! Quella foto del forno a legna fa venire fame a tutta Torino, e il modulo prenotazioni è una bomba! Tieni questa mancia, te la sei meritata!»",
				"good_review": "«Bel lavoro guagliò, il sito è solido e i clienti finalmente possono vedere le nostre pizze online. Grazie!»"
			}
		"caffe_san_carlo":
			return {
				"client_name": "Elena Barista",
				"preferred_tags": ["Speed", "Tradition"],
				"preferred_palette": "mocha",
				"palette_name": "Café Mocha & Oro",
				"perfect_review": "«Incredibile! La cassa touch screen e la gestione comande volano! Niente più file al bancone nelle ore di punta. Eccoti un bonus ben meritato!»",
				"good_review": "«Ottimo POS web, molto elegante e i clienti adorano la grafica del nostro storico caffè.»"
			}
		"elettronica_to":
			return {
				"client_name": "Davide",
				"preferred_tags": ["Tech", "Speed"],
				"preferred_palette": "cyan",
				"palette_name": "Cyber Cyan & Slate",
				"perfect_review": "«Latenza sotto i 2 millisecondi e architettura a prova di bomba! Sei un vero fuoriclasse del software, ottimo lavoro!»",
				"good_review": "«Cluster configurato a dovere e replica database attiva. Buon lavoro!»"
			}
		_:
			return {
				"client_name": "Cliente B2B",
				"preferred_tags": ["Tech", "E-Commerce"],
				"preferred_palette": "cyan",
				"palette_name": "Cyber Cyan & Slate",
				"perfect_review": "«Eccezionale! Punteggio Lighthouse stratosferico e release impeccabile. Ti abbiamo aggiunto una cospicua mancia!»",
				"good_review": "«Progetto consegnato nei tempi e pienamente conforme alle specifiche. Ottimo lavoro!»"
			}

func _select_slot(idx: int) -> void:
	if idx < 0 or idx >= SLOT_KEYS.size():
		return
	active_slot_idx = idx
	SoundManager.play_ui_click()
	_update_slot_tabs_visual()
	_update_component_tray()

func _update_slot_tabs_visual() -> void:
	for i in range(slot_tab_buttons.size()):
		var btn = slot_tab_buttons[i]
		var k = SLOT_KEYS[i]
		var is_slotted = (slotted_components[k] != null)
		var is_active = (i == active_slot_idx)
		
		var prefix = "✔ " if is_slotted else ""
		btn.text = "%s%s" % [prefix, ["Header", "Hero", "Body", "Widget", "Footer"][i]]
		
		if is_active:
			btn.add_theme_color_override("font_color", Color(0.3, 1, 0.7, 1))
		elif is_slotted:
			btn.add_theme_color_override("font_color", Color(0.9, 0.9, 1, 1))
		else:
			btn.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1))

func _update_component_tray() -> void:
	for c in component_tray_vbox.get_children():
		c.queue_free()
		
	var slot_key = SLOT_KEYS[active_slot_idx]
	var catalog_items: Array = COMPONENT_CATALOG.get(slot_key, [])
	var prefs = _get_client_preferences(active_contract_id)
	var current_slotted_id = slotted_components.get(slot_key)
	
	for item in catalog_items:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 30)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 11)
		
		# Tag affinity check
		var has_affinity = false
		for t in item["tags"]:
			if t in prefs["preferred_tags"]:
				has_affinity = true
				break
				
		var is_selected = (item["id"] == current_slotted_id)
		var affinity_star = " ★ [Match]" if has_affinity else ""
		var selected_mark = "✔ " if is_selected else ""
		
		var tag_labels = " ".join(item["tags"].map(func(t): return "[%s]" % t))
		btn.text = "%s%s %s%s" % [selected_mark, item["title"], tag_labels, affinity_star]
		
		if is_selected:
			btn.add_theme_color_override("font_color", Color(0.3, 1, 0.6, 1))
		elif has_affinity:
			btn.add_theme_color_override("font_color", Color(1, 0.85, 0.35, 1))
		else:
			btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1))
			
		var comp_id = item["id"]
		btn.pressed.connect(func(): _on_component_chosen(slot_key, comp_id))
		component_tray_vbox.add_child(btn)

func _on_component_chosen(slot_key: String, comp_id: String) -> void:
	SoundManager.play_ui_click()
	slotted_components[slot_key] = comp_id
	
	# Auto-advance to next empty slot if available
	for i in range(SLOT_KEYS.size()):
		var k = SLOT_KEYS[i]
		if slotted_components[k] == null:
			active_slot_idx = i
			break
			
	_update_slot_tabs_visual()
	_update_component_tray()
	_update_website_preview()
	_update_lighthouse_display()

func _on_palette_selected(index: int) -> void:
	current_palette_idx = index
	SoundManager.play_ui_click()
	_update_palette_affinity_badge()
	_update_website_preview()
	_update_lighthouse_display()

func _update_palette_affinity_badge() -> void:
	var cur_palette = BRAND_PALETTES[current_palette_idx]
	var prefs = _get_client_preferences(active_contract_id)
	if cur_palette["id"] == prefs["preferred_palette"]:
		palette_affinity_badge.text = "★ Brand Affinity Match! (+15% Bonus SEO & Design)"
		palette_affinity_badge.add_theme_color_override("font_color", Color(0.3, 1, 0.6, 1))
	else:
		palette_affinity_badge.text = "Palette standard (Nessun bonus affinità)"
		palette_affinity_badge.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 1))

func _on_opt_minify_pressed() -> void:
	opt_minify = not opt_minify
	SoundManager.play_keyboard_sound()
	_update_optimization_buttons_visual()
	_update_lighthouse_display()

func _on_opt_webp_pressed() -> void:
	opt_webp = not opt_webp
	SoundManager.play_keyboard_sound()
	_update_optimization_buttons_visual()
	_update_lighthouse_display()

func _on_opt_meta_pressed() -> void:
	opt_meta = not opt_meta
	SoundManager.play_keyboard_sound()
	_update_optimization_buttons_visual()
	_update_lighthouse_display()

func _update_optimization_buttons_visual() -> void:
	if opt_minify:
		opt_btn_minify.text = "✔ Minify CSS/JS Attivo (-2.8MB)"
		opt_btn_minify.add_theme_color_override("font_color", Color(0.3, 1, 0.6, 1))
	else:
		opt_btn_minify.text = "⚡ Minify CSS/JS [Warning: +3.8MB]"
		opt_btn_minify.add_theme_color_override("font_color", Color(1, 0.8, 0.3, 1))
		
	if opt_webp:
		opt_btn_webp.text = "✔ Compressione WebP Attiva (-72%)"
		opt_btn_webp.add_theme_color_override("font_color", Color(0.3, 1, 0.6, 1))
	else:
		opt_btn_webp.text = "🖼 Comprimi WebP [Warning: PNG pesanti]"
		opt_btn_webp.add_theme_color_override("font_color", Color(1, 0.8, 0.3, 1))
		
	if opt_meta:
		opt_btn_meta.text = "✔ Meta SEO & OpenGraph Iniettati"
		opt_btn_meta.add_theme_color_override("font_color", Color(0.3, 1, 0.6, 1))
	else:
		opt_btn_meta.text = "🏷 Meta SEO & OpenGraph [Warning: Mancanti]"
		opt_btn_meta.add_theme_color_override("font_color", Color(1, 0.8, 0.3, 1))

## Calculates dynamic Lighthouse audit score (0-100) based on slotted components, tag affinities, palette match, and linting.
func calculate_lighthouse_score() -> Dictionary:
	var slots_filled = 0
	var matching_tags = 0
	var prefs = _get_client_preferences(active_contract_id)
	
	for slot_key in SLOT_KEYS:
		var comp_id = slotted_components.get(slot_key)
		if comp_id != null:
			slots_filled += 1
			# Find item in catalog
			for item in COMPONENT_CATALOG[slot_key]:
				if item["id"] == comp_id:
					for t in item["tags"]:
						if t in prefs["preferred_tags"]:
							matching_tags += 1
					break
					
	var cur_palette = BRAND_PALETTES[current_palette_idx]
	var palette_match = (cur_palette["id"] == prefs["preferred_palette"])
	
	var opts_count = 0
	if opt_minify: opts_count += 1
	if opt_webp: opts_count += 1
	if opt_meta: opts_count += 1
	
	# Sub-scores:
	# 1. Performance (50% slots + 25% minify + 25% webp)
	var perf = clampf(round((float(slots_filled) / 5.0 * 50.0) + (25.0 if opt_minify else 0.0) + (25.0 if opt_webp else 0.0)), 0.0, 100.0)
	
	# 2. Accessibility (70% slots + 20% palette contrast + 10% all slots bonus)
	var a11y_palette = 20.0 if palette_match else 10.0
	var a11y_bonus = 10.0 if slots_filled == 5 else 0.0
	var a11y = clampf(round((float(slots_filled) / 5.0 * 70.0) + a11y_palette + a11y_bonus), 0.0, 100.0)
	
	# 3. SEO (40% slots + 35% tag match affinity + 25% meta tags)
	var tag_affinity_ratio = clampf(float(matching_tags) / 5.0, 0.0, 1.0)
	var seo = clampf(round((float(slots_filled) / 5.0 * 40.0) + (tag_affinity_ratio * 35.0) + (25.0 if opt_meta else 0.0)), 0.0, 100.0)
	
	# Total Overall Score
	var total = clampf(round((perf * 0.40) + (a11y * 0.30) + (seo * 0.30)), 0.0, 100.0)
	
	var grade = "C"
	if total >= 95.0:
		grade = "A+"
	elif total >= 85.0:
		grade = "A"
	elif total >= 70.0:
		grade = "B"
		
	return {
		"performance": perf,
		"accessibility": a11y,
		"seo": seo,
		"total": total,
		"grade": grade,
		"slots_filled": slots_filled,
		"matching_tags": matching_tags,
		"palette_match": palette_match,
		"opts_count": opts_count
	}

func _update_lighthouse_display() -> void:
	var audit = calculate_lighthouse_score()
	var total = audit["total"]
	var grade = audit["grade"]
	
	lighthouse_score_label.text = "🎯 Lighthouse: %d/100 (Grado %s)" % [int(total), grade]
	perf_label.text = "⚡ Prestazioni: %d%%" % int(audit["performance"])
	a11y_label.text = "♿ Accessibilità: %d%%" % int(audit["accessibility"])
	seo_label.text = "🔍 SEO: %d%%" % int(audit["seo"])
	
	var slots_filled = audit["slots_filled"]
	if slots_filled == 5:
		compile_btn.disabled = is_compiling or is_build_completed
		compile_btn.text = "⚡ Compila & Esegui Build (5/5 Slot)"
		if not is_build_completed and not is_compiling:
			status_label.text = "Tutti i 5 slot configurati! Clicca su 'Compila & Esegui Build' per avviare il bundling."
	else:
		compile_btn.disabled = true
		compile_btn.text = "Configura gli slot (%d/5)" % slots_filled
		if not is_build_completed and not is_compiling:
			status_label.text = "Mancano ancora %d slot da selezionare prima di poter compilare." % (5 - slots_filled)

func _update_website_preview() -> void:
	for child in preview_vbox.get_children():
		child.queue_free()
		
	var palette = BRAND_PALETTES[current_palette_idx]
	
	# 0. Simulated Browser Bar
	var url_bar = PanelContainer.new()
	var url_style = StyleBoxFlat.new()
	url_style.bg_color = Color(0.12, 0.14, 0.18, 1)
	url_style.set_content_margin_all(6)
	url_style.set_corner_radius_all(4)
	url_bar.add_theme_stylebox_override("panel", url_style)
	var url_lbl = Label.new()
	
	var domain = "https://localhost:8080/preview"
	match active_contract_id:
		"pizzeria_da_mario": domain = "🔒 https://www.pizzeriadamario-torino.it [Live Staging]"
		"caffe_san_carlo": domain = "🔒 https://pos.caffesancarlo.to.it [Touch Screen Preview]"
		"elettronica_to": domain = "🔒 https://cloud.elettronicato.com [Production Cluster]"
	url_lbl.text = domain
	url_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5, 1))
	url_lbl.add_theme_font_size_override("font_size", 11)
	url_bar.add_child(url_lbl)
	preview_vbox.add_child(url_bar)
	
	# Render each of the 5 slots
	for i in range(SLOT_KEYS.size()):
		var slot_key = SLOT_KEYS[i]
		var comp_id = slotted_components.get(slot_key)
		var is_current = (i == active_slot_idx)
		
		var panel = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(6)
		style.set_content_margin_all(8)
		
		if comp_id == null:
			# Empty placeholder slot
			style.bg_color = Color(0.08, 0.10, 0.14, 0.6)
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color(0.3, 0.8, 1, 0.8) if is_current else Color(0.2, 0.25, 0.35, 0.6)
			panel.add_theme_stylebox_override("panel", style)
			
			var placeholder_btn = Button.new()
			placeholder_btn.text = "＋ Clicca per inserire [%s]" % SLOT_NAMES[i]
			placeholder_btn.add_theme_font_size_override("font_size", 11)
			placeholder_btn.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9, 1))
			var slot_idx_copy = i
			placeholder_btn.pressed.connect(func(): _select_slot(slot_idx_copy))
			panel.add_child(placeholder_btn)
		else:
			# Render populated component
			var comp_item: Dictionary = {}
			for item in COMPONENT_CATALOG[slot_key]:
				if item["id"] == comp_id:
					comp_item = item
					break
					
			match slot_key:
				"header":
					style.bg_color = palette["primary"]
					panel.add_theme_stylebox_override("panel", style)
					var v = VBoxContainer.new()
					var title_lbl = Label.new()
					title_lbl.text = comp_item.get("preview_title", comp_item["title"])
					title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					title_lbl.add_theme_font_size_override("font_size", 13)
					v.add_child(title_lbl)
					var sub_lbl = Label.new()
					sub_lbl.text = comp_item.get("preview_sub", "")
					sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					sub_lbl.add_theme_font_size_override("font_size", 10)
					v.add_child(sub_lbl)
					panel.add_child(v)
				"hero":
					style.bg_color = palette["bg"]
					style.border_width_left = 2
					style.border_color = palette["accent"]
					panel.add_theme_stylebox_override("panel", style)
					var hero_lbl = Label.new()
					hero_lbl.text = comp_item.get("preview_text", comp_item["desc"])
					hero_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					hero_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					hero_lbl.add_theme_font_size_override("font_size", 11)
					panel.add_child(hero_lbl)
				"body":
					style.bg_color = Color(0.12, 0.14, 0.18, 1)
					panel.add_theme_stylebox_override("panel", style)
					var body_rtl = RichTextLabel.new()
					body_rtl.bbcode_enabled = true
					body_rtl.fit_content = true
					body_rtl.theme_override_font_sizes.normal_font_size = 11
					body_rtl.text = comp_item.get("preview_text", comp_item["desc"])
					panel.add_child(body_rtl)
				"widget":
					style.bg_color = palette["bg"]
					panel.add_theme_stylebox_override("panel", style)
					var cta = Button.new()
					cta.text = comp_item.get("preview_btn", "➔ CONFERMA AZIONE")
					cta.add_theme_font_size_override("font_size", 11)
					cta.add_theme_color_override("font_color", palette["accent"])
					cta.pressed.connect(func(): SoundManager.play_ui_click())
					panel.add_child(cta)
				"footer":
					style.bg_color = Color(0.08, 0.09, 0.12, 1)
					panel.add_theme_stylebox_override("panel", style)
					var foot_lbl = Label.new()
					foot_lbl.text = comp_item.get("preview_text", comp_item["desc"])
					foot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					foot_lbl.add_theme_font_size_override("font_size", 10)
					panel.add_child(foot_lbl)
					
		preview_vbox.add_child(panel)

func _switch_tab(show_preview: bool) -> void:
	preview_area.visible = show_preview
	terminal_area.visible = not show_preview
	SoundManager.play_ui_click()

func _on_compile_pressed() -> void:
	if is_compiling or is_build_completed:
		return
		
	var audit = calculate_lighthouse_score()
	if audit["slots_filled"] < 5:
		SoundManager.play_ui_error()
		status_label.text = "Devi prima configurare tutti i 5 slot della pagina!"
		return
		
	is_compiling = true
	compile_elapsed = 0.0
	compile_step = 0
	compile_btn.disabled = true
	_switch_tab(false) # Switch to terminal
	
	SoundManager.play_keyboard_sound()
	terminal_logs.text = "[color=#00ccff]▶ [00:00.00] Inizializzazione toolchain Vite / WebForge 3.0 bundler...[/color]\n"
	terminal_logs.text += "[color=#aaaaaa]• Progetto: %s | Palette: %s[/color]\n" % [active_contract_id, BRAND_PALETTES[current_palette_idx]["name"]]
	terminal_logs.text += "[color=#44ffbb]• Profilo Hardware: %s[/color]\n\n" % build_speed_info.text
	status_label.text = "Compilazione in corso... Generazione bundle di produzione."

func _append_compilation_log_step(step: int) -> void:
	SoundManager.play_keyboard_sound()
	match step:
		1:
			terminal_logs.text += "[color=#33ccff]▶ [%0.2fs] Assemblaggio 5 slot modulari & albero AST... OK[/color]\n" % compile_elapsed
		2:
			terminal_logs.text += "[color=#33ccff]▶ [%0.2fs] Compilazione CSS Brand Palette '%s'... OK[/color]\n" % [compile_elapsed, BRAND_PALETTES[current_palette_idx]["id"]]
		3:
			if opt_minify or opt_webp or opt_meta:
				terminal_logs.text += "[color=#44ffbb]▶ [%0.2fs] Pipeline Ottimizzazione: Minify=%s | WebP=%s | MetaSEO=%s[/color]\n" % [
					compile_elapsed, "Sì" if opt_minify else "No", "Sì" if opt_webp else "No", "Sì" if opt_meta else "No"
				]
			else:
				terminal_logs.text += "[color=#ffbb33]▶ [%0.2fs] Nessuna ottimizzazione attiva: payload bundle non compresso.[/color]\n" % compile_elapsed
		4:
			var audit = calculate_lighthouse_score()
			terminal_logs.text += "[color=#33ff77]▶ [%0.2fs] Lighthouse Audit: Perf %d | A11y %d | SEO %d (Score: %d/100, Grado %s)[/color]\n" % [
				compile_elapsed, int(audit["performance"]), int(audit["accessibility"]), int(audit["seo"]), int(audit["total"]), audit["grade"]
			]

func _finish_compilation() -> void:
	is_compiling = false
	is_build_completed = true
	compile_btn.disabled = true
	compile_btn.text = "✔ Compilazione Terminata"
	
	SoundManager.play_ui_success()
	var audit = calculate_lighthouse_score()
	last_calculated_score = audit["total"]
	
	terminal_logs.text += "\n[color=#33ff77]✔ BUILD E BUNDLING COMPLETATI CON SUCCESSO![/color]\n"
	terminal_logs.text += "[color=#00ccff]• Artifact: dist/release_%s.tar.gz (Lighthouse %d/100 - Grado %s)[/color]\n" % [
		active_contract_id, int(last_calculated_score), audit["grade"]
	]
	
	var contract = ContractManager.get_contract(active_contract_id)
	var base_budget = float(contract.get("budget", 650.0))
	var prefs = _get_client_preferences(active_contract_id)
	
	# Tip bonus for 95%+ Lighthouse score
	if last_calculated_score >= 95.0:
		last_calculated_tip = round(base_budget * 0.20)
		terminal_logs.text += "[color=#ffdd44]★ Punteggio di Eccellenza (>=95%%): Sbloccata mancia cliente del 20%% (+€ %0.2f)![/color]\n" % last_calculated_tip
	else:
		last_calculated_tip = 0.0
		
	var review_quote = prefs["perfect_review"] if last_calculated_score >= 95.0 else prefs["good_review"]
	terminal_logs.text += "[color=#ffffff]\nRecensione Cliente:\n%s[/color]\n" % review_quote
	
	var result_data = {
		"quality": last_calculated_score,
		"theme": BRAND_PALETTES[current_palette_idx]["id"],
		"slots": slotted_components.duplicate(),
		"lighthouse": audit
	}
	ContractManager.mark_contract_built(active_contract_id, result_data)
	
	deliver_btn.visible = true
	deliver_btn.disabled = false
	if last_calculated_tip > 0.0:
		deliver_btn.text = "★ Consegna Release (€ %0.2f + € %0.2f Mancia!)" % [base_budget, last_calculated_tip]
		status_label.text = "Eccellente! Punteggio %d/100 (Grado %s) con mancia di € %0.2f! Clicca su Consegna per incassare." % [
			int(last_calculated_score), audit["grade"], last_calculated_tip
		]
	else:
		deliver_btn.text = "★ Consegna Release a %s (€ %0.2f)" % [contract.get("client", "Cliente"), base_budget]
		status_label.text = "Build pronta! Punteggio %d/100 (Grado %s). Clicca su Consegna per incassare il pagamento." % [
			int(last_calculated_score), audit["grade"]
		]

func _on_deliver_pressed() -> void:
	SoundManager.play_cash_register()
	SoundManager.play_ui_success()
	
	# Award tip bonus if earned
	if last_calculated_tip > 0.0:
		var contract = ContractManager.get_contract(active_contract_id)
		var client_str = contract.get("client", "Cliente")
		EconomyManager.earn(last_calculated_tip, "Mancia WebForge (Lighthouse %d/100): %s" % [int(last_calculated_score), client_str])
		
	# Complete contract in ContractManager
	if active_contract_id in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to"]:
		ContractManager.complete_story_contract(active_contract_id)
	else:
		ContractManager.complete_marketplace_contract(active_contract_id)
		
	visible = false
	EventBus.computer_opened.emit()

func _on_exit_pressed() -> void:
	if is_compiling:
		return
	visible = false
	EventBus.computer_opened.emit()
