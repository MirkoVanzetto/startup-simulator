extends Control
## WebForgeController - WebForge 4.0: Spoiler-Free Briefs, Responsive Wireframe & Code Debug Minigame.
## Eliminates passive checkboxes and pre-filled match spoilers:
## - Natural Italian briefs (plus Sara's optional hints if hired)
## - Neutral starter palette (player interprets brief & picks theme + components)
## - Interactive 3-Ticket Code Debug & Fix tab for CSS/JS Bundling, WebP Pipeline & Meta SEO
## - Live Desktop / Mobile responsive preview toggle
## - Genuine hardware/employee compilation duration timer

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
@onready var tab_debug_btn: Button = $Main/Body/Canvas/CanvasVBox/CanvasHeaderHBox/TabDebugBtn
@onready var tab_terminal_btn: Button = $Main/Body/Canvas/CanvasVBox/CanvasHeaderHBox/TabTerminalBtn
@onready var preview_area: PanelContainer = $Main/Body/Canvas/CanvasVBox/PreviewArea
@onready var preview_vbox: VBoxContainer = $Main/Body/Canvas/CanvasVBox/PreviewArea/PreviewScroll/PreviewVBox
@onready var debug_area: PanelContainer = $Main/Body/Canvas/CanvasVBox/DebugArea
@onready var ticket_buttons: Array[Button] = [
	$Main/Body/Canvas/CanvasVBox/DebugArea/DebugScroll/DebugVBox/TicketSelectorRow/Ticket0Btn,
	$Main/Body/Canvas/CanvasVBox/DebugArea/DebugScroll/DebugVBox/TicketSelectorRow/Ticket1Btn,
	$Main/Body/Canvas/CanvasVBox/DebugArea/DebugScroll/DebugVBox/TicketSelectorRow/Ticket2Btn
]
@onready var ticket_problem_label: Label = $Main/Body/Canvas/CanvasVBox/DebugArea/DebugScroll/DebugVBox/TicketProblemLabel
@onready var snippet_label: RichTextLabel = $Main/Body/Canvas/CanvasVBox/DebugArea/DebugScroll/DebugVBox/SnippetPanel/SnippetLabel
@onready var sara_hint_label: Label = $Main/Body/Canvas/CanvasVBox/DebugArea/DebugScroll/DebugVBox/SaraHintLabel
@onready var fixes_vbox: VBoxContainer = $Main/Body/Canvas/CanvasVBox/DebugArea/DebugScroll/DebugVBox/FixesVBox
@onready var debug_feedback_label: Label = $Main/Body/Canvas/CanvasVBox/DebugArea/DebugScroll/DebugVBox/DebugFeedbackLabel
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

# CSS Brand Palettes (keep indices 0=terracotta and 2=cyan for backwards compatibility!)
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
	},
	{
		"id": "amber",
		"name": "Acciaio & Ambra Industriale (Giallo & Nero)",
		"primary": Color(0.88, 0.56, 0.14, 1.0),
		"accent": Color(0.28, 0.72, 0.92, 1.0),
		"bg": Color(0.11, 0.12, 0.15, 1.0),
		"client_bias": "factory_bellini_web"
	}
]

# Modular Components Catalog (4 choices per slot including Industrial / Officina)
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
		},
		{
			"id": "header_officina",
			"title": "⚙ Officina Bellini Portal",
			"tags": ["Tech", "Booking"],
			"bias": "factory_bellini_web",
			"desc": "Testata industriale con stato reparti CNC e portale preventivi B2B.",
			"preview_title": "⚙ OFFICINA MECCANICA BELLINI — VALDOCCO",
			"preview_sub": "Tornitura CNC 5 Assi · Carpenteria di Precisione ISO 9001"
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
		},
		{
			"id": "hero_officina",
			"title": "🏭 Reparto CNC & Logistica",
			"tags": ["Tech", "Booking"],
			"bias": "factory_bellini_web",
			"desc": "Banner tecnico sulle fresatrici automatiche e consegne B2B in Piemonte.",
			"preview_text": "«Prototipazione rapida e serie industriali ad alta tolleranza (+/- 0.01mm) nello stabilimento di Borgo Valdocco Est.»"
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
		},
		{
			"id": "body_officina",
			"title": "🔩 Catalogo Lavorazioni & CAD",
			"tags": ["Tech", "E-Commerce"],
			"bias": "factory_bellini_web",
			"desc": "Specifiche fresatura, taglio laser fibra e carichi di produzione.",
			"preview_text": "• [b]Fresatura CNC 5 Assi:[/b] Alluminio 7075, Acciaio Inox, Titanio\n• [b]Taglio Laser Fibra:[/b] Fino a 20mm spessore | Spedizione 48h\n• [b]Portale Clienti LAN/NAS:[/b] Upload disegni STEP/IGES protetti"
		}
	],
	"widget": [
		{
			"id": "widget_booking",
			"title": "📅 Prenotazione Tavoli / Slot",
			"tags": ["Booking", "Tradition"],
			"bias": "pizzeria_da_mario",
			"desc": "Selezione orario, numero coperti o slot ritiro/preventivo.",
			"preview_btn": "➔ PRENOTA UN TAVOLO O RICHIEDI APPUNTAMENTO"
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
		},
		{
			"id": "widget_officina",
			"title": "📐 Configuratore Preventivi B2B",
			"tags": ["Booking", "Tech"],
			"bias": "factory_bellini_web",
			"desc": "Caricamento file CAD e prenotazione slot di produzione o carico merci.",
			"preview_btn": "➔ INVIA FILE CAD & PRENOTA PREVENTIVO B2B"
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
		},
		{
			"id": "footer_officina",
			"title": "🚚 Ribalta Valdocco Est & Certificati",
			"tags": ["Tech", "Booking"],
			"bias": "factory_bellini_web",
			"desc": "Accesso mezzi pesanti Borgo Valdocco Est, orari officina e ISO 9001.",
			"preview_text": "🏭 Borgo Valdocco Est, Torino | Carico/Scarico Lun-Ven 08:00-18:00 | Rete Wi-Fi 6 + NAS RAID"
		}
	]
}

# Interactive Code Debug Tickets (drives opt_minify, opt_webp, opt_meta)
const DEBUG_TICKETS: Array[Dictionary] = [
	{
		"key": "minify",
		"title": "Ticket #1: Script Render-Blocking & Bundle CSS/JS (+3.8MB)",
		"problem": "Il caricamento si blocca 2.4s perché analytics e CSS non sono minimizzati in <head>.",
		"code": "[color=#8899aa]// index.html & vite.config.ts[/color]\n[color=#ff6666]- <script src=\"/assets/bundle_uncompressed.js\"></script>[/color]\n[color=#ffbb33]  <link rel=\"stylesheet\" href=\"/css/raw_styles.css\">[/color]\n[color=#ff6666]  // build: { minify: false }[/color]",
		"hint": "Tip di Sara: serve uno script non bloccante ('defer') e la minificazione Esbuild/Vite attiva per dimezzare il payload.",
		"options": [
			{"label": "Aggiungi <script defer> + attiva Vite minify:'esbuild'", "correct": true, "msg": "Patch applicata! Bundle JS/CSS ridotto da 3.8MB a 420KB (-89% tempo FCP)."},
			{"label": "Disabilita del tutto i fogli di stile CSS", "correct": false, "msg": "Regressione visiva! Senza CSS la pagina risulta illeggibile su tutti i browser."},
			{"label": "Sposta tutto in eval(fetch(...)) sincrono", "correct": false, "msg": "Rischio sicurezza XSS e blocco del thread principale!"}
		]
	},
	{
		"key": "webp",
		"title": "Ticket #2: Immagini PNG grezze non compresse (8.4MB)",
		"problem": "Le foto banner rallentano il mobile 4G: <img> carica PNG a piena risoluzione senza lazy-loading.",
		"code": "[color=#8899aa]// components/HeroBanner.html[/color]\n[color=#ff6666]- <img src=\"/raw/hero_4k_8mb.png\">[/color]\n[color=#ffbb33]  /* Nessun width/height esplicito -> Layout Shift (CLS) alto */[/color]",
		"hint": "Tip di Sara: converti in formato WebP moderno, aggiungi 'loading=\"lazy\"' alle card e specifica 'width/height'.",
		"options": [
			{"label": "Riduci le immagini a 16x16 pixel per risparmiare byte", "correct": false, "msg": "Le foto appaiono sgranate e il cliente rifiuterebbe l'anteprima!"},
			{"label": "Converti in .webp + sizes responsive + loading=\"lazy\"", "correct": true, "msg": "Pipeline WebP attiva! Peso immagini tagliato del 72% con nitidezza Retina."},
			{"label": "Duplica le immagini in Base64 dentro al file HTML", "correct": false, "msg": "Il file HTML iniziale esplode a +11MB bloccando il parser!"}
		]
	},
	{
		"key": "meta",
		"title": "Ticket #3: Meta SEO, OpenGraph & Tag Semantici Mancanti",
		"problem": "I motori di ricerca non indicizzano il sito: manca <meta description>, canonical e struttura H1.",
		"code": "[color=#8899aa]// layouts/MainLayout.html[/color]\n[color=#ff6666]<head><title>Sito</title></head>[/color]\n[color=#ffbb33]<body><div class=\"big-text\">Benvenuto</div></body>[/color]",
		"hint": "Tip di Sara: inserisci <meta name=\"description\">, 'og:title', rel=\"canonical\" e un vero tag semantico <h1>.",
		"options": [
			{"label": "Nascondi 500 parole chiave bianche nel footer", "correct": false, "msg": "Penalità Google Anti-Spam garantita!"},
			{"label": "Usa tre tag <title> duplicati nel <body>", "correct": false, "msg": "HTML non valido secondo il validatore W3C."},
			{"label": "Aggiungi <meta description>, OpenGraph og:title, canonical & <h1>", "correct": true, "msg": "SEO Audit al 100%! Tag OpenGraph e gerarchia semantica validati."}
		]
	}
]

# State Variables
var active_contract_id: String = "pizzeria_da_mario"
var active_slot_idx: int = 0
var active_ticket_idx: int = 0
var preview_mode: String = "desktop" # "desktop" or "mobile"
var slotted_components: Dictionary = {
	"header": null,
	"hero": null,
	"body": null,
	"widget": null,
	"footer": null
}
var current_palette_idx: int = 4 # Neutral default (Minimal White)
var opt_minify: bool = false
var opt_webp: bool = false
var opt_meta: bool = false

# Compilation & Build State
var is_compiling: bool = false
var is_build_completed: bool = false
var compile_elapsed: float = 0.0
var compile_target_duration: float = 5.5
var compile_step: int = 0
var last_calculated_tip: float = 0.0
var last_calculated_score: float = 0.0

func _ready() -> void:
	visible = false
	EventBus.minigame_started.connect(_on_minigame_started)
	
	exit_btn.pressed.connect(_on_exit_pressed)
	compile_btn.pressed.connect(_on_compile_pressed)
	deliver_btn.pressed.connect(_on_deliver_pressed)
	
	tab_preview_btn.pressed.connect(func(): _show_canvas_tab("preview"))
	tab_debug_btn.pressed.connect(func(): _show_canvas_tab("debug"))
	tab_terminal_btn.pressed.connect(func(): _show_canvas_tab("terminal"))
	
	for i in range(slot_tab_buttons.size()):
		var idx = i
		slot_tab_buttons[idx].pressed.connect(func(): _select_slot(idx))
		
	for i in range(ticket_buttons.size()):
		var tidx = i
		ticket_buttons[tidx].pressed.connect(func(): _select_debug_ticket(tidx))
		
	_setup_palette_picker()
	palette_picker.item_selected.connect(_on_palette_selected)
	
	opt_btn_minify.pressed.connect(_on_opt_minify_pressed)
	opt_btn_webp.pressed.connect(_on_opt_webp_pressed)
	opt_btn_meta.pressed.connect(_on_opt_meta_pressed)

func _process(delta: float) -> void:
	if not is_compiling:
		return
		
	compile_elapsed += delta
	var target_dur := maxf(compile_target_duration, 0.5)
	var progress = clampf(compile_elapsed / target_dur, 0.0, 1.0)
	terminal_progress.value = progress * 100.0
	
	var step_threshold = target_dur / 4.0
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
	var pref := str(ContractManager.preferred_webforge_contract_id)
	if pref != "":
		var pc = ContractManager.get_contract(pref)
		if pc.get("status") == "in_progress" and pc.get("execution_type", "webforge") == "webforge":
			active_contract_id = pref
		ContractManager.preferred_webforge_contract_id = ""
		
	if active_contract_id == "":
		for cid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to", "factory_bellini_web"]:
			var c = ContractManager.get_contract(cid)
			if c.get("status") == "in_progress":
				active_contract_id = cid
				break
			
	if active_contract_id == "":
		for c in ContractManager.active_contracts.values():
			if c.get("status") == "in_progress" and c.get("execution_type", "webforge") == "webforge":
				active_contract_id = str(c.get("id", ""))
				break
				
	if active_contract_id == "":
		visible = false
		EventBus.notification_posted.emit(
			"WebForge Inattivo",
			"Nessun sito web in lavorazione! Accetta un lavoro su Freelance Hub o parla con i clienti nel Borgo.",
			"warning"
		)
		return
		
	visible = true
	is_compiling = false
	is_build_completed = false
	compile_elapsed = 0.0
	compile_step = 0
	last_calculated_tip = 0.0
	preview_mode = "desktop"
	active_ticket_idx = 0
	debug_feedback_label.text = ""
	
	for k in SLOT_KEYS:
		slotted_components[k] = null
	opt_minify = false
	opt_webp = false
	opt_meta = false
	active_slot_idx = 0
	
	deliver_btn.disabled = true
	deliver_btn.visible = false
	terminal_progress.value = 0.0
	terminal_logs.text = "[color=#00ccff]WebForge Toolchain v4.0 pronta per bundling modulare & code debug.[/color]\n"
	
	_show_canvas_tab("preview")
	_setup_for_active_contract()
	_calculate_compilation_speed()
	_update_slot_tabs_visual()
	_update_component_tray()
	_update_optimization_buttons_visual()
	_update_palette_affinity_badge()
	_render_debug_ticket()
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
		
	if EmployeeManager and EmployeeManager.is_employee_hired("emp_sara"):
		duration -= 2.5
		boosts.append("Sara Dev (-2.5s)")
		
	compile_target_duration = maxf(1.2, duration)
	
	if boosts.is_empty():
		build_speed_info.text = "Toolchain: Starter Laptop (%0.1fs)" % compile_target_duration
	else:
		build_speed_info.text = "Toolchain: %0.1fs [%s]" % [compile_target_duration, ", ".join(boosts)]

func _setup_palette_picker() -> void:
	palette_picker.clear()
	for p in BRAND_PALETTES:
		palette_picker.add_item(p["name"])
	palette_picker.selected = 4
	current_palette_idx = 4

func _setup_for_active_contract() -> void:
	var contract = ContractManager.get_contract(active_contract_id)
	var title = contract.get("title", "Progetto Web")
	var budget = float(contract.get("budget", 650.0))
	ide_label.text = "⚡ WebForge 4.0 — %s (€ %0.2f)" % [title, budget]
	
	client_title.text = "PROGETTO: %s" % contract.get("client", "Cliente")
	
	var prefs = _get_client_preferences(active_contract_id)
	var brief_txt := str(prefs.get("brief", "Segui i requisiti funzionali del cliente."))
	if EmployeeManager and EmployeeManager.is_employee_hired("emp_sara"):
		var tags_str := " ".join(prefs["preferred_tags"].map(func(t): return "[%s]" % t))
		brief_txt += "\n👩‍💻 Nota Sara: cerca componenti %s + palette '%s'." % [tags_str, prefs["palette_name"]]
	client_prefs.text = brief_txt
	
	# Neutro all'avvio: il developer legge il brief e sceglie i colori giusti!
	palette_picker.selected = 4
	current_palette_idx = 4

func _get_client_preferences(cid: String) -> Dictionary:
	match cid:
		"pizzeria_da_mario":
			return {
				"client_name": "Mario Esposito",
				"preferred_tags": ["Tradition", "Booking"],
				"preferred_palette": "terracotta",
				"palette_name": "Terracotta Napoletana",
				"brief": "«Vogliamo un sito caldo color forno a legna con il nostro menu verace e un pulsante immediato per prenotare i tavoli.»",
				"perfect_review": "«Mamma mia! Quella foto del forno a legna fa venire fame a tutta Torino, e il modulo prenotazioni è una bomba! Tieni questa mancia!»",
				"good_review": "«Bel lavoro guagliò, il sito è solido e i clienti finalmente possono vedere le nostre pizze online. Grazie!»"
			}
		"caffe_san_carlo":
			return {
				"client_name": "Elena Rossi",
				"preferred_tags": ["Speed", "Tradition"],
				"preferred_palette": "mocha",
				"palette_name": "Café Mocha & Oro",
				"brief": "«Stile elegante da caffetteria storica torinese sui toni espresso e oro, ultra-rapido per le comande al bancone.»",
				"perfect_review": "«Incredibile! La cassa touch screen e la gestione comande volano! Niente più file al bancone nelle ore di punta!»",
				"good_review": "«Ottimo POS web, molto elegante e i clienti adorano la grafica del nostro storico caffè.»"
			}
		"elettronica_to":
			return {
				"client_name": "Davide Ferrero",
				"preferred_tags": ["Tech", "Speed"],
				"preferred_palette": "cyan",
				"palette_name": "Cyber Cyan & Slate",
				"brief": "«Portale dark ad alte prestazioni: estetica cyber ciano, zero latenza, dashboard cluster e controllo stato server.»",
				"perfect_review": "«Latenza sotto i 2 millisecondi e architettura a prova di bomba! Sei un vero fuoriclasse del software!»",
				"good_review": "«Cluster configurato a dovere e replica database attiva. Buon lavoro!»"
			}
		"factory_bellini_web":
			return {
				"client_name": "Ing. Gianluca Bellini",
				"preferred_tags": ["Tech", "Booking"],
				"preferred_palette": "amber",
				"palette_name": "Acciaio & Ambra Industriale",
				"brief": "«Portale B2B da officina meccanica con palette industriale giallo/acciaio, catalogo lavorazioni CNC e modulo invio preventivi.»",
				"perfect_review": "«Eccellente! I nostri clienti industriali caricano già i disegni CAD e prenotano i lotti dal portale! Ecco la mancia di risultato!»",
				"good_review": "«Sito robusto e chiaro, rispecchia appieno l'identità tecnica dell'Officina Bellini.»"
			}
		_:
			var c = ContractManager.get_contract(cid)
			var b_tags: Array = c.get("preferred_tags", ["Tech", "E-Commerce"])
			var b_pal: String = str(c.get("preferred_palette", "cyan"))
			var p_name := "Cyber Cyan & Slate"
			for p in BRAND_PALETTES:
				if p["id"] == b_pal:
					p_name = p["name"]
					break
			var b_brief := str(c.get("brief", "Sviluppa un portale veloce, accessibile e ben ottimizzato per le esigenze del cliente B2B."))
			return {
				"client_name": str(c.get("client", "Cliente B2B")),
				"preferred_tags": b_tags,
				"preferred_palette": b_pal,
				"palette_name": p_name,
				"brief": "«%s»" % b_brief,
				"perfect_review": "«Eccezionale! Punteggio Lighthouse da primato e release impeccabile su desktop e mobile. Meriti il bonus!»",
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
	var current_slotted_id = slotted_components.get(slot_key)
	
	for item in catalog_items:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 11)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		var is_selected = (item["id"] == current_slotted_id)
		var selected_mark = "✔ " if is_selected else ""
		var tag_labels = " ".join(item["tags"].map(func(t): return "[%s]" % t))
		btn.text = "%s%s %s" % [selected_mark, item["title"], tag_labels]
		btn.tooltip_text = "%s — %s" % [item["title"], item["desc"]]
		
		if is_selected:
			btn.add_theme_color_override("font_color", Color(0.3, 1, 0.6, 1))
		else:
			btn.add_theme_color_override("font_color", Color(0.86, 0.90, 0.95, 1))
			
		var comp_id = item["id"]
		btn.pressed.connect(func(): _on_component_chosen(slot_key, comp_id))
		component_tray_vbox.add_child(btn)

func _on_component_chosen(slot_key: String, comp_id: String) -> void:
	SoundManager.play_ui_click()
	slotted_components[slot_key] = comp_id
	
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
	current_palette_idx = clampi(index, 0, BRAND_PALETTES.size() - 1)
	if palette_picker and palette_picker.selected != current_palette_idx:
		palette_picker.select(current_palette_idx)
	SoundManager.play_ui_click()
	_update_palette_affinity_badge()
	_update_website_preview()
	_update_lighthouse_display()

func _update_palette_affinity_badge() -> void:
	var cur_palette = BRAND_PALETTES[current_palette_idx]
	palette_affinity_badge.text = "Tema attivo: %s — Verifica coerenza col brief." % cur_palette["name"]
	palette_affinity_badge.add_theme_color_override("font_color", Color(0.68, 0.80, 0.92, 1))

# Left shortcut buttons open the interactive Code Debug tab directly on that ticket!
func _on_opt_minify_pressed() -> void:
	_select_debug_ticket(0)
	_show_canvas_tab("debug")

func _on_opt_webp_pressed() -> void:
	_select_debug_ticket(1)
	_show_canvas_tab("debug")

func _on_opt_meta_pressed() -> void:
	_select_debug_ticket(2)
	_show_canvas_tab("debug")

func _select_debug_ticket(idx: int) -> void:
	active_ticket_idx = clampi(idx, 0, DEBUG_TICKETS.size() - 1)
	debug_feedback_label.text = ""
	SoundManager.play_ui_click()
	_render_debug_ticket()

func _is_ticket_solved(idx: int) -> bool:
	match idx:
		0: return opt_minify
		1: return opt_webp
		2: return opt_meta
		_: return false

func _render_debug_ticket() -> void:
	if not ticket_problem_label or not snippet_label or not fixes_vbox:
		return
	var t: Dictionary = DEBUG_TICKETS[active_ticket_idx]
	var solved := _is_ticket_solved(active_ticket_idx)

	for i in range(ticket_buttons.size()):
		var tb := ticket_buttons[i]
		var is_s := _is_ticket_solved(i)
		var base_names := ["#1 Bundle JS/CSS", "#2 Media WebP", "#3 Meta SEO"]
		tb.text = ("✔ " if is_s else "🐛 ") + base_names[i]
		if i == active_ticket_idx:
			tb.add_theme_color_override("font_color", Color(0.35, 1.0, 0.65) if is_s else Color(1.0, 0.85, 0.35))
		elif is_s:
			tb.add_theme_color_override("font_color", Color(0.45, 0.90, 0.55))
		else:
			tb.add_theme_color_override("font_color", Color(0.80, 0.84, 0.90))

	ticket_problem_label.text = "%s\n%s" % [t["title"], t["problem"]]
	snippet_label.text = t["code"]

	var has_sara := EmployeeManager != null and EmployeeManager.is_employee_hired("emp_sara")
	sara_hint_label.visible = has_sara
	if has_sara:
		sara_hint_label.text = "👩‍💻 " + str(t["hint"])

	for ch in fixes_vbox.get_children():
		ch.queue_free()

	if solved:
		var done_lbl := Label.new()
		done_lbl.text = "✔ Patch di produzione già applicata con successo per questo ticket!"
		done_lbl.add_theme_font_size_override("font_size", 12)
		done_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.60))
		done_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fixes_vbox.add_child(done_lbl)
	else:
		var opts: Array = t["options"]
		for opt in opts:
			var btn := Button.new()
			btn.text = "🔧 " + str(opt["label"])
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", 11)
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			btn.custom_minimum_size = Vector2(0, 32)
			var is_ok := bool(opt["correct"])
			var fb_msg := str(opt["msg"])
			btn.pressed.connect(func(): _on_debug_patch_selected(is_ok, fb_msg))
			fixes_vbox.add_child(btn)

func _on_debug_patch_selected(is_correct: bool, feedback: String) -> void:
	if is_correct:
		match active_ticket_idx:
			0: opt_minify = true
			1: opt_webp = true
			2: opt_meta = true
		SoundManager.play_ui_success()
		debug_feedback_label.text = "✔ " + feedback
		debug_feedback_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.58))
		_update_optimization_buttons_visual()
		_update_lighthouse_display()
		_render_debug_ticket()
	else:
		SoundManager.play_ui_error()
		debug_feedback_label.text = "✘ Patch respinta: " + feedback
		debug_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.42))

func _update_optimization_buttons_visual() -> void:
	var solved_count := 0
	if opt_minify:
		solved_count += 1
		opt_btn_minify.text = "✔ #1: Bundle CSS/JS (-89%)"
		opt_btn_minify.add_theme_color_override("font_color", Color(0.3, 1, 0.6, 1))
	else:
		opt_btn_minify.text = "🐛 #1: Risolvi Bundle CSS/JS"
		opt_btn_minify.add_theme_color_override("font_color", Color(1, 0.8, 0.3, 1))
		
	if opt_webp:
		solved_count += 1
		opt_btn_webp.text = "✔ #2: Media WebP (-72%)"
		opt_btn_webp.add_theme_color_override("font_color", Color(0.3, 1, 0.6, 1))
	else:
		opt_btn_webp.text = "🐛 #2: Risolvi Media & WebP"
		opt_btn_webp.add_theme_color_override("font_color", Color(1, 0.8, 0.3, 1))
		
	if opt_meta:
		solved_count += 1
		opt_btn_meta.text = "✔ #3: Meta SEO Attivi"
		opt_btn_meta.add_theme_color_override("font_color", Color(0.3, 1, 0.6, 1))
	else:
		opt_btn_meta.text = "🐛 #3: Risolvi Meta SEO"
		opt_btn_meta.add_theme_color_override("font_color", Color(1, 0.8, 0.3, 1))

	if tab_debug_btn:
		tab_debug_btn.text = "🐛 Debug (%d/3)" % solved_count

## Calculates dynamic Lighthouse audit score (0-100) based on slotted components, tag affinities, palette match, and debug tickets.
func calculate_lighthouse_score() -> Dictionary:
	var slots_filled = 0
	var matching_tags = 0
	var prefs = _get_client_preferences(active_contract_id)
	
	for slot_key in SLOT_KEYS:
		var comp_id = slotted_components.get(slot_key)
		if comp_id != null:
			slots_filled += 1
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
	var perf = clampf(round((float(slots_filled) / 5.0 * 50.0) + (25.0 if opt_minify else 0.0) + (25.0 if opt_webp else 0.0)), 0.0, 100.0)
	var a11y_palette = 20.0 if palette_match else 10.0
	var a11y_bonus = 10.0 if slots_filled == 5 else 0.0
	var a11y = clampf(round((float(slots_filled) / 5.0 * 70.0) + a11y_palette + a11y_bonus), 0.0, 100.0)
	var tag_affinity_ratio = clampf(float(matching_tags) / 5.0, 0.0, 1.0)
	var seo = clampf(round((float(slots_filled) / 5.0 * 40.0) + (tag_affinity_ratio * 35.0) + (25.0 if opt_meta else 0.0)), 0.0, 100.0)
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
	perf_label.text = "⚡ Perf: %d%%" % int(audit["performance"])
	a11y_label.text = "♿ A11y: %d%%" % int(audit["accessibility"])
	seo_label.text = "🔍 SEO: %d%%" % int(audit["seo"])
	
	var slots_filled = audit["slots_filled"]
	if slots_filled == 5:
		compile_btn.disabled = is_compiling or is_build_completed
		compile_btn.text = "⚡ Compila & Esegui Build (5/5 Slot)"
		if not is_build_completed and not is_compiling:
			if int(audit["opts_count"]) < 3:
				status_label.text = "5/5 slot pronti! Risolvi i 3 ticket in 'Debug' per 100/100 A+ (+20% mancia), o compila subito."
			else:
				status_label.text = "Tutti i slot e ticket pronti! Clicca su 'Compila & Esegui Build'."
	else:
		compile_btn.disabled = true
		compile_btn.text = "Configura gli slot (%d/5)" % slots_filled
		if not is_build_completed and not is_compiling:
			status_label.text = "Mancano ancora %d slot da selezionare prima di poter compilare." % (5 - slots_filled)

func _update_website_preview() -> void:
	for child in preview_vbox.get_children():
		child.queue_free()
		
	var palette = BRAND_PALETTES[current_palette_idx]
	
	# 0. Simulated Browser Bar + Responsive Desktop / Mobile Switcher
	var url_bar = PanelContainer.new()
	var url_style = StyleBoxFlat.new()
	url_style.bg_color = Color(0.12, 0.14, 0.18, 1)
	url_style.set_content_margin_all(6)
	url_style.set_corner_radius_all(4)
	url_bar.add_theme_stylebox_override("panel", url_style)
	var url_hbox := HBoxContainer.new()
	url_hbox.add_theme_constant_override("separation", 6)
	url_bar.add_child(url_hbox)

	var url_lbl = Label.new()
	url_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	url_lbl.clip_text = true
	var domain = "🔒 https://staging-%s.torino.it/preview" % active_contract_id
	match active_contract_id:
		"pizzeria_da_mario": domain = "🔒 https://www.pizzeriadamario-torino.it [Staging]"
		"caffe_san_carlo": domain = "🔒 https://pos.caffesancarlo.to.it [Touch POS]"
		"elettronica_to": domain = "🔒 https://cloud.elettronicato.com [Cluster]"
		"factory_bellini_web": domain = "🔒 https://www.officinabellini-valdocco.it [CNC B2B]"
	url_lbl.text = domain
	url_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5, 1))
	url_lbl.add_theme_font_size_override("font_size", 11)
	url_hbox.add_child(url_lbl)

	var desktop_btn := Button.new()
	desktop_btn.text = "🖥 Desktop"
	desktop_btn.add_theme_font_size_override("font_size", 10)
	desktop_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.6) if preview_mode == "desktop" else Color(0.75, 0.80, 0.88))
	desktop_btn.pressed.connect(func():
		preview_mode = "desktop"
		SoundManager.play_ui_click()
		_update_website_preview()
	)
	url_hbox.add_child(desktop_btn)

	var mobile_btn := Button.new()
	mobile_btn.text = "📱 Mobile"
	mobile_btn.add_theme_font_size_override("font_size", 10)
	mobile_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.6) if preview_mode == "mobile" else Color(0.75, 0.80, 0.88))
	mobile_btn.pressed.connect(func():
		preview_mode = "mobile"
		SoundManager.play_ui_click()
		_update_website_preview()
	)
	url_hbox.add_child(mobile_btn)

	preview_vbox.add_child(url_bar)

	var target_container: VBoxContainer = preview_vbox
	if preview_mode == "mobile":
		var center := CenterContainer.new()
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var phone_shell := PanelContainer.new()
		phone_shell.custom_minimum_size = Vector2(305, 0)
		var ph_style := StyleBoxFlat.new()
		ph_style.bg_color = Color(0.06, 0.07, 0.09, 1.0)
		ph_style.border_color = palette["accent"]
		ph_style.set_border_width_all(2)
		ph_style.set_corner_radius_all(14)
		ph_style.set_content_margin_all(8)
		phone_shell.add_theme_stylebox_override("panel", ph_style)
		var ph_vbox := VBoxContainer.new()
		ph_vbox.add_theme_constant_override("separation", 5)
		var mob_hdr := Label.new()
		mob_hdr.text = "📱 390×844 Responsive Mobile Viewport"
		mob_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mob_hdr.add_theme_font_size_override("font_size", 10)
		mob_hdr.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
		ph_vbox.add_child(mob_hdr)
		phone_shell.add_child(ph_vbox)
		center.add_child(phone_shell)
		preview_vbox.add_child(center)
		target_container = ph_vbox
	
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
			style.bg_color = Color(0.08, 0.10, 0.14, 0.6)
			style.set_border_width_all(1)
			style.border_color = Color(0.3, 0.8, 1, 0.8) if is_current else Color(0.2, 0.25, 0.35, 0.6)
			panel.add_theme_stylebox_override("panel", style)
			
			var placeholder_btn = Button.new()
			placeholder_btn.text = "＋ Inserisci [%s]" % SLOT_NAMES[i]
			placeholder_btn.add_theme_font_size_override("font_size", 11)
			placeholder_btn.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9, 1))
			var slot_idx_copy = i
			placeholder_btn.pressed.connect(func(): _select_slot(slot_idx_copy))
			panel.add_child(placeholder_btn)
		else:
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
					title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					title_lbl.add_theme_font_size_override("font_size", 13)
					v.add_child(title_lbl)
					var sub_lbl = Label.new()
					sub_lbl.text = comp_item.get("preview_sub", "")
					sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
					body_rtl.add_theme_font_size_override("normal_font_size", 11)
					body_rtl.text = comp_item.get("preview_text", comp_item["desc"])
					panel.add_child(body_rtl)
				"widget":
					style.bg_color = palette["bg"]
					panel.add_theme_stylebox_override("panel", style)
					var cta = Button.new()
					cta.text = comp_item.get("preview_btn", "➔ CONFERMA AZIONE")
					cta.add_theme_font_size_override("font_size", 11)
					cta.add_theme_color_override("font_color", palette["accent"])
					cta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					cta.pressed.connect(func(): SoundManager.play_ui_click())
					panel.add_child(cta)
				"footer":
					style.bg_color = Color(0.08, 0.09, 0.12, 1)
					panel.add_theme_stylebox_override("panel", style)
					var foot_lbl = Label.new()
					foot_lbl.text = comp_item.get("preview_text", comp_item["desc"])
					foot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					foot_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					foot_lbl.add_theme_font_size_override("font_size", 10)
					panel.add_child(foot_lbl)
					
		target_container.add_child(panel)

func _switch_tab(show_preview: bool) -> void:
	_show_canvas_tab("preview" if show_preview else "terminal")

func _show_canvas_tab(tab_name: String) -> void:
	preview_area.visible = (tab_name == "preview")
	if debug_area:
		debug_area.visible = (tab_name == "debug")
	terminal_area.visible = (tab_name == "terminal")
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
	_show_canvas_tab("terminal")
	
	SoundManager.play_keyboard_sound()
	terminal_logs.text = "[color=#00ccff]▶ [00:00.00] Inizializzazione toolchain Vite / WebForge 4.0 bundler...[/color]\n"
	terminal_logs.text += "[color=#aaaaaa]• Progetto: %s | Palette: %s | Tempo stimato: %0.1fs[/color]\n" % [active_contract_id, BRAND_PALETTES[current_palette_idx]["name"], compile_target_duration]
	terminal_logs.text += "[color=#44ffbb]• Profilo Hardware: %s[/color]\n\n" % build_speed_info.text
	status_label.text = "Compilazione in corso (%0.1fs)..." % compile_target_duration

func _append_compilation_log_step(step: int) -> void:
	SoundManager.play_keyboard_sound()
	match step:
		1:
			terminal_logs.text += "[color=#33ccff]▶ [%0.2fs] Assemblaggio 5 slot modulari & albero AST... OK[/color]\n" % compile_elapsed
		2:
			terminal_logs.text += "[color=#33ccff]▶ [%0.2fs] Compilazione CSS Brand Palette '%s' + Responsive Grid... OK[/color]\n" % [compile_elapsed, BRAND_PALETTES[current_palette_idx]["id"]]
		3:
			if opt_minify or opt_webp or opt_meta:
				terminal_logs.text += "[color=#44ffbb]▶ [%0.2fs] Debug Pipeline: Minify=%s | WebP=%s | MetaSEO=%s[/color]\n" % [
					compile_elapsed, "OK" if opt_minify else "Warn", "OK" if opt_webp else "Warn", "OK" if opt_meta else "Warn"
				]
			else:
				terminal_logs.text += "[color=#ffbb33]▶ [%0.2fs] Nessuna patch debug applicata: payload bundle non ottimizzato.[/color]\n" % compile_elapsed
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
		deliver_btn.text = "★ Consegna (€ %0.2f + € %0.0f)" % [base_budget, last_calculated_tip]
		status_label.text = "Eccellente! %d/100 (%s) + mancia € %0.0f! Consegna ora." % [
			int(last_calculated_score), audit["grade"], last_calculated_tip
		]
	else:
		deliver_btn.text = "★ Consegna Release (€ %0.2f)" % base_budget
		status_label.text = "Build pronta (%d/100, Grado %s)! Clicca su Consegna." % [
			int(last_calculated_score), audit["grade"]
		]

func _on_deliver_pressed() -> void:
	SoundManager.play_cash_register()
	SoundManager.play_ui_success()
	
	if last_calculated_tip > 0.0:
		var contract = ContractManager.get_contract(active_contract_id)
		var client_str = contract.get("client", "Cliente")
		EconomyManager.earn(last_calculated_tip, "Mancia WebForge (Lighthouse %d/100): %s" % [int(last_calculated_score), client_str])
		
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
